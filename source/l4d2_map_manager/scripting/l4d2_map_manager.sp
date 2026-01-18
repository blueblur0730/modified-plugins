#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <nativevotes>
#include <l4d2_source_keyvalues>    	// https://github.com/fdxx/l4d2_source_keyvalues
#include <left4dhooks>
#include <colors>
#include <gamedata_wrapper>

// all by fdxx.
// https://github.com/fdxx/l4d2_plugins/blob/main/gamedata/l4d2_map_vote.txt
#define GAMEDATA_FILE "l4d2_map_manager"
#define ADDRESS_MATCHEXTL4D "g_pMatchExtL4D"
#define ADDRESS_THEDIRECTOR "TheDirector"
#define SDKCALL_GETALLMISSIONS "MatchExtL4D::GetAllMissions"
#define SDKCALL_ONCHANGEMISSIONVOTE "CDirector::OnChangeMissionVote"
#define SDKCALL_CLEARTEAMSCORES "CDirector::ClearTeamScores"
#define DETOUR_FUNCTION "CDirector::FinishScenarioExit"
#define TRANSLATION_FILE "l4d2_map_manager.phrases"

#define TEAMFLAGS_SPEC	2
#define TEAMFLAGS_SUR	4
#define TEAMFLAGS_INF	8
#define TEAMFLAGS_DEFAULT (TEAMFLAGS_SPEC|TEAMFLAGS_SUR|TEAMFLAGS_INF)

Address
	g_pMatchExtL4D,
	g_pTheDirector;

Handle
	g_hSDKGetAllMissions,
	g_hSDKChangeMission,
	g_hSDKClearTeamScores;

DynamicDetour g_hDTR_CDirector_OnFinishScenarioExit;

StringMap
	g_smTranslate,
	g_smExcludeMissions,
	g_smFirstMap;

ConVar
	mp_gamemode,
	g_cvAdminTeamFlags;

GlobalForward
    g_hFWD_OnPreservedMap;

int
	g_iType[MAXPLAYERS],
	g_iPos[MAXPLAYERS][2];

bool g_bIsFinalMap = false;

enum struct MvAttr
{
	int MenuTeamFlags;
	int VoteTeamFlags;
	bool bAdminOneVotePassed;
	bool bAdminOneVoteAgainst;
}

MvAttr g_MvAttr;
char g_sMode[128];
char g_sPreservedMap[128];

bool g_bPreserved = false;
bool g_bAdminOneVote = false;

Handle g_hTimer = null;

static const char g_sValveMaps[][][] = 
{
	{"#L4D360UI_CampaignName_C1",	"C1 死亡中心"},
	{"#L4D360UI_CampaignName_C2",	"C2 黑色嘉年华"},
	{"#L4D360UI_CampaignName_C3",	"C3 沼泽激战"},
	{"#L4D360UI_CampaignName_C4",	"C4 暴风骤雨"},
	{"#L4D360UI_CampaignName_C5",	"C5 教区"},
	{"#L4D360UI_CampaignName_C6",	"C6 短暂时刻"},
	{"#L4D360UI_CampaignName_C7",	"C7 牺牲"},
	{"#L4D360UI_CampaignName_C8",	"C8 毫不留情"},
	{"#L4D360UI_CampaignName_C9",	"C9 坠机险途"},
	{"#L4D360UI_CampaignName_C10",	"C10 死亡丧钟"},
	{"#L4D360UI_CampaignName_C11",	"C11 寂静时分"},
	{"#L4D360UI_CampaignName_C12",	"C12 血腥收获"},
	{"#L4D360UI_CampaignName_C13",	"C13 刺骨寒溪"},
	{"#L4D360UI_CampaignName_C14",	"C14 临死一搏"},
};

#define PLUGIN_VERSION "1.3"

#include "l4d2_map_manager/map_loop.sp"
#include "l4d2_map_manager/map_vote.sp"

public Plugin myinfo = 
{
	name = "[L4D2] Map Manager",
	author = "fdxx, blueblur",
	description = "Map manager for voting, cycling.",
	version = PLUGIN_VERSION,
	url = "https://github.com/blueblur0730/modified-plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	
    // void OnNextMapPreserved(const char[] map);
    g_hFWD_OnPreservedMap = new GlobalForward("OnNextMapPreserved", ET_Event, Param_String);
	RegPluginLibrary("l4d2_map_manager");
	return APLRes_Success;
}

public void OnPluginStart()
{
	Init();
    LoadTranslation(TRANSLATION_FILE);
	CreateConVar("l4d2_map_manager_version", PLUGIN_VERSION, "version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvAdminTeamFlags = CreateConVar("l4d2_map_manager_adminteamflags", "0", "Admin bypass TeamFlags.");
	mp_gamemode = FindConVar("mp_gamemode");

	OnConVarChanged(null, "", "");
	mp_gamemode.AddChangeHook(OnConVarChanged);
    g_cvAdminTeamFlags.AddChangeHook(OnConVarChanged);

    _map_vote_OnPluginStart();
    _map_loop_OnPluginStart();

    g_hTimer = CreateTimer(300.0, Timer_PreserveAnnounce, _, TIMER_REPEAT);
}

public void OnClientPutInServer(int client)
{
	_map_loop_OnClientPutInServer(client);
}

public void OnPluginEnd()
{
    if (g_smTranslate) delete g_smTranslate;
    if (g_smExcludeMissions) delete g_smExcludeMissions;
    if (g_smFirstMap) delete g_smFirstMap;
    if (g_hTimer) g_hTimer = null;
	if (g_hDTR_CDirector_OnFinishScenarioExit)
	{
		g_hDTR_CDirector_OnFinishScenarioExit.Disable(Hook_Pre, DTR_CDirector_OnFinishScenarioExit);
		delete g_hDTR_CDirector_OnFinishScenarioExit;
	}
}

public void OnMapStart()
{
    g_bIsFinalMap = L4D_IsMissionFinalMap();
}

public void OnMapEnd()
{
    g_bIsFinalMap = false;
}

// wait for natives to full loaded.
public void OnAllPluginsLoaded()
{
    SetFirstMapString();
}

void Timer_PreserveAnnounce(Handle timer)
{
    if (g_bPreserved)
    {
        char sMissionName[256];
        if (g_smFirstMap.GetString(g_sPreservedMap, sMissionName, sizeof(sMissionName)))
            CPrintToChatAll("%t", "PreservedMap", sMissionName);
    }
}

void SetFirstMapString()
{
	delete g_smFirstMap;
	g_smFirstMap = new StringMap();

	char sKey[64], sMissionName[256], sFirstMap[256];

	SourceKeyValues kvMissions = SDKCall(g_hSDKGetAllMissions, g_pMatchExtL4D);
	for (SourceKeyValues kvSub = kvMissions.GetFirstTrueSubKey(); !kvSub.IsNull(); kvSub = kvSub.GetNextTrueSubKey())
	{
		FormatEx(sKey, sizeof(sKey), "modes/%s/1/Map", g_sMode);
		SourceKeyValues kvFirstMap = kvSub.FindKey(sKey);
		if (!kvFirstMap.IsNull())
		{
			kvSub.GetName(sMissionName, sizeof(sMissionName));
			kvFirstMap.GetString(NULL_STRING, sFirstMap, sizeof(sFirstMap));
			g_smFirstMap.SetString(sFirstMap, sMissionName);
		}
	}
}

bool IsValidTeamFlags(int client, int flags)
{
	if (g_bAdminOneVote && CheckCommandAccess(client, "sm_admin", ADMFLAG_ROOT))
		return true;

	int team = GetClientTeam(client);
	return (flags & (1 << team)) != 0;
}

void RegAdminCmdEx(const char[] cmd, ConCmd callback, int adminflags, const char[] description="", const char[] group="", int flags=0)
{
	if (!CommandExists(cmd))
		RegAdminCmd(cmd, callback, adminflags, description, group, flags);
	else
	{
		char pluginName[PLATFORM_MAX_PATH];
		FindPluginNameByCmd(pluginName, sizeof(pluginName), cmd);
		LogError("The command \"%s\" already exists, plugin: \"%s\"", cmd, pluginName);
	}
}

void RegConsoleCmdEx(const char[] cmd, ConCmd callback, const char[] description="", int flags=0)
{
	if (!CommandExists(cmd))
		RegConsoleCmd(cmd, callback, description, flags);
	else
	{
		char pluginName[PLATFORM_MAX_PATH];
		FindPluginNameByCmd(pluginName, sizeof(pluginName), cmd);
		LogError("The command \"%s\" already exists, plugin: \"%s\"", cmd, pluginName);
	}
}

bool FindPluginNameByCmd(char[] buffer, int maxlength, const char[] cmd)
{
	char cmdBuffer[128];
	bool result = false;
	CommandIterator iter = new CommandIterator();

	while (iter.Next())
	{
		iter.GetName(cmdBuffer, sizeof(cmdBuffer));
		if (strcmp(cmdBuffer, cmd, false))
			continue;

		GetPluginFilename(iter.Plugin, buffer, maxlength);
		result = true;
		break;
	}

	if (!result)
	{
		ConVar cvar = FindConVar(cmd);
		if (cvar)
		{
			GetPluginFilename(cvar.Plugin, buffer, maxlength);
			result = true;
		}
	}

	delete iter;
	return result;
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	mp_gamemode.GetString(g_sMode, sizeof(g_sMode));
    g_bAdminOneVote = g_cvAdminTeamFlags.BoolValue;

    if (g_bAdminOneVote)
    {
	    g_MvAttr.bAdminOneVotePassed = true;
	    g_MvAttr.bAdminOneVoteAgainst = true;
    }
    else
    {
        g_MvAttr.bAdminOneVotePassed = false;
	    g_MvAttr.bAdminOneVoteAgainst = false;
    }
}

void Init()
{
	GameDataWrapper gd = new GameDataWrapper(GAMEDATA_FILE);
	g_pMatchExtL4D = gd.GetAddress(ADDRESS_MATCHEXTL4D);
	g_pTheDirector = gd.GetAddress(ADDRESS_THEDIRECTOR);

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetVirtual(0);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetAllMissions = EndPrepSDKCall();
	if (g_hSDKGetAllMissions == null)
		SetFailState("Failed to create SDKCall: MatchExtL4D::GetAllMissions");
	
    SDKCallParamsWrapper params[] = {{ SDKType_String, SDKPass_Pointer }};
    g_hSDKChangeMission = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Signature, SDKCALL_ONCHANGEMISSIONVOTE, params, sizeof(params));

    SDKCallParamsWrapper params1[] = {{ SDKType_Bool, SDKPass_Plain }};
    g_hSDKClearTeamScores = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Signature, SDKCALL_CLEARTEAMSCORES, params1, sizeof(params1));

	g_hDTR_CDirector_OnFinishScenarioExit = gd.CreateDetourOrFail(DETOUR_FUNCTION, true, DTR_CDirector_OnFinishScenarioExit);

	delete gd;

	g_smTranslate = new StringMap();
	for (int i; i < sizeof(g_sValveMaps); i++)
		g_smTranslate.SetString(g_sValveMaps[i][0], g_sValveMaps[i][1]);

	g_smExcludeMissions = new StringMap();
	g_smExcludeMissions.SetValue("credits", 1);
	g_smExcludeMissions.SetValue("HoldoutChallenge", 1);
	g_smExcludeMissions.SetValue("HoldoutTraining", 1);
	g_smExcludeMissions.SetValue("parishdash", 1);
	g_smExcludeMissions.SetValue("shootzones", 1);

	// Out-of-the-box settings.
	g_MvAttr.MenuTeamFlags = TEAMFLAGS_SUR|TEAMFLAGS_INF;
	g_MvAttr.VoteTeamFlags = TEAMFLAGS_SUR|TEAMFLAGS_INF;
}

stock void LoadTranslation(const char[] translation)
{
	char sPath[PLATFORM_MAX_PATH], sName[PLATFORM_MAX_PATH];

	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}
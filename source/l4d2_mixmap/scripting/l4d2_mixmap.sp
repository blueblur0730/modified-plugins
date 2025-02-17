#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>
//#include <log4sp>
#include <l4d2_source_keyvalues>
#include <l4d2_nativevote>
#include <gamedata_wrapper>
#include <colors>

#define PLUGIN_VERSION "re1.0"

#define LOGGER_NAME "Mixmap"
#define TRANSLATION_FILE "l4d2_mixmap.phrases"
#define GAMEDATA_FILE "l4d2_mixmap"
#define ADDRESS_MATCHEXTL4D "g_pMatchExtL4D"
#define ADDRESS_THEDIRECTOR "TheDirector"
#define SDKCALL_GETALLMISSIONS "MatchExtL4D::GetAllMissions"
#define SDKCALL_ONCHANGEMISSIONVOTE "CDirector::OnChangeMissionVote"
#define SDKCALL_CLEARTRANSITIONEDLANDMARKNAME "ClearTransitionedLandmarkName"
#define DETOUR_RESTORETRANSITIONEDENTITIES "RestoreTransitionedEntities"
#define DETOUR_TRANSITIONRESTORE "CTerrorPlayer::TransitionRestore"
#define DETOUR_DIRECTORCHANGELEVEL "CDirector::DirectorChangeLevel"
#define DETOUR_CTERRORGAMERULES_ONBEGINCHANGELEVEL "CTerrorGameRules::OnBeginChangeLevel"

StringMap g_hMapChapterNames;

ArrayList
	g_hArrayMissionsAndMaps,			// Stores all missions and their map names in order.
	g_hArrayPools;						// Stores slected map names.

//Logger g_hLogger;

bool g_bMapsetInitialized;
int g_iMapsPlayed;

enum MapSetType {
	MapSet_None = 0,
	MapSet_Official = 1,
	MapSet_Custom = 2,
	MapSet_Mixtape = 3
}

MapSetType g_iMapsetType = MapSet_None;

// Modules
#include <l4d2_mixmap/setup.sp>
#include <l4d2_mixmap/detour.sp>
#include <l4d2_mixmap/actions.sp>
#include <l4d2_mixmap/commands.sp>
#include <l4d2_mixmap/mappool.sp>
#include <l4d2_mixmap/util.sp>
#include <l4d2_mixmap/vote.sp>

public Plugin myinfo =
{
	name = "[L4D2] Mixmap",
	author = "blueblur",
	description = "Randomly selects limited maps to build a mixed campaign or match.",
	version = PLUGIN_VERSION,
	url = "https://github.com/blueblur0730/modified-plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	SetupForwards();
	SetupNatives();
	RegPluginLibrary("l4d2_mixmap");

	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslation(TRANSLATION_FILE);
	SetUpGameData();

	SetupConVars();
	SetupCommands();
	//SetupLogger();
	PluginStartInit();
}

public void OnClientPutInServer(int client)
{
	if (g_bMapsetInitialized)
		return;

	if (!g_hCvar_NextMapPrint.BoolValue)
		return;

	int userid = GetClientUserId(client);
	CreateTimer(10.0, Timer_Notify, userid);
	CreateTimer(15.0, Timer_ShowMaplist, userid);
	
}

void Timer_Notify(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsClientInGame(client))
		return;
	
	NotifyMixmap(client);
}

void Timer_ShowMaplist(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsClientInGame(client))
		return;

	NotifyMapList(client);
}

public void OnMapStart()
{
	if (!g_bMapsetInitialized)
		return;

	// if current map dose not match the map set, stop mix map.
	char sBuffer[64];
	char sPresetMap[64];
	GetCurrentMap(sBuffer, sizeof(sBuffer));
	g_hArrayPools.GetString(g_iMapsPlayed, sPresetMap, sizeof(sPresetMap));

	if (!StrEqual(sBuffer, sPresetMap))
	{
		PluginStartInit();
		//g_hLogger.WarnEx("Current map dose not match the map set. Stopping MixMap. Current map: %s, Map set: %s", sBuffer, sPresetMap);
		Call_StartForward(g_hForwardInterrupt);
		Call_Finish();
		return;
	}
	
	HookEntityOutput("info_director", "OnGameplayStart", OnGameplayStart);

	// finished playing. reset.
	if (g_iMapsPlayed >= g_hArrayPools.Length)
	{
		PluginStartInit();
		Call_StartForward(g_hForwardEnd);
		Call_Finish();
		return;
	}

	// let other plugins know what the map *after* this one will be (unless it is the last map)
	g_iMapsPlayed++;
	g_hArrayPools.GetString(g_iMapsPlayed, sBuffer, sizeof(sBuffer));
	Call_StartForward(g_hForwardNext);
	Call_PushString(sBuffer);
	Call_Finish();
}

void PluginStartInit()
{
	g_bMapsetInitialized = false;
	g_iMapsPlayed		 = 0;
	g_iMapsetType        = MapSet_None;
	delete g_hArrayPools;
}

stock void LoadTranslation(const char[] translation)
{
	char sPath[PLATFORM_MAX_PATH], sName[64];
	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("[MixMap] Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}
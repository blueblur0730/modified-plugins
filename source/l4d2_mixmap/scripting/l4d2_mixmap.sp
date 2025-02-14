#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <left4dhooks>
#include <l4d2_source_keyvalues>
#include <colors>
#include <gamedata_wrapper>

#define DEBUG 1

#define TRANSLATION_FILE "l4d2_mixmap.phrases"
#define GAMEDATA_FILE "l4d2_mixmap"
#define ADDRESS_MATCHEXTL4D "g_pMatchExtL4D"
#define SDKCALL_GETALLMISSIONS "MatchExtL4D::GetAllMissions"
#define SDKCALL_ONCHANGEMISSIONVOTE "CDirector::OnChangeMissionVote"
#define SDKCALL_ISFIRSTMAPINSCENARIO "CDirector::IsFirstMapInScenario"
#define DETOUR_RESTORETRANSITIONEDENTITIES "RestoreTransitionedEntities"
#define DETOUR_TRANSITIONRESTORE "CTerrorPlayer::TransitionRestore"

ArrayList
	g_hArrayMissionsAndMaps,			// Stores all missions and their map names in order.
	g_hArrayOfficialMissionsAndMaps,	// Stores all official missions and their map names in order.
	g_hArrayThirdPartyMissionsAndMaps,	// Stores all third party missions and their map names in order.
	g_hArrayPools;						// Stores slected map names.

bool g_bMapsetInitialized;

int
	g_iMapsPlayed,
	g_iMapCount;

// Modules
#include <l4d2_mixmap/setup.sp>
#include <l4d2_mixmap/events.sp>
#include <l4d2_mixmap/actions.sp>
#include <l4d2_mixmap/commands.sp>
#include <l4d2_mixmap/mappool.sp>
#include <l4d2_mixmap/util.sp>
#include <l4d2_mixmap/vote.sp>

public Plugin myinfo =
{
	name = "[L4D2] Mixmap",
	author = "Stabby, Bred, Yuzumi, blueblur",
	description = "Randomly select five maps to build a mixed campaign or match.",
	version = "r3.0",
	url = "https://github.com/blueblur0730/modified-plugins"
};

// ----------------------------------------------------------
// 		Setup
// ----------------------------------------------------------

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
	HookEvents();
	PluginStartInit();

	VT_OnPluginStart();
}

// ----------------------------------------------------------
// 		Global Forwards
// ----------------------------------------------------------
public void OnClientPutInServer(int client)
{
	if (g_bMapsetInitialized)
		CreateTimer(10.0, Timer_ShowMaplist, client);
}

void Timer_ShowMaplist(Handle timer, int client)
{
	if (IsClientInGame(client))
		CPrintToChat(client, "%t", "Auto_Show_Maplist");
}

public void OnPluginEnd() 
{

}

public void OnMapStart()
{
	VT_OnMapStart();
	
	// if current map dose not match the map set, stop mix map.
	char sBuffer[64];
	if (g_bMapsetInitialized)
	{
		char sPresetMap[64];
		GetCurrentMap(sBuffer, sizeof(sBuffer));
		g_hArrayPools.GetString(g_iMapsPlayed, sPresetMap, sizeof(sPresetMap));

		if (!StrEqual(sBuffer, sPresetMap) && g_bMaplistFinalized)
		{
			PluginStartInit();
			CPrintToChatAll("%t", "Differ_Abort");
			Call_StartForward(g_hForwardInterrupt);
			Call_Finish();
			return;
		}
	}

	// let other plugins know what the map *after* this one will be (unless it is the last map)
	if (!g_bMaplistFinalized || g_iMapsPlayed >= g_iMapCount - 1)
		return;

	g_hArrayPools.GetString(g_iMapsPlayed + 1, sBuffer, sizeof(sBuffer));

	Call_StartForward(g_hForwardNext);
	Call_PushString(sBuffer);
	Call_Finish();
}

public void OnMapEnd()
{
	VT_OnMapEnd();
}

void PluginStartInit()
{
	g_bMapsetInitialized = false;
	g_bMaplistFinalized	 = false;

	g_iMapsPlayed		 = 0;
	g_iMapCount			 = 0;
}

void LoadTranslation(const char[] translation)
{
	char sPath[PLATFORM_MAX_PATH], sName[64];
	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("[MixMap] Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}
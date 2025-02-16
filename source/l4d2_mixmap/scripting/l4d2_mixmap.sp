#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <log4sp>
#include <left4dhooks>
#include <l4d2_source_keyvalues>
#include <l4d2_nativevote>
#include <gamedata_wrapper>
#include <colors>

#define LOGGER_NAME "Mixmap"
#define TRANSLATION_FILE "l4d2_mixmap.phrases"
#define GAMEDATA_FILE "l4d2_mixmap"
#define ADDRESS_MATCHEXTL4D "g_pMatchExtL4D"
#define SDKCALL_GETALLMISSIONS "MatchExtL4D::GetAllMissions"
#define SDKCALL_ONCHANGEMISSIONVOTE "CDirector::OnChangeMissionVote"
#define SDKCALL_ISFIRSTMAPINSCENARIO "CDirector::IsFirstMapInScenario"
#define SDKCALL_CLEARTRANSITIONEDLANDMARKNAME "ClearTransitionedLandmarkName"
#define DETOUR_RESTORETRANSITIONEDENTITIES "RestoreTransitionedEntities"
#define DETOUR_TRANSITIONRESTORE "CTerrorPlayer::TransitionRestore"
#define DETOUR_DIRECTORCHANGELEVEL "CDirector::DirectorChangeLevel"
#define DETOUR_CTERRORGAMERULES_ONBEGINCHANGELEVEL "CTerrorGameRules::OnBeginChangeLevel"
#define DETOUR_SURVIVORBOT_ONBEGINCHANGELEVEL "SurvivorBot::OnBeginChangeLevel"
#define DETOUR_CTERRORPLAYER_ONBEGINCHANGELEVEL "CTerrorPlayer::OnBeginChangeLevel"

StringMap g_hMapChapterNames;

ArrayList
	g_hArrayMissionsAndMaps,			// Stores all missions and their map names in order.
	g_hArrayPools;						// Stores slected map names.

Logger g_hLogger;

bool g_bMapsetInitialized;
int g_iMapsPlayed;

enum MapSetType {
	MapSet_Official = 1,
	MapSet_Custom = 2,
	MapSet_Mixtape = 3
}

// Modules
#include <l4d2_mixmap/setup.sp>
#include <l4d2_mixmap/detour.sp>
#include <l4d2_mixmap/events.sp>
#include <l4d2_mixmap/actions.sp>
#include <l4d2_mixmap/commands.sp>
#include <l4d2_mixmap/mappool.sp>
#include <l4d2_mixmap/util.sp>
#include <l4d2_mixmap/vote.sp>

public Plugin myinfo =
{
	name = "[L4D2] Mixmap",
	author = "Stabby, Bred, blueblur",
	description = "Randomly select five maps to build a mixed campaign or match.",
	version = "re1.0",
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
	//LoadTranslation(TRANSLATION_FILE);
	SetUpGameData();

	SetupConVars();
	SetupCommands();
	SetupLogger();
	HookEvents();
	PluginStartInit();
}

public void OnClientPutInServer(int client)
{
	if (g_bMapsetInitialized)
		CreateTimer(10.0, Timer_ShowMaplist, client);
}

void Timer_ShowMaplist(Handle timer, int client)
{
	//if (IsClientInGame(client))
		//CPrintToChat(client, "%t", "Auto_Show_Maplist");
}

public void OnAllPluginsLoaded()
{
	TheDirector = CDirector();
}

public void OnPluginEnd() 
{
	if (g_hDetour_RestoreTransitionedEntities)
	{
		g_hDetour_RestoreTransitionedEntities.Disable(Hook_Pre, DTR_OnRestoreTransitionedEntities);
		delete g_hDetour_RestoreTransitionedEntities;
	}
		
	if (g_hDetour_TransitionRestore)
	{
		g_hDetour_TransitionRestore.Disable(Hook_Post, DTR_CTerrorPlayer_OnTransitionRestore_Post);
		delete g_hDetour_TransitionRestore;
	}

	if (g_hDetour_DirectorChangeLevel)
	{
		g_hDetour_DirectorChangeLevel.Disable(Hook_Pre, DTR_CDirector_OnDirectorChangeLevel);
		delete g_hDetour_DirectorChangeLevel;
	}

	if (g_hDetour_CTerrorGameRules_OnBeginChangeLevel)
	{
		g_hDetour_CTerrorGameRules_OnBeginChangeLevel.Disable(Hook_Pre, DTR_CTerrorGameRules_OnBeginChangeLevel);
		delete g_hDetour_CTerrorGameRules_OnBeginChangeLevel;
	}

	if (g_hDetour_SurvivorBot_OnBeginChangeLevel)
	{
		g_hDetour_SurvivorBot_OnBeginChangeLevel.Disable(Hook_Pre, DTR_SurvivorBots_OnBeginChangeLevel);
		delete g_hDetour_SurvivorBot_OnBeginChangeLevel;
	}

	if (g_hDetour_CTerrorPlayer_OnBeginChangeLevel)
	{
		g_hDetour_CTerrorPlayer_OnBeginChangeLevel.Disable(Hook_Pre, DTR_CTerrorPlayer_OnBeginChangeLevel);
		delete g_hDetour_CTerrorPlayer_OnBeginChangeLevel;
	}
}

public void OnMapStart()
{
	// if current map dose not match the map set, stop mix map.
	char sBuffer[64];
	if (g_bMapsetInitialized)
	{
		char sPresetMap[64];
		GetCurrentMap(sBuffer, sizeof(sBuffer));
		g_hArrayPools.GetString(g_iMapsPlayed, sPresetMap, sizeof(sPresetMap));

		if (!StrEqual(sBuffer, sPresetMap))
		{
			PluginStartInit();

			g_hLogger.WarnEx("Current map dose not match the map set. Stopping MixMap. Current map: %s, Map set: %s", sBuffer, sPresetMap);
			Call_StartForward(g_hForwardInterrupt);
			Call_Finish();
			return;
		}
	}

	// let other plugins know what the map *after* this one will be (unless it is the last map)
	if (!g_bMapsetInitialized || g_iMapsPlayed >= g_hArrayPools.Length)
		return;

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
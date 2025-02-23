#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <log4sp>	// requires log4sp 1.8.0+
#include <midhook>
#include <sourcescramble>
#include <l4d2_source_keyvalues>
#include <l4d2_nativevote>
#include <left4dhooks>
#include <gamedata_wrapper>
#include <colors>

#define PLUGIN_VERSION "re3.0.1"

StringMap g_hMapChapterNames;			// stores the mission name by its corresponding first map name.

ArrayList
	g_hArrayMissionsAndMaps,			// Stores all missions and their map names in order.
	g_hArrayPools,						// Stores slected map names.
	g_hArraySurvivorSets,				// Stores selected survivor sets.
	g_hArrayBlackList,					// Stores blacklisted map names.
	g_hArrayPresetList,					// Stores all preset file names.
	g_hArrayPresetNames;				// Stores all preset names.

Logger g_hLogger;						// for debugging.

bool g_bManullyChoosingMap = false;
bool g_bMapsetInitialized = false;
int g_iMapsPlayed = 0;
MapSetType g_iMapsetType = MapSet_None;
char g_sPresetName[512];

// Modules
#include <l4d2_mixmap/tags.sp>
#include <l4d2_mixmap/setup.sp>
#include <l4d2_mixmap/util.sp>
#include <l4d2_mixmap/hooks.sp>
#include <l4d2_mixmap/actions.sp>
#include <l4d2_mixmap/commands.sp>
#include <l4d2_mixmap/mappool.sp>
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
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}

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
	SetupLogger();
	BuildBlackList(-1);
	LoadFolderFiles(-1);
	PluginStartInit();
}

public void OnAllPluginsLoaded()
{
	g_pTheDirector	   = L4D_GetPointer(POINTER_DIRECTOR);
	if (!g_pTheDirector)
		SetFailState("[Mixmap] Failed to get address of TheDirector.");
}

public void OnClientPutInServer(int client)
{
	if (!g_bMapsetInitialized)
		return;
		
	if (!g_hCvar_NextMapPrint.BoolValue)
		return;

	CPrintToChat(client, "%t", "NotifyClients");
	int userid = GetClientUserId(client);
	CreateTimer(10.0, Timer_Notify, userid);
	CreateTimer(15.0, Timer_ShowMaplist, userid);
}

public void OnMapStart()
{
	if (!g_bMapsetInitialized)
		return;

	// turn off entitis transisition.
	g_hLogger.Trace("### OnMapStart: Blocking restored entitis from transitioning.");
	StoreToAddress(g_bNeedRestore, 0, NumberType_Int8);

	// just in case.
	PrecacheAllModels();

	// if current map dose not match the map set, stop mix map.
	char sBuffer[64];
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
	
	g_iMapsPlayed++;

	// let other plugins know what the map *after* this one will be (unless it is the last map)
	Call_StartForward(g_hForwardNext);
	Call_PushString(sPresetMap);
	Call_Finish();
}

public void OnMapEnd()
{
	if (!g_bMapsetInitialized)
		return;

	// finished playing. reset.
	if (g_iMapsPlayed >= g_hArrayPools.Length)
	{
		g_hLogger.Info("### Stopping MixMap.");
		PluginStartInit();
		Patch(false);

		Call_StartForward(g_hForwardEnd);
		Call_Finish();
		return;
	}
}

public void OnPluginEnd()
{
	delete g_hPatch_BlockRestoring;
	delete g_hMidhook_ChangeCharacter;
	PluginStartInit();

	delete g_hArrayBlackList;
	delete g_hArrayPresetList;
	delete g_hArrayPresetNames;
	delete g_hLogger;
}
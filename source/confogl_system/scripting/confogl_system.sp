#pragma semicolon 1
#pragma newdecls required

#define DEBUG_ALL				   0
#define PLUGIN_VERSION			   "1.3.2"	// 2.4.5 rework

#define VOTE_API_BUILTINVOTE 1		// will work in the future. for now dont turn it off.
#define GAME_LEFT4DEAD2		 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <colors>

#if VOTE_API_BUILTINVOTE
	#tryinclude <builtinvotes>
#else
	#tryinclude <nativevotes>
#endif

#undef REQUIRE_PLUGIN
#include <confogl_system>
#include <l4d2_changelevel>

// Includes here
#include "confogl_system/includes/constants.sp"
#include "confogl_system/includes/functions.sp"
#include "confogl_system/includes/debug.sp"
#include "confogl_system/includes/configs.sp"
#include "confogl_system/includes/customtags.sp"
#include "confogl_system/includes/predictable_unloader.sp"	// Predictable Unloader by Sir

// Modules here
#include "confogl_system/MatchVote.sp"
#include "confogl_system/ReqMatch.sp"
#include "confogl_system/CvarSettings.sp"
#include "confogl_system/PasswordSystem.sp"
#include "confogl_system/BotKick.sp"
#include "confogl_system/ClientSettings.sp"

// Competitive Rework Team:
// Confogl Team, A1m` (for confogl itself)
// vintik, Sir (for match_vote.sp)
// other contributors: Sir, Forgetest, sheo, StarterX4
public Plugin myinfo =
{
	name = "[L4D2/ANY?] Confogl System",
	author = "Competitive Rework Team, blueblur",
	description = "Confogl System that is only used for server management.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	Configs_APL();	  // configs
	RM_APL();	 	  // ReqMatch

	RegPluginLibrary("confogl_system");
	return APLRes_Success;
}

public void OnPluginStart()
{
	// translation file should be the first thing to do. 
	// other wise plugin cant translate the phrases and goes rong.
	LoadTranslation(TRANSLATION_FILE);

	// Plugin functions
	Fns_OnModuleStart();		// functions
	Debug_OnModuleStart();		// debug
	Configs_OnModuleStart();	// configs
	CT_OnModuleStart();			// customtags
	PU_OnPluginStart();		// Predictable Unloader

	// Modules
	MV_OnModuleStart();	   // MatchVote
	RM_OnModuleStart();	   // ReqMatch
	CLS_OnModuleStart();	// ClientSettings
	CVS_OnModuleStart();	// CvarSettings
	PS_OnModuleStart();	   // PasswordSystem
	BK_OnModuleStart();	   // BotKick

	// Other
	AddCustomServerTag("confogl");
}

public void OnPluginEnd()
{
	MV_OnPluginEnd();	 // MatchVote
	CVS_OnModuleEnd();	  // CvarSettings
	PS_OnModuleEnd();	 // PasswordSystem

	// Other
	RemoveCustomServerTag("confogl");
}

public void OnMapStart()
{
	RM_OnMapStart();	// ReqMatch
}

public void OnMapEnd()
{
	PS_OnMapEnd();	  // PasswordSystem
}

public void OnConfigsExecuted()
{
	MV_OnConfigsExecuted();	// MatchVote
	CVS_OnConfigsExecuted();	// CvarSettings
}

public void OnClientDisconnect(int client)
{
	RM_OnClientDisconnect(client);	  // ReqMatch
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	// BotKick
	if (!BK_OnClientConnect(client))
		return false;

	return true;
}

public void OnClientPutInServer(int client)
{
	RM_OnClientPutInServer();	 		// ReqMatch
	PS_OnClientPutInServer(client);	   	// PasswordSystem
}

public void OnLibraryAdded(const char[] name)
{
	if (strcmp(name, "l4d2_changelevel") == 0)
		g_bIsChangeLevelAvailable = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if (strcmp(name, "l4d2_changelevel") == 0)
		g_bIsChangeLevelAvailable = false;
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	if (IsPluginEnabled())
		CreateTimer(0.1, OFSLA_ForceMobSpawnTimer);

	return Plugin_Continue;
}

static Action OFSLA_ForceMobSpawnTimer(Handle hTimer)
{
	// Workaround to make tank horde blocking always work
	// Makes the first horde always start 100s after survivors leave saferoom
	static ConVar hCvarMobSpawnTimeMin = null;
	static ConVar hCvarMobSpawnTimeMax = null;

	if (hCvarMobSpawnTimeMin == null)
	{
		hCvarMobSpawnTimeMin = FindConVar("z_mob_spawn_min_interval_normal");
		hCvarMobSpawnTimeMax = FindConVar("z_mob_spawn_max_interval_normal");
	}

	float fRand = GetRandomFloat(hCvarMobSpawnTimeMin.FloatValue, hCvarMobSpawnTimeMax.FloatValue);
	L4D2_CTimerStart(L4D2CT_MobSpawnTimer, fRand);

	return Plugin_Stop;
}

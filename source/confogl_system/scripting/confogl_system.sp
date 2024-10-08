#pragma semicolon 1
#pragma newdecls required

#define DEBUG_ALL				   0
#define PLUGIN_VERSION			   "1.3.5"	// 2.4.5 rework

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
#include <confogl>
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
// other contributors: Sir, Forgetest, sheo, StarterX4 and so on...
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

	RegPluginLibrary("confogl");
	return APLRes_Success;
}

public void OnPluginStart()
{
	// translation file should be the first thing to do. 
	// other wise plugin cant translate the phrases and goes rong.
	LoadTranslation(TRANSLATION_FILE);

	// here we retrieve the plugin path for predictable unloader to use.
	char sPluginName[PLATFORM_MAX_PATH];
	GetPluginFilename(INVALID_HANDLE, sPluginName, sizeof(sPluginName));

	// Plugin functions
	Fns_OnModuleStart();				// functions
	Debug_OnModuleStart();				// debug
	Configs_OnModuleStart();			// configs
	CT_OnModuleStart();					// customtags
	PU_OnPluginStart(sPluginName);		// Predictable Unloader

	// Modules
	MV_OnModuleStart();	   	// MatchVote
	RM_OnModuleStart();	   	// ReqMatch
	CLS_OnModuleStart();	// ClientSettings
	CVS_OnModuleStart();	// CvarSettings
	PS_OnModuleStart();	   	// PasswordSystem
	BK_OnModuleStart();	   	// BotKick

	// Other
	AddCustomServerTag("confogl");
}

public void OnPluginEnd()
{
	MV_OnPluginEnd();	 	// MatchVote
	CVS_OnModuleEnd();	  	// CvarSettings
	PS_OnModuleEnd();	 	// PasswordSystem
	PU_OnPluginEnd();	 	// Predictable Unloader

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
	MV_OnConfigsExecuted();		// MatchVote
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
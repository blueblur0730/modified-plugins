#pragma semicolon 1
#pragma newdecls required

#define DEBUG_ALL				   0
#define PLUGIN_VERSION			   "r1.7.1"	// 2.4.5 rework

#include <sourcemod>
#include <sdktools>
#include <colors>

#undef REQUIRE_PLUGIN
#include <l4d2_changelevel>

bool 
	g_bIsChangeLevelAvailable = false,
	RM_bIsMatchModeLoaded = false,
	RM_bIsLoadingConfig   = false;

native void L4D_LobbyUnreserve();

// Basic helper here.
#include "confogl_system/includes/constants.sp"
#include "confogl_system/includes/functions.sp"
#include "confogl_system/includes/debug.sp"
#include "confogl_system/includes/configs.sp"
#include "confogl_system/includes/customtags.sp"
#include "confogl_system/includes/predictable_unloader.sp"	// Predictable Unloader by Sir
#include "confogl_system/includes/voting.sp"				// nativevote by Powerlord, fdxx. This built-in version is to make sure our vote can work as usual.

// Main Modules here.
#include "confogl_system/ReqMatch.sp"
#include "confogl_system/MatchVote.sp"
#include "confogl_system/CvarSettings.sp"
#include "confogl_system/PasswordSystem.sp"
#include "confogl_system/BotKick.sp"
#include "confogl_system/ClientSettings.sp"
#include "confogl_system/UnreserveLobby.sp"

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
	UL_APL();		  // UnreserveLobby
	CVS_APL();		  // CvarSettings

	MarkNativeAsOptional("L4D_LobbyUnreserve");

	// make it consistent.
	RegPluginLibrary("confogl");
	return APLRes_Success;
}

public void OnPluginStart()
{
	// translation file should be the first thing to do. 
	// other wise plugin cant translate the phrases and goes wrong.
	LoadTranslation(TRANSLATION_FILE);

	// Plugin functions
	Fns_OnModuleStart();				// functions
	Debug_OnModuleStart();				// debug
	Configs_OnModuleStart();			// configs
	CT_OnModuleStart();					// customtags
	PU_OnPluginStart();					// Predictable Unloader
	VT_OnPluginStart();					// Voting

	// Modules
	MV_OnModuleStart();	   	// MatchVote
	RM_OnModuleStart();	   	// ReqMatch
	CLS_OnModuleStart();	// ClientSettings
	CVS_OnModuleStart();	// CvarSettings
	PS_OnModuleStart();	   	// PasswordSystem
	BK_OnModuleStart();	   	// BotKick
	UL_OnModuleStart();		// UnreserveLobby

	// Other
	AddCustomServerTag("confogl_system");
}

public void OnPluginEnd()
{
	MV_OnPluginEnd();	 	// MatchVote
	CVS_OnModuleEnd();	  	// CvarSettings
	PS_OnModuleEnd();	 	// PasswordSystem
	PU_OnPluginEnd();	 	// Predictable Unloader

	// Other
	RemoveCustomServerTag("confogl_system");
}

public void OnMapStart()
{
	RM_OnMapStart();	// ReqMatch
	VT_OnMapStart();	// Voting
}

public void OnMapEnd()
{
	PS_OnMapEnd();	  // PasswordSystem
	VT_OnMapEnd();	  // Voting
}

public void OnConfigsExecuted()
{
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
	UL_OnClientPutInServer();			// UnreserveLobby
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
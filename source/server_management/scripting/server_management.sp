#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.1.1"

// define the macros to compile the part you need
#define MODULE_PLAYERINFO 1
#define MODULE_WELCOMEMSG 1
#define MODULE_CHANGELOG 1
#define MODULE_HOURSLIMITER 1

#define APP_L4D2 550
#define STEAMID_SIZE 32

#include <sourcemod>
#include <sdktools>
#include <SteamWorks>
#include <colors>
#include <geoip>
#include <left4dhooks>
#undef REQUIRE_PLUGIN
#include <readyup>

bool
	g_bIsLerpmonitorAvailable = false,
    g_bReadyUpAvailable = false;

bool g_bIsInReady = true;

#include "server_management/includes/util.inc"

#if MODULE_WELCOMEMSG
	#include "server_management/welcome_msg.inc"
#endif

#if MODULE_PLAYERINFO
	#include "server_management/player_info.inc"
#endif

#if MODULE_HOURSLIMITER
	#include "server_management/hours_limiter.inc"
#endif

#if MODULE_CHANGELOG
	#include "server_management/changelog.inc"
#endif

public Plugin myinfo =
{
	name = "Server Management",
	author = "blueblur, credits to TouchMe, stars",
	description = "Intergrated server management method.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();

	if (engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

#if MODULE_HOURSLIMITER
	HL_APL();
#endif

#if MODULE_PLAYERINFO
	PL_APL();
#endif

	RegPluginLibrary("server_management");
	return APLRes_Success;
}

public void OnPluginStart()
{
#if MODULE_WELCOMEMSG
    WM_OnPluginStart();
#endif

#if MODULE_PLAYERINFO
    PI_OnPluginStart();
#endif

#if MODULE_HOURSLIMITER
    HL_OnPluginStart();
#endif

#if MODULE_CHANGELOG
    CL_OnPluginStart();
#endif
}

public void OnAllPluginsLoaded()
{
	g_bReadyUpAvailable = LibraryExists("readyup");
#if MODULE_CHANGELOG
	CL_OnAllPluginsLoaded();
#endif
}

public void OnClientPostAdminCheck(int iClient)
{
#if MODULE_HOURSLIMITER
	HL_OnClientPostAdminCheck(iClient);
#endif
}

public void OnClientConnected(int iClient)
{
#if MODULE_PLAYERINFO
	PI_OnClientConnected(iClient);
#endif
}

public void OnClientPutInServer(int client)
{
#if MODULE_WELCOMEMSG
	WM_OnClientPutInServer(client);
#endif

#if MODULE_PLAYERINFO
	PI_OnClientPutInServer(client);
#endif
}

public void SteamWorks_OnValidateClient(int iOwnerAuthId, int iAuthId)
{
#if MODULE_PLAYERINFO
	PI_SteamWorks_OnValidateClient(iAuthId);
#endif
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "readyup")) g_bReadyUpAvailable = false;
	if (StrEqual(name, "lerpmonitor")) g_bIsLerpmonitorAvailable = false;
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "readyup")) g_bReadyUpAvailable = true;
	if (StrEqual(name, "lerpmonitor")) g_bIsLerpmonitorAvailable = true;
}

public void OnReadyUpInitiate()
{
	g_bIsInReady = true;
}

public void OnRoundIsLive()
{
	g_bIsInReady = false;
}
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <colors>
#include <gamedata_wrapper>

#define GAMEDATA_FILE "server_management"
#define STEAMID_SIZE 32

bool 
	g_bReadyUpAvailable = false,
	g_bIsInReady = false,
	g_bCoopSystem = false,
	g_bIsConfoglAvailable = false,
	g_bChangeLevelAvailable = false,
	g_bNekoSpecials = false;

Handle g_hSDKCall_fSetCampaignScores = null;

// utilities here
#include "server_management/includes/util.sp"

// Modules here
#include "server_management/welcome_msg.sp"
#include "server_management/player_info.sp"
#include "server_management/restarter.sp"
#include "server_management/bequiet.sp"
#include "server_management/prefix.sp"
#include "server_management/advertisement.sp"
#include "server_management/lerpmonitor.sp"
#include "server_management/vote_manager.sp"
#include "server_management/hours_limiter.sp"
//#include "server_management/changelog.sp"

#define PLUGIN_VERSION "r1.7"

public Plugin myinfo =
{
	name = "[L4D2] Server Management",
	author = "blueblur, Many Others.",
	description = "Intergrated Server Management.",
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

	_lerpmonitor_AskPluginLoad2(late);
	_advertisement_AskPluginLoad2(late);
	_player_info_AskPluginLoad2();
	_hours_limiter_AskPluginLoad2();
	RegPluginLibrary("server_management");
	return APLRes_Success;
}

public void OnPluginStart()
{
	IniGameData();
	CreateConVar("server_management_version", PLUGIN_VERSION, "Server Management Version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
    _welcome_message_OnPluginStart();
    _player_info_OnPluginStart();
	_restarter_OnPluginStart();
	_bequiet_OnPluginStart();
	_prefix_OnPluginStart();
	_advertisement_OnPluginStart();
	_lerpmonitor_OnPluginStart();
	_vote_manager_OnPluginStart();
    _hours_limiter_OnPluginStart();
}

public void OnPluginEnd()
{
	_restarter_OnPluginEnd();
	_prefix_OnPluginEnd();
	_advertisement_OnPluginEnd();
	_vote_manager_OnPluginEnd();
}

public void OnConfigsExecuted()
{
	_restarter_OnConfigsExecuted();
	_prefix_OnConfigsExecuted();
}

public void OnMapStart() 
{
	_restarter_OnMapStart();
	_prefix_OnMapStart();
	_lerpmonitor_OnMapStart();
	_advertisement_OnMapStart();
}

public void OnMapEnd()
{
	_restarter_OnMapEnd();
	_prefix_OnMaEnd();
	_lerpmonitor_OnMapEnd();
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("coop_system"))	g_bCoopSystem = true;
	if (LibraryExists("readyup"))		g_bReadyUpAvailable = true;
	if (LibraryExists("confogl_system"))	g_bIsConfoglAvailable = true;
	if (LibraryExists("l4d2_changelevel"))	g_bChangeLevelAvailable = true;
	if (LibraryExists("nekospecials"))	g_bNekoSpecials = true;
}

public void OnClientPostAdminCheck(int iClient)
{
	_hours_limiter_OnClientPostAdminCheck(iClient);
}

public void OnClientConnected(int iClient)
{
	_player_info_OnClientConnected(iClient);
	_restarter_OnClientConnected(iClient);
}

public void OnClientPutInServer(int client)
{
	_welcome_message_OnClientPutInServer(client);
	_player_info_OnClientPutInServer(client);
	_lerpmonitor_OnClientPutInServer(client);
	_advertisement_OnClientPutInServer(client);
}

public void OnClientSettingsChanged(int client)
{
	_lerpmonitor_OnClientSettingsChanged(client);
}

public void SteamWorks_OnValidateClient(int iOwnerAuthId, int iAuthId)
{
	_player_info_SteamWorks_OnValidateClient(iAuthId);
}

public void OnLibraryRemoved(const char[] name)
{
	if (strcmp(name, "coop_system") == 0) g_bCoopSystem = false;
	if (strcmp(name, "readyup") == 0) g_bReadyUpAvailable = false;
	if (strcmp(name, "confogl_system") == 0) g_bIsConfoglAvailable = false;
	if (strcmp(name, "l4d2_changelevel") == 0) g_bChangeLevelAvailable = false;
	if (strcmp(name, "nekospecials") == 0) g_bNekoSpecials = false;
}

public void OnLibraryAdded(const char[] name)
{
	if (strcmp(name, "coop_system") == 0) g_bCoopSystem = true;
	if (strcmp(name, "readyup") == 0) g_bReadyUpAvailable = true;
	if (strcmp(name, "confogl_system") == 0) g_bIsConfoglAvailable = true;
	if (strcmp(name, "l4d2_changelevel") == 0) g_bChangeLevelAvailable = true;
	if (strcmp(name, "nekospecials") == 0) g_bNekoSpecials = true;
}

public void OnReadyUpInitiate()
{
	g_bIsInReady = true;
}

public void OnRoundIsLive()
{
	g_bIsInReady = false;
}

void IniGameData()
{
    GameDataWrapper gd = new GameDataWrapper(GAMEDATA_FILE);

	SDKCallParamsWrapper params[] = {{SDKType_PlainOldData, SDKPass_Plain}, {SDKType_PlainOldData, SDKPass_Plain}};
	g_hSDKCall_fSetCampaignScores = gd.CreateSDKCallOrFail(SDKCall_GameRules, SDKConf_Signature, "CTerrorGameRules::SetCampaignScores", params, sizeof(params));

    delete gd;
}
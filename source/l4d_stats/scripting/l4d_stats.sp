#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
//#include <clientprefs>	// do we need this?
#include <sdktools>
#include <colors>
#undef REQUIRE_PLUGIN
#include <adminmenu>

// here to define the global variables.
#include "l4d_stats/globals.inc"

// Plugin Info
public Plugin myinfo =
{
	name = "[L4D/L4D2] Custom Player Statistics",
	author = "Mikko Andersson (muukis), blueblur",
	version = PLUGIN_VERSION,
	description = "Player Stats and Ranking for Left 4 Dead (2).",
	url = "https://github.com/blueblur0730/modified-plugins"
};

// Modules here
#include "l4d_stats/utils.inc"
#include "l4d_stats/setup.inc"
#include "l4d_stats/commands.inc"
#include "l4d_stats/menus.inc"
#include "l4d_stats/events.inc"
#include "l4d_stats/dbi.inc"
#include "l4d_stats/actions.inc"
#include "l4d_stats/timers.inc"

// here to define the include functions.
#include "l4d_stats/natives.inc"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead && test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2 and Left 4 Dead.");
		return APLRes_SilentFailure;
	}

	if (test == Engine_Left4Dead)
		g_bLeft4Dead = true;

	if (test == Engine_Left4Dead2)
		g_bLeft4Dead2 = true;

	CreateNatives();

	RegPluginLibrary("l4d_stats");
	return APLRes_Success;
}

// Here we go!
public void OnPluginStart()
{
	g_bCommandsRegistered = false;

	// load translation here
	LoadTranslation(TRANSLATION_FILE);

	// setup all convars here
	SetupConVars();

	// setup all commands here
	RegCommands();

	// Make that config!
	AutoExecConfig(true, "l4d_stats");

	// hook all events here
	HookEvents();

	// Startup the plugin's timers
	// CreateTimer(1.0, InitPlayers); // Called in OnMapStart
	CreateTimer(60.0, Timer_UpdatePlayers, _, TIMER_REPEAT);
	g_hUpdateTimer = CreateTimer(g_hCvar_UpdateRate.FloatValue, Timer_ShowTimerScore, _, TIMER_REPEAT);

	// Gamemode
	g_hCvar_Gamemode.GetString(g_sCurrentGamemode, sizeof(g_sCurrentGamemode));
	g_iCurrentGamemodeID = GetCurrentGamemodeID();

	// RegConsoleCmd("l4d_stats_test", cmd_StatsTest);

	// initialize stringmaps
	IniStringMaps();

	TopMenu topmenu;
	if (LibraryExists("adminmenu") && (topmenu = GetAdminTopMenu()) != null)
		OnAdminMenuReady(topmenu);

	// Initialize SDKCalls
	IniSDKCalls();

	// prechae resources
	PrechaeResources();
}

public void OnConfigsExecuted()
{
	g_hCvar_DbTagPrefix.GetString(g_sDbPrefix, sizeof(g_sDbPrefix));

	// Init MySQL connections
	if (!ConnectDB())
	{
		SetFailState("Connecting to database failed. Read error log for further details.");
		return;
	}

	if (g_bCommandsRegistered)
		return;

	g_bCommandsRegistered = true;

	// Read the settings etc from the database.
	ReadDb();
}

public void OnLibraryAdded(const char[] name)
{
	TopMenu topmenu = null;
	if (StrEqual(name, "adminmenu") && (topmenu = GetAdminTopMenu()) != null)
		OnAdminMenuReady(topmenu);
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
		delete g_hTM_RankAdminMenu;
}

// Reset all boolean variables when a map changes.
public void OnMapStart()
{
	g_hCvar_Gamemode.GetString(g_sCurrentGamemode, sizeof(g_sCurrentGamemode));
	g_iCurrentGamemodeID = GetCurrentGamemodeID();
	ResetVars();
}

// Init player on connect, and update total rank and client rank.
public void OnClientPostAdminCheck(int client)
{
	if (!db)
		return;

	InitializeClientInf(client);
	g_iPostAdminCheckRetryCounter[client] = 0;

	if (IsClientBot(client))
		return;

	CreateTimer(1.0, Timer_ClientPostAdminCheck, client);
}

public void OnPluginEnd()
{
	if (!db)
		return;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsClientBot(i))
		{
			switch (GetClientTeam(i))
			{
				case TEAM_SURVIVORS:
					InterstitialPlayerUpdate(i);
				case TEAM_INFECTED:
					DoInfectedFinalChecks(i);
			}
		}
	}

	delete db;
	g_bCommandsRegistered = false;

	// if (ClearPlayerMenu != INVALID_HANDLE)
	//{
	//	CloseHandle(ClearPlayerMenu);
	//	ClearPlayerMenu = INVALID_HANDLE;
	// }

	ResetVars();
	delete g_hTM_RankAdminMenu;
	DeleteStringMaps();
}

// Update the player's interstitial stats, since they may have
// gotten points between the last update and when they disconnect.
public void OnClientDisconnect(int client)
{
	InitializeClientInf(client);
	g_iPlayerRankVote[client] = RANKVOTE_NOVOTE;
	g_bClientRankMute[client] = false;

	if (g_hTimerRankChangeCheck[client] != null)
		delete g_hTimerRankChangeCheck[client];

	if (IsClientBot(client))
		return;

	if (g_fMapTimingStartTime >= 0.0)
	{
		char ClientID[MAX_LINE_WIDTH];
		GetClientRankAuthString(client, ClientID, sizeof(ClientID));

		g_hMapTimingSurvivors.Remove(ClientID);
		g_hMapTimingInfected.Remove(ClientID);
	}

	if (IsClientInGame(client))
	{
		switch (GetClientTeam(client))
		{
			case TEAM_SURVIVORS:
				InterstitialPlayerUpdate(client);
			case TEAM_INFECTED:
				DoInfectedFinalChecks(client);
		}
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			return;
	}

	// If we get this far, ALL HUMAN PLAYERS LEFT THE SERVER
	g_bCampaignOver = true;

	if (g_hRankVoteTimer != null)
		delete g_hRankVoteTimer;
}

stock void LoadTranslation(const char[] translation)
{
	char
		sPath[PLATFORM_MAX_PATH],
		sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}
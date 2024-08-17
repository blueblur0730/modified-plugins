#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

// here to define the global variables.
#include "l4d_stats/globals.inc"

// Plugin Info
public Plugin myinfo =
{
	name = "[L4D/L4D2] Custom Player Stats",
	author = "Mikko Andersson (muukis), blueblur",
	version = PLUGIN_VERSION,
	description = "Player Stats and Ranking for Left 4 Dead and Left 4 Dead 2.",
	url = "http://www.sourcemod.com/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead && test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2 and Left 4 Dead.");
		return APLRes_SilentFailure;
	}

	RegPluginLibrary("l4d_stats");
	return APLRes_Success;
}

// Modules here
#include "l4d_stats/setup.inc"
#include "l4d_stats/commands.inc"
#include "l4d_stats/menus.inc"
#include "l4d_stats/events.inc"
#include "l4d_stats/dbi.inc"
#include "l4d_stats/actions.inc"
#include "l4d_stats/timers.inc"
#include "l4d_stats/utils.inc"

// Here we go!
public void OnPluginStart()
{
	g_bCommandsRegistered		= false;

	EngineVersion ServerVersion = GetEngineVersion();

	// setup all convars here
	SetupConVars(ServerVersion);

	// setup all commands here
	RegCommands();

	// Make that config!
	AutoExecConfig(true, "l4d_stats");

	// hook all events here
	HookEvents(ServerVersion);

	// Startup the plugin's timers
	// CreateTimer(1.0, InitPlayers); // Called in OnMapStart
	CreateTimer(60.0, Timer_UpdatePlayers, INVALID_HANDLE, TIMER_REPEAT);
	g_hUpdateTimer = CreateTimer(GetConVarFloat(g_hCvar_UpdateRate), Timer_ShowTimerScore, INVALID_HANDLE, TIMER_REPEAT);

	// Gamemode
	g_hCvar_Gamemode.GetString(g_sCurrentGamemode, sizeof(g_sCurrentGamemode));
	g_iCurrentGamemodeID = GetCurrentGamemodeID();
	SetCurrentGamemodeName();

	// RegConsoleCmd("l4d_stats_test", cmd_StatsTest);

	// initialize stringmaps
	IniStringMaps();

	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(topmenu);

	// Initialize SDKCalls
	IniSDKCalls();

	// prechae resources
	PrechaeResources(ServerVersion);
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

// Reset all boolean variables when a map changes.
public void OnMapStart()
{
	GetConVarString(g_hCvar_Gamemode, g_sCurrentGamemode, sizeof(g_sCurrentGamemode));
	g_iCurrentGamemodeID = GetCurrentGamemodeID();
	SetCurrentGamemodeName();
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

	int maxplayers = MaxClients;

	for (int i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
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

	int maxplayers = MaxClients;

	for (int i = 1; i <= maxplayers; i++)
	{
		if (i != client && IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			return;
	}

	// If we get this far, ALL HUMAN PLAYERS LEFT THE SERVER
	g_bCampaignOver = true;

	if (g_hRankVoteTimer != null)
		delete g_hRankVoteTimer;
}
#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <left4dhooks>	  // to get gamemode more efficiently
#undef REQUIRE_PLUGIN
#include <readyup>

ConVar
	g_hcvarSwitch,
	g_hcvarWaitTime,
	g_hcvarPrintRound,
	g_hcvarPrintRoundWaitTime,
	g_hcvarMoreLine,
	g_hcvarHostname,
	g_hcvarMaxSlots;

bool
	g_bReadyUpAvailable,
	g_bIsInReady = true;

public Plugin myinfo =
{
	name = "Server Welcome Message",
	author = "blueblur",
	description = "Welcome the user, query the info",
	version	= "1.3.2",
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_svinfo", Cmd_svInfo, "Get server info");

	g_hcvarSwitch = CreateConVar("welcome_message_switch", "1", "Turn on the welcome");
	g_hcvarWaitTime	= CreateConVar("welcome_wait_time", "5.0", "Wait this time to print the welcome message");
	g_hcvarPrintRound = CreateConVar("welcome_print_round_status", "1", "Print the round status");
	g_hcvarPrintRoundWaitTime = CreateConVar("welcome_print_round_wait_time", "2.0", "Wait this time to print round status");
	g_hcvarMoreLine	= CreateConVar("welcome_more_line", "1", "Optional. If you want to print more message on client connected. set 0 to turn off.");

	g_hcvarHostname	= FindConVar("hostname");
	g_hcvarMaxSlots	= FindConVar("mv_maxplayers");

	LoadTranslations("welcome_msg.phrases");
}

public void OnAllPluginsLoaded()
{
	g_bReadyUpAvailable = LibraryExists("readyup");
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "readyup")) g_bReadyUpAvailable = false;
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "readyup")) g_bReadyUpAvailable = true;
}

public void OnReadyUpInitiate()
{
	g_bIsInReady = true;
}

public void OnRoundIsLive()
{
	g_bIsInReady = false;
}

public void OnClientPutInServer(int client)
{
	if (g_hcvarSwitch.BoolValue && IsValidClient(client))
		CreateTimer(g_hcvarWaitTime.FloatValue, Timer_WelcomeMessage, client);
}

public Action Timer_WelcomeMessage(Handle Timer, int client)
{
	char name[128];
	GetClientName(client, name, sizeof(name));
	CPrintToChat(client, "%t", "Message", name);

	if (g_hcvarMoreLine.IntValue != 0)
	{
		char buffer[128];
		for (int i = 1; i < g_hcvarMoreLine.IntValue; i++)
		{
			CycleCount(buffer, sizeof(buffer), i);
			CPrintToChat(client, "%t", buffer);
		}
	}

	if (g_hcvarPrintRound.BoolValue)
		CreateTimer(g_hcvarPrintRoundWaitTime.FloatValue, Timer_RoundStatus, client);

	return Plugin_Handled;
}

public Action Timer_RoundStatus(Handle Timer, int client)
{
	char Buffer[128], Mapname[128];
	g_hcvarHostname.GetString(Buffer, sizeof(Buffer));
	GetCurrentMap(Mapname, sizeof(Mapname));

	if (g_hcvarMaxSlots == null)	// in case you dont have match_vote.smx
		g_hcvarMaxSlots = FindConVar("sv_maxplayers");

	CPrintToChatEx(client, client, "%t", "Header", Buffer);
	CPrintToChatEx(client, client, "%t", "PlayerNum", (GetTotalPlayers() == g_hcvarMaxSlots.IntValue) ? "{green}" : "{olive}", GetTotalPlayers(), g_hcvarMaxSlots.IntValue);
	CPrintToChatEx(client, client, "%t", "MapName", Mapname);

	if (L4D_IsVersusMode() || L4D2_IsScavengeMode())
	{
		char firsthalf[64], secondhalf[64], round[16];
		Format(firsthalf, sizeof(firsthalf), "%t", "FirstHalf");
		Format(secondhalf, sizeof(secondhalf), "%t", "SecondHalf");
		Format(round, sizeof(round), "#R%d / ", GetScavengeRoundNumber());

		CPrintToChatEx(client, client,  "%t", "GameMode_RoundStatus", GetGameModeString(client), 
		(L4D2_IsScavengeMode()) ? round : "", 
		(!InSecondHalfOfRound()) ? firsthalf : secondhalf);
	}
	else if (L4D2_IsGenericCooperativeMode())
	{
		char difficulty[64];
		ConVar hdifficulty = FindConVar("z_difficulty");
		hdifficulty.GetString(difficulty, sizeof(difficulty));
		CPrintToChatEx(client, client, "%t", "GameMode_Coop", GetGameModeString(client), difficulty);
	}
	//else if (L4D_IsSurvivalMode())		// not this time.
		//CPrintToChatEx(client, client, "%t", "GameMode_Survival", GetGameModeString(client));

	if (g_bReadyUpAvailable)
	{
		CPrintToChatEx(client, client, "%t", "ReadyUpStatus", ReadyUpStatus(client));
		CPrintToChatEx(client, client, "%t", "ReadyUpCfgNameStatus", ReadyUpCfgNameStatus(client));
	}

	return Plugin_Handled;
}

public Action Cmd_svInfo(int client, int arg)
{
	char Buffer[128], Mapname[128];
	g_hcvarHostname.GetString(Buffer, sizeof(Buffer));
	GetCurrentMap(Mapname, sizeof(Mapname));

	if (g_hcvarMaxSlots == null)	// in case you dont have match_vote.smx
		g_hcvarMaxSlots = FindConVar("sv_maxplayers");

	CPrintToChatEx(client, client, "%t", "Header", Buffer);
	CPrintToChatEx(client, client, "%t", "PlayerNum",(GetTotalPlayers() == g_hcvarMaxSlots.IntValue) ? "{green}" : "{olive}", GetTotalPlayers(), g_hcvarMaxSlots.IntValue);
	CPrintToChatEx(client, client, "%t", "MapName", Mapname);

	if (L4D_GetGameModeType() == GAMEMODE_VERSUS || L4D_GetGameModeType() == GAMEMODE_SCAVENGE)
	{
		char firsthalf[64], secondhalf[64], round[16];
		Format(firsthalf, sizeof(firsthalf), "%t", "FirstHalf");
		Format(secondhalf, sizeof(secondhalf), "%t", "SecondHalf");
		Format(round, sizeof(round), "#R%d / ", GetScavengeRoundNumber());

		CPrintToChatEx(client, client, "%t", "GameMode_RoundStatus", GetGameModeString(client),
		(L4D_GetGameModeType() == GAMEMODE_SCAVENGE ? round : ""),
		(!InSecondHalfOfRound() ? firsthalf : secondhalf));
	}
	else
		CPrintToChatEx(client, client, "%t", "GameMode", GetGameModeString(client));

	if (g_bReadyUpAvailable)
	{
		CPrintToChatEx(client, client, "%t", "ReadyUpStatus", ReadyUpStatus(client));
		CPrintToChatEx(client, client, "%t", "ReadyUpCfgNameStatus", ReadyUpCfgNameStatus(client));
	}

	return Plugin_Handled;
}

stock int GetTotalPlayers()
{
	int players;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) > 1 && !IsFakeClient(i))
			players++;
	}

	return players;
}

stock void CycleCount(char[] buffer, int maxlength, int count)
{
	Format(buffer, maxlength, "MoreMessage%d", count);
}

stock char[] GetGameModeString(int client)
{
	char unknown[64], coop[64], versus[64], scavenge[64], survival[64];
	SetGlobalTransTarget(client);
	Format(unknown, sizeof(unknown), "%t", "unknown");
	Format(coop, sizeof(coop), "%t", "coop");
	Format(versus, sizeof(versus), "%t", "versus");
	Format(scavenge, sizeof(scavenge), "%t", "scavenge");
	Format(survival, sizeof(survival), "%t", "survival");

	switch (L4D_GetGameModeType())
	{
		case GAMEMODE_UNKNOWN: return unknown;
		case GAMEMODE_COOP: return coop;
		case GAMEMODE_VERSUS: return versus;
		case GAMEMODE_SCAVENGE: return scavenge;
		case GAMEMODE_SURVIVAL: return survival;
	}

	return unknown;
}

stock char[] ReadyUpStatus(int client)
{
	char inready[32], outready[32];
	SetGlobalTransTarget(client);

	Format(inready, sizeof(inready), "%t", "InReady");
	Format(outready, sizeof(outready), "%t", "OutReady");

	return g_bIsInReady ? inready : outready;
}

stock char[] ReadyUpCfgNameStatus(int client)
{
	char   config[64], empty[64];
	bool   none		= false;
	ConVar hCfgName = FindConVar("l4d_ready_cfg_name");
	SetGlobalTransTarget(client);

	Format(empty, sizeof(empty), "%t", "Empty");
	hCfgName.GetString(config, sizeof(config));

	if (StrEqual(config, "", false))
		none = true;

	return none ? empty : config;
}

stock int GetScavengeRoundNumber()
{
	return GameRules_GetProp("m_nRoundNumber");
}

stock bool InSecondHalfOfRound()
{
	return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound"));
}

stock bool IsValidClient(int client)
{ 
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client)) ? true : false; 
}

#if defined _server_management_welcome_msg_included
 #endinput
#endif
#define _server_management_welcome_msg_included

#define TRANSLATIONS_WELCOME_MSG       "welcome_msg.phrases"

/* welcome_msg */
static ConVar
	wm_cvSwitch, wm_cvWaitTime, wm_cvPrintRound, wm_cvPrintRoundWaitTime, wm_cvMoreLine, wm_cvHostname, wm_cvMaxSlots;

void WM_OnPluginStart()
{
	RegConsoleCmd("sm_svinfo", Cmd_svInfo, "Get server info");

	wm_cvSwitch = CreateConVar("welcome_message_switch", "1", "Turn on the welcome");
	wm_cvWaitTime	= CreateConVar("welcome_wait_time", "5.0", "Wait this time to print the welcome message");
	wm_cvPrintRound = CreateConVar("welcome_print_round_status", "1", "Print the round status");
	wm_cvPrintRoundWaitTime = CreateConVar("welcome_print_round_wait_time", "2.0", "Wait this time to print round status");
	wm_cvMoreLine	= CreateConVar("welcome_more_line", "1", "Optional. If you want to print more message on client connected. set 0 to turn off.");

	wm_cvHostname	= FindConVar("hostname");
	wm_cvMaxSlots	= FindConVar("mv_maxplayers");

	LoadTranslations(TRANSLATIONS_WELCOME_MSG);
}

void WM_OnClientPutInServer(int client)
{
	if (wm_cvSwitch.BoolValue && IsValidClient(client) && client > 0 && IsClientInGame(client) && !IsFakeClient(client))
		CreateTimer(wm_cvWaitTime.FloatValue, Timer_WelcomeMessage, client);
}

public Action Timer_WelcomeMessage(Handle Timer, int client)
{
	char name[128];
	if(client > 0 && IsValidClient(client) && !IsFakeClient(client)&& client > 0 && IsClientInGame(client))
	{
		GetClientName(client, name, sizeof(name));
		CPrintToChat(client, "%t", "Message", name);

		if (wm_cvMoreLine.IntValue != 0)
		{
			char buffer[128];
			for (int i = 1; i < wm_cvMoreLine.IntValue; i++)
			{
				CycleCount(buffer, sizeof(buffer), i);
				CPrintToChat(client, "%t", buffer);
			}
		}
		
		if (wm_cvPrintRound.BoolValue && IsValidClient(client) && client > 0 && IsClientInGame(client) && !IsFakeClient(client))
			CreateTimer(wm_cvPrintRoundWaitTime.FloatValue, Timer_RoundStatus, client);
	}

	return Plugin_Handled;
}

public Action Timer_RoundStatus(Handle Timer, int client)
{
	char Buffer[128], Mapname[128];
	wm_cvHostname.GetString(Buffer, sizeof(Buffer));
	GetCurrentMap(Mapname, sizeof(Mapname));

	if (wm_cvMaxSlots == null)	// in case you dont have match_vote.smx
		wm_cvMaxSlots = FindConVar("sv_maxplayers");

	CPrintToChatEx(client, client, "%t", "Header", Buffer);
	CPrintToChatEx(client, client, "%t", "PlayerNum", (GetTotalPlayers() == wm_cvMaxSlots.IntValue) ? "{green}" : "{olive}", GetTotalPlayers(), wm_cvMaxSlots.IntValue);
	CPrintToChatEx(client, client, "%t", "MapName", Mapname);

	if (L4D_IsVersusMode() || L4D2_IsScavengeMode())
	{
		SetGlobalTransTarget(client);
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
	wm_cvHostname.GetString(Buffer, sizeof(Buffer));
	GetCurrentMap(Mapname, sizeof(Mapname));

	if (wm_cvMaxSlots == null)	// in case you dont have match_vote.smx
		wm_cvMaxSlots = FindConVar("sv_maxplayers");

	CPrintToChatEx(client, client, "%t", "Header", Buffer);
	CPrintToChatEx(client, client, "%t", "PlayerNum",(GetTotalPlayers() == wm_cvMaxSlots.IntValue) ? "{green}" : "{olive}", GetTotalPlayers(), wm_cvMaxSlots.IntValue);
	CPrintToChatEx(client, client, "%t", "MapName", Mapname);

	if (L4D_GetGameModeType() == GAMEMODE_VERSUS || L4D_GetGameModeType() == GAMEMODE_SCAVENGE)
	{
		SetGlobalTransTarget(client);
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
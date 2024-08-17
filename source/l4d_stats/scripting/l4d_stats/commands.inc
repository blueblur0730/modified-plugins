#if defined _l4d_stats_commands_included
	#endinput
#endif
#define _l4d_stats_commands_included

void RegCommands()
{
	// Hook chat commands for rank panels
	RegConsoleCmd("say", cmd_Say);
	RegConsoleCmd("say_team", cmd_Say);

	// Register console commands for rank panels
	RegConsoleCmd("sm_rank", cmd_ShowRank);
	RegConsoleCmd("sm_top10", cmd_ShowTop10);
	RegConsoleCmd("sm_top10ppm", cmd_ShowTop10PPM);
	RegConsoleCmd("sm_nextrank", cmd_ShowNextRank);
	RegConsoleCmd("sm_showtimer", cmd_ShowTimedMapsTimer);
	RegConsoleCmd("sm_showrank", cmd_ShowRanks);
	RegConsoleCmd("sm_showppm", cmd_ShowPPMs);
	RegConsoleCmd("sm_rankvote", cmd_RankVote);
	RegConsoleCmd("sm_timedmaps", cmd_TimedMaps);
	RegConsoleCmd("sm_maptimes", cmd_MapTimes);
	RegConsoleCmd("sm_showmaptimes", cmd_ShowMapTimes);
	RegConsoleCmd("sm_rankmenu", cmd_ShowRankMenu);
	RegConsoleCmd("sm_rankmutetoggle", cmd_ToggleClientRankMute);
	RegConsoleCmd("sm_rankmute", cmd_ClientRankMute);
	RegConsoleCmd("sm_showmotd", cmd_ShowMotd);

	// Register administrator command for clearing all stats (BE CAREFUL)
	// RegAdminCmd("sm_rank_admin", cmd_RankAdmin, ADMFLAG_ROOT, "Display admin panel for Rank");
	RegAdminCmd("sm_rank_clear", cmd_ClearRank, ADMFLAG_ROOT, "Clear all stats from database (asks a confirmation before clearing the database)");
	RegAdminCmd("sm_rank_shuffle", cmd_ShuffleTeams, ADMFLAG_KICK, "Shuffle teams by player PPM (Points Per Minute)");
	RegAdminCmd("sm_rank_motd", cmd_SetMotd, ADMFLAG_GENERIC, "Set Message Of The Day");
}

/*
-----------------------------------------------------------------------------
Chat/command handling and panels for Rank and Top10
-----------------------------------------------------------------------------
*/

// DEBUG
// public Action:cmd_StatsTest(client, args)
//{
//	char CurrentMode[16];
//	GetConVarString(g_hCvar_Gamemode, CurrentMode, sizeof(CurrentMode));
//	PrintToConsole(0, "Gamemode: %s", CurrentMode);
//	UpdateMapStat("playtime", 10);
//	PrintToConsole(0, "Added 10 seconds to maps table current map.");
//	float ReductionFactor = GetMedkitPointReductionFactor();
//
//	StatsPrintToChat(client, "\x03ALL SURVIVORS \x01now earns only \x04%i percent \x01of their normal points after using their \x05%i%s Medkit\x01!", RoundToNearest(ReductionFactor * 100), g_iMedkitsUsedCounter, (g_iMedkitsUsedCounter == 1 ? "st" : (g_iMedkitsUsedCounter == 2 ? "nd" : (g_iMedkitsUsedCounter == 3 ? "rd" : "th"))), GetClientTeam(client));
//}

Action HandleCommands(int client, const char[] Text)
{
	if (strcmp(Text, "rankmenu", false) == 0)
	{
		cmd_ShowRankMenu(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "rank", false) == 0)
	{
		cmd_ShowRank(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "showrank", false) == 0)
	{
		cmd_ShowRanks(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "showppm", false) == 0)
	{
		cmd_ShowPPMs(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "top10", false) == 0)
	{
		cmd_ShowTop10(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "top10ppm", false) == 0)
	{
		cmd_ShowTop10PPM(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "nextrank", false) == 0)
	{
		cmd_ShowNextRank(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "showtimer", false) == 0)
	{
		cmd_ShowTimedMapsTimer(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "timedmaps", false) == 0)
	{
		cmd_TimedMaps(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "showmaptime", false) == 0)
	{
		cmd_ShowMapTimes(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "maptimes", false) == 0)
	{
		cmd_MapTimes(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "rankvote", false) == 0)
	{
		cmd_RankVote(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "rankmutetoggle", false) == 0)
	{
		cmd_ToggleClientRankMute(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "showmotd", false) == 0)
	{
		cmd_ShowMotd(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	return Plugin_Continue;
}

// Parse chat for RANK and TOP10 triggers.
Action cmd_Say(int client, int args)
{
	char Text[192];
	// char Command[64];
	int	Start = 0;

	GetCmdArgString(Text, sizeof(Text));

	int TextLen = strlen(Text);

	// This apparently happens sometimes?
	if (TextLen <= 0)
		return Plugin_Continue;

	if (Text[TextLen - 1] == '"')
	{
		Text[TextLen - 1] = '\0';
		Start = 1;
	}

	// Command is never set? This will always result to false.
	// if (strcmp(Command, "say2", false) == 0)
	//	Start += 4;

	return HandleCommands(client, Text[Start]);
}

// Show current Timed Maps timer.
Action cmd_ShowTimedMapsTimer(int client, int args)
{
	if (client != 0 && !IsClientConnected(client) && !IsClientInGame(client))
		return Plugin_Handled;

	if (client != 0 && IsClientBot(client))
		return Plugin_Handled;

	if (g_fMapTimingStartTime <= 0.0)
	{
		if (client == 0) PrintToConsole(0, "[RANK] Map timer has not started");
		else StatsPrintToChatPreFormatted(client, "Map timer has not started");

		return Plugin_Handled;
	}

	float CurrentMapTimer = GetEngineTime() - g_fMapTimingStartTime;
	char  TimeLabel[32];

	SetTimeLabel(CurrentMapTimer, TimeLabel, sizeof(TimeLabel));

	if (client == 0) PrintToConsole(0, "[RANK] Current map timer: %s", TimeLabel);
	else StatsPrintToChat(client, "Current map timer: \x04%s", TimeLabel);

	return Plugin_Handled;
}

// Begin generating the NEXTRANK display panel.
Action cmd_ShowNextRank(int client, int args)
{
	if (!IsClientConnected(client) && !IsClientInGame(client))
		return Plugin_Handled;

	if (IsClientBot(client))
		return Plugin_Handled;

	char SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));
	QueryClientStatsSteamID(client, SteamID, CM_NEXTRANK);

	return Plugin_Handled;
}

// Clear database.
// public Action:cmd_RankAdmin(client, args)
//{
//	if (!client)
//		return Plugin_Handled;
//
//	Handle RankAdminPanel = CreatePanel();
//
//	SetPanelTitle(RankAdminPanel, "Rank Admin:");
//
//	DrawPanelItem(RankAdminPanel, "Clear...");
//	DrawPanelItem(RankAdminPanel, "Clear Players");
//	DrawPanelItem(RankAdminPanel, "Clear Maps");
//	DrawPanelItem(RankAdminPanel, "Clear All");
//
//	SendPanelToClient(RankAdminPanel, client, RankAdminPanelHandler, 30);
//	CloseHandle(RankAdminPanel);
//
//	return Plugin_Handled;
//}

// Run Team Shuffle.
Action cmd_ShuffleTeams(int client, int args)
{
	if (!IsTeamGamemode())
	{
		PrintToConsole(client, "[RANK] Team shuffle is not enabled in this gamemode!");
		return Plugin_Handled;
	}

	if (g_hRankVoteTimer != null)
	{
		delete g_hRankVoteTimer;
		StatsPrintToChatAllPreFormatted("Team shuffle executed by administrator.");
	}

	PrintToConsole(client, "[RANK] Executing team shuffle...");
	CreateTimer(1.0, timer_ShuffleTeams);

	return Plugin_Handled;
}

// Set Message Of The Day.
Action cmd_SetMotd(int client, int args)
{
	char arg[1024], msofd[1024];

	GetCmdArgString(arg, sizeof(arg));

	strcopy(msofd, sizeof(msofd), MOTD_TITLE);
	UpdateServerSettings(client, "motdmessage", arg, msofd);

	return Plugin_Handled;
}

// Clear database.
Action cmd_ClearRank(int client, int args)
{
	if (client == 0)
	{
		PrintToConsole(client, "[RANK] Clear Stats: Database clearing from server console currently disabled because of a bug in it! Run the command from in-game console or from Admin Panel.");
		return Plugin_Handled;
	}

	if (g_hClearDatabaseTimer != null)
		delete g_hClearDatabaseTimer;

	if (g_iClearDatabaseCaller == client)
	{
		PrintToConsole(client, "[RANK] Clear Stats: Started clearing the database!");
		g_iClearDatabaseCaller = -1;
		ClearStatsAll(client);

		return Plugin_Handled;
	}

	PrintToConsole(client, "[RANK] Clear Stats: To clear the database, execute this command again in %.2f seconds!", CLEAR_DATABASE_CONFIRMTIME);
	g_iClearDatabaseCaller = client;

	g_hClearDatabaseTimer  = CreateTimer(CLEAR_DATABASE_CONFIRMTIME, timer_ClearDatabase);

	return Plugin_Handled;
}

// Toggle client rank mute.
Action cmd_ToggleClientRankMute(int client, int args)
{
	if (client == 0)
		return Plugin_Handled;

	if (!IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	char SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));

	g_bClientRankMute[client] = !g_bClientRankMute[client];

	char query[256];
	Format(query, sizeof(query), "UPDATE %ssettings SET mute = %i WHERE steamid = '%s'", g_sDbPrefix, (g_bClientRankMute[client] ? 1 : 0), SteamID);
	SendSQLUpdate(query);

	AnnounceClientRankMute(client);

	return Plugin_Handled;
}

void ShowRankMuteUsage(int client)
{
	PrintToConsole(client, "[RANK] Command usage: sm_rankmute <0|1>");
}

// Show current message of the day.
Action cmd_ShowMotd(int client, int args)
{
	ShowMOTD(client, true);
}

// Set client rank mute.
Action cmd_ClientRankMute(int client, int args)
{
	if (client == 0)
		return Plugin_Handled;

	if (!IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	if (args != 1)
	{
		ShowRankMuteUsage(client);
		return Plugin_Handled;
	}

	char arg[MAX_LINE_WIDTH];
	GetCmdArgString(arg, sizeof(arg));

	if (!StrEqual(arg, "0") && !StrEqual(arg, "1"))
	{
		ShowRankMuteUsage(client);
		return Plugin_Handled;
	}

	char SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));

	g_bClientRankMute[client] = StrEqual(arg, "1");

	char query[256];
	Format(query, sizeof(query), "UPDATE %ssettings SET mute = %s WHERE steamid = '%s'", g_sDbPrefix, arg, SteamID);
	SendSQLUpdate(query);

	AnnounceClientRankMute(client);

	return Plugin_Handled;
}

void AnnounceClientRankMute(int client)
{
	StatsPrintToChat2(client, true, "You %s \x01the \x05Plugin\x01.", (g_bClientRankMute[client] ? "\x04MUTED" : "\x03UNMUTED"));
}

// Start RANKVOTE.
Action cmd_RankVote(int client, int args)
{
	if (client == 0)
	{
		StartRankVote(client);
		return Plugin_Handled;
	}

	if (!IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	int	ClientFlags = GetUserFlagBits(client);
	bool IsAdmin = ((ClientFlags & ADMFLAG_GENERIC) == ADMFLAG_GENERIC);

	int	ClientTeam = GetClientTeam(client);

	if (!IsAdmin && ClientTeam != TEAM_SURVIVORS && ClientTeam != TEAM_INFECTED)
	{
		StatsPrintToChatPreFormatted2(client, true, "The spectators cannot initiate the \x04Rank Vote\x01.");
		return Plugin_Handled;
	}

	StartRankVote(client);

	return Plugin_Handled;
}

// Generate the TIMEDMAPS display menu.
Action cmd_TimedMaps(int client, int args)
{
	if (client == 0 || !IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	char query[256];
	Format(query, sizeof(query), "SELECT DISTINCT tm.gamemode, tm.mutation FROM %stimedmaps AS tm INNER JOIN %splayers AS p ON tm.steamid = p.steamid", g_sDbPrefix, g_sDbPrefix);
	SQL_TQuery(db, CreateTimedMapsMenu, query, client);

	return Plugin_Handled;
}

// Generate the MAPTIME display menu.
Action cmd_MapTimes(int client, int args)
{
	if (client == 0 || !IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	char Info[MAX_LINE_WIDTH], CurrentMapName[MAX_LINE_WIDTH];

	GetCurrentMap(CurrentMapName, sizeof(CurrentMapName));
	Format(Info, sizeof(Info), "%i\\%s", g_iCurrentGamemodeID, CurrentMapName);

	DisplayTimedMapsMenu3FromInfo(client, Info);

	return Plugin_Handled;
}

// Generate the SHOWMAPTIME display menu.
Action cmd_ShowMapTimes(int client, int args)
{
	if (client == 0 || !IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	StatsPrintToChatPreFormatted2(client, true, "\x05NOT IMPLEMENTED YET");

	return Plugin_Handled;
}

// Generate the SHOWPPM display menu.
Action cmd_ShowPPMs(int client, int args)
{
	if (!IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	char query[1024];
	// Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers", g_sDbPrefix);
	// SQL_TQuery(db, GetRankTotal, query);

	Format(query, sizeof(query), "SELECT steamid, name, (%s) / (%s) AS ppm FROM %splayers WHERE ", DB_PLAYERS_TOTALPOINTS, DB_PLAYERS_TOTALPLAYTIME, g_sDbPrefix);

	char SteamID[MAX_LINE_WIDTH], where[512];
	int	counter = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientBot(i) || !IsClientConnected(i) || !IsClientInGame(i))
			continue;

		if (counter++ > 0)
			StrCat(query, sizeof(query), "OR ");

		GetClientRankAuthString(i, SteamID, sizeof(SteamID));
		Format(where, sizeof(where), "steamid = '%s' ", SteamID);
		StrCat(query, sizeof(query), where);
	}

	if (counter == 0)
		return Plugin_Handled;

	if (counter == 1)
	{
		cmd_ShowRank(client, 0);
		return Plugin_Handled;
	}

	StrCat(query, sizeof(query), "ORDER BY ppm DESC");
	SQL_TQuery(db, CreatePPMMenu, query, client);

	return Plugin_Handled;
}

// Generate the SHOWRANK display menu.
Action cmd_ShowRanks(int client, int args)
{
	if (!IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	char query[1024];
	// Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers", g_sDbPrefix);
	// SQL_TQuery(db, GetRankTotal, query);

	Format(query, sizeof(query), "SELECT steamid, name, %s AS totalpoints FROM %splayers WHERE ", DB_PLAYERS_TOTALPOINTS, g_sDbPrefix);

	char SteamID[MAX_LINE_WIDTH], where[512];
	int	counter = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientBot(i) || !IsClientConnected(i) || !IsClientInGame(i))
			continue;

		if (counter++ > 0)
			StrCat(query, sizeof(query), "OR ");

		GetClientRankAuthString(i, SteamID, sizeof(SteamID));
		Format(where, sizeof(where), "steamid = '%s' ", SteamID);
		StrCat(query, sizeof(query), where);
	}

	if (counter == 0)
		return Plugin_Handled;

	if (counter == 1)
	{
		cmd_ShowRank(client, 0);
		return Plugin_Handled;
	}

	StrCat(query, sizeof(query), "ORDER BY totalpoints DESC");

	SQL_TQuery(db, CreateRanksMenu, query, client);

	return Plugin_Handled;
}

// Generate the TOPPPM display panel.
Action cmd_ShowTop10PPM(int client, int args)
{
	if (!IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	char query[1024];
	Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers", g_sDbPrefix);
	SQL_TQuery(db, GetRankTotal, query);

	Format(query, sizeof(query), "SELECT name, (%s) / (%s) AS ppm FROM %splayers WHERE (%s) >= %i ORDER BY ppm DESC, (%s) DESC LIMIT 10", DB_PLAYERS_TOTALPOINTS, DB_PLAYERS_TOTALPLAYTIME, g_sDbPrefix, DB_PLAYERS_TOTALPLAYTIME, GetConVarInt(g_hCvar_Top10PPMMin), DB_PLAYERS_TOTALPLAYTIME);
	SQL_TQuery(db, DisplayTop10PPM, query, client);

	return Plugin_Handled;
}

// Generate the TOP10 display panel.
Action cmd_ShowTop10(int client, int args)
{
	if (!IsClientConnected(client) && !IsClientInGame(client) && IsClientBot(client))
		return Plugin_Handled;

	char query[512];
	Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers", g_sDbPrefix);
	SQL_TQuery(db, GetRankTotal, query);

	Format(query, sizeof(query), "SELECT name FROM %splayers ORDER BY %s DESC LIMIT 10", g_sDbPrefix, DB_PLAYERS_TOTALPOINTS);
	SQL_TQuery(db, DisplayTop10, query, client);

	return Plugin_Handled;
}

// Begin generating the RANK display panel.
Action cmd_ShowRank(int client, int args)
{
	if (client == 0)
	{
		NotServerConsoleCommand();
		return Plugin_Handled;
	}

	if (!IsClientConnected(client) && !IsClientInGame(client))
		return Plugin_Handled;

	if (IsClientBot(client))
		return Plugin_Handled;

	char SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));
	QueryClientStatsSteamID(client, SteamID, CM_RANK);

	return Plugin_Handled;
}

// Begin generating the RANKMENU display panel.
Action cmd_ShowRankMenu(int client, int args)
{
	if (client <= 0)
	{
		if (client == 0)
			PrintToConsole(0, "[RANK] You must be ingame to operate rankmenu.");

		return Plugin_Handled;
	}

	if (!IsClientConnected(client) && !IsClientInGame(client))
		return Plugin_Handled;

	if (IsClientBot(client))
		return Plugin_Handled;

	DisplayRankMenu(client);

	return Plugin_Handled;
}
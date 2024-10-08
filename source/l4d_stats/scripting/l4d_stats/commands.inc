#if defined _l4d_stats_commands_included
	#endinput
#endif
#define _l4d_stats_commands_included

void RegCommands()
{
	// Hook chat commands for rank panels
	RegConsoleCmd("say", Cmd_Say);
	RegConsoleCmd("say_team", Cmd_Say);

	// Register console commands for rank panels
	RegConsoleCmd("sm_rank", Cmd_ShowRank);
	RegConsoleCmd("sm_top10", Cmd_ShowTop10);
	RegConsoleCmd("sm_top10ppm", Cmd_ShowTop10PPM);
	RegConsoleCmd("sm_nextrank", Cmd_ShowNextRank);
	RegConsoleCmd("sm_showtimer", Cmd_ShowTimedMapsTimer);
	RegConsoleCmd("sm_showrank", Cmd_ShowRanks);
	RegConsoleCmd("sm_showppm", Cmd_ShowPPMs);
	RegConsoleCmd("sm_rankvote", Cmd_RankVote);
	RegConsoleCmd("sm_timedmaps", Cmd_TimedMaps);
	RegConsoleCmd("sm_maptimes", Cmd_MapTimes);
	RegConsoleCmd("sm_showmaptimes", Cmd_ShowMapTimes);
	RegConsoleCmd("sm_rankmenu", Cmd_ShowRankMenu);
	RegConsoleCmd("sm_rankmutetoggle", Cmd_ToggleClientRankMute);
	RegConsoleCmd("sm_rankmute", Cmd_ClientRankMute);
	RegConsoleCmd("sm_showmotd", Cmd_ShowMotd);

	// Register administrator command for clearing all stats (BE CAREFUL)
	// RegAdminCmd("sm_rank_admin", cmd_RankAdmin, ADMFLAG_ROOT, "Display admin panel for Rank");
	RegAdminCmd("sm_rank_clear", Cmd_ClearRank, ADMFLAG_ROOT, "Clear all stats from database (asks a confirmation before clearing the database)");
	RegAdminCmd("sm_rank_shuffle", Cmd_ShuffleTeams, ADMFLAG_KICK, "Shuffle teams by player PPM (Points Per Minute)");
	RegAdminCmd("sm_rank_motd", Cmd_SetMotd, ADMFLAG_GENERIC, "Set Message Of The Day");
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
//	StatsPrintToChat(client, "{lightgreen}ALL SURVIVORS {default}now earns only {green}%i percent {default}of their normal points after using their {olive}%i%s Medkit{default}!", RoundToNearest(ReductionFactor * 100), g_iMedkitsUsedCounter, (g_iMedkitsUsedCounter == 1 ? "st" : (g_iMedkitsUsedCounter == 2 ? "nd" : (g_iMedkitsUsedCounter == 3 ? "rd" : "th"))), GetClientTeam(client));
//}

Action HandleCommands(int client, const char[] Text)
{
	if (strcmp(Text, "rankmenu", false) == 0)
	{
		Cmd_ShowRankMenu(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "rank", false) == 0)
	{
		Cmd_ShowRank(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "showrank", false) == 0)
	{
		Cmd_ShowRanks(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "showppm", false) == 0)
	{
		Cmd_ShowPPMs(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "top10", false) == 0)
	{
		Cmd_ShowTop10(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "top10ppm", false) == 0)
	{
		Cmd_ShowTop10PPM(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "nextrank", false) == 0)
	{
		Cmd_ShowNextRank(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "showtimer", false) == 0)
	{
		Cmd_ShowTimedMapsTimer(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "timedmaps", false) == 0)
	{
		Cmd_TimedMaps(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "showmaptime", false) == 0)
	{
		Cmd_ShowMapTimes(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "maptimes", false) == 0)
	{
		Cmd_MapTimes(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "rankvote", false) == 0)
	{
		Cmd_RankVote(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "rankmutetoggle", false) == 0)
	{
		Cmd_ToggleClientRankMute(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	else if (strcmp(Text, "showmotd", false) == 0)
	{
		Cmd_ShowMotd(client, 0);
		if (g_hCvar_SilenceChat.BoolValue)
			return Plugin_Handled;
	}

	return Plugin_Continue;
}

// Parse chat for RANK and TOP10 triggers.
Action Cmd_Say(int client, int args)
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
Action Cmd_ShowTimedMapsTimer(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || IsClientBot(client))
		return Plugin_Handled;

	if (g_fMapTimingStartTime <= 0.0)
	{
		if (client == 0) PrintToConsole(0, "[RANK] Map timer has not started");
		else CPrintToChat(client, "%t %t", "Tag","MapTimerNotStarted");

		return Plugin_Handled;
	}

	float CurrentMapTimer = GetEngineTime() - g_fMapTimingStartTime;
	char  TimeLabel[32];

	SetTimeLabel(CurrentMapTimer, TimeLabel, sizeof(TimeLabel));

	if (client == 0) PrintToConsole(0, "[RANK] Current map timer: %s", TimeLabel);
	else CPrintToChat(client, "%t %t", "Tag","CurrentMapTimer", TimeLabel);

	return Plugin_Handled;
}

// Begin generating the NEXTRANK display panel.
Action Cmd_ShowNextRank(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || IsClientBot(client))
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
Action Cmd_ShuffleTeams(int client, int args)
{
	if (!IsTeamGamemode())
	{
		PrintToConsole(client, "[RANK] Team shuffle is not enabled in this gamemode!");
		return Plugin_Handled;
	}

	if (g_hRankVoteTimer != null)
	{
		delete g_hRankVoteTimer;
		CPrintToChatAll("%t %t", "Tag","ShuffledByAdmin");
	}

	PrintToConsole(client, "[RANK] Executing team shuffle...");
	CreateTimer(1.0, Timer_ShuffleTeams);

	return Plugin_Handled;
}

// Set Message Of The Day.
Action Cmd_SetMotd(int client, int args)
{
	char arg[1024], msofd[1024];

	GetCmdArgString(arg, sizeof(arg));

	strcopy(msofd, sizeof(msofd), MOTD_TITLE);
	UpdateServerSettings(client, "motdmessage", arg, msofd);

	return Plugin_Handled;
}

// Clear database.
Action Cmd_ClearRank(int client, int args)
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

	g_hClearDatabaseTimer  = CreateTimer(CLEAR_DATABASE_CONFIRMTIME, Timer_ClearDatabase);

	return Plugin_Handled;
}

// Toggle client rank mute.
Action Cmd_ToggleClientRankMute(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || IsClientBot(client))
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

// Show current message of the day.
Action Cmd_ShowMotd(int client, int args)
{
	ShowMOTD(client, true);
	return Plugin_Handled
}

// Set client rank mute.
Action Cmd_ClientRankMute(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || IsClientBot(client))
		return Plugin_Handled;

	if (args != 1)
	{
		PrintToConsole(client, "[RANK] Command usage: sm_rankmute <0|1>");
		return Plugin_Handled;
	}

	char arg[MAX_LINE_WIDTH];
	GetCmdArgString(arg, sizeof(arg));

	if (!StrEqual(arg, "0") && !StrEqual(arg, "1"))
	{
		PrintToConsole(client, "[RANK] Command usage: sm_rankmute <0|1>");
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
	char muted[32], unmuted[32];
	Format(muted, sizeof(muted), "%T", "Muted", client);
	Format(unmuted, sizeof(unmuted), "%T", "Unmuted", client);
	CPrintToChat(client, "%t %t", "Tag", "YouMutedPlugin", (g_bClientRankMute[client] ? muted : unmuted));
}

// Start RANKVOTE.
Action Cmd_RankVote(int client, int args)
{
	if (client == 0)
	{
		StartRankVote(client);
		return Plugin_Handled;
	}

	if (client == 0 || !IsClientInGame(client) || IsClientBot(client))
		return Plugin_Handled;

	int	ClientFlags = GetUserFlagBits(client);
	bool IsAdmin = ((ClientFlags & ADMFLAG_GENERIC) == ADMFLAG_GENERIC);

	int	ClientTeam = GetClientTeam(client);

	if (!IsAdmin && ClientTeam != TEAM_SURVIVORS && ClientTeam != TEAM_INFECTED)
	{
		CPrintToChat(client, "%t %t", "Tag", "SpecNoteAllowed");
		return Plugin_Handled;
	}

	StartRankVote(client);

	return Plugin_Handled;
}

// Generate the TIMEDMAPS display menu.
Action Cmd_TimedMaps(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || IsClientBot(client))
		return Plugin_Handled;

	char query[256];
	Format(query, sizeof(query), "SELECT DISTINCT tm.gamemode, tm.mutation FROM %stimedmaps AS tm INNER JOIN %splayers AS p ON tm.steamid = p.steamid", g_sDbPrefix, g_sDbPrefix);
	SQL_TQuery(db, CreateTimedMapsMenu, query, client);

	return Plugin_Handled;
}

// Generate the MAPTIME display menu.
Action Cmd_MapTimes(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || IsClientBot(client))
		return Plugin_Handled;

	char Info[MAX_LINE_WIDTH], CurrentMapName[MAX_LINE_WIDTH];

	GetCurrentMap(CurrentMapName, sizeof(CurrentMapName));
	Format(Info, sizeof(Info), "%i\\%s", g_iCurrentGamemodeID, CurrentMapName);

	DisplayTimedMapsMenu3FromInfo(client, Info);

	return Plugin_Handled;
}

// Generate the SHOWMAPTIME display menu.
Action Cmd_ShowMapTimes(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || IsClientBot(client))
		return Plugin_Handled;

	CPrintToChat(client, "{olive}NOT IMPLEMENTED YET");

	return Plugin_Handled;
}

// Generate the SHOWPPM display menu.
Action Cmd_ShowPPMs(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || IsClientBot(client))
		return Plugin_Handled;

	char query[1024];
	// Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers", g_sDbPrefix);
	// SQL_TQuery(db, GetRankTotal, query);

	Format(query, sizeof(query), "SELECT steamid, name, (%s) / (%s) AS ppm FROM %splayers WHERE ", DB_PLAYERS_TOTALPOINTS, DB_PLAYERS_TOTALPLAYTIME, g_sDbPrefix);

	char SteamID[MAX_LINE_WIDTH], where[512];
	int	counter = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientBot(i) || !IsClientInGame(i))
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
		Cmd_ShowRank(client, 0);
		return Plugin_Handled;
	}

	StrCat(query, sizeof(query), "ORDER BY ppm DESC");
	SQL_TQuery(db, CreatePPMMenu, query, client);

	return Plugin_Handled;
}

// Generate the SHOWRANK display menu.
Action Cmd_ShowRanks(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || IsClientBot(client))
		return Plugin_Handled;

	char query[1024];
	// Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers", g_sDbPrefix);
	// SQL_TQuery(db, GetRankTotal, query);

	Format(query, sizeof(query), "SELECT steamid, name, %s AS totalpoints FROM %splayers WHERE ", DB_PLAYERS_TOTALPOINTS, g_sDbPrefix);

	char SteamID[MAX_LINE_WIDTH], where[512];
	int	counter = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientBot(i) || !IsClientInGame(i))
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
		Cmd_ShowRank(client, 0);
		return Plugin_Handled;
	}

	StrCat(query, sizeof(query), "ORDER BY totalpoints DESC");
	SQL_TQuery(db, CreateRanksMenu, query, client);

	return Plugin_Handled;
}

// Generate the TOPPPM display panel.
Action Cmd_ShowTop10PPM(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || IsClientBot(client))
		return Plugin_Handled;

	char query[1024];
	Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers", g_sDbPrefix);
	SQL_TQuery(db, GetRankTotal, query);

	Format(query, sizeof(query), "SELECT name, (%s) / (%s) AS ppm FROM %splayers WHERE (%s) >= %i ORDER BY ppm DESC, (%s) DESC LIMIT 10", DB_PLAYERS_TOTALPOINTS, DB_PLAYERS_TOTALPLAYTIME, g_sDbPrefix, DB_PLAYERS_TOTALPLAYTIME, g_hCvar_Top10PPMMin.IntValue, DB_PLAYERS_TOTALPLAYTIME);
	SQL_TQuery(db, DisplayTop10PPM, query, client);

	return Plugin_Handled;
}

// Generate the TOP10 display panel.
Action Cmd_ShowTop10(int client, int args)
{
	if (client == 0 || !IsClientInGame(client) || IsClientBot(client))
		return Plugin_Handled;

	char query[512];
	Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers", g_sDbPrefix);
	SQL_TQuery(db, GetRankTotal, query);

	Format(query, sizeof(query), "SELECT name FROM %splayers ORDER BY %s DESC LIMIT 10", g_sDbPrefix, DB_PLAYERS_TOTALPOINTS);
	SQL_TQuery(db, DisplayTop10, query, client);

	return Plugin_Handled;
}

// Begin generating the RANK display panel.
Action Cmd_ShowRank(int client, int args)
{
	if (client == 0)
	{
		PrintToConsole(0, "[RANK] Error: Most of the rank commands including this one are not available from server console.");
		return Plugin_Handled;
	}

	if (!IsClientInGame(client) || IsClientBot(client))
		return Plugin_Handled;

	char SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));
	QueryClientStatsSteamID(client, SteamID, CM_RANK);

	return Plugin_Handled;
}

// Begin generating the RANKMENU display panel.
Action Cmd_ShowRankMenu(int client, int args)
{
	if (client <= 0)
	{
		if (client == 0)
			PrintToConsole(0, "[RANK] You must be ingame to operate rankmenu.");

		return Plugin_Handled;
	}

	if (!IsClientInGame(client) || IsClientBot(client))
		return Plugin_Handled;

	DisplayRankMenu(client);

	return Plugin_Handled;
}
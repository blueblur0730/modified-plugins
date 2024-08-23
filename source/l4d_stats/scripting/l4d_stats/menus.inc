#if defined _l4d_stats_menus_included
 #endinput
#endif
#define _l4d_stats_menus_included

// Load our categories and menus
public void OnAdminMenuReady(Handle TopMenuHandle)
{
	// Block us from being called twice
	if (TopMenuHandle == g_hTM_RankAdminMenu)
		return;

	g_hTM_RankAdminMenu = view_as<TopMenu>(TopMenuHandle);

	// Add a category to the SourceMod menu called "Player Stats"
	g_hTM_RankAdminMenu.AddCategory("Player Stats", ClearRankCategoryHandler);

	// Get a handle for the catagory we just added so we can add items to it
	TopMenuObject statscommands = g_hTM_RankAdminMenu.FindCategory("Player Stats");

	// Don't attempt to add items to the catagory if for some reason the catagory doesn't exist
	if (statscommands == INVALID_TOPMENUOBJECT)
		return;

	// The order that items are added to menus has no relation to the order that they appear. Items are sorted alphabetically automatically
	// Assign the menus to global values so we can easily check what a menu is when it is chosen
	g_TMO_MenuClearPlayers = g_hTM_RankAdminMenu.AddItem("sm_rank_admin_clearplayers", ClearRankTopItemHandler, statscommands, "sm_rank_admin_clearplayers", ADMFLAG_ROOT);
	g_TMO_MenuClearMaps = g_hTM_RankAdminMenu.AddItem("sm_rank_admin_clearallmaps", ClearRankTopItemHandler, statscommands, "sm_rank_admin_clearallmaps", ADMFLAG_ROOT);
	g_TMO_MenuClearAll = g_hTM_RankAdminMenu.AddItem("sm_rank_admin_clearall", ClearRankTopItemHandler, statscommands, "sm_rank_admin_clearall", ADMFLAG_ROOT);
	g_TMO_MenuClearTimedMaps = g_hTM_RankAdminMenu.AddItem("sm_rank_admin_cleartimedmaps", ClearRankTopItemHandler, statscommands, "sm_rank_admin_cleartimedmaps", ADMFLAG_ROOT);
	g_TMO_MenuRemoveCustomMaps = g_hTM_RankAdminMenu.AddItem("sm_rank_admin_removecustom", ClearRankTopItemHandler, statscommands, "sm_rank_admin_removecustom", ADMFLAG_ROOT);
	g_TMO_MenuCleanPlayers = g_hTM_RankAdminMenu.AddItem("sm_rank_admin_removeplayers", ClearRankTopItemHandler, statscommands, "sm_rank_admin_removeplayers", ADMFLAG_ROOT);
	g_TMO_MenuClear = g_hTM_RankAdminMenu.AddItem("sm_rank_admin_clear", ClearRankTopItemHandler, statscommands, "sm_rank_admin_clear", ADMFLAG_ROOT);
}

// This handles the top level "Player Stats" category and how it is displayed on the core admin menu
void ClearRankCategoryHandler(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int client, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Player Stats");
	else if (action == TopMenuAction_DisplayTitle)
		Format(buffer, maxlength, "Player Stats:");
}

void Menu_CreateClearMenu(int client)
{
	Menu menu = new Menu(Menu_CreateClearMenuHandler);

	menu.SetTitle("Clear:");
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.AddItem("cps", "Clear stats from currently playing player...");
	menu.AddItem("ctm", "Clear timed maps...");
	menu.Display(client, 30);
}

int Menu_CreateClearMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 0:DisplayClearPanel(param1);
				case 1:Menu_CreateClearTMMenu(param1);
			}
		}

		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && g_hTM_RankAdminMenu)
				g_hTM_RankAdminMenu.Display(param1, TopMenuPosition_LastCategory);
		}

		case MenuAction_End: 
            delete menu;
	}

	return 0;
}

void Menu_CreateClearTMMenu(int client)
{
	Menu menu = new Menu(Menu_CreateClearTMMenuHandler);

	menu.SetTitle("Clear Timed Maps:");
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.AddItem("ctma",  "All");
	menu.AddItem("ctmc",  "Coop");
	menu.AddItem("ctmsu", "Survival");
	menu.AddItem("ctmr",  "Realism");
	menu.AddItem("ctmm",  "Mutations");
	menu.Display(client, 30);
}

int Menu_CreateClearTMMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 0:DisplayYesNoPanel(param1, "Do you really want to clear all map timings?", ClearTMAllPanelHandler);
				case 1:DisplayYesNoPanel(param1, "Do you really want to clear all Coop map timings?", ClearTMCoopPanelHandler);
				case 2:DisplayYesNoPanel(param1, "Do you really want to clear all Survival map timings?", ClearTMSurvivalPanelHandler);
				case 3:DisplayYesNoPanel(param1, "Do you really want to clear all Realism map timings?", ClearTMRealismPanelHandler);
				case 4:DisplayYesNoPanel(param1, "Do you really want to clear all Mutations map timings?", ClearTMMutationsPanelHandler);
			}
		}

		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && g_hTM_RankAdminMenu)
				g_hTM_RankAdminMenu.Display(param1, TopMenuPosition_LastCategory);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

// This deals with what happens someone opens the "Player Stats" category from the menu
void ClearRankTopItemHandler(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int client, char[] buffer, int maxlength)
{
	// When an item is displayed to a player tell the menu to format the item
	if (action == TopMenuAction_DisplayOption)
	{
		if (object_id == g_TMO_MenuClearPlayers) Format(buffer, maxlength, "Clear players");
		else if (object_id == g_TMO_MenuClearMaps) Format(buffer, maxlength, "Clear maps");
		else if (object_id == g_TMO_MenuClearAll) Format(buffer, maxlength, "Clear all");
		else if (object_id == g_TMO_MenuClearTimedMaps) Format(buffer, maxlength, "Clear timed maps");
		else if (object_id == g_TMO_MenuRemoveCustomMaps) Format(buffer, maxlength, "Remove custom maps");
		else if (object_id == g_TMO_MenuCleanPlayers) Format(buffer, maxlength, "Clean players");
		else if (object_id == g_TMO_MenuClear) Format(buffer, maxlength, "Clear...");
	}

	// When an item is selected do the following
	else if (action == TopMenuAction_SelectOption)
	{
		if (object_id == g_TMO_MenuClearPlayers) DisplayYesNoPanel(client, "Do you really want to clear the player stats?", ClearPlayersPanelHandler);
		else if (object_id == g_TMO_MenuClearMaps) DisplayYesNoPanel(client, "Do you really want to clear the map stats?", ClearMapsPanelHandler);
		else if (object_id == g_TMO_MenuClearAll) DisplayYesNoPanel(client, "Do you really want to clear all stats?", ClearAllPanelHandler);
		else if (object_id == g_TMO_MenuClearTimedMaps) DisplayYesNoPanel(client, "Do you really want to clear all map timings?", ClearTMAllPanelHandler);
		else if (object_id == g_TMO_MenuRemoveCustomMaps) DisplayYesNoPanel(client, "Do you really want to remove the custom maps?", RemoveCustomMapsPanelHandler);
		else if (object_id == g_TMO_MenuCleanPlayers) DisplayYesNoPanel(client, "Do you really want to clean the player stats?", CleanPlayersPanelHandler);
		else if (object_id == g_TMO_MenuClear) Menu_CreateClearMenu(client);
	}
}

void DisplayYesNoPanel(int client, const char[] title, MenuHandler handler, int delay = 30)
{
	if (!client)
		return;

	Panel panel = new Panel();

	panel.SetTitle(title);
	panel.DrawItem("Yes");
	panel.DrawItem("No");
	panel.Send(client, handler, delay);

	delete panel;
}

int Menu_CreateTimedMapsMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (!menu)
		return 0;

	if (action == MenuAction_End)
		delete menu;

	if (action != MenuAction_Select || param1 <= 0 || IsClientBot(param1))
		return 0;

	char Info[2];
	bool found = menu.GetItem(param2, Info, sizeof(Info));

	if (!found)
		return 0;

	DisplayTimedMapsMenu2FromInfo(param1, Info);

	return 0;
}

void DisplayTimedMapsMenu2FromInfo(int client, char[] Info)
{
	if (!TimedMapsMenuInfoMarker(Info, 2))
	{
		Cmd_TimedMaps(client, 0);
		return;
	}

	strcopy(g_sMapTimingMenuInfo[client], MAX_LINE_WIDTH, Info);

	int Gamemode = StringToInt(Info);
	DisplayTimedMapsMenu2(client, Gamemode);
}

void DisplayTimedMapsMenu2(int client, int Gamemode)
{
	char query[256];
	Format(query, sizeof(query), "SELECT DISTINCT tm.gamemode, tm.map FROM %stimedmaps AS tm INNER JOIN %splayers AS p ON tm.steamid = p.steamid WHERE tm.gamemode = %i ORDER BY tm.map ASC", g_sDbPrefix, g_sDbPrefix, Gamemode);
	SQL_TQuery(db, CreateTimedMapsMenu2, query, client);
}

int Menu_CreateTimedMapsMenu2Hndl(Menu menu, MenuAction action, int param1, int param2)
{
	if (!menu)
		return 0;

	if (action == MenuAction_End)
		delete menu;

	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
			Cmd_TimedMaps(param1, 0);

		return 0;
	}

	if (action != MenuAction_Select || param1 <= 0 || IsClientBot(param1))
		return 0;

	char Info[MAX_LINE_WIDTH];
	bool found = menu.GetItem(param2, Info, sizeof(Info));

	if (!found)
		return 0;

	DisplayTimedMapsMenu3FromInfo(param1, Info);

	return 0;
}

void DisplayTimedMapsMenu3FromInfo(int client, char[] Info)
{
	if (!TimedMapsMenuInfoMarker(Info, 3))
	{
		Cmd_TimedMaps(client, 0);
		return;
	}

	strcopy(g_sMapTimingMenuInfo[client], MAX_LINE_WIDTH, Info);

	char GamemodeInfo[2], Map[MAX_LINE_WIDTH];
	strcopy(GamemodeInfo, sizeof(GamemodeInfo), Info);
	GamemodeInfo[1] = 0;

	strcopy(Map, sizeof(Map), Info[2]);
	DisplayTimedMapsMenu3(client, StringToInt(GamemodeInfo), Map);
}

void DisplayTimedMapsMenu3(int client, int Gamemode, const char[] Map)
{
	DataPack dp = new DataPack();

	dp.WriteCell(client);
	dp.WriteCell(Gamemode);
	dp.WriteString(Map);

	char SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));

	char query[256];
	Format(query, sizeof(query), "SELECT tm.time FROM %stimedmaps AS tm INNER JOIN %splayers AS p ON tm.steamid = p.steamid WHERE tm.gamemode = %i AND tm.map = '%s' AND p.steamid = '%s'", g_sDbPrefix, g_sDbPrefix, Gamemode, Map, SteamID);
	SQL_TQuery(db, DisplayTimedMapsMenu3_2, query, dp);
}

int Menu_CreateTimedMapsMenu3Hndl(Menu menu, MenuAction action, int param1, int param2)
{
	if (!menu)
		return 0;

	if (action == MenuAction_End)
		delete menu;

	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
			DisplayTimedMapsMenu2FromInfo(param1, g_sMapTimingMenuInfo[param1]);

		return 0;
	}

	if (action != MenuAction_Select || param1 <= 0 || IsClientBot(param1))
		return 0;

	char Info[MAX_LINE_WIDTH];
	bool found = menu.GetItem(param2, Info, sizeof(Info));

	if (!found)
		return 0;

	DisplayTimedMapsMenu4FromInfo(param1, Info);

	return 0;
}

void DisplayTimedMapsMenu4FromInfo(int client, char[] Info)
{
	if (!TimedMapsMenuInfoMarker(Info, 4))
	{
		Cmd_TimedMaps(client, 0);
		return;
	}

	strcopy(g_sMapTimingMenuInfo[client], MAX_LINE_WIDTH, Info);

	char GamemodeInfo[2], Map[MAX_LINE_WIDTH];
	strcopy(GamemodeInfo, sizeof(GamemodeInfo), Info);
	GamemodeInfo[1] = 0;

	int Position = FindCharInString(Info[2], '\\');
	if (Position < 0)
	{
		LogError("Timed Maps menu 4 error: Info = \"%s\"", Info);
		return;
	}

	Position += 2;

	strcopy(Map, sizeof(Map), Info[2]);
	Map[Position - 2] = '\0';

	char MapTime[MAX_LINE_WIDTH];
	strcopy(MapTime, sizeof(MapTime), Info[Position + 1]);
	DisplayTimedMapsMenu4(client, StringToInt(GamemodeInfo), Map, StringToFloat(MapTime));
}

void DisplayTimedMapsMenu4(int client, int Gamemode, const char[] Map, float MapTime)
{
	char query[256];
	Format(query, sizeof(query), "SELECT tm.steamid, p.name FROM %stimedmaps AS tm INNER JOIN %splayers AS p ON tm.steamid = p.steamid WHERE tm.gamemode = %i AND tm.map = '%s' AND tm.time = %f ORDER BY p.name ASC", g_sDbPrefix, g_sDbPrefix, Gamemode, Map, MapTime);
	SQL_TQuery(db, CreateTimedMapsMenu4, query, client);
}

int Menu_CreateTimedMapsMenu4Hndl(Menu menu, MenuAction action, int param1, int param2)
{
	if (!menu)
		return 0;

	if (action == MenuAction_End)
		delete menu;

	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
			DisplayTimedMapsMenu3FromInfo(param1, g_sMapTimingMenuInfo[param1]);

		return 0;
	}

	if (action != MenuAction_Select || param1 <= 0 || IsClientBot(param1))
		return 0;

	char SteamID[MAX_LINE_WIDTH];
	bool found = menu.GetItem(param2, SteamID, sizeof(SteamID));

	if (!found)
		return 0;

	QueryClientStatsSteamID(param1, SteamID, CM_RANK);

	return 0;
}

int Menu_CreateRanksMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (!menu)
		return 0;

	if (action == MenuAction_End)
		delete menu;

	if (action != MenuAction_Select || param1 <= 0 || IsClientBot(param1))
		return 0;

	char SteamID[MAX_LINE_WIDTH];
	bool found = menu.GetItem(param2, SteamID, sizeof(SteamID));

	if (!found)
		return 0;

	QueryClientStatsSteamID(param1, SteamID, CM_RANK);

	return 0;
}

int Menu_CreateRankMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (!menu)
		return 0;

	if (action == MenuAction_End)
		delete menu;

	if (action != MenuAction_Select || param1 <= 0 || IsClientBot(param1))
		return 0;

	char Info[MAX_LINE_WIDTH];
	bool found = menu.GetItem(param2, Info, sizeof(Info));

	if (!found)
		return 0;

	if (strcmp(Info, "rankabout", false) == 0)
	{
		DisplayAboutPanel(param1);
		return 0;
	}

	else if (strcmp(Info, "showsettings", false) == 0)
	{
		DisplaySettingsPanel(param1);
		return 0;
	}

	HandleCommands(param1, Info);

	return 0;
}

// Send the RANKABOUT panel to the client's display.
void DisplayAboutPanel(int client)
{
	char Value[MAX_LINE_WIDTH];

	Panel panel = new Panel();

	Format(Value, sizeof(Value), "About [L4D/L4D2] Statistic:");
	panel.SetTitle(Value);

	Format(Value, sizeof(Value), "Version: %s", PLUGIN_VERSION);
	panel.DrawText(Value);

	Format(Value, sizeof(Value), "Author: %s", "Mikko Andersson (muukis), blueblur (Modifieder)");
	panel.DrawText(Value);

	Format(Value, sizeof(Value), "Description: %s", "Record player statistics.");
	panel.DrawText(Value);

	panel.DrawItem("Back");
	panel.DrawItem("Close");

	panel.Send(client, AboutPanelHandler, 30);
	delete panel;
}

// Send the RANKABOUT panel to the client's display.
void DisplaySettingsPanel(int client)
{
	char Value[MAX_LINE_WIDTH];

	Panel panel = new Panel();

	Format(Value, sizeof(Value), "Plugin Settings:");
	panel.SetTitle(Value);

	panel.DrawItem((g_bClientRankMute[client] ? "Unmute (Currently: Muted)" : "Mute (Currently: Not muted)"));

	panel.DrawItem("Back");
	panel.DrawItem("Close");

	panel.Send(client, SettingsPanelHandler, 30);
	delete panel;
}

// Handler for RANK panel.
int RankPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	return 0;
}

// Handler for NEXTRANK panel.
int NextRankPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (param2 == 1)
		QueryClientStats(param1, CM_NEXTRANKFULL);

	return 0;
}

// Handler for NEXTRANK panel.
int NextRankFullPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	return 0;
}

// Handler for TIMEDMAPS panel.
int TimedMapsPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	return 0;
}

// Handler for RANKADMIN panel.
//public RankAdminPanelHandler(Menu menu, MenuAction action, int param1, int param2)
//{
//	if (action != MenuAction_Select)
//		return;
//
//	if (param2 == 1)
//		DisplayClearPanel(param1);
//	else if (param2 == 2)
//		DisplayYesNoPanel(param1, "Do you really want to clear the player stats?", ClearPlayersPanelHandler);
//	else if (param2 == 3)
//		DisplayYesNoPanel(param1, "Do you really want to clear the map stats?", ClearMapsPanelHandler);
//	else if (param2 == 4)
//		DisplayYesNoPanel(param1, "Do you really want to clear all stats?", ClearAllPanelHandler);
//}

// Handler for RANKADMIN panel.
int ClearPlayersPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action != MenuAction_Select)
		return 0;

	if (param2 == 1)
	{
		ClearStatsPlayers(param1);
		StatsPrintToChatPreFormatted(param1, "All player stats cleared!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);

	return 0;
}

// Handler for RANKADMIN panel.
int ClearMapsPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action != MenuAction_Select)
		return 0;

	if (param2 == 1)
	{
		ClearStatsMaps(param1);
		StatsPrintToChatPreFormatted(param1, "All map stats cleared!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);

	return 0;
}

// Handler for RANKADMIN panel.
int ClearAllPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action != MenuAction_Select)
		return 0;

	if (param2 == 1)
	{
		ClearStatsAll(param1);
		StatsPrintToChatPreFormatted(param1, "All stats cleared!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);

	return 0;
}

// Handler for RANKADMIN panel.
int CleanPlayersPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action != MenuAction_Select)
		return 0;

	if (param2 == 1)
	{
		int LastOnTimeMonths = g_hCvar_AdminPlayerCleanLastOnTime.IntValue;
		int PlaytimeMinutes = g_hCvar_AdminPlayerCleanPlatime.IntValue;

		if (LastOnTimeMonths || PlaytimeMinutes)
		{
			bool Success = true;

			if (LastOnTimeMonths)
				Success &= DoFastQuery(param1, "DELETE FROM %splayers WHERE lastontime < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL %i MONTH))", g_sDbPrefix, LastOnTimeMonths);

			if (PlaytimeMinutes)
				Success &= DoFastQuery(param1, "DELETE FROM %splayers WHERE %s < %i AND lastontime < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 1 HOUR))", g_sDbPrefix, DB_PLAYERS_TOTALPLAYTIME, PlaytimeMinutes);

			if (Success)
				StatsPrintToChatPreFormatted(param1, "Player cleaning successful!");
			else
				StatsPrintToChatPreFormatted(param1, "Player cleaning failed!");
		}
		else
			StatsPrintToChatPreFormatted(param1, "Player cleaning is disabled by configurations!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);

	return 0;
}

// Handler for RANKADMIN panel.
int RemoveCustomMapsPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action != MenuAction_Select)
		return 0;

	if (param2 == 1)
	{
		if (DoFastQuery(param1, "DELETE FROM %smaps WHERE custom = 1", g_sDbPrefix))
			StatsPrintToChatPreFormatted(param1, "All custom maps removed!");
		else
			StatsPrintToChatPreFormatted(param1, "Removing custom maps failed!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);

	return 0;
}

// Handler for RANKADMIN panel.
int ClearTMAllPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action != MenuAction_Select)
		return 0;

	if (param2 == 1)
	{
		if (DoFastQuery(param1, "DELETE FROM %stimedmaps", g_sDbPrefix))
			StatsPrintToChatPreFormatted(param1, "All map timings removed!");
		else
			StatsPrintToChatPreFormatted(param1, "Removing map timings failed!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);

	return 0;
}

// Handler for RANKADMIN panel.
int ClearTMCoopPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action != MenuAction_Select)
		return 0;

	if (param2 == 1)
	{
		if (DoFastQuery(param1, "DELETE FROM %stimedmaps WHERE gamemode = %i", g_sDbPrefix, GAMEMODE_COOP))
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Coop successful!");
		else
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Coop failed!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);

	return 0;
}

// Handler for RANKADMIN panel.
int ClearTMSurvivalPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action != MenuAction_Select)
		return 0;

	if (param2 == 1)
	{
		if (DoFastQuery(param1, "DELETE FROM %stimedmaps WHERE gamemode = %i", g_sDbPrefix, GAMEMODE_SURVIVAL))
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Survival successful!");
		else
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Survival failed!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);

	return 0;
}

// Handler for RANKADMIN panel.
int ClearTMRealismPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action != MenuAction_Select)
		return 0;

	if (param2 == 1)
	{
		if (DoFastQuery(param1, "DELETE FROM %stimedmaps WHERE gamemode = %i", g_sDbPrefix, GAMEMODE_REALISM))
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Realism successful!");
		else
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Realism failed!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);

	return 0;
}

// Handler for RANKADMIN panel.
int ClearTMMutationsPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action != MenuAction_Select)
		return 0;

	if (param2 == 1)
	{
		if (DoFastQuery(param1, "DELETE FROM %stimedmaps WHERE gamemode = %i", g_sDbPrefix, GAMEMODE_OTHERMUTATIONS))
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Mutations successful!");
		else
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Mutations failed!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);

	return 0;
}

// Handler for RANKVOTE panel.
int RankVotePanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action != MenuAction_Select || !g_hRankVoteTimer || param1 <= 0 || IsClientBot(param1))
		return 0;

	if (param2 == 1 || param2 == 2)
	{
		int team = GetClientTeam(param1);

		if (team != TEAM_SURVIVORS && team != TEAM_INFECTED)
			return 0;

		int OldPlayerRankVote = g_iPlayerRankVote[param1];

		if (param2 == 1)
			g_iPlayerRankVote[param1] = RANKVOTE_YES;
		else if (param2 == 2)
			g_iPlayerRankVote[param1] = RANKVOTE_NO;

		int humans = 0, votes = 0, yesvotes = 0, novotes = 0, WinningVoteCount = 0;
		CheckRankVotes(humans, votes, yesvotes, novotes, WinningVoteCount);

		if (yesvotes >= WinningVoteCount || novotes >= WinningVoteCount)
		{
			if (g_hRankVoteTimer != null)
				delete g_hRankVoteTimer;

			StatsPrintToChatAll("Vote to shuffle teams by player PPM \x03%s \x01with \x04%i (yes) against %i (no)\x01.", (yesvotes >= WinningVoteCount ? "PASSED" : "DID NOT PASS"), yesvotes, novotes);

			if (yesvotes >= WinningVoteCount)
				CreateTimer(2.0, Timer_ShuffleTeams);
		}

		if (OldPlayerRankVote != RANKVOTE_NOVOTE)
			return 0;

		char Name[32];
		GetClientName(param1, Name, sizeof(Name));
		StatsPrintToChatAll("\x05%s \x01voted. \x04%i/%i \x01players have voted.", Name, votes, humans);
	}

	return 0;
}

void CheckRankVotes(int &Humans, int &Votes, int &YesVotes, int &NoVotes, int &WinningVoteCount)
{
	Humans = 0;
	Votes = 0;
	YesVotes = 0;
	NoVotes = 0;
	WinningVoteCount = 0;

	int team;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			team = GetClientTeam(i);
			if (team == TEAM_SURVIVORS || team == TEAM_INFECTED)
			{
				Humans++;
				if (g_iPlayerRankVote[i] != RANKVOTE_NOVOTE)
				{
					Votes++;
					if (g_iPlayerRankVote[i] == RANKVOTE_YES)
						YesVotes++;
				}
			}
		}
	}

	// More than half of the players are needed to vot YES for rankvote pass
	WinningVoteCount = RoundToNearest(float(Humans) / 2) + 1 - (Humans % 2);
	NoVotes = Votes - YesVotes;
}

void DisplayClearPanel(int client, int delay = 30)
{
	if (!client)
		return;

	//if (ClearPlayerMenu != INVALID_HANDLE)
	//{
	//	CloseHandle(ClearPlayerMenu);
	//	ClearPlayerMenu = INVALID_HANDLE;
	//}

	Menu ClearPlayerMenu = new Menu(DisplayClearPanelHandler);
	char id[3], Name[32];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientBot(i) || !IsClientConnected(i) || !IsClientInGame(i))
			continue;

		GetClientName(i, Name, sizeof(Name));
		IntToString(i, id, sizeof(id));

		ClearPlayerMenu.AddItem(id, Name);
	}

	ClearPlayerMenu.SetTitle("Clear player stats:");
	ClearPlayerMenu.Display(client, delay);
}

// Handler for RANKADMIN panel.
int DisplayClearPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (!menu)
		return 0;

	if (action == MenuAction_End)
		delete menu;

	if (action != MenuAction_Select || param1 <= 0 || IsClientBot(param1))
		return 0;

	char id[3];
	bool found = menu.GetItem(param2, id, sizeof(id));

	if (!found)
		return 0;

	int client = StringToInt(id);

	char SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));

	if (DoFastQuery(param1, "DELETE FROM %splayers WHERE steamid = '%s'", g_sDbPrefix, SteamID))
	{
		DoFastQuery(param1, "DELETE FROM %stimedmaps WHERE steamid = '%s'", g_sDbPrefix, SteamID);

		g_iClientPoints[client] = 0;
		g_iClientRank[client] = 0;

		char Name[32];
		GetClientName(client, Name, sizeof(Name));

		StatsPrintToChatPreFormatted(client, "Your player stats were cleared!");
		if (client != param1)
			StatsPrintToChat(param1, "Player \x05%s \x01stats cleared!", Name);
	}
	else
		StatsPrintToChatPreFormatted(param1, "Clearing player stats failed!");

	return 0;
}

// Handler for RANKABOUT panel.
int AboutPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1)
			Cmd_ShowRankMenu(param1, 0);
	}

	return 0;
}

// Handler for RANK SETTINGS panel.
int SettingsPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1)
			Cmd_ToggleClientRankMute(param1, 0);
		if (param2 == 2)
			Cmd_ShowRankMenu(param1, 0);
	}

	return 0;
}

// Handler for TOP10 panel.
int Top10PanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 0)
			param2 = 10;

		GetClientFromTop10(param1, param2 - 1);
	}

	return 0;
}

// Handler for TOP10PPM panel.
int Top10PPMPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 0)
			param2 = 10;

		GetClientFromTop10PPM(param1, param2 - 1);
	}

	return 0;
}

// Send the NEXTRANK panel to the client's display.
void DisplayNextRank(int client)
{
	if (!client)
		return;

	Panel NextRankPanel = new Panel();
	char Value[MAX_LINE_WIDTH];

	NextRankPanel.SetTitle("Next Rank:");

	if (g_iClientNextRank[client])
	{
		Format(Value, sizeof(Value), "Points required: %i", g_iClientNextRank[client]);
		NextRankPanel.DrawText(Value);

		Format(Value, sizeof(Value), "Current rank: %i", g_iClientRank[client]);
		NextRankPanel.DrawText(Value);
	}
	else
		NextRankPanel.DrawText("You are 1st");

	NextRankPanel.DrawItem("More...");
	NextRankPanel.DrawItem("Close");
	NextRankPanel.Send(client, NextRankPanelHandler, 30);
	delete NextRankPanel;
}

void DisplayRankMenu(int client)
{
	char Title[MAX_LINE_WIDTH];

	Format(Title, sizeof(Title), "[L4D] Statistic:");

	Menu menu = new Menu(Menu_CreateRankMenuHandler);

	menu.SetTitle(Title);
	menu.ExitBackButton = false;
	menu.ExitButton = true;

	menu.AddItem("rank", "Show my rank");
	menu.AddItem("top10", "Show top 10");
	menu.AddItem("top10ppm", "Show top 10 PPM");
	menu.AddItem("nextrank", "Show my next rank");
	menu.AddItem("showtimer", "Show current timer");
	menu.AddItem("showrank", "Show others rank");
	menu.AddItem("showppm", "Show others PPM");
	if (g_hCvar_EnableRankVote.BoolValue && IsTeamGamemode())
		menu.AddItem("rankvote", "Vote for team shuffle by PPM");

	menu.AddItem("timedmaps", "Show all map timings");

	if (IsSingleTeamGamemode())
		menu.AddItem("maptimes", "Show current map timings");

	if (g_hCvar_AnnounceMode.IntValue)
		menu.AddItem("showsettings", "Modify rank settings");

	//AddMenuItem(menu, "showmaptimes", "Show others current map timings");

	Format(Title, sizeof(Title), "About [L4D] Statistic");
	menu.AddItem("rankabout", Title);
	menu.Display(client, 30);

	if (g_bEnableSounds_Rankmenu_Show && g_hCvar_SoundsEnabled.BoolValue)
		EmitSoundToClient(client, g_sStatsSound_Rankmenu_Show);
}

void CreateRanksMenu(Handle owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client || !hndl)
	{
		LogError("CreateRanksMenu failed! Reason: %s", error);
		return;
	}

	char SteamID[MAX_LINE_WIDTH];
	Menu menu = new Menu(Menu_CreateRanksMenuHandler);

	char Name[32], DisplayName[MAX_LINE_WIDTH];
	menu.SetTitle("Player Ranks:");
	menu.ExitBackButton = false;
	menu.ExitButton = true;

	while (hndl.FetchRow())
	{
		hndl.FetchString(0, SteamID, sizeof(SteamID));
		hndl.FetchString(1, Name, sizeof(Name));

		ReplaceString(Name, sizeof(Name), "&lt;", "<");
		ReplaceString(Name, sizeof(Name), "&gt;", ">");
		ReplaceString(Name, sizeof(Name), "&#37;", "%");
		ReplaceString(Name, sizeof(Name), "&#61;", "=");
		ReplaceString(Name, sizeof(Name), "&#42;", "*");

		Format(DisplayName, sizeof(DisplayName), "%s (%i points)", Name, hndl.FetchInt(2));
		menu.AddItem(SteamID, DisplayName);
	}

	menu.Display(client, 30);
}

void CreateTimedMapsMenu(Handle owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client || !hndl)
	{
		LogError("CreateTimedMapsMenu failed! Reason: %s", error);
		return;
	}

	if (hndl.RowCount <= 0)
	{
		Panel TimedMapsPanel = new Panel();
		TimedMapsPanel.SetTitle("Timed Maps:");
		TimedMapsPanel.DrawText("There are no recorded map timings!");
		TimedMapsPanel.DrawItem("Close");
		TimedMapsPanel.Send(client, TimedMapsPanelHandler, 30);

		delete TimedMapsPanel;
		return;
	}

	int Gamemode;
	Menu menu = new Menu(Menu_CreateTimedMapsMenuHandler);
	char GamemodeTitle[32], GamemodeInfo[2]; //, MutationInfo[MAX_LINE_WIDTH];

	menu.SetTitle("Timed Maps:");
	menu.ExitBackButton = false;
	menu.ExitButton = true;

	while (hndl.FetchRow())
	{
		Gamemode = hndl.FetchInt(0);
		IntToString(Gamemode, GamemodeInfo, sizeof(GamemodeInfo));

		switch (Gamemode)
		{
			case GAMEMODE_COOP: strcopy(GamemodeTitle, sizeof(GamemodeTitle), "Co-op");
			case GAMEMODE_SURVIVAL: strcopy(GamemodeTitle, sizeof(GamemodeTitle), "Survival");
			case GAMEMODE_REALISM: strcopy(GamemodeTitle, sizeof(GamemodeTitle), "Realism");
			case GAMEMODE_OTHERMUTATIONS:
			{
				strcopy(GamemodeTitle, sizeof(GamemodeTitle), "Mutations");
				//SQL_FetchString(hndl, 1, MutationInfo, sizeof(MutationInfo));
				//Format(GamemodeTitle, sizeof(GamemodeTitle), "Mutations (%s)", MutationInfo);
			}
			default:
				continue;
		}

		if (g_iCurrentGamemodeID == Gamemode)
			StrCat(GamemodeTitle, sizeof(GamemodeTitle), TM_MENU_CURRENT);

		menu.AddItem(GamemodeInfo, GamemodeTitle);
	}

	menu.Display(client, 30);
}

void CreateTimedMapsMenu2(Handle owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client || !hndl)
	{
		LogError("CreateTimedMapsMenu2 failed! Reason: %s", error);
		return;
	}

	if (hndl.RowCount <= 0)
	{
		Panel TimedMapsPanel = new Panel();
		TimedMapsPanel.SetTitle("Timed Maps:");
		TimedMapsPanel.DrawText("There are no recorded times for this gamemode!");
		TimedMapsPanel.DrawItem("Close");
		TimedMapsPanel.Send(client, TimedMapsPanelHandler, 30);
		delete TimedMapsPanel;

		return;
	}

	Menu menu = new Menu(Menu_CreateTimedMapsMenu2Hndl);
	int Gamemode;
	char Map[MAX_LINE_WIDTH], Info[MAX_LINE_WIDTH], CurrentMapName[MAX_LINE_WIDTH];
	GetCurrentMap(CurrentMapName, sizeof(CurrentMapName));

	menu.SetTitle("Timed Maps:");
	menu.ExitBackButton = true;
	menu.ExitButton = true;

	while (hndl.FetchRow())
	{
		Gamemode = hndl.FetchInt(0);
		hndl.FetchString(1, Map, sizeof(Map));

		Format(Info, sizeof(Info), "%i\\%s", Gamemode, Map);

		if (g_iCurrentGamemodeID == Gamemode && StrEqual(CurrentMapName, Map))
			StrCat(Map, sizeof(Map), TM_MENU_CURRENT);

		menu.AddItem(Info, Map);
	}

	menu.Display(client, 30);
}

void DisplayTimedMapsMenu3_2(Handle owner, DBResultSet hndl, const char[] error, DataPack dp)
{
	if (!hndl)
	{
		if (dp)
			delete dp;

		LogError("DisplayTimedMapsMenu3_2 failed! Reason: %s", error);
		return;
	}

	dp.Reset();

	int client = dp.ReadCell();
	int Gamemode = dp.ReadCell();
	char Map[MAX_LINE_WIDTH];
	dp.ReadString(Map, sizeof(Map));

	delete dp;

	if (hndl.FetchRow())
		g_fClientMapTime[client] = hndl.FetchFloat(0);
	else
		g_fClientMapTime[client] = 0.0;

	char query[256];
	Format(query, sizeof(query), "SELECT DISTINCT tm.gamemode, tm.map, tm.time FROM %stimedmaps AS tm INNER JOIN %splayers AS p ON tm.steamid = p.steamid WHERE tm.gamemode = %i AND tm.map = '%s' ORDER BY tm.time %s", g_sDbPrefix, g_sDbPrefix, Gamemode, Map, (Gamemode == GAMEMODE_SURVIVAL ? "DESC" : "ASC"));
	SQL_TQuery(db, CreateTimedMapsMenu3, query, client);
}

void CreateTimedMapsMenu3(Handle owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client || !hndl)
	{
		LogError("CreateTimedMapsMenu3 failed! Reason: %s", error);
		return;
	}

	if (hndl.RowCount <= 0)
	{
		Panel TimedMapsPanel = new Panel();
		TimedMapsPanel.SetTitle("Timed Maps:");
		TimedMapsPanel.DrawText("There are no recorded times for this map!");
		TimedMapsPanel.DrawItem("Close");
		TimedMapsPanel.Send(client, TimedMapsPanelHandler, 30);
		delete TimedMapsPanel;

		return;
	}

	Menu menu = new Menu(Menu_CreateTimedMapsMenu3Hndl);
	float MapTime;
	char Map[MAX_LINE_WIDTH], Info[MAX_LINE_WIDTH], Value[MAX_LINE_WIDTH];

	menu.SetTitle("Timed Maps:");
	menu.ExitBackButton = true;
	menu.ExitButton = true;

	while (hndl.FetchRow())
	{
		hndl.FetchString(1, Map, sizeof(Map));
		MapTime = hndl.FetchFloat(2);

		SetTimeLabel(MapTime, Value, sizeof(Value));
		Format(Info, sizeof(Info), "%i\\%s\\%f", hndl.FetchInt(0), Map, MapTime);

		if (g_fClientMapTime[client] > 0.0 && g_fClientMapTime[client] == MapTime)
			StrCat(Value, sizeof(Value), TM_MENU_CURRENT);

		menu.AddItem(Info, Value);
	}

	menu.Display(client, 30);
}

void CreateTimedMapsMenu4(Handle owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client || !hndl)
	{
		LogError("CreateTimedMapsMenu4 failed! Reason: %s", error);
		return;
	}

	Menu menu = new Menu(Menu_CreateTimedMapsMenu4Hndl);

	char Name[32], SteamID[MAX_LINE_WIDTH];
	menu.SetTitle("Timed Maps:");
	menu.ExitBackButton = true;
	menu.ExitButton = true;

	while (hndl.FetchRow())
	{
		hndl.FetchString(0, SteamID, sizeof(SteamID));
		hndl.FetchString(1, Name, sizeof(Name));

		ReplaceString(Name, sizeof(Name), "&lt;", "<");
		ReplaceString(Name, sizeof(Name), "&gt;", ">");
		ReplaceString(Name, sizeof(Name), "&#37;", "%");
		ReplaceString(Name, sizeof(Name), "&#61;", "=");
		ReplaceString(Name, sizeof(Name), "&#42;", "*");

		menu.AddItem(SteamID, Name);
	}

	menu.Display(client, 30);
}

void CreatePPMMenu(Handle owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client || !hndl)
	{
		LogError("CreatePPMMenu failed! Reason: %s", error);
		return;
	}

	char SteamID[MAX_LINE_WIDTH];
	Menu menu = new Menu(Menu_CreateRanksMenuHandler);

	char Name[32], DisplayName[MAX_LINE_WIDTH];

	menu.SetTitle("Player PPM:");
	menu.ExitBackButton = false;
	menu.ExitButton = true;

	while (hndl.FetchRow())
	{
		hndl.FetchString(0, SteamID, sizeof(SteamID));
		hndl.FetchString(1, Name, sizeof(Name));

		ReplaceString(Name, sizeof(Name), "&lt;", "<");
		ReplaceString(Name, sizeof(Name), "&gt;", ">");
		ReplaceString(Name, sizeof(Name), "&#37;", "%");
		ReplaceString(Name, sizeof(Name), "&#61;", "=");
		ReplaceString(Name, sizeof(Name), "&#42;", "*");

		Format(DisplayName, sizeof(DisplayName), "%s (PPM: %.2f)", Name, hndl.FetchFloat(2));
		menu.AddItem(SteamID, DisplayName);
	}

	menu.Display(client, 30);
}

// Send the TOP10 panel to the client's display.
void DisplayTop10(Handle owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client || !hndl)
	{
		LogError("DisplayTop10 failed! Reason: %s", error);
		return;
	}

	char Name[32];
	Panel Top10Panel = new Panel();
	Top10Panel.SetTitle("Top 10 Players");

	while (hndl.FetchRow())
	{
		hndl.FetchString(0, Name, sizeof(Name));

		ReplaceString(Name, sizeof(Name), "&lt;", "<");
		ReplaceString(Name, sizeof(Name), "&gt;", ">");
		ReplaceString(Name, sizeof(Name), "&#37;", "%");
		ReplaceString(Name, sizeof(Name), "&#61;", "=");
		ReplaceString(Name, sizeof(Name), "&#42;", "*");

		Top10Panel.DrawItem(Name);
	}

	Top10Panel.Send(client, Top10PanelHandler, 30);
	delete Top10Panel;
}

// Send the TOP10PPM panel to the client's display.
void DisplayTop10PPM(Handle owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client || !hndl)
	{
		LogError("DisplayTop10PPM failed! Reason: %s", error);
		return;
	}

	char Name[32], Disp[MAX_LINE_WIDTH];

	Panel TopPPMPanel = new Panel();
	TopPPMPanel.SetTitle("Top 10 PPM Players");

	while (hndl.FetchRow())
	{
		hndl.FetchString(0, Name, sizeof(Name));

		ReplaceString(Name, sizeof(Name), "&lt;", "<");
		ReplaceString(Name, sizeof(Name), "&gt;", ">");
		ReplaceString(Name, sizeof(Name), "&#37;", "%");
		ReplaceString(Name, sizeof(Name), "&#61;", "=");
		ReplaceString(Name, sizeof(Name), "&#42;", "*");

		Format(Disp, sizeof(Disp), "%s (PPM: %.2f)", Name, hndl.FetchFloat(1));

		TopPPMPanel.DrawItem(Disp);
	}

	TopPPMPanel.Send(client, Top10PPMPanelHandler, 30);
	delete TopPPMPanel;
}

// Send the NEXTRANK panel to the client's display.
void DisplayNextRankFull(Handle owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client)
		return;

	if (!hndl)
	{
		LogError("DisplayNextRankFull Query failed: %s", error);
		return;
	}

	if(hndl.RowCount <= 1)
		return;

	int Points;
	char Name[32];

	Panel NextRankPanel = new Panel();
	char Value[MAX_LINE_WIDTH];

	NextRankPanel.SetTitle("Next Rank:");

	if (g_iClientNextRank[client])
	{
		Format(Value, sizeof(Value), "Points required: %i", g_iClientNextRank[client]);
		NextRankPanel.DrawText(Value);

		Format(Value, sizeof(Value), "Current rank: %i", g_iClientRank[client]);
		NextRankPanel.DrawText(Value);
	}
	else
		NextRankPanel.DrawText("You are 1st");

	while (hndl.FetchRow())
	{
		hndl.FetchString(0, Name, sizeof(Name));
		Points = hndl.FetchInt(1);

		Format(Value, sizeof(Value), "%i points: %s", Points, Name);
		NextRankPanel.DrawText(Value);
	}

	NextRankPanel.DrawItem("Close");
	NextRankPanel.Send(client, NextRankFullPanelHandler, 30);
	delete NextRankPanel;
}

// Send the RANK panel to the client's display.
void DisplayRank(Handle owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client)
		return;

	if (!hndl)
	{
		LogError("DisplayRank Query failed: %s", error);
		return;
	}

	float PPM;
	int Playtime, Points, InfectedKilled, SurvivorsKilled, Headshots;
	char Name[32];

	if (hndl.FetchRow())
	{
		hndl.FetchString(0, Name, sizeof(Name));
		Playtime = hndl.FetchInt(1);
		Points = hndl.FetchInt(2);
		InfectedKilled = hndl.FetchInt(3);
		SurvivorsKilled = hndl.FetchInt(4);
		Headshots = hndl.FetchInt(5);
		PPM = float(Points) / float(Playtime);
	}
	else
	{
		GetClientName(client, Name, sizeof(Name));
		Playtime = 0;
		Points = 0;
		InfectedKilled = 0;
		SurvivorsKilled = 0;
		Headshots = 0;
		PPM = 0.0;
	}

	Panel RankPanel = new Panel();
	char Value[MAX_LINE_WIDTH];
	char URL[MAX_LINE_WIDTH];

	g_hCvar_SiteURL.GetString(URL, sizeof(URL));
	float HeadshotRatio = Headshots == 0 ? 0.00 : (float(Headshots)/float(InfectedKilled))*100;

	Format(Value, sizeof(Value), "Ranking of %s" , Name);
	RankPanel.SetTitle(Value);

	Format(Value, sizeof(Value), "Rank: %i of %i" , g_iClientRank[client], g_iRankTotal);
	RankPanel.DrawText(Value);

	if (!InvalidGameMode())
	{
		Format(Value, sizeof(Value), "%s Rank: %i of %i" ,g_sCurrentGamemodeLabel , g_iClientGameModeRank[client], g_iGameModeRankTotal);
		RankPanel.DrawText(Value);
	}

	if (Playtime > 60)
	{
		Format(Value, sizeof(Value), "Playtime: %.2f hours" , float(Playtime)/60.0);
		RankPanel.DrawText(Value);
	}
	else
	{
		Format(Value, sizeof(Value), "Playtime: %i min" , Playtime);
		RankPanel.DrawText(Value);
	}

	Format(Value, sizeof(Value), "Points: %i" , Points);
	RankPanel.DrawText(Value);

	Format(Value, sizeof(Value), "PPM: %.2f" , PPM);
	RankPanel.DrawText(Value);

	Format(Value, sizeof(Value), "Infected Killed: %i" , InfectedKilled);
	RankPanel.DrawText(Value);

	Format(Value, sizeof(Value), "Survivors Killed: %i" , SurvivorsKilled);
	RankPanel.DrawText(Value);

	Format(Value, sizeof(Value), "Headshots: %i" , Headshots);
	RankPanel.DrawText(Value);

	Format(Value, sizeof(Value), "Headshot Ratio: %.2f %" , HeadshotRatio);
	RankPanel.DrawText(Value);

	if (!StrEqual(URL, "", false))
	{
		Format(Value, sizeof(Value), "For full stats visit %s", URL);
		RankPanel.DrawText(Value);
	}

	//DrawPanelItem(RankPanel, "Next Rank");
	RankPanel.DrawItem("Close");
	RankPanel.Send(client, RankPanelHandler, 30);
	delete RankPanel;
}
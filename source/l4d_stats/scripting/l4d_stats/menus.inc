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

	char title[64];
	Format(title, sizeof(title), "%T", "Menu_TileClear", client);
	menu.SetTitle(title);

	menu.ExitBackButton = true;
	menu.ExitButton = true;

	char option1[64];
	Format(option1, sizeof(option1), "%T", "Menu_OptionClearPlayers", client);
	menu.AddItem("cps", option1);

	char option2[64];
	Format(option2, sizeof(option2), "%T", "Menu_OptionClearTimedMaps", client);
	menu.AddItem("ctm", option2);
	
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

	char title[64];
	Format(title, sizeof(title), "%T", "Menu_TileClearTM", client);
	menu.SetTitle(title);

	menu.ExitBackButton = true;
	menu.ExitButton = true;

	char option1[64];
	Format(option1, sizeof(option1), "%T", "Menu_OptionClearAll", client);
	menu.AddItem("ctma",  option1);

	char option2[64];
	Format(option2, sizeof(option2), "%T", "Menu_OptionClearCoop", client);
	menu.AddItem("ctmc",  option2);

	char option3[64];
	Format(option3, sizeof(option3), "%T", "Menu_OptionClearSurvival", client);
	menu.AddItem("ctms",  option3);

	char option4[64];
	Format(option4, sizeof(option4), "%T", "Menu_OptionClearRealism", client);
	menu.AddItem("ctmr",  option4);

	char option5[64];
	Format(option5, sizeof(option5), "%T", "Menu_OptionClearMutations", client);
	menu.AddItem("ctmm",  option5);

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
				case 0:
				{
					char sBuffer[64];
					Format(sBuffer, sizeof(sBuffer), "%T", "Menu_AskClearAllMapTimings", param1);
					DisplayYesNoPanel(param1, sBuffer, ClearTMAllPanelHandler);
				}

				case 1:
				{
					char sBuffer[64];
					Format(sBuffer, sizeof(sBuffer), "%T", "Menu_AskClearAllCoopMapTimings", param1);
					DisplayYesNoPanel(param1, sBuffer, ClearTMCoopPanelHandler);
				}
				
				case 2:
				{
					char sBuffer[64];
					Format(sBuffer, sizeof(sBuffer), "%T", "Menu_AskClearAllSurvivalMapTimings", param1);
					DisplayYesNoPanel(param1, sBuffer, ClearTMSurvivalPanelHandler);
				}

				case 3:
				{
					char sBuffer[64];
					Format(sBuffer, sizeof(sBuffer), "%T", "Menu_AskClearAllRealismMapTimings", param1);
					DisplayYesNoPanel(param1, sBuffer, ClearTMRealismPanelHandler);
				}

				case 4:
				{
					char sBuffer[64];
					Format(sBuffer, sizeof(sBuffer), "%T", "Menu_AskClearAllMutationMapTimings", param1);
					DisplayYesNoPanel(param1, sBuffer, ClearTMMutationsPanelHandler);
				}
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
		if (object_id == g_TMO_MenuClearPlayers) 
		{
			char sBuffer[64];
			Format(sBuffer, sizeof(sBuffer), "%T", "Menu_AskClearPlayers", client);
			DisplayYesNoPanel(client, sBuffer, ClearPlayersPanelHandler);
		}

		else if (object_id == g_TMO_MenuClearMaps) 
		{
			char sBuffer[64];
			Format(sBuffer, sizeof(sBuffer), "%T", "Menu_AskClearAllMaps", client);
			DisplayYesNoPanel(client, sBuffer, ClearMapsPanelHandler);
		}
		else if (object_id == g_TMO_MenuClearAll)
		{
			char sBuffer[64];
			Format(sBuffer, sizeof(sBuffer), "%T", "Menu_AskClearAll", client);
			DisplayYesNoPanel(client, sBuffer, ClearAllPanelHandler);
		} 
		else if (object_id == g_TMO_MenuClearTimedMaps)
		{
			char sBuffer[64];
			Format(sBuffer, sizeof(sBuffer), "%T", "Menu_AskClearTimedMaps", client);
			DisplayYesNoPanel(client, sBuffer, ClearTMAllPanelHandler);
		} 
		else if (object_id == g_TMO_MenuRemoveCustomMaps)
		{
			char sBuffer[64];
			Format(sBuffer, sizeof(sBuffer), "%T", "Menu_AskRemoveCustomMaps", client);
			DisplayYesNoPanel(client, sBuffer, RemoveCustomMapsPanelHandler);
		} 
		else if (object_id == g_TMO_MenuCleanPlayers)
		{
			char sBuffer[64];
			Format(sBuffer, sizeof(sBuffer), "%T", "Menu_AskCleanPlayers", client);
			DisplayYesNoPanel(client, sBuffer, CleanPlayersPanelHandler);
		} 
		else if (object_id == g_TMO_MenuClear)
		{
			Menu_CreateClearMenu(client);
		} 
	}
}

void DisplayYesNoPanel(int client, const char[] title, MenuHandler handler, int delay = 30)
{
	if (!client)
		return;

	Panel panel = new Panel();

	panel.SetTitle(title);

	char yes[64];
	Format(yes, sizeof(yes), "%T", "Menu_Yes", client);
	panel.DrawItem(yes);

	char no[64];
	Format(no, sizeof(no), "%T", "Menu_No", client);
	panel.DrawItem(no);

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

	dp.Reset();
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

	Format(Value, sizeof(Value), "%T", "Menu_AboutPlugin", client);
	panel.SetTitle(Value);

	Format(Value, sizeof(Value), "%T", "Menu_Version", client, PLUGIN_VERSION);
	panel.DrawText(Value);

	Format(Value, sizeof(Value), "%T", "Menu_Author", client);
	panel.DrawText(Value);

	Format(Value, sizeof(Value), "%T", "Menu_Description", client);
	panel.DrawText(Value);

	char back[64];
	Format(back, sizeof(back), "%T", "Menu_Back", client);
	panel.DrawItem(back);

	char close[64];
	Format(close, sizeof(close), "%T", "Menu_Close", client);
	panel.DrawItem(close);

	panel.Send(client, AboutPanelHandler, 30);
	delete panel;
}

// Send the RANKABOUT panel to the client's display.
void DisplaySettingsPanel(int client)
{
	char Value[MAX_LINE_WIDTH];

	Panel panel = new Panel();

	Format(Value, sizeof(Value), "%T", "Menu_PluginSettings", client);
	panel.SetTitle(Value);

	char unmute[64], mute[64];
	Format(unmute, sizeof(unmute), "%T", "Menu_Unmute", client);
	Format(mute, sizeof(mute), "%T", "Menu_Mute", client);
	panel.DrawItem((g_bClientRankMute[client] ? unmute : mute));

	char back[64];
	Format(back, sizeof(back), "%T", "Menu_Back", client);
	panel.DrawItem(back);

	char close[64];
	Format(close, sizeof(close), "%T", "Menu_Close", client);
	panel.DrawItem(close);

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
		CPrintToChat(param1, "%t %t", "Tag", "AllPlayerStatsCleared");
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
		CPrintToChat(param1, "%t %t", "Tag", "AllMapStatsCleared");
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
		CPrintToChat(param1, "%t %t", "Tag", "AllStatsCleared");
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

			if (Success) CPrintToChat(param1, "%t %t", "Tag", "PlayerCleaningSuccessful");
			else CPrintToChat(param1, "%t %t", "Tag", "PlayerCleaningFalied");

		}
		else
			CPrintToChat(param1, "%t %t", "Tag", "PlayerCleaningDisabled");
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
			CPrintToChat(param1, "%t %t", "Tag", "AllCustomeMapsRemoved");
		else
			CPrintToChat(param1, "%t %t", "Tag", "CustomMapsRemovalFailed");
			
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
			CPrintToChat(param1, "%t %t", "Tag", "AllMapTimingsCleared");
		else
			CPrintToChat(param1, "%t %t", "Tag", "MapTimingsRemovalFailed");
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
			CPrintToChat(param1, "%t %t", "Tag", "AllCoopMapTimingsCleared");
		else
			CPrintToChat(param1, "%t %t", "Tag", "CoopMapTimingsRemovalFailed");
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
			CPrintToChat(param1, "%t %t", "Tag", "AllSurvivalMapTimingsCleared");
		else
			CPrintToChat(param1, "%t %t", "Tag", "SurvivalMapTimingsRemovalFailed");
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
			CPrintToChat(param1, "%t %t", "Tag", "AllRealismMapTimingsCleared");
		else
			CPrintToChat(param1, "%t %t", "Tag", "RealismMapTimingsRemovalFailed");
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
			CPrintToChat(param1, "%t %t", "Tag", "AllMutationsMapTimingsCleared");
		else 
			CPrintToChat(param1, "%t %t", "Tag", "MutationsMapTimingsRemovalFailed");
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
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || IsClientBot(i))
					continue;

				char passed[16], didnotpassed[16];
				Format(passed, sizeof(passed), "%T", "PASSED", i);
				Format(didnotpassed, sizeof(didnotpassed), "%T", "DID_NOT_PASS", i);
				CPrintToChat(i, "%t %t", "Tag", "VoteToShuffle", (yesvotes >= WinningVoteCount ? passed : didnotpassed), yesvotes, novotes);
			}

			if (yesvotes >= WinningVoteCount)
				CreateTimer(2.0, Timer_ShuffleTeams);
		}

		if (OldPlayerRankVote != RANKVOTE_NOVOTE)
			return 0;

		CPrintToChatAll("%t %t", "Tag", "PlayerVoted", param1, votes, humans);
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
		if (IsClientInGame(i) && !IsClientBot(i))
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
		if (IsClientBot(i) || !IsClientInGame(i))
			continue;

		GetClientName(i, Name, sizeof(Name));
		IntToString(i, id, sizeof(id));

		ClearPlayerMenu.AddItem(id, Name);
	}

	char title[64];
	Format(title, sizeof(title), "%T", "Menu_ClearplayerstatsTitle", client);
	ClearPlayerMenu.SetTitle(title);

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

		CPrintToChat(client, "%t", "YourPlayerStatsCleared");
		if (client != param1)
			CPrintToChat(param1, "%t", "PlayerStatsCleared", Name);
	}
	else
		CPrintToChat(param1, "%t %t", "Tag", "ClearingPlayerStatsFailed");

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

	char title[64];
	Format(title, sizeof(title), "%T", "Menu_NextrankTitle", client);
	NextRankPanel.SetTitle(title);

	if (g_iClientNextRank[client])
	{
		Format(Value, sizeof(Value), "%T", "Menu_PointsRequired", client, g_iClientNextRank[client]);
		NextRankPanel.DrawText(Value);

		Format(Value, sizeof(Value), "%T", "Menu_CurrentRank", client, g_iClientRank[client]);
		NextRankPanel.DrawText(Value);
	}
	else
	{
		Format(Value, sizeof(Value), "%T", "Menu_YourAreFirst", client);
		NextRankPanel.DrawText(Value);
	}

	char more[64];
	Format(more, sizeof(more), "%T", "Menu_More", client);
	NextRankPanel.DrawItem(more);

	char close[64];
	Format(close, sizeof(close), "%T", "Menu_Close", client);
	NextRankPanel.DrawItem(close);
	NextRankPanel.Send(client, NextRankPanelHandler, 30);
	delete NextRankPanel;
}

void DisplayRankMenu(int client)
{
	char Title[MAX_LINE_WIDTH];

	Format(Title, sizeof(Title), "%T", "Menu_PluginStyledTitle", client);

	Menu menu = new Menu(Menu_CreateRankMenuHandler);

	menu.SetTitle(Title);
	menu.ExitBackButton = false;
	menu.ExitButton = true;

	char Value[64];
	Format(Value, sizeof(Value), "%T", "Menu_ShowMyRank", client);
	menu.AddItem("rank", Value);

	Format(Value, sizeof(Value), "%T", "Menu_ShowTop10", client);
	menu.AddItem("top10", Value);

	Format(Value, sizeof(Value), "%T", "Menu_ShowTop10PPM", client);
	menu.AddItem("top10ppm", Value);

	Format(Value, sizeof(Value), "%T", "Menu_ShowMyNextrank", client);
	menu.AddItem("nextrank", Value);

	Format(Value, sizeof(Value), "%T", "Menu_ShowCurrentTimer", client);
	menu.AddItem("showtimer", Value);

	Format(Value, sizeof(Value), "%T", "Menu_ShowOthersRank", client);
	menu.AddItem("showrank", Value);

	Format(Value, sizeof(Value), "%T", "Menu_ShowOthersPPM", client);
	menu.AddItem("showppm", Value);

	if (g_hCvar_EnableRankVote.BoolValue && IsTeamGamemode())
	{
		Format(Value, sizeof(Value), "%T", "Menu_VoteForShuffle", client);
		menu.AddItem("rankvote", Value);
	}

	Format(Value, sizeof(Value), "%T", "Menu_ShowAllMapTimings", client);
	menu.AddItem("timedmaps", Value);

	if (IsSingleTeamGamemode())
	{
		Format(Value, sizeof(Value), "%T", "Menu_ShowCurrentMapTimes", client);
		menu.AddItem("maptimes", Value);
	}


	if (g_hCvar_AnnounceMode.IntValue)
	{
		Format(Value, sizeof(Value), "%T", "Menu_ModifyRankSettings", client);
		menu.AddItem("showsettings", Value);
	}


	//AddMenuItem(menu, "showmaptimes", "Show others current map timings");

	Format(Title, sizeof(Title), "%T", "Menu_PluginStyledTitle", client);
	menu.AddItem("rankabout", Title);
	menu.Display(client, 30);

	if (g_bEnableSounds_Rankmenu_Show && g_hCvar_SoundsEnabled.BoolValue)
		EmitSoundToClient(client, g_sStatsSound_Rankmenu_Show);
}

void CreateRanksMenu(Database owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client || !hndl)
	{
		LogError("CreateRanksMenu failed! Reason: %s", error);
		return;
	}

	char SteamID[MAX_LINE_WIDTH];
	Menu menu = new Menu(Menu_CreateRanksMenuHandler);

	char Name[32], DisplayName[MAX_LINE_WIDTH];

	char title[64];
	Format(title, sizeof(title), "%T", "Menu_PlayerRanksTitle", client);
	menu.SetTitle(title);

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

		Format(DisplayName, sizeof(DisplayName), "%T", "Menu_PlayerRank", client, Name, hndl.FetchInt(2));
		menu.AddItem(SteamID, DisplayName);
	}

	menu.Display(client, 30);
}

void CreateTimedMapsMenu(Database owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client || !hndl)
	{
		LogError("CreateTimedMapsMenu failed! Reason: %s", error);
		return;
	}

	if (hndl.RowCount <= 0)
	{
		Panel TimedMapsPanel = new Panel();

		char title[64];
		Format(title, sizeof(title), "%T", "Menu_TimedMapsTitle", client);
		TimedMapsPanel.SetTitle(title);

		char Value[MAX_LINE_WIDTH];
		Format(Value, sizeof(Value), "%T", "Menu_NoTimedMaps", client);
		TimedMapsPanel.DrawText(Value);

		Format(Value, sizeof(Value), "%T", "Menu_Close", client);
		TimedMapsPanel.DrawItem("Value");

		TimedMapsPanel.Send(client, TimedMapsPanelHandler, 30);

		delete TimedMapsPanel;
		return;
	}

	int Gamemode;
	Menu menu = new Menu(Menu_CreateTimedMapsMenuHandler);
	char GamemodeTitle[32], GamemodeInfo[2]; //, MutationInfo[MAX_LINE_WIDTH];

	char title[64];
	Format(title, sizeof(title), "%T", "Menu_TimedMapsTitle", client);
	menu.SetTitle(title);

	menu.ExitBackButton = false;
	menu.ExitButton = true;

	while (hndl.FetchRow())
	{
		Gamemode = hndl.FetchInt(0);
		IntToString(Gamemode, GamemodeInfo, sizeof(GamemodeInfo));

		switch (Gamemode)
		{
			case GAMEMODE_COOP: Format(GamemodeTitle, sizeof(GamemodeTitle), "%T", "Menu_Co-op", client);
			case GAMEMODE_SURVIVAL: Format(GamemodeTitle, sizeof(GamemodeTitle), "%T", "Menu_Survival", client);
			case GAMEMODE_REALISM: Format(GamemodeTitle, sizeof(GamemodeTitle), "%T", "Menu_Realism", client);
			case GAMEMODE_OTHERMUTATIONS:
			{
				Format(GamemodeTitle, sizeof(GamemodeTitle), "%T", "Menu_Mutations", client);
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

void CreateTimedMapsMenu2(Database owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client || !hndl)
	{
		LogError("CreateTimedMapsMenu2 failed! Reason: %s", error);
		return;
	}

	if (hndl.RowCount <= 0)
	{
		Panel TimedMapsPanel = new Panel();

		char title[64];
		Format(title, sizeof(title), "%T", "Menu_TimedMapsTitle", client);
		TimedMapsPanel.SetTitle(title);

		char Value[MAX_LINE_WIDTH];
		Format(Value, sizeof(Value), "%T", "Menu_NoTimedMapsForGameMode", client);
		TimedMapsPanel.DrawText(Value);

		char close[64];
		Format(close, sizeof(close), "%T", "Menu_Close", client);
		TimedMapsPanel.DrawItem(close);

		TimedMapsPanel.Send(client, TimedMapsPanelHandler, 30);
		delete TimedMapsPanel;

		return;
	}

	Menu menu = new Menu(Menu_CreateTimedMapsMenu2Hndl);
	int Gamemode;
	char Map[MAX_LINE_WIDTH], Info[MAX_LINE_WIDTH], CurrentMapName[MAX_LINE_WIDTH];
	GetCurrentMap(CurrentMapName, sizeof(CurrentMapName));

	char title[64];
	Format(title, sizeof(title), "%T", "Menu_TimedMapsTitle", client);
	menu.SetTitle(title);

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

void DisplayTimedMapsMenu3_2(Database owner, DBResultSet hndl, const char[] error, DataPack dp)
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

void CreateTimedMapsMenu3(Database owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client || !hndl)
	{
		LogError("CreateTimedMapsMenu3 failed! Reason: %s", error);
		return;
	}

	if (hndl.RowCount <= 0)
	{
		Panel TimedMapsPanel = new Panel();

		char title[64];
		Format(title, sizeof(title), "%T", "Menu_TimedMapsTitle", client);
		TimedMapsPanel.SetTitle(title);

		char Value[MAX_LINE_WIDTH];
		Format(Value, sizeof(Value), "%T", "Menu_NoTimedMapsForRecords", client);
		TimedMapsPanel.DrawText(Value);

		char close[64];
		Format(close, sizeof(close), "%T", "Menu_Close", client);
		TimedMapsPanel.DrawItem(close);

		TimedMapsPanel.Send(client, TimedMapsPanelHandler, 30);
		delete TimedMapsPanel;

		return;
	}

	Menu menu = new Menu(Menu_CreateTimedMapsMenu3Hndl);
	float MapTime;
	char Map[MAX_LINE_WIDTH], Info[MAX_LINE_WIDTH], Value[MAX_LINE_WIDTH];

	char title[64];
	Format(title, sizeof(title), "%T", "Menu_TimedMapsTitle", client);
	menu.SetTitle(title);

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

void CreateTimedMapsMenu4(Database owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client || !hndl)
	{
		LogError("CreateTimedMapsMenu4 failed! Reason: %s", error);
		return;
	}

	Menu menu = new Menu(Menu_CreateTimedMapsMenu4Hndl);

	char Name[32], SteamID[MAX_LINE_WIDTH];

	char title[64];
	Format(title, sizeof(title), "%T", "Menu_TimedMapsTitle", client);
	menu.SetTitle(title);

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

void CreatePPMMenu(Database owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client || !hndl)
	{
		LogError("CreatePPMMenu failed! Reason: %s", error);
		return;
	}

	char SteamID[MAX_LINE_WIDTH];
	Menu menu = new Menu(Menu_CreateRanksMenuHandler);

	char Name[32], DisplayName[MAX_LINE_WIDTH];

	char title[64];
	Format(title, sizeof(title), "%T", "Menu_PlayerPPMTitle", client);
	menu.SetTitle(title);

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

		Format(DisplayName, sizeof(DisplayName), "%T", "Menu_PlayerPPM", client, Name, hndl.FetchFloat(2));
		menu.AddItem(SteamID, DisplayName);
	}

	menu.Display(client, 30);
}

// Send the TOP10 panel to the client's display.
void DisplayTop10(Database owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client || !hndl)
	{
		LogError("DisplayTop10 failed! Reason: %s", error);
		return;
	}

	char Name[32];
	Panel Top10Panel = new Panel();

	char title[64];
	Format(title, sizeof(title), "%T", "Menu_Top10Title", client);
	Top10Panel.SetTitle(title);

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
void DisplayTop10PPM(Database owner, DBResultSet hndl, const char[] error, int client)
{
	if (!client || !hndl)
	{
		LogError("DisplayTop10PPM failed! Reason: %s", error);
		return;
	}

	char Name[32], Disp[MAX_LINE_WIDTH];

	Panel TopPPMPanel = new Panel();

	char title[64];
	Format(title, sizeof(title), "%T", "Menu_Top10PPMTitle", client);
	TopPPMPanel.SetTitle(title);

	while (hndl.FetchRow())
	{
		hndl.FetchString(0, Name, sizeof(Name));

		ReplaceString(Name, sizeof(Name), "&lt;", "<");
		ReplaceString(Name, sizeof(Name), "&gt;", ">");
		ReplaceString(Name, sizeof(Name), "&#37;", "%");
		ReplaceString(Name, sizeof(Name), "&#61;", "=");
		ReplaceString(Name, sizeof(Name), "&#42;", "*");

		Format(Disp, sizeof(Disp), "%T", "Menu_PlayerPPM", client, Name, hndl.FetchFloat(2));

		TopPPMPanel.DrawItem(Disp);
	}

	TopPPMPanel.Send(client, Top10PPMPanelHandler, 30);
	delete TopPPMPanel;
}

// Send the NEXTRANK panel to the client's display.
void DisplayNextRankFull(Database owner, DBResultSet hndl, const char[] error, int client)
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

	char title[64];
	Format(title, sizeof(title), "%T", "Menu_NextRankTitle", client);
	NextRankPanel.SetTitle(title);

	if (g_iClientNextRank[client])
	{
		Format(Value, sizeof(Value), "%T", "Menu_PointsRequired", client, g_iClientNextRank[client]);
		NextRankPanel.DrawText(Value);

		Format(Value, sizeof(Value), "%T", "Menu_CurrentRank", client, g_iClientRank[client]);
		NextRankPanel.DrawText(Value);
	}
	else
	{
		Format(Value, sizeof(Value), "%T", "Menu_YourAreFirst", client);
		NextRankPanel.DrawText(Value);
	}

	while (hndl.FetchRow())
	{
		hndl.FetchString(0, Name, sizeof(Name));
		Points = hndl.FetchInt(1);

		Format(Value, sizeof(Value), "%T", "Menu_PlayerPoints", Points, Name);
		NextRankPanel.DrawText(Value);
	}

	char close[64];
	Format(close, sizeof(close), "%T", "Menu_Close", client);
	NextRankPanel.DrawItem(close);

	NextRankPanel.Send(client, NextRankFullPanelHandler, 30);
	delete NextRankPanel;
}

// Send the RANK panel to the client's display.
void DisplayRank(Database owner, DBResultSet hndl, const char[] error, int client)
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
	float HeadshotRatio = Headshots == 0 ? 0.00 : (float(Headshots) / float(InfectedKilled))*100;

	Format(Value, sizeof(Value), "%T", "Menu_TitleRankOf", client, Name);
	RankPanel.SetTitle(Value);

	Format(Value, sizeof(Value), "%T", "Menu_Rank" , client, g_iClientRank[client], g_iRankTotal);
	RankPanel.DrawText(Value);

	if (!InvalidGameMode())
	{
		switch (g_iCurrentGamemodeID)
		{
			case GAMEMODE_COOP: Format(g_sCurrentGamemodeLabel, sizeof(g_sCurrentGamemodeLabel), "%T", "Label_Coop", client);
			case GAMEMODE_VERSUS: Format(g_sCurrentGamemodeLabel, sizeof(g_sCurrentGamemodeLabel), "%T", "Label_Versus", client);
			case GAMEMODE_REALISM: Format(g_sCurrentGamemodeLabel, sizeof(g_sCurrentGamemodeLabel), "%T", "Label_Realism", client);
			case GAMEMODE_SURVIVAL: Format(g_sCurrentGamemodeLabel, sizeof(g_sCurrentGamemodeLabel), "%T", "Label_Survival", client);
			case GAMEMODE_SCAVENGE: Format(g_sCurrentGamemodeLabel, sizeof(g_sCurrentGamemodeLabel), "%T", "Label_Scavenge", client);
			case GAMEMODE_REALISMVERSUS: Format(g_sCurrentGamemodeLabel, sizeof(g_sCurrentGamemodeLabel), "%T", "Label_Realism_Versus", client);
			case GAMEMODE_OTHERMUTATIONS:
			{
				Format(g_sCurrentGamemodeLabel, sizeof(g_sCurrentGamemodeLabel), "%T", "Label_Mutations", client);
				g_hCvar_Gamemode.GetString(g_sCurrentMutation, sizeof(g_sCurrentMutation));
			}

			default:
			{
				Format(g_sCurrentGamemodeLabel, sizeof(g_sCurrentGamemodeLabel), "%T", "Label_Unknown", client);
				g_sCurrentMutation[0] = 0
			}
		}

		Format(Value, sizeof(Value), "%T", "Menu_GameModeRank", client, g_sCurrentGamemodeLabel , g_iClientGameModeRank[client], g_iGameModeRankTotal);
		RankPanel.DrawText(Value);
	}

	if (Playtime > 60)
	{
		Format(Value, sizeof(Value), "%T", "Menu_Playtime", client, float(Playtime)/60.0);
		RankPanel.DrawText(Value);
	}
	else
	{
		Format(Value, sizeof(Value), "%T", "Menu_PlaytimeMinute", client,Playtime);
		RankPanel.DrawText(Value);
	}

	Format(Value, sizeof(Value), "%T", "Menu_Points", client, Points);
	RankPanel.DrawText(Value);

	Format(Value, sizeof(Value), "%T", "Menu_PPM", client, PPM);
	RankPanel.DrawText(Value);

	Format(Value, sizeof(Value), "%T", "Menu_InfectedKilled", client, InfectedKilled);
	RankPanel.DrawText(Value);

	Format(Value, sizeof(Value), "%T", "Menu_SurvivorsKilled", client, SurvivorsKilled);
	RankPanel.DrawText(Value);

	Format(Value, sizeof(Value), "%T", "Menu_HeadShots", client, Headshots);
	RankPanel.DrawText(Value);

	Format(Value, sizeof(Value), "%T", "Menu_HeadShotRatio", client, HeadshotRatio);
	RankPanel.DrawText(Value);

	if (!StrEqual(URL, "", false))
	{
		Format(Value, sizeof(Value), "%T", "Menu_FullStats", client, URL);
		RankPanel.DrawText(Value);
	}

	//DrawPanelItem(RankPanel, "Next Rank");
	char close[64];
	Format(close, sizeof(close), "%T", "Menu_Close", client);
	RankPanel.DrawItem(close);

	RankPanel.Send(client, RankPanelHandler, 30);
	delete RankPanel;
}
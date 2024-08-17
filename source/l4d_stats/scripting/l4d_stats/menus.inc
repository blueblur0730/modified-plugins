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

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
		g_hTM_RankAdminMenu = null;
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

int Menu_CreateClearTMMenuHandler(Handle menu, MenuAction action, int param1, int param2)
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
void ClearRankTopItemHandler(Handle topmenu, TopMenuAction action, TopMenuObject object_id, client, char[] buffer, maxlength)
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

void CreateRanksMenu(Handle owner, Handle hndl, const char[] error, any client)
{
	if (!client || hndl == INVALID_HANDLE)
	{
		LogError("CreateRanksMenu failed! Reason: %s", error);
		return;
	}

	char SteamID[MAX_LINE_WIDTH];
	Handle menu = CreateMenu(Menu_CreateRanksMenuHandler);

	char Name[32], DisplayName[MAX_LINE_WIDTH];

	SetMenuTitle(menu, "Player Ranks:");
	SetMenuExitBackButton(menu, false);
	SetMenuExitButton(menu, true);

	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, SteamID, sizeof(SteamID));
		SQL_FetchString(hndl, 1, Name, sizeof(Name));

		ReplaceString(Name, sizeof(Name), "&lt;", "<");
		ReplaceString(Name, sizeof(Name), "&gt;", ">");
		ReplaceString(Name, sizeof(Name), "&#37;", "%");
		ReplaceString(Name, sizeof(Name), "&#61;", "=");
		ReplaceString(Name, sizeof(Name), "&#42;", "*");

		Format(DisplayName, sizeof(DisplayName), "%s (%i points)", Name, SQL_FetchInt(hndl, 2));

		AddMenuItem(menu, SteamID, DisplayName);
	}

	DisplayMenu(menu, client, 30);
}

public CreateTimedMapsMenu(Handle owner, Handle hndl, const char[] error, any client)
{
	if (!client || hndl == INVALID_HANDLE)
	{
		LogError("CreateTimedMapsMenu failed! Reason: %s", error);
		return;
	}

	if (SQL_GetRowCount(hndl) <= 0)
	{
		Handle TimedMapsPanel = CreatePanel();
		SetPanelTitle(TimedMapsPanel, "Timed Maps:");

		DrawPanelText(TimedMapsPanel, "There are no recorded map timings!");
		DrawPanelItem(TimedMapsPanel, "Close");

		SendPanelToClient(TimedMapsPanel, client, TimedMapsPanelHandler, 30);
		CloseHandle(TimedMapsPanel);

		return;
	}

	int Gamemode;
	Handle menu = CreateMenu(Menu_CreateTimedMapsMenuHandler);
	char GamemodeTitle[32], GamemodeInfo[2]; //, MutationInfo[MAX_LINE_WIDTH];

	SetMenuTitle(menu, "Timed Maps:");
	SetMenuExitBackButton(menu, false);
	SetMenuExitButton(menu, true);

	while (SQL_FetchRow(hndl))
	{
		Gamemode = SQL_FetchInt(hndl, 0);
		IntToString(Gamemode, GamemodeInfo, sizeof(GamemodeInfo));

		switch (Gamemode)
		{
			case GAMEMODE_COOP:
				strcopy(GamemodeTitle, sizeof(GamemodeTitle), "Co-op");
			case GAMEMODE_SURVIVAL:
				strcopy(GamemodeTitle, sizeof(GamemodeTitle), "Survival");
			case GAMEMODE_REALISM:
				strcopy(GamemodeTitle, sizeof(GamemodeTitle), "Realism");
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

		AddMenuItem(menu, GamemodeInfo, GamemodeTitle);
	}

	DisplayMenu(menu, client, 30);

	return;
}

DisplayYesNoPanel(client, const char[] title, MenuHandler:handler, delay=30)
{
	if (!client)
		return;

	Handle panel = CreatePanel();

	SetPanelTitle(panel, title);

	DrawPanelItem(panel, "Yes");
	DrawPanelItem(panel, "No");

	SendPanelToClient(panel, client, handler, delay);
	CloseHandle(panel);
}

public Menu_CreateTimedMapsMenuHandler(Handle menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE)
		return;

	if (action == MenuAction_End)
		CloseHandle(menu);

	if (action != MenuAction_Select || param1 <= 0 || IsClientBot(param1))
		return;

	char Info[2];
	bool found = GetMenuItem(menu, param2, Info, sizeof(Info));

	if (!found)
		return;

	DisplayTimedMapsMenu2FromInfo(param1, Info);
}

bool TimedMapsMenuInfoMarker(char[] Info, MenuNumber)
{
	if (Info[0] == '\0' || MenuNumber < 2)
		return false;

	int Position = -1, TempPosition;

	for (int i = 0; i < MenuNumber; i++)
	{
		TempPosition = FindCharInString(Info[Position + 1], '\\');

		if (TempPosition < 0)
		{
			if (i + 2 == MenuNumber)
				return true;
			else
				return false;
		}

		Position += 1 + TempPosition;

		if (i + 2 >= MenuNumber)
		{
			Info[Position] = '\0';
			return true;
		}
	}

	return false;
}

public DisplayTimedMapsMenu2FromInfo(client, char[] Info)
{
	if (!TimedMapsMenuInfoMarker(Info, 2))
	{
		cmd_TimedMaps(client, 0);
		return;
	}

	strcopy(g_sMapTimingMenuInfo[client], MAX_LINE_WIDTH, Info);

	int Gamemode = StringToInt(Info);

	DisplayTimedMapsMenu2(client, Gamemode);
}

public DisplayTimedMapsMenu2(client, Gamemode)
{
	char query[256];
	Format(query, sizeof(query), "SELECT DISTINCT tm.gamemode, tm.map FROM %stimedmaps AS tm INNER JOIN %splayers AS p ON tm.steamid = p.steamid WHERE tm.gamemode = %i ORDER BY tm.map ASC", g_sDbPrefix, g_sDbPrefix, Gamemode);
	SQL_TQuery(db, CreateTimedMapsMenu2, query, client);
}

public CreateTimedMapsMenu2(Handle owner, Handle hndl, const char[] error, any client)
{
	if (!client || hndl == INVALID_HANDLE)
	{
		LogError("CreateTimedMapsMenu2 failed! Reason: %s", error);
		return;
	}

	if (SQL_GetRowCount(hndl) <= 0)
	{
		Panel TimedMapsPanel = CreatePanel();
		SetPanelTitle(TimedMapsPanel, "Timed Maps:");

		DrawPanelText(TimedMapsPanel, "There are no recorded times for this gamemode!");
		DrawPanelItem(TimedMapsPanel, "Close");

		SendPanelToClient(TimedMapsPanel, client, TimedMapsPanelHandler, 30);
		CloseHandle(TimedMapsPanel);

		return;
	}

	Handle menu = CreateMenu(Menu_CreateTimedMapsMenu2Hndl);
	int Gamemode;
	char Map[MAX_LINE_WIDTH], Info[MAX_LINE_WIDTH], CurrentMapName[MAX_LINE_WIDTH];

	GetCurrentMap(CurrentMapName, sizeof(CurrentMapName));

	SetMenuTitle(menu, "Timed Maps:");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);

	while (SQL_FetchRow(hndl))
	{
		Gamemode = SQL_FetchInt(hndl, 0);
		SQL_FetchString(hndl, 1, Map, sizeof(Map));

		Format(Info, sizeof(Info), "%i\\%s", Gamemode, Map);

		if (g_iCurrentGamemodeID == Gamemode && StrEqual(CurrentMapName, Map))
			StrCat(Map, sizeof(Map), TM_MENU_CURRENT);

		AddMenuItem(menu, Info, Map);
	}

	DisplayMenu(menu, client, 30);
}

public Menu_CreateTimedMapsMenu2Hndl(Handle menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE)
		return;

	if (action == MenuAction_End)
		CloseHandle(menu);

	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
			cmd_TimedMaps(param1, 0);

		return;
	}

	if (action != MenuAction_Select || param1 <= 0 || IsClientBot(param1))
		return;

	char Info[MAX_LINE_WIDTH];
	bool found = GetMenuItem(menu, param2, Info, sizeof(Info));

	if (!found)
		return;

	DisplayTimedMapsMenu3FromInfo(param1, Info);
}

public DisplayTimedMapsMenu3FromInfo(client, char[] Info)
{
	if (!TimedMapsMenuInfoMarker(Info, 3))
	{
		cmd_TimedMaps(client, 0);
		return;
	}

	strcopy(g_sMapTimingMenuInfo[client], MAX_LINE_WIDTH, Info);

	char GamemodeInfo[2], Map[MAX_LINE_WIDTH];

	strcopy(GamemodeInfo, sizeof(GamemodeInfo), Info);
	GamemodeInfo[1] = 0;

	strcopy(Map, sizeof(Map), Info[2]);

	DisplayTimedMapsMenu3(client, StringToInt(GamemodeInfo), Map);
}

public DisplayTimedMapsMenu3(client, Gamemode, const char[] Map)
{
	Handle dp = CreateDataPack();

	WritePackCell(dp, client);
	WritePackCell(dp, Gamemode);
	WritePackString(dp, Map);

	char SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));

	char query[256];
	Format(query, sizeof(query), "SELECT tm.time FROM %stimedmaps AS tm INNER JOIN %splayers AS p ON tm.steamid = p.steamid WHERE tm.gamemode = %i AND tm.map = '%s' AND p.steamid = '%s'", g_sDbPrefix, g_sDbPrefix, Gamemode, Map, SteamID);
	SQL_TQuery(db, DisplayTimedMapsMenu3_2, query, dp);
}

public DisplayTimedMapsMenu3_2(Handle owner, Handle hndl, const char[] error, any dp)
{
	if (hndl == INVALID_HANDLE)
	{
		if (dp != INVALID_HANDLE)
			CloseHandle(dp);

		LogError("DisplayTimedMapsMenu3_2 failed! Reason: %s", error);
		return;
	}

	ResetPack(dp);

	int client = ReadPackCell(dp);
	int Gamemode = ReadPackCell(dp);
	char Map[MAX_LINE_WIDTH];
	ReadPackString(dp, Map, sizeof(Map));

	CloseHandle(dp);

	if (SQL_FetchRow(hndl))
		g_fClientMapTime[client] = SQL_FetchFloat(hndl, 0);
	else
		g_fClientMapTime[client] = 0.0;

	char query[256];
	Format(query, sizeof(query), "SELECT DISTINCT tm.gamemode, tm.map, tm.time FROM %stimedmaps AS tm INNER JOIN %splayers AS p ON tm.steamid = p.steamid WHERE tm.gamemode = %i AND tm.map = '%s' ORDER BY tm.time %s", g_sDbPrefix, g_sDbPrefix, Gamemode, Map, (Gamemode == GAMEMODE_SURVIVAL ? "DESC" : "ASC"));
	SQL_TQuery(db, CreateTimedMapsMenu3, query, client);
}

public CreateTimedMapsMenu3(Handle owner, Handle hndl, const char[] error, any client)
{
	if (!client || hndl == INVALID_HANDLE)
	{
		LogError("CreateTimedMapsMenu3 failed! Reason: %s", error);
		return;
	}

	if (SQL_GetRowCount(hndl) <= 0)
	{
		Handle TimedMapsPanel = CreatePanel();
		SetPanelTitle(TimedMapsPanel, "Timed Maps:");

		DrawPanelText(TimedMapsPanel, "There are no recorded times for this map!");
		DrawPanelItem(TimedMapsPanel, "Close");

		SendPanelToClient(TimedMapsPanel, client, TimedMapsPanelHandler, 30);
		CloseHandle(TimedMapsPanel);

		return;
	}

	Handle menu = CreateMenu(Menu_CreateTimedMapsMenu3Hndl);
	float MapTime;
	char Map[MAX_LINE_WIDTH], Info[MAX_LINE_WIDTH], Value[MAX_LINE_WIDTH];

	SetMenuTitle(menu, "Timed Maps:");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);

	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 1, Map, sizeof(Map));
		MapTime = SQL_FetchFloat(hndl, 2);

		SetTimeLabel(MapTime, Value, sizeof(Value));

		Format(Info, sizeof(Info), "%i\\%s\\%f", SQL_FetchInt(hndl, 0), Map, MapTime);

		if (g_fClientMapTime[client] > 0.0 && g_fClientMapTime[client] == MapTime)
			StrCat(Value, sizeof(Value), TM_MENU_CURRENT);

		AddMenuItem(menu, Info, Value);
	}

	DisplayMenu(menu, client, 30);
}

public Menu_CreateTimedMapsMenu3Hndl(Handle menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE)
		return;

	if (action == MenuAction_End)
		CloseHandle(menu);

	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
			DisplayTimedMapsMenu2FromInfo(param1, g_sMapTimingMenuInfo[param1]);

		return;
	}

	if (action != MenuAction_Select || param1 <= 0 || IsClientBot(param1))
		return;

	char Info[MAX_LINE_WIDTH];
	bool found = GetMenuItem(menu, param2, Info, sizeof(Info));

	if (!found)
		return;

	DisplayTimedMapsMenu4FromInfo(param1, Info);
}

public DisplayTimedMapsMenu4FromInfo(client, char[] Info)
{
	if (!TimedMapsMenuInfoMarker(Info, 4))
	{
		cmd_TimedMaps(client, 0);
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

public DisplayTimedMapsMenu4(client, Gamemode, const char[] Map, float MapTime)
{
	char query[256];
	Format(query, sizeof(query), "SELECT tm.steamid, p.name FROM %stimedmaps AS tm INNER JOIN %splayers AS p ON tm.steamid = p.steamid WHERE tm.gamemode = %i AND tm.map = '%s' AND tm.time = %f ORDER BY p.name ASC", g_sDbPrefix, g_sDbPrefix, Gamemode, Map, MapTime);
	SQL_TQuery(db, CreateTimedMapsMenu4, query, client);
}

public CreateTimedMapsMenu4(Handle owner, Handle hndl, const char[] error, any client)
{
	if (!client || hndl == INVALID_HANDLE)
	{
		LogError("CreateTimedMapsMenu4 failed! Reason: %s", error);
		return;
	}

	Handle menu = CreateMenu(Menu_CreateTimedMapsMenu4Hndl);

	char Name[32], SteamID[MAX_LINE_WIDTH];

	SetMenuTitle(menu, "Timed Maps:");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);

	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, SteamID, sizeof(SteamID));
		SQL_FetchString(hndl, 1, Name, sizeof(Name));

		ReplaceString(Name, sizeof(Name), "&lt;", "<");
		ReplaceString(Name, sizeof(Name), "&gt;", ">");
		ReplaceString(Name, sizeof(Name), "&#37;", "%");
		ReplaceString(Name, sizeof(Name), "&#61;", "=");
		ReplaceString(Name, sizeof(Name), "&#42;", "*");

		AddMenuItem(menu, SteamID, Name);
	}

	DisplayMenu(menu, client, 30);
}

public Menu_CreateTimedMapsMenu4Hndl(Handle menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE)
		return;

	if (action == MenuAction_End)
		CloseHandle(menu);

	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
			DisplayTimedMapsMenu3FromInfo(param1, g_sMapTimingMenuInfo[param1]);

		return;
	}

	if (action != MenuAction_Select || param1 <= 0 || IsClientBot(param1))
		return;

	char SteamID[MAX_LINE_WIDTH];
	bool found = GetMenuItem(menu, param2, SteamID, sizeof(SteamID));

	if (!found)
		return;

	QueryClientStatsSteamID(param1, SteamID, CM_RANK);
}

public CreatePPMMenu(Handle owner, Handle hndl, const char[] error, any client)
{
	if (!client || hndl == INVALID_HANDLE)
	{
		LogError("CreatePPMMenu failed! Reason: %s", error);
		return;
	}

	char SteamID[MAX_LINE_WIDTH];
	Handle menu = CreateMenu(Menu_CreateRanksMenuHandler);

	char Name[32], DisplayName[MAX_LINE_WIDTH];

	SetMenuTitle(menu, "Player PPM:");
	SetMenuExitBackButton(menu, false);
	SetMenuExitButton(menu, true);

	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, SteamID, sizeof(SteamID));
		SQL_FetchString(hndl, 1, Name, sizeof(Name));

		ReplaceString(Name, sizeof(Name), "&lt;", "<");
		ReplaceString(Name, sizeof(Name), "&gt;", ">");
		ReplaceString(Name, sizeof(Name), "&#37;", "%");
		ReplaceString(Name, sizeof(Name), "&#61;", "=");
		ReplaceString(Name, sizeof(Name), "&#42;", "*");

		Format(DisplayName, sizeof(DisplayName), "%s (PPM: %.2f)", Name, SQL_FetchFloat(hndl, 2));

		AddMenuItem(menu, SteamID, DisplayName);
	}

	DisplayMenu(menu, client, 30);
}

public Menu_CreateRanksMenuHandler(Handle menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE)
		return;

	if (action == MenuAction_End)
		CloseHandle(menu);

	if (action != MenuAction_Select || param1 <= 0 || IsClientBot(param1))
		return;

	char SteamID[MAX_LINE_WIDTH];
	bool found = GetMenuItem(menu, param2, SteamID, sizeof(SteamID));

	if (!found)
		return;

	QueryClientStatsSteamID(param1, SteamID, CM_RANK);
}

public Menu_CreateRankMenuHandler(Handle menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE)
		return;

	if (action == MenuAction_End)
		CloseHandle(menu);

	if (action != MenuAction_Select || param1 <= 0 || IsClientBot(param1))
		return;

	char Info[MAX_LINE_WIDTH];
	bool found = GetMenuItem(menu, param2, Info, sizeof(Info));

	if (!found)
		return;

	if (strcmp(Info, "rankabout", false) == 0)
	{
		DisplayAboutPanel(param1);
		return;
	}

	else if (strcmp(Info, "showsettings", false) == 0)
	{
		DisplaySettingsPanel(param1);
		return;
	}

	HandleCommands(param1, Info);
}

// Send the RANKABOUT panel to the client's display.
public DisplayAboutPanel(client)
{
	char Value[MAX_LINE_WIDTH];

	Handle panel = CreatePanel();

	Format(Value, sizeof(Value), "About [L4D] Statistic:");
	SetPanelTitle(panel, Value);

	Format(Value, sizeof(Value), "Version: %s", PLUGIN_VERSION);
	DrawPanelText(panel, Value);

	Format(Value, sizeof(Value), "Author: %s", "Mikko Andersson (muukis)");
	DrawPanelText(panel, Value);

	Format(Value, sizeof(Value), "Description: %s", "Record player statistics.");
	DrawPanelText(panel, Value);

	DrawPanelItem(panel, "Back");
	DrawPanelItem(panel, "Close");

	SendPanelToClient(panel, client, AboutPanelHandler, 30);
	CloseHandle(panel);
}

// Send the RANKABOUT panel to the client's display.
public DisplaySettingsPanel(client)
{
	char Value[MAX_LINE_WIDTH];

	Handle panel = CreatePanel();

	Format(Value, sizeof(Value), "Plugin Settings:");
	SetPanelTitle(panel, Value);

	DrawPanelItem(panel, (g_bClientRankMute[client] ? "Unmute (Currently: Muted)" : "Mute (Currently: Not muted)"));

	DrawPanelItem(panel, "Back");
	DrawPanelItem(panel, "Close");

	SendPanelToClient(panel, client, SettingsPanelHandler, 30);
	CloseHandle(panel);
}

// Send the TOP10 panel to the client's display.
public DisplayTop10(Handle owner, Handle hndl, const char[] error, any client)
{
	if (!client || hndl == INVALID_HANDLE)
	{
		LogError("DisplayTop10 failed! Reason: %s", error);
		return;
	}

	char Name[32];

	Handle Top10Panel = CreatePanel();
	SetPanelTitle(Top10Panel, "Top 10 Players");

	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, Name, sizeof(Name));

		ReplaceString(Name, sizeof(Name), "&lt;", "<");
		ReplaceString(Name, sizeof(Name), "&gt;", ">");
		ReplaceString(Name, sizeof(Name), "&#37;", "%");
		ReplaceString(Name, sizeof(Name), "&#61;", "=");
		ReplaceString(Name, sizeof(Name), "&#42;", "*");

		DrawPanelItem(Top10Panel, Name);
	}

	SendPanelToClient(Top10Panel, client, Top10PanelHandler, 30);
	CloseHandle(Top10Panel);
}

// Send the TOP10PPM panel to the client's display.
public DisplayTop10PPM(Handle owner, Handle hndl, const char[] error, any client)
{
	if (!client || hndl == INVALID_HANDLE)
	{
		LogError("DisplayTop10PPM failed! Reason: %s", error);
		return;
	}

	char Name[32], Disp[MAX_LINE_WIDTH];

	Handle TopPPMPanel = CreatePanel();
	SetPanelTitle(TopPPMPanel, "Top 10 PPM Players");

	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, Name, sizeof(Name));

		ReplaceString(Name, sizeof(Name), "&lt;", "<");
		ReplaceString(Name, sizeof(Name), "&gt;", ">");
		ReplaceString(Name, sizeof(Name), "&#37;", "%");
		ReplaceString(Name, sizeof(Name), "&#61;", "=");
		ReplaceString(Name, sizeof(Name), "&#42;", "*");

		Format(Disp, sizeof(Disp), "%s (PPM: %.2f)", Name, SQL_FetchFloat(hndl, 1));

		DrawPanelItem(TopPPMPanel, Disp);
	}

	SendPanelToClient(TopPPMPanel, client, Top10PPMPanelHandler, 30);
	CloseHandle(TopPPMPanel);
}

// Handler for RANK panel.
public RankPanelHandler(Handle menu, MenuAction:action, param1, param2)
{
}

// Handler for NEXTRANK panel.
public NextRankPanelHandler(Handle menu, MenuAction:action, param1, param2)
{
	if (param2 == 1)
		QueryClientStats(param1, CM_NEXTRANKFULL);
}

// Handler for NEXTRANK panel.
public NextRankFullPanelHandler(Handle menu, MenuAction:action, param1, param2)
{
}

// Handler for TIMEDMAPS panel.
public TimedMapsPanelHandler(Handle menu, MenuAction:action, param1, param2)
{
}

// Handler for RANKADMIN panel.
//public RankAdminPanelHandler(Handle menu, MenuAction:action, param1, param2)
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
public ClearPlayersPanelHandler(Handle menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select)
		return;

	if (param2 == 1)
	{
		ClearStatsPlayers(param1);
		StatsPrintToChatPreFormatted(param1, "All player stats cleared!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
}

// Handler for RANKADMIN panel.
public ClearMapsPanelHandler(Handle menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select)
		return;

	if (param2 == 1)
	{
		ClearStatsMaps(param1);
		StatsPrintToChatPreFormatted(param1, "All map stats cleared!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
}

// Handler for RANKADMIN panel.
public ClearAllPanelHandler(Handle menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select)
		return;

	if (param2 == 1)
	{
		ClearStatsAll(param1);
		StatsPrintToChatPreFormatted(param1, "All stats cleared!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
}

// Handler for RANKADMIN panel.
public CleanPlayersPanelHandler(Handle menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select)
		return;

	if (param2 == 1)
	{
		new LastOnTimeMonths = GetConVarInt(g_hCvar_AdminPlayerCleanLastOnTime);
		new PlaytimeMinutes = GetConVarInt(g_hCvar_AdminPlayerCleanPlatime);

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
}

// Handler for RANKADMIN panel.
public RemoveCustomMapsPanelHandler(Handle menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select)
		return;

	if (param2 == 1)
	{
		if (DoFastQuery(param1, "DELETE FROM %smaps WHERE custom = 1", g_sDbPrefix))
			StatsPrintToChatPreFormatted(param1, "All custom maps removed!");
		else
			StatsPrintToChatPreFormatted(param1, "Removing custom maps failed!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
}

// Handler for RANKADMIN panel.
public ClearTMAllPanelHandler(Handle menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select)
		return;

	if (param2 == 1)
	{
		if (DoFastQuery(param1, "DELETE FROM %stimedmaps", g_sDbPrefix))
			StatsPrintToChatPreFormatted(param1, "All map timings removed!");
		else
			StatsPrintToChatPreFormatted(param1, "Removing map timings failed!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
}

// Handler for RANKADMIN panel.
public ClearTMCoopPanelHandler(Handle menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select)
		return;

	if (param2 == 1)
	{
		if (DoFastQuery(param1, "DELETE FROM %stimedmaps WHERE gamemode = %i", g_sDbPrefix, GAMEMODE_COOP))
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Coop successful!");
		else
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Coop failed!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
}

// Handler for RANKADMIN panel.
public ClearTMSurvivalPanelHandler(Handle menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select)
		return;

	if (param2 == 1)
	{
		if (DoFastQuery(param1, "DELETE FROM %stimedmaps WHERE gamemode = %i", g_sDbPrefix, GAMEMODE_SURVIVAL))
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Survival successful!");
		else
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Survival failed!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
}

// Handler for RANKADMIN panel.
public ClearTMRealismPanelHandler(Handle menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select)
		return;

	if (param2 == 1)
	{
		if (DoFastQuery(param1, "DELETE FROM %stimedmaps WHERE gamemode = %i", g_sDbPrefix, GAMEMODE_REALISM))
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Realism successful!");
		else
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Realism failed!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
}

// Handler for RANKADMIN panel.
public ClearTMMutationsPanelHandler(Handle menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select)
		return;

	if (param2 == 1)
	{
		if (DoFastQuery(param1, "DELETE FROM %stimedmaps WHERE gamemode = %i", g_sDbPrefix, GAMEMODE_OTHERMUTATIONS))
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Mutations successful!");
		else
			StatsPrintToChatPreFormatted(param1, "Clearing map timings for Mutations failed!");
	}
	//else if (param2 == 2)
	//	cmd_RankAdmin(param1, 0);
}

// Handler for RANKVOTE panel.
public RankVotePanelHandler(Handle menu, MenuAction:action, param1, param2)
{
	if (action != MenuAction_Select || g_hRankVoteTimer == INVALID_HANDLE || param1 <= 0 || IsClientBot(param1))
		return;

	if (param2 == 1 || param2 == 2)
	{
		new team = GetClientTeam(param1);

		if (team != TEAM_SURVIVORS && team != TEAM_INFECTED)
			return;

		new Oldg_iPlayerRankVote = g_iPlayerRankVote[param1];

		if (param2 == 1)
			g_iPlayerRankVote[param1] = RANKVOTE_YES;
		else if (param2 == 2)
			g_iPlayerRankVote[param1] = RANKVOTE_NO;

		new humans = 0, votes = 0, yesvotes = 0, novotes = 0, WinningVoteCount = 0;

		CheckRankVotes(humans, votes, yesvotes, novotes, WinningVoteCount);

		if (yesvotes >= WinningVoteCount || novotes >= WinningVoteCount)
		{
			if (g_hRankVoteTimer != INVALID_HANDLE)
			{
				CloseHandle(g_hRankVoteTimer);
				g_hRankVoteTimer = INVALID_HANDLE;
			}

			StatsPrintToChatAll("Vote to shuffle teams by player PPM \x03%s \x01with \x04%i (yes) against %i (no)\x01.", (yesvotes >= WinningVoteCount ? "PASSED" : "DID NOT PASS"), yesvotes, novotes);

			if (yesvotes >= WinningVoteCount)
				CreateTimer(2.0, Timer_ShuffleTeams);
		}

		if (Oldg_iPlayerRankVote != RANKVOTE_NOVOTE)
			return;

		char Name[32];
		GetClientName(param1, Name, sizeof(Name));

		StatsPrintToChatAll("\x05%s \x01voted. \x04%i/%i \x01players have voted.", Name, votes, humans);
	}
}

CheckRankVotes(&Humans, &Votes, &YesVotes, &NoVotes, &WinningVoteCount)
{
	Humans = 0;
	Votes = 0;
	YesVotes = 0;
	NoVotes = 0;
	WinningVoteCount = 0;

	int i, team, maxplayers = MaxClients;

	for (i = 1; i <= maxplayers; i++)
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

DisplayClearPanel(client, delay=30)
{
	if (!client)
		return;

	//if (ClearPlayerMenu != INVALID_HANDLE)
	//{
	//	CloseHandle(ClearPlayerMenu);
	//	ClearPlayerMenu = INVALID_HANDLE;
	//}

	Handle ClearPlayerMenu = CreateMenu(DisplayClearPanelHandler);
	int maxplayers = MaxClients;
	char id[3], Name[32];

	for (int i = 1; i <= maxplayers; i++)
	{
		if (IsClientBot(i) || !IsClientConnected(i) || !IsClientInGame(i))
			continue;

		GetClientName(i, Name, sizeof(Name));
		IntToString(i, id, sizeof(id));

		AddMenuItem(ClearPlayerMenu, id, Name);
	}

	SetMenuTitle(ClearPlayerMenu, "Clear player stats:");
	DisplayMenu(ClearPlayerMenu, client, delay);
}

// Handler for RANKADMIN panel.
public DisplayClearPanelHandler(Handle menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE)
		return;

	if (action == MenuAction_End)
		CloseHandle(menu);

	if (action != MenuAction_Select || param1 <= 0 || IsClientBot(param1))
		return;

	char id[3];
	bool found = GetMenuItem(menu, param2, id, sizeof(id));

	if (!found)
		return;

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
}

// Handler for RANKABOUT panel.
public AboutPanelHandler(Handle menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1)
			cmd_ShowRankMenu(param1, 0);
	}
}

// Handler for RANK SETTINGS panel.
public SettingsPanelHandler(Handle menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1)
			cmd_ToggleClientRankMute(param1, 0);
		if (param2 == 2)
			cmd_ShowRankMenu(param1, 0);
	}
}

// Handler for TOP10 panel.
public Top10PanelHandler(Handle menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 0)
			param2 = 10;

		GetClientFromTop10(param1, param2 - 1);
	}
}

// Handler for TOP10PPM panel.
public Top10PPMPanelHandler(Handle menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 0)
			param2 = 10;

		GetClientFromTop10PPM(param1, param2 - 1);
	}
}

// Send the NEXTRANK panel to the client's display.
public DisplayNextRank(client)
{
	if (!client)
		return;

	Handle NextRankPanel = CreatePanel();
	char Value[MAX_LINE_WIDTH];

	SetPanelTitle(NextRankPanel, "Next Rank:");

	if (g_iClientNextRank[client])
	{
		Format(Value, sizeof(Value), "Points required: %i", g_iClientNextRank[client]);
		DrawPanelText(NextRankPanel, Value);

		Format(Value, sizeof(Value), "Current rank: %i", g_iClientRank[client]);
		DrawPanelText(NextRankPanel, Value);
	}
	else
		DrawPanelText(NextRankPanel, "You are 1st");

	DrawPanelItem(NextRankPanel, "More...");
	DrawPanelItem(NextRankPanel, "Close");
	SendPanelToClient(NextRankPanel, client, NextRankPanelHandler, 30);
	CloseHandle(NextRankPanel);
}

// Send the NEXTRANK panel to the client's display.
public DisplayNextRankFull(Handle owner, Handle hndl, const char[] error, any client)
{
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("DisplayNextRankFull Query failed: %s", error);
		return;
	}

	if(SQL_GetRowCount(hndl) <= 1)
		return;

	int Points;
	char Name[32];

	Handle NextRankPanel = CreatePanel();
	char Value[MAX_LINE_WIDTH];

	SetPanelTitle(NextRankPanel, "Next Rank:");

	if (g_iClientNextRank[client])
	{
		Format(Value, sizeof(Value), "Points required: %i", g_iClientNextRank[client]);
		DrawPanelText(NextRankPanel, Value);

		Format(Value, sizeof(Value), "Current rank: %i", g_iClientRank[client]);
		DrawPanelText(NextRankPanel, Value);
	}
	else
		DrawPanelText(NextRankPanel, "You are 1st");

	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, Name, sizeof(Name));
		Points = SQL_FetchInt(hndl, 1);

		Format(Value, sizeof(Value), "%i points: %s", Points, Name);
		DrawPanelText(NextRankPanel, Value);
	}

	DrawPanelItem(NextRankPanel, "Close");
	SendPanelToClient(NextRankPanel, client, NextRankFullPanelHandler, 30);
	CloseHandle(NextRankPanel);
}

// Send the RANK panel to the client's display.
public DisplayRank(Handle owner, Handle hndl, const char[] error, any client)
{
	if (!client)
		return;

	if (hndl == INVALID_HANDLE)
	{
		LogError("DisplayRank Query failed: %s", error);
		return;
	}

	float PPM;
	int Playtime, Points, InfectedKilled, SurvivorsKilled, Headshots;
	char Name[32];

	if (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, Name, sizeof(Name));
		Playtime = SQL_FetchInt(hndl, 1);
		Points = SQL_FetchInt(hndl, 2);
		InfectedKilled = SQL_FetchInt(hndl, 3);
		SurvivorsKilled = SQL_FetchInt(hndl, 4);
		Headshots = SQL_FetchInt(hndl, 5);
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

	Handle RankPanel = CreatePanel();
	char Value[MAX_LINE_WIDTH];
	char URL[MAX_LINE_WIDTH];

	GetConVarString(g_hCvar_SiteURL, URL, sizeof(URL));
	float HeadshotRatio = Headshots == 0 ? 0.00 : (float(Headshots)/float(InfectedKilled))*100;

	Format(Value, sizeof(Value), "Ranking of %s" , Name);
	SetPanelTitle(RankPanel, Value);

	Format(Value, sizeof(Value), "Rank: %i of %i" , g_iClientRank[client], g_iRankTotal);
	DrawPanelText(RankPanel, Value);

	if (!InvalidGameMode())
	{
		Format(Value, sizeof(Value), "%s Rank: %i of %i" ,g_sCurrentGamemodeLabel , g_iClientGameModeRank[client], g_iGameModeRankTotal);
		DrawPanelText(RankPanel, Value);
	}

	if (Playtime > 60)
	{
		Format(Value, sizeof(Value), "Playtime: %.2f hours" , float(Playtime)/60.0);
		DrawPanelText(RankPanel, Value);
	}
	else
	{
		Format(Value, sizeof(Value), "Playtime: %i min" , Playtime);
		DrawPanelText(RankPanel, Value);
	}

	Format(Value, sizeof(Value), "Points: %i" , Points);
	DrawPanelText(RankPanel, Value);

	Format(Value, sizeof(Value), "PPM: %.2f" , PPM);
	DrawPanelText(RankPanel, Value);

	Format(Value, sizeof(Value), "Infected Killed: %i" , InfectedKilled);
	DrawPanelText(RankPanel, Value);

	Format(Value, sizeof(Value), "Survivors Killed: %i" , SurvivorsKilled);
	DrawPanelText(RankPanel, Value);

	Format(Value, sizeof(Value), "Headshots: %i" , Headshots);
	DrawPanelText(RankPanel, Value);

	Format(Value, sizeof(Value), "Headshot Ratio: %.2f %" , HeadshotRatio);
	DrawPanelText(RankPanel, Value);

	if (!StrEqual(URL, "", false))
	{
		Format(Value, sizeof(Value), "For full stats visit %s", URL);
		DrawPanelText(RankPanel, Value);
	}

	//DrawPanelItem(RankPanel, "Next Rank");
	DrawPanelItem(RankPanel, "Close");
	SendPanelToClient(RankPanel, client, RankPanelHandler, 30);
	CloseHandle(RankPanel);
}

public DisplayRankMenu(client)
{
	char Title[MAX_LINE_WIDTH];

	Format(Title, sizeof(Title), "[L4D] Statistic:");

	Handle menu = CreateMenu(Menu_CreateRankMenuHandler);

	SetMenuTitle(menu, Title);
	SetMenuExitBackButton(menu, false);
	SetMenuExitButton(menu, true);

	AddMenuItem(menu, "rank", "Show my rank");
	AddMenuItem(menu, "top10", "Show top 10");
	AddMenuItem(menu, "top10ppm", "Show top 10 PPM");
	AddMenuItem(menu, "nextrank", "Show my next rank");
	AddMenuItem(menu, "showtimer", "Show current timer");
	AddMenuItem(menu, "showrank", "Show others rank");
	AddMenuItem(menu, "showppm", "Show others PPM");
	if (GetConVarBool(g_hCvar_EnableRankVote) && IsTeamGamemode())
	{
		AddMenuItem(menu, "rankvote", "Vote for team shuffle by PPM");
	}
	AddMenuItem(menu, "timedmaps", "Show all map timings");
	if (IsSingleTeamGamemode())
	{
		AddMenuItem(menu, "maptimes", "Show current map timings");
	}
	if (GetConVarInt(g_hCvar_AnnounceMode))
	{
		AddMenuItem(menu, "showsettings", "Modify rank settings");
	}
	//AddMenuItem(menu, "showmaptimes", "Show others current map timings");

	Format(Title, sizeof(Title), "About [L4D] Statistic");
	AddMenuItem(menu, "rankabout", Title);

	DisplayMenu(menu, client, 30);

	if (g_bEnableSounds_Rankmenu_Show && GetConVarBool(g_hCvar_SoundsEnabled))
		EmitSoundToClient(client, g_sStatsSound_Rankmenu_Show);
}
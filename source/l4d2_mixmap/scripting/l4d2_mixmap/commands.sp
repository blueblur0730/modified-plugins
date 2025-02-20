#if defined _l4d2_mixmap_commands_included
 #endinput
#endif
#define _l4d2_mixmap_commands_included

Action Command_Mixmap(int client, int args) 
{
	if (!g_hCvar_Enable.BoolValue)
	{
		CReplyToCommand(client, "%t", "PluginDisabled");
		return Plugin_Handled;
	}

	if (g_bMapsetInitialized) 
	{
		CReplyToCommand(client, "%t", "HasStarted");
		return Plugin_Handled;
	}

	CreateMixmapMenu(client);
	return Plugin_Handled;
}

void CreateMixmapMenu(int client)
{
	char sBuffer[128];
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "MenuTitle_SelectMapSetType", client);
	Menu menu = new Menu(MenuHandler_Mixmap);
	menu.SetTitle(sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%T", "MenuItem_OfficialMapSet", client)
	menu.AddItem("1", sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%T", "MenuItem_CustomMapSet", client)
	menu.AddItem("2", sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%T", "MenuItem_MixtapeMapSet", client)
	menu.AddItem("3", sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%T", "MenuItem_ManuallySelectMap", client);
	menu.AddItem("4", sBuffer);

	menu.Display(client, MENU_TIME_FOREVER);
}

// Abort a currently loaded mapset
Action Command_StopMixmap(int client, int args) 
{
	if (!g_bMapsetInitialized) 
	{
		CReplyToCommand(client, "%t", "NotStartedYet");
		return Plugin_Handled;
	}
	
    CreateStopMixmapVote(client);
	return Plugin_Continue;
}

// Loads a specified set of maps
Action Command_ForceMixmap(int client, int args) 
{
	if (g_bMapsetInitialized) 
	{
		CReplyToCommand(client, "%t", "HasStarted");
		return Plugin_Handled;
	}

	if (GetCmdArgs() > 1)
	{
		CReplyToCommand(client, "Usage: sm_forcemixmap <1-3>");
		return Plugin_Handled;
	}

	if (GetCmdArgs() == 1)
	{
		char sArg[8];
		GetCmdArg(1, sArg, sizeof(sArg));

		int iMapSet = StringToInt(sArg);
		if (iMapSet != 1 || iMapSet != 2 || iMapSet != 3)
		{
			CReplyToCommand(client, "Usage: sm_forcemixmap <1-3>");
			return Plugin_Handled;
		}

		InitiateMixmap(view_as<MapSetType>(iMapSet));
	}

	InitiateMixmap(MapSet_Official);
	return Plugin_Handled;
}

Action Command_ForceStopMixmap(int client, int args) 
{
	if (!g_bMapsetInitialized) 
	{
		CReplyToCommand(client, "%t", "NotStartedYet");
		return Plugin_Handled;
	}

	PluginStartInit();
	CPrintToChatAllEx(client, "%t", "AdminForceStop", client);
	return Plugin_Handled;
}

// Display current map list
Action Command_Maplist(int client, int args) 
{
	if (!g_bMapsetInitialized) 
	{
		CReplyToCommand(client, "%t", "NotStartedYet");
		return Plugin_Handled;
	}

	if (!g_hArrayPools || !g_hArrayPools.Length)
		return Plugin_Handled;

	NotifyMapList(client);
	return Plugin_Handled;
}

void MenuHandler_Mixmap(Menu menu, MenuAction action, int client, int selection)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (selection)
			{
				case 0: CreateMixmapVote(client, MapSet_Official);
				case 1: CreateMixmapVote(client, MapSet_Custom);
				case 2: CreateMixmapVote(client, MapSet_Mixtape);
				case 3: ManullySelectMap_ChooseMapSetType(client);
			}
		}

		case MenuAction_End:
			delete menu;
	}
}

void ManullySelectMap_ChooseMapSetType(int client)
{
	char sBuffer[128];
	Menu menu = new Menu(MenuHandler_ChooseMapSetType);

	FormatEx(sBuffer, sizeof(sBuffer), "%T", "MenuTitle_ChooseMapSetType", client);
	menu.SetTitle(sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%T", "MenuItem_OfficialMapSet", client);
	menu.AddItem("", sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%T", "MenuItem_CustomMapSet", client);
	menu.AddItem("", sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%T", "MenuItem_MixtapeMapSet", client);
	menu.AddItem("", sBuffer);

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

void MenuHandler_ChooseMapSetType(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 0: CollectAllMapsEx(client, MapSet_Official);
				case 1: CollectAllMapsEx(client, MapSet_Custom);
				case 2: CollectAllMapsEx(client, MapSet_Mixtape);
			}

			CPrintToChat(client, "%t", "SelectMapsIntoPool");
			CPrintToChat(client, "%t", "CanOnlySelect", g_hCvar_MapPoolCapacity.IntValue);
		}

		case MenuAction_End:
			delete menu;

		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
				CreateMixmapMenu(client);
		}
	}
}
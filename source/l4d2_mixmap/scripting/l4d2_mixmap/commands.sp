#if defined _l4d2_mixmap_commands_included
 #endinput
#endif
#define _l4d2_mixmap_commands_included

Action Command_Mixmap(int client, int args) 
{
	if (g_bMapsetInitialized) 
	{
		CPrintToChat(client, "has started.");
		return Plugin_Handled;
	}

	Menu menu = new Menu(MenuHandler_Mixmap);
	menu.SetTitle("Mapset Menu");

	menu.AddItem("1", "Official Mapset");
	menu.AddItem("2", "Custom Mapset");
	menu.AddItem("3", "Mixtape Mapset");
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

// Abort a currently loaded mapset
Action Command_StopMixmap(int client, int args) 
{
	if (!g_bMapsetInitialized) 
	{
		CPrintToChat(client, "Not started yet");
		return Plugin_Handled;
	}

    CreateStopMixmapVote(client);
	return Plugin_Continue;
}

// Loads a specified set of maps
Action Command_ForceMixmap(int client, int args) 
{
	char sArg[8];
	GetCmdArg(1, sArg, sizeof(sArg));

	int iMapSet = StringToInt(sArg);
	if (iMapSet < 1 || iMapSet > 3)
	{
		CPrintToChat(client, "Invalid mapset type.");
		return Plugin_Handled;
	}

	InitiateMixmap(view_as<MapSetType>(iMapSet));
	return Plugin_Handled;
}

Action Command_ForceStopMixmap(int client, int args) 
{
	if (!g_bMapsetInitialized) 
	{
		CPrintToChat(client, "Has not started yet.");
		return Plugin_Handled;
	}

	PluginStartInit();
	CPrintToChatAllEx(client, "Admin %N forces stopped.", client);
	return Plugin_Handled;
}

// Display current map list
Action Command_Maplist(int client, int args) 
{
	if (!g_bMapsetInitialized) 
	{
		CPrintToChat(client, "Has not started yet.");
		return Plugin_Handled;
	}

	if (!g_hArrayPools || !g_hArrayPools.Length)
		return Plugin_Handled;

	CPrintToChat(client, "Map List");
	
	char sMap[128];
	for (int i = 0; i < g_hArrayPools.Length; i++)
	{
		g_hArrayPools.GetString(i, sMap, sizeof(sMap));
		CPrintToChat(client, "> %s", sMap);
	}

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
			}
		}

		case MenuAction_End:
			delete menu;
	}
}
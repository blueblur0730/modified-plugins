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

    CreateMixmapVote(client);
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
	InitiateMixmap();
	return Plugin_Handled;
}

Action Command_ForceStopMixmap(int client, int args) 
{
	if (!g_bMapsetInitialized) 
	{
		//CPrintToChatAll("%t", "Not_Start");
		return Plugin_Handled;
	}

	PluginStartInit();
	//CPrintToChatAllEx(client, "%t", "Stop_Mixmap_Admin", client);
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


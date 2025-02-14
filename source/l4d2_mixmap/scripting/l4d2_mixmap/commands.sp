#if defined _l4d2_mixmap_commands_included
 #endinput
#endif
#define _l4d2_mixmap_commands_included

Action Command_Mixmap(int client, int args) 
{
	if (g_bMapsetInitialized) 
	{
		CPrintToChat(client, "have started");
		return Plugin_Handled;
	}

	if (IsClientAndInGame(client))
	{
		if (!ShouldAllowNewVote())
            CreateMixmapVote(client);
		else
			CPrintToChat(client, "Vote In Progress");
	}

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

	if (IsClientAndInGame(client))
	{
		if (!ShouldAllowNewVote())
            CreateStopMixmapVote(client);
		else
			CPrintToChat(client, "Vote In Progress");
	}

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

Action Command_ShowAllMaps(int client, int Args)
{
	if (!L4D2_IsScavengeMode())
	{
		CPrintToChat(client, "%t", "AllMaps_Official");
		CPrintToChat(client, "c1m1_hotel,c1m2_streets,c1m3_mall,c1m4_atrium");
		CPrintToChat(client, "c2m1_highway,c2m2_fairgrounds,c2m3_coaster,c2m4_barns,c2m5_concert");
		CPrintToChat(client, "c3m1_plankcountry,c3m2_swamp,c3m3_shantytown,c3m4_plantation");
		CPrintToChat(client, "c4m1_milltown_a,c4m2_sugarmill_a,c4m3_sugarmill_b,c4m4_milltown_b,c4m5_milltown_escape");
		CPrintToChat(client, "c5m1_waterfront,c5m2_park,c5m3_cemetery,c5m4_quarter,c5m5_bridge");
		CPrintToChat(client, "c6m1_riverbank,c6m2_bedlam,c7m1_docks,c7m2_barge,c7m3_port");
		CPrintToChat(client, "c8m1_apartment,c8m2_subway,c8m3_sewers,c8m4_interior,c8m5_rooftop");
		CPrintToChat(client, "c9m1_alleys,c9m2_lots,c14m1_junkyard,c14m2_lighthouse");
		CPrintToChat(client, "c10m1_caves,c10m2_drainage,c10m3_ranchhouse,c10m4_mainstreet,c10m5_houseboat");
		CPrintToChat(client, "c11m1_greenhouse,c11m2_offices,c11m3_garage,c11m4_terminal,c11m5_runway");
		CPrintToChat(client, "c12m1_hilltop,c12m2_traintunnel,c12m3_bridge,c12m4_barn,c12m5_cornfield");
		CPrintToChat(client, "c13m1_alpinecreek,c13m2_southpinestream,c13m3_memorialbridge,c13m4_cutthroatcreek");
		CPrintToChat(client, "%t", "AllMaps_Usage");
	}
	else
	{
		CPrintToChat(client, "%t", "AllMaps_Official");
		CPrintToChat(client, "c1m4_atrium");
		CPrintToChat(client, "c2m1_highway");
		CPrintToChat(client, "c3m1_plankcountry");
		CPrintToChat(client, "c4m1_milltown_a, c4m2_sugarmill_a, c4m3_sugarmill_b");
		CPrintToChat(client, "c5m2_park");
		CPrintToChat(client, "c6m1_riverbank, c6m2_bedlam, c6m3_port, c7m1_docks, c7m2_barge, c7m3_port");
		CPrintToChat(client, "c8m1_apartment, c8m5_rooftop");
		CPrintToChat(client, "c9m1_alleys, c14m1_junkyard, c14m2_lighthouse");
		CPrintToChat(client, "c10m3_ranchhouse");
		CPrintToChat(client, "c11m4_terminal");
		CPrintToChat(client, "c12m5_cornfield");
		CPrintToChat(client, "c14m1_junkyard, c14m2_lighthouse");
		CPrintToChat(client, "%t", "AllMaps_Usage");
	}

	return Plugin_Handled;
}

/*
// Display current map list
Action Command_Maplist(int client, int args) 
{
	if (!g_bMaplistFinalized) 
	{
		CPrintToChat(client, "%t", "Show_Maplist_Not_Start");
		return Plugin_Handled;
	}

	char output[BUF_SZ];
	char buffer[BUF_SZ];

	CPrintToChat(client, "%t", "Maplist_Title");
	
	for (int i = 0; i < g_hArrayMapOrder.Length; i++) 
	{
		g_hArrayMapOrder.GetString(i, buffer, BUF_SZ);
		if (g_iMapsPlayed == i)
			FormatEx(output, BUF_SZ, "\x04 %d - %s", i + 1, buffer);
		else if (!g_cvNextMapPrint.IntValue && g_iMapsPlayed < i)
		{
			FormatEx(output, BUF_SZ, "\x01 %d - %T", i + 1, "Secret", client);
			CPrintToChat(client, "%s", output);
			continue;
		}
		else FormatEx(output, BUF_SZ, "\x01 %d - %s", i + 1, buffer);

		if (GetPrettyName(buffer)) 
		{
			if (g_iMapsPlayed == i) 
				FormatEx(output, BUF_SZ, "\x04%d - %s", i + 1, buffer);
			else
				FormatEx(output, BUF_SZ, "%d - %s ", i + 1, buffer);
		}
		CPrintToChat(client, "%s", output);
	}
	CPrintToChat(client, "%t", "Show_Maplist_Cmd");

	return Plugin_Handled;
}
*/

#if defined _l4d2_mixmap_command_included
 #endinput
#endif
#define _l4d2_mixmap_command_included

// ----------------------------------------------------------
// 		Commands: Console/Admin
// ----------------------------------------------------------

// Loads a specified set of maps
public Action ForceMixmap(int client, any args) 
{
	if (!L4D2_IsScavengeMode() && !L4D_IsSurvivalMode())	// for coop/reliasm and versus only
		Format(cfg_exec, sizeof(cfg_exec), CFG_DEFAULT);
	else if (L4D2_IsScavengeMode())
		Format(cfg_exec, sizeof(cfg_exec), CFG_DEFAULT_SCAV);

	
	if (args >=1)
	{
		char sBuffer[BUF_SZ], arg[BUF_SZ];

		if (!L4D2_IsScavengeMode() && !L4D_IsSurvivalMode())
		{
			GetCmdArg(1, arg, BUF_SZ);
			Format(sBuffer, sizeof(sBuffer), "cfg/%s%s.cfg", DIR_CFGS, arg);
			if (FileExists(sBuffer)) Format(cfg_exec, sizeof(cfg_exec), arg);
			else
			{
				if (StrEqual(arg, CFG_DODEFAULT_ST))
					Format(cfg_exec, sizeof(cfg_exec), CFG_DODEFAULT);
				else if (StrEqual(arg, CFG_ALLOF_ST))
					Format(cfg_exec, sizeof(cfg_exec), CFG_ALLOF);
				else if (StrEqual(arg, CFG_DOALLOF_ST))
					Format(cfg_exec, sizeof(cfg_exec), CFG_DOALLOF);
				else if (StrEqual(arg, CFG_UNOF_ST))
					Format(cfg_exec, sizeof(cfg_exec), CFG_UNOF);
				else if (StrEqual(arg, CFG_DOUNOF_ST))
					Format(cfg_exec, sizeof(cfg_exec), CFG_DOUNOF);
				else
				{
					CReplyToCommand(client, "%t", "Invalid_Cfg");
					return Plugin_Handled;
				}
			}
		}
		else if (L4D2_IsScavengeMode())
		{
			GetCmdArg(1, arg, BUF_SZ);
			Format(sBuffer, sizeof(sBuffer), "cfg/%s%s.cfg", DIR_CFGS_SCAV, arg);
			if (FileExists(sBuffer)) Format(cfg_exec, sizeof(cfg_exec), arg);
			else
			{
				if (StrEqual(arg, CFG_DODEFAULT_ST_SCAV))
					Format(cfg_exec, sizeof(cfg_exec), CFG_DODEFAULT_SCAV);
				else if (StrEqual(arg, CFG_UNOF_ST_SCAV))
					Format(cfg_exec, sizeof(cfg_exec), CFG_UNOF_SCAV);
				else if (StrEqual(arg, CFG_DOUNOF_ST_SCAV))
					Format(cfg_exec, sizeof(cfg_exec), CFG_DOUNOF_SCAV);
				else
				{
					CReplyToCommand(client, "%t", "Invalid_Cfg");
					return Plugin_Handled;
				}
			}
		}
	}

	if (client) CPrintToChatAllEx(client, "%t", "Force_Start", client, cfg_exec);
	PluginStartInit();
	if (client == 0) g_bServerForceStart = true;

	if (!L4D2_IsScavengeMode() && !L4D_IsSurvivalMode())
		ServerCommand("exec %s%s.cfg", DIR_CFGS, cfg_exec);
	else if (L4D2_IsScavengeMode())
		ServerCommand("exec %s%s.cfg", DIR_CFGS_SCAV, cfg_exec);

	g_bMapsetInitialized = true;
	CreateTimer(0.1, Timed_PostMapSet);

	return Plugin_Handled;
}

// Load a specified set of maps
public Action ManualMixmap(int client, any args) 
{
	if (args < 1) CPrintToChat(client, "%t", "Manualmixmap_Syntax");
	
	PluginStartInit();

	char map[BUF_SZ];
	for (int i = 1; i <= args; i++) 
	{
		GetCmdArg(i, map, BUF_SZ);
		ServerCommand("sm_addmap %s %d", map, i);
		ServerCommand("sm_tagrank %d %d", i, i-1);
	}
	g_bMapsetInitialized = true;
	CreateTimer(0.1, Timed_PostMapSet);

	return Plugin_Handled;
}

public Action ShowAllMaps(int client, any Args)
{
	if (!L4D2_IsScavengeMode() && !L4D_IsSurvivalMode())
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
	else if (L4D2_IsScavengeMode())
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


// ----------------------------------------------------------
// 		Commands: Client
// ----------------------------------------------------------
public Action Mixmap_Cmd(int client, any args) 
{
	if (IsClientAndInGame(client))
	{
		if (!IsBuiltinVoteInProgress())
		{
			if (!L4D2_IsScavengeMode() && !L4D_IsSurvivalMode())	// for coop/reliasm and versus only
				Format(cfg_exec, sizeof(cfg_exec), CFG_DEFAULT);
			else if (L4D2_IsScavengeMode())
				Format(cfg_exec, sizeof(cfg_exec), CFG_DEFAULT_SCAV);
	
			if (args >=1)
			{
				char sBuffer[BUF_SZ], arg[BUF_SZ];
				if (!L4D2_IsScavengeMode() && !L4D_IsSurvivalMode())
				{
					GetCmdArg(1, arg, BUF_SZ);
					Format(sBuffer, sizeof(sBuffer), "cfg/%s%s.cfg", DIR_CFGS, arg);
					if (FileExists(sBuffer)) Format(cfg_exec, sizeof(cfg_exec), arg);
					else
					{
						if (StrEqual(arg, CFG_DODEFAULT_ST))
							Format(cfg_exec, sizeof(cfg_exec), CFG_DODEFAULT);
						else if (StrEqual(arg, CFG_ALLOF_ST))
							Format(cfg_exec, sizeof(cfg_exec), CFG_ALLOF);
						else if (StrEqual(arg, CFG_DOALLOF_ST))
							Format(cfg_exec, sizeof(cfg_exec), CFG_DOALLOF);
						else if (StrEqual(arg, CFG_UNOF_ST))
							Format(cfg_exec, sizeof(cfg_exec), CFG_UNOF);
						else if (StrEqual(arg, CFG_DOUNOF_ST))
							Format(cfg_exec, sizeof(cfg_exec), CFG_DOUNOF);
						else
						{
							CReplyToCommand(client, "%t", "Invalid_Cfg");
							return Plugin_Handled;
						}
					}
				}
				else if (L4D2_IsScavengeMode())
				{
					GetCmdArg(1, arg, BUF_SZ);
					Format(sBuffer, sizeof(sBuffer), "cfg/%s%s.cfg", DIR_CFGS_SCAV, arg);
					if (FileExists(sBuffer)) Format(cfg_exec, sizeof(cfg_exec), arg);
					else
					{
						if (StrEqual(arg, CFG_DODEFAULT_ST_SCAV))
							Format(cfg_exec, sizeof(cfg_exec), CFG_DODEFAULT_SCAV);
						else if (StrEqual(arg, CFG_UNOF_ST_SCAV))
							Format(cfg_exec, sizeof(cfg_exec), CFG_UNOF_SCAV);
						else if (StrEqual(arg, CFG_DOUNOF_ST_SCAV))
							Format(cfg_exec, sizeof(cfg_exec), CFG_DOUNOF_SCAV);
						else
						{
							CReplyToCommand(client, "%t", "Invalid_Cfg");
							return Plugin_Handled;
						}
					}
				}
			}

			CreateMixmapVote(client);
		}
		else
			PrintToChat(client, "%t", "Vote_Progress");

		return Plugin_Handled;
	}

	return Plugin_Continue;
}

// Display current map list
public Action Maplist(int client, any args) 
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

// Abort a currently loaded mapset
public Action StopMixmap_Cmd(int client, any args) 
{
	if (!g_bMapsetInitialized) 
	{
		CPrintToChat(client, "%t", "Not_Start");
		return Plugin_Handled;
	}
	if (IsClientAndInGame(client))
	{
		if (!IsBuiltinVoteInProgress())
            CreateStopMixmapVote(client);
		else
			PrintToChat(client, "%t", "Vote_Progress");

		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action StopMixmap(int client, any args) 
{
	if (!g_bMapsetInitialized) 
	{
		CPrintToChatAll("%t", "Not_Start");
		return Plugin_Handled;
	}

	if (g_hCountDownTimer) 
	{
		// interrupt any upcoming transitions
		KillTimer(g_hCountDownTimer);
	}

	PluginStartInit();

	CPrintToChatAllEx(client, "%t", "Stop_Mixmap_Admin", client);
	return Plugin_Handled;
}

// Specifiy a rank for a given tag
public Action TagRank(any args) 
{
	if (args < 2) 
	{
		ReplyToCommand(0, "Syntax: sm_tagrank <tag> <map number>");
		ReplyToCommand(0, "Sets tag <tag> as the tag to be used to fetch maps for map <map number> in the map list.");
		ReplyToCommand(0, "Rank 0 is map 1, rank 1 is map 2, etc.");

		return Plugin_Handled;
	}

	char buffer[BUF_SZ];
	GetCmdArg(2, buffer, BUF_SZ);
	int index = StringToInt(buffer);

	GetCmdArg(1, buffer, BUF_SZ);

	if (index >= g_hArrayTagOrder.Length) 
		g_hArrayTagOrder.Resize(index + 1);

	g_iMapCount++;
	g_hArrayTagOrder.SetString(index, buffer);
	if (g_hArrayTags.FindString(buffer) < 0) 
		g_hArrayTags.PushString(buffer);

	return Plugin_Handled;
}

// Add a map to the maplist under specified tags
public Action AddMap(any args) 
{
	if (args < 2) 
	{
		ReplyToCommand(0, "Syntax: sm_addmap <mapname> <tag1> <tag2> <...>");
		ReplyToCommand(0, "Adds <mapname> to the map selection and tags it with every mentioned tag.");

		return Plugin_Handled;
	}

	char map[BUF_SZ];
	GetCmdArg(1, map, BUF_SZ);

	char tag[BUF_SZ];

	//add the map under only one of the tags
	//TODO - maybe we should add it under all tags, since it might be removed from 1+ or even all of them anyway
	//also, if that ends up being implemented, remember to remove vetoed maps from ALL the pools it belongs to
	if (args == 2) 
		GetCmdArg(2, tag, BUF_SZ);
	else 
		GetCmdArg(GetRandomInt(2, args), tag, BUF_SZ);

	ArrayList hArrayMapPool;
	if (! g_hTriePools.GetValue(tag, hArrayMapPool)) 
		g_hTriePools.SetValue(tag, (hArrayMapPool = new ArrayList(BUF_SZ/4)));

	hArrayMapPool.PushString(map);

	return Plugin_Handled;
}
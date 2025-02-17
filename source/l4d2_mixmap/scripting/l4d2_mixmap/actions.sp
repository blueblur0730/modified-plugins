#if defined _l4d2_mixmap_actions_included
 #endinput
#endif
#define _l4d2_mixmap_actions_included

void InitiateMixmap(MapSetType type)
{
	CollectAllMaps(type);
	if (!SelectRandomMap())
	{
		CPrintToChatAll("%t", "FailedToGet");
		g_bMapsetInitialized = false;
		return;
	}

	g_iMapsetType = type;
	CPrintToChatAll("%t", "StatingIn", g_hCvar_SecondsToRead.IntValue);
	CreateTimer(5.0, Timer_StartFisrMixmap);
}

// OnChangeMissionVote needs mission name.
void Timer_StartFisrMixmap(Handle timer)
{
	char sMap[128], sMissionName[128];
	g_hArrayPools.GetString(0, sMap, sizeof(sMap));
	g_hMapChapterNames.GetString(sMap, sMissionName, sizeof(sMissionName));
	//g_hLogger.DebugEx("### Starting Mixmap with %s", sMissionName);
	SDKCall(g_hSDKCall_OnChangeMissionVote, g_pTheDirector, sMissionName);

	g_bMapsetInitialized = true;
	Call_StartForward(g_hForwardStart);
	Call_PushCell(g_hCvar_MapPoolCapacity.IntValue);
	Call_Finish();
}

void OnGameplayStart(const char[] output, int caller, int activator, float delay)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2)
			CheatCommand(i, "warp_to_start_area");
	}

	char sBuffer[128], sMap[128];
	GetCurrentMap(sBuffer, sizeof(sBuffer));
	g_hArrayPools.GetString(g_hArrayPools.Length - 1, sMap, sizeof(sMap));
	if (StrEqual(sBuffer, sMap))
		CPrintToChatAll("%t", "HaveReachedTheEnd");
}

void NotifyMixmap(int client)
{
	char sCurrentMap[64], sNextMap[64];
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));

	if (g_iMapsPlayed >= g_hArrayPools.Length)
		Format(sNextMap, sizeof(sNextMap), "%T", "None", client);
	else
		g_hArrayPools.GetString(g_iMapsPlayed, sNextMap, sizeof(sNextMap));

	CPrintToChat(client, "%t", "NotifyClients");
	CPrintToChat(client, "%t", "MapProgress", sCurrentMap, sNextMap);
}

void NotifyMapList(int client)
{
	CPrintToChat(client, "%t", "MapList");

	char sBuffer[64], sCurrentMap[64];
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
	for (int i = 0; i < g_hArrayPools.Length; i++)
	{
		g_hArrayPools.GetString(i, sBuffer, sizeof(sBuffer));
		CPrintToChat(client, "{green}-> {olive}%s{default} %s", sBuffer, !strcmp(sCurrentMap, sBuffer) ? "({orange}Current{default})" : "");
	}
}
/*
// here we store the match or game info for the next map.
Action Timed_NextMapInfo(Handle timer)
{
	char ssMapName_New[64], ssMapName_Old[64];
	g_hArrayPools.GetString(g_iMapsPlayed, ssMapName_New, 64);
	g_hArrayPools.GetString(g_iMapsPlayed - 1, ssMapName_Old, 64);

	g_cvNextMapPrint.BoolValue ? CPrintToChatAll("%t", "Show_Next_Map",  ssMapName_New) : CPrintToChatAll("%t%t", "Show_Next_Map",  "", "Secret");

	if (L4D_IsVersusMode())
	{
		if ((StrEqual(ssMapName_Old, "c6m2_bedlam") && !StrEqual(ssMapName_New, "c7m1_docks"))
		|| (StrEqual(ssMapName_Old, "c9m2_lots") && !StrEqual(ssMapName_New, "c14m1_junkyard")))
		{
			s_iPointsTeam_A = L4D2Direct_GetVSCampaignScore(0);
			s_iPointsTeam_B = L4D2Direct_GetVSCampaignScore(1);
			g_bCMapTransitioned = true;

			PrintToServer("[Mixmap] Timer_Gotomap creating.");

			CreateTimer(9.0, Timed_Gotomap);	//this command must set ahead of the l4d2_map_transition plugin setting. Otherwise the map will be c7m1_docks/c14m1_junkyard after c6m2_bedlam/c9m2_lots
		}
		else if ((!StrEqual(ssMapName_Old, "c6m2_bedlam") && StrEqual(ssMapName_New, "c7m1_docks"))
		|| (!StrEqual(ssMapName_Old, "c9m2_lots") && StrEqual(ssMapName_New, "c14m1_junkyard")))
		{
			s_iPointsTeam_A = L4D2Direct_GetVSCampaignScore(0);
			s_iPointsTeam_B = L4D2Direct_GetVSCampaignScore(1);
			g_bCMapTransitioned = true;

			PrintToServer("[Mixmap] Timer_Gotomap creating.");

			CreateTimer(10.0, Timed_Gotomap);	//this command must set ahead of the l4d2_map_transition plugin setting. Otherwise the map will be c7m1_docks/c14m1_junkyard after c6m2_bedlam/c9m2_lots
		}
	}

	return Plugin_Handled;
}
*/
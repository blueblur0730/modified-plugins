#if defined _l4d2_mixmap_actions_included
 #endinput
#endif
#define _l4d2_mixmap_actions_included

void InitiateMixmap(MapSetType type)
{
	switch (type)
	{
		case MapSet_Official, MapSet_Custom, MapSet_Mixtape:
		{
			CollectAllMaps(type);
			if (!SelectRandomMap())
			{
				CPrintToChatAll("%t", "FailedToGet");
				g_bMapsetInitialized = false;
				return;
			}

			g_iMapsetType = type;
			CPrintToChatAll("%t", "StartingIn", g_hCvar_SecondsToRead.IntValue);
			CreateTimer(g_hCvar_SecondsToRead.FloatValue, Timer_StartFirstMixmap);
		}

		case MapSet_Manual:
		{
			g_iMapsetType = type;
			CPrintToChatAll("%t", "StartingIn", g_hCvar_SecondsToRead.IntValue);
			CreateTimer(g_hCvar_SecondsToRead.FloatValue, Timer_StartFirstMixmapManully);
		}
	}
}

// OnChangeMissionVote needs mission name.
void Timer_StartFirstMixmap(Handle timer)
{
	char sMap[128], sMissionName[128];
	g_hArrayPools.GetString(0, sMap, sizeof(sMap));
	g_hMapChapterNames.GetString(sMap, sMissionName, sizeof(sMissionName));
	g_hLogger.InfoEx("### Starting Mixmap with %s", sMissionName);
	SDKCall(g_hSDKCall_OnChangeMissionVote, g_pTheDirector, sMissionName);

	g_bMapsetInitialized = true;
	Call_StartForward(g_hForwardStart);
	Call_PushCell(g_hCvar_MapPoolCapacity.IntValue);
	Call_Finish();
}

void Timer_StartFirstMixmapManully(Handle timer)
{
	char sMap[128];
	g_hArrayPools.GetString(0, sMap, sizeof(sMap));
	g_hLogger.InfoEx("### Starting Mixmap with %s", sMap);
	SDKCall(g_hSDKCall_OnChangeChapterVote, g_pTheDirector, sMap);

	g_bMapsetInitialized = true;
	Call_StartForward(g_hForwardStart);
	Call_PushCell(g_hCvar_MapPoolCapacity.IntValue);
	Call_Finish();
}

void Timer_Notify(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (client <= 0 || client > MaxClients)
		return;

	if (!IsClientInGame(client))
		return;
	
	NotifyMixmap(client);
}

void Timer_ShowMaplist(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (client <= 0 || client > MaxClients)
		return;

	if (!IsClientInGame(client))
		return;

	NotifyMapList(client);
}

void NotifyMixmap(int client)
{
	char sCurrentMap[64], sNextMap[64];
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));

	if (g_iMapsPlayed >= g_hArrayPools.Length)
		Format(sNextMap, sizeof(sNextMap), "%T", "None", client);
	else
		g_hArrayPools.GetString(g_iMapsPlayed, sNextMap, sizeof(sNextMap));

	CPrintToChat(client, "%t", "MapProgress", sCurrentMap, sNextMap);

	if (g_iMapsPlayed == g_hArrayPools.Length)
		CPrintToChat(client, "%t", "HaveReachedTheEnd");
}

void NotifyMapList(int client)
{
	if (g_hArrayPools.Length > 6)
		CPrintToChat(client, "%t", "SeeConsole");

	g_hArrayPools.Length > 6 ?	// we have a small chat right?
	PrintToConsole(client, "%t", "MapList_NoColor") :
	CPrintToChat(client, "%t", "MapList");
	
	char sBuffer[64], sCurrentMap[64], sCurrent[32];
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
	Format(sCurrent, sizeof(sCurrent), "%T", "Current", client);
	for (int i = 0; i < g_hArrayPools.Length; i++)
	{
		g_hArrayPools.GetString(i, sBuffer, sizeof(sBuffer));
		g_hArrayPools.Length > 6 ?
		PrintToConsole(client, "-> %s %s", sBuffer, (!strcmp(sCurrentMap, sBuffer) && g_iMapsPlayed == i + 1) ? sCurrent : "") :
		CPrintToChat(client, "{green}-> {olive}%s{default} {orange}%s{default}", sBuffer, (!strcmp(sCurrentMap, sBuffer) && g_iMapsPlayed == i + 1) ? sCurrent : "");
	}
}

void Patch(bool bPatch)
{
	static bool bPatched = false;
	if (bPatch && !bPatched)
	{
		g_hPatch_BlockRestoring.Enable();
		bPatched = true;
	}
	else if (!bPatch && bPatched)
	{
		g_hPatch_BlockRestoring.Disable();
		bPatched = false;
	}
}

void PluginStartInit()
{
	g_bMapsetInitialized = false;
	g_iMapsPlayed		 = 0;
	g_iMapsetType        = MapSet_None;
	delete g_hArrayPools;
	delete g_hMapChapterNames;
	delete g_hArraySurvivorSets;
}

void ErrorHandler_LogToFile(const char[] msg, const char[] name, const char[] file, int line, const char[] func)
{
	char sBuffer[256];
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), LOGGER_ERROR_FILE);
	LogToFile(sBuffer, "[Log4sp] Error occurs: (%s)", msg);
	LogToFile(sBuffer, "[Log4sp] in function [%s]", func);
	LogToFile(sBuffer, "[Log4sp] at [%s:line %d]", file, line);
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
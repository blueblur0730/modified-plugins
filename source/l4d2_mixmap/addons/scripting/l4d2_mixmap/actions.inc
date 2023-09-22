#if defined _l4d2_mixmap_actions_included
 #endinput
#endif
#define _l4d2_mixmap_actions_included
// ----------------------------------------------------------
// 		Map switching logic
// ----------------------------------------------------------
Action PerformMapProgression()
{
	if (++g_iMapsPlayed < g_iMapCount)
	{
		GotoNextMap(false);
		return Plugin_Handled;
	}
	else if (g_cvFinaleEndStart.IntValue)
		CreateTimer(9.0, Timed_ContinueMixmap);

	Call_StartForward(g_hForwardEnd);
	Call_Finish();

	return Plugin_Handled;
}

void GotoNextMap(bool force = false)
{
	char sMapName[BUF_SZ];
	g_hArrayMapOrder.GetString(g_iMapsPlayed, sMapName, BUF_SZ);

	GotoMap(sMapName, force);
}

void GotoMap(const char[] sMapName, bool force = false)
{
	if (force)
	{
		ForceChangeLevel(sMapName, "Mixmap");
		return;
	}
	ServerCommand("sm_nextmap %s", sMapName);
	CreateTimer(5.0, Timed_NextMapInfo);
}

public Action Timed_NextMapInfo(Handle timer)
{
	char sMapName_New[BUF_SZ], sMapName_Old[BUF_SZ];
	g_hArrayMapOrder.GetString(g_iMapsPlayed, sMapName_New, BUF_SZ);
	g_hArrayMapOrder.GetString(g_iMapsPlayed - 1, sMapName_Old, BUF_SZ);

	g_cvNextMapPrint.BoolValue ? CPrintToChatAll("%t", "Show_Next_Map",  sMapName_New) : CPrintToChatAll("%t%t", "Show_Next_Map",  "", "Secret");

	if (L4D_IsVersusMode())
	{
		if ((StrEqual(sMapName_Old, "c6m2_bedlam") && !StrEqual(sMapName_New, "c7m1_docks"))
		|| (StrEqual(sMapName_Old, "c9m2_lots") && !StrEqual(sMapName_New, "c14m1_junkyard")))
		{
			g_iPointsTeam_A = L4D2Direct_GetVSCampaignScore(0);
			g_iPointsTeam_B = L4D2Direct_GetVSCampaignScore(1);
			g_bCMapTransitioned = true;
			CreateTimer(9.0, Timed_Gotomap);	//this command must set ahead of the l4d2_map_transition plugin setting. Otherwise the map will be c7m1_docks/c14m1_junkyard after c6m2_bedlam/c9m2_lots
		}
		else if ((!StrEqual(sMapName_Old, "c6m2_bedlam") && StrEqual(sMapName_New, "c7m1_docks"))
		|| (!StrEqual(sMapName_Old, "c9m2_lots") && StrEqual(sMapName_New, "c14m1_junkyard")))
		{
			g_iPointsTeam_A = L4D2Direct_GetVSCampaignScore(0);
			g_iPointsTeam_B = L4D2Direct_GetVSCampaignScore(1);
			g_bCMapTransitioned = true;
			CreateTimer(10.0, Timed_Gotomap);	//this command must set ahead of the l4d2_map_transition plugin setting. Otherwise the map will be c7m1_docks/c14m1_junkyard after c6m2_bedlam/c9m2_lots
		}
	}
	else if (L4D2_IsScavengeMode())
	{
		MatchInfo esMatchInfo;

		// currently we are flipped.
		esMatchInfo.rs_TeamA = GetScavengeTeamScore(2, GetScavengeRoundNumber());		// team index 1, score 2, match score 0
		esMatchInfo.rs_TeamB = GetScavengeTeamScore(3, GetScavengeRoundNumber());		// team index 0, score 8, match score 1
		esMatchInfo.ms_TeamA = GetScavengeMatchScore(2);
		esMatchInfo.ms_TeamB = GetScavengeMatchScore(3);
		esMatchInfo.winner	 = GetWinningTeamNumber(GetScavengeRoundNumber());

#if DEBUG
		PrintToServer("[Mixmap] Survivor Round Score: %d", esMatchInfo.rs_TeamA);
		PrintToServer("[Mixmap] Infected Round Score: %d", esMatchInfo.rs_TeamB);
		PrintToServer("[Mixmap] Survivor Match Score: %d", esMatchInfo.ms_TeamA);
		PrintToServer("[Mixmap] Infected Match Score: %d", esMatchInfo.ms_TeamB);
		PrintToServer("[Mixmap] Winner Team Index: %d", esMatchInfo.winner);
#endif
		g_bCMapTransitioned = true;
		g_hArrayMatchInfo.PushArray(esMatchInfo);
		CreateTimer(5.0, Timed_Gotomap);
	}

	return Plugin_Handled;
}

public Action Timed_Gotomap(Handle timer)
{
	char sMapName_New[BUF_SZ];
	g_hArrayMapOrder.GetString(g_iMapsPlayed, sMapName_New, BUF_SZ);

	GotoMap(sMapName_New, true);
	return Plugin_Handled;
}

public Action Timed_ContinueMixmap(Handle timer)
{
	ServerCommand("sm_fmixmap %s", cfg_exec);
	return Plugin_Handled;
}

public Action Timed_GiveThemTimeToReadTheMapList(Handle timer)
{
	if (IsBuiltinVoteInProgress() && !g_bServerForceStart)
	{
		CPrintToChatAll("%t", "Vote_Progress_delay");
		g_hCountDownTimer = CreateTimer(20.0, Timed_GiveThemTimeToReadTheMapList);
		return Plugin_Handled;
	}
	if (g_bServerForceStart) g_bServerForceStart = false;
	g_hCountDownTimer = null;

	// call starting forward
	char buffer[BUF_SZ];
	g_hArrayMapOrder.GetString(0, buffer, BUF_SZ);

	Call_StartForward(g_hForwardStart);
	Call_PushCell(g_iMapCount);
	Call_PushString(buffer);
	Call_Finish();

	GotoNextMap(true);
	return Plugin_Handled;
}

//-----------------------------------------------------------
//			Set Info
//-----------------------------------------------------------
void SetVersusScores()
{
	//If team B is winning, swap teams. Does not change how scores are set
	if (g_iPointsTeam_A < g_iPointsTeam_B)
		L4D2_SwapTeams();

	//Set scores on scoreboard
	SDKCall(g_hCMapSetCampaignScores, g_iPointsTeam_A, g_iPointsTeam_B);

	//Set actual scores
	L4D2Direct_SetVSCampaignScore(0, g_iPointsTeam_A);
	L4D2Direct_SetVSCampaignScore(1, g_iPointsTeam_B);
}

void SetScavengeScores()
{
	MatchInfo esMatchInfo;
	for (int i = 0; i < g_iMapsPlayed; i++)
	{
		g_hArrayMatchInfo.GetArray(i, esMatchInfo);

		// currently we are unflipped
		SetScavengeRoundNumber(g_iMapsPlayed + 1);
		SetScavengeTeamScore(3, i + 1, esMatchInfo.rs_TeamA);		// team index 1
		SetScavengeTeamScore(2, i + 1, esMatchInfo.rs_TeamB);		// team index 0

		if (i == g_iMapsPlayed - 1)		// we only set the score at the end of array
		{
			SetScavengeMatchScore(3, esMatchInfo.ms_TeamA);		// team index 0
			SetScavengeMatchScore(2, esMatchInfo.ms_TeamB);		// team index 1
		}

		// to do: are teams swapped after map changed? if not, we need another way to swap teams.
		SetWinningTeamNumber(i + 1, esMatchInfo.winner);
	}
}
#if defined _l4d2_mixmap_util_included
 #endinput
#endif
#define _l4d2_mixmap_util_included

// ----------------------------------------------------------
// 		Basic logic helpers
// ----------------------------------------------------------
// Return false if pretty name not found, ture otherwise
stock bool GetPrettyName(char[] map) 
{
	static KeyValues hKvMapNames = null;
	if (hKvMapNames == null) 
	{
		hKvMapNames = new KeyValues("Mixmap Map Names");
		if (!hKvMapNames.ImportFromFile(PATH_KV)) 
		{
			LogMessage("Couldn't create KV for map names.");
			hKvMapNames = null;
			return false;
		}
	}
	
	char buffer[BUF_SZ];
	hKvMapNames.GetString(map, buffer, BUF_SZ, "no");
		
	if (!StrEqual(buffer, "no")) 
	{
		strcopy(map, BUF_SZ, buffer);
		return true;
	}
	return false;
}

stock bool IsClientAndInGame(int index) 
{
	return (index > 0 && index <= MaxClients && IsClientInGame(index) && IsClientConnected(index) && !IsFakeClient(index) && GetClientTeam(index) != 1);
}

stock int CheckSameCampaignNum(char[] map)
{
	int count = 0;
	char buffer[BUF_SZ];
	
	for (int i = 0; i < g_hArrayMapOrder.Length; i++)
	{
		g_hArrayMapOrder.GetString(i, buffer, sizeof(buffer));
		if (IsSameCampaign(map, buffer))
			count ++;
	}
	
	return count;
}

stock bool IsSameCampaign(char[] map1, char[] map2)
{
	char buffer1[BUF_SZ], buffer2[BUF_SZ];
	
	strcopy(buffer1, BUF_SZ, map1);
	strcopy(buffer2, BUF_SZ, map2);
	
	if (GetPrettyName(buffer1)) SplitString(buffer1, "_", buffer1, sizeof(buffer1));
	if (GetPrettyName(buffer2)) SplitString(buffer2, "_", buffer2, sizeof(buffer2));
	
	if (StrEqual(buffer1, buffer2)) 
		return true;

	return false;
}

// Returns a handle to the first array which is found to contain the specified mapname
// (should be the first and only one) (will this be used?)
stock ArrayList GetPoolThatContainsMap(char[] map, int index, char[] tag) 
{
	ArrayList hArrayMapPool;

	for (int i = 0; i < g_hArrayTags.Length; i++) 
	{
		g_hArrayTags.GetString(i, tag, BUF_SZ);
		g_hTriePools.GetValue(tag, hArrayMapPool);
		if ((index = hArrayMapPool.FindString(map)) >= 0) {
			return hArrayMapPool;
		}
	}
	return null;
}

// ----------------------------------------------------------
// 		Basic scavenge helpers
// ----------------------------------------------------------
stock bool InSecondHalfOfRound()
{
    return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound", 1));
}

stock int GetScavengeRoundNumber()
{
	return GameRules_GetProp("m_nRoundNumber");
}

stock void SetScavengeRoundNumber(int round)
{
	if (round <= 0 || round > 5)
		return;

	GameRules_SetProp("m_nRoundNumber", round);
}

stock int GetWinningTeamNumber(int round)
{
	return GameRules_GetProp("m_iWinningTeamNumber", _, round - 1);
}

stock void SetWinningTeamNumber(int round, int team)
{
	if (team != 2 || team != 3)
		return;

	if (round <= 0 || round > 5)
		return;

	GameRules_SetProp("m_iWinningTeamNumber", L4D2_TeamNumberToTeamIndex(team), _, round - 1);
}

stock int GetScavengeMatchScore(int team)
{
	if (team != 2 || team != 3) return -1;

	return GameRules_GetProp("m_iScavengeMatchScore", _, L4D2_TeamNumberToTeamIndex(team));
}

stock void SetScavengeMatchScore(int team, int score)
{
	if (team != 2 || team != 3)
		return;

	GameRules_SetProp("m_iScavengeMatchScore", score, 4, L4D2_TeamNumberToTeamIndex(team));
}

stock int GetScavengeTeamScore(int team, int round = -1)
{
	if (team == -1) return -1;

	if (round <= 0 || round > 5)
		round = GameRules_GetProp("m_nRoundNumber");

	return GameRules_GetProp("m_iScavengeTeamScore", _, (2 * (round - 1)) + L4D2_TeamNumberToTeamIndex(team));
}

stock void SetScavengeTeamScore(int team, int round, int score)
{
	if (team != 2 || team != 3)
		return;

	if (round <= 0 || round > 5)
		return;

	GameRules_SetProp("m_iScavengeTeamScore", score, 4, (2 * (round - 1)) + L4D2_TeamNumberToTeamIndex(team));
}

stock int L4D2_TeamNumberToTeamIndex(int team)
{
	if (team != 2 && team != 3) return -1;

	bool flipped = view_as<bool>(GameRules_GetProp("m_bAreTeamsFlipped", 1));
	if (flipped) ++team;
	return team % 2;
}
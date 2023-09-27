#if defined _l4d2_mixmap_util_included
 #endinput
#endif
#define _l4d2_mixmap_util_included

#define DEBUG 1

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
		if (!L4D2_IsScavengeMode())
		{
			if (!hKvMapNames.ImportFromFile(PATH_KV))
			{
				LogMessage("Couldn't create KV for map names.");
				hKvMapNames = null;
				return false;
			}
		}
		else
		{
			if (!hKvMapNames.ImportFromFile(PATH_KV_SCAV))
			{
				LogMessage("Couldn't create KV for map names.");
				hKvMapNames = null;
				return false;
			}
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

stock bool IsClientAndInGame(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) != 1);
}

stock bool IsClientOrBotAndInGame(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) != 1);
}

stock bool IsBotAndInGame(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) != 1);
}

/* from playermanagment.sp . current unused.
// ----------------------------------------------------------
// 		Basic change client team helpers
// ----------------------------------------------------------
stock bool ChangeClientTeamEx(int client, int team, bool force)
{
	if (GetClientTeam(client) == team)
		return true;

	else if (!force && GetTeamHumanCount(team) == GetTeamMaxHumans(team))
		return false;

	if (team != 2)
	{
		ChangeClientTeam(client, team);
		return true;
	}
	else
	{
		int bot = FindSurvivorBot();
		if (bot > 0)
		{
			int flags = GetCommandFlags("sb_takecontrol");
			SetCommandFlags("sb_takecontrol", flags & ~FCVAR_CHEAT);
			FakeClientCommand(client, "sb_takecontrol");
			SetCommandFlags("sb_takecontrol", flags);
			return true;
		}
	}
	return false;
}

stock int GetHumanCount()
{
	int humans = 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientConnected(client) && !IsFakeClient(client))
			humans++;
	}
	
	return humans;
}

stock int GetTeamMaxHumans(int team)
{
	ConVar survivor_limit = FindConVar("survivor_limit");
	ConVar z_max_player_zombies = FindConVar("z_max_player_zombies");

	if (team == 2)
		return survivor_limit.IntValue;
	else if (team == 3)
		return z_max_player_zombies.IntValue;

	return MaxClients;
}

stock int GetTeamHumanCount(int team)
{
	int humans = 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == team)
			humans++;
	}
	
	return humans;
}

stock int FindSurvivorBot()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) == 2)
			return client;
	}
	return -1;
}
*/

// ----------------------------------------------------------
// 		Basic scavenge helpers
// ----------------------------------------------------------
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
	// we use array whose index starts from 0, so we dont do round - 1 here.
	GameRules_SetProp("m_iWinningTeamNumber", team, 4, round);
}

stock int GetScavengeMatchScore(int team)
{
	team = L4D2_TeamNumberToTeamIndex(team);

	return GameRules_GetProp("m_iScavengeMatchScore", _, team);
}

stock void SetScavengeMatchScore(int team, int score)
{
	team = L4D2_TeamNumberToTeamIndex(team);

	GameRules_SetProp("m_iScavengeMatchScore", score, 4, team);
}

stock int GetScavengeTeamScore(int team, int round = -1)
{
	if (round <= 0 || round > 5)
		round = GameRules_GetProp("m_nRoundNumber");

	team = L4D2_TeamNumberToTeamIndex(team);

	return GameRules_GetProp("m_iScavengeTeamScore", _, (2 * (round - 1)) + team);
}

stock void SetScavengeTeamScore(int team, int round, int score)
{
	if (round <= 0 || round > 5)
		return;

	team = L4D2_TeamNumberToTeamIndex(team);

	GameRules_SetProp("m_iScavengeTeamScore", score, 4, (2 * (round - 1)) + team);
}

stock int L4D2_TeamNumberToTeamIndex(int team)
{
	if (team != 2 && team != 3) return -1;

	bool flipped = view_as<bool>(GameRules_GetProp("m_bAreTeamsFlipped", 1));
	if (flipped) ++team;
	return team % 2;
}

/**
 * from spechud 
 * */
stock int GetWeaponClipAmmo(int weapon)
{
	return (weapon > 0 ? GetEntProp(weapon, Prop_Send, "m_iClip1") : -1);
}

stock void SetWeaponClipAmmo(int weapon, int amount)
{
	if (weapon > 0) 
		SetEntProp(weapon, Prop_Send, "m_iClip1", amount);
}
/** 
 * Coop game check
 */
stock bool AreAllLivingSurivorsInEndSafeRoom() 
{
	ConVar hLimit = FindConVar("survivor_limit");
	int iLimit = hLimit.IntValue; int iPlayer = 0; int iDead = 0; int iBot = 0;

	for (int i = 1; i <= MaxClients; i++) 
	{
		if (!IsSurvivorClient(i))
			continue;

		if (!IsPlayerAlive(i))
		{
			iDead++;
			continue;
		}

		if (IsBotAndInGame(i) && SAFEDETECT_IsEntityInEndSaferoom(i)) 	// client index is actually another form of entity index...emm
		{
			iBot++;
			continue;
		}	

		if (IsClientAndInGame(i) && SAFEDETECT_IsPlayerInEndSaferoom(i))
			iPlayer++;
	}

#if DEBUG
		PrintToServer("[Mixmap] iLimit: %d, iPlayer: %d, iBot: %d, iDead: %d", iLimit, iPlayer, iBot, iDead);
#endif

	if (iPlayer + iBot == iLimit - iDead)
		return true;

	return false;
}

stock bool IsSurvivorClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientConnected(client) && GetClientTeam(client) == TEAM_SURVIVOR);
}
#if defined _l4d_stats_timers_included
	#endinput
#endif
#define _l4d_stats_timers_included

Action Timer_ClientPostAdminCheck(Handle timer, int client)
{
	if (!IsClientInGame(client))
	{
		if (g_iPostAdminCheckRetryCounter[client]++ < 10)
			CreateTimer(3.0, Timer_ClientPostAdminCheck, client);

		return Plugin_Handled;
	}

	StartRankChangeCheck(client);

	char SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));

	CheckPlayerDB(client);

	g_iTimerPoints[client]	  = 0;
	g_iTimerKills[client]	  = 0;
	g_iTimerHeadshots[client] = 0;

	CreateTimer(10.0, Timer_RankConnect, client);
	CreateTimer(15.0, Timer_AnnounceConnect, client);

	AnnouncePlayerConnect(client);

	return Plugin_Handled;
}

// Show rank on connect.
Action Timer_RankConnect(Handle timer, int value)
{
	if (g_hCvar_RankOnJoin.BoolValue && !InvalidGameMode())
		cmd_ShowRank(value, 0);

	return Plugin_Handled;
}

// Announce on player connect!
Action Timer_AnnounceConnect(Handle timer, int client)
{
	if (!g_hCvar_AnnounceMode.BoolValue)
		return Plugin_Handled;

	if (!IsClientConnected(client) || !IsClientInGame(client))
	{
		if (g_iAnnounceCounter[client] > 10)
			g_iAnnounceCounter[client] = 0;
		else
		{
			g_iAnnounceCounter[client]++;
			CreateTimer(5.0, Timer_AnnounceConnect, client);
		}

		return Plugin_Handled;
	}

	g_iAnnounceCounter[client]++;

	ShowMOTD(client);
	StatsPrintToChat2(client, true, "Type \x05RANKMENU \x01to operate \x04the Plugin\x01!");

	return Plugin_Handled;
}

Action Timer_ProtectedFriendly(Handle timer, int data)
{
	g_hTimerProtectedFriendly[data]	  = null;
	int ProtectedFriendlies	= g_iProtectedFriendlyCounter[data];
	g_iProtectedFriendlyCounter[data] = 0;

	if (data == 0 || !IsClientConnected(data) || !IsClientInGame(data) || IsClientBot(data))
		return Plugin_Handled;

	int Score = ModifyScoreDifficulty(g_hCvar_HelpScore[HELP_PROTECT].IntValue * ProtectedFriendlies, 2, 3, TEAM_SURVIVORS);
	AddScore(data, Score);

	UpdateMapStat("points", Score);

	char UpdatePoints[32];
	char UserID[MAX_LINE_WIDTH];
	GetClientRankAuthString(data, UserID, sizeof(UserID));
	char UserName[MAX_LINE_WIDTH];
	GetClientName(data, UserName, sizeof(UserName));

	switch (g_iCurrentGamemodeID)
	{
		case GAMEMODE_VERSUS: Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		case GAMEMODE_REALISM: Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		case GAMEMODE_SURVIVAL: Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		case GAMEMODE_SCAVENGE: Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		case GAMEMODE_REALISMVERSUS: Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
		case GAMEMODE_OTHERMUTATIONS: Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	char query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_protect = award_protect + %i WHERE steamid = '%s'", g_sDbPrefix, UpdatePoints, UpdatePoints, Score, ProtectedFriendlies, UserID);
	SendSQLUpdate(query);

	if (Score > 0)
	{
		int Mode = g_hCvar_AnnounceMode.IntValue;

		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(data, "You have earned \x04%i \x01points for Protecting \x05%i friendlies\x01!", Score, ProtectedFriendlies);
		else if (Mode == 3)
			StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for Protecting \x05%i friendlies\x01!", UserName, Score, ProtectedFriendlies);
	}

	return Plugin_Handled;
}

// Team infected damage score
Action Timer_InfectedDamageCheck(Handle timer, int data)
{
	g_hTimerInfectedDamageCheck[data] = INVALID_HANDLE;

	if (data == 0 || IsClientBot(data))
		return Plugin_Handled;

	int InfectedDamage = g_hCvar_InfectedDamagePerPoint.IntValue;

	int Score = 0;
	int DamageCounter  = 0;

	if (InfectedDamage > 1)
	{
		if (g_iInfectedDamageCounter[data] < InfectedDamage)
			return Plugin_Handled;

		int TotalDamage = g_iInfectedDamageCounter[data];

		while (TotalDamage >= InfectedDamage)
		{
			DamageCounter += InfectedDamage;
			TotalDamage -= InfectedDamage;
			Score++;
		}
	}
	else
	{
		DamageCounter = g_iInfectedDamageCounter[data];
		Score = g_iInfectedDamageCounter[data];
	}

	Score = ModifyScoreDifficultyFloat(Score, 0.75, 0.5, TEAM_INFECTED);

	if (Score > 0)
	{
		g_iInfectedDamageCounter[data] -= DamageCounter;

		int	 Mode = g_hCvar_AnnounceMode.IntValue;

		char query[1024];
		char iID[MAX_LINE_WIDTH];

		GetClientRankAuthString(data, iID, sizeof(iID));

		switch (g_iCurrentGamemodeID)
		{
			case GAMEMODE_VERSUS: Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected + %i WHERE steamid = '%s'", g_sDbPrefix, Score, iID);
			case GAMEMODE_REALISMVERSUS: Format(query, sizeof(query), "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i WHERE steamid = '%s'", g_sDbPrefix, Score, iID);
			case GAMEMODE_SCAVENGE: Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i WHERE steamid = '%s'", g_sDbPrefix, Score, iID);
			default:
			{
				Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations + %i WHERE steamid = '%s'", g_sDbPrefix, Score, iID);
			}
		}

		SendSQLUpdate(query);
		UpdateMapStat("points_infected", Score);

		if (Mode == 1 || Mode == 2)
		{
			if (InfectedDamage > 1)
				StatsPrintToChat(data, "You have earned \x04%i \x01points for doing \x04%i \x01points of damage to the Survivors!", Score, DamageCounter);
			else
				StatsPrintToChat(data, "You have earned \x04%i \x01points for doing damage to the Survivors!", Score, DamageCounter);
		}
		else if (Mode == 3)
		{
			char Name[MAX_LINE_WIDTH];
			GetClientName(data, Name, sizeof(Name));
			if (InfectedDamage > 1)
				StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for doing \x04%i \x01points of damage to the Survivors!", Name, Score, DamageCounter);
			else
				StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for doing damage to the Survivors!", Name, Score, DamageCounter);
		}
	}

	return Plugin_Handled;
}

/*
// Display player rank.
Action timer_ShowPlayerJoined(Handle timer, int client)
{
	DoShowPlayerJoined(client);
}
*/

// Display common Infected scores to each player.
Action Timer_ShowTimerScore(Handle timer, Handle hndl)
{
	if (StatsDisabled())
		return Plugin_Handled;

	int	 Mode = g_hCvar_AnnounceMode.IntValue;
	char Name[MAX_LINE_WIDTH];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			// if (g_iCurrentPoints[i] > GetConVarInt(g_hCvar_MaxPoints))
			//     continue;

			g_iTimerPoints[i] = GetMedkitPointReductionScore(g_iTimerPoints[i]);

			if (g_iTimerPoints[i] > 0 && g_iTimerKills[i] > 0)
			{
				if (Mode == 1 || Mode == 2)
				{
					StatsPrintToChat(i, "You have earned \x04%i \x01points for killing \x05%i \x01Infected!", g_iTimerPoints[i], g_iTimerKills[i]);
				}
				else if (Mode == 3)
				{
					GetClientName(i, Name, sizeof(Name));
					StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for killing \x05%i \x01Infected!", Name, g_iTimerPoints[i], g_iTimerKills[i]);
				}
			}

			InterstitialPlayerUpdate(i);
		}

		g_iTimerPoints[i]	 = 0;
		g_iTimerKills[i]	 = 0;
		g_iTimerHeadshots[i] = 0;
	}

	return Plugin_Handled;
}

Action Timer_ClearDatabase(Handle timer)
{
	delete g_hClearDatabaseTimer;
	g_iClearDatabaseCaller = -1;

	return Plugin_Handled;
}

// Calculate Boomer vomit hits and check Boomer Perfect Blindness award
Action Timer_BoomerBlindnessCheck(Handle timer, int data)
{
	delete g_hTimerBoomerPerfectCheck[data];

	if (data > 0 && !IsClientBot(data) && IsClientInGame(data) && GetClientTeam(data) == TEAM_INFECTED && g_iBoomerHitCounter[data] > 0)
	{
		int HitCounter			  = g_iBoomerHitCounter[data];
		g_iBoomerHitCounter[data] = 0;
		int OriginalHitCounter	  = HitCounter;
		int BoomerPerfectHits	  = g_hCvar_BoomerPerfectHits.IntValue;
		int BoomerPerfectSuccess  = g_hCvar_BoomerPerfectSuccessScore.IntValue;
		int Score				  = 0;
		int AwardCounter		  = 0;

		// PrintToConsole(0, "timer_BoomerBlindnessCheck -> HitCounter = %i / BoomerPerfectHits = %i", HitCounter, BoomerPerfectHits);

		while (HitCounter >= BoomerPerfectHits)
		{
			HitCounter -= BoomerPerfectHits;
			Score += BoomerPerfectSuccess;
			AwardCounter++;
			// PrintToConsole(0, "timer_BoomerBlindnessCheck -> Score = %i", Score);
		}

		Score += GetBoomerPoints(HitCounter);
		// PrintToConsole(0, "timer_BoomerBlindnessCheck -> Total Score = %i", Score);
		Score = ModifyScoreDifficultyFloat(Score, 0.75, 0.5, TEAM_INFECTED);

		char query[1024];
		char iID[MAX_LINE_WIDTH];
		GetClientRankAuthString(data, iID, sizeof(iID));

		if (g_iCurrentGamemodeID == GAMEMODE_VERSUS) Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected + %i, award_perfect_blindness = award_perfect_blindness + %i, infected_boomer_blinded = infected_boomer_blinded + %i, infected_boomer_vomits = infected_boomer_vomits + %i WHERE steamid = '%s'", g_sDbPrefix, Score, AwardCounter, OriginalHitCounter, (g_iBoomerVomitUpdated[data] ? 0 : 1), iID);
		else if (g_iCurrentGamemodeID == GAMEMODE_REALISMVERSUS) Format(query, sizeof(query), "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i, award_perfect_blindness = award_perfect_blindness + %i, infected_boomer_blinded = infected_boomer_blinded + %i, infected_boomer_vomits = infected_boomer_vomits + %i WHERE steamid = '%s'", g_sDbPrefix, Score, AwardCounter, OriginalHitCounter, (g_iBoomerVomitUpdated[data] ? 0 : 1), iID);
		else if (g_iCurrentGamemodeID == GAMEMODE_SCAVENGE) Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i, award_perfect_blindness = award_perfect_blindness + %i, infected_boomer_blinded = infected_boomer_blinded + %i, infected_boomer_vomits = infected_boomer_vomits + %i WHERE steamid = '%s'", g_sDbPrefix, Score, AwardCounter, OriginalHitCounter, (g_iBoomerVomitUpdated[data] ? 0 : 1), iID);
		else Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations + %i, award_perfect_blindness = award_perfect_blindness + %i, infected_boomer_blinded = infected_boomer_blinded + %i, infected_boomer_vomits = infected_boomer_vomits + %i WHERE steamid = '%s'", g_sDbPrefix, Score, AwardCounter, OriginalHitCounter, (g_iBoomerVomitUpdated[data] ? 0 : 1), iID);
		SendSQLUpdate(query);

		if (!g_iBoomerVomitUpdated[data]) UpdateMapStat("infected_boomer_vomits", 1);
		UpdateMapStat("infected_boomer_blinded", HitCounter);

		g_iBoomerVomitUpdated[data] = false;
		if (Score > 0)
		{
			UpdateMapStat("points_infected", Score);
			int Mode = g_hCvar_AnnounceMode.IntValue;

			if (Mode == 1 || Mode == 2)
			{
				if (AwardCounter > 0) StatsPrintToChat(data, "You have earned \x04%i \x01points from \x05Perfect Blindness\x01!", Score);
				else StatsPrintToChat(data, "You have earned \x04%i \x01points for blinding \x05%i Survivors\x01!", Score, OriginalHitCounter);
			}
			else if (Mode == 3)
			{
				char Name[MAX_LINE_WIDTH];
				GetClientName(data, Name, sizeof(Name));
				if (AwardCounter > 0) StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points from \x05Perfect Blindness\x01!", Name, Score);
				else StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for blinding \x05%i Survivors\x01!", Name, Score, OriginalHitCounter);
			}
		}

		if (AwardCounter > 0 && g_bEnableSounds_Boomer_Vomit && g_hCvar_SoundsEnabled.BoolValue)
			EmitSoundToAll(g_sStatsSound_Boomer_Vomit);
	}

	return Plugin_Handled;
}

// Perform player init.
Action Timer_InitPlayers(Handle timer)
{
	if (!db)
		return Plugin_Handled;

	char query[64];
	Format(query, sizeof(query), "SELECT COUNT(*) FROM %splayers", g_sDbPrefix);
	SQL_TQuery(db, GetRankTotal, query);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			CheckPlayerDB(i);
			QueryClientPoints(i);
			g_iTimerPoints[i] = 0;
			g_iTimerKills[i]  = 0;
		}
	}

	return Plugin_Handled;
}

// End blinded state.
Action Timer_EndBoomerBlinded(Handle timer, int data)
{
	g_iPlayerBlinded[data][0] = 0;
	g_iPlayerBlinded[data][1] = 0;

	return Plugin_Handled;
}

// End blinded state.
Action Timer_EndSmokerParalyzed(Handle timer, int data)
{
	g_iPlayerParalyzed[data][0] = 0;
	g_iPlayerParalyzed[data][1] = 0;

	return Plugin_Handled;
}

// End lunging state.
Action Timer_EndHunterLunged(Handle timer, int data)
{
	g_iPlayerLunged[data][0] = 0;
	g_iPlayerLunged[data][1] = 0;

	return Plugin_Handled;
}

// End plummel state.
Action Timer_EndChargerPlummel(Handle timer, int data)
{
	g_iChargerPlummelVictim[g_iPlayerPummeled[data][1]] = 0;
	g_iPlayerPummeled[data][0] = 0;
	g_iPlayerPummeled[data][1] = 0;

	return Plugin_Handled;
}

// End charge impact counter state.
Action Timer_EndCharge(Handle timer, int data)
{
	g_hChargerImpactCounterTimer[data] = INVALID_HANDLE;
	int Counter	= g_iChargerImpactCounter[data];
	g_iChargerImpactCounter[data] = 0;

	int	 Score = 0;
	char ScoreSet[256] = "";

	if (Counter >= g_hCvar_ChargerRamHitsPerPoints.IntValue)
	{
		Score = ModifyScoreDifficultyFloat(g_hCvar_ChargerRamSuccessScore.IntValue, 0.9, 0.8, TEAM_INFECTED);
		if (g_iCurrentGamemodeID == GAMEMODE_VERSUS) Format(ScoreSet, sizeof(ScoreSet), "points_infected = points_infected + %i", Score);
		else if (g_iCurrentGamemodeID == GAMEMODE_REALISMVERSUS) Format(ScoreSet, sizeof(ScoreSet), "points_realism_infected = points_realism_infected + %i", Score);
		else if (g_iCurrentGamemodeID == GAMEMODE_SCAVENGE) Format(ScoreSet, sizeof(ScoreSet), "points_scavenge_infected = points_scavenge_infected + %i", Score);
		else Format(ScoreSet, sizeof(ScoreSet), "points_mutations = points_mutations + %i", Score);

		StrCat(ScoreSet, sizeof(ScoreSet), ", award_scatteringram = award_scatteringram + 1, ");

		if (g_bEnableSounds_Charger_Ram && g_hCvar_SoundsEnabled.BoolValue)
			EmitSoundToAll(SOUND_CHARGER_RAM);
	}
	// UPDATE players SET points_infected = points_infected + 40, award_scatteringram = acharger_impacts = charger_impacts + 4 WHERE steamid = 'STEAM_1:1:12345678'

	char AttackerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(data, AttackerID, sizeof(AttackerID));

	char query[512];
	Format(query, sizeof(query), "UPDATE %splayers SET %scharger_impacts = charger_impacts + %i WHERE steamid = '%s'", g_sDbPrefix, ScoreSet, Counter, AttackerID);
	SendSQLUpdate(query);

	if (Score > 0)
		UpdateMapStat("points_infected", Score);

	if (Counter > 0)
		UpdateMapStat("charger_impacts", Counter);

	int Mode = 0;
	if (Score > 0)
		Mode = g_hCvar_AnnounceMode.IntValue;

	if ((Mode == 1 || Mode == 2) && IsClientConnected(data) && IsClientInGame(data))
		StatsPrintToChat(data, "You have earned \x04%i \x01points for charging a \x05Scattering Ram \x01on \x03%i \x01victims!", Score, Counter);
	else if (Mode == 3)
	{
		char AttackerName[MAX_LINE_WIDTH];
		GetClientName(data, AttackerName, sizeof(AttackerName));
		StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for charging a \x05Scattering Ram \x01on \x03%i \x01victims!", AttackerName, Score, Counter);
	}

	return Plugin_Handled;
}

// End carried state.
Action Timer_EndChargerCarry(Handle timer, int data)
{
	g_iChargerCarryVictim[g_iPlayerCarried[data][1]] = 0;
	g_iPlayerCarried[data][0] = 0;
	g_iPlayerCarried[data][1] = 0;

	return Plugin_Handled;
}

// End jockey ride state.
Action Timer_EndJockeyRide(Handle timer, int data)
{
	g_iJockeyVictim[g_iPlayerCarried[data][1]] = 0;
	g_iPlayerJockied[data][0] = 0;
	g_iPlayerJockied[data][1] = 0;

	return Plugin_Handled;
}

// End friendly fire damage counter.
Action Timer_FriendlyFireDamageEnd(Handle timer, DataPack dp)
{
	dp.Reset();

	int HumanDamage = dp.ReadCell();
	int BotDamage = dp.ReadCell();
	int Attacker = dp.ReadCell();

	// This may fail! What happens when a player skips and another joins with the same Client ID (is this even possible in such short time?)
	g_hFriendlyFireTimer[Attacker][0] = INVALID_HANDLE;

	char AttackerID[MAX_LINE_WIDTH];
	dp.ReadString(AttackerID, sizeof(AttackerID));
	char AttackerName[MAX_LINE_WIDTH];
	dp.ReadString(AttackerName, sizeof(AttackerName));

	// The damage is read and turned into lost points...
	dp.Reset();
	dp.WriteCell(0);	// Human damage
	dp.WriteCell(0);	// Bot damage

	if (HumanDamage <= 0 && BotDamage <= 0)
		return Plugin_Handled;

	int Score = 0;
	if (g_hCvar_EnableNegativeScore.BoolValue)
	{
		if (HumanDamage > 0)
			Score += ModifyScoreDifficultyNR(RoundToNearest(g_hCvar_FriendlyFireMultiplier.FloatValue * HumanDamage), 2, 4, TEAM_SURVIVORS);

		if (BotDamage > 0)
		{
			float BotScoreMultiplier = g_hCvar_BotScoreMultiplier.FloatValue;
			if (BotScoreMultiplier > 0.0)
				Score += ModifyScoreDifficultyNR(RoundToNearest(g_hCvar_FriendlyFireMultiplier.FloatValue * BotDamage), 2, 4, TEAM_SURVIVORS);
		}
	}

	char UpdatePoints[32];
	switch (g_iCurrentGamemodeID)
	{
		case GAMEMODE_VERSUS: Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		case GAMEMODE_REALISM: Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		case GAMEMODE_SURVIVAL: Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		case GAMEMODE_SCAVENGE: Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		case GAMEMODE_REALISMVERSUS: Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
		case GAMEMODE_OTHERMUTATIONS: Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	char query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s - %i, award_friendlyfire = award_friendlyfire + 1 WHERE steamid = '%s'", g_sDbPrefix, UpdatePoints, UpdatePoints, Score, AttackerID);
	SendSQLUpdate(query);

	int Mode = 0;
	if (Score > 0)
		Mode = g_hCvar_AnnounceMode.IntValue;

	if ((Mode == 1 || Mode == 2) && IsClientConnected(Attacker) && IsClientInGame(Attacker))
		StatsPrintToChat(Attacker, "You have \x03LOST \x04%i \x01points for inflicting \x03Friendly Fire Damage \x05(%i HP)\x01!", Score, HumanDamage + BotDamage);
	else if (Mode == 3)
		StatsPrintToChatAll("\x05%s \x01has \x03LOST \x04%i \x01points for inflicting \x03Friendly Fire Damage \x05(%i HP)\x01!", AttackerName, Score, HumanDamage + BotDamage);

	return Plugin_Handled;
}

// Start team shuffle.
Action Timer_ShuffleTeams(Handle timer)
{
	if (CheckHumans())
		return Plugin_Handled;

	char query[1024];
	Format(query, sizeof(query), "SELECT steamid FROM %splayers WHERE ", g_sDbPrefix);

	char SteamID[MAX_LINE_WIDTH], where[512];
	int	 counter = 0, team;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientBot(i) || !IsClientConnected(i) || !IsClientInGame(i))
			continue;

		team = GetClientTeam(i);

		if (team != TEAM_SURVIVORS && team != TEAM_INFECTED)
			continue;

		if (counter++ > 0)
			StrCat(query, sizeof(query), "OR ");

		GetClientRankAuthString(i, SteamID, sizeof(SteamID));
		Format(where, sizeof(where), "steamid = '%s' ", SteamID);
		StrCat(query, sizeof(query), where);
	}

	if (counter <= 1)
	{
		StatsPrintToChatAllPreFormatted2(true, "Team shuffle by player PPM failed because there was \x03not enough players\x01!");
		return Plugin_Handled;
	}

	Format(where, sizeof(where), "ORDER BY (%s) / (%s) DESC", DB_PLAYERS_TOTALPOINTS, DB_PLAYERS_TOTALPLAYTIME);
	StrCat(query, sizeof(query), where);

	SQL_TQuery(db, ExecuteTeamShuffle, query);

	return Plugin_Handled;
}

// End of RANKVOTE.
Action Timer_RankVote(Handle timer)
{
	delete g_hRankVoteTimer;

	if (!CheckHumans())
	{
		int humans = 0, votes = 0, yesvotes = 0, novotes = 0, WinningVoteCount = 0;
		CheckRankVotes(humans, votes, yesvotes, novotes, WinningVoteCount);
		StatsPrintToChatAll2(true, "Vote to shuffle teams by player PPM \x03%s \x01with \x04%i (yes) against %i (no)\x01.", (yesvotes > novotes ? "PASSED" : "DID NOT PASS"), yesvotes, novotes);

		if (yesvotes > novotes)
			CreateTimer(3.0, Timer_ShuffleTeams);
	}

	return Plugin_Handled;
}

// End friendly fire cooldown.
Action Timer_FriendlyFireCooldownEnd(Handle timer, int data)
{
	g_bFriendlyFireCooldown[g_iFriendlyFirePrm[data][0]][g_iFriendlyFirePrm[data][1]] = false;
	delete g_hFriendlyFireTimer[g_iFriendlyFirePrm[data][0]][g_iFriendlyFirePrm[data][1]];

	return Plugin_Handled;
}

// End friendly fire cooldown.
Action Timer_MeleeKill(Handle timer, any data)
{
	delete g_hMeleeKillTimer[data];
	int Counter = g_iMeleeKillCounter[data];
	g_iMeleeKillCounter[data] = 0;

	if (Counter <= 0 || IsClientBot(data) || !IsClientConnected(data) || !IsClientInGame(data) || GetClientTeam(data) != TEAM_SURVIVORS)
		return Plugin_Handled;

	char query[512], clientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(data, clientID, sizeof(clientID));
	Format(query, sizeof(query), "UPDATE %splayers SET melee_kills = melee_kills + %i WHERE steamid = '%s'", g_sDbPrefix, Counter, clientID);
	SendSQLUpdate(query);

	return Plugin_Handled;
}

// Perform minutely updates of player database.
// Reports Disabled message if in Versus, Easy mode, not enough Human players, and if cheats are active.
Action Timer_UpdatePlayers(Handle timer, Handle hndl)
{
	if (CheckHumans())
	{
		if (g_hCvar_DisabledMessages.BoolValue)
			StatsPrintToChatAllPreFormatted("Left 4 Dead Stats are \x04DISABLED\x01, not enough Human players!");

		return Plugin_Handled;
	}

	if (StatsDisabled())
		return Plugin_Handled;

	UpdateMapStat("playtime", 1);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			CheckPlayerDB(i);
	}

	return Plugin_Handled;
}

// Display rank change.
Action Timer_ShowRankChange(Handle timer, int client)
{
	DoShowRankChange(client);
	return Plugin_Handled;
}
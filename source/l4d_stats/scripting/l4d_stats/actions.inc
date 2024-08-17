#if defined _l4d_stats_actions_included
	#endinput
#endif
#define _l4d_stats_actions_included

void DoInfectedFinalChecks(int Client, int ClientInfType = -1)
{
	if (Client == 0)
		return;

	EngineVersion ServerVersion = GetEngineVersion();

	if (ClientInfType < 0)
		ClientInfType = g_iClientInfectedType[Client];

	if (ClientInfType == INF_ID_SMOKER)
	{
		int Damage = g_iSmokerDamageCounter[Client];
		g_iSmokerDamageCounter[Client] = 0;
		UpdateSmokerDamage(Client, Damage);
	}
	else if (ServerVersion != Engine_Left4Dead && ClientInfType == INF_ID_SPITTER_L4D2)
	{
		int Damage = g_iSpitterDamageCounter[Client];
		g_iSpitterDamageCounter[Client] = 0;
		UpdateSpitterDamage(Client, Damage);
	}
	else if (ServerVersion != Engine_Left4Dead && ClientInfType == INF_ID_JOCKEY_L4D2)
	{
		int Damage = g_iJockeyDamageCounter[Client];
		g_iJockeyDamageCounter[Client] = 0;
		UpdateJockeyDamage(Client, Damage);
		UpdateJockeyRideLength(Client);
	}
	else if (ServerVersion != Engine_Left4Dead && ClientInfType == INF_ID_CHARGER_L4D2)
	{
		int Damage = g_iChargerDamageCounter[Client];
		g_iChargerDamageCounter[Client] = 0;
		UpdateChargerDamage(Client, Damage);
	}
}

void SetClientInfectedType(int Client)
{
	// Bot check is done by the caller

	if (Client <= 0)
		return;

	int ClientTeam = GetClientTeam(Client);

	if (ClientTeam == TEAM_INFECTED)
	{
		g_iClientInfectedType[Client] = GetInfType(Client);

		if (g_iClientInfectedType[Client] != INF_ID_SMOKER
			&& g_iClientInfectedType[Client] != INF_ID_BOOMER
			&& g_iClientInfectedType[Client] != INF_ID_HUNTER
			&& g_iClientInfectedType[Client] != INF_ID_SPITTER_L4D2
			&& g_iClientInfectedType[Client] != INF_ID_JOCKEY_L4D2
			&& g_iClientInfectedType[Client] != INF_ID_CHARGER_L4D2
			&& g_iClientInfectedType[Client] != INF_ID_TANK_L4D2)
			return;

		char ClientID[MAX_LINE_WIDTH];
		GetClientRankAuthString(Client, ClientID, sizeof(ClientID));

		char query[1024];
		Format(query, sizeof(query), "UPDATE %splayers SET infected_spawn_%i = infected_spawn_%i + 1 WHERE steamid = '%s'", g_sDbPrefix, g_iClientInfectedType[Client], g_iClientInfectedType[Client], ClientID);
		SendSQLUpdate(query);

		char Spawn[32];
		Format(Spawn, sizeof(Spawn), "infected_spawn_%i", g_iClientInfectedType[Client]);
		UpdateMapStat(Spawn, 1);
	}
	else
		g_iClientInfectedType[Client] = 0;
}

int TankDamage(int Client, int Damage)
{
	if (Client <= 0 || Damage <= 0)
		return 0;

	// Update only the Tank inflicted damage related statistics
	UpdateTankDamage(Client, Damage);

	// If value is negative then client has already received the Bulldozer Award
	if (g_iTankDamageTotalCounter[Client] >= 0)
	{
		g_iTankDamageTotalCounter[Client] += Damage;
		int TankDamageTotal = g_hCvar_TankScoreDamageTotal.IntValue;

		if (g_iTankDamageTotalCounter[Client] >= TankDamageTotal)
		{
			g_iTankDamageTotalCounter[Client] = -1;	   // Just one award per Tank
			int Score = ModifyScoreDifficultyFloat(g_hCvar_TankScoreDamageTotalSuccessScore.IntValue, 0.75, 0.5, TEAM_INFECTED);

			if (Score > 0)
			{
				char ClientID[MAX_LINE_WIDTH];
				GetClientRankAuthString(Client, ClientID, sizeof(ClientID));

				char query[1024];

				if (g_iCurrentGamemodeID == GAMEMODE_VERSUS)
					Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected + %i, award_bulldozer = award_bulldozer + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, ClientID);
				else if (g_iCurrentGamemodeID == GAMEMODE_REALISMVERSUS)
					Format(query, sizeof(query), "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i, award_bulldozer = award_bulldozer + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, ClientID);
				else if (g_iCurrentGamemodeID == GAMEMODE_SCAVENGE)
					Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i, award_bulldozer = award_bulldozer + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, ClientID);
				else
					Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations + %i, award_bulldozer = award_bulldozer + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, ClientID);

				SendSQLUpdate(query);
				UpdateMapStat("points_infected", Score);

				int Mode = g_hCvar_AnnounceMode.IntValue;

				if (Mode == 1 || Mode == 2)
					StatsPrintToChat(Client, "You have earned \x04%i \x01points for Bulldozing the Survivors worth %i points of damage!", Score, TankDamageTotal);
				else if (Mode == 3)
				{
					char Name[MAX_LINE_WIDTH];
					GetClientName(Client, Name, sizeof(Name));
					StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for Bulldozing the Survivors worth %i points of damage!", Name, Score, TankDamageTotal);
				}

				if (g_bEnableSounds_Tank_Bulldozer && g_hCvar_SoundsEnabled.BoolValue)
					EmitSoundToAll(g_sStatsSound_Tank_Bulldozer);
			}
		}
	}

	int DamageLimit = g_hCvar_TankScoreDamageCap.IntValue;

	if (g_iTankDamageCounter[Client] >= DamageLimit)
		return 0;

	g_iTankDamageCounter[Client] += Damage;

	if (g_iTankDamageCounter[Client] > DamageLimit)
		Damage -= g_iTankDamageCounter[Client] - DamageLimit;

	return Damage;
}

void UpdateFriendlyFire(int Attacker, int Victim)
{
	char AttackerName[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerName, sizeof(AttackerName));
	char AttackerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Attacker, AttackerID, sizeof(AttackerID));

	char VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));

	int Score = 0;
	if (g_hCvar_EnableNegativeScore.BoolValue)
	{
		if (!IsClientBot(Victim))
			Score = ModifyScoreDifficultyNR(g_hCvar_ActionScore[ACT_FF].IntValue, 2, 4, TEAM_SURVIVORS);
		else
		{
			float BotScoreMultiplier = g_hCvar_BotScoreMultiplier.FloatValue;

			if (BotScoreMultiplier > 0.0)
				Score = RoundToNearest(ModifyScoreDifficultyNR(g_hCvar_ActionScore[ACT_FF].IntValue, 2, 4, TEAM_SURVIVORS) * BotScoreMultiplier);
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

	if (Mode == 1 || Mode == 2)
		StatsPrintToChat(Attacker, "You have \x03LOST \x04%i \x01points for \x03Friendly Firing \x05%s\x01!", Score, VictimName);
	else if (Mode == 3)
		StatsPrintToChatAll("\x05%s \x01has \x03LOST \x04%i \x01points for \x03Friendly Firing \x05%s\x01!", AttackerName, Score, VictimName);
}

void UpdateHunterDamage(int Client, int Damage)
{
	if (Damage <= 0)
		return;

	char ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, ClientID, sizeof(ClientID));

	char query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_hunter_pounce_dmg = infected_hunter_pounce_dmg + %i, infected_hunter_pounce_counter = infected_hunter_pounce_counter + 1 WHERE steamid = '%s'", g_sDbPrefix, Damage, ClientID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_hunter_pounce_counter", 1);
	UpdateMapStat("infected_hunter_pounce_damage", Damage);
}

void UpdateTankDamage(int Client, int Damage)
{
	if (Damage <= 0)
		return;

	char ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, ClientID, sizeof(ClientID));

	char query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_tank_damage = infected_tank_damage + %i WHERE steamid = '%s'", g_sDbPrefix, Damage, ClientID);
	SendSQLUpdate(query);
	UpdateMapStat("infected_tank_damage", Damage);
}
/*
UpdatePlayerScore(Client, Score)
{
	if (Score == 0)
		return;

	switch (g_iCurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			UpdatePlayerScoreVersus(Client, GetClientTeam(Client), Score);
		}
		case GAMEMODE_REALISM:
		{
			UpdatePlayerScoreRealismVersus(Client, GetClientTeam(Client), Score);
		}
		case GAMEMODE_SURVIVAL:
		{
			UpdatePlayerScore2(Client, Score, "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			UpdatePlayerScoreScavenge(Client, GetClientTeam(Client), Score);
		}
		case GAMEMODE_OTHERMUTATIONS:
		{
			UpdatePlayerScore2(Client, Score, "points_mutations");
		}
		default:
		{
			UpdatePlayerScore2(Client, Score, "points");
		}
	}
}

UpdatePlayerScoreVersus(Client, ClientTeam, Score)
{
	if (Score == 0)
		return;

	if (ClientTeam == TEAM_SURVIVORS)
		UpdatePlayerScore2(Client, Score, "points_survivors");
	else if (ClientTeam == TEAM_INFECTED)
		UpdatePlayerScore2(Client, Score, "points_infected");
}

UpdatePlayerScoreRealismVersus(Client, ClientTeam, Score)
{
	if (Score == 0)
		return;

	if (ClientTeam == TEAM_SURVIVORS)
		UpdatePlayerScore2(Client, Score, "points_realism_survivors");
	else if (ClientTeam == TEAM_INFECTED)
		UpdatePlayerScore2(Client, Score, "points_realism_infected");
}

UpdatePlayerScoreScavenge(Client, ClientTeam, Score)
{
	if (Score == 0)
		return;

	if (ClientTeam == TEAM_SURVIVORS)
		UpdatePlayerScore2(Client, Score, "points_scavenge_survivors");
	else if (ClientTeam == TEAM_INFECTED)
		UpdatePlayerScore2(Client, Score, "points_scavenge_infected");
}
*/
void UpdatePlayerScore2(int Client, int Score, const char[] Points)
{
	if (Score == 0)
		return;

	char ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, ClientID, sizeof(ClientID));

	char query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i WHERE steamid = '%s'", g_sDbPrefix, Points, Points, Score, ClientID);
	SendSQLUpdate(query);

	if (Score > 0)
		UpdateMapStat("points", Score);

	AddScore(Client, Score);
}

void UpdateTankSniper(int Client)
{
	if (Client <= 0)
		return;

	char ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, ClientID, sizeof(ClientID));
	UpdateTankSniperSteamID(ClientID);
}

void UpdateTankSniperSteamID(const char[] ClientID)
{
	char query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_tanksniper = infected_tanksniper + 1 WHERE steamid = '%s'", g_sDbPrefix, ClientID);
	SendSQLUpdate(query);
	UpdateMapStat("infected_tanksniper", 1);
}

// Survivor died.

void SurvivorDied(int Attacker, int Victim, int AttackerInfType = -1, int Mode = -1)
{
	if (!Attacker || !Victim || StatsGetClientTeam(Attacker) != TEAM_INFECTED || StatsGetClientTeam(Victim) != TEAM_SURVIVORS)
		return;

	char AttackerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Attacker, AttackerID, sizeof(AttackerID));

	char VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));
	SurvivorDiedNamed(Attacker, Victim, VictimName, AttackerID, AttackerInfType, Mode);
}

// An Infected player killed a Survivor.

void SurvivorDiedNamed(int Attacker, int Victim, const char[] VictimName, const char[] AttackerID, int AttackerInfType = -1, int Mode = -1)
{
	if (!Attacker || !Victim || StatsGetClientTeam(Attacker) != TEAM_INFECTED || StatsGetClientTeam(Victim) != TEAM_SURVIVORS)
		return;

	// LogError("SurvivorDiedNamed - VictimName = %s", VictimName);

	if (AttackerInfType < 0)
	{
		if (g_iClientInfectedType[Attacker] == 0)
			SetClientInfectedType(Attacker);

		AttackerInfType = g_iClientInfectedType[Attacker];
	}

	EngineVersion ServerVersion = GetEngineVersion();
	if (ServerVersion == Engine_Left4Dead)
	{
		if (AttackerInfType != INF_ID_SMOKER
			&& AttackerInfType != INF_ID_BOOMER
			&& AttackerInfType != INF_ID_HUNTER
			&& AttackerInfType != INF_ID_TANK_L4D2)	   // SetClientInfectedType sets tank id to L4D2
			return;
	}
	else
	{
		if (AttackerInfType != INF_ID_SMOKER
			&& AttackerInfType != INF_ID_BOOMER
			&& AttackerInfType != INF_ID_HUNTER
			&& AttackerInfType != INF_ID_SPITTER_L4D2
			&& AttackerInfType != INF_ID_JOCKEY_L4D2
			&& AttackerInfType != INF_ID_CHARGER_L4D2
			&& AttackerInfType != INF_ID_TANK_L4D2)
			return;
	}

	int	 Score = GetSurvivorKillScore();

	int	 len   = 0;
	char query[1024];

	if (g_iCurrentGamemodeID == GAMEMODE_VERSUS)
		len += Format(query[len], sizeof(query) - len, "UPDATE %splayers SET points_infected = points_infected + %i, versus_kills_survivors = versus_kills_survivors + 1 ", g_sDbPrefix, Score);
	else if (g_iCurrentGamemodeID == GAMEMODE_REALISMVERSUS)
		len += Format(query[len], sizeof(query) - len, "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i, realism_kills_survivors = realism_kills_survivors + 1 ", g_sDbPrefix, Score);
	else if (g_iCurrentGamemodeID == GAMEMODE_SCAVENGE)
		len += Format(query[len], sizeof(query) - len, "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i, scavenge_kills_survivors = scavenge_kills_survivors + 1 ", g_sDbPrefix, Score);
	else
		len += Format(query[len], sizeof(query) - len, "UPDATE %splayers SET points_mutations = points_mutations + %i, mutations_kills_survivors = mutations_kills_survivors + 1 ", g_sDbPrefix, Score);
	len += Format(query[len], sizeof(query) - len, "WHERE steamid = '%s'", AttackerID);
	SendSQLUpdate(query);

	if (Mode < 0)
		Mode = g_hCvar_AnnounceMode.IntValue;

	if (Mode)
	{
		if (Mode > 2)
		{
			char AttackerName[MAX_LINE_WIDTH];
			GetClientName(Attacker, AttackerName, sizeof(AttackerName));
			StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for killing \x05%s\x01!", AttackerName, Score, VictimName);
		}
		else
			StatsPrintToChat(Attacker, "You have earned \x04%i \x01points for killing \x05%s\x01!", Score, VictimName);
	}

	UpdateMapStat("survivor_kills", 1);
	UpdateMapStat("points_infected", Score);
	AddScore(Attacker, Score);
}

// Survivor got hurt.
void SurvivorHurt(int Attacker, int Victim, int Damage, int AttackerInfType = -1, Event event = null)
{
	if (!Attacker || !Victim || Damage <= 0 || Attacker == Victim)
		return;

	if (AttackerInfType < 0)
	{
		int AttackerTeam = GetClientTeam(Attacker);

		if (Attacker > 0 && AttackerTeam == TEAM_INFECTED)
			AttackerInfType = GetInfType(Attacker);
	}

	if (AttackerInfType != INF_ID_SMOKER
		&& AttackerInfType != INF_ID_BOOMER
		&& AttackerInfType != INF_ID_HUNTER
		&& AttackerInfType != INF_ID_SPITTER_L4D2
		&& AttackerInfType != INF_ID_JOCKEY_L4D2
		&& AttackerInfType != INF_ID_CHARGER_L4D2
		&& AttackerInfType != INF_ID_TANK_L4D2)
		return;

	if (g_hTimerInfectedDamageCheck[Attacker] != null)
		delete g_hTimerInfectedDamageCheck[Attacker];

	int VictimHealth = GetClientHealth(Victim);

	if (VictimHealth < 0)
		Damage += VictimHealth;

	if (Damage <= 0)
		return;

	if (AttackerInfType == INF_ID_TANK_L4D2 && event != null)
	{
		g_iInfectedDamageCounter[Attacker] += TankDamage(Attacker, Damage);

		char Weapon[16];
		event.GetString("weapon", Weapon, sizeof(Weapon));

		int RockHit = g_hCvar_TankScoreThrowRockSuccessScore.IntValue;

		if (RockHit > 0 && strcmp(Weapon, "tank_rock", false) == 0)
		{
			if (g_iCurrentGamemodeID == GAMEMODE_VERSUS) UpdatePlayerScore2(Attacker, RockHit, "points_infected");
			else if (g_iCurrentGamemodeID == GAMEMODE_REALISMVERSUS) UpdatePlayerScore2(Attacker, RockHit, "points_realism_infected");
			else if (g_iCurrentGamemodeID == GAMEMODE_SCAVENGE) UpdatePlayerScore2(Attacker, RockHit, "points_scavenge_infected");
			else UpdatePlayerScore2(Attacker, RockHit, "points_mutations");
			UpdateTankSniper(Attacker);

			char VictimName[MAX_LINE_WIDTH];

			if (Victim > 0) GetClientName(Victim, VictimName, sizeof(VictimName));
			else Format(VictimName, sizeof(VictimName), "UNKNOWN");

			int Mode = g_hCvar_AnnounceMode.IntValue;

			if (Mode == 1 || Mode == 2)
				StatsPrintToChat(Attacker, "You have earned \x04%i \x01points for throwing a rock at \x05%s\x01!", RockHit, VictimName);
			else if (Mode == 3)
			{
				char AttackerName[MAX_LINE_WIDTH];
				GetClientName(Attacker, AttackerName, sizeof(AttackerName));
				StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for throwing a rock at \x05%s\x01!", AttackerName, RockHit, VictimName);
			}
		}
	}
	else
		g_iInfectedDamageCounter[Attacker] += Damage;

	if (AttackerInfType == INF_ID_SMOKER)
		g_iSmokerDamageCounter[Attacker] += Damage;
	else if (AttackerInfType == INF_ID_SPITTER_L4D2)
		g_iSpitterDamageCounter[Attacker] += Damage;
	else if (AttackerInfType == INF_ID_JOCKEY_L4D2)
		g_iJockeyDamageCounter[Attacker] += Damage;
	else if (AttackerInfType == INF_ID_CHARGER_L4D2)
		g_iChargerDamageCounter[Attacker] += Damage;

	g_hTimerInfectedDamageCheck[Attacker] = CreateTimer(5.0, Timer_InfectedDamageCheck, Attacker);
}

// Survivor was hurt by normal infected while being blinded and/or paralyzed.
void SurvivorHurtExternal(Event event, int Victim)
{
	if (!event || !Victim)
		return;

	int Damage = event.GetInt("dmg_health");

	int VictimHealth = GetClientHealth(Victim);

	if (VictimHealth < 0)
		Damage += VictimHealth;

	if (Damage <= 0)
		return;

	int Attacker;

	if (g_iPlayerBlinded[Victim][0] && g_iPlayerBlinded[Victim][1])
	{
		Attacker = g_iPlayerBlinded[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}

	if (g_iPlayerParalyzed[Victim][0] && g_iPlayerParalyzed[Victim][1])
	{
		Attacker = g_iPlayerParalyzed[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}
	else if (g_iPlayerLunged[Victim][0] && g_iPlayerLunged[Victim][1])
	{
		Attacker = g_iPlayerLunged[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}
	else if (g_iPlayerPummeled[Victim][0] && g_iPlayerPummeled[Victim][1])
	{
		Attacker = g_iPlayerPummeled[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}
	else if (g_iPlayerCarried[Victim][0] && g_iPlayerCarried[Victim][1])
	{
		Attacker = g_iPlayerCarried[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}
	else if (g_iPlayerJockied[Victim][0] && g_iPlayerJockied[Victim][1])
	{
		Attacker = g_iPlayerJockied[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorHurt(Attacker, Victim, Damage);
	}
}

void PlayerDeathExternal(int Victim)
{
	if (!Victim || StatsGetClientTeam(Victim) != TEAM_SURVIVORS)
		return;

	CheckSurvivorsAllDown();

	int Attacker = 0;

	if (g_iPlayerBlinded[Victim][0] && g_iPlayerBlinded[Victim][1])
	{
		Attacker = g_iPlayerBlinded[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_BOOMER);
	}

	if (g_iPlayerParalyzed[Victim][0] && g_iPlayerParalyzed[Victim][1])
	{
		Attacker = g_iPlayerParalyzed[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_SMOKER);
	}
	else if (g_iPlayerLunged[Victim][0] && g_iPlayerLunged[Victim][1])
	{
		Attacker = g_iPlayerLunged[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_HUNTER);
	}
	else if (g_iPlayerJockied[Victim][0] && g_iPlayerJockied[Victim][1])
	{
		Attacker = g_iPlayerJockied[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_HUNTER);
	}
	else if (g_iPlayerCarried[Victim][0] && g_iPlayerCarried[Victim][1])
	{
		Attacker = g_iPlayerCarried[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_HUNTER);
	}
	else if (g_iPlayerPummeled[Victim][0] && g_iPlayerPummeled[Victim][1])
	{
		Attacker = g_iPlayerPummeled[Victim][1];

		if (Attacker && !IsClientBot(Attacker) && IsClientInGame(Attacker))
			SurvivorDied(Attacker, Victim, INF_ID_HUNTER);
	}
}

void PlayerIncapExternal(int Victim)
{
	if (!Victim || StatsGetClientTeam(Victim) != TEAM_SURVIVORS)
		return;

	CheckSurvivorsAllDown();

	int Attacker = 0;

	if (g_iPlayerBlinded[Victim][0] && g_iPlayerBlinded[Victim][1])
	{
		Attacker = g_iPlayerBlinded[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}

	if (g_iPlayerParalyzed[Victim][0] && g_iPlayerParalyzed[Victim][1])
	{
		Attacker = g_iPlayerParalyzed[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}
	else if (g_iPlayerLunged[Victim][0] && g_iPlayerLunged[Victim][1])
	{
		Attacker = g_iPlayerLunged[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}
	else if (g_iPlayerPummeled[Victim][0] && g_iPlayerPummeled[Victim][1])
	{
		Attacker = g_iPlayerPummeled[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}
	else if (g_iPlayerCarried[Victim][0] && g_iPlayerCarried[Victim][1])
	{
		Attacker = g_iPlayerCarried[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}
	else if (g_iPlayerJockied[Victim][0] && g_iPlayerJockied[Victim][1])
	{
		Attacker = g_iPlayerJockied[Victim][1];
		SurvivorIncappedByInfected(Attacker, Victim);
	}
}

void SurvivorIncappedByInfected(int Attacker, int Victim, int Mode = -1)
{
	if (Attacker > 0 && !IsClientConnected(Attacker) || Attacker > 0 && IsClientBot(Attacker))
		return;

	char AttackerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Attacker, AttackerID, sizeof(AttackerID));
	char AttackerName[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerName, sizeof(AttackerName));

	char VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));

	int Score = ModifyScoreDifficultyFloat(g_hCvar_SurvivorIncapScore.IntValue, 0.75, 0.5, TEAM_INFECTED);

	if (Score <= 0)
		return;

	char query[512];

	if (g_iCurrentGamemodeID == GAMEMODE_VERSUS) Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected + %i, award_survivor_down = award_survivor_down + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, AttackerID);
	else if (g_iCurrentGamemodeID == GAMEMODE_REALISMVERSUS) Format(query, sizeof(query), "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i, award_survivor_down = award_survivor_down + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, AttackerID);
	else if (g_iCurrentGamemodeID == GAMEMODE_SCAVENGE) Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i, award_survivor_down = award_survivor_down + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, AttackerID);
	else Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations + %i, award_survivor_down = award_survivor_down + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, AttackerID);
	SendSQLUpdate(query);
	UpdateMapStat("points_infected", Score);

	if (Mode < 0)
		Mode = g_hCvar_AnnounceMode.IntValue;

	if (Mode == 1 || Mode == 2)
		StatsPrintToChat(Attacker, "You have earned \x04%i \x01points for Incapacitating \x05%s\x01!", Score, VictimName);
	else if (Mode == 3)
		StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for Incapacitating \x05%s\x01!", AttackerName, Score, VictimName);
}

void AnnounceMedkitPenalty(int Mode = -1)
{
	float ReductionFactor = GetMedkitPointReductionFactor();

	if (ReductionFactor == 1.0)
		return;

	if (Mode < 0)
		Mode = g_hCvar_AnnounceMode.IntValue;

	if (Mode)
	{
		EngineVersion ServerVersion = GetEngineVersion();
		StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03ALL SURVIVORS \x01now earns only \x04%i percent \x01of their normal points after using their \x05%i%s Medkit%s\x01!", RoundToNearest(ReductionFactor * 100), g_iMedkitsUsedCounter, (g_iMedkitsUsedCounter == 1 ? "st" : (g_iMedkitsUsedCounter == 2 ? "nd" : (g_iMedkitsUsedCounter == 3 ? "rd" : "th"))), (ServerVersion == Engine_Left4Dead ? "" : " or Defibrillator"));
	}
}

void InitializeClientInf(int Client)
{
	for (int i = 1; i <= MAXPLAYERS; i++)
	{
		if (g_iPlayerParalyzed[i][1] == Client)
		{
			g_iPlayerParalyzed[i][0] = 0;
			g_iPlayerParalyzed[i][1] = 0;
		}
		if (g_iPlayerLunged[i][1] == Client)
		{
			g_iPlayerLunged[i][0] = 0;
			g_iPlayerLunged[i][1] = 0;
		}
		if (g_iPlayerCarried[i][1] == Client)
		{
			g_iPlayerCarried[i][0] = 0;
			g_iPlayerCarried[i][1] = 0;
		}
		if (g_iPlayerPummeled[i][1] == Client)
		{
			g_iPlayerPummeled[i][0] = 0;
			g_iPlayerPummeled[i][1] = 0;
		}
		if (g_iPlayerJockied[i][1] == Client)
		{
			g_iPlayerJockied[i][0] = 0;
			g_iPlayerJockied[i][1] = 0;
		}
	}
}

void NotServerConsoleCommand()
{
	PrintToConsole(0, "[RANK] Error: Most of the rank commands including this one are not available from server console.");
}

void StartMapTiming()
{
	if (!MapTimingEnabled() || g_fMapTimingStartTime != 0.0 || StatsDisabled())
		return;

	g_fMapTimingStartTime = GetEngineTime();

	int	 ClientTeam;
	char ClientID[MAX_LINE_WIDTH];

	g_hMapTimingSurvivors.Clear();
	g_hMapTimingInfected.Clear();

	bool SoundsEnabled = (g_bEnableSounds_Maptime_Start && g_hCvar_SoundsEnabled.BoolValue);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);
			if (ClientTeam == TEAM_SURVIVORS)
			{
				GetClientRankAuthString(i, ClientID, sizeof(ClientID));
				g_hMapTimingSurvivors.SetValue(ClientID, 1, true);

				if (SoundsEnabled)
					EmitSoundToClient(i, g_sStatsSound_MapTime_Start);
			}
			else if (ClientTeam == TEAM_INFECTED)
			{
				GetClientRankAuthString(i, ClientID, sizeof(ClientID));
				g_hMapTimingInfected.SetValue(ClientID, 1, true);
			}
		}
	}
}

void StopMapTiming()
{
	if (!MapTimingEnabled() || g_fMapTimingStartTime <= 0.0 || StatsDisabled())
		return;

	float TotalTime	= GetEngineTime() - g_fMapTimingStartTime;
	g_fMapTimingStartTime = -1.0;
	g_bMapTimingBlocked	  = true;

	int	 ClientTeam, enabled;
	char ClientID[MAX_LINE_WIDTH], MapName[MAX_LINE_WIDTH], query[512];

	GetCurrentMap(MapName, sizeof(MapName));

	int i, PlayerCounter = 0, InfectedCounter = (g_iCurrentGamemodeID == GAMEMODE_VERSUS || g_iCurrentGamemodeID == GAMEMODE_SCAVENGE ? 0 : 1);

	for (i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);
			GetClientRankAuthString(i, ClientID, sizeof(ClientID));

			if (ClientTeam == TEAM_SURVIVORS && g_hMapTimingSurvivors.GetValue(ClientID, enabled))
			{
				if (enabled)
					PlayerCounter++;
			}
			else if (ClientTeam == TEAM_INFECTED)
			{
				InfectedCounter++;
				if (g_hMapTimingInfected.GetValue(ClientID, enabled))
				{
					if (enabled)
						PlayerCounter++;
				}
			}
		}
	}

	// Game ended because all of the infected team left the server... don't record the time!
	if (InfectedCounter <= 0)
		return;

	int GameDifficulty = GetCurrentDifficulty();

	for (i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);

			if (ClientTeam == TEAM_SURVIVORS)
			{
				GetClientRankAuthString(i, ClientID, sizeof(ClientID));

				if (g_hMapTimingSurvivors.GetValue(ClientID, enabled))
				{
					if (enabled)
					{
						DataPack dp = new DataPack();
						dp.WriteString(MapName);
						dp.WriteCell(g_iCurrentGamemodeID);
						dp.WriteString(ClientID);
						dp.WriteFloat(TotalTime);
						dp.WriteCell(i);
						dp.WriteCell(PlayerCounter);
						dp.WriteCell(GameDifficulty);
						dp.WriteString(g_sCurrentMutation);

						Format(query, sizeof(query), "SELECT time FROM %stimedmaps WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = '%s' AND steamid = '%s'", g_sDbPrefix, MapName, g_iCurrentGamemodeID, GameDifficulty, g_sCurrentMutation, ClientID);
						SQL_TQuery(db, UpdateMapTimingStat, query, dp);
					}
				}
			}
		}
	}

	g_hMapTimingSurvivors.Clear();
}

void DisplayRankVote(int client)
{
	char question[128];
	strcopy(question, sizeof(question), RANKVOTE_QUESTION);
	DisplayYesNoPanel(client, question, RankVotePanelHandler, RoundToNearest(g_hCvar_RankVoteTime.FloatValue));
}

// Initialize RANKVOTE
void InitializeRankVote(int client)
{
	if (StatsDisabled())
	{
		if (client == 0) PrintToConsole(0, "[RANK] Cannot initiate vote when the plugin is disabled!");
		else StatsPrintToChatPreFormatted2(client, true, "Cannot initiate vote when the plugin is disabled!");

		return;
	}

	// No TEAM gamemodes are allowed
	if (!IsTeamGamemode())
	{
		if (client == 0) PrintToConsole(0, "[RANK] The Rank Vote is not enabled in this gamemode!");
		else
		{
			EngineVersion ServerVersion = GetEngineVersion();
			if (ServerVersion == Engine_Left4Dead) StatsPrintToChatPreFormatted2(client, true, "The \x04Rank Vote \x01is enabled in \x03Versus \x01gamemode!");
			else StatsPrintToChatPreFormatted2(client, true, "The \x04Rank Vote \x01is enabled in \x03Versus\x01, \x03Realism Versus \x01and \x03Scavenge \x01gamemodes!");
		}

		return;
	}

	if (g_hRankVoteTimer != INVALID_HANDLE)
	{
		if (client > 0) DisplayRankVote(client);
		else PrintToConsole(client, "[RANK] The Rank Vote is already initiated!");

		return;
	}

	bool IsAdmin = (client > 0 ? ((GetUserFlagBits(client) & ADMFLAG_GENERIC) == ADMFLAG_GENERIC) : true);

	int	team;
	char ClientID[MAX_LINE_WIDTH];

	if (!IsAdmin && client > 0 && g_hPlayerRankVoteTrie.GetValue(ClientID, team))
	{
		StatsPrintToChatPreFormatted2(client, true, "You can initiate a \x04Rank Vote \x01only once per map!");
		return;
	}

	if (!IsAdmin && client > 0)
	{
		GetClientRankAuthString(client, ClientID, sizeof(ClientID));
		g_hPlayerRankVoteTrie.SetValue(ClientID, 1, true);
	}

	g_hRankVoteTimer = CreateTimer(g_hCvar_RankVoteTime.FloatValue, Timer_RankVote);

	int i;

	for (i = 0; i <= MAXPLAYERS; i++)
		g_iPlayerRankVote[i] = RANKVOTE_NOVOTE;

	for (i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			team = GetClientTeam(i);

			if (team == TEAM_SURVIVORS || team == TEAM_INFECTED)
				DisplayRankVote(i);
		}
	}

	if (client > 0)
	{
		char UserName[MAX_LINE_WIDTH];
		GetClientName(client, UserName, sizeof(UserName));
		StatsPrintToChatAll2(true, "The \x04Rank Vote \x01was initiated by \x05%s\x01!", UserName);
	}
	else StatsPrintToChatAllPreFormatted2(true, "The \x04Rank Vote \x01was initiated from Server Console!");
}

void CheckSurvivorsAllDown()
{
	if (g_bCampaignOver || g_iCurrentGamemodeID == GAMEMODE_COOP || g_iCurrentGamemodeID == GAMEMODE_REALISM)
		return;

	int	 ClientTeam;
	bool ClientIsAlive, ClientIsBot, ClientIsIncap;
	int	 KilledSurvivor[MAXPLAYERS + 1];
	int	 AliveInfected[MAXPLAYERS + 1];
	int	 Infected[MAXPLAYERS + 1];
	int	 InfectedCounter = 0, AliveInfectedCounter = 0;
	int	 i;

	// Add to killing score on all incapacitated surviviors
	int	 IncapCounter = 0;

	for (i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		ClientIsBot	  = IsClientBot(i);
		ClientIsIncap = IsClientIncapacitated(i);
		ClientIsAlive = IsClientAlive(i);

		if (ClientIsBot || IsClientInGame(i))
			ClientTeam = GetClientTeam(i);
		else
			continue;

		// Client is not dead and not incapped -> game continues!
		if (ClientTeam == TEAM_SURVIVORS && ClientIsAlive && !ClientIsIncap)
			return;

		if (ClientTeam == TEAM_INFECTED && !ClientIsBot)
		{
			if (ClientIsAlive)
				AliveInfected[AliveInfectedCounter++] = i;

			Infected[InfectedCounter++] = i;
		}
		else if (ClientTeam == TEAM_SURVIVORS && ClientIsAlive)
			KilledSurvivor[IncapCounter++] = i;
	}

	// If we ever get this far it means the surviviors are all down or dead!
	g_bCampaignOver = true;

	// Stop the timer and return if gamemode is Survival
	if (g_iCurrentGamemodeID == GAMEMODE_SURVIVAL)
	{
		g_bSurvivalStarted = false;
		StopMapTiming();
		return;
	}

	// If we ever get this far it means the current gamemode is NOT Survival
	for (i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i) && IsClientInGame(i))
		{
			if (GetClientTeam(i) == TEAM_SURVIVORS)
				InterstitialPlayerUpdate(i);

			if (g_hTimerRankChangeCheck[i] != null)
				TriggerTimer(g_hTimerRankChangeCheck[i], true);
		}
	}

	char query[1024];
	char ClientID[MAX_LINE_WIDTH];
	int	 Mode = g_hCvar_AnnounceMode.IntValue;

	for (i = 0; i < AliveInfectedCounter; i++)
		DoInfectedFinalChecks(AliveInfected[i]);

	int Score = ModifyScoreDifficultyFloat(g_hCvar_VictoryInfectedScore.IntValue, 0.75, 0.5, TEAM_INFECTED) * IncapCounter;

	if (Score > 0)
		for (i = 0; i < InfectedCounter; i++)
		{
			GetClientRankAuthString(Infected[i], ClientID, sizeof(ClientID));

			if (g_iCurrentGamemodeID == GAMEMODE_VERSUS)
				Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected + %i, award_infected_win = award_infected_win + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, ClientID);
			else if (g_iCurrentGamemodeID == GAMEMODE_REALISMVERSUS)
				Format(query, sizeof(query), "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i, award_infected_win = award_infected_win + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, ClientID);
			else if (g_iCurrentGamemodeID == GAMEMODE_SCAVENGE)
				Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i, award_scavenge_infected_win = award_scavenge_infected_win + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, ClientID);
			else
				Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations + %i, award_scavenge_infected_win = award_scavenge_infected_win + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, ClientID);

			SendSQLUpdate(query);
		}

	UpdateMapStat("infected_win", 1);
	if (IncapCounter > 0)
		UpdateMapStat("survivor_kills", IncapCounter);
	if (Score > 0)
		UpdateMapStat("points_infected", Score);

	if (Score > 0 && Mode)
		StatsPrintToChatTeam(TEAM_INFECTED, "\x03ALL INFECTED \x01have earned \x04%i \x01points for killing all survivors!", Score);

	if (!g_hCvar_EnableNegativeScore.BoolValue)
		return;

	if (g_iCurrentGamemodeID == GAMEMODE_VERSUS)
		Score = ModifyScoreDifficultyFloatNR(g_hCvar_ActionScore[ACT_RESTART].IntValue, 0.75, 0.5, TEAM_SURVIVORS);
	else if (g_iCurrentGamemodeID == GAMEMODE_REALISMVERSUS)
		Score = ModifyScoreDifficultyFloatNR(g_hCvar_ActionScore[ACT_RESTART].IntValue, 0.6, 0.3, TEAM_SURVIVORS);
	else
	{
		Score = ModifyScoreDifficultyNR(g_hCvar_ActionScore[ACT_RESTART].IntValue, 2, 3, TEAM_SURVIVORS);
		Score = 400 - Score;
	}

	for (i = 0; i < IncapCounter; i++)
	{
		GetClientRankAuthString(KilledSurvivor[i], ClientID, sizeof(ClientID));

		if (g_iCurrentGamemodeID == GAMEMODE_VERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_survivors = points_survivors - %i WHERE steamid = '%s'", g_sDbPrefix, Score, ClientID);
		else if (g_iCurrentGamemodeID == GAMEMODE_REALISMVERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_realism_survivors = points_realism_survivors - %i WHERE steamid = '%s'", g_sDbPrefix, Score, ClientID);
		else if (g_iCurrentGamemodeID == GAMEMODE_SCAVENGE)
			Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_survivors = points_scavenge_survivors - %i WHERE steamid = '%s'", g_sDbPrefix, Score, ClientID);
		else
			Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations - %i WHERE steamid = '%s'", g_sDbPrefix, Score, ClientID);

		SendSQLUpdate(query);
	}

	if (Mode)
		StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03ALL SURVIVORS \x01have \x03LOST \x04%i \x01points for \x03All Survivors Dying\x01!", Score);
}

void UpdateSmokerDamage(int Client, int Damage)
{
	if (Client <= 0 || Damage <= 0 || IsClientBot(Client))
		return;

	char iID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, iID, sizeof(iID));

	char query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_smoker_damage = infected_smoker_damage + %i WHERE steamid = '%s'", g_sDbPrefix, Damage, iID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_smoker_damage", Damage);
}

void UpdateSpitterDamage(int Client, int Damage)
{
	if (Client <= 0 || Damage <= 0 || IsClientBot(Client))
		return;

	char iID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, iID, sizeof(iID));

	char query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_spitter_damage = infected_spitter_damage + %i WHERE steamid = '%s'", g_sDbPrefix, Damage, iID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_spitter_damage", Damage);
}

void UpdateJockeyDamage(int Client, int Damage)
{
	if (Client <= 0 || Damage <= 0 || IsClientBot(Client))
		return;

	char iID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, iID, sizeof(iID));

	char query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_jockey_damage = infected_jockey_damage + %i WHERE steamid = '%s'", g_sDbPrefix, Damage, iID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_jockey_damage", Damage);
}

void UpdateJockeyRideLength(int Client, float RideLength = -1.0)
{
	if (Client <= 0 || RideLength == 0 || IsClientBot(Client) || (RideLength < 0 && g_iJockeyRideStartTime[Client] <= 0))
		return;

	if (RideLength < 0)
		RideLength = float(GetTime() - g_iJockeyRideStartTime[Client]);

	char iID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, iID, sizeof(iID));

	char query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_jockey_ridetime = infected_jockey_ridetime + %f WHERE steamid = '%s'", g_sDbPrefix, RideLength, iID);
	SendSQLUpdate(query);

	UpdateMapStatFloat("infected_jockey_ridetime", RideLength);
}

void UpdateChargerDamage(int Client, int Damage)
{
	if (Client <= 0 || Damage <= 0 || IsClientBot(Client))
		return;

	char iID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, iID, sizeof(iID));

	char query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_charger_damage = infected_charger_damage + %i WHERE steamid = '%s'", g_sDbPrefix, Damage, iID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_charger_damage", Damage);
}

public CheckSurvivorsWin()
{
	if (g_bCampaignOver)
		return;

	g_bCampaignOver = true;

	StopMapTiming();

	// Return if gamemode is Scavenge or Survival
	if (g_iCurrentGamemodeID == GAMEMODE_SCAVENGE || g_iCurrentGamemodeID == GAMEMODE_SURVIVAL)
		return;

	int	 Score = ModifyScoreDifficulty(g_hCvar_NotDisturbingWitchScore.IntValue, 5, 10, TEAM_SURVIVORS);
	int	 Mode  = g_hCvar_AnnounceMode.IntValue;
	char iID[MAX_LINE_WIDTH];
	char query[1024];
	char UpdatePoints[32], UpdatePointsPenalty[32];
	int	 ClientTeam;
	bool NegativeScore = g_hCvar_EnableNegativeScore.BoolValue;

	switch (g_iCurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
			Format(UpdatePointsPenalty, sizeof(UpdatePointsPenalty), "points_infected");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
			Format(UpdatePointsPenalty, sizeof(UpdatePointsPenalty), "points_realism_infected");
		}
		case GAMEMODE_OTHERMUTATIONS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_mutations");
		}
		default:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points");
		}
	}

	if (Score > 0 && g_bWitchExists && !g_bWitchDisturb)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i) && GetClientTeam(i) == TEAM_SURVIVORS)
			{
				GetClientRankAuthString(i, iID, sizeof(iID));
				Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i WHERE steamid = '%s'", g_sDbPrefix, UpdatePoints, UpdatePoints, Score, iID);
				SendSQLUpdate(query);
				UpdateMapStat("points", Score);
				AddScore(i, Score);
			}
		}

		if (Mode)
			StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03ALL SURVIVORS \x01have earned \x04%i \x01points for \x05Not Disturbing A Witch!", Score);
	}

	Score = 0;
	int Deaths = 0;
	int BaseScore = ModifyScoreDifficulty(g_hCvar_ReachedSafeHouseScore.IntValue, 2, 5, TEAM_SURVIVORS);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i) && GetClientTeam(i) == TEAM_SURVIVORS)
		{
			if (IsPlayerAlive(i))
				Score = Score + BaseScore;
			else
				Deaths++;
		}
	}

	char All4Safe[64] = "";
	if (Deaths == 0)
		Format(All4Safe, sizeof(All4Safe), ", award_allinsafehouse = award_allinsafehouse + 1");

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);

			if (ClientTeam == TEAM_SURVIVORS)
			{
				InterstitialPlayerUpdate(i);
				GetClientRankAuthString(i, iID, sizeof(iID));
				Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i%s WHERE steamid = '%s'", g_sDbPrefix, UpdatePoints, UpdatePoints, Score, All4Safe, iID);
				SendSQLUpdate(query);
				UpdateMapStat("points", Score);
				AddScore(i, Score);
			}
			else if (ClientTeam == TEAM_INFECTED && NegativeScore)
			{
				DoInfectedFinalChecks(i);
				GetClientRankAuthString(i, iID, sizeof(iID));
				Format(query, sizeof(query), "UPDATE %splayers SET %s = %s - %i WHERE steamid = '%s'", g_sDbPrefix, UpdatePoints, UpdatePoints, Score, iID);
				SendSQLUpdate(query);
				AddScore(i, Score * (-1));
			}

			if (g_hTimerRankChangeCheck[i] != null)
				TriggerTimer(g_hTimerRankChangeCheck[i], true);
		}
	}

	if (Mode && Score > 0)
	{
		StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03ALL SURVIVORS \x01have earned \x04%i \x01points for reaching a Safe House with \x05%i Deaths!", Score, Deaths);

		if (NegativeScore)
			StatsPrintToChatTeam(TEAM_INFECTED, "\x03ALL INFECTED \x01have \x03LOST \x04%i \x01points for letting the survivors reach a Safe House!", Score);
	}

	g_bPlayerVomited = false;
	g_bPanicEvent = false;
}

void ResetInfVars()
{
	int i;

	// Reset all Infected variables
	for (i = 0; i < MAXPLAYERS + 1; i++)
	{
		g_iBoomerHitCounter[i]		  = 0;
		g_iBoomerVomitUpdated[i]	  = false;
		g_iInfectedDamageCounter[i]	  = 0;
		g_iSmokerDamageCounter[i]	  = 0;
		g_iSpitterDamageCounter[i]	  = 0;
		g_iJockeyDamageCounter[i]	  = 0;
		g_iChargerDamageCounter[i]	  = 0;
		g_iChargerImpactCounter[i]	  = 0;
		g_iTankPointsCounter[i]		  = 0;
		g_iTankDamageCounter[i]		  = 0;
		g_iClientInfectedType[i]	  = 0;
		g_iTankSurvivorKillCounter[i] = 0;
		g_iTankDamageTotalCounter[i]  = 0;
		g_iChargerCarryVictim[i]	  = 0;
		g_iChargerPlummelVictim[i]	  = 0;
		g_iJockeyVictim[i]			  = 0;
		g_iJockeyRideStartTime[i]	  = 0;

		g_iPlayerBlinded[i][0]		  = 0;
		g_iPlayerBlinded[i][1]		  = 0;
		g_iPlayerParalyzed[i][0]	  = 0;
		g_iPlayerParalyzed[i][1]	  = 0;
		g_iPlayerLunged[i][0]		  = 0;
		g_iPlayerLunged[i][1]		  = 0;
		g_iPlayerPummeled[i][0]		  = 0;
		g_iPlayerPummeled[i][1]		  = 0;
		g_iPlayerCarried[i][0]		  = 0;
		g_iPlayerCarried[i][1]		  = 0;
		g_iPlayerJockied[i][0]		  = 0;
		g_iPlayerJockied[i][1]		  = 0;

		delete g_hTimerBoomerPerfectCheck[i];
		delete g_hTimerInfectedDamageCheck[i];

		delete g_hTimerProtectedFriendly[i];
		g_iProtectedFriendlyCounter[i] = 0;

		if (g_hChargerImpactCounterTimer[i] != null)
			delete g_hChargerImpactCounterTimer[i];

		delete g_hChargerImpactCounterTimer[i];
	}
}

void ResetVars()
{
	ClearTrie(g_hFriendlyFireDamageTrie);
	ClearTrie(g_hPlayerRankVoteTrie);

	g_bPlayerVomited	  = false;
	g_bPlayerVomitedIncap = false;
	g_bPanicEvent		  = false;
	g_bPanicEventIncap	  = false;
	g_bCampaignOver		  = false;
	g_bWitchExists		  = false;
	g_bWitchDisturb		  = false;
	g_iMedkitsUsedCounter = 0;

	// Reset kill/point score timer amount
	CreateTimer(1.0, Timer_InitPlayers);

	g_iTankCount = 0;

	int i, j;
	for (i = 1; i <= MaxClients; i++)
	{
		g_iAnnounceCounter[i] = 0;
		g_iCurrentPoints[i]	  = 0;
		g_bClientRankMute[i]  = false;
	}

	for (i = 0; i < MAXPLAYERS + 1; i++)
	{
		if (g_hTimerRankChangeCheck[i] != null)
			delete g_hTimerRankChangeCheck[i];

		delete g_hTimerRankChangeCheck[i];

		for (j = 0; j < MAXPLAYERS + 1; j++)
		{
			g_bFriendlyFireCooldown[i][j] = false;
			delete g_hFriendlyFireTimer[i][j];
		}

		if (g_hMeleeKillTimer[i] != null)
			delete g_hMeleeKillTimer[i];

		delete g_hMeleeKillTimer[i];
		g_iMeleeKillCounter[i]			 = 0;

		g_iPostAdminCheckRetryCounter[i] = 0;
	}

	ResetInfVars();
}

void ResetRankChangeCheck()
{
	for (int i = 1; i <= MaxClients; i++)
		StartRankChangeCheck(i);
}

void StartRankChangeCheck(int Client)
{
	if (g_hTimerRankChangeCheck[Client] != null)
		delete g_hTimerRankChangeCheck[Client];

	delete g_hTimerRankChangeCheck[Client];

	if (Client == 0 || IsClientBot(Client))
		return;

	g_bRankChangeFirstCheck[Client] = true;
	DoShowRankChange(Client);
	g_hTimerRankChangeCheck[Client] = CreateTimer(g_hCvar_AnnounceRankChangeIVal.FloatValue, Timer_ShowRankChange, Client, TIMER_REPEAT);
}

void ShowMOTDAll()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			ShowMOTD(i);
	}
}

void ShowMOTD(int client, bool forced = false)
{
	if (!forced && !g_hCvar_AnnounceMotd.BoolValue)
		return;

	StatsPrintToChat2(client, forced, "\x05%s: \x01%s", MOTD_TITLE, g_sMessageOfTheDay);
}

void AnnouncePlayerConnect(int client)
{
	if (!g_hCvar_AnnouncePlayerJoined.BoolValue)
		return;

	DoShowPlayerJoined(client);
}

void HunterSmokerSave(int Savior, int Victim, int BasePoints, int AdvMult, int ExpertMult, char[] SaveFrom, char[] SQLField)
{
	if (StatsDisabled())
		return;

	if (IsClientBot(Savior) || IsClientBot(Victim))
		return;

	int	 Mode = g_hCvar_AnnounceMode.IntValue;

	char SaviorName[MAX_LINE_WIDTH];
	GetClientName(Savior, SaviorName, sizeof(SaviorName));
	char SaviorID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Savior, SaviorID, sizeof(SaviorID));

	char VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));
	char VictimID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Victim, VictimID, sizeof(VictimID));

	if (StrEqual(SaviorID, VictimID))
		return;

	int	 Score = ModifyScoreDifficulty(BasePoints, AdvMult, ExpertMult, TEAM_SURVIVORS);
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
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, %s = %s + 1 WHERE steamid = '%s'", g_sDbPrefix, UpdatePoints, UpdatePoints, Score, SQLField, SQLField, SaviorID);
	SendSQLUpdate(query);

	if (Score <= 0)
		return;

	if (Mode)
		StatsPrintToChat(Savior, "You have earned \x04%i \x01points for saving \x05%s\x01 from \x04%s\x01!", Score, VictimName, SaveFrom);

	UpdateMapStat("points", Score);
	AddScore(Savior, Score);
}

void StartRankVote(int client)
{
	if (!g_hCvar_EnableRankVote.BoolValue)
	{
		if (client > 0) StatsPrintToChatPreFormatted(client, "The \x04Rank Vote \x01is \x03DISABLED\x01.");
		else PrintToConsole(0, "[RANK] The Rank Vote is DISABLED.");
	}
	else InitializeRankVote(client);
}

// Update a player's stats, used for interstitial updating.
void InterstitialPlayerUpdate(int client)
{
	char ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, ClientID, sizeof(ClientID));

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

	int	 len = 0;
	char query[1024];
	len += Format(query[len], sizeof(query) - len, "UPDATE %splayers SET %s = %s + %i, ", g_sDbPrefix, UpdatePoints, UpdatePoints, g_iTimerPoints[client]);
	len += Format(query[len], sizeof(query) - len, "kills = kills + %i, kill_infected = kill_infected + %i, ", g_iTimerKills[client], g_iTimerKills[client]);
	len += Format(query[len], sizeof(query) - len, "headshots = headshots + %i ", g_iTimerHeadshots[client]);
	len += Format(query[len], sizeof(query) - len, "WHERE steamid = '%s'", ClientID);
	SendSQLUpdate(query);
	UpdateMapStat("kills", g_iTimerKills[client]);
	UpdateMapStat("points", g_iTimerPoints[client]);
	AddScore(client, g_iTimerPoints[client]);
}

void ClearStatsMaps(int client)
{
	if (!DoFastQuery(client, "START TRANSACTION"))
		return;

	char query[256];
	Format(query, sizeof(query), "SELECT * FROM %smaps WHERE 1 = 2", g_sDbPrefix);
	SQL_TQuery(db, ClearStatsMapsHandler, query, client);
}

void ClearStatsAll(int client)
{
	if (!DoFastQuery(client, "START TRANSACTION"))
		return;

	if (!DoFastQuery(client, "DELETE FROM %stimedmaps", g_sDbPrefix))
	{
		PrintToConsole(client, "[RANK] Clear Stats: Clearing timedmaps table failed. Executing rollback...");
		DoFastQuery(client, "ROLLBACK");
		PrintToConsole(client, "[RANK] Clear Stats: Failure!");

		return;
	}

	if (!DoFastQuery(client, "DELETE FROM %splayers", g_sDbPrefix))
	{
		PrintToConsole(client, "[RANK] Clear Stats: Clearing players table failed. Executing rollback...");
		DoFastQuery(client, "ROLLBACK");
		PrintToConsole(client, "[RANK] Clear Stats: Failure!");

		return;
	}

	char query[256];
	Format(query, sizeof(query), "SELECT * FROM %smaps WHERE 1 = 2", g_sDbPrefix);

	SQL_TQuery(db, ClearStatsMapsHandler, query, client);
}

void ClearStatsPlayers(int client)
{
	if (!DoFastQuery(client, "START TRANSACTION"))
		return;

	if (!DoFastQuery(client, "DELETE FROM %splayers", g_sDbPrefix))
	{
		PrintToConsole(client, "[RANK] Clear Stats: Clearing players table failed. Executing rollback...");
		DoFastQuery(client, "ROLLBACK");
		PrintToConsole(client, "[RANK] Clear Stats: Failure!");
	}
	else
	{
		DoFastQuery(client, "COMMIT");
		PrintToConsole(client, "[RANK] Clear Stats: Ranks succesfully cleared!");
	}
}

void DoShowRankChange(int Client)
{
	if (StatsDisabled())
		return;

	char ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, ClientID, sizeof(ClientID));
	QueryClientPointsSteamID(Client, ClientID, GetClientPointsRankChange);
}

void DoShowPlayerJoined(int client)
{
	if (StatsDisabled())
	{
		return;
	}

	char clientId[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, clientId, sizeof(clientId));

	QueryClientPointsSteamID(client, clientId, GetClientPointsPlayerJoined);
}
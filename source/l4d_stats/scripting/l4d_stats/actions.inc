#if defined _l4d_stats_actions_included
 #endinput
#endif
#define _l4d_stats_actions_included

DoInfectedFinalChecks(int Client, int ClientInfType = -1)
{
	if (Client == 0)
		return;

    EngineVersion ServerVersion = GetEngineVersion();

	if (ClientInfType < 0)
		ClientInfType = g_iClientInfectedType[Client];

	if (ClientInfType == INF_ID_SMOKER)
	{
		new Damage = g_iSmokerDamageCounter[Client];
		g_iSmokerDamageCounter[Client] = 0;
		UpdateSmokerDamage(Client, Damage);
	}
	else if (ServerVersion != Engine_Left4Dead && ClientInfType == INF_ID_SPITTER_L4D2)
	{
		new Damage = g_iSpitterDamageCounter[Client];
		g_iSpitterDamageCounter[Client] = 0;
		UpdateSpitterDamage(Client, Damage);
	}
	else if (ServerVersion != Engine_Left4Dead && ClientInfType == INF_ID_JOCKEY_L4D2)
	{
		new Damage = g_iJockeyDamageCounter[Client];
		g_iJockeyDamageCounter[Client] = 0;
		UpdateJockeyDamage(Client, Damage);
		UpdateJockeyRideLength(Client);
	}
	else if (ServerVersion != Engine_Left4Dead && ClientInfType == INF_ID_CHARGER_L4D2)
	{
		new Damage = g_iChargerDamageCounter[Client];
		g_iChargerDamageCounter[Client] = 0;
		UpdateChargerDamage(Client, Damage);
	}
}

GetInfType(Client)
{
	// Client > 0 && ClientTeam == TEAM_INFECTED checks are done by the caller
	int InfType = GetEntProp(Client, Prop_Send, "m_zombieClass");

	// Make the conversion so that everything gets stored in the correct fields
	EngineVersion ServerVersion = GetEngineVersion();
	if (ServerVersion == Engine_Left4Dead)
	{
		if (InfType == INF_ID_WITCH_L4D1)
			return INF_ID_WITCH_L4D2;

		if (InfType == INF_ID_TANK_L4D1)
			return INF_ID_TANK_L4D2;
	}

	return InfType;
}

Setg_iClientInfectedType(Client)
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

TankDamage(Client, Damage)
{
	if (Client <= 0 || Damage <= 0)
		return 0;

	// Update only the Tank inflicted damage related statistics
	UpdateTankDamage(Client, Damage);

	// If value is negative then client has already received the Bulldozer Award
	if (TankDamageTotalCounter[Client] >= 0)
	{
		TankDamageTotalCounter[Client] += Damage;
		new TankDamageTotal = GetConVarInt(g_hCvar_TankScoreDamageTotal);

		if (TankDamageTotalCounter[Client] >= TankDamageTotal)
		{
			TankDamageTotalCounter[Client] = -1; // Just one award per Tank
			new Score = ModifyScoreDifficultyFloat(GetConVarInt(g_hCvar_TankScoreDamageTotalSuccessScore), 0.75, 0.5, TEAM_INFECTED);

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

				new Mode = GetConVarInt(g_hCvar_AnnounceMode);

				if (Mode == 1 || Mode == 2)
					StatsPrintToChat(Client, "You have earned \x04%i \x01points for Bulldozing the Survivors worth %i points of damage!", Score, TankDamageTotal);
				else if (Mode == 3)
				{
					char Name[MAX_LINE_WIDTH];
					GetClientName(Client, Name, sizeof(Name));
					StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for Bulldozing the Survivors worth %i points of damage!", Name, Score, TankDamageTotal);
				}

				if (g_bEnableSounds_Tank_Bulldozer && GetConVarBool(g_hCvar_SoundsEnabled))
					EmitSoundToAll(g_sStatsSound_Tank_Bulldozer);
			}
		}
	}

	int DamageLimit = GetConVarInt(g_hCvar_TankScoreDamageCap);

	if (TankDamageCounter[Client] >= DamageLimit)
		return 0;

	TankDamageCounter[Client] += Damage;

	if (TankDamageCounter[Client] > DamageLimit)
		Damage -= TankDamageCounter[Client] - DamageLimit;

	return Damage;
}

UpdateFriendlyFire(Attacker, Victim)
{
	char AttackerName[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerName, sizeof(AttackerName));
	char AttackerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Attacker, AttackerID, sizeof(AttackerID));

	char VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));

	int Score = 0;
	if (GetConVarBool(g_hCvar_EnableNegativeScore))
	{
		if (!IsClientBot(Victim))
			Score = ModifyScoreDifficultyNR(GetConVarInt(g_hCvar_ActionScore[ACT_FF]), 2, 4, TEAM_SURVIVORS);
		else
		{
			float BotScoreMultiplier = GetConVarFloat(g_hCvar_BotScoreMultiplier);

			if (BotScoreMultiplier > 0.0)
				Score = RoundToNearest(ModifyScoreDifficultyNR(GetConVarInt(g_hCvar_ActionScore[ACT_FF]), 2, 4, TEAM_SURVIVORS) * BotScoreMultiplier);
		}
	}

	char UpdatePoints[32];

	switch (g_iCurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
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

	char query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s - %i, award_friendlyfire = award_friendlyfire + 1 WHERE steamid = '%s'", g_sDbPrefix, UpdatePoints, UpdatePoints, Score, AttackerID);
	SendSQLUpdate(query);

	int Mode = 0;
	if (Score > 0)
		Mode = GetConVarInt(g_hCvar_AnnounceMode);

	if (Mode == 1 || Mode == 2)
		StatsPrintToChat(Attacker, "You have \x03LOST \x04%i \x01points for \x03Friendly Firing \x05%s\x01!", Score, VictimName);
	else if (Mode == 3)
		StatsPrintToChatAll("\x05%s \x01has \x03LOST \x04%i \x01points for \x03Friendly Firing \x05%s\x01!", AttackerName, Score, VictimName);
}

UpdateHunterDamage(Client, Damage)
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

UpdateTankDamage(Client, Damage)
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
UpdatePlayerScore2(Client, Score, const char[] Points)
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

UpdateTankSniper(Client)
{
	if (Client <= 0)
		return;

	char ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Client, ClientID, sizeof(ClientID));

	UpdateTankSniperSteamID(ClientID);
}

UpdateTankSniperSteamID(const char[] ClientID)
{
	char query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET infected_tanksniper = infected_tanksniper + 1 WHERE steamid = '%s'", g_sDbPrefix, ClientID);
	SendSQLUpdate(query);

	UpdateMapStat("infected_tanksniper", 1);
}

// Survivor died.

SurvivorDied(Attacker, Victim, AttackerInfType = -1, Mode = -1)
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

SurvivorDiedNamed(Attacker, Victim, const char[] VictimName, const char[] AttackerID, AttackerInfType = -1, Mode = -1)
{
	if (!Attacker || !Victim || StatsGetClientTeam(Attacker) != TEAM_INFECTED || StatsGetClientTeam(Victim) != TEAM_SURVIVORS)
		return;

//LogError("SurvivorDiedNamed - VictimName = %s", VictimName);

	if (AttackerInfType < 0)
	{
		if (g_iClientInfectedType[Attacker] == 0)
			Setg_iClientInfectedType(Attacker);

		AttackerInfType = g_iClientInfectedType[Attacker];
	}

	EngineVersion ServerVersion = GetEngineVersion();
	if (ServerVersion == Engine_Left4Dead)
	{
		if (AttackerInfType != INF_ID_SMOKER
				&& AttackerInfType != INF_ID_BOOMER
				&& AttackerInfType != INF_ID_HUNTER
				&& AttackerInfType != INF_ID_TANK_L4D2) // Setg_iClientInfectedType sets tank id to L4D2
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

	int Score = GetSurvivorKillScore();

	int len = 0;
	char query[1024];

	if (g_iCurrentGamemodeID == GAMEMODE_VERSUS)
		len += Format(query[len], sizeof(query)-len, "UPDATE %splayers SET points_infected = points_infected + %i, versus_kills_survivors = versus_kills_survivors + 1 ", g_sDbPrefix, Score);
	else if (g_iCurrentGamemodeID == GAMEMODE_REALISMVERSUS)
		len += Format(query[len], sizeof(query)-len, "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i, realism_kills_survivors = realism_kills_survivors + 1 ", g_sDbPrefix, Score);
	else if (g_iCurrentGamemodeID == GAMEMODE_SCAVENGE)
		len += Format(query[len], sizeof(query)-len, "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i, scavenge_kills_survivors = scavenge_kills_survivors + 1 ", g_sDbPrefix, Score);
	else
		len += Format(query[len], sizeof(query)-len, "UPDATE %splayers SET points_mutations = points_mutations + %i, mutations_kills_survivors = mutations_kills_survivors + 1 ", g_sDbPrefix, Score);
	len += Format(query[len], sizeof(query)-len, "WHERE steamid = '%s'", AttackerID);
	SendSQLUpdate(query);

	if (Mode < 0)
		Mode = GetConVarInt(g_hCvar_AnnounceMode);

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

SurvivorHurt(Attacker, Victim, Damage, AttackerInfType = -1, Handle event = INVALID_HANDLE)
{
	if (!Attacker || !Victim || Damage <= 0 || Attacker == Victim)
		return;

	if (AttackerInfType < 0)
	{
		new AttackerTeam = GetClientTeam(Attacker);

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

	if (g_hTimerInfectedDamageCheck[Attacker] != INVALID_HANDLE)
	{
		CloseHandle(g_hTimerInfectedDamageCheck[Attacker]);
		g_hTimerInfectedDamageCheck[Attacker] = INVALID_HANDLE;
	}

	int VictimHealth = GetClientHealth(Victim);

	if (VictimHealth < 0)
		Damage += VictimHealth;

	if (Damage <= 0)
		return;

	if (AttackerInfType == INF_ID_TANK_L4D2 && event != INVALID_HANDLE)
	{
		g_iInfectedDamageCounter[Attacker] += TankDamage(Attacker, Damage);

		char Weapon[16];
		GetEventString(event, "weapon", Weapon, sizeof(Weapon));

		new RockHit = GetConVarInt(g_hCvar_TankScoreThrowRockSuccessScore);

		if (RockHit > 0 && strcmp(Weapon, "tank_rock", false) == 0)
		{
			if (g_iCurrentGamemodeID == GAMEMODE_VERSUS)
				UpdatePlayerScore2(Attacker, RockHit, "points_infected");
			else if (g_iCurrentGamemodeID == GAMEMODE_REALISMVERSUS)
				UpdatePlayerScore2(Attacker, RockHit, "points_realism_infected");
			else if (g_iCurrentGamemodeID == GAMEMODE_SCAVENGE)
				UpdatePlayerScore2(Attacker, RockHit, "points_scavenge_infected");
			else
				UpdatePlayerScore2(Attacker, RockHit, "points_mutations");
			UpdateTankSniper(Attacker);

			char VictimName[MAX_LINE_WIDTH];

			if (Victim > 0)
				GetClientName(Victim, VictimName, sizeof(VictimName));
			else
				Format(VictimName, sizeof(VictimName), "UNKNOWN");

			new Mode = GetConVarInt(g_hCvar_AnnounceMode);

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

	g_hTimerInfectedDamageCheck[Attacker] = CreateTimer(5.0, timer_InfectedDamageCheck, Attacker);
}

// Survivor was hurt by normal infected while being blinded and/or paralyzed.
SurvivorHurtExternal(Handle event, Victim)
{
	if (event == INVALID_HANDLE || !Victim)
		return;

	int Damage = GetEventInt(event, "dmg_health");

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

PlayerDeathExternal(Victim)
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

PlayerIncapExternal(Victim)
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

SurvivorIncappedByInfected(Attacker, Victim, Mode = -1)
{
	if (Attacker > 0 && !IsClientConnected(Attacker) || Attacker > 0 && IsClientBot(Attacker))
		return;

	char AttackerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Attacker, AttackerID, sizeof(AttackerID));
	char AttackerName[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerName, sizeof(AttackerName));

	char VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));

	int Score = ModifyScoreDifficultyFloat(GetConVarInt(g_hCvar_SurvivorIncapScore), 0.75, 0.5, TEAM_INFECTED);

	if (Score <= 0)
		return;

	char query[512];

	if (g_iCurrentGamemodeID == GAMEMODE_VERSUS)
		Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected + %i, award_survivor_down = award_survivor_down + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, AttackerID);
	else if (g_iCurrentGamemodeID == GAMEMODE_REALISMVERSUS)
		Format(query, sizeof(query), "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i, award_survivor_down = award_survivor_down + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, AttackerID);
	else if (g_iCurrentGamemodeID == GAMEMODE_SCAVENGE)
		Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i, award_survivor_down = award_survivor_down + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, AttackerID);
	else
		Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations + %i, award_survivor_down = award_survivor_down + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, AttackerID);
	SendSQLUpdate(query);

	UpdateMapStat("points_infected", Score);

	if (Mode < 0)
		Mode = GetConVarInt(g_hCvar_AnnounceMode);

	if (Mode == 1 || Mode == 2)
		StatsPrintToChat(Attacker, "You have earned \x04%i \x01points for Incapacitating \x05%s\x01!", Score, VictimName);
	else if (Mode == 3)
		StatsPrintToChatAll("\x05%s \x01has earned \x04%i \x01points for Incapacitating \x05%s\x01!", AttackerName, Score, VictimName);
}

float GetMedkitPointReductionFactor()
{
	if (g_iMedkitsUsedCounter <= 0)
		return 1.0;

	float Penalty = GetConVarFloat(g_hCvar_MedkitUsedPointPenalty);

	// If Penalty is set to ZERO: There is no reduction.
	if (Penalty <= 0.0)
		return 1.0;

	int PenaltyFree = -1;

	if (g_iCurrentGamemodeID == GAMEMODE_REALISM || g_iCurrentGamemodeID == GAMEMODE_REALISMVERSUS)
		PenaltyFree = GetConVarInt(g_hCvar_MedkitUsedRealismFree);

	if (PenaltyFree < 0)
		PenaltyFree = GetConVarInt(g_hCvar_MedkitUsedFree);

	if (PenaltyFree >= g_iMedkitsUsedCounter)
		return 1.0;

	Penalty *= g_iMedkitsUsedCounter - PenaltyFree;

	float PenaltyMax = GetConVarFloat(g_hCvar_MedkitUsedPointPenaltyMax);

	if (Penalty > PenaltyMax)
		return 1.0 - PenaltyMax;

	return 1.0 - Penalty;
}

// Calculate the score with the medkit point reduction

GetMedkitPointReductionScore(Score, bool ToCeil = false)
{
	float ReductionFactor = GetMedkitPointReductionFactor();

	if (ReductionFactor == 1.0)
		return Score;

	if (ToCeil)
		return RoundToCeil(Score * ReductionFactor);
	else
		return RoundToFloor(Score * ReductionFactor);
}

AnnounceMedkitPenalty(Mode = -1)
{
	float ReductionFactor = GetMedkitPointReductionFactor();

	if (ReductionFactor == 1.0)
		return;

	if (Mode < 0)
		Mode = GetConVarInt(g_hCvar_AnnounceMode);

	if (Mode)
	{
		EngineVersion ServerVersion = GetEngineVersion();
		StatsPrintToChatTeam(TEAM_SURVIVORS, "\x03ALL SURVIVORS \x01now earns only \x04%i percent \x01of their normal points after using their \x05%i%s Medkit%s\x01!", RoundToNearest(ReductionFactor * 100), g_iMedkitsUsedCounter, (g_iMedkitsUsedCounter == 1 ? "st" : (g_iMedkitsUsedCounter == 2 ? "nd" : (g_iMedkitsUsedCounter == 3 ? "rd" : "th"))), (ServerVersion == Engine_Left4Dead ? "" : " or Defibrillator"));
	}
		
}

GetClientInfectedType(Client)
{
	if (Client > 0 && GetClientTeam(Client) == TEAM_INFECTED)
		return GetInfType(Client);

	return 0;
}

InitializeClientInf(Client)
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




public StartMapTiming()
{
	if (!MapTimingEnabled() || g_fMapTimingStartTime != 0.0 || StatsDisabled())
	{
		return;
	}

	g_fMapTimingStartTime = GetEngineTime();

	int ClientTeam, maxplayers = MaxClients;
	char ClientID[MAX_LINE_WIDTH];

	ClearTrie(g_hMapTimingSurvivors);
	ClearTrie(g_hMapTimingInfected);

	bool SoundsEnabled = g_bEnableSounds_Maptime_Start && GetConVarBool(g_hCvar_SoundsEnabled);

	for (int i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);

			if (ClientTeam == TEAM_SURVIVORS)
			{
				GetClientRankAuthString(i, ClientID, sizeof(ClientID));
				SetTrieValue(g_hMapTimingSurvivors, ClientID, 1, true);

				if (SoundsEnabled)
					EmitSoundToClient(i, g_sStatsSound_MapTime_Start);
			}
			else if (ClientTeam == TEAM_INFECTED)
			{
				GetClientRankAuthString(i, ClientID, sizeof(ClientID));
				SetTrieValue(g_hMapTimingInfected, ClientID, 1, true);
			}
		}
	}
}

public StopMapTiming()
{
	if (!MapTimingEnabled() || g_fMapTimingStartTime <= 0.0 || StatsDisabled())
	{
		return;
	}

	float TotalTime = GetEngineTime() - g_fMapTimingStartTime;
	g_fMapTimingStartTime = -1.0;
	g_bMapTimingBlocked = true;

	Handle dp = INVALID_HANDLE;
	int ClientTeam, enabled, maxplayers = MaxClients;
	char ClientID[MAX_LINE_WIDTH], MapName[MAX_LINE_WIDTH], query[512];

	GetCurrentMap(MapName, sizeof(MapName));

	int i, PlayerCounter = 0, InfectedCounter = (g_iCurrentGamemodeID == GAMEMODE_VERSUS || g_iCurrentGamemodeID == GAMEMODE_SCAVENGE ? 0 : 1);

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);
			GetClientRankAuthString(i, ClientID, sizeof(ClientID));

			if (ClientTeam == TEAM_SURVIVORS && GetTrieValue(g_hMapTimingSurvivors, ClientID, enabled))
			{
				if (enabled)
					PlayerCounter++;
			}
			else if (ClientTeam == TEAM_INFECTED)
			{
				InfectedCounter++;
				if (GetTrieValue(g_hMapTimingInfected, ClientID, enabled))
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

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);

			if (ClientTeam == TEAM_SURVIVORS)
			{
				GetClientRankAuthString(i, ClientID, sizeof(ClientID));

				if (GetTrieValue(g_hMapTimingSurvivors, ClientID, enabled))
				{
					if (enabled)
					{
						dp = CreateDataPack();

						WritePackString(dp, MapName);
						WritePackCell(dp, g_iCurrentGamemodeID);
						WritePackString(dp, ClientID);
						WritePackFloat(dp, TotalTime);
						WritePackCell(dp, i);
						WritePackCell(dp, PlayerCounter);
						WritePackCell(dp, GameDifficulty);
						WritePackString(dp, g_sCurrentMutation);

						Format(query, sizeof(query), "SELECT time FROM %stimedmaps WHERE map = '%s' AND gamemode = %i AND difficulty = %i AND mutation = '%s' AND steamid = '%s'", g_sDbPrefix, MapName, g_iCurrentGamemodeID, GameDifficulty, g_sCurrentMutation, ClientID);

						SQL_TQuery(db, UpdateMapTimingStat, query, dp);
					}
				}
 			}
		}
	}

	ClearTrie(g_hMapTimingSurvivors);
}

public DisplayRankVote(client)
{
    char question[128];
    strcopy(question, sizeof(question), RANKVOTE_QUESTION);
	DisplayYesNoPanel(client, question, RankVotePanelHandler, RoundToNearest(GetConVarFloat(g_hCvar_RankVoteTime)));
}

// Initialize RANKVOTE
public InitializeRankVote(client)
{
	if (StatsDisabled())
	{
		if (client == 0)
		{
			PrintToConsole(0, "[RANK] Cannot initiate vote when the plugin is disabled!");
		}
		else
		{
			StatsPrintToChatPreFormatted2(client, true, "Cannot initiate vote when the plugin is disabled!");
		}

		return;
	}

	// No TEAM gamemodes are allowed
	if (!IsTeamGamemode())
	{
		if (client == 0)
		{
			PrintToConsole(0, "[RANK] The Rank Vote is not enabled in this gamemode!");
		}
		else
		{
            EngineVersion ServerVersion = GetEngineVersion();
			if (ServerVersion == Engine_Left4Dead)
			{
				StatsPrintToChatPreFormatted2(client, true, "The \x04Rank Vote \x01is enabled in \x03Versus \x01gamemode!");
			}
			else
			{
				StatsPrintToChatPreFormatted2(client, true, "The \x04Rank Vote \x01is enabled in \x03Versus\x01, \x03Realism Versus \x01and \x03Scavenge \x01gamemodes!");
			}
		}

		return;
	}

	if (g_hRankVoteTimer != INVALID_HANDLE)
	{
		if (client > 0)
		{
			DisplayRankVote(client);
		}
		else
		{
			PrintToConsole(client, "[RANK] The Rank Vote is already initiated!");
		}

		return;
	}

	bool IsAdmin = (client > 0 ? ((GetUserFlagBits(client) & ADMFLAG_GENERIC) == ADMFLAG_GENERIC) : true);

	int team;
	char ClientID[MAX_LINE_WIDTH];

	if (!IsAdmin && client > 0 && GetTrieValue(g_hPlayerRankVoteTrie, ClientID, team))
	{
		StatsPrintToChatPreFormatted2(client, true, "You can initiate a \x04Rank Vote \x01only once per map!");
		return;
	}

	if (!IsAdmin && client > 0)
	{
		GetClientRankAuthString(client, ClientID, sizeof(ClientID));
		SetTrieValue(g_hPlayerRankVoteTrie, ClientID, 1, true);
	}

	g_hRankVoteTimer = CreateTimer(GetConVarFloat(g_hCvar_RankVoteTime), timer_RankVote);

	int i;

	for (i = 0; i <= MAXPLAYERS; i++)
	{
		g_iPlayerRankVote[i] = RANKVOTE_NOVOTE;
	}

	int maxplayers = MaxClients;

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			team = GetClientTeam(i);

			if (team == TEAM_SURVIVORS || team == TEAM_INFECTED)
			{
				DisplayRankVote(i);
			}
		}
	}

	if (client > 0)
	{
		char UserName[MAX_LINE_WIDTH];
		GetClientName(client, UserName, sizeof(UserName));

		StatsPrintToChatAll2(true, "The \x04Rank Vote \x01was initiated by \x05%s\x01!", UserName);
	}
	else
	{
		StatsPrintToChatAllPreFormatted2(true, "The \x04Rank Vote \x01was initiated from Server Console!");
	}
}

CheckSurvivorsAllDown()
{
	if (g_bCampaignOver ||
				g_iCurrentGamemodeID == GAMEMODE_COOP ||
				g_iCurrentGamemodeID == GAMEMODE_REALISM)
		return;

	int maxplayers = MaxClients;
	int ClientTeam;
	bool ClientIsAlive, ClientIsBot, ClientIsIncap;
	new KilledSurvivor[MaxClients];
	new AliveInfected[MaxClients];
	new Infected[MaxClients];
	int InfectedCounter = 0, AliveInfectedCounter = 0;
	int i;

	// Add to killing score on all incapacitated surviviors
	int IncapCounter = 0;

	for (i = 1; i <= maxplayers; i++)
	{
		if (!IsClientInGame(i))
			continue;

		ClientIsBot = IsClientBot(i);
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

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i) && IsClientInGame(i))
		{
			if (GetClientTeam(i) == TEAM_SURVIVORS)
				InterstitialPlayerUpdate(i);

			if (g_hTimerRankChangeCheck[i] != INVALID_HANDLE)
				TriggerTimer(g_hTimerRankChangeCheck[i], true);
		}
	}

	char query[1024];
	char ClientID[MAX_LINE_WIDTH];
	int Mode = GetConVarInt(g_hCvar_AnnounceMode);

	for (i = 0; i < AliveInfectedCounter; i++)
		DoInfectedFinalChecks(AliveInfected[i]);

	int Score = ModifyScoreDifficultyFloat(GetConVarInt(g_hCvar_VictoryInfectedScore), 0.75, 0.5, TEAM_INFECTED) * IncapCounter;

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

	if (!GetConVarBool(g_hCvar_EnableNegativeScore))
		return;

	if (g_iCurrentGamemodeID == GAMEMODE_VERSUS)
	{
		Score = ModifyScoreDifficultyFloatNR(GetConVarInt(g_hCvar_ActionScore[ACT_RESTART]), 0.75, 0.5, TEAM_SURVIVORS);
	}
	else if (g_iCurrentGamemodeID == GAMEMODE_REALISMVERSUS)
	{
		Score = ModifyScoreDifficultyFloatNR(GetConVarInt(g_hCvar_ActionScore[ACT_RESTART]), 0.6, 0.3, TEAM_SURVIVORS);
	}
	else
	{
		Score = ModifyScoreDifficultyNR(GetConVarInt(g_hCvar_ActionScore[ACT_RESTART]), 2, 3, TEAM_SURVIVORS);
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

public UpdateSmokerDamage(Client, Damage)
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

public UpdateSpitterDamage(Client, Damage)
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

public UpdateJockeyDamage(Client, Damage)
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

UpdateJockeyRideLength(Client, float RideLength=-1.0)
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

public UpdateChargerDamage(Client, Damage)
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
	if (g_iCurrentGamemodeID == GAMEMODE_SCAVENGE ||
			g_iCurrentGamemodeID == GAMEMODE_SURVIVAL)
		return;

	int Score = ModifyScoreDifficulty(GetConVarInt(g_hCvar_NotDisturbingWitchScore), 5, 10, TEAM_SURVIVORS);
	int Mode = GetConVarInt(g_hCvar_AnnounceMode);
	char iID[MAX_LINE_WIDTH];
	char query[1024];
	int maxplayers = MaxClients;
	char UpdatePoints[32], UpdatePointsPenalty[32];
	int ClientTeam;
	bool NegativeScore = GetConVarBool(g_hCvar_EnableNegativeScore);

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
		for (int i = 1; i <= maxplayers; i++)
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
	int BaseScore = ModifyScoreDifficulty(GetConVarInt(g_hCvar_ReachedSafeHouseScore), 2, 5, TEAM_SURVIVORS);

	for (int i = 1; i <= maxplayers; i++)
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

	for (int i = 1; i <= maxplayers; i++)
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

			if (g_hTimerRankChangeCheck[i] != INVALID_HANDLE)
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

ResetInfVars()
{
	int i;

	// Reset all Infected variables
	for (i = 0; i < MAXPLAYERS + 1; i++)
	{
		g_iBoomerHitCounter[i] = 0;
		g_iBoomerVomitUpdated[i] = false;
		g_iInfectedDamageCounter[i] = 0;
		g_iSmokerDamageCounter[i] = 0;
		g_iSpitterDamageCounter[i] = 0;
		g_iJockeyDamageCounter[i] = 0;
		g_iChargerDamageCounter[i] = 0;
		g_iChargerImpactCounter[i] = 0;
		TankPointsCounter[i] = 0;
		TankDamageCounter[i] = 0;
		g_iClientInfectedType[i] = 0;
		TankSurvivorKillCounter[i] = 0;
		TankDamageTotalCounter[i] = 0;
		g_iChargerCarryVictim[i] = 0;
		g_iChargerPlummelVictim[i] = 0;
		g_iJockeyVictim[i] = 0;
		g_iJockeyRideStartTime[i] = 0;

		g_iPlayerBlinded[i][0] = 0;
		g_iPlayerBlinded[i][1] = 0;
		g_iPlayerParalyzed[i][0] = 0;
		g_iPlayerParalyzed[i][1] = 0;
		g_iPlayerLunged[i][0] = 0;
		g_iPlayerLunged[i][1] = 0;
		g_iPlayerPummeled[i][0] = 0;
		g_iPlayerPummeled[i][1] = 0;
		g_iPlayerCarried[i][0] = 0;
		g_iPlayerCarried[i][1] = 0;
		g_iPlayerJockied[i][0] = 0;
		g_iPlayerJockied[i][1] = 0;

		g_hTimerBoomerPerfectCheck[i] = INVALID_HANDLE;
		g_hTimerInfectedDamageCheck[i] = INVALID_HANDLE;

		g_hTimerProtectedFriendly[i] = INVALID_HANDLE;
		g_iProtectedFriendlyCounter[i] = 0;

		if (g_hChargerImpactCounterTimer[i] != INVALID_HANDLE)
		{
			CloseHandle(g_hChargerImpactCounterTimer[i]);
		}

		g_hChargerImpactCounterTimer[i] = INVALID_HANDLE;
	}
}

ResetVars()
{
	ClearTrie(g_hFriendlyFireDamageTrie);
	ClearTrie(g_hPlayerRankVoteTrie);

	g_bPlayerVomited = false;
	g_bPlayerVomitedIncap = false;
	g_bPanicEvent = false;
	g_bPanicEventIncap = false;
	g_bCampaignOver = false;
	g_bWitchExists = false;
	g_bWitchDisturb = false;
	g_iMedkitsUsedCounter = 0;

	// Reset kill/point score timer amount
	CreateTimer(1.0, InitPlayers);

	g_iTankCount = 0;

	int i, j, maxplayers = MaxClients;
	for (i = 1; i <= maxplayers; i++)
	{
		g_iAnnounceCounter[i] = 0;
		g_iCurrentPoints[i] = 0;
		g_bClientRankMute[i] = false;
	}

	for (i = 0; i < MAXPLAYERS + 1; i++)
	{
		if (g_hTimerRankChangeCheck[i] != INVALID_HANDLE)
			CloseHandle(g_hTimerRankChangeCheck[i]);

		g_hTimerRankChangeCheck[i] = INVALID_HANDLE;

		for (j = 0; j < MAXPLAYERS + 1; j++)
		{
			g_bFriendlyFireCooldown[i][j] = false;
			g_hFriendlyFireTimer[i][j] = INVALID_HANDLE;
		}

		if (g_hMeleeKillTimer[i] != INVALID_HANDLE)
			CloseHandle(g_hMeleeKillTimer[i]);
		g_hMeleeKillTimer[i] = INVALID_HANDLE;
		g_iMeleeKillCounter[i] = 0;

		g_iPostAdminCheckRetryCounter[i] = 0;
	}

	ResetInfVars();
}

public ResetRankChangeCheck()
{
	int maxplayers = MaxClients;

	for (int i = 1; i <= maxplayers; i++)
		StartRankChangeCheck(i);
}

public StartRankChangeCheck(Client)
{
	if (g_hTimerRankChangeCheck[Client] != INVALID_HANDLE)
		CloseHandle(g_hTimerRankChangeCheck[Client]);

	g_hTimerRankChangeCheck[Client] = INVALID_HANDLE;

	if (Client == 0 || IsClientBot(Client))
		return;

	g_bRankChangeFirstCheck[Client] = true;
	DoShowRankChange(Client);
	g_hTimerRankChangeCheck[Client] = CreateTimer(GetConVarFloat(g_hCvar_AnnounceRankChangeIVal), timer_ShowRankChange, Client, TIMER_REPEAT);
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

HunterSmokerSave(Savior, Victim, BasePoints, AdvMult, ExpertMult, char[] SaveFrom, char[] SQLField)
{
	if (StatsDisabled())
		return;

	if (IsClientBot(Savior) || IsClientBot(Victim))
		return;

	int Mode = GetConVarInt(g_hCvar_AnnounceMode);

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

	int Score = ModifyScoreDifficulty(BasePoints, AdvMult, ExpertMult, TEAM_SURVIVORS);
	char UpdatePoints[32];

	switch (g_iCurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
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

public ExecuteTeamShuffle(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("ExecuteTeamShuffle failed! Reason: %s", error);
		return;
	}

	char SteamID[MAX_LINE_WIDTH];
	int i, team, maxplayers = MaxClients, client, topteam;
	int SurvivorsLimit = GetConVarInt(g_hCvar_SurvivorLimit), InfectedLimit = GetConVarInt(g_hCvar_InfectedLimit);
	Handle PlayersTrie = CreateTrie();
	Handle InfectedArray = CreateArray();
	Handle SurvivorArray = CreateArray();

	for (i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			GetClientRankAuthString(i, SteamID, sizeof(SteamID));

			if (!SetTrieValue(PlayersTrie, SteamID, i, false))
			{
				LogError("ExecuteTeamShuffle failed! Reason: Duplicate SteamID while generating shuffled teams.");
				StatsPrintToChatAllPreFormatted2(true, "Team shuffle failed in an error.");

				SetConVarBool(g_hCvar_EnableRankVote, false);

				ClearTrie(PlayersTrie);
				CloseHandle(PlayersTrie);

				CloseHandle(hndl);

				return;
			}

			switch (GetClientTeam(i))
			{
				case TEAM_SURVIVORS:
					PushArrayCell(SurvivorArray, i);
				case TEAM_INFECTED:
					PushArrayCell(InfectedArray, i);
			}
		}
	}

	int SurvivorCounter = GetArraySize(SurvivorArray);
	int InfectedCounter = GetArraySize(InfectedArray);

	i = 0;
	topteam = 0;

	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, SteamID, sizeof(SteamID));

		if (GetTrieValue(PlayersTrie, SteamID, client))
		{
			team = GetClientTeam(client);

			if (i == 0)
			{
				if (team == TEAM_SURVIVORS)
				{
					RemoveFromArray(SurvivorArray, FindValueInArray(SurvivorArray, client));
				}
				else
				{
					RemoveFromArray(InfectedArray, FindValueInArray(InfectedArray, client));
				}

				topteam = team;
				i++;

				continue;
			}

			if (i++ % 2)
			{
				if (topteam == TEAM_SURVIVORS && team == TEAM_INFECTED)
				{
					RemoveFromArray(InfectedArray, FindValueInArray(InfectedArray, client));
				}
				else if (topteam == TEAM_INFECTED && team == TEAM_SURVIVORS)
				{
					RemoveFromArray(SurvivorArray, FindValueInArray(SurvivorArray, client));
				}
			}
			else
			{
				if (topteam == TEAM_SURVIVORS && team == TEAM_SURVIVORS)
				{
					RemoveFromArray(SurvivorArray, FindValueInArray(SurvivorArray, client));
				}
				else if (topteam == TEAM_INFECTED && team == TEAM_INFECTED)
				{
					RemoveFromArray(InfectedArray, FindValueInArray(InfectedArray, client));
				}
			}
		}
	}

	if (GetArraySize(SurvivorArray) > 0 || GetArraySize(InfectedArray) > 0)
	{
		new NewSurvivorCounter = SurvivorCounter - GetArraySize(SurvivorArray) + GetArraySize(InfectedArray);
		new NewInfectedCounter = InfectedCounter - GetArraySize(InfectedArray) + GetArraySize(SurvivorArray);

		if (NewSurvivorCounter > SurvivorsLimit || NewInfectedCounter > InfectedLimit)
		{
			LogError("ExecuteTeamShuffle failed! Reason: Team size limits block Rank Vote functionality. (Survivors Limit = %i [%i] / Infected Limit = %i [%i])", SurvivorsLimit, NewSurvivorCounter, InfectedLimit, NewInfectedCounter);
			StatsPrintToChatAllPreFormatted2(true, "Team shuffle failed in an error.");

			SetConVarBool(g_hCvar_EnableRankVote, false);
		}
		else
		{
			g_bCampaignOver = true;

			char Name[32];

			// Change Survivors team to Spectators (TEMPORARILY)
			for (i = 0; i < GetArraySize(SurvivorArray); i++)
			{
				ChangeRankPlayerTeam(GetArrayCell(SurvivorArray, i), TEAM_SPECTATORS);
			}

			// Change Infected team to Survivors
			for (i = 0; i < GetArraySize(InfectedArray); i++)
			{
				client = GetArrayCell(InfectedArray, i);
				GetClientName(client, Name, sizeof(Name));

				ChangeRankPlayerTeam(client, TEAM_SURVIVORS);

				StatsPrintToChatAll2(true, "\x05%s \x01was swapped to team \x03Survivors\x01!", Name);
			}

			// Change Spectators (TEMPORARILY) team to Infected
			for (i = 0; i < GetArraySize(SurvivorArray); i++)
			{
				client = GetArrayCell(SurvivorArray, i);
				GetClientName(client, Name, sizeof(Name));

				ChangeRankPlayerTeam(client, TEAM_INFECTED);

				StatsPrintToChatAll2(true, "\x05%s \x01was swapped to team \x03Infected\x01!", Name);
			}

			StatsPrintToChatAllPreFormatted2(true, "Team shuffle by player PPM \x03DONE\x01.");

			if (g_bEnableSounds_Rankvote && GetConVarBool(g_hCvar_SoundsEnabled))
				EmitSoundToAll(SOUND_RANKVOTE);
		}
	}
	else
	{
		StatsPrintToChatAllPreFormatted2(true, "Teams are already even by player PPM.");
	}

	ClearArray(SurvivorArray);
	ClearArray(InfectedArray);
	ClearTrie(PlayersTrie);

	CloseHandle(SurvivorArray);
	CloseHandle(InfectedArray);
	CloseHandle(PlayersTrie);

	CloseHandle(hndl);
}

public StartRankVote(client)
{
	if (!GetConVarBool(g_hCvar_EnableRankVote))
	{
		if (client > 0) StatsPrintToChatPreFormatted(client, "The \x04Rank Vote \x01is \x03DISABLED\x01.");
		else PrintToConsole(0, "[RANK] The Rank Vote is DISABLED.");
	}

	else
		InitializeRankVote(client);
}

bool DoFastQuery(Client, const char[] Query, any ...)
{
	char FormattedQuery[4096];
	VFormat(FormattedQuery, sizeof(FormattedQuery), Query, 3);

	char Error[1024];

	if (!SQL_FastQuery(db, FormattedQuery))
	{
		if (SQL_GetError(db, Error, sizeof(Error)))
		{
			PrintToConsole(Client, "[RANK] Fast query failed! (Error = \"%s\") Query = \"%s\"", Error, FormattedQuery);
			LogError("Fast query failed! (Error = \"%s\") Query = \"%s\"", Error, FormattedQuery);
		}
		else
		{
			PrintToConsole(Client, "[RANK] Fast query failed! Query = \"%s\"", FormattedQuery);
			LogError("Fast query failed! Query = \"%s\"", FormattedQuery);
		}

		return false;
	}

	return true;
}

// Update a player's stats, used for interstitial updating.

void InterstitialPlayerUpdate(int client)
{
	char ClientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, ClientID, sizeof(ClientID));

	char UpdatePoints[32];

	switch (g_iCurrentGamemodeID)
	{
		case GAMEMODE_VERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survivors");
		}
		case GAMEMODE_REALISM:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism");
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_survival");
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_scavenge_survivors");
		}
		case GAMEMODE_REALISMVERSUS:
		{
			Format(UpdatePoints, sizeof(UpdatePoints), "points_realism_survivors");
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

	int len = 0;
	char query[1024];
	len += Format(query[len], sizeof(query)-len, "UPDATE %splayers SET %s = %s + %i, ", g_sDbPrefix, UpdatePoints, UpdatePoints, g_iTimerPoints[client]);
	len += Format(query[len], sizeof(query)-len, "kills = kills + %i, kill_infected = kill_infected + %i, ", g_iTimerKills[client], g_iTimerKills[client]);
	len += Format(query[len], sizeof(query)-len, "headshots = headshots + %i ", g_iTimerHeadshots[client]);
	len += Format(query[len], sizeof(query)-len, "WHERE steamid = '%s'", ClientID);
	SendSQLUpdate(query);

	UpdateMapStat("kills", g_iTimerKills[client]);
	UpdateMapStat("points", g_iTimerPoints[client]);

	AddScore(client, g_iTimerPoints[client]);
}



public ClearStatsMaps(client)
{
	if (!DoFastQuery(client, "START TRANSACTION"))
		return;

	char query[256];
	Format(query, sizeof(query), "SELECT * FROM %smaps WHERE 1 = 2", g_sDbPrefix);

	SQL_TQuery(db, ClearStatsMapsHandler, query, client);
}

public ClearStatsAll(client)
{
	if (!DoFastQuery(client, "START TRANSACTION"))
	{
		return;
	}

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

public ClearStatsPlayers(client)
{
	if (!DoFastQuery(client, "START TRANSACTION"))
	{
		return;
	}

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
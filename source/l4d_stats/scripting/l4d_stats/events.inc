#if defined _l4d_stats_events_included
 #endinput
#endif
#define _l4d_stats_events_included

void HookEvents()
{
	// Personal Gain Events
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("infected_death", Event_InfectedDeath);
	HookEvent("tank_killed", Event_TankKilled);

	if (g_bLeft4Dead) HookEvent("weapon_given", Event_GivePills);
	else if (g_bLeft4Dead2) HookEvent("defibrillator_used", Event_DefibPlayer);

	HookEvent("heal_success", Event_HealPlayer);
	HookEvent("revive_success", Event_RevivePlayer);
	HookEvent("tongue_pull_stopped", Event_TongueSave);
	HookEvent("choke_stopped", Event_ChokeSave);
	HookEvent("pounce_stopped", Event_PounceSave);
	HookEvent("lunge_pounce", Event_PlayerPounced);
	HookEvent("player_ledge_grab", Event_PlayerLedge);
	HookEvent("player_falldamage", Event_PlayerFallDamage);
	HookEvent("melee_kill", Event_MeleeKill);

	// Personal Loss Events
	HookEvent("friendly_fire", Event_FriendlyFire);
	HookEvent("player_incapacitated", Event_PlayerIncap);

	// Team Gain Events
	HookEvent("finale_vehicle_leaving", Event_CampaignWin);
	HookEvent("map_transition", Event_MapTransition, EventHookMode_PostNoCopy);
	HookEvent("create_panic_event", Event_PanicEvent, EventHookMode_PostNoCopy);
	HookEvent("player_now_it", Event_PlayerBlind);
	HookEvent("player_no_longer_it", Event_PlayerBlindEnd);

	// Team Loss Events / Misc. Events
	if (g_bLeft4Dead2) HookEvent("award_earned", Event_Award_L4D1);
	else if (g_bLeft4Dead2) HookEvent("award_earned", Event_Award_L4D2);

	HookEvent("witch_spawn", Event_WitchSpawn, EventHookMode_PostNoCopy);
	HookEvent("witch_killed", Event_WitchCrowned);
	HookEvent("witch_harasser_set", Event_WitchDisturb);
	HookEvent("round_start", Event_RoundStart);

	// Record player positions when an ability is used
	HookEvent("ability_use", Event_AbilityUse);

	// Set player specific counters (BoomerHitCounter etc)
	HookEvent("player_spawn", Event_PlayerSpawn);

	// Set player specific counters (BoomerHitCounter etc)
	HookEvent("player_hurt", Event_PlayerHurt);

	// Smoker stats
	HookEvent("tongue_grab", Event_SmokerGrap);
	HookEvent("tongue_release", Event_SmokerRelease);

	if (g_bLeft4Dead) HookEvent("tongue_broke_victim_died", Event_SmokerRelease);
    
	HookEvent("choke_end", Event_SmokerRelease);
	HookEvent("tongue_broke_bent", Event_SmokerRelease);
	// Hooked previously ^
	//HookEvent("choke_stopped", Event_SmokerRelease);
	//HookEvent("tongue_pull_stopped", Event_SmokerRelease);

	// Hunter stats
	HookEvent("pounce_end", Event_HunterRelease);

	if (g_bLeft4Dead2)
	{
		// Spitter stats
		//HookEvent("spitter_killed", event_SpitterKilled);

		// Jockey stats
		HookEvent("jockey_ride", Event_JockeyStart);
		HookEvent("jockey_ride_end", Event_JockeyRelease);
		HookEvent("jockey_killed", Event_JockeyKilled);

		// Charger stats
		HookEvent("charger_impact", Event_ChargerImpact);
		HookEvent("charger_killed", Event_ChargerKilled);
		HookEvent("charger_carry_start", Event_ChargerCarryStart);
		HookEvent("charger_carry_end", Event_ChargerCarryRelease);
		HookEvent("charger_pummel_start", Event_ChargerPummelStart);
		HookEvent("charger_pummel_end", Event_ChargerPummelRelease);

		// Misc L4D2 events
		HookEvent("upgrade_pack_used", Event_UpgradePackAdded);
		HookEvent("gascan_pour_completed", Event_GascanPoured);
		HookEvent("triggered_car_alarm", Event_CarAlarm, EventHookMode_PostNoCopy);
		HookEvent("survival_round_start", Event_SurvivalStart, EventHookMode_PostNoCopy); // Timed Maps event
		HookEvent("scavenge_round_halftime", Event_ScavengeHalftime, EventHookMode_PostNoCopy);
		HookEvent("scavenge_round_start", Event_ScavengeRoundStart, EventHookMode_PostNoCopy);
	}

	// Achievements
	HookEvent("achievement_earned", Event_Achievement);

	// Timed Maps events
	HookEvent("door_open", Event_DoorOpen, EventHookMode_Post); // When the saferoom door opens...
	HookEvent("player_left_start_area", Event_StartArea, EventHookMode_PostNoCopy); // When a survivor leaves the start area...
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post); // When a survivor changes team...
}

// Scavenge round start event (occurs when door opens or players leave the start area)
void Event_ScavengeRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	OnRoundStart();
	StartMapTiming();
}

// Called after the connection to the database is established
void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	OnRoundStart();
}

void OnRoundStart()
{
	ResetVars();
	CheckCurrentMapDB();

	g_fMapTimingStartTime = 0.0;
	g_bMapTimingBlocked = false;

	ResetRankChangeCheck();
}

// Player Death event. Used for killing AI Infected. +2 on headshot, and global announcement.
// Team Kill code is in the awards section. Tank Kill code is in Tank section.
void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled() || g_bCampaignOver)
		return;

	int Attacker = GetClientOfUserId(event.GetInt("attacker"));
	int Victim = GetClientOfUserId(event.GetInt("userid"));
	bool AttackerIsBot = event.GetBool("attackerisbot");
	bool VictimIsBot = event.GetBool("victimisbot");
	int VictimTeam = -1;

	// Self inflicted death does not count
	if (Attacker == Victim)
		return;

	if (!VictimIsBot)
		DoInfectedFinalChecks(Victim, g_iClientInfectedType[Victim]);

	if (Victim > 0)
		VictimTeam = GetClientTeam(Victim);

	if (Attacker == 0 || AttackerIsBot)
	{
		// Attacker is normal indected but the Victim was infected by blinding and/or paralysation.
		if (Attacker == 0
				&& VictimTeam == TEAM_SURVIVORS
				&& (g_iPlayerBlinded[Victim][0] && g_iPlayerBlinded[Victim][1]
					|| g_iPlayerParalyzed[Victim][0] && g_iPlayerParalyzed[Victim][1]
					|| g_iPlayerLunged[Victim][0] && g_iPlayerLunged[Victim][1]
					|| g_iPlayerCarried[Victim][0] && g_iPlayerCarried[Victim][1]
					|| g_iPlayerPummeled[Victim][0] && g_iPlayerPummeled[Victim][1]
					|| g_iPlayerJockied[Victim][0] && g_iPlayerJockied[Victim][1])
				&& IsGamemodeVersus())
			PlayerDeathExternal(Victim);

		if (g_iCurrentGamemodeID == GAMEMODE_SURVIVAL && Victim > 0 && VictimTeam == TEAM_SURVIVORS)
			CheckSurvivorsAllDown();

		return;
	}

	int Mode = g_hCvar_AnnounceMode.IntValue;
	int AttackerTeam = GetClientTeam(Attacker);
	char AttackerName[MAX_LINE_WIDTH];
	char AttackerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Attacker, AttackerID, sizeof(AttackerID));
	char VictimName[MAX_LINE_WIDTH];
	int VictimInfType = -1;

	if (Victim > 0)
	{
		GetClientName(Victim, VictimName, sizeof(VictimName));

		if (VictimTeam == TEAM_INFECTED)
			VictimInfType = GetInfType(Victim);
	}
	else
	{
		event.GetString("victimname", VictimName, sizeof(VictimName));

		if (StrEqual(VictimName, "hunter", false))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_HUNTER;
		}
		else if (StrEqual(VictimName, "smoker", false))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_SMOKER;
		}
		else if (StrEqual(VictimName, "boomer", false))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_BOOMER;
		}
		if (StrEqual(VictimName, "spitter", false))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_SPITTER_L4D2;
		}
		else if (StrEqual(VictimName, "jockey", false))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_JOCKEY_L4D2;
		}
		else if (StrEqual(VictimName, "charger", false))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_CHARGER_L4D2;
		}
		else if (StrEqual(VictimName, "tank", false))
		{
			VictimTeam = TEAM_INFECTED;
			VictimInfType = INF_ID_TANK_L4D2;
		}
		else
			return;
	}

	// The wearoff should now work properly! Don't initialize
	//if (Victim > 0 && (VictimInfType == INF_ID_HUNTER || VictimInfType == INF_ID_SMOKER))
	//	InitializeClientInf(Victim);

	if (VictimTeam == TEAM_SURVIVORS)
		CheckSurvivorsAllDown();

	// Team Kill: Attacker is a Survivor and Victim is Survivor
	if (AttackerTeam == TEAM_SURVIVORS && VictimTeam == TEAM_SURVIVORS)
	{
		int Score = 0;
		if (g_hCvar_EnableNegativeScore.BoolValue)
		{
			if (!IsClientBot(Victim))
				Score = ModifyScoreDifficultyNR(g_hCvar_ActionScore[ACT_FFKILL].IntValue, 2, 4, TEAM_SURVIVORS);
			else
			{
				float BotScoreMultiplier = g_hCvar_BotScoreMultiplier.FloatValue;

				if (BotScoreMultiplier > 0.0)
					Score = RoundToNearest(ModifyScoreDifficultyNR(g_hCvar_ActionScore[ACT_FFKILL].IntValue, 2, 4, TEAM_SURVIVORS) * BotScoreMultiplier);
			}
		}
		else
			Mode = 0;

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
		Format(query, sizeof(query), "UPDATE %splayers SET %s = %s - %i, award_teamkill = award_teamkill + 1 WHERE steamid = '%s'", g_sDbPrefix, UpdatePoints, UpdatePoints, Score, AttackerID);

		SendSQLUpdate(query);

		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(Attacker, "You have {lightgreen}LOST {green}%i {default}points for {lightgreen}Team Killing {olive}%s{default}!", Score, VictimName);
		else if (Mode == 3)
			StatsPrintToChatAll("{olive}%s {default}has {lightgreen}LOST {green}%i {default}points for {lightgreen}Team Killing {olive}%s{default}!", AttackerName, Score, VictimName);
	}

	// Attacker is a Survivor
	else if (AttackerTeam == TEAM_SURVIVORS && VictimTeam == TEAM_INFECTED)
	{
		new Score = 0;
		char InfectedType[8];

		if (VictimInfType == INF_ID_HUNTER)
		{
			Format(InfectedType, sizeof(InfectedType), "hunter");
			Score = ModifyScoreDifficultyNR(g_hCvar_KillInfectedClassScore[CLASS_HUNTER].IntValue, 2, 3, TEAM_SURVIVORS);
		}
		else if (VictimInfType == INF_ID_SMOKER)
		{
			Format(InfectedType, sizeof(InfectedType), "smoker");
			Score = ModifyScoreDifficultyNR(g_hCvar_KillInfectedClassScore[CLASS_SMOKER].IntValue, 2, 3, TEAM_SURVIVORS);
		}
		else if (VictimInfType == INF_ID_BOOMER)
		{
			Format(InfectedType, sizeof(InfectedType), "boomer");
			Score = ModifyScoreDifficultyNR(g_hCvar_KillInfectedClassScore[CLASS_BOOMER].IntValue, 2, 3, TEAM_SURVIVORS);
		}
		else if (VictimInfType == INF_ID_SPITTER_L4D2)
		{
			Format(InfectedType, sizeof(InfectedType), "spitter");
			Score = ModifyScoreDifficultyNR(g_hCvar_KillInfectedClassScore[CLASS_SPITTER].IntValue, 2, 3, TEAM_SURVIVORS);
		}
		else if (VictimInfType == INF_ID_JOCKEY_L4D2)
		{
			Format(InfectedType, sizeof(InfectedType), "jockey");
			Score = ModifyScoreDifficultyNR(g_hCvar_KillInfectedClassScore[CLASS_JOCKEY].IntValue, 2, 3, TEAM_SURVIVORS);
		}
		else if (VictimInfType == INF_ID_CHARGER_L4D2)
		{
			Format(InfectedType, sizeof(InfectedType), "charger");
			Score = ModifyScoreDifficultyNR(g_hCvar_KillInfectedClassScore[CLASS_CHARGER].IntValue, 2, 3, TEAM_SURVIVORS);
		}
		else
			return;

		char Headshot[32];
		if (event.GetBool("headshot"))
		{
			Format(Headshot, sizeof(Headshot), ", headshots = headshots + 1");
			Score = Score + 2;
		}

		Score = GetMedkitPointReductionScore(Score);
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

		int len = 0;
		char query[1024];
		len += Format(query[len], sizeof(query)-len, "UPDATE %splayers SET %s = %s + %i, ", g_sDbPrefix, UpdatePoints, UpdatePoints, Score);
		len += Format(query[len], sizeof(query)-len, "kills = kills + 1, kill_%s = kill_%s + 1", InfectedType, InfectedType);
		len += Format(query[len], sizeof(query)-len, "%s WHERE steamid = '%s'", Headshot, AttackerID);
		SendSQLUpdate(query);

		if (Mode && Score > 0)
		{
			if (event.GetBool("headshot"))
			{
				if (Mode > 1)
				{
					GetClientName(Attacker, AttackerName, sizeof(AttackerName));
					StatsPrintToChatAll("{olive}%s {default}has earned {green}%i {default}points for killing%s {olive}%s {default}with a {green}HEAD SHOT{default}!", AttackerName, Score, (VictimIsBot ? " a" : ""), VictimName);
				}
				else
					StatsPrintToChat(Attacker, "You have earned {green}%i {default}points for killing%s {olive}%s {default}with a {green}HEAD SHOT{default}!", Score, (VictimIsBot ? " a" : ""), VictimName);
			}
			else
			{
				if (Mode > 2)
				{
					GetClientName(Attacker, AttackerName, sizeof(AttackerName));
					StatsPrintToChatAll("{olive}%s {default}has earned {green}%i {default}points for killing%s {olive}%s{default}!", AttackerName, Score, (VictimIsBot ? " a" : ""), VictimName);
				}
				else
					StatsPrintToChat(Attacker, "You have earned {green}%i {default}points for killing%s {olive}%s{default}!", Score, (VictimIsBot ? " a" : ""), VictimName);
			}
		}

		UpdateMapStat("kills", 1);
		UpdateMapStat("points", Score);
		AddScore(Attacker, Score);
	}

	// Attacker is an Infected
	else if (AttackerTeam == TEAM_INFECTED && VictimTeam == TEAM_SURVIVORS)
		SurvivorDiedNamed(Attacker, Victim, VictimName, AttackerID, -1, Mode);

	if (VictimTeam == TEAM_SURVIVORS)
	{
		if (g_bPanicEvent)
			g_bPanicEventIncap = true;

		if (g_bPlayerVomited)
			g_bPlayerVomitedIncap = true;
	}
}

// Common Infected death code. +1 on headshot.
void Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled() || g_bCampaignOver)
		return;

	int Attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (!Attacker || IsClientBot(Attacker) || GetClientTeam(Attacker) == TEAM_INFECTED)
		return;

	int Score = ModifyScoreDifficultyNR(g_hCvar_KillInfectedClassScore[CLASS_COMMON].IntValue, 2, 3, TEAM_SURVIVORS);

	if (event.GetBool("headshot"))
	{
		Score = Score + 1;
		g_iTimerHeadshots[Attacker] = g_iTimerHeadshots[Attacker] + 1;
	}

	g_iTimerPoints[Attacker] = g_iTimerPoints[Attacker] + Score;
	g_iTimerKills[Attacker] = g_iTimerKills[Attacker] + 1;

	// Melee?
	if (g_bLeft4Dead2)
	{
		int WeaponID = event.GetInt("weapon_id");

		if (WeaponID == 19)
			IncrementMeleeKills(Attacker);
	}

	//char AttackerName[MAX_LINE_WIDTH];
	//GetClientName(Attacker, AttackerName, sizeof(AttackerName));

	//LogMessage("[DEBUG] %s killed an infected (Weapon ID: %i)", AttackerName, WeaponID);
	//PrintToConsoleAll("[DEBUG] %s killed an infected (Weapon ID: %i)", AttackerName, WeaponID);
}

// Tank death code. Points are given to all players.
void Event_TankKilled(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled() || g_bCampaignOver)
		return;

	if (g_iTankCount >= 3)
		return;

	int BaseScore = ModifyScoreDifficulty(g_hCvar_KillTankScore.IntValue, 2, 4, TEAM_SURVIVORS);
	int Mode = g_hCvar_AnnounceMode.IntValue;
	int Deaths = 0;
	int Players = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			Players++;

			if (!IsPlayerAlive(i))
				Deaths++;
		}
	}

	// This was proposed by AlliedModders users el_psycho and PatriotGames (Thanks!)
	int Score = (BaseScore * ((Players - Deaths) / Players)) / Players;

	char UpdatePoints[32];
	FormatInGameMode(UpdatePoints, sizeof(UpdatePoints));

	char iID[MAX_LINE_WIDTH];
	char query[512];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i) && GetClientTeam(i) == TEAM_SURVIVORS)
		{
			GetClientRankAuthString(i, iID, sizeof(iID));
			Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_tankkill = award_tankkill + 1 WHERE steamid = '%s'", g_sDbPrefix, UpdatePoints, UpdatePoints, Score, iID);
			SendSQLUpdate(query);

			AddScore(i, Score);
		}
	}

	if (Mode && Score > 0)
		StatsPrintToChatTeam(TEAM_SURVIVORS, "{lightgreen}ALL SURVIVORS {default}have earned {green}%i {default}points for killing a Tank with {olive}%i Deaths{default}!", Score, Deaths);

	UpdateMapStat("kills", 1);
	UpdateMapStat("points", Score);
	g_iTankCount = g_iTankCount + 1;
}

// Pill give event. (From give a weapon)
void Event_GivePills(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled())
		return;

	// If given weapon != 12 (Pain g_iPillsIndex) then return
	if (event.GetInt("weapon") != 12)
		return;

	if (g_iCurrentGamemodeID == GAMEMODE_SURVIVAL && !g_hCvar_EnableSurvivalMedicPoints.BoolValue)
		return;

	int Recipient = GetClientOfUserId(event.GetInt("userid"));
	int Giver = GetClientOfUserId(event.GetInt("giver"));
	int PillsIndex = event.GetInt("weaponentid");

	GivePills(Giver, Recipient, PillsIndex);
}

// Defibrillator used code.
void Event_DefibPlayer(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled() || g_bCampaignOver)
		return;

	if (g_iCurrentGamemodeID == GAMEMODE_SURVIVAL && (!g_bSurvivalStarted || !g_hCvar_EnableSurvivalMedicPoints.BoolValue))
		return;

	int Recipient = GetClientOfUserId(event.GetInt("subject"));
	int Giver = GetClientOfUserId(event.GetInt("userid"));

	bool GiverIsBot = IsClientBot(Giver);
	bool RecipientIsBot = IsClientBot(Recipient);

	if (g_iCurrentGamemodeID != GAMEMODE_SURVIVAL && (!GiverIsBot || (GiverIsBot && (g_hCvar_MedkitBotMode.IntValue >= 2 || (!RecipientIsBot && g_hCvar_MedkitBotMode.IntValue >= 1)))))
	{
		g_iMedkitsUsedCounter++;
		AnnounceMedkitPenalty();
	}

	if (IsClientBot(Giver))
		return;

	// How is this possible?
	if (Recipient == Giver)
		return;

	char RecipientName[MAX_LINE_WIDTH];
	GetClientName(Recipient, RecipientName, sizeof(RecipientName));
	char RecipientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Recipient, RecipientID, sizeof(RecipientID));

	char GiverName[MAX_LINE_WIDTH];
	GetClientName(Giver, GiverName, sizeof(GiverName));
	char GiverID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Giver, GiverID, sizeof(GiverID));

	int Score = ModifyScoreDifficulty(g_hCvar_GiveItemClassScore[ITEM_DEFIB].IntValue, 2, 4, TEAM_SURVIVORS);

	char UpdatePoints[32];
	FormatInGameMode(UpdatePoints, sizeof(UpdatePoints));

	char query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_defib = award_defib + 1 WHERE steamid = '%s'", g_sDbPrefix, UpdatePoints, UpdatePoints, Score, GiverID);
	SendSQLUpdate(query);

	UpdateMapStat("points", Score);
	AddScore(Giver, Score);

	if (Score > 0)
	{
		int Mode = g_hCvar_AnnounceMode.IntValue;
		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(Giver, "You have earned {green}%i {default}points for Reviving {olive}%s{default} using a Defibrillator!", Score, RecipientName);
		else if (Mode == 3)
			StatsPrintToChatAll("{olive}%s {default}has earned {green}%i {default}points for Reviving {olive}%s{default} using a Defibrillator!", GiverName, Score, RecipientName);
	}
}

// Medkit give code.
void Event_HealPlayer(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled() || g_bCampaignOver)
		return;

	if (g_iCurrentGamemodeID == GAMEMODE_SURVIVAL && (!g_bSurvivalStarted || !g_hCvar_EnableSurvivalMedicPoints.BoolValue))
		return;

	int Recipient = GetClientOfUserId(event.GetInt("subject"));
	int Giver = GetClientOfUserId(event.GetInt("userid"));
	int Amount = event.GetInt("health_restored");

	bool GiverIsBot = IsClientBot(Giver);
	bool RecipientIsBot = IsClientBot(Recipient);

	if (g_iCurrentGamemodeID != GAMEMODE_SURVIVAL && (!GiverIsBot || (GiverIsBot && (g_hCvar_MedkitBotMode.IntValue >= 2 || (!RecipientIsBot && g_hCvar_MedkitBotMode.IntValue >= 1)))))
	{
		g_iMedkitsUsedCounter++;
		AnnounceMedkitPenalty();
	}

	if (GiverIsBot)
		return;

	if (Recipient == Giver)
		return;

	char RecipientName[MAX_LINE_WIDTH];
	GetClientName(Recipient, RecipientName, sizeof(RecipientName));
	char RecipientID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Recipient, RecipientID, sizeof(RecipientID));

	char GiverName[MAX_LINE_WIDTH];
	GetClientName(Giver, GiverName, sizeof(GiverName));
	char GiverID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Giver, GiverID, sizeof(GiverID));

	int Score = (Amount + 1) / 2;
	if (g_hCvar_MedkitMode.IntValue)
		Score = ModifyScoreDifficulty(g_hCvar_GiveItemClassScore[ITEM_MEDKIT].IntValue, 2, 4, TEAM_SURVIVORS);
	else
		Score = ModifyScoreDifficulty(Score, 2, 3, TEAM_SURVIVORS);

	char UpdatePoints[32];
	FormatInGameMode(UpdatePoints, sizeof(UpdatePoints));

	char query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_medkit = award_medkit + 1 WHERE steamid = '%s'", g_sDbPrefix, UpdatePoints, UpdatePoints, Score, GiverID);
	SendSQLUpdate(query);

	UpdateMapStat("points", Score);
	AddScore(Giver, Score);

	if (Score > 0)
	{
		int Mode = g_hCvar_AnnounceMode.IntValue;
		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(Giver, "You have earned {green}%i {default}points for healing {olive}%s{default}!", Score, RecipientName);
		else if (Mode == 3)
			StatsPrintToChatAll("{olive}%s {default}has earned {green}%i {default}points for healing {olive}%s{default}!", GiverName, Score, RecipientName);
	}
}

// Friendly fire code.
void Event_FriendlyFire(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled() || g_bCampaignOver)
		return;

	int Attacker = GetClientOfUserId(event.GetInt("attacker"));
	int Victim = GetClientOfUserId(event.GetInt("victim"));

	if (!Attacker || !Victim)
		return;

//	if (IsClientBot(Victim))
//		return;

	int FFMode = g_hCvar_FriendlyFireMode.IntValue;

	if (FFMode == 1)
	{
		int CooldownMode = g_hCvar_FriendlyFireCooldownMode.IntValue;
		if (CooldownMode == 1 || CooldownMode == 2)
		{
			int Target = 0;

			// Player specific : CooldownMode = 1
			// General : CooldownMode = 2
			if (CooldownMode == 1)
				Target = Victim;

			if (g_bFriendlyFireCooldown[Attacker][Target])
				return;

			g_bFriendlyFireCooldown[Attacker][Target] = true;

			if (g_iFriendlyFirePrmCounter >= MAXPLAYERS)
				g_iFriendlyFirePrmCounter = 0;

			g_iFriendlyFirePrm[g_iFriendlyFirePrmCounter][0] = Attacker;
			g_iFriendlyFirePrm[g_iFriendlyFirePrmCounter][1] = Target;
			g_hFriendlyFireTimer[Attacker][Target] = CreateTimer(g_hCvar_FriendlyFireCooldown.FloatValue, Timer_FriendlyFireCooldownEnd, g_iFriendlyFirePrmCounter++);
		}
	}
	else if (FFMode == 2)
	{
		// Friendly fire is calculated in player_hurt event (Damage based)
		return;
	}

	UpdateFriendlyFire(Attacker, Victim);
}

// Campaign win code.
void Event_CampaignWin(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bCampaignOver || StatsDisabled())
		return;

	g_bCampaignOver = true;

	StopMapTiming();

	if (g_iCurrentGamemodeID == GAMEMODE_SCAVENGE ||
			g_iCurrentGamemodeID == GAMEMODE_SURVIVAL)
		return;

	int Score = ModifyScoreDifficulty(g_hCvar_VictorySurvivorsScore.IntValue, 4, 12, TEAM_SURVIVORS);
	int Mode = g_hCvar_AnnounceMode.IntValue;
	int SurvivorCount = event.GetInt("survivorcount");
	int ClientTeam;
	bool NegativeScore = g_hCvar_EnableNegativeScore.BoolValue;

	Score *= SurvivorCount;

	char query[1024];
	char iID[MAX_LINE_WIDTH];
	char UpdatePoints[32], UpdatePointsPenalty[32];

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

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ClientTeam = GetClientTeam(i);
			if (ClientTeam == TEAM_SURVIVORS)
			{
				GetClientRankAuthString(i, iID, sizeof(iID));
				Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_campaigns = award_campaigns + 1 WHERE steamid = '%s'", g_sDbPrefix, UpdatePoints, UpdatePoints, Score, iID);
				SendSQLUpdate(query);

				if (Score > 0)
				{
					UpdateMapStat("points", Score);
					AddScore(i, Score);
				}
			}
			else if (ClientTeam == TEAM_INFECTED && NegativeScore)
			{
				GetClientRankAuthString(i, iID, sizeof(iID));

				Format(query, sizeof(query), "UPDATE %splayers SET %s = %s - %i WHERE steamid = '%s'", g_sDbPrefix, UpdatePointsPenalty, UpdatePointsPenalty, Score, iID);
				SendSQLUpdate(query);

				if (Score < 0)
					AddScore(i, Score * (-1));
			}
		}
	}

	if (Mode && Score > 0)
	{
		StatsPrintToChatTeam(TEAM_SURVIVORS, "{lightgreen}ALL SURVIVORS {default}have earned {green}%i {default}points for winning the {green}Campaign Finale {default}with {olive}%i survivors{default}!", Score, SurvivorCount);

		if (NegativeScore)
			StatsPrintToChatTeam(TEAM_INFECTED, "{lightgreen}ALL INFECTED {default}have {lightgreen}LOST {green}%i {default}points for loosing the {green}Campaign Finale {default}to {olive}%i survivors{default}!", Score, SurvivorCount);
	}
}

// Safe House reached code. Points are given to all players.
// Also, Witch Not Disturbed code, points also given to all players.
void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled())
		return;

	CheckSurvivorsWin();
}

// Begin panic event.
void Event_PanicEvent(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled())
		return;

	if (g_bCampaignOver || g_bPanicEvent)
		return;

	g_bPanicEvent = true;

	if (g_iCurrentGamemodeID == GAMEMODE_SURVIVAL)
	{
		SurvivalStart();
		return;
	}

	CreateTimer(75.0, Timer_PanicEventEnd);
}

// Begin Boomer blind.
void Event_PlayerBlind(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled() || g_bCampaignOver)
		return;

	int Attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (StatsGetClientTeam(Attacker) != TEAM_INFECTED)
		return;

	g_bPlayerVomited = true;

//	bool Infected = GetEventBool(event, "infected");
//
//	if (!Infected)
//		return;

	int Victim = GetClientOfUserId(event.GetInt("userid"));

	if (IsClientBot(Attacker))
		return;

	g_iPlayerBlinded[Victim][0] = 1;
	g_iPlayerBlinded[Victim][1] = Attacker;

	g_iBoomerHitCounter[Attacker]++;

	if (g_hTimerBoomerPerfectCheck[Attacker] != null)
		delete g_hTimerBoomerPerfectCheck[Attacker];

	g_hTimerBoomerPerfectCheck[Attacker] = CreateTimer(6.0, Timer_BoomerBlindnessCheck, Attacker);
}

// Boomer Mob Survival with no Incaps code. Points are given to all players.
void Event_PlayerBlindEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled())
		return;

	int Player = GetClientOfUserId(event.GetInt("userid"));

	if (StatsGetClientTeam(Player) != TEAM_SURVIVORS)
		return;

	if (Player > 0)
		CreateTimer(INF_WEAROFF_TIME, Timer_EndBoomerBlinded, Player);

	int Mode = g_hCvar_AnnounceMode.IntValue;
	if (g_bPlayerVomited && !g_bPlayerVomitedIncap)
	{
		int Score = ModifyScoreDifficulty(g_hCvar_SurvivedBoomerHordeScore.IntValue, 2, 5, TEAM_SURVIVORS);

		if (Score > 0)
		{
			char query[1024];
			char iID[MAX_LINE_WIDTH];
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

			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
				{
					GetClientRankAuthString(i, iID, sizeof(iID));
					Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i WHERE steamid = '%s' ", g_sDbPrefix, UpdatePoints, UpdatePoints, Score, iID);
					SendSQLUpdate(query);
					UpdateMapStat("points", Score);
					AddScore(i, Score);
				}
			}

			if (Mode)
				StatsPrintToChatTeam(TEAM_SURVIVORS, "{lightgreen}ALL SURVIVORS {default}have earned {green}%i {default}points for {olive}No Incapicitates Or Deaths After Boomer Mob{default}!", Score);
		}
	}

	g_bPlayerVomited = false;
	g_bPlayerVomitedIncap = false;
}

// Friendly Incapacitate event.
void Event_PlayerIncap(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled() || g_bCampaignOver)
		return;

	int Attacker = GetClientOfUserId(event.GetInt("attacker"));
	int Victim = GetClientOfUserId(event.GetInt("userid"));

	PlayerIncap(Attacker, Victim);
}

// Save friendly from being dragged by Smoker.
void Event_TongueSave(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled())
		return;

	int Victim = GetClientOfUserId(event.GetInt("victim"));
	int Savior = GetClientOfUserId(event.GetInt("userid"));

	HunterSmokerSave(Savior, Victim, g_hCvar_SaveFromInfectedAbilityScore[INF_ABILITY_TONGUEDRAG].IntValue, 2, 3, "Smoker", "award_smoker");
}

// Save friendly from being choked by Smoker.
void Event_ChokeSave(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled())
		return;

	int Victim = GetClientOfUserId(event.GetInt("victim"));
	int Savior = GetClientOfUserId(event.GetInt("userid"));

	HunterSmokerSave(Savior, Victim, g_hCvar_SaveFromInfectedAbilityScore[INF_ABILITY_CHOKE].IntValue, 2, 3, "Smoker", "award_smoker");
}

// Save friendly from being pounced by Hunter.
void Event_PounceSave(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled())
		return;

	int Victim = GetClientOfUserId(event.GetInt("victim"));
	int Savior = GetClientOfUserId(event.GetInt("userid"));

	if (Victim > 0)
		CreateTimer(INF_WEAROFF_TIME, Timer_EndHunterLunged, Victim);

	HunterSmokerSave(Savior, Victim, g_hCvar_SaveFromInfectedAbilityScore[INF_ABILITY_CHOKE].IntValue, 2, 3, "Hunter", "award_hunter");
}

// Player is hanging from a ledge.
void Event_PlayerFallDamage(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled() || g_bCampaignOver || !IsGamemodeVersus())
		return;

	int Victim = GetClientOfUserId(event.GetInt("userid"));
	int Attacker = GetClientOfUserId(event.GetInt("causer"));
	int Damage = RoundToNearest(event.GetFloat("damage"));

	if (Attacker == 0 && g_iPlayerJockied[Victim][0] && g_iPlayerJockied[Victim][1])
		Attacker = g_iPlayerJockied[Victim][1];

	if (Attacker == 0 || IsClientBot(Attacker) || GetClientTeam(Attacker) != TEAM_INFECTED || GetClientTeam(Victim) != TEAM_SURVIVORS || Damage <= 0)
		return;

	int VictimHealth = GetClientHealth(Victim);
	int VictimIsIncap = GetEntProp(Victim, Prop_Send, "m_isIncapacitated");

	// If the victim health is zero or below zero or is incapacitated don't count the damage from the fall
	if (VictimHealth <= 0 || VictimIsIncap != 0)
		return;

	// Damage should never exceed the amount of healt the fallen survivor had before falling down.
	if (VictimHealth < Damage)
		Damage = VictimHealth;

	if (Damage <= 0)
		return;

	SurvivorHurt(Attacker, Victim, Damage);
}

// Player melee killed an infected
void Event_MeleeKill(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled() || g_bCampaignOver)
		return;

	int Attacker = GetClientOfUserId(event.GetInt("userid"));
	//new EntityID = GetEventInt(event, "entityid");
	//bool Ambushed = GetEventBool(event, "ambush");

	if (Attacker == 0 || IsClientBot(Attacker) || GetClientTeam(Attacker) != TEAM_SURVIVORS || !IsClientConnected(Attacker) || !IsClientInGame(Attacker))
		return;

	IncrementMeleeKills(Attacker);
}

// Player is hanging from a ledge.
void Event_PlayerLedge(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled() || !IsGamemodeVersus())
		return;

	int Attacker = GetClientOfUserId(event.GetInt("causer"));
	int Victim = GetClientOfUserId(event.GetInt("userid"));

	if (Attacker == 0 && g_iPlayerJockied[Victim][0] && g_iPlayerJockied[Victim][1])
		Attacker = g_iPlayerJockied[Victim][1];

	if (Attacker == 0 || IsClientBot(Attacker) || GetClientTeam(Attacker) != TEAM_INFECTED)
		return;

	int Score = ModifyScoreDifficultyFloat(g_hCvar_PlayerLedgeSuccessScore.IntValue, 0.9, 0.8, TEAM_INFECTED);

	if (Score > 0)
	{
		char VictimName[MAX_LINE_WIDTH];
		GetClientName(Victim, VictimName, sizeof(VictimName));

		int Mode = g_hCvar_AnnounceMode.IntValue;
		char ClientID[MAX_LINE_WIDTH];
		GetClientRankAuthString(Attacker, ClientID, sizeof(ClientID));

		char query[1024];
		if (g_iCurrentGamemodeID == GAMEMODE_VERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected + %i, award_ledgegrab = award_ledgegrab + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, ClientID);
		else if (g_iCurrentGamemodeID == GAMEMODE_REALISMVERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i, award_ledgegrab = award_ledgegrab + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, ClientID);
		else if (g_iCurrentGamemodeID == GAMEMODE_SCAVENGE)
			Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i, award_ledgegrab = award_ledgegrab + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, ClientID);
		else
			Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations + %i, award_ledgegrab = award_ledgegrab + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, ClientID);

		SendSQLUpdate(query);
		UpdateMapStat("points_infected", Score);

		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(Attacker, "You have earned {green}%i {default}points for causing player {olive}%s{default} to grab a ledge!", Score, VictimName);
		else if (Mode == 3)
		{
			char AttackerName[MAX_LINE_WIDTH];
			GetClientName(Attacker, AttackerName, sizeof(AttackerName));
			StatsPrintToChatAll("{olive}%s {default}has earned {green}%i {default}points for causing player {olive}%s{default} to grab a ledge!", AttackerName, Score, VictimName);
		}
	}
}

// Player spawned in game.
void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled())
		return;

	int Player = GetClientOfUserId(event.GetInt("userid"));

	if (Player == 0)
		return;

	InitializeClientInf(Player);

	g_iClientInfectedType[Player] = 0;
	g_iBoomerHitCounter[Player] = 0;
	g_iBoomerVomitUpdated[Player] = false;
	g_iSmokerDamageCounter[Player] = 0;
	g_iSpitterDamageCounter[Player] = 0;
	g_iJockeyDamageCounter[Player] = 0;
	g_iChargerDamageCounter[Player] = 0;
	g_iChargerImpactCounter[Player] = 0;
	g_iTankPointsCounter[Player] = 0;
	g_iTankDamageCounter[Player] = 0;
	g_iTankDamageTotalCounter[Player] = 0;
	g_iTankSurvivorKillCounter[Player] = 0;
	g_iChargerCarryVictim[Player] = 0;
	g_iChargerPlummelVictim[Player] = 0;
	g_iJockeyVictim[Player] = 0;
	g_iJockeyRideStartTime[Player] = 0;

	g_iPlayerBlinded[Player][0] = 0;
	g_iPlayerBlinded[Player][1] = 0;
	g_iPlayerParalyzed[Player][0] = 0;
	g_iPlayerParalyzed[Player][1] = 0;
	g_iPlayerLunged[Player][0] = 0;
	g_iPlayerLunged[Player][1] = 0;
	g_iPlayerPummeled[Player][0] = 0;
	g_iPlayerPummeled[Player][1] = 0;
	g_iPlayerCarried[Player][0] = 0;
	g_iPlayerCarried[Player][1] = 0;
	g_iPlayerJockied[Player][0] = 0;
	g_iPlayerJockied[Player][1] = 0;

	if (!IsClientBot(Player))
		SetClientInfectedType(Player);

	if (g_hChargerImpactCounterTimer[Player] != null)
		delete g_hChargerImpactCounterTimer[Player];
}

// Player hurt. Used for calculating damage points for the Infected players and also
// the friendly fire damage when Friendly Fire Mode is set to Damage Based.
void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled() || g_bCampaignOver)
		return;

	int Attacker = GetClientOfUserId(event.GetInt("attacker"));
	int Victim = GetClientOfUserId(event.GetInt("userid"));

	// Self inflicted damage does not count
	if (Attacker == Victim)
		return;

	if (Attacker == 0 || IsClientBot(Attacker))
	{
		// Attacker is normal indected but the Victim was infected by blinding and/or paralysation.
		if (Attacker == 0
				&& Victim > 0
				&& (g_iPlayerBlinded[Victim][0] && g_iPlayerBlinded[Victim][1]
					|| g_iPlayerParalyzed[Victim][0] && g_iPlayerParalyzed[Victim][1]
					|| g_iPlayerLunged[Victim][0] && g_iPlayerLunged[Victim][1]
					|| g_iPlayerCarried[Victim][0] && g_iPlayerCarried[Victim][1]
					|| g_iPlayerPummeled[Victim][0] && g_iPlayerPummeled[Victim][1]
					|| g_iPlayerJockied[Victim][0] && g_iPlayerJockied[Victim][1])
				&& IsGamemodeVersus())
			SurvivorHurtExternal(event, Victim);

		return;
	}

	int Damage = event.GetInt("dmg_health");
	int AttackerTeam = GetClientTeam(Attacker);
	int AttackerInfType = -1;

	int VictimTeam = GetClientTeam(Victim);
	if (AttackerTeam == VictimTeam && AttackerTeam == TEAM_INFECTED)
		return;

	if (Attacker > 0)
	{
		if (AttackerTeam == TEAM_INFECTED)
			AttackerInfType = g_iClientInfectedType[Attacker];
		else if (AttackerTeam == TEAM_SURVIVORS && g_hCvar_FriendlyFireMode.IntValue == 2)
		{
			if (VictimTeam == TEAM_SURVIVORS)
			{
				if (g_hFriendlyFireTimer[Attacker][0] != null)
					delete g_hFriendlyFireTimer[Attacker][0];

				char AttackerID[MAX_LINE_WIDTH];
				GetClientRankAuthString(Attacker, AttackerID, sizeof(AttackerID));
				char AttackerName[MAX_LINE_WIDTH];
				GetClientName(Attacker, AttackerName, sizeof(AttackerName));

				// Using datapack to deliver the needed info so that the attacker can't escape the penalty by disconnecting

				DataPack dp = null;
				int OldHumanDamage = 0;
				int OldBotDamage = 0;

				if (!g_hFriendlyFireDamageTrie.GetValue(AttackerID, dp))
				{
					dp = new DataPack();
					g_hFriendlyFireDamageTrie.SetValue(AttackerID, dp);
				}
				else
				{
					// Read old damage value
					dp.Reset();
					OldHumanDamage = dp.ReadCell();
					OldBotDamage = dp.ReadCell();
				}

				if (IsClientBot(Victim)) OldBotDamage += Damage;
				else OldHumanDamage += Damage;

				dp.Reset(true);

				dp.WriteCell(OldHumanDamage);
				dp.WriteCell(OldBotDamage);
				dp.WriteCell(Attacker);
				dp.WriteString(AttackerID);
				dp.WriteString(AttackerName);

				// This may fail! What happens when a player skips and another joins with the same Client ID (is this even possible in such short time?)
				g_hFriendlyFireTimer[Attacker][0] = CreateTimer(5.0, Timer_FriendlyFireDamageEnd, dp);

				return;
			}
		}
	}
	if (AttackerInfType < 0)
		return;

//	char AttackerID[MAX_LINE_WIDTH];
//	GetClientRankAuthString(Attacker, AttackerID, sizeof(AttackerID));

//	new Mode;
//	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
//	char VictimName[MAX_LINE_WIDTH];
//	new VictimTeam = 0;
//	new Score = 0;

//	if (Victim > 0)
//	{
//		GetClientName(Victim, VictimName, sizeof(VictimName));
//		VictimTeam = GetClientTeam(Victim);
//	}
//	else
//		Format(VictimName, sizeof(VictimName), "UNKNOWN");

//	if (VictimTeam == TEAM_INFECTED)
//	{
//		char query[1024];
//
//		Score = GetConVarInt(g_hCvar_ActionScore[ACT_FF]);
//		Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected - %i WHERE steamid = '%s'", g_sDbPrefix, Score, AttackerID);
//		SendSQLUpdate(query);
//
//		UpdateMapStat("points_infected", Score * -1);
//		Mode = GetConVarInt(g_hCvar_AnnounceMode);
//
//		if (Mode == 1 || Mode == 2)
//			StatsPrintToChat(Attacker, "You have {lightgreen}LOST {green}%i {default}points for {lightgreen}Friendly Firing {olive}%s{default}!", Score, VictimName);
//		else if (Mode == 3)
//		{
//			char AttackerName[MAX_LINE_WIDTH];
//			GetClientName(Attacker, AttackerName, sizeof(AttackerName));
//			StatsPrintToChatAll("{olive}%s {default}has {lightgreen}LOST {green}%i {default}points for {lightgreen}Friendly Firing {olive}%s{default}!", AttackerName, Score, VictimName);
//		}
//
//		return;
//	}

	SurvivorHurt(Attacker, Victim, Damage, AttackerInfType, event);
}

// Smoker events.
void Event_SmokerGrap(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled() || !IsGamemodeVersus() || g_bCampaignOver)
		return;

	int Attacker = GetClientOfUserId(event.GetInt("userid"));
	int Victim = GetClientOfUserId(event.GetInt("victim"));

	g_iPlayerParalyzed[Victim][0] = 1;
	g_iPlayerParalyzed[Victim][1] = Attacker;
}

// Jockey events.
void Event_JockeyStart(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled() || g_bCampaignOver)
		return;

	int Attacker = GetClientOfUserId(event.GetInt("userid"));
	int Victim = GetClientOfUserId(event.GetInt("victim"));

	g_iPlayerJockied[Victim][0] = 1;
	g_iPlayerJockied[Victim][1] = Attacker;

	g_iJockeyVictim[Attacker] = Victim;
	g_iJockeyRideStartTime[Attacker] = 0;

	if (Attacker == 0 || IsClientBot(Attacker) || !IsClientConnected(Attacker) || !IsClientInGame(Attacker))
		return;

	g_iJockeyRideStartTime[Attacker] = GetTime();

	char query[1024];
	char iID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Attacker, iID, sizeof(iID));
	Format(query, sizeof(query), "UPDATE %splayers SET jockey_rides = jockey_rides + 1 WHERE steamid = '%s'", g_sDbPrefix, iID);
	SendSQLUpdate(query);
	UpdateMapStat("jockey_rides", 1);
}

void Event_JockeyRelease(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled() || g_bCampaignOver)
		return;

	int Jockey = GetClientOfUserId(event.GetInt("userid"));
	int Victim = GetClientOfUserId(event.GetInt("victim"));
	int Rescuer = GetClientOfUserId(event.GetInt("rescuer"));
	float RideLength = event.GetFloat("ride_length");

	if (Rescuer > 0 && !IsClientBot(Rescuer) && IsClientInGame(Rescuer))
	{
		char query[1024], JockeyName[MAX_LINE_WIDTH], VictimName[MAX_LINE_WIDTH], RescuerName[MAX_LINE_WIDTH], RescuerID[MAX_LINE_WIDTH], UpdatePoints[32];
		int Score = ModifyScoreDifficulty(g_hCvar_SaveFromInfectedAbilityScore[INF_ABILITY_RIDE].IntValue, 2, 3, TEAM_SURVIVORS);

		GetClientRankAuthString(Rescuer, RescuerID, sizeof(RescuerID));
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

		Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_jockey = award_jockey + 1 WHERE steamid = '%s'", g_sDbPrefix, UpdatePoints, UpdatePoints, Score, RescuerID);
		SendSQLUpdate(query);

		if (Score > 0)
		{
			UpdateMapStat("points", Score);
			AddScore(Rescuer, Score);
		}

		GetClientName(Jockey, JockeyName, sizeof(JockeyName));
		GetClientName(Victim, VictimName, sizeof(VictimName));

		int Mode = g_hCvar_AnnounceMode.IntValue++
		if (Score > 0)
		{
			if (Mode == 1 || Mode == 2)
				StatsPrintToChat(Rescuer, "You have earned {green}%i {default}points for saving {olive}%s {default}from {green}%s{default}!", Score, VictimName, JockeyName);
			else if (Mode == 3)
			{
				GetClientName(Rescuer, RescuerName, sizeof(RescuerName));
				StatsPrintToChatAll("{olive}%s {default}has earned {green}%i {default}points for saving {olive}%s {default}from {green}%s{default}!", RescuerName, Score, VictimName, JockeyName);
			}
		}
	}

	g_iJockeyVictim[Jockey] = 0;

	if (Jockey == 0 || IsClientBot(Jockey) || !IsClientInGame(Jockey))
	{
		g_iPlayerJockied[Victim][0] = 0;
		g_iPlayerJockied[Victim][1] = 0;
		g_iJockeyRideStartTime[Victim] = 0;
		return;
	}

	UpdateJockeyRideLength(Jockey, RideLength);

	if (Victim > 0)
		CreateTimer(INF_WEAROFF_TIME, Timer_EndJockeyRide, Victim);
}

void Event_JockeyKilled(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled())
		return;

	int Attacker = GetClientOfUserId(event.GetInt("userid"));

	if (Attacker == 0 || IsClientBot(Attacker) || !IsClientInGame(Attacker))
		return;

	int Victim = GetClientOfUserId(event.GetInt("victim"));

	if (Victim > 0)
		CreateTimer(INF_WEAROFF_TIME, Timer_EndJockeyRide, Victim);
}

// Charger events.
void Event_ChargerKilled(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled() || g_bCampaignOver)
		return;

	int Killer = GetClientOfUserId(event.GetInt("attacker"));
	if (Killer == 0 || IsClientBot(Killer) || !IsClientInGame(Killer))
		return;

	int Charger = GetClientOfUserId(event.GetInt("userid"));
	char query[1024], KillerName[MAX_LINE_WIDTH], KillerID[MAX_LINE_WIDTH], UpdatePoints[32];
	int Score = 0;
	bool IsMatador = event.GetBool("melee") && event.GetBool("charging");

	GetClientRankAuthString(Killer, KillerID, sizeof(KillerID));

	FormatInGameMode(UpdatePoints, sizeof(UpdatePoints));

	if (g_iChargerCarryVictim[Charger]) Score += ModifyScoreDifficulty(g_hCvar_SaveFromInfectedAbilityScore[INF_ABILITY_CARRY].IntValue, 2, 3, TEAM_SURVIVORS);
	else if (g_iChargerPlummelVictim[Charger]) Score += ModifyScoreDifficulty(g_hCvar_SaveFromInfectedAbilityScore[INF_ABILITY_PUMMEL].IntValue, 2, 3, TEAM_SURVIVORS);

	if (IsMatador)
	{
		// Give a Matador award
		Score += ModifyScoreDifficulty(g_hCvar_MatadorScore.IntValue, 2, 3, TEAM_SURVIVORS);
	}

	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_charger = award_charger + 1%s WHERE steamid = '%s'", g_sDbPrefix, UpdatePoints, UpdatePoints, Score, (IsMatador ? ", award_matador = award_matador + 1" : ""), KillerID);
	SendSQLUpdate(query);

	if (Score <= 0)
		return;

	UpdateMapStat("points", Score);
	AddScore(Killer, Score);

	int Mode = g_hCvar_AnnounceMode.IntValue;
	if (Mode)
	{
		GetClientName(Killer, KillerName, sizeof(KillerName));
		if (IsMatador)
		{
			if (Mode == 1 || Mode == 2)
				StatsPrintToChat(Killer, "You have earned {green}%i {default}points for {green}Leveling a Charge{default}!", Score);
			else if (Mode == 3)
				StatsPrintToChatAll("{olive}%s {default}has earned {green}%i {default}points for {green}Leveling a Charge{default}!", KillerName, Score);
		}
		else
		{
			char VictimName[MAX_LINE_WIDTH], ChargerName[MAX_LINE_WIDTH];
			GetClientName(Charger, ChargerName, sizeof(ChargerName));
			if (g_iChargerCarryVictim[Charger] > 0 && (IsClientBot(g_iChargerCarryVictim[Charger]) || (IsClientConnected(g_iChargerCarryVictim[Charger]) && IsClientInGame(g_iChargerCarryVictim[Charger]))))
			{
				GetClientName(g_iChargerCarryVictim[Charger], VictimName, sizeof(VictimName));
				Format(VictimName, sizeof(VictimName), "{olive}%s{default}", VictimName);
			}
			else
				Format(VictimName, sizeof(VictimName), "a survivor");

			if (Mode == 1 || Mode == 2)
				StatsPrintToChat(Killer, "You have earned {green}%i {default}points for saving %s from {green}%s{default}!", Score, VictimName, ChargerName);
			else if (Mode == 3)
				StatsPrintToChatAll("{olive}%s {default}has earned {green}%i {default}points for saving %s from {green}%s{default}!", KillerName, Score, VictimName, ChargerName);
		}
	}
}

void Event_ChargerCarryStart(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled())
		return;

	int Attacker = GetClientOfUserId(event.GetInt("userid"));
	int Victim = GetClientOfUserId(event.GetInt("victim"));

	g_iPlayerCarried[Victim][0] = 1;
	g_iPlayerCarried[Victim][1] = Attacker;

	g_iChargerCarryVictim[Attacker] = Victim;

	if (IsClientBot(Attacker) || !IsClientConnected(Attacker) || !IsClientInGame(Attacker))
		return;

	IncrementImpactCounter(Attacker);
}

void Event_ChargerCarryRelease(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled())
		return;

	//new Attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	int Victim = GetClientOfUserId(event.GetInt("victim"));

	//if (Attacker == 0 || IsClientBot(Attacker) || !IsClientInGame(Attacker))
	//{
	//	g_iChargerCarryVictim[Attacker] = 0;
	//	g_iPlayerCarried[Victim][0] = 0;
	//	g_iPlayerCarried[Victim][1] = 0;
	//	return;
	//}

	if (Victim > 0)
		CreateTimer(INF_WEAROFF_TIME, Timer_EndChargerCarry, Victim);
}

void Event_ChargerImpact(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled() || g_bCampaignOver)
		return;

	int Attacker = GetClientOfUserId(event.GetInt("userid"));

	if (Attacker == 0 || IsClientBot(Attacker) || !IsClientConnected(Attacker) || !IsClientInGame(Attacker))
		return;

	//new Victim = GetClientOfUserId(GetEventInt(event, "victim"));
	IncrementImpactCounter(Attacker);
}

void Event_ChargerPummelStart(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled())
		return;

	int Attacker = GetClientOfUserId(event.GetInt("userid"));

	// There is no delay on charger carry once the plummel starts
	g_iChargerCarryVictim[Attacker] = 0;

	int Victim = GetClientOfUserId(event.GetInt("victim"));

	g_iPlayerPummeled[Victim][0] = 1;
	g_iPlayerPummeled[Victim][1] = Attacker;
	g_iChargerPlummelVictim[Attacker] = Victim;

	//if (Attacker == 0 || IsClientBot(Attacker) || !IsClientInGame(Attacker))
	//	return;
}

void Event_ChargerPummelRelease(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled())
		return;

	int Attacker = GetClientOfUserId(event.GetInt("userid"));
	int Victim = GetClientOfUserId(event.GetInt("victim"));

	if (Attacker == 0 || IsClientBot(Attacker) || !IsClientInGame(Attacker))
	{
		g_iPlayerPummeled[Victim][0] = 0;
		g_iPlayerPummeled[Victim][1] = 0;
		g_iChargerPlummelVictim[Attacker] = 0;
		return;
	}

	if (Victim > 0)
		CreateTimer(INF_WEAROFF_TIME, Timer_EndChargerPummel, Victim);
}

// Hunter events.
void Event_HunterRelease(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled())
		return;

	int Player = GetClientOfUserId(event.GetInt("victim"));

	if (Player > 0)
		CreateTimer(INF_WEAROFF_TIME, Timer_EndHunterLunged, Player);
}

// Smoker events.
void Event_SmokerRelease(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled())
		return;

	int Player = GetClientOfUserId(event.GetInt("victim"));

	if (Player > 0)
		CreateTimer(INF_WEAROFF_TIME, Timer_EndSmokerParalyzed, Player);
}

// L4D2 ammo upgrade deployed event.
void Event_UpgradePackAdded(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled() || g_bCampaignOver)
		return;

	if (g_iCurrentGamemodeID == GAMEMODE_SURVIVAL && !g_bSurvivalStarted)
		return;

	int Player = GetClientOfUserId(event.GetInt("userid"));

	if (Player == 0 || IsClientBot(Player))
		return;

	int Score = g_hCvar_AmmoUpgradeAddedScore.IntValue;

	if (Score > 0)
		Score = ModifyScoreDifficulty(Score, 2, 3, TEAM_SURVIVORS);

	char PlayerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Player, PlayerID, sizeof(PlayerID));

	char UpdatePoints[32];
	FormatInGameMode(UpdatePoints, sizeof(UpdatePoints));

	char query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_upgrades_added = award_upgrades_added + 1 WHERE steamid = '%s'", g_sDbPrefix, UpdatePoints, UpdatePoints, Score, PlayerID);
	SendSQLUpdate(query);

	if (Score > 0)
	{
		int Mode = g_hCvar_AnnounceMode.IntValue;
		int EntityID = event.GetInt("upgradeid");
		char ModelName[128];
		GetEntPropString(EntityID, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));

		if (StrContains(ModelName, "incendiary_ammo", false) >= 0)
			strcopy(ModelName, sizeof(ModelName), "Incendiary Ammo");
		else if (StrContains(ModelName, "exploding_ammo", false) >= 0)
			strcopy(ModelName, sizeof(ModelName), "Exploding Ammo");
		else
			strcopy(ModelName, sizeof(ModelName), "UNKNOWN");

		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(Player, "You have earned {green}%i {default}points for deploying {olive}%s{default}!", Score, ModelName);
		else if (Mode == 3)
		{
			char PlayerName[MAX_LINE_WIDTH];
			GetClientName(Player, PlayerName, sizeof(PlayerName));
			StatsPrintToChatAll("{olive}%s {default}has earned {green}%i {default}points for deploying {olive}%s{default}!", PlayerName, Score, ModelName);
		}
	}
}

// L4D2 gascan pour completed event.
void Event_GascanPoured(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled() || g_bCampaignOver)
		return;

	int Player = GetClientOfUserId(event.GetInt("userid"));

	if (Player == 0 || IsClientBot(Player))
		return;

	int Score = g_hCvar_GascanPouredScore.IntValue;

	if (Score > 0)
		Score = ModifyScoreDifficulty(Score, 2, 3, TEAM_SURVIVORS);

	char PlayerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Player, PlayerID, sizeof(PlayerID));

	char UpdatePoints[32];
	FormatInGameMode(UpdatePoints, sizeof(UpdatePoints));

	char query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_gascans_poured = award_gascans_poured + 1 WHERE steamid = '%s'", g_sDbPrefix, UpdatePoints, UpdatePoints, Score, PlayerID);

	SendSQLUpdate(query);
	if (Score > 0)
	{
		int Mode = g_hCvar_AnnounceMode.IntValue;

		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(Player, "You have earned {green}%i {default}points for successfully {olive}Pouring a Gascan{default}!", Score);
		else if (Mode == 3)
		{
			char PlayerName[MAX_LINE_WIDTH];
			GetClientName(Player, PlayerName, sizeof(PlayerName));
			StatsPrintToChatAll("{olive}%s {default}has earned {green}%i {default}points for successfully {olive}Pouring a Gascan{default}!", PlayerName, Score);
		}
	}
}

// Achievement earned.

/*
56 - Helping Hand
57 - Field Medic
58 - Pharm-Assist
59 - My Bodyguard
60 - Dead Stop
61 - Crownd
62 - Untouchables
63 -
64 - Drag and Drop
65 - Blind Luck
66 - Akimbo Assassin
67 -
68 - Hero Closet
69 - Hunter Punter
70 - Tongue Twister
71 - No Smoking Section
72 -
73 - 101 Cremations
74 - Do Not Disturb
75 - Man Vs Tank
76 - TankBusters
77 - Safety First
78 - No-one Left Behind
79 -
80 -
81 - Unbreakable
82 - Witch Hunter
83 - Red Mist
84 - Pyrotechnician
85 - Zombie Genocidest
86 - Dead Giveaway
87 - Stand Tall
88 -
89 -
90 - Zombicidal Maniac
91 - What are you trying to Prove?
92 -
93 - Nothing Special
94 - Burn the Witch
95 - Towering Inferno
96 - Spinal Tap
97 - Stomach Upset
98 - Brain Salad
99 - Jump Shot
100 - Mercy Killer
101 - Back 2 Help
102 - Toll Collector
103 - Dead Baron
104 - Grim Reaper
105 - Ground Cover
106 - Clean Kill
107 - Big Drag
108 - Chain Smoker
109 - Barf Bagged
110 - Double Jump
111 - All 4 Dead
112 - Dead Wreckening
113 - Lamb 2 Slaughter
114 - Outbreak
*/

void Event_Achievement(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled())
		return;

	int Player = GetClientOfUserId(event.GetInt("player"));

	if (IsClientBot(Player))
		return;

#if DEBUG
	int Achievement = GetEventInt(event, "achievement");
	LogMessage("Achievement earned: %i", Achievement);
#endif
}

// Saferoom door opens.
void Event_DoorOpen(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bMapTimingBlocked || g_fMapTimingStartTime != 0.0 || !event.GetBool("checkpoint") || !event.GetBool("closed") || g_iCurrentGamemodeID == GAMEMODE_SURVIVAL || StatsDisabled())
	{
		g_bMapTimingBlocked = true;
		return;
	}

	StartMapTiming();
}

void Event_StartArea(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bMapTimingBlocked || g_fMapTimingStartTime != 0.0 || g_iCurrentGamemodeID == GAMEMODE_SURVIVAL || StatsDisabled())
	{
		g_bMapTimingBlocked = true;
		return;
	}

	StartMapTiming();
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bMapTimingBlocked || g_fMapTimingStartTime != 0.0 || event.GetBool("isbot"))
		return;

	int Player = GetClientOfUserId(event.GetInt("userid"));
	//new NewTeam = GetEventInt(event, "team");
	//new OldTeam = GetEventInt(event, "oldteam");

	if (Player <= 0)
		return;

	char PlayerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Player, PlayerID, sizeof(PlayerID));

	g_hMapTimingSurvivors.Remove(PlayerID);
	g_hMapTimingInfected.Remove(PlayerID);
}

// AbilityUse.
void Event_AbilityUse(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled())
		return;

	int Player = GetClientOfUserId(event.GetInt("userid"));
	GetClientAbsOrigin(Player, g_fHunterPosition[Player]);

	if (!IsClientBot(Player) && GetClientInfectedType(Player) == INF_ID_BOOMER)
	{
		char query[1024];
		char iID[MAX_LINE_WIDTH];
		GetClientRankAuthString(Player, iID, sizeof(iID));
		Format(query, sizeof(query), "UPDATE %splayers SET infected_boomer_vomits = infected_boomer_vomits + 1 WHERE steamid = '%s'", g_sDbPrefix, iID);
		SendSQLUpdate(query);
		UpdateMapStat("infected_boomer_vomits", 1);
		g_iBoomerVomitUpdated[Player] = true;
	}
}

// Player got pounced.
void Event_PlayerPounced(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled() || g_bCampaignOver)
		return;

	int Attacker = GetClientOfUserId(event.GetInt("userid"));
	int Victim = GetClientOfUserId(event.GetInt("victim"));

	g_iPlayerLunged[Victim][0] = 1;
	g_iPlayerLunged[Victim][1] = Attacker;

	if (IsClientBot(Attacker))
		return;

	float PouncePosition[3];

	GetClientAbsOrigin(Attacker, PouncePosition);
	int PounceDistance = RoundToNearest(GetVectorDistance(g_fHunterPosition[Attacker], PouncePosition));

	if (PounceDistance < g_iMinPounceDistance)
		return;

	int Dmg = RoundToNearest((((PounceDistance - float(g_iMinPounceDistance)) / float(g_iMaxPounceDistance - g_iMinPounceDistance)) * float(g_iMaxPounceDamage)) + 1);
	int DmgCap = g_hCvar_HunterDamageCap.IntValue;

	if (Dmg > DmgCap)
		Dmg = DmgCap;

	int PerfectDmgLimit = g_hCvar_HunterPerfectPounceDamage.IntValue;
	int NiceDmgLimit = g_hCvar_HunterNicePounceDamage.IntValue;

	UpdateHunterDamage(Attacker, Dmg);

	if (Dmg < NiceDmgLimit && Dmg < PerfectDmgLimit)
		return;

	int Mode = g_hCvar_AnnounceMode.IntValue;

	char AttackerName[MAX_LINE_WIDTH];
	GetClientName(Attacker, AttackerName, sizeof(AttackerName));
	char AttackerID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Attacker, AttackerID, sizeof(AttackerID));
	char VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));

	int Score = 0;
	char Label[32];
	char query[1024];

	if (Dmg >= PerfectDmgLimit)
	{
		Score = g_hCvar_HunterPerfectPounceSuccess.IntValue;
		if (g_iCurrentGamemodeID == GAMEMODE_VERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected + %i, award_pounce_perfect = award_pounce_perfect + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, AttackerID);
		else if (g_iCurrentGamemodeID == GAMEMODE_REALISMVERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i, award_pounce_perfect = award_pounce_perfect + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, AttackerID);
		else if (g_iCurrentGamemodeID == GAMEMODE_SCAVENGE)
			Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i, award_pounce_perfect = award_pounce_perfect + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, AttackerID);
		else
			Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations + %i, award_pounce_perfect = award_pounce_perfect + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, AttackerID);
		Format(Label, sizeof(Label), "Death From Above");

		if (g_bEnableSounds_Hunter_Perfect && g_hCvar_SoundsEnabled.BoolValue)
			EmitSoundToAll(g_sStatsSound_Hunter_Perfect);
	}
	else
	{
		Score = g_hCvar_HunterNicePounceSuccess.IntValue;
		if (g_iCurrentGamemodeID == GAMEMODE_VERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_infected = points_infected + %i, award_pounce_nice = award_pounce_nice + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, AttackerID);
		else if (g_iCurrentGamemodeID == GAMEMODE_REALISMVERSUS)
			Format(query, sizeof(query), "UPDATE %splayers SET points_realism_infected = points_realism_infected + %i, award_pounce_nice = award_pounce_nice + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, AttackerID);
		else if (g_iCurrentGamemodeID == GAMEMODE_SCAVENGE)
			Format(query, sizeof(query), "UPDATE %splayers SET points_scavenge_infected = points_scavenge_infected + %i, award_pounce_nice = award_pounce_nice + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, AttackerID);
		else
			Format(query, sizeof(query), "UPDATE %splayers SET points_mutations = points_mutations + %i, award_pounce_nice = award_pounce_nice + 1 WHERE steamid = '%s'", g_sDbPrefix, Score, AttackerID);
		Format(Label, sizeof(Label), "Pain From Above");
	}

	SendSQLUpdate(query);
	UpdateMapStat("points_infected", Score);

	if (Mode == 1 || Mode == 2)
		StatsPrintToChat(Attacker, "You have earned {green}%i {default}points for landing a {olive}%s {default}Pounce on {olive}%s{default}!", Score, Label, VictimName);
	else if (Mode == 3)
		StatsPrintToChatAll("{olive}%s {default}has earned {green}%i {default}points for landing a {olive}%s {default}Pounce on {olive}%s{default}!", AttackerName, Score, Label, VictimName);
}

// Revive friendly code.
void Event_RevivePlayer(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled())
		return;

	if (g_iCurrentGamemodeID == GAMEMODE_SURVIVAL && !g_bSurvivalStarted)
		return;

	if (event.GetBool("ledge_hang"))
		return;

	int Savior = GetClientOfUserId(event.GetInt("userid"));
	int Victim = GetClientOfUserId(event.GetInt("subject"));
	int Mode = g_hCvar_AnnounceMode.IntValue;

	if (IsClientBot(Savior) || IsClientBot(Victim))
		return;

	char SaviorName[MAX_LINE_WIDTH];
	GetClientName(Savior, SaviorName, sizeof(SaviorName));
	char SaviorID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Savior, SaviorID, sizeof(SaviorID));

	char VictimName[MAX_LINE_WIDTH];
	GetClientName(Victim, VictimName, sizeof(VictimName));
	char VictimID[MAX_LINE_WIDTH];
	GetClientRankAuthString(Victim, VictimID, sizeof(VictimID));

	int Score = ModifyScoreDifficulty(g_hCvar_HelpScore[HELP_REVIVE].IntValue, 2, 3, TEAM_SURVIVORS);

	char UpdatePoints[32];
	FormatInGameMode(UpdatePoints, sizeof(UpdatePoints));

	char query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_revive = award_revive + 1 WHERE steamid = '%s'", g_sDbPrefix, UpdatePoints, UpdatePoints, Score, SaviorID);
	SendSQLUpdate(query);

	UpdateMapStat("points", Score);
	AddScore(Savior, Score);

	if (Score > 0)
	{
		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(Savior, "You have earned {green}%i {default}points for Reviving {olive}%s{default}!", Score, VictimName);
		else if (Mode == 3)
			StatsPrintToChatAll("{olive}%s {default}has earned {green}%i {default}points for Reviving {olive}%s{default}!", SaviorName, Score, VictimName);
	}
}

/*
L4D1:

56 - Helping Hand
57 - Field Medic
58 - Pharm-Assist
59 - My Bodyguard
60 - Dead Stop
61 - Crownd
62 - Untouchables
63 -
64 - Drag and Drop
65 - Blind Luck
66 - Akimbo Assassin
67 -
68 - Hero Closet
69 - Hunter Punter
70 - Tongue Twister
71 - No Smoking Section
72 -
73 - 101 Cremations
74 - Do Not Disturb
75 - Man Vs Tank
76 - TankBusters
77 - Safety First
78 - No-one Left Behind
79 -
80 -
81 - Unbreakable
82 - Witch Hunter
83 - Red Mist
84 - Pyrotechnician
85 - Zombie Genocidest
86 - Dead Giveaway
87 - Stand Tall
88 -
89 -
90 - Zombicidal Maniac
91 - What are you trying to Prove?
92 -
93 - Nothing Special
94 - Burn the Witch
95 - Towering Inferno
96 - Spinal Tap
97 - Stomach Upset
98 - Brain Salad
99 - Jump Shot
100 - Mercy Killer
101 - Back 2 Help
102 - Toll Collector
103 - Dead Baron
104 - Grim Reaper
105 - Ground Cover
106 - Clean Kill
107 - Big Drag
108 - Chain Smoker
109 - Barf Bagged
110 - Double Jump
111 - All 4 Dead
112 - Dead Wreckening
113 - Lamb 2 Slaughter
114 - Outbreak
*/

// Miscellaneous events and awards. See specific award for info.
void Event_Award_L4D1(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled())
		return;

	int User = GetClientOfUserId(event.GetInt("userid"));
	if (IsClientBot(User))
		return;

	int SubjectID = event.GetInt("subjectentid");
	int Mode = g_hCvar_AnnounceMode.IntValue;
	char UserName[MAX_LINE_WIDTH];
	GetClientName(User, UserName, sizeof(UserName));

	int Recipient;
	char RecipientName[MAX_LINE_WIDTH];

	int Score = 0;
	char AwardSQL[128];
	int AwardID = event.GetInt("award");

	if (AwardID == 67) // Protect friendly
	{
		if (!SubjectID)
			return;

		g_iProtectedFriendlyCounter[User]++;

		if (g_hTimerProtectedFriendly[User] != null)
			delete g_hTimerProtectedFriendly[User];

		g_hTimerProtectedFriendly[User] = CreateTimer(3.0, Timer_ProtectedFriendly, User);

		return;
	}
	else if (AwardID == 79) // Respawn friendly
	{
		if (!SubjectID)
			return;

		Recipient = GetClientOfUserId(GetClientUserId(SubjectID));

		if (IsClientBot(Recipient))
			return;

		Score = ModifyScoreDifficulty(g_hCvar_HelpScore[HELP_RESCUE].IntValue, 2, 3, TEAM_SURVIVORS);
		GetClientName(Recipient, RecipientName, sizeof(RecipientName));
		Format(AwardSQL, sizeof(AwardSQL), ", award_rescue = award_rescue + 1");
		UpdateMapStat("points", Score);
		AddScore(User, Score);

		if (Score > 0)
		{
			if (Mode == 1 || Mode == 2)
				StatsPrintToChat(User, "You have earned {green}%i {default}points for Rescuing {olive}%s{default}!", Score, RecipientName);
			else if (Mode == 3)
				StatsPrintToChatAll("{olive}%s {default}has earned {green}%i {default}points for Rescuing {olive}%s{default}!", UserName, Score, RecipientName);
		}
	}
	else if (AwardID == 80) // Kill Tank with no deaths
	{
		Score = ModifyScoreDifficulty(0, 1, 1, TEAM_SURVIVORS);
		Format(AwardSQL, sizeof(AwardSQL), ", award_tankkillnodeaths = award_tankkillnodeaths + 1");
	}
// Moved to Event_PlayerDeath
//	else if (AwardID == 83 && !g_bCampaignOver) // Team kill
//	{
//		if (!SubjectID)
//			return;
//
//		Recipient = GetClientOfUserId(GetClientUserId(SubjectID));
//
//		Format(AwardSQL, sizeof(AwardSQL), ", award_teamkill = award_teamkill + 1");
//		Score = ModifyScoreDifficultyNR(GetConVarInt(g_hCvar_ActionScore[ACT_FFKILL]), 2, 4, TEAM_SURVIVORS);
//		Score = Score * -1;
//
//		if (Mode == 1 || Mode == 2)
//			StatsPrintToChat(User, "You have {lightgreen}LOST {green}%i {default}points for {lightgreen}Team Killing!", Score);
//		else if (Mode == 3)
//			StatsPrintToChatAll("{olive}%s {default}has {lightgreen}LOST {green}%i {default}points for {lightgreen}Team Killing!", UserName, Score);
//	}
	else if (AwardID == 85) // Left friendly for dead
	{
		Format(AwardSQL, sizeof(AwardSQL), ", award_left4dead = award_left4dead + 1");
		Score = ModifyScoreDifficulty(0, 1, 1, TEAM_SURVIVORS);
	}
	else if (AwardID == 94) // Let infected in safe room
	{
		Format(AwardSQL, sizeof(AwardSQL), ", award_letinsafehouse = award_letinsafehouse + 1");

		Score = 0;
		if (g_hCvar_EnableNegativeScore.BoolValue)
			Score = ModifyScoreDifficultyNR(g_hCvar_ActionScore[ACT_LET_INF_IN_SAFE_ROOM].IntValue, 2, 4, TEAM_SURVIVORS);
		else
			Mode = 0;

		if (Mode == 1 || Mode == 2)
			StatsPrintToChat(User, "You have {lightgreen}LOST {green}%i {default}points for letting {lightgreen}Infected In The Safe Room!", Score);
		else if (Mode == 3)
			StatsPrintToChatAll("{olive}%s {default}has {lightgreen}LOST {green}%i {default}points for letting {lightgreen}Infected In The Safe Room!", UserName, Score);

		Score = Score * -1;
	}
	else if (AwardID == 98) // Round restart
	{
		UpdateMapStat("restarts", 1);

		if (!g_hCvar_EnableNegativeScore.BoolValue)
			return;

		Score = ModifyScoreDifficultyNR(g_hCvar_ActionScore[ACT_RESTART].IntValue, 2, 3, TEAM_SURVIVORS);
		Score = 400 - Score;

		if (Mode)
			StatsPrintToChat(User, "{lightgreen}ALL SURVIVORS {default}have {lightgreen}LOST {green}%i {default}points for {lightgreen}All Survivors Dying!", Score);

		Score = Score * -1;
	}
	else
	{
//#if DEBUG	
//	LogError("event_Award => %i", AwardID);
//  StatsPrintToChat(User, "[DEBUG] event_Award => %i", AwardID);
//#endif
		return;
	}

	char UpdatePoints[32];
	char UserID[MAX_LINE_WIDTH];
	GetClientRankAuthString(User, UserID, sizeof(UserID));

	FormatInGameMode(UpdatePoints, sizeof(UpdatePoints));

	char query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i%s WHERE steamid = '%s'", g_sDbPrefix, UpdatePoints, UpdatePoints, Score, AwardSQL, UserID);
	SendSQLUpdate(query);
}

/*
L4D2:
0 - End of Campaign (Not 100% Sure)
7 - End of Level (Not 100% Sure)
8 - End of Level (Not 100% Sure)
17 - Kill Tank
22 - Random Director Mob
23 - End of Level (Not 100% Sure)
40 - End of Campaign (Not 100% Sure)
67 - Protect Friendly
68 - Give Pain g_iPillsIndex
69 - Give g_iAdrenalineIndex
70 - Give Heatlh (Heal using Med Pack)
71 - End of Level (Not 100% Sure)
72 - End of Campaign (Not 100% Sure)
75 - Save Friendly from Ledge Grasp
76 - Save Friendly from Special Infected
80 - Hero Closet Rescue Survivor
81 - Kill Tank with no deaths
84 - Team Kill
85 - Incap Friendly
86 - Left Friendly for Dead
87 - Friendly Fire
89 - Incap Friendly
95 - Let infected in safe room
99 - Round Restart (All Dead)
*/

// Miscellaneous events and awards. See specific award for info.
void Event_Award_L4D2(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled())
		return;

	int User = GetClientOfUserId(event.GetInt("userid"));
	if (IsClientBot(User))
		return;

	int SubjectID = event.GetInt("subjectentid");
	int Mode = g_hCvar_AnnounceMode.IntValue;
	char UserName[MAX_LINE_WIDTH];
	GetClientName(User, UserName, sizeof(UserName));

	int Recipient;
	char RecipientName[MAX_LINE_WIDTH];

	int Score = 0;
	char AwardSQL[128];
	int AwardID = event.GetInt("award");

	//StatsPrintToChat(User, "[TEST] Your actions gave you award (ID = %i)", AwardID);

	if (AwardID == 67) // Protect friendly
	{
		if (!SubjectID)
			return;

		g_iProtectedFriendlyCounter[User]++;

		if (g_hTimerProtectedFriendly[User] != null)
			delete g_hTimerProtectedFriendly[User];

		g_hTimerProtectedFriendly[User] = CreateTimer(3.0, Timer_ProtectedFriendly, User);
		return;
	}

	if (AwardID == 68) // g_iPillsIndex given
	{
		if (!SubjectID)
			return;

		if (g_iCurrentGamemodeID == GAMEMODE_SURVIVAL && !g_hCvar_EnableSurvivalMedicPoints.BoolValue)
			return;

		Recipient = GetClientOfUserId(GetClientUserId(SubjectID));
		GivePills(User, Recipient);
		return;
	}

	if (AwardID == 69) // g_iAdrenalineIndex given
	{
		if (!SubjectID)
			return;

		if (g_iCurrentGamemodeID == GAMEMODE_SURVIVAL && !g_hCvar_EnableSurvivalMedicPoints.BoolValue)
			return;

		Recipient = GetClientOfUserId(GetClientUserId(SubjectID));
		GiveAdrenaline(User, Recipient);
		return;
	}

	if (AwardID == 85) // Incap friendly
	{
		if (!SubjectID)
			return;

		Recipient = GetClientOfUserId(GetClientUserId(SubjectID));
		PlayerIncap(User, Recipient);
		return;
	}

	if (AwardID == 80) // Respawn friendly
	{
		if (!SubjectID)
			return;

		Recipient = GetClientOfUserId(GetClientUserId(SubjectID));

		if (IsClientBot(Recipient))
			return;

		Score = ModifyScoreDifficulty(g_hCvar_HelpScore[HELP_RESCUE].IntValue, 2, 3, TEAM_SURVIVORS);
		GetClientName(Recipient, RecipientName, sizeof(RecipientName));
		Format(AwardSQL, sizeof(AwardSQL), ", award_rescue = award_rescue + 1");
		UpdateMapStat("points", Score);
		AddScore(User, Score);

		if (Score > 0)
		{
			if (Mode == 1 || Mode == 2) StatsPrintToChat(User, "You have earned {green}%i {default}points for Rescuing {olive}%s{default}!", Score, RecipientName);
			else if (Mode == 3) StatsPrintToChatAll("{olive}%s {default}has earned {green}%i {default}points for Rescuing {olive}%s{default}!", UserName, Score, RecipientName);
		}
	}
	else if (AwardID == 81) // Kill Tank with no deaths
	{
		Score = ModifyScoreDifficulty(0, 1, 1, TEAM_SURVIVORS);
		Format(AwardSQL, sizeof(AwardSQL), ", award_tankkillnodeaths = award_tankkillnodeaths + 1");
	}
// Moved to Event_PlayerDeath
//	else if (AwardID == 84 && !g_bCampaignOver) // Team kill
//	{
//		if (!SubjectID)
//			return;
//
//		Recipient = GetClientOfUserId(GetClientUserId(SubjectID));
//
//		Format(AwardSQL, sizeof(AwardSQL), ", award_teamkill = award_teamkill + 1");
//		Score = ModifyScoreDifficultyNR(GetConVarInt(g_hCvar_ActionScore[ACT_FFKILL]), 2, 4, TEAM_SURVIVORS);
//		Score = Score * -1;
//
//		if (Mode == 1 || Mode == 2)
//			StatsPrintToChat(User, "You have {lightgreen}LOST {green}%i {default}points for {lightgreen}Team Killing!", Score);
//		else if (Mode == 3)
//			StatsPrintToChatAll("{olive}%s {default}has {lightgreen}LOST {green}%i {default}points for {lightgreen}Team Killing!", UserName, Score);
//	}
	else if (AwardID == 86) // Left friendly for dead
	{
		Format(AwardSQL, sizeof(AwardSQL), ", award_left4dead = award_left4dead + 1");
		Score = ModifyScoreDifficulty(0, 1, 1, TEAM_SURVIVORS);
	}
	else if (AwardID == 95) // Let infected in safe room
	{
		Format(AwardSQL, sizeof(AwardSQL), ", award_letinsafehouse = award_letinsafehouse + 1");

		Score = 0;
		if (g_hCvar_EnableNegativeScore.BoolValue)
			Score = ModifyScoreDifficultyNR(g_hCvar_ActionScore[ACT_LET_INF_IN_SAFE_ROOM].IntValue, 2, 4, TEAM_SURVIVORS);
		else
			Mode = 0;

		if (Mode == 1 || Mode == 2) StatsPrintToChat(User, "You have {lightgreen}LOST {green}%i {default}points for letting {lightgreen}Infected In The Safe Room!", Score);
		else if (Mode == 3) StatsPrintToChatAll("{olive}%s {default}has {lightgreen}LOST {green}%i {default}points for letting {lightgreen}Infected In The Safe Room!", UserName, Score);

		Score = Score * -1;
	}
	else if (AwardID == 99) // Round restart
	{
		UpdateMapStat("restarts", 1);

		if (!g_hCvar_EnableNegativeScore.BoolValue)
			return;

		Score = ModifyScoreDifficultyNR(g_hCvar_ActionScore[ACT_RESTART].IntValue, 2, 3, TEAM_SURVIVORS);
		Score = 400 - Score;

		if (Mode)
			StatsPrintToChat(User, "{lightgreen}ALL SURVIVORS {default}have {lightgreen}LOST {green}%i {default}points for {lightgreen}All Survivors Dying!", Score);

		Score = Score * -1;
	}
	else
	{
//StatsPrintToChat(User, "[DEBUG] event_Award => %i", AwardID);
		return;
	}

	char UpdatePoints[32];
	char UserID[MAX_LINE_WIDTH];
	GetClientRankAuthString(User, UserID, sizeof(UserID));
	FormatInGameMode(UpdatePoints, sizeof(UpdatePoints));

	char query[1024];
	Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i%s WHERE steamid = '%s'", g_sDbPrefix, UpdatePoints, UpdatePoints, Score, AwardSQL, UserID);
	SendSQLUpdate(query);
}

// Scavenge halftime code.
void Event_ScavengeHalftime(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled() || g_bCampaignOver)
		return;

	g_bCampaignOver = true;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			switch (GetClientTeam(i))
			{
				case TEAM_SURVIVORS: InterstitialPlayerUpdate(i);
				case TEAM_INFECTED: DoInfectedFinalChecks(i);
			}
		}
	}
}

// Survival started code.
void Event_SurvivalStart(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled())
		return;

	SurvivalStart();
}

public SurvivalStart()
{
	UpdateMapStat("restarts", 1);
	g_bSurvivalStarted = true;
	g_fMapTimingStartTime = 0.0;
	g_bMapTimingBlocked = false;
	StartMapTiming();
}

// Car alarm triggered code.
void Event_CarAlarm(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled() || g_iCurrentGamemodeID == GAMEMODE_SURVIVAL || !g_hCvar_EnableNegativeScore.BoolValue)
		return;

	int Score = ModifyScoreDifficultyNR(g_hCvar_ActionScore[ACT_TRIGGERCARALERM].IntValue, 2, 3, TEAM_SURVIVORS);
	UpdateMapStat("caralarm", 1);

	if (Score <= 0)
		return;

	char UpdatePoints[32];
	char query[1024];

	FormatInGameMode(UpdatePoints, sizeof(UpdatePoints));

	int Mode = g_hCvar_AnnounceMode.IntValue;
	char iID[MAX_LINE_WIDTH];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i) && GetClientTeam(i) == TEAM_SURVIVORS)
		{
			GetClientRankAuthString(i, iID, sizeof(iID));
			Format(query, sizeof(query), "UPDATE %splayers SET %s = %s - %i WHERE steamid = '%s'", g_sDbPrefix, UpdatePoints, UpdatePoints, Score, iID);
			SendSQLUpdate(query);

			if (Mode)
				StatsPrintToChat(i, "{lightgreen}ALL SURVIVORS {default}have {lightgreen}LOST {green}%i {default}points for {lightgreen}Triggering the Car Alarm{default}!", Score);
		}
	}
}

// Reset Witch existence in the world when a new one is created.
void Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled())
		return;

	g_bWitchExists = true;
}

// Witch was crowned!
void Event_WitchCrowned(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled() || g_iCurrentGamemodeID == GAMEMODE_SURVIVAL)
		return;

	int Killer = GetClientOfUserId(event.GetInt("userid"));
	bool Crowned = event.GetBool("oneshot");

	if (Crowned && Killer > 0 && !IsClientBot(Killer) && IsClientConnected(Killer) && IsClientInGame(Killer))
	{
		char SteamID[MAX_LINE_WIDTH];
		GetClientRankAuthString(Killer, SteamID, sizeof(SteamID));

		int Score = ModifyScoreDifficulty(g_hCvar_WitchCrownedScore.IntValue, 2, 3, TEAM_SURVIVORS);
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
		Format(query, sizeof(query), "UPDATE %splayers SET %s = %s + %i, award_witchcrowned = award_witchcrowned + 1 WHERE steamid = '%s'", g_sDbPrefix, UpdatePoints, UpdatePoints, Score, SteamID);
		SendSQLUpdate(query);

		if (Score > 0 && g_hCvar_AnnounceMode.IntValue)
		{
			char Name[MAX_LINE_WIDTH];
			GetClientName(Killer, Name, sizeof(Name));
			StatsPrintToChatTeam(TEAM_SURVIVORS, "{olive}%s {default}has earned {green}%i {default}points for {green}Crowning the Witch{default}!", Name, Score);
		}
	}
}

// Witch was disturbed!
void Event_WitchDisturb(Event event, const char[] name, bool dontBroadcast)
{
	if (StatsDisabled())
		return;

	if (g_bWitchExists)
	{
		g_bWitchDisturb = true;

		int User = GetClientOfUserId(event.GetInt("userid"));

		if (!User)
			return;

		if (IsClientBot(User))
			return;

		char UserID[MAX_LINE_WIDTH];
		GetClientRankAuthString(User, UserID, sizeof(UserID));

		char query[1024];
		Format(query, sizeof(query), "UPDATE %splayers SET award_g_bwitchdisturb = award_g_bwitchdisturb + 1 WHERE steamid = '%s'", g_sDbPrefix, UserID);
		SendSQLUpdate(query);
	}
}
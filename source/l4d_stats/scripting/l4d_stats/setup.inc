#if defined _l4d_stats_setup_included
	#endinput
#endif
#define _l4d_stats_setup_included

void SetupConVars()
{
	// Plugin version public Cvar
	CreateConVar("l4d_stats_version", PLUGIN_VERSION, "Custom Player Stats Version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);

	// Disable setting Cvars
	g_hCvar_Difficulty = FindConVar("z_difficulty");
	g_hCvar_Gamemode   = FindConVar("mp_gamemode");
	g_hCvar_Cheats	   = FindConVar("sv_cheats");
	g_hCvar_Lan		   = FindConVar("sv_lan");

	if (g_hCvar_Lan.IntValue)
		LogMessage("ATTENTION! Plugin in LAN environment is based on IP address rather than Steam ID. The statistics are not reliable when they are base on IP!");

	// Game cvars
	g_hCvar_SurvivorLimit = FindConVar("survivor_limit");
	g_hCvar_InfectedLimit = FindConVar("z_max_player_zombies");
	g_iMaxPounceDamage	  = FindConVar("z_hunter_max_pounce_bonus_damage").IntValue;

	if (g_bLeft4Dead)
	{
		g_iMaxPounceDistance = FindConVar("z_pounce_damage_range_max").IntValue;
		g_iMinPounceDistance = FindConVar("z_pounce_damage_range_min").IntValue;
	}
	else if (g_bLeft4Dead2)
	{
		g_iMaxPounceDistance = 1024;
		g_iMinPounceDistance = 300;
	}

	// Administrative Cvars
	g_hCvar_AdminPlayerCleanLastOnTime							 = CreateConVar("l4d_stats_adm_cleanoldplayers", "2", "How many months old players (last online time) will be cleaned. 0 = Disabled", _, true, 0.0);
	g_hCvar_AdminPlayerCleanPlatime								 = CreateConVar("l4d_stats_adm_cleanplaytime", "30", "How many minutes of playtime to not get cleaned from stats. 0 = Disabled", _, true, 0.0);

	// Config/control Cvars
	g_hCvar_Enable												 = CreateConVar("l4d_stats_enable", "1", "Enable/Disable all stat tracking", _, true, 0.0, true, 1.0);
	g_hCvar_EnableRankVote										 = CreateConVar("l4d_stats_enablerankvote", "1", "Enable voting of team shuffle by player PPM (Points Per Minute)", _, true, 0.0, true, 1.0);
	g_hCvar_HumansNeeded										 = CreateConVar("l4d_stats_minhumans", "2", "Minimum Human players before stats will be enabled", _, true, 1.0, true, 4.0);
	g_hCvar_UpdateRate											 = CreateConVar("l4d_stats_updaterate", "90", "Number of seconds between Common Infected point earn announcement/update", _, true, 30.0);
	// g_hCvar_AnnounceRankMinChange = CreateConVar("l4d_stats_announcerankminpoint", "500", "Minimum change to points before rank change announcement", _, true, 0.0);
	g_hCvar_AnnounceRankChange									 = CreateConVar("l4d_stats_announcerank", "1", "Chat announcment for rank change", _, true, 0.0, true, 1.0);
	g_hCvar_AnnounceRankChangeIVal								 = CreateConVar("l4d_stats_announcerankinterval", "60", "Rank change check interval", _, true, 10.0);
	g_hCvar_AnnouncePlayerJoined								 = CreateConVar("l4d_stats_announceplayerjoined", "1", "Chat announcment for player joined.", _, true, 0.0, true, 1.0);
	g_hCvar_AnnounceMotd										 = CreateConVar("l4d_stats_announcemotd", "1", "Chat announcment for the message of the day.", _, true, 0.0, true, 1.0);
	g_hCvar_AnnounceMode										 = CreateConVar("l4d_stats_announcemode", "1", "Chat announcment mode. 0 = Off, 1 = Player Only, 2 = Player Only w/ Public Headshots, 3 = All Public", _, true, 0.0, true, 3.0);
	// g_hCvar_AnnounceSpecial = CreateConVar("l4d_stats_announcespecial", "1", "Chat announcment mode for special events. 0 = Off, 1 = Player Only, 2 = Print messages to all teams, 3 = Print messages to own team only, 4 = Print messages to own team and spectators only", _, true, 0.0, true, 4.0);
	g_hCvar_MedkitMode											 = CreateConVar("l4d_stats_medkitmode", "0", "Medkit point award mode. 0 = Based on amount healed, 1 = Static amount", _, true, 0.0, true, 1.0);
	g_hCvar_SiteURL												 = CreateConVar("l4d_stats_siteurl", "", "Community site URL, for rank panel display", _);
	g_hCvar_RankOnJoin											 = CreateConVar("l4d_stats_rankonjoin", "1", "Display player's rank when they connect. 0 = Disable, 1 = Enable", _, true, 0.0, true, 1.0);
	g_hCvar_SilenceChat											 = CreateConVar("l4d_stats_silencechat", "0", "Silence chat triggers. 0 = Show chat triggers, 1 = Silence chat triggers", _, true, 0.0, true, 1.0);
	g_hCvar_DisabledMessages									 = CreateConVar("l4d_stats_disabledmessages", "1", "Show 'Stats Disabled' messages, allow chat commands to work when stats disabled. 0 = Hide messages/disable chat, 1 = Show messages/allow chat", _, true, 0.0, true, 1.0);
	// g_hCvar_MaxPoints = CreateConVar("l4d_stats_maxpoints", "500", "Maximum number of points that can be earned in a single map. Normal = x1, Adv = x2, Expert = x3", _, true, 500.0);
	g_hCvar_DbTagPrefix											 = CreateConVar("l4d_stats_g_sdbprefix", "", "Prefix for your stats tables", _);
	// g_hCvar_LeaderboardTime = CreateConVar("l4d_stats_leaderboardtime", "14", "Time in days to show Survival Leaderboard times", _, true, 1.0);
	g_hCvar_EnableNegativeScore									 = CreateConVar("l4d_stats_enablenegativescore", "1", "Enable point losses (negative score)", _, true, 0.0, true, 1.0);
	g_hCvar_FriendlyFireMode									 = CreateConVar("l4d_stats_ffire_mode", "2", "Friendly fire mode. 0 = Normal, 1 = Cooldown, 2 = Damage based", _, true, 0.0, true, 2.0);
	g_hCvar_FriendlyFireMultiplier								 = CreateConVar("l4d_stats_ffire_multiplier", "1.5", "Friendly fire damage multiplier (Formula: Score = Damage * Multiplier)", _, true, 0.0);
	g_hCvar_FriendlyFireCooldown								 = CreateConVar("l4d_stats_ffire_cooldown", "10.0", "Time in seconds for friendly fire cooldown", _, true, 1.0);
	g_hCvar_FriendlyFireCooldownMode							 = CreateConVar("l4d_stats_ffire_cooldownmode", "1", "Friendly fire cooldown mode. 0 = Disable, 1 = Player specific, 2 = General", _, true, 0.0, true, 2.0);

	// Game mode Cvars
	g_hCvar_GameMode[GAMEMODE_COOP]								 = CreateConVar("l4d_stats_enablecoop", "1", "Enable/Disable coop stat tracking", _, true, 0.0, true, 1.0);
	g_hCvar_GameMode[GAMEMODE_SURVIVAL]							 = CreateConVar("l4d_stats_enablesv", "1", "Enable/Disable survival stat tracking", _, true, 0.0, true, 1.0);
	g_hCvar_GameMode[GAMEMODE_VERSUS]							 = CreateConVar("l4d_stats_enableversus", "1", "Enable/Disable versus stat tracking", _, true, 0.0, true, 1.0);
	g_hCvar_GameMode[GAMEMODE_TEAMVERSUS]						 = CreateConVar("l4d_stats_enableteamversus", "1", "[L4D2] Enable/Disable team versus stat tracking", _, true, 0.0, true, 1.0);
	g_hCvar_GameMode[GAMEMODE_REALISM]							 = CreateConVar("l4d_stats_enablerealism", "1", "[L4D2] Enable/Disable realism stat tracking", _, true, 0.0, true, 1.0);
	g_hCvar_GameMode[GAMEMODE_SCAVENGE]							 = CreateConVar("l4d_stats_enablescavenge", "1", "[L4D2] Enable/Disable scavenge stat tracking", _, true, 0.0, true, 1.0);
	g_hCvar_GameMode[GAMEMODE_TEAMSCAVENGE]						 = CreateConVar("l4d_stats_enableteamscavenge", "1", "[L4D2] Enable/Disable team scavenge stat tracking", _, true, 0.0, true, 1.0);
	g_hCvar_GameMode[GAMEMODE_REALISMVERSUS]					 = CreateConVar("l4d_stats_enablerealismvs", "1", "[L4D2] Enable/Disable realism versus stat tracking", _, true, 0.0, true, 1.0);
	g_hCvar_GameMode[GAMEMODE_TEAMREALISMVERSUS]				 = CreateConVar("l4d_stats_enableteamrealismvs", "1", "[L4D2] Enable/Disable team realism versus stat tracking", _, true, 0.0, true, 1.0);
	g_hCvar_GameMode[GAMEMODE_OTHERMUTATIONS]					 = CreateConVar("l4d_stats_enablemutations", "1", "[L4D2] Enable/Disable mutations stat tracking", _, true, 0.0, true, 1.0);

	// Game mode depended Cvars
	g_hCvar_RealismMultiplier									 = CreateConVar("l4d_stats_realismmultiplier", "1.4", "[L4D2] Realism score multiplier for coop score", _, true, 1.0);
	g_hCvar_RealismVersusSurMultiplier							 = CreateConVar("l4d_stats_realismvsmultiplier_s", "1.4", "[L4D2] Realism score multiplier for survivors versus score", _, true, 1.0);
	g_hCvar_RealismVersusInfMultiplier							 = CreateConVar("l4d_stats_realismvsmultiplier_i", "0.6", "[L4D2] Realism score multiplier for infected versus score", _, true, 0.0, true, 1.0);
	g_hCvar_EnableSurvivalMedicPoints							 = CreateConVar("l4d_stats_medicpointssv", "0", "Survival medic points enabled", _, true, 0.0, true, 1.0);

	// Infected point Cvars
	g_hCvar_KillInfectedClassScore[CLASS_COMMON]				 = CreateConVar("l4d_stats_infected", "1", "Base score for killing a Common Infected", _, true, 1.0);
	g_hCvar_KillInfectedClassScore[CLASS_HUNTER]				 = CreateConVar("l4d_stats_hunter", "2", "Base score for killing a Hunter", _, true, 1.0);
	g_hCvar_KillInfectedClassScore[CLASS_SMOKER]				 = CreateConVar("l4d_stats_smoker", "3", "Base score for killing a Smoker", _, true, 1.0);
	g_hCvar_KillInfectedClassScore[CLASS_BOOMER]				 = CreateConVar("l4d_stats_boomer", "5", "Base score for killing a Boomer", _, true, 1.0);
	g_hCvar_KillInfectedClassScore[CLASS_SPITTER]				 = CreateConVar("l4d_stats_spitter", "5", "[L4D2] Base score for killing a Spitter", _, true, 1.0);
	g_hCvar_KillInfectedClassScore[CLASS_JOCKEY]				 = CreateConVar("l4d_stats_jockey", "5", "[L4D2] Base score for killing a Jockey", _, true, 1.0);
	g_hCvar_KillInfectedClassScore[CLASS_CHARGER]				 = CreateConVar("l4d_stats_charger", "5", "[L4D2] Base score for killing a Charger", _, true, 1.0);
	g_hCvar_InfectedDamagePerPoint								 = CreateConVar("l4d_stats_infected_damage", "2", "The amount of damage inflicted to Survivors to earn 1 point", _, true, 1.0);

	// Misc personal gain Cvars
	g_hCvar_GiveItemClassScore[ITEM_PILLS]						 = CreateConVar("l4d_stats_g_ipillsIndex", "15", "Base score for giving g_iPillsIndex to a friendly", _, true, 1.0);
	g_hCvar_GiveItemClassScore[ITEM_ADRENALINE]					 = CreateConVar("l4d_stats_g_iadrenalineIndex", "15", "[L4D2] Base score for giving g_iAdrenalineIndex to a friendly", _, true, 1.0);
	g_hCvar_GiveItemClassScore[ITEM_MEDKIT]						 = CreateConVar("l4d_stats_medkit", "20", "Base score for using a Medkit on a friendly", _, true, 1.0);
	g_hCvar_GiveItemClassScore[ITEM_DEFIB]						 = CreateConVar("l4d_stats_defib", "20", "[L4D2] Base score for using a Defibrillator on a friendly", _, true, 1.0);
	g_hCvar_SaveFromInfectedAbilityScore[INF_ABILITY_TONGUEDRAG] = CreateConVar("l4d_stats_smokerdrag", "5", "Base score for saving a friendly from a Smoker Tongue Drag", _, true, 1.0);
	g_hCvar_SaveFromInfectedAbilityScore[INF_ABILITY_RIDE]		 = CreateConVar("l4d_stats_jockeyride", "10", "[L4D2] Base score for saving a friendly from a Jockey Ride", _, true, 1.0);
	g_hCvar_SaveFromInfectedAbilityScore[INF_ABILITY_PUMMEL]	 = CreateConVar("l4d_stats_chargerplummel", "10", "[L4D2] Base score for saving a friendly from a Charger Plummel", _, true, 1.0);
	g_hCvar_SaveFromInfectedAbilityScore[INF_ABILITY_CARRY]		 = CreateConVar("l4d_stats_chargercarry", "15", "[L4D2] Base score for saving a friendly from a Charger Carry", _, true, 1.0);
	g_hCvar_SaveFromInfectedAbilityScore[INF_ABILITY_CHOKE]		 = CreateConVar("l4d_stats_chokepounce", "10", "Base score for saving a friendly from a Hunter Pounce / Smoker Choke", _, true, 1.0);
	g_hCvar_HelpScore[HELP_REVIVE]								 = CreateConVar("l4d_stats_revive", "15", "Base score for Revive a friendly from Incapacitated state", _, true, 1.0);
	g_hCvar_HelpScore[HELP_RESCUE]								 = CreateConVar("l4d_stats_rescue", "10", "Base score for Rescue a friendly from a closet", _, true, 1.0);
	g_hCvar_HelpScore[HELP_PROTECT]								 = CreateConVar("l4d_stats_protect", "3", "Base score for Protect a friendly in combat", _, true, 1.0);
	g_hCvar_PlayerLedgeSuccessScore								 = CreateConVar("l4d_stats_ledgegrap", "15", "Base score for causing a survivor to grap a ledge", _, true, 1.0);
	g_hCvar_MatadorScore										 = CreateConVar("l4d_stats_matador", "30", "[L4D2] Base score for killing a charging Charger with a melee weapon", _, true, 1.0);
	g_hCvar_WitchCrownedScore									 = CreateConVar("l4d_stats_witchcrowned", "30", "Base score for Crowning a Witch", _, true, 1.0);

	// Team gain Cvars
	g_hCvar_KillTankScore										 = CreateConVar("l4d_stats_tank", "25", "Base team score for killing a Tank", _, true, 1.0);
	g_hCvar_SurvivedPanicHordeScore								 = CreateConVar("l4d_stats_panic", "25", "Base team score for surviving a Panic Event with no Incapacitations", _, true, 1.0);
	g_hCvar_SurvivedBoomerHordeScore							 = CreateConVar("l4d_stats_boomermob", "10", "Base team score for surviving a Boomer Mob with no Incapacitations", _, true, 1.0);
	g_hCvar_ReachedSafeHouseScore								 = CreateConVar("l4d_stats_safehouse", "10", "Base score for reaching a Safe House", _, true, 1.0);
	g_hCvar_NotDisturbingWitchScore								 = CreateConVar("l4d_stats_witch", "10", "Base score for Not Disturbing a Witch", _, true, 1.0);
	g_hCvar_VictorySurvivorsScore								 = CreateConVar("l4d_stats_campaign", "5", "Base score for Completing a Campaign", _, true, 1.0);
	g_hCvar_VictoryInfectedScore								 = CreateConVar("l4d_stats_infected_win", "30", "Base victory score for Infected Team", _, true, 1.0);

	// Point loss Cvars
	g_hCvar_ActionScore[ACT_FF]									 = CreateConVar("l4d_stats_ffire", "25", "Base score for Friendly Fire", _, true, 1.0);
	g_hCvar_ActionScore[ACT_FFINCAP]							 = CreateConVar("l4d_stats_fincap", "75", "Base score for a Friendly Incap", _, true, 1.0);
	g_hCvar_ActionScore[ACT_FFKILL]								 = CreateConVar("l4d_stats_fkill", "250", "Base score for a Friendly Kill", _, true, 1.0);
	g_hCvar_ActionScore[ACT_LET_INF_IN_SAFE_ROOM]				 = CreateConVar("l4d_stats_insaferoom", "5", "Base score for letting Infected in the Safe Room", _, true, 1.0);
	g_hCvar_ActionScore[ACT_RESTART]							 = CreateConVar("l4d_stats_restart", "100", "Base score for a Round Restart", _, true, 1.0);
	g_hCvar_ActionScore[ACT_TRIGGERCARALERM]					 = CreateConVar("l4d_stats_caralarm", "50", "[L4D2] Base score for a Triggering Car Alarm", _, true, 1.0);
	g_hCvar_MedkitUsedPointPenalty								 = CreateConVar("l4d_stats_medkitpenalty", "0.1", "Score reduction for all Survivor earned points for each used Medkit (Formula: Score = NormalPoints * (1 - MedkitsUsed * MedkitPenalty))", _, true, 0.0, true, 0.5);
	g_hCvar_MedkitUsedPointPenaltyMax							 = CreateConVar("l4d_stats_medkitpenaltymax", "1.0", "Maximum score reduction (the score reduction will not go over this value when a Medkit is used)", _, true, 0.0, true, 1.0);
	g_hCvar_MedkitUsedFree										 = CreateConVar("l4d_stats_medkitpenaltyfree", "0", "Team Survivors can use this many Medkits for free without any reduction to the score", _, true, 0.0);
	g_hCvar_MedkitUsedRealismFree								 = CreateConVar("l4d_stats_medkitpenaltyfree_r", "4", "Team Survivors can use this many Medkits for free without any reduction to the score when playing in Realism gamemodes (-1 = use the value in l4d_stats_medkitpenaltyfree)", _, true, -1.0);
	g_hCvar_MedkitBotMode										 = CreateConVar("l4d_stats_medkitbotmode", "1", "Add score reduction when bot uses a medkit. 0 = No, 1 = Bot uses a Medkit to a human player, 2 = Bot uses a Medkit to other than itself, 3 = Yes", _, true, 0.0, true, 2.0);
	g_hCvar_BotScoreMultiplier									 = CreateConVar("l4d_stats_botscoremultiplier", "1.0", "Multiplier to use when receiving bot related score penalty. 0 = Disable", _, true, 0.0);

	// Survivor point Cvars
	g_hCvar_SurvivorDeathScore									 = CreateConVar("l4d_stats_survivor_death", "40", "Base score for killing a Survivor", _, true, 1.0);
	g_hCvar_SurvivorIncapScore									 = CreateConVar("l4d_stats_survivor_incap", "15", "Base score for incapacitating a Survivor", _, true, 1.0);

	// Hunter point Cvars
	g_hCvar_HunterPerfectPounceDamage							 = CreateConVar("l4d_stats_perfectpouncedamage", "25", "The amount of damage from a pounce to earn Perfect Pounce (Death From Above) success points", _, true, 1.0);
	g_hCvar_HunterPerfectPounceSuccess							 = CreateConVar("l4d_stats_perfectpouncesuccess", "25", "Base score for a successful Perfect Pounce", _, true, 1.0);
	g_hCvar_HunterNicePounceDamage								 = CreateConVar("l4d_stats_nicepouncedamage", "15", "The amount of damage from a pounce to earn Nice Pounce (Pain From Above) success points", _, true, 1.0);
	g_hCvar_HunterNicePounceSuccess								 = CreateConVar("l4d_stats_nicepouncesuccess", "10", "Base score for a successful Nice Pounce", _, true, 1.0);
	g_hCvar_HunterDamageCap										 = CreateConVar("l4d_stats_hunterdamagecap", "25", "Hunter stored damage cap", _, true, 25.0);

	// Boomer point Cvars
	g_hCvar_BoomerSuccessScore									 = CreateConVar("l4d_stats_boomersuccess", "5", "Base score for a successfully vomiting on survivor", _, true, 1.0);
	g_hCvar_BoomerPerfectHits									 = CreateConVar("l4d_stats_boomerperfecthits", "4", "The number of survivors that needs to get blinded to earn Boomer Perfect Vomit Award and success points", _, true, 4.0);
	g_hCvar_BoomerPerfectSuccessScore							 = CreateConVar("l4d_stats_boomerperfectsuccess", "30", "Base score for a successful Boomer Perfect Vomit", _, true, 1.0);

	// Tank point Cvars
	g_hCvar_TankScoreDamageCap									 = CreateConVar("l4d_stats_tankdmgcap", "500", "Maximum inflicted damage done by Tank to earn Infected damagepoints", _, true, 150.0);
	g_hCvar_TankScoreDamageTotal								 = CreateConVar("l4d_stats_bulldozer", "200", "Damage inflicted by Tank to earn Bulldozer Award and success points", _, true, 200.0);
	g_hCvar_TankScoreDamageTotalSuccessScore					 = CreateConVar("l4d_stats_bulldozersuccess", "50", "Base score for Bulldozer Award", _, true, 1.0);
	g_hCvar_TankScoreThrowRockSuccessScore						 = CreateConVar("l4d_stats_tankthrowrocksuccess", "5", "Base score for a Tank thrown rock hit", _, true, 0.0);

	// Charger point Cvars
	g_hCvar_ChargerRamSuccessScore								 = CreateConVar("l4d_stats_chargerramsuccess", "40", "Base score for a successful Charger Scattering Ram", _, true, 1.0);
	g_hCvar_ChargerRamHitsPerPoints								 = CreateConVar("l4d_stats_chargerramhits", "4", "The number of impacts on survivors to earn Scattering Ram Award and success points", _, true, 2.0);

	// Misc L4D2 Cvars
	g_hCvar_AmmoUpgradeAddedScore								 = CreateConVar("l4d_stats_deployammoupgrade", "10", "[L4D2] Base score for deploying ammo upgrade pack", _, true, 0.0);
	g_hCvar_GascanPouredScore									 = CreateConVar("l4d_stats_gascanpoured", "5", "[L4D2] Base score for successfully pouring a gascan", _, true, 0.0);

	// Other Cvars
	g_hCvar_Top10PPMMin											 = CreateConVar("l4d_stats_top10ppmplaytime", "30", "Minimum playtime (minutes) to show in top10 ppm list", _, true, 1.0);
	g_hCvar_RankVoteTime										 = CreateConVar("l4d_stats_rankvotetime", "20", "Time to wait people to vote", _, true, 10.0);
	g_hCvar_SoundsEnabled										 = CreateConVar("l4d_stats_soundsenabled", "1", "Play sounds on certain events", _, true, 0.0, true, 1.0);

	g_hCvar_Lan.AddChangeHook(OnLanCvarChanged);
	g_hCvar_UpdateRate.AddChangeHook(OnTimerCvarChanged);
	g_hCvar_DbTagPrefix.AddChangeHook(OnDbPrefixCvarChanged);
	g_hCvar_Gamemode.AddChangeHook(OnGamemodeChanged);
	g_hCvar_Difficulty.AddChangeHook(OnDifficultyChanged);
}

void IniStringMaps()
{
	if (!g_hMapTimingSurvivors)
		g_hMapTimingSurvivors = new StringMap();

	if (!g_hMapTimingInfected)
		g_hMapTimingInfected = new StringMap();

	if (!g_hFriendlyFireDamageTrie)
		g_hFriendlyFireDamageTrie = new StringMap();

	if (!g_hPlayerRankVoteTrie)
		g_hPlayerRankVoteTrie = new StringMap();
}

void IniSDKCalls()
{
	// SDK handles for team shuffle
	GameData gd = new GameData("l4d_stats");
	if (!gd)
	{
		LogError("Could not load gamedata/l4d_stats.txt");
		LogMessage("Rank Vote is disabled because could not load gamedata/l4d_stats.txt");
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "SetHumanSpec");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDKCall_SetHumanSpec = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "TakeOverBot");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	g_hSDCall_TakeOverBot = EndPrepSDKCall();

	delete gd;
}

void PrechaeResources()
{
	if (g_bLeft4Dead)
	{
		strcopy(g_sStatsSound_MapTime_Start, sizeof(g_sStatsSound_MapTime_Start), SOUND_MAPTIME_START_L4D1);
		strcopy(g_SStatsSound_MapTime_Improve, sizeof(g_SStatsSound_MapTime_Improve), SOUND_MAPTIME_IMPROVE_L4D1);
		strcopy(g_sStatsSound_Rankmenu_Show, sizeof(g_sStatsSound_Rankmenu_Show), SOUND_RANKMENU_SHOW_L4D1);
		strcopy(g_sStatsSound_Boomer_Vomit, sizeof(g_sStatsSound_Boomer_Vomit), SOUND_BOOMER_VOMIT_L4D1);
		strcopy(g_sStatsSound_Hunter_Perfect, sizeof(g_sStatsSound_Hunter_Perfect), SOUND_HUNTER_PERFECT_L4D1);
		strcopy(g_sStatsSound_Tank_Bulldozer, sizeof(g_sStatsSound_Tank_Bulldozer), SOUND_TANK_BULLDOZER_L4D1);
	}
	else if (g_bLeft4Dead2)
	{
		strcopy(g_sStatsSound_MapTime_Start, sizeof(g_sStatsSound_MapTime_Start), SOUND_MAPTIME_START_L4D2);
		strcopy(g_SStatsSound_MapTime_Improve, sizeof(g_SStatsSound_MapTime_Improve), SOUND_MAPTIME_IMPROVE_L4D2);
		strcopy(g_sStatsSound_Rankmenu_Show, sizeof(g_sStatsSound_Rankmenu_Show), SOUND_RANKMENU_SHOW_L4D2);
		strcopy(g_sStatsSound_Boomer_Vomit, sizeof(g_sStatsSound_Boomer_Vomit), SOUND_BOOMER_VOMIT_L4D2);
		strcopy(g_sStatsSound_Hunter_Perfect, sizeof(g_sStatsSound_Hunter_Perfect), SOUND_HUNTER_PERFECT_L4D2);
		strcopy(g_sStatsSound_Tank_Bulldozer, sizeof(g_sStatsSound_Tank_Bulldozer), SOUND_TANK_BULLDOZER_L4D2);
	}

	// Sounds
	g_bEnableSounds_Rankvote		= PrecacheSound(SOUND_RANKVOTE);				   // Sound from rankvote team switch
	g_bEnableSounds_Maptime_Start	= PrecacheSound(g_sStatsSound_MapTime_Start);	   // Sound map timer start
	g_bEnableSounds_Maptime_Improve = PrecacheSound(g_SStatsSound_MapTime_Improve);	   // Sound from improving personal map timing
	g_bEnableSounds_Rankmenu_Show	= PrecacheSound(g_sStatsSound_Rankmenu_Show);	   // Sound from showing the rankmenu
	g_bEnableSounds_Boomer_Vomit	= PrecacheSound(g_sStatsSound_Boomer_Vomit);	   // Sound from a successful boomer vomit (Perfect Blindness)
	g_bEnableSounds_Hunter_Perfect	= PrecacheSound(g_sStatsSound_Hunter_Perfect);	   // Sound from a hunter perfect pounce (Death From Above)
	g_bEnableSounds_Tank_Bulldozer	= PrecacheSound(g_sStatsSound_Tank_Bulldozer);	   // Sound from a tank bulldozer

	if (g_bLeft4Dead2) g_bEnableSounds_Charger_Ram = PrecacheSound(SOUND_CHARGER_RAM);	  // Sound from a charger scattering ram
	else g_bEnableSounds_Charger_Ram = false;
}

void CreateNatives()
{
	CreateNative("L4DStats.TotalPlayer.get", Native_GetTotalPlayer);
	CreateNative("L4DStats.Connected", Native_IsConnected);
	CreateNative("L4DStats.CheckDBValidity", Native_CheckDBValidity)
	CreateNative("L4DStats.CheckMap", Native_CheckMap);
	CreateNative("L4DStats.CheckPlayer", Native_CheckPlayer);
	CreateNative("L4DStats.GetSteamID", Native_GetPlayerSteamID);
	CreateNative("L4DStats.GetName", Native_GetPlayerName);
	CreateNative("L4DStats.GetPoints", Native_GetPlayerPoints);
	CreateNative("L4DStats.GetTime", Native_GetPlayerTime);
	CreateNative("L4DStats.GetPPM", Native_GetPlayerPPM);
	CreateNative("L4DStats.GetRank", Native_GetPlayerRank);
}

void OnLanCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (g_hCvar_Lan.IntValue)
		LogMessage("ATTENTION! Plugin in LAN environment is based on IP address rather than Steam ID. The statistics are not reliable when they are base on IP!");
}

// Update the Database prefix when the Cvar is changed.
void OnDbPrefixCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_hCvar_DbTagPrefix)
	{
		if (StrEqual(g_sDbPrefix, newValue))
			return;

		if (db && !CheckDatabaseValidity(g_sDbPrefix))
		{
			strcopy(g_sDbPrefix, sizeof(g_sDbPrefix), oldValue);
			g_hCvar_DbTagPrefix.SetString(g_sDbPrefix);
		}
		else
			strcopy(g_sDbPrefix, sizeof(g_sDbPrefix), newValue);
	}
}

// Update the Update Timer when the Cvar is changed.
void OnTimerCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_hCvar_UpdateRate)
	{
		if (g_hUpdateTimer != null)
			delete g_hUpdateTimer;

		int NewTime	   = StringToInt(newValue);
		g_hUpdateTimer = CreateTimer(float(NewTime), Timer_ShowTimerScore, _, TIMER_REPEAT);
	}
}

// Update the g_sCurrentGamemode when the Cvar is changed.
void OnDifficultyChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_hCvar_Difficulty)
	{
		g_fMapTimingStartTime = -1.0;
		g_bMapTimingBlocked	  = true;
	}
}

// Update the g_sCurrentGamemode when the Cvar is changed.
void OnGamemodeChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_hCvar_Gamemode)
	{
		g_hCvar_Gamemode.GetString(g_sCurrentGamemode, sizeof(g_sCurrentGamemode));
		g_iCurrentGamemodeID = GetCurrentGamemodeID();
	}
}
#if defined _skill_detect_setup_included
    #endinput
#endif
#define _skill_detect_setup_included

void SetupForwards()
{
    g_hForwardSkeet            = new GlobalForward("SkillDetect_OnSkeet", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
    g_hForwardJockeySkeet      = new GlobalForward("SkillDetect_OnJockeySkeet", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
    g_hForwardSIShove          = new GlobalForward("SkillDetect_OnSpecialShoved", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    g_hForwardHunterDeadstop   = new GlobalForward("SkillDetect_OnHunterDeadstop", ET_Ignore, Param_Cell, Param_Cell);
    g_hForwardBoomerPop        = new GlobalForward("SkillDetect_OnBoomerPop", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Float);
    g_hForwardLevel            = new GlobalForward("SkillDetect_OnChargerLevel", ET_Ignore, Param_Cell, Param_Cell);
    g_hForwardLevelHurt        = new GlobalForward("SkillDetect_OnChargerLevelHurt", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    g_hForwardCrown            = new GlobalForward("SkillDetect_OnWitchCrown", ET_Ignore, Param_Cell);
    g_hForwardDrawCrown        = new GlobalForward("SkillDetect_OnWitchDrawCrown", ET_Ignore, Param_Cell);
    g_hForwardTongueCut        = new GlobalForward("SkillDetect_OnTongueCut", ET_Ignore, Param_Cell, Param_Cell);
    g_hForwardSmokerSelfClear  = new GlobalForward("SkillDetect_OnSmokerSelfClear", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    g_hForwardRockSkeeted      = new GlobalForward("SkillDetect_OnTankRockSkeeted", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    g_hForwardRockEaten        = new GlobalForward("SkillDetect_OnTankRockEaten", ET_Ignore, Param_Cell, Param_Cell);
    g_hForwardHunterDP         = new GlobalForward("SkillDetect_OnHunterHighPounce", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Float, Param_Cell);
    g_hForwardJockeyDP         = new GlobalForward("SkillDetect_OnJockeyHighPounce", ET_Ignore, Param_Cell, Param_Cell, Param_Float, Param_Cell);
    g_hForwardDeathCharge      = new GlobalForward("SkillDetect_OnDeathCharge", ET_Ignore, Param_Cell, Param_Cell, Param_Float, Param_Float, Param_Cell, Param_Cell);
    g_hForwardChargingSkeet    = new GlobalForward("SkillDetect_OnChargingSkeet", ET_Ignore, Param_Cell, Param_Cell, Param_Float);
    g_hForwardClear            = new GlobalForward("SkillDetect_OnSpecialClear", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Float, Param_Cell);
    g_hForwardVomitLanded      = new GlobalForward("SkillDetect_OnBoomerVomitLanded", ET_Ignore, Param_Cell, Param_Cell);
    g_hForwardBHopStreak       = new GlobalForward("SkillDetect_OnBunnyHopStreak", ET_Ignore, Param_Cell, Param_Cell, Param_Float);
    g_hForwardAlarmTriggered   = new GlobalForward("SkillDetect_OnCarAlarmTriggered", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    g_hForwardNumImpacts       = new GlobalForward("SkillDetect_OnMultipleImpacts", ET_Ignore, Param_Cell, Param_Cell);
    g_hForwardPopStagger       = new GlobalForward("SkillDetect_OnBoomerPopStagger", ET_Ignore, Param_Cell, Param_Cell, Param_Array);
    g_hForwardBoomerStaggerTeammate = new GlobalForward("SkillDetect_OnBoomerStaggerTeammate", ET_Ignore, Param_Cell, Param_Cell);
}

void SetupConVars()
{
    // cvars: config
    g_hCvar_RepSkeet                    = CreateConVar("l4d2_skill_detect_report_skeet", "1", "Enable skeet reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepJockeySkeet              = CreateConVar("l4d2_skill_detect_report_jockey_skeet", "1", "Enable jockey skeet reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepLevel                    = CreateConVar("l4d2_skill_detect_report_level", "1", "Enable level reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepHurtLevel                = CreateConVar("l4d2_skill_detect_report_hurtlevel", "1", "Enable hurt-level reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepCrow                     = CreateConVar("l4d2_skill_detect_report_crow", "1", "Enable crow reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepDrawCrow                 = CreateConVar("l4d2_skill_detect_report_drawcrow", "1", "Enable draw-crow reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepTongueCut                = CreateConVar("l4d2_skill_detect_report_tonguecut", "1", "Enable tongue-cut reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepSelfClear                = CreateConVar("l4d2_skill_detect_report_sc", "1", "Enable self clear reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepSelfClearShove           = CreateConVar("l4d2_skill_detect_report_scs", "1", "Enable self clear Shove reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepRockSkeet                = CreateConVar("l4d2_skill_detect_report_rockskeet", "1", "Enable rock-skeet reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepDeadStop                 = CreateConVar("l4d2_skill_detect_report_deadstop", "1", "Enable deadstop reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepPop                      = CreateConVar("l4d2_skill_detect_report_pop", "1", "Enable pop reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepShove                    = CreateConVar("l4d2_skill_detect_report_shove", "1", "Enable shove reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepHunterDP                 = CreateConVar("l4d2_skill_detect_report_hunterdp", "1", "Enable hunter DP reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepJockeyDP                 = CreateConVar("l4d2_skill_detect_report_jockeydp", "1", "Enable jockey DP reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepDeathCharge              = CreateConVar("l4d2_skill_detect_report_deadcharger", "1", "Enable deadcharger reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepChargingSkeet            = CreateConVar("l4d2_skill_detect_report_chargerskeet", "1", "Enable charger-skeet reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepInstanClear              = CreateConVar("l4d2_skill_detect_report_instanclear", "1", "Enable instan-clear reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepBhopStreak               = CreateConVar("l4d2_skill_detect_report_bhop", "1", "Enable bhop streak reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepCarAlarm                 = CreateConVar("l4d2_skill_detect_report_caralarm", "1", "Enable car alarm reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepNumImpacts               = CreateConVar("l4d2_skill_detect_report_multi_impacts", "1", "Enable multi impact reporting.", FCVAR_NONE, true, 0.0, true, 1.0); 
    g_hCvar_RepPopStagger               = CreateConVar("l4d2_skill_detect_report_popstagger", "1", "Enable boomer pop stagger reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepVomitLanded              = CreateConVar("l4d2_skill_detect_report_vomitlanded", "1", "Enable boomer vomit landed reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepBoomerStaggerTeammate    = CreateConVar("l4d2_skill_detect_report_boomerstaggerteammate", "0", "Enable boomer stagger teammate reporting.", FCVAR_NONE, true, 0.0, true, 1.0)

    g_hCvar_AllowMelee                  = CreateConVar("l4d2_skill_detect_skeet_allowmelee", "1", "Whether to count/forward melee skeets.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_AllowSniper                 = CreateConVar("l4d2_skill_detect_skeet_allowsniper", "1", "Whether to count/forward sniper/magnum headshots as skeets.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_AllowGLSkeet                = CreateConVar("l4d2_skill_detect_skeet_allowgl", "1", "Whether to count/forward direct GL hits as skeets.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_HunterDPThresh              = CreateConVar("l4d2_skill_detect_hunterdp_height", "400", "Minimum height of hunter pounce for it to count as a DP.", FCVAR_NONE, true, 0.0, false);
    g_hCvar_JockeyDPThresh              = CreateConVar("l4d2_skill_detect_jockeydp_height", "400", "How much height distance a jockey must make for his 'DP' to count as a reportable highpounce.", FCVAR_NONE, true, 0.0, false);
    g_hCvar_ClearThreh                  = CreateConVar("l4d2_skill_detect_clear_max_time", "1.0", "How much time a clear must last for it to count.", FCVAR_NONE, true, 0.0, false);
    g_hCvar_DeathChargeHeight           = CreateConVar("l4d2_skill_detect_deathcharge_height", "375.0", "How much height distance a charger must take its victim for a deathcharge to be reported.", FCVAR_NONE, true, 0.0, false);
    g_hCvar_DeathChargeHeightBlow       = CreateConVar("l4d2_skill_detect_deathcharge_height_blow", "200.0", "How much height distance a charger must take its victim for a deathcharge to be reported when blown up.", FCVAR_NONE, true, 0.0, false);
    g_hCvar_DeathChargeBlowCheckHealth  = CreateConVar("l4d2_skill_detect_deathcharge_blow_check_health", "0", "Whether to check health when being blown up by a charger.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_InstaTime                   = CreateConVar("l4d2_skill_detect_instaclear_time", "0.75", "A clear within this time (in seconds) counts as an insta-clear.", FCVAR_NONE, true, 0.0, false);
    g_hCvar_BHopMinStreak               = CreateConVar("l4d2_skill_detect_bhopstreak", "3", "The lowest bunnyhop streak that will be reported.", FCVAR_NONE, true, 0.0, false);
    g_hCvar_BHopMinInitSpeed            = CreateConVar("l4d2_skill_detect_bhopinitspeed", "150", "The minimal speed of the first jump of a bunnyhopstreak (0 to allow 'hops' from standstill).", FCVAR_NONE, true, 0.0, false);
    g_hCvar_BHopContSpeed               = CreateConVar("l4d2_skill_detect_bhopkeepspeed", "300", "The minimal speed at which hops are considered succesful even if not speed increase is made.", FCVAR_NONE, true, 0.0, false);

}

void SetupStringMaps()
{
   g_hMapWeapons = new StringMap();
    g_hMapWeapons.SetValue("hunting_rifle", WPTYPE_SNIPER);
    g_hMapWeapons.SetValue("sniper_military", WPTYPE_SNIPER);
    g_hMapWeapons.SetValue("sniper_awp", WPTYPE_SNIPER);
    g_hMapWeapons.SetValue("sniper_scout", WPTYPE_SNIPER);
    g_hMapWeapons.SetValue("pistol_magnum", WPTYPE_MAGNUM);
    g_hMapWeapons.SetValue("grenade_launcher_projectile", WPTYPE_GL);

    g_hMapEntityCreated = new StringMap();
    g_hMapEntityCreated.SetValue("tank_rock", OEC_TANKROCK);
    g_hMapEntityCreated.SetValue("witch", OEC_WITCH);
    g_hMapEntityCreated.SetValue("trigger_hurt", OEC_TRIGGER);
    g_hMapEntityCreated.SetValue("prop_car_alarm", OEC_CARALARM);
    g_hMapEntityCreated.SetValue("prop_car_glass", OEC_CARGLASS);
}
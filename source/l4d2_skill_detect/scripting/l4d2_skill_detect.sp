#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <actions>
#include <left4dhooks>
#include <l4d2util>
#include <colors>

bool g_bSIAdjustment = false;

// Map values: weapon type
enum strWeaponType
{
    WPTYPE_SNIPER,
    WPTYPE_MAGNUM,
    WPTYPE_GL
};

// Map values: OnEntityCreated classname
enum strOEC
{
    OEC_WITCH,
    OEC_TANKROCK,
    OEC_TRIGGER,
    OEC_CARALARM,
    OEC_CARGLASS
};

GlobalForward
    g_hForwardSkeet           = null,
    g_hForwardHunterDeadstop  = null,
    g_hForwardSIShove         = null,
    g_hForwardBoomerPop       = null,
    g_hForwardLevel           = null,
    g_hForwardLevelHurt       = null,
    g_hForwardCrown           = null,
    g_hForwardDrawCrown       = null,
    g_hForwardTongueCut       = null,
    g_hForwardSmokerSelfClear = null,
    g_hForwardRockSkeeted     = null,
    g_hForwardRockEaten       = null,
    g_hForwardHunterDP        = null,
    g_hForwardJockeyDP        = null,
    g_hForwardDeathCharge     = null,
    g_hForwardChargingSkeet   = null,
    g_hForwardClear           = null,
    g_hForwardVomitLanded     = null,
    g_hForwardBHopStreak      = null,
    g_hForwardAlarmTriggered  = null;

StringMap
    g_hMapWeapons       = null,       // weapon check
    g_hMapEntityCreated = null;       // getting classname of entity created

// cvars
ConVar
    g_hCvar_Debug,

    g_hCvar_Report,
    g_hCvar_RepSkeet,
    g_hCvar_RepLevel,
    g_hCvar_RepHurtLevel,
    g_hCvar_RepCrow,
    g_hCvar_RepDrawCrow,
    g_hCvar_RepTongueCut,
    g_hCvar_RepSelfClear,
    g_hCvar_RepSelfClearShove,
    g_hCvar_RepRockSkeet,
    g_hCvar_RepDeadStop,
    g_hCvar_RepPop,
    g_hCvar_RepShove,
    g_hCvar_RepHunterDP,
    g_hCvar_RepJockeyDP,
    g_hCvar_RepDeathCharge,
    g_hCvar_RepChargingSkeet,
    g_hCvar_RepInstanClear,
    g_hCvar_RepBhopStreak,
    g_hCvar_RepCarAlarm,

    g_hCvar_AllowMelee,              // cvar whether to count melee skeets
    g_hCvar_AllowSniper,             // cvar whether to count sniper headshot skeets
    g_hCvar_AllowGLSkeet,            // cvar whether to count direct hit GL skeets
    g_hCvar_SelfClearThresh,         // cvar damage while self-clearing from smokers
    g_hCvar_HunterDPThresh,          // cvar damage for hunter highpounce
    g_hCvar_JockeyDPThresh,          // cvar distance for jockey highpounce
    g_hCvar_ClearThreh,              // cvar for max special clear time
    g_hCvar_DeathChargeHeight,       // cvar how high a charger must have come in order for a DC to count
    g_hCvar_DeathChargeHeightBlow,   // cvar how high a blow must have come in order for a DC to count
    g_hCvar_DeathChargeBlowCheckHealth, // cvar whether to check health when a blown up by charger
    g_hCvar_InstaTime,               // cvar clear within this time or lower for instaclear
    g_hCvar_BHopMinStreak,           // cvar this many hops in a row+ = streak
    g_hCvar_BHopMinInitSpeed,        // cvar lower than this and the first jump won't be seen as the start of a streak
    g_hCvar_BHopContSpeed;

ConVar g_hCvar_PounceInterrupt = null;    // l4d2_si_damage_ajustment_pounce_damage_interrupt
int g_iPounceInterrupt = 150;             // default 150, damage that is greater that this applied on a flying hunter will be skeeted immediately. but not handle on this plugin :).


/*
    To Do
    -----
    - fix:  tank rock skeets still unreliable detection (often triggers a 'skeet' when actually landed on someone)

    - fix:  apparently some HR4 cars generate car alarm messages when shot, even when no alarm goes off
            (combination with car equalize plugin?)
            - see below: the single hook might also fix this.. -- if not, hook for sound
            - do a hookoutput on prop_car_alarm's and use that to track the actual alarm
                going off (might help in the case 2 alarms go off exactly at the same time?)

    - fix:  double prints on car alarms (sometimes? epi + m60)

    - fix:  sometimes instaclear reports double for single clear (0.16s / 0.19s) epi saw this, was for hunter
    - fix:  deadstops and m2s don't always register .. no idea why..
    - fix:  sometimes a (first?) round doesn't work for skeet detection.. no hurt/full skeets are reported or counted

    - make forwards fire for every potential action,
        - include the relevant values, so other plugins can decide for themselves what to consider it

    - test chargers getting dislodged with boomer pops?

    - add commonhop check
    - add deathcharge assist check
        - smoker
        - jockey

    - count rock hits even if they do no damage [epi request]
    - sir
        - make separate teamskeet forward, with (for now, up to) 4 skeeters + the damage each did
    - xan
        - add detection/display of unsuccesful witch crowns (witch death + info)

    detect...
        - ? add jockey deadstops (and change forward to reflect type)
        - ? speedcrown detection?
        - ? spit-on-cap detection
*/

/*****************************************************************
            L I B R A R Y   I N C L U D E S
*****************************************************************/
#include "l4d2_skill_detect/utils.sp"
#include "l4d2_skill_detect/tracking.sp"
#include "l4d2_skill_detect/reporting.sp"

#define PLUGIN_VERSION "r2.5.2"

public Plugin myinfo =
{
    name = "[L4D2] Skill Detection",
    author = "Tabun, Competitive Rework Team, blueblur",
    description = "Detects and reports skilled gameplay performances.",
    version    = PLUGIN_VERSION,
    url    = "https://github.com/blueblur0730/modified-plugins"
};

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int errMax)
{
    g_hForwardSkeet            = new GlobalForward("SkillDetect_OnSkeet", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
    g_hForwardSIShove          = new GlobalForward("SkillDetect_OnSpecialShoved", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    g_hForwardHunterDeadstop   = new GlobalForward("SkillDetect_OnHunterDeadstop", ET_Ignore, Param_Cell, Param_Cell);
    g_hForwardBoomerPop        = new GlobalForward("SkillDetect_OnBoomerPop", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Float);
    g_hForwardLevel            = new GlobalForward("SkillDetect_OnChargerLevel", ET_Ignore, Param_Cell, Param_Cell);
    g_hForwardLevelHurt        = new GlobalForward("SkillDetect_OnChargerLevelHurt", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    g_hForwardCrown            = new GlobalForward("SkillDetect_OnWitchCrown", ET_Ignore, Param_Cell);
    g_hForwardDrawCrown        = new GlobalForward("SkillDetect_OnWitchDrawCrown", ET_Ignore, Param_Cell);
    g_hForwardTongueCut        = new GlobalForward("SkillDetect_OnTongueCut", ET_Ignore, Param_Cell, Param_Cell);
    g_hForwardSmokerSelfClear  = new GlobalForward("SkillDetect_OnSmokerSelfClear", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    g_hForwardRockSkeeted      = new GlobalForward("SkillDetect_OnTankRockSkeeted", ET_Ignore, Param_Cell, Param_Cell);
    g_hForwardRockEaten        = new GlobalForward("SkillDetect_OnTankRockEaten", ET_Ignore, Param_Cell, Param_Cell);
    g_hForwardHunterDP         = new GlobalForward("SkillDetect_OnHunterHighPounce", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Float, Param_Cell);
    g_hForwardJockeyDP         = new GlobalForward("SkillDetect_OnJockeyHighPounce", ET_Ignore, Param_Cell, Param_Cell, Param_Float, Param_Cell);
    g_hForwardDeathCharge      = new GlobalForward("SkillDetect_OnDeathCharge", ET_Ignore, Param_Cell, Param_Cell, Param_Float, Param_Float, Param_Cell);
    g_hForwardChargingSkeet    = new GlobalForward("SkillDetect_OnChargingSkeet", ET_Ignore, Param_Cell, Param_Cell, Param_Float);
    g_hForwardClear            = new GlobalForward("SkillDetect_OnSpecialClear", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Float, Param_Cell);
    g_hForwardVomitLanded      = new GlobalForward("SkillDetect_OnBoomerVomitLanded", ET_Ignore, Param_Cell, Param_Cell);
    g_hForwardBHopStreak       = new GlobalForward("SkillDetect_OnBunnyHopStreak", ET_Ignore, Param_Cell, Param_Cell, Param_Float);
    g_hForwardAlarmTriggered   = new GlobalForward("SkillDetect_OnCarAlarmTriggered", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

    RegPluginLibrary("l4d2_skill_detect");
    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslation("l4d2_skill_detect.phrases");

    g_hCvar_Debug             = CreateConVar("l4d2_skill_detect_detect_debug", "0", "Enable debug messages.", FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD);

    // cvars: config
    g_hCvar_Report            = CreateConVar("l4d2_skill_detect_report_enable", "1", "Whether to report in chat.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepSkeet          = CreateConVar("l4d2_skill_detect_report_skeet", "1", "Enable skeet reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepLevel          = CreateConVar("l4d2_skill_detect_report_level", "1", "Enable level reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepHurtLevel      = CreateConVar("l4d2_skill_detect_report_hurtlevel", "1", "Enable hurt-level reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepCrow           = CreateConVar("l4d2_skill_detect_report_crow", "1", "Enable crow reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepDrawCrow       = CreateConVar("l4d2_skill_detect_report_drawcrow", "1", "Enable draw-crow reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepTongueCut      = CreateConVar("l4d2_skill_detect_report_tonguecut", "1", "Enable tongue-cut reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepSelfClear      = CreateConVar("l4d2_skill_detect_report_sc", "1", "Enable self clear reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepSelfClearShove = CreateConVar("l4d2_skill_detect_report_scs", "1", "Enable self clear Shove reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepRockSkeet      = CreateConVar("l4d2_skill_detect_report_rockskeet", "1", "Enable rock-skeet reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepDeadStop       = CreateConVar("l4d2_skill_detect_report_deadstop", "1", "Enable deadstop reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepPop            = CreateConVar("l4d2_skill_detect_report_pop", "1", "Enable pop reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepShove          = CreateConVar("l4d2_skill_detect_report_shove", "1", "Enable shove reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepHunterDP       = CreateConVar("l4d2_skill_detect_report_hunterdp", "1", "Enable hunter DP reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepJockeyDP       = CreateConVar("l4d2_skill_detect_report_jockeydp", "1", "Enable jockey DP reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepDeathCharge    = CreateConVar("l4d2_skill_detect_report_deadcharger", "1", "Enable deadcharger reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepChargingSkeet  = CreateConVar("l4d2_skill_detect_report_chargerskeet", "1", "Enable charger-skeet reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepInstanClear    = CreateConVar("l4d2_skill_detect_report_instanclear", "1", "Enable instan-clear reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepBhopStreak     = CreateConVar("l4d2_skill_detect_report_bhop", "1", "Enable bhop streak reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_RepCarAlarm       = CreateConVar("l4d2_skill_detect_report_caralarm", "1", "Enable car alarm reporting.", FCVAR_NONE, true, 0.0, true, 1.0);

    g_hCvar_AllowMelee        = CreateConVar("l4d2_skill_detect_skeet_allowmelee", "1", "Whether to count/forward melee skeets.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_AllowSniper       = CreateConVar("l4d2_skill_detect_skeet_allowsniper", "1", "Whether to count/forward sniper/magnum headshots as skeets.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_AllowGLSkeet      = CreateConVar("l4d2_skill_detect_skeet_allowgl", "1", "Whether to count/forward direct GL hits as skeets.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_SelfClearThresh   = CreateConVar("l4d2_skill_detect_selfclear_damage", "200", "How much damage a survivor must at least do to a smoker for him to count as self-clearing.", FCVAR_NONE, true, 0.0, false);
    g_hCvar_HunterDPThresh    = CreateConVar("l4d2_skill_detect_hunterdp_height", "400", "Minimum height of hunter pounce for it to count as a DP.", FCVAR_NONE, true, 0.0, false);
    g_hCvar_JockeyDPThresh    = CreateConVar("l4d2_skill_detect_jockeydp_height", "300", "How much height distance a jockey must make for his 'DP' to count as a reportable highpounce.", FCVAR_NONE, true, 0.0, false);
    g_hCvar_ClearThreh        = CreateConVar("l4d2_skill_detect_clear_max_time", "1.0", "How much time a clear must last for it to count.", FCVAR_NONE, true, 0.0, false);
    g_hCvar_DeathChargeHeight = CreateConVar("l4d2_skill_detect_deathcharge_height", "375.0", "How much height distance a charger must take its victim for a deathcharge to be reported.", FCVAR_NONE, true, 0.0, false);
    g_hCvar_DeathChargeHeightBlow = CreateConVar("l4d2_skill_detect_deathcharge_height_blow", "200.0", "How much height distance a charger must take its victim for a deathcharge to be reported when blown up.", FCVAR_NONE, true, 0.0, false);
    g_hCvar_DeathChargeBlowCheckHealth = CreateConVar("l4d2_skill_detect_deathcharge_blow_check_health", "0", "Whether to check health when being blown up by a charger.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvar_InstaTime         = CreateConVar("l4d2_skill_detect_instaclear_time", "0.75", "A clear within this time (in seconds) counts as an insta-clear.", FCVAR_NONE, true, 0.0, false);
    g_hCvar_BHopMinStreak     = CreateConVar("l4d2_skill_detect_bhopstreak", "3", "The lowest bunnyhop streak that will be reported.", FCVAR_NONE, true, 0.0, false);
    g_hCvar_BHopMinInitSpeed  = CreateConVar("l4d2_skill_detect_bhopinitspeed", "150", "The minimal speed of the first jump of a bunnyhopstreak (0 to allow 'hops' from standstill).", FCVAR_NONE, true, 0.0, false);
    g_hCvar_BHopContSpeed     = CreateConVar("l4d2_skill_detect_bhopkeepspeed", "300", "The minimal speed at which hops are considered succesful even if not speed increase is made.", FCVAR_NONE, true, 0.0, false);

    // Maps
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

    _skill_detect_tracking_OnPluginStart();
}

public void OnPluginEnd()
{
    delete g_hMapWeapons;
    delete g_hMapEntityCreated;

    _skill_detect_tracking_OnPluginEnd();
}

public void OnAllPluginsLoaded()
{
    g_bSIAdjustment = LibraryExists("l4d2_si_damage_adjustment");
    if (g_bSIAdjustment)
    {
        g_hCvar_PounceInterrupt = FindConVar("l4d2_si_damage_adjustment_pounce_damage_interrupt");
        g_hCvar_PounceInterrupt.AddChangeHook(CvarChange_PounceInterrupt);
        g_iPounceInterrupt = g_hCvar_PounceInterrupt.IntValue;
    }
}

public void OnLibraryAdded(const char[] library)
{
    g_bSIAdjustment = (strcmp(library, "l4d2_si_damage_adjustment") == 0);
}

public void OnLibraryRemoved(const char[] library)
{
    g_bSIAdjustment = !(strcmp(library, "l4d2_si_damage_adjustment") == 0);
}
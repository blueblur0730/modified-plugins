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
    g_hForwardJockeySkeet     = null,
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
    g_hForwardAlarmTriggered  = null,
    g_hForwardNumImpacts      = null,
    g_hForwardPopStagger      = null;

StringMap
    g_hMapWeapons       = null,       // weapon check
    g_hMapEntityCreated = null;       // getting classname of entity created

// cvars
ConVar
    g_hCvar_RepSkeet,
    g_hCvar_RepJockeySkeet,
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
    g_hCvar_RepNumImpacts,
    g_hCvar_RepPopStagger,
    g_hCvar_RepVomitLanded,

    g_hCvar_AllowMelee,              // cvar whether to count melee skeets
    g_hCvar_AllowSniper,             // cvar whether to count sniper headshot skeets
    g_hCvar_AllowGLSkeet,            // cvar whether to count direct hit GL skeets
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

/*
    To Do
    -----
    - test chargers getting dislodged with boomer pops?

    - add deathcharge assist check
        - smoker
        - jockey

    - count rock hits even if they do no damage [epi request]
    - sir
        - make separate teamskeet forward, with (for now, up to) 4 skeeters + the damage each did
        - ? spit-on-cap detection
*/

/*****************************************************************
            L I B R A R Y   I N C L U D E S
*****************************************************************/
#include "l4d2_skill_detect/setup.sp"
#include "l4d2_skill_detect/utils.sp"
#include "l4d2_skill_detect/tracking.sp"
#include "l4d2_skill_detect/reporting.sp"

#define PLUGIN_VERSION "r3.1.0"

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
    SetupForwards();
    RegPluginLibrary("l4d2_skill_detect");
    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslation("l4d2_skill_detect.phrases");

    SetupConVars();
    SetupStringMaps();
 
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
}

public void OnLibraryAdded(const char[] library)
{
    g_bSIAdjustment = (strcmp(library, "l4d2_si_damage_adjustment") == 0);
}

public void OnLibraryRemoved(const char[] library)
{
    g_bSIAdjustment = !(strcmp(library, "l4d2_si_damage_adjustment") == 0);
}
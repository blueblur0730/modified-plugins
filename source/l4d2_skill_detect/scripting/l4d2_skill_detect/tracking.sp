#if defined _skill_detect_tracking_included
    #endinput
#endif
#define _skill_detect_tracking_included

#define L4D2_MAXPLAYERS        32

#define POUNCE_CHECK_TIME      0.1
#define HOP_CHECK_TIME         0.1
#define HOPEND_CHECK_TIME      0.1     // after streak end (potentially) detected, to check for realz?
#define SHOVE_TIME             0.05
#define MAX_CHARGE_TIME        12.0      // maximum time to pass before charge checking ends
#define CHARGE_CHECK_TIME      0.25      // check interval for survivors flying from impacts
#define CHARGE_END_CHECK       2.5      // after client hits ground after getting impact-charged: when to check whether it was a death
#define CHARGE_END_RECHECK     3.0      // safeguard wait to recheck on someone getting incapped out of bounds
#define VOMIT_DURATION_TIME    2.25      // how long the boomer vomit stream lasts -- when to check for boom count
#define ROCK_CHECK_TIME        0.34      // how long to wait after rock entity is destroyed before checking for skeet/eat (high to avoid lag issues)
#define CARALARM_MIN_TIME      0.11      // maximum time after touch/shot => alarm to connect the two events (test this for LAG)

#define WITCH_CHECK_TIME       0.1      // time to wait before checking for witch crown after shoots fired
#define WITCH_DELETE_TIME      0.15      // time to wait before deleting entry from witch Map after entity is destroyed

#define MIN_DC_TRIGGER_DMG     300       // minimum amount a 'trigger' / drown must do before counted as a death action
#define MIN_DC_FALL_DMG        175       // minimum amount of fall damage counts as death-falling for a deathcharge
#define WEIRD_FLOW_THRESH      900.0       // -9999 seems to be break flow.. but meh
#define MIN_FLOWDROPHEIGHT     350.0       // minimum height a survivor has to have dropped before a WEIRD_FLOW value is treated as a DC spot
#define MIN_DC_RECHECK_DMG     100       // minimum damage from map to have taken on first check, to warrant recheck

#define HOP_ACCEL_THRESH       0.01      // bhop speed increase must be higher than this for it to count as part of a hop streak

#define DMGARRAYEXT            7       // L4D2_MAXPLAYERS+# -- extra indices in witch_dmg_array + 1

#define CUT_SHOVED             1       // smoker got shoved
#define CUT_SHOVEDSURV         2       // survivor got shoved
#define CUT_KILL               3       // reason for tongue break (release_type)
#define CUT_SLASH              4       // this is used for others shoving a survivor free too, don't trust .. it involves tongue damage?

#define VICFLG_CARRIED         (1 << 0)      // was the one that the charger carried (not impacted)
#define VICFLG_FALL            (1 << 1)      // flags stored per charge victim, to check for deathchargeroony -- fallen
#define VICFLG_DROWN           (1 << 2)      // drowned
#define VICFLG_HURTLOTS        (1 << 3)      // whether the victim was hurt by 400 dmg+ at once
#define VICFLG_TRIGGER         (1 << 4)      // killed by trigger_hurt
#define VICFLG_AIRDEATH        (1 << 5)      // died before they hit the ground (impact check)
#define VICFLG_KILLEDBYOTHER   (1 << 6)      // if the survivor was killed by an SI other than the charger
#define VICFLG_WEIRDFLOW       (1 << 7)      // when survivors get out of the map and such
#define VICFLG_WEIRDFLOWDONE   (1 << 8)      //      checked, don't recheck for this

#define ZC_SMOKER              1
#define ZC_BOOMER              2
#define ZC_HUNTER              3
#define ZC_SPITTER             4
#define ZC_JOCKEY              5
#define ZC_CHARGER             6
#define ZC_WITCH               7
#define ZC_TANK                8

#define L4D1_ZOMBIECLASS_TANK 5
#define L4D2_ZOMBIECLASS_TANK 8

enum struct InfectedSkillCache_t
{
    // all SI / pinners
    float m_flSpawnTime;       // time the SI spawned up
    float m_flPinTime[2];       // time the SI pinned a target: 0 = start of pin (tongue pull, charger carry); 1 = carry end / tongue reigned in
    int m_iSpecialVictim;       // current victim (set in traceattack, so we can check on death)

    // leap
    Vector m_vecLeapStartPos;                                      // position that a jockey leapt from    

    // deadstops
    float m_flVictimLastShove[L4D2_MAXPLAYERS + 1];       // when was the player shoved last by attacker? (to prevent doubles)

    // pops
    bool m_bBoomerHitSomebody;         // false if boomer didn't puke/exploded on anybody
    int m_iBoomerGotShoved;            // how many times the boomer got shoved
    int m_iBoomerVomitHits;            // how many booms in one vomit so far

    // smoker clears
    bool m_bSmokerClearCheck;           // [smoker] smoker dies and this is set, it's a self-clear if m_iSmokerVictim is the killer
    int m_iSmokerVictim;                // [smoker] the one that's being pulled
    int m_iSmokerVictimDamage;          // [smoker] amount of damage done to a smoker by the one he pulled
    bool m_bSmokerShoved;               // [smoker] set if the victim of a pull manages to shove the smoker
}
InfectedSkillCache_t g_InfectedSkillCache[L4D2_MAXPLAYERS + 1];

enum struct SurvivorSkillCache_t
{
    // skeet
    bool m_bShotCounted;                // whether the shot has been counted for the hunter

    // levels / charges
    Vector m_vecImpactStartPos;         // position that the player was impacted from
    Vector m_vecImpactLastVelocity;     // velocity of the player when impacted before landed.
    int m_iLastImpactHealth;            // health of the player when impacted before landed.
    int m_iLastImpactAttacker;          // attacker of the player when impacted before landed.
 
    // hops
    bool m_bIsHopping;              // currently in a hop streak
    bool m_bHopCheck;               // flag to check whether a hopstreak has ended (if on ground for too long.. ends)
    int m_iHops;                    // amount of hops in streak
    float m_flLastHop[3];           // velocity vector of last jump
    float m_flHopTopVelocity;       // maximum velocity in hopping streak

    void ResetImpact()
    {
        this.m_vecImpactStartPos.Set(0.0, 0.0, 0.0);
        this.m_vecImpactLastVelocity.Set(0.0, 0.0, 0.0);
        this.m_iLastImpactHealth = 0;
    }
}
SurvivorSkillCache_t g_Survivor[L4D2_MAXPLAYERS + 1];

static ConVar g_hCvar_PounceInterrupt_Default = null;  // z_pounce_damage_interrupt
int    g_iPounceInterruptDefault = 150;         // z_pounce_damage_interrupt, default 150, damage that is greater that this applied on a flying hunter will be skeeted immediately. but not handle on this plugin :).

ConVar g_hCvar_ChargerHealth     = null;     // z_charger_health
ConVar g_hCvar_MaxPounceDistance = null;     // z_pounce_damage_range_max
ConVar g_hCvar_MinPounceDistance = null;     // z_pounce_damage_range_min
ConVar g_hCvar_MaxPounceDamage = null;       // z_hunter_max_pounce_bonus_damage;

#include "tracking/witch.sp"
#include "tracking/rock.sp"
#include "tracking/caralarm.sp"
#include "tracking/boomer.sp"
#include "tracking/smoker.sp"
#include "tracking/charger.sp"
#include "tracking/hunter.sp"
#include "tracking/jockey.sp"
#include "tracking/survivor.sp"

void _skill_detect_tracking_OnPluginStart()
{
    g_hArray_TankRockTrace = new ArrayList(sizeof(TankRockTrace_t));
    g_hArray_WitchTrace = new ArrayList(sizeof(WitchTrace_t));
    g_hArray_CarAlarmTrace = new ArrayList(sizeof(CarAlarmTrace_t));

    // cvars: built in
    g_hCvar_PounceInterrupt_Default = FindConVar("z_pounce_damage_interrupt");
    g_hCvar_PounceInterrupt_Default.AddChangeHook(CvarChange_PounceInterrupt);
    g_iPounceInterruptDefault = g_hCvar_PounceInterrupt_Default.IntValue;

    g_hCvar_ChargerHealth = FindConVar("z_charger_health");
    g_hCvar_MaxPounceDistance = FindConVar("z_pounce_damage_range_max");
    g_hCvar_MinPounceDistance = FindConVar("z_pounce_damage_range_min");
    g_hCvar_MaxPounceDamage = FindConVar("z_hunter_max_pounce_bonus_damage");

    if (g_hCvar_MaxPounceDistance == null)
        g_hCvar_MaxPounceDistance = CreateConVar("z_pounce_damage_range_max", "1000.0", "Not available on this server, added by l4d2_skill_detect.", FCVAR_NONE, true, 0.0, false);

    if (g_hCvar_MinPounceDistance == null)
        g_hCvar_MinPounceDistance = CreateConVar("z_pounce_damage_range_min", "300.0", "Not available on this server, added by l4d2_skill_detect.", FCVAR_NONE, true, 0.0, false);

    if (g_hCvar_MaxPounceDamage == null)
        g_hCvar_MaxPounceDamage = CreateConVar("z_hunter_max_pounce_bonus_damage", "49", "Not available on this server, added by l4d2_skill_detect.", FCVAR_NONE, true, 0.0, false);

    // globals.
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("scavenge_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
    HookEvent("player_shoved", Event_PlayerShoved, EventHookMode_Post);
    HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);

    // hunter.
    HookEvent("lunge_pounce", Event_LungePounce, EventHookMode_Post);

    // survivor.
    HookEvent("player_jump", Event_PlayerJumped, EventHookMode_Post);
    HookEvent("player_jump_apex", Event_PlayerJumpApex, EventHookMode_Post);

    // boomers.
    HookEvent("player_now_it", Event_PlayerBoomed, EventHookMode_Post);
    HookEvent("boomer_exploded", Event_BoomerExploded, EventHookMode_Post);

    // witches.
    HookEvent("witch_spawn", Event_WitchSpawned, EventHookMode_Post);
    HookEvent("witch_killed", Event_WitchKilled, EventHookMode_Post);
    HookEvent("witch_harasser_set", Event_WitchHarasserSet, EventHookMode_Post);

    // smokers.
    HookEvent("tongue_grab", Event_TongueGrab, EventHookMode_Post);
    HookEvent("tongue_pull_stopped", Event_TonguePullStopped, EventHookMode_Post);
    HookEvent("choke_start", Event_ChokeStart, EventHookMode_Post);
    HookEvent("choke_stopped", Event_ChokeStop, EventHookMode_Post);

    // jockeys.
    HookEvent("jockey_ride", Event_JockeyRide, EventHookMode_Post);

    // chargers.
    HookEvent("charger_impact", Event_ChargeImpact, EventHookMode_Post);
}

void _skill_detect_tracking_OnPluginEnd()
{
    delete g_hArray_TankRockTrace;
    delete g_hArray_WitchTrace;
    delete g_hArray_CarAlarmTrace;
}

// entity creation
public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity < 1 || !IsValidEntity(entity) || !IsValidEdict(entity))
        return;

    strOEC classnameOEC;
    if (!g_hMapEntityCreated.GetValue(classname, classnameOEC))
        return;

    switch (classnameOEC)
    {
        case OEC_TANKROCK:
        {
            TankRockTrace_t rockTrace;
            rockTrace.m_iRock = entity;
            rockTrace.m_iThrower = GetEntPropEnt(entity, Prop_Send, "m_hThrower");    // CTankRock < CBaseGrenade.
            g_hArray_TankRockTrace.PushArray(rockTrace, sizeof(rockTrace));

            SDKHook(entity, SDKHook_TraceAttackPost, TraceAttackPost_Rock);
            SDKHook(entity, SDKHook_TouchPost, OnTouchPost_Rock);
        }

        case OEC_CARALARM:
        {
            SDKHook(entity, SDKHook_OnTakeDamagePost, OnTakeDamagePost_Car);
            SDKHook(entity, SDKHook_TouchPost, OnTouchPost_Car);
            SDKHook(entity, SDKHook_SpawnPost, OnSpawn_CarAlarm);
        }

        case OEC_CARGLASS:
        {
            SDKHook(entity, SDKHook_OnTakeDamagePost, OnTakeDamagePost_CarGlass);
            SDKHook(entity, SDKHook_TouchPost, OnTouchPost_CarGlass);
            SDKHook(entity, SDKHook_SpawnPost, OnSpawn_CarAlarmGlass);
        }
    }
}

// entity destruction
public void OnEntityDestroyed(int entity)
{
    int index = g_hArray_TankRockTrace.FindValue(entity, TankRockTrace_t::m_iRock);
    if (index != -1)
    {
        CreateTimer(ROCK_CHECK_TIME, Timer_CheckRockSkeet, index);
        return;
    }

    index = g_hArray_WitchTrace.FindValue(entity, WitchTrace_t::m_iWitch);
    if (index != -1)
    {
        // witch
        // delayed deletion, to avoid potential problems with crowns not detecting
        CreateTimer(WITCH_DELETE_TIME, Timer_WitchKeyDelete, index);
    }
}

public void OnActionCreated( BehaviorAction action, int actor, const char[] name )
{
    if (strcmp(name, "HunterLungeAtVictim") == 0)
    {
        action.OnShoved = HunterLungeAtVictim_OnShoved;
        action.OnInjured = HunterLungeAtVictim_OnInjured;
        action.OnKilled = HunterLungeAtVictim_OnKilled;
        action.OnStart = HunterLungeAtVictim_OnStart;
        action.OnEnd = HunterLungeAtVictim_OnEnd;
    }
    else if (strcmp(name, "ChargerChargeAtVictim") == 0)
    {
        action.Update = ChargerChargeAtVictim_Update;
        action.OnStart = ChargerChargeAtVictim_OnStart;
        action.OnEnd = ChargerChargeAtVictim_OnEnd;
        action.OnInjured = ChargerChargeAtVictim_OnInjured;
        action.OnKilled = ChargerChargeAtVictim_OnKilled;
    }
}

public void L4D2_OnDominatedBySpecialInfected(int victim, int dominator)
{
    g_InfectedSkillCache[dominator].m_iSpecialVictim = victim;
}

static void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        g_Survivor[i].m_bIsHopping = false;

        for (int j = 1; j <= MaxClients; j++)
            g_InfectedSkillCache[i].m_flVictimLastShove[j] = 0.0;
    }

    g_hArray_TankRockTrace.Clear();
    g_hArray_WitchTrace.Clear();
}

static void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    // clean array, new cars will be created
    g_hArray_CarAlarmTrace.Clear();
}

static void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || client > MaxClients)
        return;

    if (!IsClientInGame(client))
        return;

    int wepid = event.GetInt("weaponid");
    if (wepid == WEPID_SHOTGUN_CHROME || wepid == WEPID_SHOTGUN_SPAS || wepid == WEPID_AUTOSHOTGUN || wepid == WEPID_PUMPSHOTGUN)
    {
        g_Survivor[client].m_bShotCounted = false;
    }
}

static void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (!IsValidClientInGame(victim) || !IsValidClientInGame(attacker))
        return;

    int damage = event.GetInt("dmg_health");
    int damagetype = event.GetInt("type");

    if (IsValidInfected(victim))
    {     
        int zClass = GetEntProp(victim, Prop_Send, "m_zombieClass");

        if (damage < 1)
            return;

        switch (zClass)
        {
            case ZC_SMOKER:
            {
                if (!IsValidSurvivor(attacker))
                    return;

                g_InfectedSkillCache[victim].m_iSmokerVictimDamage += damage;
            }
        }
    }
    else if (IsValidInfected(attacker))
    {
        int zClass = GetEntProp(attacker, Prop_Send, "m_zombieClass");
        switch (zClass)
        {
            case ZC_HUNTER:
            {
                // a hunter pounce landing is DMG_CRUSH
                if (damagetype & DMG_CRUSH)
                    g_Hunter[attacker].m_iPounceDamage = damage;
            }

            case ZC_TANK:
            {
                char weapon[10];
                event.GetString("weapon", weapon, sizeof(weapon));

                if (StrEqual(weapon, "tank_rock"))
                {
                    if (IsValidSurvivor(victim))
                        HandleRockEaten(attacker, victim);
                }

                return;
            }
        }
    }
}

static void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidInfected(client))
        return;

    int zClass = GetEntProp(client, Prop_Send, "m_zombieClass");

    g_InfectedSkillCache[client].m_flSpawnTime  = GetGameTime();
    g_InfectedSkillCache[client].m_iSpecialVictim = 0;

    switch (zClass)
    {
        case ZC_BOOMER:
        {
            g_InfectedSkillCache[client].m_bBoomerHitSomebody = false;
            g_InfectedSkillCache[client].m_iBoomerGotShoved      = 0;
        }

        case ZC_SMOKER:
        {
            g_InfectedSkillCache[client].m_bSmokerClearCheck   = false;
            g_InfectedSkillCache[client].m_iSmokerVictim       = 0;
            g_InfectedSkillCache[client].m_iSmokerVictimDamage = 0;
        }

        case ZC_HUNTER:
        {
            g_Hunter[client].ResetHunter();
            g_Hunter[client].m_vecPounceStartPos.Set(0.0, 0.0, 0.0);
        }

        case ZC_CHARGER:
        {
            g_Charger[client].ResetCharger();
        }

        case ZC_JOCKEY:
        {
            g_InfectedSkillCache[client].m_vecLeapStartPos.Set(0.0, 0.0, 0.0);
        }
    }
}

static void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (IsValidInfected(victim))
    {
        int zClass = GetEntProp(victim, Prop_Send, "m_zombieClass");

        switch (zClass)
        {
            case ZC_HUNTER:
            {
                // check whether it was a clear
                if (g_InfectedSkillCache[victim].m_iSpecialVictim > 0)
                    HandleClear(attacker, victim, g_InfectedSkillCache[victim].m_iSpecialVictim, ZC_HUNTER, (g_Hunter[victim].m_IncapStartTimer.GetElapsedTime()), -1.0);
            }

            case ZC_SMOKER:
            {
                if (!IsValidSurvivor(attacker))
                    return;

                if (g_InfectedSkillCache[victim].m_bSmokerClearCheck && g_InfectedSkillCache[victim].m_iSmokerVictim == attacker && g_InfectedSkillCache[victim].m_iSmokerVictimDamage >= g_hCvar_SelfClearThresh.IntValue)
                {
                    HandleSmokerSelfClear(attacker, victim);
                }
                else
                {
                    g_InfectedSkillCache[victim].m_bSmokerClearCheck = false;
                    g_InfectedSkillCache[victim].m_iSmokerVictim = 0;
                }
            }

            case ZC_JOCKEY:
            {
                // check whether it was a clear
                if (g_InfectedSkillCache[victim].m_iSpecialVictim > 0)
                    HandleClear(attacker, victim, g_InfectedSkillCache[victim].m_iSpecialVictim, ZC_JOCKEY, (GetGameTime() - g_InfectedSkillCache[victim].m_flPinTime[0]), -1.0);
            }

            case ZC_CHARGER:
            {
                // check whether it was a clear
                if (g_Charger[victim].m_bCarriedVictim && g_Charger[victim].m_ChargeTimer.IsLessThan(g_hCvar_ClearThreh.FloatValue))
                {
                    HandleClear(attacker, victim, g_InfectedSkillCache[victim].m_iSpecialVictim, ZC_CHARGER, (g_Charger[victim].m_PummelTimer.HasStarted()) ? (g_Charger[victim].m_PummelTimer.GetElapsedTime()) : -1.0, (g_Charger[victim].m_ChargeTimer.GetElapsedTime()));
                    g_Charger[victim].ResetCharger();
                }
            }
        }
    }
}

static void Event_PlayerShoved(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (!IsValidSurvivor(attacker) || !IsValidInfected(victim))
        return;

    int zClass = GetEntProp(victim, Prop_Send, "m_zombieClass");

    // check for clears
    switch (zClass)
    {
        case ZC_HUNTER:
        {
            if (GetEntPropEnt(victim, Prop_Send, "m_pounceVictim") > 0)
                HandleClear(attacker, victim, GetEntPropEnt(victim, Prop_Send, "m_pounceVictim"), ZC_HUNTER, (GetGameTime() - g_InfectedSkillCache[victim].m_flPinTime[0]), -1.0, true);
        }

        case ZC_JOCKEY:
        {
            if (GetEntPropEnt(victim, Prop_Send, "m_jockeyVictim") > 0)
                HandleClear(attacker, victim, GetEntPropEnt(victim, Prop_Send, "m_jockeyVictim"), ZC_JOCKEY, (GetGameTime() - g_InfectedSkillCache[victim].m_flPinTime[0]), -1.0, true);
        }

        case ZC_BOOMER:
        {
            g_InfectedSkillCache[victim].m_iBoomerGotShoved++;
        }
    }

    if (g_InfectedSkillCache[victim].m_flVictimLastShove[attacker] == 0.0 || (GetGameTime() - g_InfectedSkillCache[victim].m_flVictimLastShove[attacker]) >= SHOVE_TIME)
    {
        HandleShove(attacker, victim, zClass);
        g_InfectedSkillCache[victim].m_flVictimLastShove[attacker] = GetGameTime();
    }

    // check for shove on smoker by pull victim
    if (g_InfectedSkillCache[victim].m_iSmokerVictim == attacker)
        g_InfectedSkillCache[victim].m_bSmokerShoved = true;

    PrintDebug("shove by %i on %i", attacker, victim);
}

void CvarChange_PounceInterrupt(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_iPounceInterruptDefault = g_hCvar_PounceInterrupt_Default.IntValue;
    
    if (g_bSIAdjustment)
        g_iPounceInterrupt = g_hCvar_PounceInterrupt.IntValue;
}


#if defined _skill_detect_tracking_included
    #endinput
#endif
#define _skill_detect_tracking_included

enum struct InfectedSkillCache_t
{
    // all SI / pinners
   int m_iSpecialVictim;                                              // current victim (set in traceattack, so we can check on death)
   IntervalTimer_t m_VictimLastShoveTimer[L4D2_MAXPLAYERS + 1];       // when was the player shoved last by attacker? (to prevent doubles)
}
InfectedSkillCache_t g_Infected[L4D2_MAXPLAYERS + 1];

enum struct SurvivorSkillCache_t
{
    bool m_bShotCounted;                // whether the shot has been counted for the hunter
    Vector m_vecImpactStartPos;         // position that the player was impacted from
    Vector m_vecImpactLastVelocity;     // velocity of the player when impacted before landed.
    int m_iLastImpactHealth;            // health of the player when impacted before landed.
    int m_iLastImpactAttacker;          // attacker of the player when impacted before landed.

    int m_iSpecialAttacker;             // special attacker who's dominating me.
 
    // hops
    bool m_bIsHopping;             // currently in a hop streak
    bool m_bHopCheck;              // flag to check whether a hopstreak has ended (if on ground for too long.. ends)
    int m_iHops;                   // amount of hops in streak
    Vector m_vecLastHop;           // velocity vector of last jump
    float m_flHopTopVelocity;      // maximum velocity in hopping streak

    void ResetImpact()
    {
        this.m_vecImpactStartPos.Set(0.0, 0.0, 0.0);
        this.m_vecImpactLastVelocity.Set(0.0, 0.0, 0.0);
        this.m_iLastImpactHealth = 0;
    }
}
SurvivorSkillCache_t g_Survivor[L4D2_MAXPLAYERS + 1];

CountdownTimer_t g_MultiDominationTimer;

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
    HookEvent("charger_carry_start", Event_ChargerCarryStart, EventHookMode_Post);
    HookEvent("charger_carry_end", Event_ChargerCarryEnd, EventHookMode_Post);
    HookEvent("charger_charge_end", Event_ChargerChargeEnd, EventHookMode_Post);
    HookEvent("charger_pummel_start", Event_ChargerPummelStart, EventHookMode_Post);
}

void _skill_detect_tracking_OnPluginEnd()
{
    delete g_hArray_TankRockTrace;
    delete g_hArray_WitchTrace;
    delete g_hArray_CarAlarmTrace;
}

public void OnActionCreated( BehaviorAction action, int actor, const char[] name )
{
    if (strcmp(name, "HunterLungeAtVictim") == 0)
    {
        action.OnUpdate = HunterLungeAtVictim_Update;
        action.OnShoved = HunterLungeAtVictim_OnShoved;
        action.OnInjured = HunterLungeAtVictim_OnInjured;
        action.OnKilled = HunterLungeAtVictim_OnKilled;
        action.OnEnd = HunterLungeAtVictim_OnEnd;
    }
    else if (strcmp(name, "ChargerChargeAtVictim") == 0)
    {
        action.OnInjured = ChargerChargeAtVictim_OnInjured;
        action.OnKilled = ChargerChargeAtVictim_OnKilled;
    }
    else if (strcmp(name, "JockeyLeap") == 0)
    {
        action.OnUpdate = JockeyLeap_Update;
        action.OnEnd = JockeyLeap_OnEnd;
        action.OnInjured = JockeyLeap_OnInjured;
        action.OnKilled = JockeyLeap_OnKilled;
        action.OnShoved = JockeyLeap_OnShoved;
    }
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
    int index = -1;
    if (IsRock(entity))
    {
        index = g_hArray_TankRockTrace.FindValue(entity, TankRockTrace_t::m_iRock);
        if (index != -1)
        {
            CreateTimer(ROCK_CHECK_TIME, Timer_CheckRockSkeet, index);
            return;
        }
    }

    if (IsWitch(entity))
    {
        index = g_hArray_WitchTrace.FindValue(entity, WitchTrace_t::m_iWitch);
        if (index != -1)
        {
            // witch
            // delayed deletion, to avoid potential problems with crowns not detecting
            CreateTimer(WITCH_DELETE_TIME, Timer_WitchKeyDelete, index);
        }
    }
}

public void L4D2_OnDominatedBySpecialInfected(int victim, int dominator)
{
    g_Infected[dominator].m_iSpecialVictim = victim;
    g_Survivor[victim].m_iSpecialAttacker = dominator;
}

public void L4D2_OnStagger_Post(int client, int source)
{
    if (!IsValidInfected(client) || !IsValidInfected(source))
        return;

    if (IsFakeClient(client) || IsFakeClient(source))
        return;

    int victimClass = GetEntProp(client, Prop_Send, "m_zombieClass");
    int sourceClass = GetEntProp(source, Prop_Send, "m_zombieClass");

    if (sourceClass == ZC_BOOMER)
    {
        if (IsDominator(victimClass) && IsValidSurvivor(g_Infected[client].m_iSpecialVictim))
        {
            HandleBoomerStaggerTeammate(client, source);
        }
    }
}

public void OnGameFrame()
{
    CheckMultiDominationTimer(false);
}

static void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        g_Survivor[i].m_bIsHopping = false;

        for (int j = 1; j <= MaxClients; j++)
            g_Infected[i].m_VictimLastShoveTimer[j].Invalidate();
    }

    g_hArray_TankRockTrace.Clear();
    g_hArray_WitchTrace.Clear();
    g_MultiDominationTimer.Invalidate();
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

    if (IsValidInfected(attacker))
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
        }
    }
}

static void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidInfected(client))
        return;

    int zClass = GetEntProp(client, Prop_Send, "m_zombieClass");
    g_Infected[client].m_iSpecialVictim = 0;

    switch (zClass)
    {
        case ZC_BOOMER:
        {
            g_Boomer[client].ResetBoomer();
        }

        case ZC_HUNTER:
        {
            g_Hunter[client].ResetHunter();
        }

        case ZC_CHARGER:
        {
            g_Charger[client].ResetCharger();
        }

        case ZC_JOCKEY:
        {
            g_Jockey[client].ResetJockey();
        }

        case ZC_SMOKER:
        {
            g_Smoker[client].ResetSmoker();
        }
    }
}

static void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (!IsValidSurvivor(attacker) || !IsValidInfected(victim))
        return;

    int damageType = event.GetInt("type");
    if (IsValidInfected(victim))
    {
        int zClass = GetEntProp(victim, Prop_Send, "m_zombieClass");

        switch (zClass)
        {
            case ZC_HUNTER:
            {
                // check whether it was a clear
                if (g_Infected[victim].m_iSpecialVictim > 0)
                    HandleClear(attacker, victim, g_Infected[victim].m_iSpecialVictim, ZC_HUNTER, (g_Hunter[victim].m_IncapStartTimer.GetElapsedTime()), -1.0);
                
                g_Hunter[victim].m_IncapStartTimer.Invalidate();

                if (!IsFakeClient(victim))
                {
                    int weapon = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
                    ProcessHunterSkeet(attacker, victim, weapon, damageType);
                }
            }

            case ZC_JOCKEY:
            {
                // check whether it was a clear
                if (g_Infected[victim].m_iSpecialVictim > 0)
                    HandleClear(attacker, victim, g_Infected[victim].m_iSpecialVictim, ZC_JOCKEY, (g_Jockey[victim].m_RideStartTimer.GetElapsedTime()), -1.0);

                g_Jockey[victim].m_RideStartTimer.Invalidate();

                if (!IsFakeClient(victim))
                {
                    int weapon = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
                    ProcessJockeySkeet(attacker, victim, weapon, damageType);
                }
            }

            case ZC_CHARGER:
            {
                // check whether it was a clear
                if (g_Charger[victim].m_bCarriedVictim && g_Charger[victim].m_ChargeTimer.IsLessThan(g_hCvar_ClearThreh.FloatValue))
                {
                    HandleClear(attacker, victim, g_Infected[victim].m_iSpecialVictim, ZC_CHARGER, (g_Charger[victim].m_PummelTimer.HasStarted()) ? (g_Charger[victim].m_PummelTimer.GetElapsedTime()) : -1.0, (g_Charger[victim].m_ChargeTimer.GetElapsedTime()));
                    g_Charger[victim].ResetCharger();
                }

                if (!IsFakeClient(victim))
                {
                    ProcessChargerSkill(attacker, victim, g_Charger[victim].m_flMeleeDamage, damageType);
                }
            }

            case ZC_BOOMER:
            {
                DataPack pack = new DataPack();
                pack.WriteCell(victim);
                pack.WriteCell(attacker);
                pack.WriteCell(L4D_IsPlayerStaggering(victim))
                
                RequestFrame(OnNextFrame_BoomerDeath, pack);
            }
        }
    }
}

static void OnNextFrame_BoomerDeath(DataPack pack)
{
    pack.Reset();
    int victim = pack.ReadCell();
    int attacker = pack.ReadCell();
    bool isStaggering = pack.ReadCell();
    delete pack;

    int staggerCount = 0;
    for (int i = 1; i < MaxClients; i++)
    {
        if (!IsClientInGame(i) || GetClientTeam(i) != 2)
            continue;

        if (IsIT(i) && L4D_IsPlayerStaggering(i)) 
        {
            staggerCount++;
        }
    }

    // someone popped a boomer and biled their friendly.
    if (staggerCount > 0)
    {
        HandlePopStagger(attacker, victim, staggerCount, isStaggering);
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
            {
                HandleClear(attacker, victim, GetEntPropEnt(victim, Prop_Send, "m_pounceVictim"), ZC_HUNTER, (g_Hunter[victim].m_IncapStartTimer.GetElapsedTime()), -1.0, true);
                g_Hunter[victim].m_IncapStartTimer.Invalidate();
            }

            if (!IsFakeClient(victim))
            {
                bool m_isLunging = view_as<bool>(GetEntProp(GetInfectedAbilityEntity(victim), Prop_Send, "m_isLunging", 1));
                if (g_Hunter[victim].m_bOnGround && m_isLunging)
                {
                    HandleDeadstop(attacker, victim);
                    g_Hunter[victim].ResetHunter();
                }
            }
        }

        case ZC_JOCKEY:
        {
            if (GetEntPropEnt(victim, Prop_Send, "m_jockeyVictim") > 0)
            {
                HandleClear(attacker, victim, GetEntPropEnt(victim, Prop_Send, "m_jockeyVictim"), ZC_JOCKEY, (g_Jockey[victim].m_RideStartTimer.GetElapsedTime()), -1.0, true);
                g_Jockey[victim].m_RideStartTimer.Invalidate();
            }
        }
    }

    if (!g_Infected[victim].m_VictimLastShoveTimer[attacker].HasStarted() || g_Infected[victim].m_VictimLastShoveTimer[attacker].IsGreaterThan(SHOVE_TIME))
    {
        HandleShove(attacker, victim, zClass);
        g_Infected[victim].m_VictimLastShoveTimer[attacker].Start();
    }
}

void CheckMultiDominationTimer(bool bEvent = false)
{
    if (g_MultiDominationTimer.HasStarted())
    {
        if (g_MultiDominationTimer.IsElapsed() && !bEvent)
        {
            HandleMultiDomination();
            g_MultiDominationTimer.Invalidate();
        }
        else if (bEvent)
        {
            g_MultiDominationTimer.Reset();
        }
    }
    else if (bEvent)
    {
        g_MultiDominationTimer.Start(g_hCvar_MultiDominationTimeThresh.FloatValue);
    }
}
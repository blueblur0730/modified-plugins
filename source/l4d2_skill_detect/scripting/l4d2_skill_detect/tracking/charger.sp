#if defined _skill_detect_tracking_charger_included
    #endinput
#endif
#define _skill_detect_tracking_charger_included

/**
 * Handled things:
 * 3. Long incapacited charge (carried)
*/

enum struct ChargerSkill_t
{
    // charges
    Vector m_vecCarryStartPos;                  // location of each survivor when it got hit by the charger
    IntervalTimer_t m_ChargeTimer;              // time the charger's charge last started.
    IntervalTimer_t m_PummelTimer;              // time the charger's pummel last started.
    bool m_bCarriedVictim;                      // whether the victim was carried by the charger
    int m_iShotsFired[L4D2_MAXPLAYERS + 1];     // number of shots fired by the charger
    int m_iDamage[L4D2_MAXPLAYERS + 1];         // damage done to each survivor by the charger
    int m_iTeamDamage;                          // damage done by team
    int m_iNumImpacts;                          // number of impacts done by the charger
    float m_flMeleeDamage;                      // damage done by the charger's melee attack, used for sdkhook.

    void SortSkeetDmg(int iArr[L4D2_MAXPLAYERS + 1][3])
    {
        for (int i = 1; i < L4D2_MAXPLAYERS; i++)
        {
            iArr[i][0] = i;
            iArr[i][1] = this.m_iDamage[i];
            iArr[i][2] = this.m_iShotsFired[i];
        }

        // Bubble sort in descending order
        int n = L4D2_MAXPLAYERS;
        for (int i = 1; i <= n - 1; i++)
        {
            for (int j = 1; j <= n - i; j++)
            {
                if (iArr[j][1] < iArr[j + 1][1])
                {
                    // Swap the entire row
                    int temp0 = iArr[j][0];
                    int temp1 = iArr[j][1];
                    int temp2 = iArr[j][2];

                    iArr[j][0] = iArr[j + 1][0];
                    iArr[j][1] = iArr[j + 1][1];
                    iArr[j][2] = iArr[j + 1][2];

                    iArr[j + 1][0] = temp0;
                    iArr[j + 1][1] = temp1;
                    iArr[j + 1][2] = temp2;
                }
            }
        }
    }

    void ResetCharger()
    {
        this.m_vecCarryStartPos.Set(0.0, 0.0, 0.0);
        this.m_ChargeTimer.Invalidate();
        this.m_PummelTimer.Invalidate();
        this.m_bCarriedVictim = false;

        for (int i = 1; i <= L4D2_MAXPLAYERS; i++)
        {
            this.m_iShotsFired[i] = 0;
            this.m_iDamage[i] = 0;
        }

        this.m_iTeamDamage = 0;
        this.m_iNumImpacts = 0;
        this.m_flMeleeDamage = 0.0;
    }
}
ChargerSkill_t g_Charger[L4D2_MAXPLAYERS + 1];

Action ChargerChargeAtVictim_OnInjured(any action, int actor, CTakeDamageInfo info, ActionDesiredResult result)
{
    if (actor <= 0 || actor > MaxClients)
        return Plugin_Continue;

    if (!IsClientInGame(actor))
        return Plugin_Continue;

    int attacker = info.m_hAttacker;

    if (attacker <= 0 || attacker > MaxClients)
        return Plugin_Continue;

    if (!IsClientInGame(attacker))
        return Plugin_Continue;

    int damageType = info.m_bitsDamageType;
    float damage = info.m_flDamage;

    ProcessChargerTakeDamage(actor, attacker, damage, damageType);
    return Plugin_Continue;
}

Action ChargerChargeAtVictim_OnKilled(any action, int actor, CTakeDamageInfo info, ActionDesiredResult result)
{
    if (actor <= 0 || actor > MaxClients)
        return Plugin_Continue;

    if (!IsClientInGame(actor))
        return Plugin_Continue;

    float damage = info.m_flDamage;
    int damageType = info.m_bitsDamageType;
    int attacker = info.m_hAttacker;
    //PrintToServer("[Skill Detect] ChargerChargeAtVictim_OnKilled called. Damage: %.2f, Type: %i", damage, damageType);
    //CheckFlag(damageType);
 
    if (attacker <= 0 || attacker > MaxClients)
        return Plugin_Continue;

    if (!IsClientInGame(attacker))
        return Plugin_Continue;

    ProcessChargerSkill(actor, attacker, damage, damageType);
    return Plugin_Continue;
}

void Event_ChargerCarryStart(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("userid"));
    int victim = GetClientOfUserId(event.GetInt("victim"));

    if (!IsValidInfected(attacker) || !IsValidSurvivor(victim))
        return;

    g_Charger[attacker].m_bCarriedVictim = true;
    g_Charger[attacker].m_vecCarryStartPos.GetClientAbsOrigin(attacker);
}

void Event_ChargerCarryEnd(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("userid"));
    int victim = GetClientOfUserId(event.GetInt("victim"));

    if (!IsValidInfected(attacker) || !IsValidSurvivor(victim))
        return;

    if (g_Charger[attacker].m_bCarriedVictim && IsValidSurvivor(g_InfectedSkillCache[attacker].m_iSpecialVictim))
    {
        // long incapacited charge check.
        Vector vecPos;
        vecPos.GetClientAbsOrigin(attacker);

        float flHeight = FloatAbs(vecPos.z) - FloatAbs(g_Charger[attacker].m_vecCarryStartPos.z);
        if (flHeight >= 360.0)  // should not be hardcoded valve.
        {
            HandleDeathCharge(attacker, victim, flHeight, g_Charger[attacker].m_vecCarryStartPos.Distance(vecPos, false), true);
        }
    }
}

void Event_ChargerChargeEnd(Event event, const char[] name, bool dontBroadcast)
{
    int charger = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidInfected(charger))
        return;

    if (!IsFakeClient(charger))
        SDKUnhook(charger, SDKHook_OnTakeDamageAlivePost, OnChargerTakeDamageAlivePost);
}

void Event_ChargerPummelStart(Event event, const char[] name, bool dontBroadcast)
{
    int charger = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidInfected(charger))
        return;

    g_Charger[charger].m_PummelTimer.Start();
}

// when being impacted and flung away by a charger.
void Event_ChargeImpact(Event event, const char[] name, bool dontBroadcast)
{
    //PrintToServer("[Skill Detect] Event_ChargeImpact called.");
    int client = GetClientOfUserId(event.GetInt("userid"));
    int victim = GetClientOfUserId(event.GetInt("victim"));

    if (!IsValidInfected(client) || !IsValidSurvivor(victim))
        return;

    // remember how many people the charger bumped into, and who, and where they were
    g_Survivor[victim].m_vecImpactStartPos.GetClientAbsOrigin(victim);
    g_Survivor[victim].m_iLastImpactAttacker = client;

    //PrintToServer("[Skill Detect] Event_ChargeImpact called, victim: %N, client: %N", victim, client);
    SDKHook(victim, SDKHook_PostThinkPost, OnFlingPostThinkPost);
}

// an attempt to rebuild CTerrorPlayer::EstimateFallingDamage. but without loop.
static void OnFlingPostThinkPost(int client)
{
    if (GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == -1)
    {
        g_Survivor[client].m_vecImpactLastVelocity.GetClientAbsVelocity(client);
        g_Survivor[client].m_iLastImpactHealth = GetEntProp(client, Prop_Data, "m_iHealth");
    }
    else
    {
        //PrintToServer("[Skill Detect] Player %N landed.", client)
        SDKUnhook(client, SDKHook_PostThinkPost, OnFlingPostThinkPost);

        Vector vecPos;
        vecPos.GetClientAbsOrigin(client);

        Vector vecMins, vecMaxs;
        vecMins.GetPlayerMins(client);
        vecMaxs.GetPlayerMaxs(client);

        int mask = (GetClientTeam(client) == 2) ? (MASK_NPCSOLID | CONTENTS_TEAM2 | CONTENTS_MIST) : (MASK_PLAYERSOLID | CONTENTS_TEAM1 | CONTENTS_MIST);
        Handle trace = TR_TraceHullFilterEx(vecPos.ToArray(), g_Survivor[client].m_vecImpactLastVelocity.ToArray(), vecMins.ToArray(), vecMaxs.ToArray(), mask, TR_Filter, client, TRACE_WORLD_ONLY);

        if (TR_AllSolid(trace) || TR_StartSolid(trace))
        {
            //PrintToServer("[Skill Detect] returning on shit.");
            return;
        }

        float fallVel;
        if (TR_GetFraction(trace) >= 1.0 || TR_GetFractionLeftSolid(trace) <= 0.7)
        {
            //PrintToServer("[Skill Detect] first check fallVel: %.2f", g_Survivor[client].m_vecImpactLastVelocity.z);
            fallVel = g_Survivor[client].m_vecImpactLastVelocity.z;
        }
        else
        {
            float flGravity = GetEntityGravity(client);
            float sv_gravity = FindConVar("sv_gravity").FloatValue * 0.1;
            float effectiveGravity = flGravity * sv_gravity;

            fallVel = g_Survivor[client].m_vecImpactLastVelocity.z + ((0.5 * (1.0 - TR_GetFraction(trace))) * effectiveGravity);
            //PrintToServer("[Skill Detect] second check fallVel: %.2f", fallVel);
        }
        
        //PrintToServer("[Skill Detect] fallVel: %.2f", fallVel);
        delete trace;
        float fallingSpeedDamage = FallingDamageForSpeed( -(fallVel + 560) );
        fallingSpeedDamage = fmaxf(fallingSpeedDamage, 0.0);
        //PrintToServer("[Skill Detect] fallingSpeedDamage: %.2f", fallingSpeedDamage);

        if (fallingSpeedDamage > 0.0)
        {
            if (fallingSpeedDamage > FindConVar("survivor_incap_max_fall_damage").FloatValue)
            {
                fallingSpeedDamage = FindConVar("survivor_incap_max_fall_damage").FloatValue;
            }

            //PrintToServer("[Skill Detect] fallingSpeedDamage: %.2f, LAST HEALTH: %d", fallingSpeedDamage, g_Survivor[client].m_iLastImpactHealth);
            if (g_hCvar_DeathChargeBlowCheckHealth.BoolValue)
            {
                if (fallingSpeedDamage < g_Survivor[client].m_iLastImpactHealth)
                    return;
            }
            
            Vector vecLandedPos;
            vecLandedPos.GetClientAbsOrigin(client);
            float flHeight = g_Survivor[client].m_vecImpactStartPos.z - vecLandedPos.z;
            //PrintToServer("[Skill Detect] flHeight: %.2f", flHeight);
            HandleDeathCharge(g_Survivor[client].m_iLastImpactAttacker, client, flHeight, g_Survivor[client].m_vecImpactStartPos.Distance(vecLandedPos), false);
        }

        g_Survivor[client].ResetImpact();
        return;
    }
}

static bool TR_Filter(int entity, int contentsMask, any data)
{
    if (entity == data || (entity >= 1 && entity <= MaxClients))
        return false;

    return true;
}

public void L4D_ActivateAbility_Charger_Post(int client, int ability)
{
    if (!IsFakeClient(client))
    {
        g_Charger[client].m_ChargeTimer.Start();
        SDKHook(client, SDKHook_OnTakeDamageAlivePost, OnChargerTakeDamageAlivePost);
    }
}

void OnChargerTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damageType)
{
    if (victim <= 0 || victim > MaxClients)
        return;

    if (!IsClientInGame(victim))
        return;

    if (attacker <= 0 || attacker > MaxClients)
        return;

    if (!IsClientInGame(attacker))
        return;

    if ((damageType & DMG_SLASH) || (damageType & DMG_CLUB))
        g_Charger[victim].m_flMeleeDamage = damage;
    
    ProcessChargerTakeDamage(victim, attacker, damage, damageType);
}

static void ProcessChargerTakeDamage(int victim, int attacker, float damage, int damageType)
{
    if (damageType & DMG_BUCKSHOT)
    {
        if (!g_Survivor[attacker].m_bShotCounted)
        {
            // count this shotgun pellet as once.
            g_Charger[victim].m_iShotsFired[attacker]++;
            g_Survivor[attacker].m_bShotCounted = true;
        }
    }
    else if (damageType & DMG_BULLET)
    {
        // just count this into.
        g_Charger[victim].m_iShotsFired[attacker]++;
    }

    g_Charger[victim].m_iDamage[attacker] += RoundToNearest(damage);
    g_Charger[victim].m_iTeamDamage += RoundToNearest(damage);
}

void ProcessChargerSkill(int attacker, int victim, float damage, int damageType)
{
    // a death charge by falling into the void, could be a hurt trigger or something else, anyway not a player.
    if (IsValidInfected(victim) && (damageType & DMG_FALL) && (attacker < 1 || attacker > MaxClients) && g_Charger[victim].m_bCarriedVictim)
    {
        Vector vecPos;
        vecPos.GetClientAbsOrigin(victim);
        float fHeight = FloatAbs(g_Charger[victim].m_vecCarryStartPos.z) - FloatAbs(vecPos.z);

        // carried dewath charge, the impacted death charge will be handled on player_death.
        HandleDeathCharge(victim, g_InfectedSkillCache[victim].m_iSpecialVictim, fHeight, g_Charger[victim].m_vecCarryStartPos.Distance(vecPos, false), true);
        g_Charger[victim].ResetCharger();
        return;
    }

    // skeeting a charger, consider as a skeet.
    if (IsValidSurvivor(attacker) && IsValidInfected(victim))
    {
        // melee?
        if ((damageType & DMG_SLASH) || (damageType & DMG_CLUB))
        {
            int iChargeHealth = g_hCvar_ChargerHealth.IntValue;
            (RoundToNearest(damage) > (iChargeHealth * 0.65)) ? HandleLevel(attacker, victim) : HandleLevelHurt(attacker, victim, RoundToNearest(damage));
            g_Charger[victim].ResetCharger();
            return;
        }

        // a clear. handled on player_death.
        if (g_Charger[victim].m_bCarriedVictim && g_Charger[victim].m_ChargeTimer.IsLessThan(g_hCvar_ClearThreh.FloatValue))
            return;

        HandleChargingSkeet(attacker, victim, g_Charger[victim].m_ChargeTimer.GetElapsedTime(), (g_Charger[victim].m_iTeamDamage > 0 && g_Charger[victim].m_iTeamDamage > g_Charger[victim].m_iDamage[attacker]));
        g_Charger[victim].ResetCharger();
    }
}
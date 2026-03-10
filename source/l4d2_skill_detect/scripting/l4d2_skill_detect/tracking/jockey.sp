#if defined _skill_detect_tracking_jockey_included
    #endinput
#endif
#define _skill_detect_tracking_jockey_included

enum struct JockeySkillCache_t
{
    // leap
    int m_iTeamDamage;                          // counting shotgun blast damage for hunter, counting entire survivor team's damage
    int m_iShotsFired[L4D2_MAXPLAYERS + 1];     // how many shots the survivor has fired to skeet a hunter.
    int m_iDamage[L4D2_MAXPLAYERS + 1];         // counting shotgun blast damage for hunter / skeeter combo
    bool m_bOnGround;                           // whether the jockey is on the ground or not.
    Vector m_vecLeapStartPos;                   // position that a jockey leapt from
    IntervalTimer_t m_RideStartTimer;           // time the jockey rides

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

    void ResetJockey()
    {
        this.m_vecLeapStartPos.Set(0.0, 0.0, 0.0);
        this.m_RideStartTimer.Invalidate();

        this.m_iTeamDamage = 0;
        for (int i = 1; i <= MaxClients; i++)
        {
            this.m_iDamage[i] = 0;
            this.m_iShotsFired[i] = 0;
        }
    }
}
JockeySkillCache_t g_Jockey[L4D2_MAXPLAYERS + 1];

Action JockeyLeap_Update(any action, int actor, float interval, ActionResult result)
{
    if (actor <= 0 || actor > MaxClients)
        return Plugin_Continue;

    if (!IsClientInGame(actor))
        return Plugin_Continue;

    Vector vecLeapPos;
    vecLeapPos.GetClientAbsOrigin(actor);

    // record the highest leap position.
    if (FloatAbs(vecLeapPos.z) > FloatAbs(g_Jockey[actor].m_vecLeapStartPos.z))
        g_Jockey[actor].m_vecLeapStartPos.Equal(vecLeapPos);


    g_Jockey[actor].m_bOnGround = GetEntPropEnt(actor, Prop_Send, "m_hGroundEntity") != -1;
    return Plugin_Continue;
}

// even later than jockey_ride.
Action JockeyLeap_OnEnd(any action, int actor, any priorAction, ActionResult result)
{
    if (actor <= 0 || actor > MaxClients)
        return Plugin_Continue;

    if (!IsClientInGame(actor))
        return Plugin_Continue;

    g_Jockey[actor].ResetJockey();
    return Plugin_Continue;
}

Action JockeyLeap_OnInjured(any action, int actor, CTakeDamageInfo info, ActionDesiredResult result)
{
    if (actor <= 0 || actor > MaxClients)
        return Plugin_Continue;

    if (!IsClientInGame(actor))
        return Plugin_Continue;

    // already had a victim, not a skeet.
    if (g_Infected[actor].m_iSpecialVictim)
        return Plugin_Continue;
    
    int attacker = info.m_hAttacker;
    int damageType = info.m_bitsDamageType;
    float damage = info.m_flDamage;

    if (attacker <= 0 || attacker > MaxClients)
        return Plugin_Continue;

    if (!IsClientInGame(attacker))
        return Plugin_Continue;

    ProccessJockeyTakeDamage(actor, attacker, damage, damageType);
    return Plugin_Continue;
}

Action JockeyLeap_OnKilled(any action, int actor, CTakeDamageInfo info, ActionDesiredResult result)
{
    if (actor <= 0 || actor > MaxClients)
        return Plugin_Continue;

    if (!IsClientInGame(actor))
        return Plugin_Continue;

    // already had a victim, not a skeet.
    if (g_Infected[actor].m_iSpecialVictim)
    {
        g_Jockey[actor].ResetJockey();
        return Plugin_Continue;
    }

    if (g_Jockey[actor].m_bOnGround)
        return Plugin_Continue;

    int attacker = info.m_hAttacker;
    int weapon = info.m_hWeapon;
    int damageType = info.m_bitsDamageType;

    if (attacker <= 0 || attacker > MaxClients)
        return Plugin_Continue;

    if (!IsClientInGame(attacker) || GetClientTeam(attacker) != 2)
        return Plugin_Continue;
    
    ProcessJockeySkeet(attacker, actor, weapon, damageType);
    return Plugin_Continue;
}

// on shoved is always later than started, killed and injured, faster than end.
Action JockeyLeap_OnShoved(any action, int actor, int entity, ActionDesiredResult result)
{
    if (actor <= 0 || actor > MaxClients)
        return Plugin_Continue;

    if (!IsClientInGame(actor))
        return Plugin_Continue;

    if (g_Jockey[actor].m_bOnGround)
        return Plugin_Continue;

    HandleDeadstop(entity, actor);
    g_Jockey[actor].ResetJockey();
    return Plugin_Continue;
}

void Event_JockeyRide(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int victim = GetClientOfUserId(event.GetInt("victim"));

    if (!IsValidInfected(client) || !IsValidSurvivor(victim))
        return;

    g_Jockey[client].m_RideStartTimer.Start();

    Vector endPos;
    endPos.GetClientAbsOrigin(client);
    float fHeight = FloatAbs(g_Jockey[client].m_vecLeapStartPos.z) - FloatAbs(endPos.z);

    // (high) pounce
    HandleJockeyDP(client, victim, fHeight);
    g_Jockey[client].ResetJockey();
}

public void L4D_ActivateAbility_Jockey_Post(int client, int ability)
{
    if (!IsFakeClient(client))
    {
        SDKHook(client, SDKHook_PostThinkPost, OnJockeyPostThinkPost);
        SDKHook(client, SDKHook_OnTakeDamageAlivePost, OnJockeyTakeDamageAlivePost);
    }
}

void OnJockeyTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damageType)
{
    if (victim <= 0 || victim > MaxClients)
        return;

    if (!IsClientInGame(victim))
        return;

    if (attacker <= 0 || attacker > MaxClients)
        return;

    if (!IsClientInGame(attacker))
        return;

    ProccessJockeyTakeDamage(victim, attacker, damage, damageType);
}

void OnJockeyPostThinkPost(int client)
{
    g_Jockey[client].m_bOnGround = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1;
    if (!g_Jockey[client].m_bOnGround)
    {
        Vector vecLeapPos;
        vecLeapPos.GetClientAbsOrigin(client);

        // record the highest leap position.
        if (FloatAbs(vecLeapPos.z) > FloatAbs(g_Jockey[client].m_vecLeapStartPos.z))
            g_Jockey[client].m_vecLeapStartPos.Equal(vecLeapPos);
    }
    else
    {
        g_Jockey[client].ResetJockey();
        SDKUnhook(client, SDKHook_PostThinkPost, OnJockeyPostThinkPost);
        SDKUnhook(client, SDKHook_OnTakeDamageAlivePost, OnJockeyTakeDamageAlivePost);
    }
}

static void ProccessJockeyTakeDamage(int victim, int attacker, float damage, int damageType)
{
    if (!g_Jockey[victim].m_bOnGround)
    {
        if (damageType & DMG_BUCKSHOT)
        {
            if (!g_Survivor[attacker].m_bShotCounted)
            {
                // count this shotgun pellet as once.
                g_Jockey[victim].m_iShotsFired[attacker]++;
                g_Survivor[attacker].m_bShotCounted = true;
            }
        }
        else if (damageType & DMG_BULLET)
        {
            // just count this into.
            g_Jockey[victim].m_iShotsFired[attacker]++;
        }

        g_Jockey[victim].m_iDamage[attacker] += RoundToNearest(damage);
        g_Jockey[victim].m_iTeamDamage += RoundToNearest(damage);
    }
}

void ProcessJockeySkeet(int attacker, int victim, int weapon, int damageType)
{
    // skeet?
    if (g_Jockey[victim].m_iTeamDamage > 0 && g_Jockey[victim].m_iTeamDamage > g_Jockey[victim].m_iDamage[attacker])
    {
        // team skeet
        HandleJockeySkeet(attacker, victim, _, _, _, true);
    }
    else if ((damageType & DMG_BULLET) || (damageType & DMG_BUCKSHOT))
    {
        char weaponA[32];
        strWeaponType weaponTypeA;
        GetEdictClassname(weapon, weaponA, sizeof(weaponA));

        if (g_hMapWeapons.GetValue(weaponA, weaponTypeA) && (weaponTypeA == WPTYPE_SNIPER || weaponTypeA == WPTYPE_MAGNUM))
        {
            if (g_hCvar_AllowSniper.BoolValue)
                HandleJockeySkeet(attacker, victim, false, true);
        }

        // single player skeet
        HandleJockeySkeet(attacker, victim);
    }
    else if (damageType & (DMG_BLAST | DMG_PLASMA))
    {
        // direct GL hit?
        /*
            direct hit is DMG_BLAST | DMG_PLASMA
            indirect hit is DMG_AIRBOAT
        */

        char weaponB[32];
        strWeaponType weaponTypeB;
        GetEdictClassname(weapon, weaponB, sizeof(weaponB));

        if (g_hMapWeapons.GetValue(weaponB, weaponTypeB) && weaponTypeB == WPTYPE_GL)
        {
            if (g_hCvar_AllowGLSkeet.BoolValue)
                HandleJockeySkeet(attacker, victim, false, false, true);
        }
    }
    else if ((damageType & DMG_SLASH) || (damageType & DMG_CLUB))
    {
        // melee skeet
        if (g_hCvar_AllowMelee.BoolValue)
            HandleJockeySkeet(attacker, victim, true);
    }

    g_Jockey[victim].ResetJockey();
}
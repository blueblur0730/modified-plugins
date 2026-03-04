#if defined _skill_detect_tracking_charger_included
    #endinput
#endif
#define _skill_detect_tracking_charger_included

void TraceAttackPost_Charger(int victim, int attacker, int inflictor, float damage, int damagetype, int ammotype, int hitbox, int hitgroup)
{
    // track pinning
    int victimA = GetEntPropEnt(victim, Prop_Send, "m_carryVictim");

    if (victimA != -1)
    {
        g_InfectedSkillCache[victim].m_iSpecialVictim = victimA;
    }
    else
    {
        g_InfectedSkillCache[victim].m_iSpecialVictim = GetEntPropEnt(victim, Prop_Send, "m_pummelVictim");
    }
}

// charger carrying
void Event_ChargeCarryStart(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int victim = GetClientOfUserId(event.GetInt("victim"));

    if (!IsValidInfected(client))
        return;

    PrintDebug("Charge carry start: %i - %i -- time: %.2f", client, victim, GetGameTime());

    g_InfectedSkillCache[client].m_ChargeTimer.Start();
    g_InfectedSkillCache[client].m_flPinTime[0] = g_InfectedSkillCache[client].m_ChargeTimer.m_timestamp;
    g_InfectedSkillCache[client].m_flPinTime[1] = 0.0;

    if (!IsValidSurvivor(victim))
        return;

    g_InfectedSkillCache[client].m_iChargeVictim  = victim;               // store who we're carrying (as long as this is set, it's not considered an impact charge flight)
    g_SurvivorSkillCache[victim].m_iVictimCharger = client;               // store who's charging whom
    g_SurvivorSkillCache[victim].m_iVictimFlags      = VICFLG_CARRIED;       // reset flags for checking later - we know only this now
    g_SurvivorSkillCache[victim].m_ChargeTimer      = g_InfectedSkillCache[client].m_ChargeTimer;
    g_SurvivorSkillCache[victim].m_iVictimMapDmg  = 0;

    GetClientAbsOrigin(victim, g_SurvivorSkillCache[victim].m_flChargeVictimPos);

    // CreateTimer( CHARGE_CHECK_TIME, Timer_ChargeCheck, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
    CreateTimer(CHARGE_CHECK_TIME, Timer_ChargeCheck, victim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void Event_ChargeImpact(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int victim = GetClientOfUserId(event.GetInt("victim"));

    if (!IsValidInfected(client) || !IsValidSurvivor(victim))
        return;

    // remember how many people the charger bumped into, and who, and where they were
    GetClientAbsOrigin(victim, g_SurvivorSkillCache[victim].m_flChargeVictimPos);

    g_SurvivorSkillCache[victim].m_iVictimCharger = client;              // store who we've bumped up
    g_SurvivorSkillCache[victim].m_iVictimFlags      = 0;                  // reset flags for checking later
    g_SurvivorSkillCache[victim].m_ChargeTimer.Start();      // store time per victim, for impacts
    g_SurvivorSkillCache[victim].m_iVictimMapDmg  = 0;

    CreateTimer(CHARGE_CHECK_TIME, Timer_ChargeCheck, victim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void Event_ChargePummelStart(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidInfected(client))
        return;

    g_InfectedSkillCache[client].m_flPinTime[1] = GetGameTime();
}

void Event_ChargeCarryEnd(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client < 1 || client > MaxClients)
        return;

    g_InfectedSkillCache[client].m_flPinTime[1] = GetGameTime();

    // delay so we can check whether charger died 'mid carry'
    CreateTimer(0.1, Timer_ChargeCarryEnd, client, TIMER_FLAG_NO_MAPCHANGE);
}

static void Timer_ChargeCarryEnd(Handle timer, int client)
{
    // set charge time to 0 to avoid deathcharge timer continuing
    g_InfectedSkillCache[client].m_iChargeVictim = 0;     // unset this so the repeated timer knows to stop for an ongroundcheck
}

static void Timer_ChargeCheck(Handle timer, int client)
{
    static float flTime = 0.0;
    if (GetGameTime() - flTime < 1.0)
        return;

    flTime = GetGameTime();

    // if something went wrong with the survivor or it was too long ago, forget about it
    if (!IsValidSurvivor(client) || !g_SurvivorSkillCache[client].m_iVictimCharger || !g_SurvivorSkillCache[client].m_ChargeTimer.HasStarted() || g_SurvivorSkillCache[client].m_ChargeTimer.IsGreaterThan(MAX_CHARGE_TIME))
        return;

    // we're done checking if either the victim reached the ground, or died
    if (!IsPlayerAlive(client))
    {
        // player died (this was .. probably.. a death charge)
        g_SurvivorSkillCache[client].m_iVictimFlags = g_SurvivorSkillCache[client].m_iVictimFlags | VICFLG_AIRDEATH;

        // check conditions now
        CreateTimer(0.0, Timer_DeathChargeCheck, client, TIMER_FLAG_NO_MAPCHANGE);
    }
    else if (GetEntityFlags(client) & FL_ONGROUND && g_InfectedSkillCache[g_SurvivorSkillCache[client].m_iVictimCharger].m_iChargeVictim != client)
    {
        // survivor reached the ground and didn't die (yet)
        // the client-check condition checks whether the survivor is still being carried by the charger
        //      (in which case it doesn't matter that they're on the ground)

        // check conditions with small delay (to see if they still die soon)
        CreateTimer(CHARGE_END_CHECK, Timer_DeathChargeCheck, client, TIMER_FLAG_NO_MAPCHANGE);
    }
}

static void Timer_DeathChargeCheck(Handle timer, int client)
{
    if (!IsValidClientInGame(client))
        return;

    // check conditions.. if flags match up, it's a DC
    PrintDebug("Checking charge victim: %i - %i - flags: %i (alive? %i)", g_SurvivorSkillCache[client].m_iVictimCharger, client, g_SurvivorSkillCache[client].m_iVictimFlags, IsPlayerAlive(client));

    int flags = g_SurvivorSkillCache[client].m_iVictimFlags;

    if (!IsPlayerAlive(client))
    {
        float pos[3];
        GetClientAbsOrigin(client, pos);
        float fHeight = g_SurvivorSkillCache[client].m_flChargeVictimPos[2] - pos[2];

        /*
            it's a deathcharge when:
                the survivor is dead AND
                    they drowned/fell AND took enough damage or died in mid-air
                    AND not killed by someone else
                    OR is in an unreachable spot AND dropped at least X height
                    OR took plenty of map damage

            old.. need?
                fHeight > g_hCvar_DeathChargeHeight.FloatValue
        */
        if (((flags & VICFLG_DROWN || flags & VICFLG_FALL) && (flags & VICFLG_HURTLOTS || flags & VICFLG_AIRDEATH) || (flags & VICFLG_WEIRDFLOW && fHeight >= MIN_FLOWDROPHEIGHT) || g_SurvivorSkillCache[client].m_iVictimMapDmg >= MIN_DC_TRIGGER_DMG) && !(flags & VICFLG_KILLEDBYOTHER))
            HandleDeathCharge(g_SurvivorSkillCache[client].m_iVictimCharger, client, fHeight, GetVectorDistance(g_SurvivorSkillCache[client].m_flChargeVictimPos, pos, false), view_as<bool>(flags & VICFLG_CARRIED));
    }
    else if ((flags & VICFLG_WEIRDFLOW || g_SurvivorSkillCache[client].m_iVictimMapDmg >= MIN_DC_RECHECK_DMG) && !(flags & VICFLG_WEIRDFLOWDONE))
    {
        // could be incapped and dying more slowly
        // flag only gets set on preincap, so don't need to check for incap
        g_SurvivorSkillCache[client].m_iVictimFlags = g_SurvivorSkillCache[client].m_iVictimFlags | VICFLG_WEIRDFLOWDONE;

        CreateTimer(CHARGE_END_RECHECK, Timer_DeathChargeCheck, client, TIMER_FLAG_NO_MAPCHANGE);
    }
}
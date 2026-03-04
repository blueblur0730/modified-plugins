#if defined _skill_detect_tracking_smoker_included
    #endinput
#endif
#define _skill_detect_tracking_smoker_included

// smoker tongue cutting & self clears
void Event_TonguePullStopped(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("userid"));
    int victim = GetClientOfUserId(event.GetInt("victim"));
    int smoker = GetClientOfUserId(event.GetInt("smoker"));
    int reason = event.GetInt("release_type");

    if (!IsValidSurvivor(attacker) || !IsValidInfected(smoker))
        return;

    // clear check -  if the smoker itself was not shoved, handle the clear
    HandleClear(attacker, smoker, victim,
                ZC_SMOKER,
                (g_InfectedSkillCache[smoker].m_flPinTime[1] > 0.0) ? (GetGameTime() - g_InfectedSkillCache[smoker].m_flPinTime[1]) : -1.0,
                (GetGameTime() - g_InfectedSkillCache[smoker].m_flPinTime[0]),
                view_as<bool>(reason != CUT_SLASH && reason != CUT_KILL));

    if (attacker != victim)
        return;

    if (reason == CUT_KILL)
    {
        g_InfectedSkillCache[smoker].m_bSmokerClearCheck = true;
    }
    else if (g_InfectedSkillCache[smoker].m_bSmokerShoved)
    {
        HandleSmokerSelfClear(attacker, smoker, true);
    }
    else if (reason == CUT_SLASH)     // note: can't trust this to actually BE a slash..
    {
        // check weapon
        char weapon[32];
        GetClientWeapon(attacker, weapon, 32);

        // this doesn't count the chainsaw, but that's no-skill anyway
        if (StrEqual(weapon, "weapon_melee", false))
            HandleTongueCut(attacker, smoker);
    }
}

void Event_TongueGrab(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("userid"));
    int victim = GetClientOfUserId(event.GetInt("victim"));

    if (IsValidInfected(attacker) && IsValidSurvivor(victim))
    {
        // new pull, clean damage
        g_InfectedSkillCache[attacker].m_bSmokerClearCheck = false;
        g_InfectedSkillCache[attacker].m_bSmokerShoved = false;
        g_InfectedSkillCache[attacker].m_iSmokerVictim = victim;
        g_InfectedSkillCache[attacker].m_iSmokerVictimDamage = 0;
        g_InfectedSkillCache[attacker].m_flPinTime[0] = GetGameTime();
        g_InfectedSkillCache[attacker].m_flPinTime[1] = 0.0;
    }
}

void Event_ChokeStart(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("userid"));

    if (g_InfectedSkillCache[attacker].m_flPinTime[0] == 0.0)
        g_InfectedSkillCache[attacker].m_flPinTime[0] = GetGameTime();

    g_InfectedSkillCache[attacker].m_flPinTime[1] = GetGameTime();
}

void Event_ChokeStop(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("userid"));
    int victim = GetClientOfUserId(event.GetInt("victim"));
    int smoker = GetClientOfUserId(event.GetInt("smoker"));
    int reason = event.GetInt("release_type");

    if (!IsValidSurvivor(attacker) || !IsValidInfected(smoker))
        return;

    // if the smoker itself was not shoved, handle the clear
    HandleClear(attacker, smoker, victim,
                ZC_SMOKER,
                (g_InfectedSkillCache[smoker].m_flPinTime[1] > 0.0) ? (GetGameTime() - g_InfectedSkillCache[smoker].m_flPinTime[1]) : -1.0,
                (GetGameTime() - g_InfectedSkillCache[smoker].m_flPinTime[0]),
                view_as<bool>(reason != CUT_SLASH && reason != CUT_KILL));
}

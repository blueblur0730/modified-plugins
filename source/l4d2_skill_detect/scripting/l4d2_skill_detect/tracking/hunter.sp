#if defined _skill_detect_tracking_hunter_included
    #endinput
#endif
#define _skill_detect_tracking_hunter_included

// trace attacks on hunters
void TraceAttackPost_Hunter(int victim, int attacker, int inflictor, float damage, int damagetype, int ammotype, int hitbox, int hitgroup)
{
    // track pinning
    g_InfectedSkillCache[victim].m_iSpecialVictim = GetEntPropEnt(victim, Prop_Send, "m_pounceVictim");

    if (!IsValidSurvivor(attacker) || !IsValidEdict(inflictor))
        return;

    // track flight
    if (GetEntProp(victim, Prop_Send, "m_isAttemptingToPounce"))
    {
        g_InfectedSkillCache[victim].m_HunterTracePouncingTimer.Start();
    }
    else
    {
        g_InfectedSkillCache[victim].m_HunterTracePouncingTimer.Invalidate();
    }
}

void Event_LungePounce(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int victim = GetClientOfUserId(event.GetInt("victim"));

    g_InfectedSkillCache[client].m_flPinTime[0] = GetGameTime();

    // clear hunter-hit stats (not skeeted)
    ResetHunter(client);

    // check if it was a DP
    // ignore if no real pounce start pos
    if (g_InfectedSkillCache[client].m_flPouncePosition[0] == 0.0
        && g_InfectedSkillCache[client].m_flPouncePosition[1] == 0.0
        && g_InfectedSkillCache[client].m_flPouncePosition[2] == 0.0)
    {
        return;
    }

    float endPos[3];
    GetClientAbsOrigin(client, endPos);
    float fHeight  = g_InfectedSkillCache[client].m_flPouncePosition[2] - endPos[2];

    // from pounceannounce:
    // distance supplied isn't the actual 2d vector distance needed for damage calculation. See more about it at
    // http://forums.alliedmods.net/showthread.php?t=93207

    float fMin = g_hCvar_MinPounceDistance.FloatValue;
    float fMax = g_hCvar_MaxPounceDistance.FloatValue;
    float fMaxDmg = g_hCvar_MaxPounceDamage.FloatValue;

    // calculate 2d distance between previous position and pounce position
    int distance = RoundToNearest(GetVectorDistance(g_InfectedSkillCache[client].m_flPouncePosition, endPos));

    // get damage using hunter damage formula
    // check if this is accurate, seems to differ from actual damage done!
    float fDamage  = (((float(distance) - fMin) / (fMax - fMin)) * fMaxDmg) + 1.0;

    // apply bounds
    if (fDamage < 0.0)
    {
        fDamage = 0.0;
    }
    else if (fDamage > fMaxDmg + 1.0)
    {
        fDamage = fMaxDmg + 1.0;
    }

    DataPack pack = new DataPack();
    pack.WriteCell(client);
    pack.WriteCell(victim);
    pack.WriteFloat(fDamage);
    pack.WriteFloat(fHeight);
    CreateTimer(0.05, Timer_HunterDP, pack);
}

static void Timer_HunterDP(Handle timer, DataPack pack)
{
    pack.Reset();
    int client  = pack.ReadCell();
    int victim  = pack.ReadCell();
    float fDamage = pack.ReadFloat();
    float fHeight = pack.ReadFloat();
    delete pack;

    HandleHunterDP(client, victim, g_InfectedSkillCache[client].m_iPounceDamage, fDamage, fHeight);
}

void ResetHunter(int client)
{
    g_InfectedSkillCache[client].m_iHunterShotDmgTeam = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        g_InfectedSkillCache[client].m_iHunterShotDmg[i]    = 0;
        g_InfectedSkillCache[client].m_HunterShotStartTimer[i].Invalidate();
    }

    g_InfectedSkillCache[client].m_iHunterOverkill = 0;
}

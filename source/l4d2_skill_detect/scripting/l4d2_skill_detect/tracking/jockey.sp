#if defined _skill_detect_tracking_jockey_included
    #endinput
#endif
#define _skill_detect_tracking_jockey_included

void Event_JockeyRide(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int victim = GetClientOfUserId(event.GetInt("victim"));

    if (!IsValidInfected(client) || !IsValidSurvivor(victim))
        return;

    g_InfectedSkillCache[client].m_flPinTime[0] = GetGameTime();

    // minimum distance travelled?
    // ignore if no real pounce start pos
    if (g_InfectedSkillCache[client].m_flPouncePosition[0] == 0.0 && 
        g_InfectedSkillCache[client].m_flPouncePosition[1] == 0.0 && 
        g_InfectedSkillCache[client].m_flPouncePosition[2] == 0.0)
        return;

    float endPos[3];
    GetClientAbsOrigin(client, endPos);
    float fHeight = g_InfectedSkillCache[client].m_flPouncePosition[2] - endPos[2];

    // (high) pounce
    HandleJockeyDP(client, victim, fHeight);
}

void TraceAttackPost_Jockey(int victim, int attacker, int inflictor, float damage, int damagetype, int ammotype, int hitbox, int hitgroup)
{
    // track pinning
    g_InfectedSkillCache[victim].m_iSpecialVictim = GetEntPropEnt(victim, Prop_Send, "m_jockeyVictim");
}
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
    if (g_InfectedSkillCache[client].m_vecLeapStartPos.Set(0.0, 0.0, 0.0))
        return;

    Vector endPos;
    endPos.GetClientAbsOrigin(client);
    float fHeight = g_InfectedSkillCache[client].m_vecLeapStartPos.z - endPos.z;

    // (high) pounce
    HandleJockeyDP(client, victim, fHeight);
}
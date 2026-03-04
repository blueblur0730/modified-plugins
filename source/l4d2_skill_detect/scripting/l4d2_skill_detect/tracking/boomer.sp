#if defined _skill_detect_tracking_boomer_included
    #endinput
#endif
#define _skill_detect_tracking_boomer_included

// boomer got somebody
void Event_PlayerBoomed(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    bool byBoom = event.GetBool("by_boomer");

    if (byBoom && IsValidInfected(attacker))
    {
        g_InfectedSkillCache[attacker].m_bBoomerHitSomebody = true;

        // check if it was vomit spray
        bool byExplosion = event.GetBool("exploded");
        if (!byExplosion)
        {
            // count amount of booms
            if (!g_InfectedSkillCache[attacker].m_iBoomerVomitHits)
            {
                // check for boom count later
                CreateTimer(VOMIT_DURATION_TIME, Timer_BoomVomitCheck, attacker, TIMER_FLAG_NO_MAPCHANGE);
            }

            g_InfectedSkillCache[attacker].m_iBoomerVomitHits++;
        }
    }
}

// check how many booms landed
static void Timer_BoomVomitCheck(Handle timer, int client)
{
    HandleVomitLanded(client, g_InfectedSkillCache[client].m_iBoomerVomitHits);
    g_InfectedSkillCache[client].m_iBoomerVomitHits = 0;
}

// boomers that didn't bile anyone
void Event_BoomerExploded(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    bool biled    = event.GetBool("splashedbile");
    if (!biled && !g_InfectedSkillCache[client].m_bBoomerHitSomebody)
    {
        int attacker = GetClientOfUserId(event.GetInt("attacker"));
        if (IsValidSurvivor(attacker))
            HandlePop(attacker, client, g_InfectedSkillCache[client].m_iBoomerGotShoved, (GetGameTime() - g_InfectedSkillCache[client].m_flSpawnTime));
    }
}
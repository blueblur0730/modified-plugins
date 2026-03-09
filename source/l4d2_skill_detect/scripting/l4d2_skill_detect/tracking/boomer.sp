#if defined _skill_detect_tracking_boomer_included
    #endinput
#endif
#define _skill_detect_tracking_boomer_included

enum struct BoomerSkillCache_t
{
    // pops
    IntervalTimer_t m_SpawnTimer;               // time the SI spawned up
    IntervalTimer_t m_VomitStartTimer;          // timer for vomit duration
    bool m_bBoomerHitSomebody;                  // false if boomer didn't puke/exploded on anybody
    int m_iBoomerGotShoved;                     // how many times the boomer got shoved
    int m_iBoomerVomitHits;                     // how many booms in one vomit so far
}
BoomerSkillCache_t g_Boomer[L4D2_MAXPLAYERS + 1];

// boomer got somebody
void Event_PlayerVomit(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    bool byBoom = event.GetBool("by_boomer");

    if (byBoom && IsValidInfected(attacker))
    {
        g_Boomer[attacker].m_bBoomerHitSomebody = true;

        // check if it was vomit spray
        bool byExplosion = event.GetBool("exploded");
        if (!byExplosion)
        {
            // count amount of booms
            if (!g_Boomer[attacker].m_iBoomerVomitHits)
            {
                // check for boom count later
                CreateTimer(VOMIT_DURATION_TIME, Timer_BoomVomitCheck, attacker, TIMER_FLAG_NO_MAPCHANGE);
            }

            g_Boomer[attacker].m_iBoomerVomitHits++;
        }
    }
}

// check how many booms landed
static void Timer_BoomVomitCheck(Handle timer, int client)
{
    HandleVomitLanded(client, g_Boomer[client].m_iBoomerVomitHits);
    g_Boomer[client].m_iBoomerVomitHits = 0;
}

// boomers that didn't bile anyone
void Event_BoomerExploded(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    bool biled    = event.GetBool("splashedbile");
    if (!biled && !g_Boomer[client].m_bBoomerHitSomebody)
    {
        int attacker = GetClientOfUserId(event.GetInt("attacker"));
        if (IsValidSurvivor(attacker))
            HandlePop(attacker, client, g_Boomer[client].m_iBoomerGotShoved, g_Boomer[client].m_SpawnTimer.GetElapsedTime());
    }
}
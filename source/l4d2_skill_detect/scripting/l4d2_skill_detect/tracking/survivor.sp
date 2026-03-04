#if defined _skill_detect_tracking_survivor_included
    #endinput
#endif
#define _skill_detect_tracking_survivor_included

void Event_PlayerJumped(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (IsValidInfected(client))
    {
        int zClass = GetEntProp(client, Prop_Send, "m_zombieClass");
        if (zClass != ZC_JOCKEY)
            return;

        // where did jockey jump from?
        GetClientAbsOrigin(client, g_InfectedSkillCache[client].m_flPouncePosition);
    }
    else if (IsValidSurvivor(client))
    {
        // could be the start or part of a hopping streak

        float fPos[3];
        float fVel[3];
        GetClientAbsOrigin(client, fPos);
        GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);
        fVel[2] = 0.0;      // safeguard

        float fLengthNew;
        float fLengthOld;
        fLengthNew = GetVectorLength(fVel);

        g_SurvivorSkillCache[client].m_bHopCheck = false;

        if (!g_SurvivorSkillCache[client].m_bIsHopping)
        {
            if (fLengthNew >= g_hCvar_BHopMinInitSpeed.FloatValue)
            {
                // starting potential hop streak
                g_SurvivorSkillCache[client].m_flHopTopVelocity = fLengthNew;
                g_SurvivorSkillCache[client].m_bIsHopping        = true;
                g_SurvivorSkillCache[client].m_iHops            = 0;
            }
        }
        else
        {
            // check for hopping streak
            fLengthOld = GetVectorLength(g_SurvivorSkillCache[client].m_flLastHop);

            // if they picked up speed, count it as a hop, otherwise, we're done hopping
            if (fLengthNew - fLengthOld > HOP_ACCEL_THRESH || fLengthNew >= g_hCvar_BHopContSpeed.FloatValue)
            {
                g_SurvivorSkillCache[client].m_iHops++;

                // this should always be the case...
                if (fLengthNew > g_SurvivorSkillCache[client].m_flHopTopVelocity)
                    g_SurvivorSkillCache[client].m_flHopTopVelocity = fLengthNew;

                // PrintToChat( client, "bunnyhop %i: speed: %.1f / increase: %.1f", g_SurvivorSkillCache[client].m_iHops, fLengthNew, fLengthNew - fLengthOld );
            }
            else
            {
                g_SurvivorSkillCache[client].m_bIsHopping = false;

                if (g_SurvivorSkillCache[client].m_iHops)
                {
                    HandleBHopStreak(client, g_SurvivorSkillCache[client].m_iHops, g_SurvivorSkillCache[client].m_flHopTopVelocity);
                    g_SurvivorSkillCache[client].m_iHops = 0;
                }
            }
        }

        g_SurvivorSkillCache[client].m_flLastHop[0] = fVel[0];
        g_SurvivorSkillCache[client].m_flLastHop[1] = fVel[1];
        g_SurvivorSkillCache[client].m_flLastHop[2] = fVel[2];

        if (g_SurvivorSkillCache[client].m_iHops != 0)
        {
            // check when the player returns to the ground
            CreateTimer(HOP_CHECK_TIME, Timer_CheckHop, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

// player back to ground = end of hop (streak)?
static void Timer_CheckHop(Handle timer, int client)
{
    // streak stopped by dying / teamswitch / disconnect?
    if (!IsValidClientInGame(client) || !IsPlayerAlive(client))
        return;

    if (GetEntityFlags(client) & FL_ONGROUND)
    {
        float fVel[3];
        GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);
        fVel[2] = 0.0;       // safeguard

        // PrintToChatAll("grounded %i: vel length: %.1f", client, GetVectorLength(fVel) );
        g_SurvivorSkillCache[client].m_bHopCheck = true;
        CreateTimer(HOPEND_CHECK_TIME, Timer_CheckHopStreak, client, TIMER_FLAG_NO_MAPCHANGE);
    }
}

static void Timer_CheckHopStreak(Handle timer, int client)
{
    if (!IsValidClientInGame(client) || !IsPlayerAlive(client))
        return;

    // check if we have any sort of hop streak, and report
    if (g_SurvivorSkillCache[client].m_bHopCheck && g_SurvivorSkillCache[client].m_iHops)
    {
        HandleBHopStreak(client, g_SurvivorSkillCache[client].m_iHops, g_SurvivorSkillCache[client].m_flHopTopVelocity);
        g_SurvivorSkillCache[client].m_bIsHopping       = false;
        g_SurvivorSkillCache[client].m_iHops            = 0;
        g_SurvivorSkillCache[client].m_flHopTopVelocity = 0.0;
    }

    g_SurvivorSkillCache[client].m_bHopCheck = false;
}

void Event_PlayerJumpApex(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (g_SurvivorSkillCache[client].m_bIsHopping)
    {
        float fVel[3];
        GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);
        fVel[2] = 0.0;
        float fLength = GetVectorLength(fVel);

        if (fLength > g_SurvivorSkillCache[client].m_flHopTopVelocity)
        {
            g_SurvivorSkillCache[client].m_flHopTopVelocity = fLength;
        }
    }
}

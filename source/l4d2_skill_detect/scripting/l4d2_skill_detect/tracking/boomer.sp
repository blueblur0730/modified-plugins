#if defined _skill_detect_tracking_boomer_included
    #endinput
#endif
#define _skill_detect_tracking_boomer_included

enum struct BoomerSkillCache_t
{
    // pops
    IntervalTimer_t m_SpawnTimer;               // time the SI spawned up
    CountdownTimer_t m_VomitDurationTimer;          // timer for vomit duration

    void ResetBoomer()
    {
        this.m_SpawnTimer.Invalidate();
        this.m_VomitDurationTimer.Invalidate();
    }
}
BoomerSkillCache_t g_Boomer[L4D2_MAXPLAYERS + 1];

public void L4D_ActivateAbility_Boomer_Post(int client, int ability)
{
    static ConVar z_vomit_duration = null;
    if (!z_vomit_duration)
        z_vomit_duration = FindConVar("z_vomit_duration");
    
    g_Boomer[client].m_VomitDurationTimer.Start(z_vomit_duration.FloatValue);
    SDKHook(client, SDKHook_PostThinkPost, OnVomitPostThinkPost);
}

void OnVomitPostThinkPost(int client)
{
    // vomit ended or popped during vomitting.
    if (g_Boomer[client].m_VomitDurationTimer.IsElapsed() || !IsPlayerAlive(client))
    {
        SDKUnhook(client, SDKHook_PostThinkPost, OnVomitPostThinkPost);

        int itCount = 0;
        int itSurvivor[L4D2_MAXPLAYERS + 1];

        for (int i = 1; i < MaxClients; i++)
        {
            if (!IsClientInGame(i) || GetClientTeam(i) != 2)
                return;

            if (IsIT(i) && !L4D_IsPlayerStaggering(i)) 
            {
                itSurvivor[itCount] = i;
                itCount++;
            }
        }

        HandleVomitLanded(client, itCount);
        g_Boomer[client].ResetBoomer();
    }
}

void Event_BoomerExploded(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    bool biled = event.GetBool("splashedbile");
    if (!biled)
    {
        int attacker = GetClientOfUserId(event.GetInt("attacker"));
        if (IsValidSurvivor(attacker))
            HandlePop(attacker, client, GetCurrentShoveCount(client), g_Boomer[client].m_SpawnTimer.GetElapsedTime());

        g_Boomer[client].ResetBoomer();
    }
}
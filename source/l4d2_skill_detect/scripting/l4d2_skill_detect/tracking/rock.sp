#if defined _skill_detect_tracking_rock_included
    #endinput
#endif
#define _skill_detect_tracking_rock_included

enum struct TankRockTrace_t
{
    int m_iThrower;        // who throwed the rock
    int m_iRock;           // rock entity index
    int m_iDamageTaken;    // how much damage was taken by the player
    int m_iSkeeter;        // who skeeted the rock
}
ArrayList g_hArray_TankRockTrace;

// tank rock
void TraceAttackPost_Rock(int victim, int attacker, int inflictor, float damage, int damagetype, int ammotype, int hitbox, int hitgroup)
{
    if (IsValidSurvivor(attacker))
    {
        int index = g_hArray_TankRockTrace.FindValue(victim, TankRockTrace_t::m_iRock);
        if (index != -1)
        {
            TankRockTrace_t rockTrace;
            g_hArray_TankRockTrace.GetArray(index, rockTrace, sizeof(rockTrace));
            rockTrace.m_iDamageTaken = RoundToFloor(damage);
            rockTrace.m_iSkeeter = attacker;
            g_hArray_TankRockTrace.SetArray(index, rockTrace, sizeof(rockTrace));
        }
    }
}

void OnTouchPost_Rock(int entity, int other)
{
    int index = g_hArray_TankRockTrace.FindValue(entity, TankRockTrace_t::m_iRock);
    if (index != -1)
    {
        TankRockTrace_t rockTrace;
        g_hArray_TankRockTrace.GetArray(index, rockTrace, sizeof(rockTrace));
        rockTrace.m_iDamageTaken = -1;
        g_hArray_TankRockTrace.SetArray(index, rockTrace, sizeof(rockTrace));

        SDKUnhook(entity, SDKHook_TouchPost, OnTouchPost_Rock);
    }
}

void Timer_CheckRockSkeet(Handle timer, int index)
{
    // nah it just works.
    //PrintToServer("index: %i, length: %i", index, g_hArray_TankRockTrace.Length);
    if (!g_hArray_TankRockTrace.Length)
        return;

    TankRockTrace_t rockTrace;
    g_hArray_TankRockTrace.GetArray(index, rockTrace, sizeof(rockTrace))
    g_hArray_TankRockTrace.Erase(index);

    if (rockTrace.m_iDamageTaken > 0)
        HandleRockSkeeted(rockTrace.m_iSkeeter, rockTrace.m_iThrower);
}
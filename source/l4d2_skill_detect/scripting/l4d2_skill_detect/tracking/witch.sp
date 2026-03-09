#if defined _skill_detect_tracking_witch_included
    #endinput
#endif
#define _skill_detect_tracking_witch_included

enum struct WitchTrace_t
{
    int m_iWitch;        // witch entity index
    bool m_bGotSlash;    // failed to crown a witch?
    bool m_bStartled;    // witch got startled?
}
ArrayList g_hArray_WitchTrace;


// crown tracking
void Event_WitchSpawned(Event event, const char[] name, bool dontBroadcast)
{
    int witch = event.GetInt("witchid");
    if (!IsValidEdict(witch))
        return;
    
    int index = g_hArray_WitchTrace.FindValue(witch, WitchTrace_t::m_iWitch);
    if (index == -1)
    {
        WitchTrace_t witchTrace;
        witchTrace.m_iWitch = witch;
        g_hArray_WitchTrace.PushArray(witchTrace, sizeof(witchTrace));
    }
    else
    {
        WitchTrace_t witchTrace;
        witchTrace.m_iWitch = witch;
        g_hArray_WitchTrace.SetArray(index, witchTrace, sizeof(witchTrace));
    }
}

void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
    int witch = event.GetInt("witchid");
    int attacker = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidSurvivor(attacker))
        return;

    bool bOneShot = event.GetBool("oneshot");

    // is it a crown / drawcrown?
    DataPack pack = new DataPack();
    pack.WriteCell(attacker);
    pack.WriteCell(witch);
    pack.WriteCell((bOneShot) ? 1 : 0);
    CreateTimer(WITCH_CHECK_TIME, Timer_CheckWitchCrown, pack);
}

void Event_WitchHarasserSet(Event event, const char[] name, bool dontBroadcast)
{
    int witch = event.GetInt("witchid");

    int index = g_hArray_WitchTrace.FindValue(witch, WitchTrace_t::m_iWitch);
    if (index != -1)
    {
        WitchTrace_t witchTrace;
        g_hArray_WitchTrace.GetArray(index, witchTrace, sizeof(witchTrace));
        witchTrace.m_bStartled = true;
        g_hArray_WitchTrace.SetArray(index, witchTrace, sizeof(witchTrace));
    }
}

static void Timer_CheckWitchCrown(Handle timer, DataPack pack)
{
    pack.Reset();
    int attacker = pack.ReadCell();
    int witch = pack.ReadCell();
    bool bOneShot = view_as<bool>(pack.ReadCell());
    delete pack;

    CheckWitchCrown(witch, attacker, bOneShot);
}

static void CheckWitchCrown(int witch, int attacker, bool bOneShot = false)
{
    int index = g_hArray_WitchTrace.FindValue(witch, WitchTrace_t::m_iWitch);
    if (index == -1)
        return;

    WitchTrace_t witchTrace;
    g_hArray_WitchTrace.GetArray(index, witchTrace, sizeof(witchTrace));

    // full crown? unharrassed
    if (!witchTrace.m_bStartled && bOneShot)
    {
        HandleCrown(attacker);
    }
    else
    {
        HandleDrawCrown(attacker);
    }
}

void Timer_WitchKeyDelete(Handle timer, int index)
{
    //PrintToServer("index: %i, length: %i", index, g_hArray_WitchTrace.Length);
    g_hArray_WitchTrace.Erase(index);
}

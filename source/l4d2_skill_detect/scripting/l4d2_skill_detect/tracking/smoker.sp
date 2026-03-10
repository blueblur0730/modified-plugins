#if defined _skill_detect_tracking_smoker_included
    #endinput
#endif
#define _skill_detect_tracking_smoker_included    

enum TongueReleaseType_t
{
    TONGUE_RELEASE_NONE = 0,
    TONGUE_RELEASE_SHOVED = 1,  // smoker got shoved
    TONGUE_RELEASE_FREED = 2,   // survivor got shoved.
    TONGUE_RELEASE_KILLED = 3,  // killed smoker.
    TONGUE_RELEASE_BROKE = 4,   // tongue break by gun/melee.
}

enum struct SmokerSkillCache_t
{
    // smoker clears
    IntervalTimer_t m_DragStartTimer;   // time the smoker starts to grab a target
    IntervalTimer_t m_ChokeStartTimer;  // time the smoker starts to choke a target

    void ResetSmoker()
    {
        this.m_DragStartTimer.Invalidate();
        this.m_ChokeStartTimer.Invalidate();
    }
}
SmokerSkillCache_t g_Smoker[L4D2_MAXPLAYERS + 1];

// smoker tongue cutting & self clears
void Event_TonguePullStopped(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("userid"));
    int smoker = GetClientOfUserId(event.GetInt("smoker"));
    int victim = GetClientOfUserId(event.GetInt("victim"));

    if (!IsValidSurvivor(attacker) || !IsValidInfected(smoker) || !IsValidSurvivor(victim))
        return;

    TongueReleaseType_t reason = view_as<TongueReleaseType_t>(event.GetInt("release_type"));
    int damageType = event.GetInt("damage_type");

    // self clear check.
    if (victim == attacker)
    {
        // a tongue cut.
        if (reason == TONGUE_RELEASE_BROKE && (damageType & DMG_SLASH) || (damageType & DMG_CLUB))
        {
            HandleTongueCut(attacker, smoker);
        }
        else if (reason == TONGUE_RELEASE_SHOVED)
        {
            HandleSmokerSelfClear(attacker, smoker, true);
        }
        else if (reason == TONGUE_RELEASE_KILLED)
        {
            HandleSmokerSelfClear(attacker, smoker, false);
        }
    }
    else
    {
        // clear check -  if the smoker itself was not shoved, handle the clear
        HandleClear(attacker, smoker, victim,
                    ZC_SMOKER,
                    (g_Smoker[smoker].m_ChokeStartTimer.HasStarted()) ? (g_Smoker[smoker].m_ChokeStartTimer.GetElapsedTime()) : -1.0,
                    (g_Smoker[smoker].m_DragStartTimer.GetElapsedTime()),
                    view_as<bool>(reason == TONGUE_RELEASE_SHOVED || reason == TONGUE_RELEASE_FREED));

    }
}

// tongue grab start.
void Event_TongueGrab(Event event, const char[] name, bool dontBroadcast)
{
    CheckMultiDominationTimer(true);

    int attacker = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidInfected(attacker))
        return;
    
    g_Smoker[attacker].m_DragStartTimer.Start();
}

void Event_ChokeStart(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidInfected(attacker))
        return;

    g_Smoker[attacker].m_ChokeStartTimer.Start();
}

void Event_ChokeStop(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("userid"));
    int victim = GetClientOfUserId(event.GetInt("victim"));
    int smoker = GetClientOfUserId(event.GetInt("smoker"));

    if (!IsValidSurvivor(attacker) || !IsValidInfected(smoker) || !IsValidSurvivor(victim))
        return;

    TongueReleaseType_t reason = view_as<TongueReleaseType_t>(event.GetInt("release_type"));
    // if the smoker itself was not shoved, handle the clear
    HandleClear(attacker, smoker, victim,
                ZC_SMOKER,
                (g_Smoker[smoker].m_ChokeStartTimer.HasStarted()) ? (g_Smoker[smoker].m_ChokeStartTimer.GetElapsedTime()) : -1.0,
                (g_Smoker[smoker].m_DragStartTimer.GetElapsedTime()),
                view_as<bool>(reason == TONGUE_RELEASE_FREED || reason == TONGUE_RELEASE_SHOVED));
}

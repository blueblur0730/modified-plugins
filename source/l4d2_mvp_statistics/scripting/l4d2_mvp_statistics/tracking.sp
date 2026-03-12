#if defined _l4d2_mvp_statistics_tracking_included
    #endinput
#endif
#define _l4d2_mvp_statistics_tracking_included

// Tank stats
int
    g_TotalCommonKilledDuringTank = 0,            // Common killed during the tank 
    g_iTotalKills,                                // prolly more efficient to store than to recalculate
    g_iTotalCommon,
    g_iTotalDamageAll,
    g_iTotalFF;

enum struct Statistics_t
{
    // Basic statistics
    char m_szName[64];  // which name is connected to the clientId?
    int m_iSIKills;     // SI kills             track for each client
    int m_iCIKills;     // CI kills
    int m_iSIDamage;    // SI only              these are a bit redundant, but will keep anyway for now
    int m_iAllDamage;   // SI + tank + witch
    int m_iTankDamage;  // tank only
    int m_iWitchDamage; // witch only
    int m_iFFDamage;    // friendly fire damage

    int m_iTICount;     // team incapacitation count
    int m_iTKCount;     // team kill count

    // Detailed statistics
    int m_iSIDamageClass[ZC_TANK + 1];  // si classes
    int m_iTimesPinned[ZC_TANK + 1];    // times pinned
    int m_iTotalPinned;                 // total times pinned
    int m_iBoomerPops;                  // total boomer pops
    int m_iDamageReceived;              // Damage received

    // Tank stats
    int m_iCommonKilledDuringTank;      // Common killed during the tank
    int m_iSiDmgDuringTank;             // SI killed during the tank
    int m_iTotalPinnedDuringTank;       // The total times we were pinned when the tank was up

    void Clear()
    {
        this.m_iSIKills = 0;
        this.m_iCIKills = 0;
        this.m_iSIDamage = 0;
        this.m_iAllDamage = 0;
        this.m_iTankDamage = 0;
        this.m_iWitchDamage = 0;
        this.m_iFFDamage = 0;
        this.m_iTICount = 0;
        this.m_iTKCount = 0;
        
        for (int siClass = ZC_SMOKER; siClass <= ZC_TANK; siClass++) 
        {
            this.m_iSIDamageClass[siClass] = 0;
            this.m_iTimesPinned[siClass] = 0;
        }

        this.m_iBoomerPops = 0;
        this.m_iDamageReceived = 0;
        this.m_iTotalPinned = 0;
        this.m_iCommonKilledDuringTank = 0;
        this.m_iSiDmgDuringTank = 0;
        this.m_iTotalPinnedDuringTank = 0;
    }

    void IncreaseClassPinnedTimes(int siClass)
    {
        this.m_iTimesPinned[siClass]++;
        this.m_iTotalPinned++;
        
        if (g_bTankSpawn_Evented) 
            this.m_iTotalPinnedDuringTank++;
    }
}
Statistics_t g_Statistics[L4D2_MAXPLAYERS + 1];


void ScavRoundStart_Event(Event event, const char[] name, bool dontBroadcast)
{
    // clear mvp stats
    for (int i = 1; i <= MaxClients; i++)
    {
        g_Statistics[i].Clear();
    }

    ClearGlobals();
}

void RoundStart_Event(Event event, const char[] name, bool dontBroadcast)
{
    g_bPlayerLeftStartArea = false;
    
    // clear mvp stats
    for (int i = 1; i <= MaxClients; i++)
    {
        g_Statistics[i].Clear();
    }

    ClearGlobals();

    if (g_hCvar_AdRank.BoolValue && !g_hTimer)
    {
        g_hTimer = CreateTimer(g_hCvar_AdInterval.FloatValue, Timer_AdRank, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }
}

void PlayerLeftSafeArea_Event(Event event, const char[] name, bool dontBroadcast)
{
    // if RUP active, now we can start tracking FF
    g_bPlayerLeftStartArea = true;
}

void FinaleEnd_Event(Event event, const char[] name, bool dontBroadcast)
{
    // Co-op modes.
    if (!L4D_HasPlayerControlledZombies())
    {
        if (g_bInRound)
        {
            if (g_hCvar_PluginEnabled.BoolValue)
                CreateTimer(8.0, Timer_DelayedMVPPrint);

            g_bInRound = false;
        }
    }

    // No need for versus/other modes as round_end fires just fine on them.
    g_bTankSpawn_Evented = false;
}

void RoundEnd_Event(Event event, const char[] name, bool dontBroadcast)
{
    // Co-op modes.
    if (!L4D_HasPlayerControlledZombies())
    {
        if (g_bInRound)
        {
            if (g_hCvar_PluginEnabled.BoolValue)
                CreateTimer(0.1, Timer_DelayedMVPPrint);

            g_bInRound = false;
        }
    }
    else
    {
        // Any scavenge/versus mode.
        if (g_bInRound && !StrEqual(name, "map_transition", false))
        {
            // only show / log stuff when the round is done "the first time"
            if (g_hCvar_PluginEnabled.BoolValue)
                CreateTimer(2.0, Timer_DelayedMVPPrint);

            g_bInRound = false;
        }
    }
    
    g_bTankSpawn_Evented = false;
}

void Timer_DelayedMVPPrint(Handle timer)
{
    PrintMVPString();
    CreateTimer(0.1, Timer_PrintLosers);
}

void Timer_PrintLosers(Handle timer)
{
    PrintLoserz(false, -1);
}

void ChargerCarryEnd_Event(Event event, const char[] name, bool dontBroadcast)
{
    HandleEvent(event, ZC_CHARGER);
}

void JockeyRide_Event(Event event, const char[] name, bool dontBroadcast)
{
    HandleEvent(event, ZC_JOCKEY);
}

void HunterLunged_Event(Event event, const char[] name, bool dontBroadcast)
{
    HandleEvent(event, ZC_HUNTER);
}

void SmokerChoke_Event(Event event, const char[] name, bool dontBroadcast)
{
    HandleEvent(event, ZC_SMOKER);
}

void HandleEvent(Event event, int iClass)
{
    int client = GetClientOfUserId(event.GetInt("victim")); 
    if (client == 0 || ! IsClientInGame(client))
        return;
    
    g_Statistics[client].IncreaseClassPinnedTimes(iClass);
}

void TankSpawn_Event(Event event, const char[] name, bool dontBroadcast) 
{
    g_bTankSpawn_Evented = true;
}

void TankKilled_Event(Event event, const char[] name, bool dontBroadcast) 
{
    g_bTankSpawn_Evented = false;
}

public void FFManager_OnFriendlyFire(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, float damageForce[3], float damagePosition[3])
{
    if (!g_bPlayerLeftStartArea) 
    {
        if (!g_hCvar_RecordBeforeLeave.BoolValue)
            return;
    }

    g_Statistics[attacker].m_iFFDamage += RoundToNearest(damage);
    g_iTotalFF += RoundToNearest(damage);
    g_Statistics[victim].m_iDamageReceived += RoundToNearest(damage);
}

void PlayerHurt_Event(Event event, const char[] name, bool dontBroadcast)
{
    // Victim details
    int victim = GetClientOfUserId(event.GetInt("userid"));
    
    // Attacker details
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    
    // no world damage or flukes or whatevs, no bot attackers, no infected-to-infected damage
    if (IsClientAndInGame(victim) && IsClientAndInGame(attacker))
    {
        int zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");

        // Misc details
        int damageDone = event.GetInt("dmg_health");

        // If a survivor is attacking infected
        if (GetClientTeam(attacker) == L4D2Team_Survivor && GetClientTeam(victim) == L4D2Team_Infected)
        {
            // Increment the damage for that class to the total
            g_Statistics[attacker].m_iSIDamageClass[zombieClass] += damageDone;
            //PrintToConsole(attacker, "Attacked: %d - Dmg: %d", zombieClass, damageDone);
            //PrintToConsole(attacker, "Total damage for %d: %d", zombieClass, g_iDidDamageClass[attacker][zombieClass]);
            
            // separately store SI and tank damage
            if (zombieClass >= ZC_SMOKER && zombieClass < ZC_WITCH)
            {
                // If the tank is up, let's store separately
                if (g_bTankSpawn_Evented) 
                    g_Statistics[attacker].m_iSiDmgDuringTank += damageDone;
                
                g_Statistics[attacker].m_iSIDamage += damageDone;
                g_Statistics[attacker].m_iAllDamage += damageDone;
                g_iTotalDamageAll += damageDone;
            }
            else if (zombieClass == ZC_TANK && damageDone != 5000) // For some reason the last attacker does 5k damage?
            {
                // We want to track tank damage even if we're not factoring it in to our mvp result
                g_Statistics[attacker].m_iTankDamage+= damageDone;
                
                // If we're factoring it in, include it in our overall damage
                if (g_bCountTankDamage)
                {
                    g_Statistics[attacker].m_iAllDamage += damageDone;
                    g_iTotalDamageAll += damageDone;
                }
            }
        }
    }
}

void InfectedHurt_Event(Event event, const char[] name, bool dontBroadcast)
{
    // catch damage done to witch
    int victimEntId = event.GetInt("entityid");
    if (IsWitch(victimEntId))
    {
        int attacker = GetClientOfUserId(event.GetInt("attacker"));
        int damageDone = event.GetInt("amount");
        
        // no world damage or flukes or whatevs, no bot attackers
        if (IsClientAndInGame(attacker) && GetClientTeam(attacker) == L4D2Team_Survivor)
        {
            // We want to track the witch damage regardless of whether we're counting it in our mvp stat
            g_Statistics[attacker].m_iWitchDamage += damageDone;
            //iTotalDamageWitch += damageDone;
            
            // If we're counting witch damage in our mvp stat, lets add the amount of damage done to the witch
            if (g_bCountWitchDamage) 
            {
                g_Statistics[attacker].m_iAllDamage += damageDone;
                g_iTotalDamageAll += damageDone;
            }
        }
    }
}

void PlayerDeath_Event(Event event, const char[] name, bool dontBroadcast)
{
    // Get the victim details
    int victim = GetClientOfUserId(event.GetInt("userid"));
    
    // Get the attacker details
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (attacker == victim)
		return;

    if (!IsClientAndInGame(victim) || !IsClientAndInGame(attacker))
        return;

    int zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
    if (zombieClass == ZC_TANK) 
        g_bTankSpawn_Evented = false;

    // no world kills or flukes or whatevs, no bot attackers
    if (GetClientTeam(attacker) == L4D2Team_Survivor)
    {
        // only SI, not the tank && only player-attackers
        if (zombieClass >= ZC_SMOKER && zombieClass < ZC_WITCH)
        {
            // store kill to count for attacker id
            g_Statistics[attacker].m_iSIKills++;
            g_iTotalKills++;
        }
    }

    if (GetClientTeam(victim) == L4D2Team_Survivor && GetClientTeam(attacker) == L4D2Team_Survivor)
    {
        g_Statistics[attacker].m_iTKCount++;
    }
}

void PlayerIncapacitated_Event(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if (attacker == 0)
        attacker = event.GetInt("attackerentid");
    
    if (victim <= 0 || victim > MaxClients || !IsClientInGame(victim))
        return;

    if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker))
        return;

    if (GetClientTeam(victim) != 2 || GetClientTeam(attacker) != 2)
        return;

    g_Statistics[attacker].m_iTICount++;
}

void InfectedDeath_Event(Event event, const char[] name, bool dontBroadcast)
{
    if (g_bPlayerLeftStartArea)
    {
        if (!g_hCvar_RecordBeforeLeave.BoolValue)
            return;
    }

    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    if (IsClientAndInGame(attacker) && GetClientTeam(attacker) == L4D2Team_Survivor)
    {
        // If the tank is up, let's store separately
        if (g_bTankSpawn_Evented) 
        {
            g_Statistics[attacker].m_iCommonKilledDuringTank++;
            g_TotalCommonKilledDuringTank++;
        }
        
        g_Statistics[attacker].m_iCIKills++;
        g_iTotalCommon++;
        // if victimType > 2, it's an "uncommon" (of some type or other) -- do nothing with this ftpresent.
    }
}

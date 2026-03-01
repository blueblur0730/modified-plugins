#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>
#include <l4d2util>
#include <colors>
#include <l4d2_ff_manager>

#define ZC_SMOKER				1
#define ZC_BOOMER				2
#define ZC_HUNTER				3
#define ZC_SPITTER				4
#define ZC_JOCKEY				5
#define ZC_CHARGER				6
#define ZC_WITCH				7
#define ZC_TANK					8

#define BREV_SI                 1
#define BREV_CI                 2
#define BREV_FF                 4
#define BREV_RANK               8

#define CONBUFSIZE              1024
#define CONBUFSIZELARGE         4096

#define CHARTHRESHOLD           160         // detecting unicode stuff
#define L4D2_MAXPLAYERS 32

ConVar
    g_hCvar_PluginEnabled,      // whether the plugin is enabled
    g_hCvar_CountTankDamage,    // whether we're tracking tank damage for MVP-selection
    g_hCvar_CountWitchDamage,   // whether we're tracking witch damage for MVP-selection
    g_hCvar_BrevityFlags,       // how verbose/brief the output should be:
    g_hCvar_RankOrder,          // how to arrange the MVP-list.
    g_hCvar_ListLimit,          // how many MVPs to display.

    g_hCvar_AdRank,             // ad rank for the chat.
    g_hCvar_AdInterval,         // ad interval for the chat.

    g_hCvar_RecordBeforeLeave;  // whether to record stats before leaving the safe area.

bool 
    g_bCountTankDamage,
    g_bCountWitchDamage;

int g_iBrevityFlags;

bool
    g_bTankThrow,                              // Whether or not the tank has thrown a rock
    g_bTankSpawn_Evented = false,              // When tank is spawned
    g_bInRound,
    g_bPlayerLeftStartArea;                    // used for tracking FF when RUP enabled

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
    int m_iPillsUsed;                   // total pills eaten
    int m_iBoomerPops;                  // total boomer pops
    int m_iDamageReceived;              // Damage received

    // Tank stats
    int m_iCommonKilledDuringTank;      // Common killed during the tank
    int m_iSiDmgDuringTank;             // SI killed during the tank
    int m_iRocksEaten;                  // The amount of rocks a player 'ate'.
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

        this.m_iPillsUsed = 0;
        this.m_iBoomerPops = 0;
        this.m_iDamageReceived = 0;
        this.m_iTotalPinned = 0;
        this.m_iCommonKilledDuringTank = 0;
        this.m_iSiDmgDuringTank = 0;
        this.m_iRocksEaten = 0;
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

// Tank stats
int
    g_TotalCommonKilledDuringTank = 0,            // Common killed during the tank 
    g_iRockIndex,                                 // The index of the rock (to detect how many times we were rocked)
    g_iTotalKills,                                // prolly more efficient to store than to recalculate
    g_iTotalCommon,
    g_iTotalDamageAll,
    g_iTotalFF;

#define PLUGIN_VERSION "r2.3.1"
public Plugin myinfo =
{
	name = "[L4D2] Survivor MVP Statistics",
	author = "Tabun, Artifacial, Competitive Reowrk Team, blueblur",
	description = "MVP Statistics for the Survivor team.",
	version = PLUGIN_VERSION,
	url = "https://github.com/blueblur0730/modified-plugins"
};

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int errMax)
{
    CreateNative("MVP_GetMVP", Native_GetMVP);
    CreateNative("MVP_GetMVPDmgCount", Native_GetMVPDmgCount);
    CreateNative("MVP_GetMVPKills", Native_GetMVPKills);
    CreateNative("MVP_GetMVPDmgPercent", Native_GetMVPDmgPercent);
    CreateNative("MVP_GetMVPCI", Native_GetMVPCI);
    CreateNative("MVP_GetMVPCIKills", Native_GetMVPCIKills);
    CreateNative("MVP_GetMVPCIPercent", Native_GetMVPCIPercent);
	return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslation("l4d2_mvp_statistics.phrases");

    // Round triggers
    HookEvent("finale_vehicle_leaving", FinaleEnd_Event, EventHookMode_PostNoCopy);
    HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
    HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);
    HookEvent("map_transition", RoundEnd_Event, EventHookMode_PostNoCopy);
    HookEvent("scavenge_round_start", ScavRoundStart_Event, EventHookMode_PostNoCopy);
    HookEvent("player_left_safe_area", PlayerLeftSafeArea_Event, EventHookMode_PostNoCopy);
    HookEvent("pills_used", PillsUsed_Event);
    HookEvent("boomer_exploded", BoomerExploded_Event);
    HookEvent("charger_carry_end", ChargerCarryEnd_Event);
    HookEvent("jockey_ride", JockeyRide_Event);
    HookEvent("lunge_pounce", HunterLunged_Event);
    HookEvent("choke_start", SmokerChoke_Event);
    HookEvent("tank_killed", TankKilled_Event);
    HookEvent("tank_spawn", TankSpawn_Event);
    HookEvent("ability_use", AbilityUse_Event);
    
    // Catching data
    HookEvent("player_hurt", PlayerHurt_Event, EventHookMode_Post);
    HookEvent("player_death", PlayerDeath_Event, EventHookMode_Post);
    HookEvent("player_incapacitated", PlayerIncapacitated_Event, EventHookMode_Post);
    HookEvent("infected_hurt" ,InfectedHurt_Event, EventHookMode_Post);
    HookEvent("infected_death", InfectedDeath_Event, EventHookMode_Post);
    
    // Cvars
    g_hCvar_PluginEnabled =    CreateConVar("l4d2_mvp_statistics_enabled", "1", "Enable display of MVP at end of round");
    g_hCvar_CountTankDamage =  CreateConVar("l4d2_mvp_statistics_counttank", "1", "Damage on tank counts towards MVP-selection if enabled.");
    g_hCvar_CountWitchDamage = CreateConVar("l4d2_mvp_statistics_countwitch", "1", "Damage on witch counts towards MVP-selection if enabled.");
    g_hCvar_BrevityFlags =     CreateConVar("l4d2_mvp_statistics_brevity", "15", "Flags for setting brevity of MVP report (hide 1:SI, 2:CI, 4:FF, 8:rank).");
    g_hCvar_RankOrder =        CreateConVar("l4d2_mvp_statistics_rank_order", "1", "1: SI first, 2: SI Damage First, 3: SI + CI Total Damage First.");
    g_hCvar_ListLimit =        CreateConVar("l4d2_mvp_statistics_list_limit", "4", "How many MVPs to display.");

    g_hCvar_AdRank =           CreateConVar("l4d2_mvp_statistics_ad_rank", "1", "Ad rank for the chat.");
    g_hCvar_AdInterval =       CreateConVar("l4d2_mvp_statistics_ad_interval", "80", "Ad interval for the chat.");

    g_hCvar_RecordBeforeLeave = CreateConVar("l4d2_mvp_statistics_record_before_leave", "1", "Record stats before leaving the safe area.");
    
    g_bCountTankDamage =  g_hCvar_CountTankDamage.BoolValue;
    g_bCountWitchDamage = g_hCvar_CountWitchDamage.BoolValue;
    g_iBrevityFlags =     g_hCvar_BrevityFlags.IntValue;
    
    g_hCvar_CountTankDamage.AddChangeHook(ConVarChange_CountTankDamage);
    g_hCvar_CountWitchDamage.AddChangeHook(ConVarChange_CountWitchDamage);
    g_hCvar_BrevityFlags.AddChangeHook(ConVarChange_BrevityFlags);
    
    g_bPlayerLeftStartArea = false;
    
    // Commands
    RegConsoleCmd("sm_mvp", SurvivorMVP_Cmd, "Prints the current MVP for the survivor team");
    RegConsoleCmd("sm_mvpme", ShowMVPStats_Cmd, "Prints the client's own MVP-related stats");
}

public void OnClientPutInServer(int client)
{
    char tmpBuffer[64];
    GetClientName(client, tmpBuffer, sizeof(tmpBuffer));
    
    // if previously stored name for same client is not the same, delete stats & overwrite name
    if (strcmp(tmpBuffer, g_Statistics[client].m_szName, true) != 0)
    {
        g_Statistics[client].Clear();

        // store name for later reference
        strcopy(g_Statistics[client].m_szName, sizeof(tmpBuffer), tmpBuffer);
    }
}

void ConVarChange_CountTankDamage(ConVar cvar, const char[] oldValue, const char[] newValue) 
{
    g_bCountTankDamage = StringToInt(newValue) != 0;
}

void ConVarChange_CountWitchDamage(ConVar cvar, const char[] oldValue, const char[] newValue) 
{
    g_bCountWitchDamage = StringToInt(newValue) != 0;
}

void ConVarChange_BrevityFlags(ConVar cvar, const char[] oldValue, const char[] newValue) 
{
    g_iBrevityFlags = StringToInt(newValue);
}

void PlayerLeftSafeArea_Event(Event event, const char[] name, bool dontBroadcast)
{
    // if RUP active, now we can start tracking FF
    g_bPlayerLeftStartArea = true;
}

public void OnMapStart()
{
    g_bPlayerLeftStartArea = false;
}

Handle g_hTimer = null;
public void OnMapEnd()
{
    g_bInRound = false;
    g_hTimer = null;
}

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

void ClearGlobals()
{
    g_iTotalKills = 0;
    g_iTotalCommon = 0;
    g_iTotalDamageAll = 0;
    g_iTotalFF = 0;
    g_TotalCommonKilledDuringTank = 0;
    g_bTankThrow = false;
    
    g_bInRound = true;
    g_bTankSpawn_Evented = false;
}

void Timer_AdRank(Handle timer)
{
    PrintRank();
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

Action SurvivorMVP_Cmd(int client, int args)
{
    PrintMVPString();
    PrintLoserz(true, client);
    return Plugin_Handled;
}

Action ShowMVPStats_Cmd(int client, int args)
{
    PrintLoserz(true, client);
    return Plugin_Handled;
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

void PrintLoserz(bool bSolo, int client)
{
    char tmpBuffer[1024];
    // also find the three non-mvp survivors and tell them they sucked
    // tell them they sucked with SI
    if (g_iTotalDamageAll > 0)
    {
        int mvp_SI = FindMVP(1);
        int mvp_SI_losers[3];
        mvp_SI_losers[0] = FindMVP(1, mvp_SI);                                           // second place
        mvp_SI_losers[1] = FindMVP(1, mvp_SI, mvp_SI_losers[0]);                         // third
        mvp_SI_losers[2] = FindMVP(1, mvp_SI, mvp_SI_losers[0], mvp_SI_losers[1]);       // fourth
        
        for (int i = 0; i <= 2; i++)
        {
            if (IsClientAndInGame(mvp_SI_losers[i]) && !IsFakeClient(mvp_SI_losers[i])) 
            {
                if (bSolo)
                {
                    if (mvp_SI_losers[i] == client)
                    {
                        Format(tmpBuffer, sizeof(tmpBuffer), "%T", "YourRankSI", client, (i + 2), g_Statistics[mvp_SI_losers[i]].m_iAllDamage, (float(g_Statistics[mvp_SI_losers[i]].m_iAllDamage) / float(g_iTotalDamageAll)) * 100, g_Statistics[mvp_SI_losers[i]].m_iSIKills, (float(g_Statistics[mvp_SI_losers[i]].m_iSIKills) / float(g_iTotalKills)) * 100);
                        CPrintToChat(mvp_SI_losers[i], "%s", tmpBuffer);
                    }
                }
                else 
                {
                    Format(tmpBuffer, sizeof(tmpBuffer), "%T", "YourRankSI", mvp_SI_losers[i], (i + 2), g_Statistics[mvp_SI_losers[i]].m_iAllDamage, (float(g_Statistics[mvp_SI_losers[i]].m_iAllDamage) / float(g_iTotalDamageAll)) * 100, g_Statistics[mvp_SI_losers[i]].m_iSIKills, (float(g_Statistics[mvp_SI_losers[i]].m_iSIKills) / float(g_iTotalKills)) * 100);
                    CPrintToChat(mvp_SI_losers[i], "%s", tmpBuffer);
                }
            }
        }
    }
    
    // tell them they sucked with Common
    if (g_iTotalCommon > 0)
    {
        int mvp_CI = FindMVP(2);
        int mvp_CI_losers[3];
        mvp_CI_losers[0] = FindMVP(2, mvp_CI);                                           // second place
        mvp_CI_losers[1] = FindMVP(2, mvp_CI, mvp_CI_losers[0]);                         // third
        mvp_CI_losers[2] = FindMVP(2, mvp_CI, mvp_CI_losers[0], mvp_CI_losers[1]);       // fourth
        
        for (int i = 0; i <= 2; i++)
        {
            if (IsClientAndInGame(mvp_CI_losers[i]) && !IsFakeClient(mvp_CI_losers[i])) 
            {
                if (bSolo)
                {
                    if (mvp_CI_losers[i] == client)
                    {
                        Format(tmpBuffer, sizeof(tmpBuffer), "%T", "YourRankCI", client, (i + 2), g_Statistics[mvp_CI_losers[i]].m_iCIKills, (float(g_Statistics[mvp_CI_losers[i]].m_iCIKills) / float(g_iTotalCommon)) * 100);
                        CPrintToChat(mvp_CI_losers[i], "%s", tmpBuffer);
                    }
                }
                else
                {
                    Format(tmpBuffer, sizeof(tmpBuffer), "%T", "YourRankCI", mvp_CI_losers[i], (i + 2), g_Statistics[mvp_CI_losers[i]].m_iCIKills, (float(g_Statistics[mvp_CI_losers[i]].m_iCIKills) / float(g_iTotalCommon)) * 100);
                    CPrintToChat(mvp_CI_losers[i], "%s", tmpBuffer);
                }
            }
        }
    }
    
    // tell them they were better with FF (I know, I know, losers = winners)
    if (g_iTotalFF > 0)
    {
        int mvp_FF = FindMVP(3);
        int mvp_FF_losers[3];
        mvp_FF_losers[0] = FindMVP(3, mvp_FF);                                           // second place
        mvp_FF_losers[1] = FindMVP(3, mvp_FF, mvp_FF_losers[0]);                         // third
        mvp_FF_losers[2] = FindMVP(3, mvp_FF, mvp_FF_losers[0], mvp_FF_losers[1]);       // fourth
        
        for (int i = 0; i <= 2; i++)
        {
            if (IsClientAndInGame(mvp_FF_losers[i]) &&  !IsFakeClient(mvp_FF_losers[i])) 
            {
                if (bSolo)
                {
                    if (mvp_FF_losers[i] == client)
                    {
                        Format(tmpBuffer, sizeof(tmpBuffer), "%T", "YourRankFF", client, (i + 2), g_Statistics[mvp_FF_losers[i]].m_iFFDamage, (float(g_Statistics[mvp_FF_losers[i]].m_iFFDamage) / float(g_iTotalFF)) * 100);
                        CPrintToChat(mvp_FF_losers[i], "%s", tmpBuffer);
                    }
                }
                else
                {
                    Format(tmpBuffer, sizeof(tmpBuffer), "%T", "YourRankFF", mvp_FF_losers[i], (i + 2), g_Statistics[mvp_FF_losers[i]].m_iFFDamage, (float(g_Statistics[mvp_FF_losers[i]].m_iFFDamage) / float(g_iTotalFF)) * 100);
                    CPrintToChat(mvp_FF_losers[i], "%s", tmpBuffer);
                }
            }
        }
    }    
}

public void OnEntityCreated(int entity, const char[] classname)
{ 
    if (!g_bTankThrow)
        return;
    
    if (StrEqual(classname, "tank_rock", true))
    {
        g_iRockIndex = entity;
        g_bTankThrow = true;
    }
}

public void OnEntityDestroyed(int entity)
{   
    // The rock has been destroyed
    if (g_iRockIndex == entity) 
        g_bTankThrow = false;
}

void AbilityUse_Event(Event event, const char[] name, bool dontBroadcast)
{
    char ability[32];
    event.GetString("ability", ability, sizeof(ability));
    
    // If tank is throwing a rock
    if (StrEqual(ability, "ability_throw", true))
        g_bTankThrow = true;
}

void PillsUsed_Event(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid")); 
    if (client == 0 || ! IsClientInGame(client)) 
        return;
    
    g_Statistics[client].m_iPillsUsed++;
}

void BoomerExploded_Event(Event event, const char[] name, bool dontBroadcast)
{
    // We only want to track pops where the boomer didn't bile anyone
    bool biled = event.GetBool("splashedbile");
    if (!biled) 
    {
        int attacker = GetClientOfUserId(event.GetInt("attacker"));
        if (attacker == 0 || ! IsClientInGame(attacker)) 
            return;

        g_Statistics[attacker].m_iBoomerPops++;
    }
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
        // Otherwise if infected are inflicting damage on a survivor
        else if (GetClientTeam(attacker) == L4D2Team_Infected && GetClientTeam(victim) == L4D2Team_Survivor) 
        {
            // If we got hit by a tank, let's see what type of damage it was
            // If it was from a rock throw
            if (g_bTankThrow && zombieClass == ZC_TANK) 
                g_Statistics[victim].m_iRocksEaten++;

            g_Statistics[victim].m_iDamageReceived += damageDone;
        }
    }
}

/** 
* When the infected are hurt (i.e. when a survivor hurts an SI)
* We want to use this to track damage done to the witch.
*/
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

void PrintMVPString()
{
    if (g_iBrevityFlags & BREV_RANK)
        PrintRank();

    char mvp_SI_name[64], mvp_Common_name[64], mvp_FF_name[64];
    int mvp_SI, mvp_Common,  mvp_FF = 0;
    bool bSI_bot, bCI_bot, bFF_bot = false;

    if (g_iBrevityFlags & BREV_SI)
        FindMVPName(1, mvp_SI_name, sizeof(mvp_SI_name), mvp_SI, bSI_bot);
    
    if (g_iBrevityFlags & BREV_CI)
        FindMVPName(2, mvp_Common_name, sizeof(mvp_Common_name), mvp_Common, bCI_bot);
    
    if (g_iBrevityFlags & BREV_FF)
        FindMVPName(3, mvp_FF_name, sizeof(mvp_FF_name), mvp_FF, bFF_bot);
    
    // report
    if (mvp_SI == 0 && mvp_Common == 0 && ((g_iBrevityFlags & BREV_SI) && (g_iBrevityFlags & BREV_CI)))
    {
        CPrintToChatAll("%t", "NotEnoughAction");
    }
    else
    {
        if (g_iBrevityFlags & BREV_SI)
        {
            if (mvp_SI > 0)
            {
                CPrintToChatAll("%t", "MVP_SI", bSI_bot ? "[BOT]" : mvp_SI_name, 
                                                g_Statistics[mvp_SI].m_iAllDamage, 
                                                (float(g_Statistics[mvp_SI].m_iAllDamage) / float(g_iTotalDamageAll)) * 100, 
                                                g_Statistics[mvp_SI].m_iSIKills, 
                                                (float(g_Statistics[mvp_SI].m_iSIKills) / float(g_iTotalKills)) * 100);
            }
            else
            {
                CPrintToChatAll("%t", "MVP_SI_Nobody");
            }
        }
        
        if (g_iBrevityFlags & BREV_CI)
        {
            if (mvp_Common > 0)
            {
                CPrintToChatAll("%t", "MVP_CI", bCI_bot ? "[BOT]" : mvp_Common_name, 
                                                g_Statistics[mvp_Common].m_iCIKills, 
                                                (float(g_Statistics[mvp_Common].m_iCIKills) / float(g_iTotalCommon)) * 100);
            }
            else
            {
                CPrintToChatAll("%t", "MVP_CI_Nobody");
            }
        }
    }
    
    // FF
    if ((g_iBrevityFlags & BREV_FF))
    {
        if (mvp_FF == 0)
        {
            CPrintToChatAll("%t", "LVP_FF_Nobody");
        }
        else
        {
            CPrintToChatAll("%t", "LVP_FF", bFF_bot ? "[BOT]" : mvp_FF_name, 
                                            g_Statistics[mvp_FF].m_iFFDamage, 
                                            (float(g_Statistics[mvp_FF].m_iFFDamage) / float(g_iTotalFF)) * 100,
                                            g_Statistics[mvp_FF].m_iTICount, 
                                            g_Statistics[mvp_FF].m_iTKCount);
        }
    }
}

enum struct DataSet_t
{
    int index;
    int data;
}

void PrintRank()
{
    switch (g_hCvar_RankOrder.IntValue)
    {
        case 1:
        {
            ArrayList hArray = new ArrayList(sizeof(DataSet_t));
            for (int i = 1; i < L4D2_MAXPLAYERS; i++)
            {
                DataSet_t data;
                data.index = i;
                data.data = g_Statistics[i - 1].m_iSIKills;
                hArray.PushArray(data, sizeof(data));
            }

            hArray.SortCustom(ArraySortFunc);
            for (int i = 0; i < hArray.Length; i++)
            {
                if (i == g_hCvar_ListLimit.IntValue)
                    break;

                DataSet_t data;
                hArray.GetArray(i, data, sizeof(data));
                int client = data.index;
                if (client <= 0 || client > MaxClients || !IsClientInGame(client))
                    continue;

                if (GetClientTeam(client) != L4D2Team_Survivor)
                    continue;

                CPrintToChatAll("%t", "RankMessage", i + 1, g_Statistics[client].m_szName, 
                                                            g_Statistics[client].m_iSIKills, 
                                                            g_Statistics[client].m_iSIDamage, 
                                                            g_Statistics[client].m_iCIKills, 
                                                            g_Statistics[client].m_iFFDamage, 
                                                            g_Statistics[client].m_iAllDamage, 
                                                            g_Statistics[client].m_iTICount, 
                                                            g_Statistics[client].m_iTKCount);  
            }

            delete hArray;
        }

        case 2:
        {
            ArrayList hArray = new ArrayList(sizeof(DataSet_t));
            for (int i = 1; i < L4D2_MAXPLAYERS; i++)
            {
                DataSet_t data;
                data.index = i;
                data.data = g_Statistics[i - 1].m_iSIDamage;
                hArray.PushArray(data, sizeof(data));
            }

            hArray.SortCustom(ArraySortFunc);
            for (int i = 0; i < hArray.Length; i++)
            {
                if (i == g_hCvar_ListLimit.IntValue)
                    break;

                DataSet_t data;
                hArray.GetArray(i, data, sizeof(data));
                int client = data.index;
                if (client <= 0 || client > MaxClients || !IsClientInGame(client))
                    continue;

                if (GetClientTeam(client) != L4D2Team_Survivor)
                    continue;

                CPrintToChatAll("%t", "RankMessage", i + 1, g_Statistics[client].m_szName, 
                                                            g_Statistics[client].m_iSIKills, 
                                                            g_Statistics[client].m_iSIDamage, 
                                                            g_Statistics[client].m_iCIKills, 
                                                            g_Statistics[client].m_iFFDamage, 
                                                            g_Statistics[client].m_iAllDamage, 
                                                            g_Statistics[client].m_iTICount, 
                                                            g_Statistics[client].m_iTKCount);  
            }

            delete hArray;
        }

        case 3:
        {
            ArrayList hArray = new ArrayList(sizeof(DataSet_t));
            for (int i = 1; i < L4D2_MAXPLAYERS; i++)
            {
                DataSet_t data;
                data.index = i;
                data.data = g_Statistics[i - 1].m_iAllDamage;
                hArray.PushArray(data, sizeof(data));
            }

            hArray.SortCustom(ArraySortFunc);
            for (int i = 0; i < hArray.Length; i++)
            {
                if (i == g_hCvar_ListLimit.IntValue)
                    break;

                DataSet_t data;
                hArray.GetArray(i, data, sizeof(data));
                int client = data.index;
                if (client <= 0 || client > MaxClients || !IsClientInGame(client))
                    continue;

                if (GetClientTeam(client) != L4D2Team_Survivor)
                    continue;

                CPrintToChatAll("%t", "RankMessage_TotalOrder", i + 1, g_Statistics[client].m_szName, 
                                                                        g_Statistics[client].m_iAllDamage, 
                                                                        g_Statistics[client].m_iSIKills, 
                                                                        g_Statistics[client].m_iSIDamage, 
                                                                        g_Statistics[client].m_iCIKills, 
                                                                        g_Statistics[client].m_iFFDamage, 
                                                                        g_Statistics[client].m_iTICount, 
                                                                        g_Statistics[client].m_iTKCount);  
            }

            delete hArray;
        }
    }
}

int ArraySortFunc(int index1, int index2, ArrayList array, Handle hndl)
{
    DataSet_t data1, data2;
    array.GetArray(index1, data1, sizeof(data1));
    array.GetArray(index2, data2, sizeof(data2));

    if (data1.data < data2.data)
    {
        return 1;
    }
    else if (data1.data > data2.data)
    {
        return -1;
    }
    else
    {
        return 0;
    }
}

void FindMVPName(int type, char[] name, int maxlen, int &mvp, bool &bBot)
{
    mvp = FindMVP(type);
    if (mvp > 0)
    {
        if (IsClientConnected(mvp))
        {
            GetClientName(mvp, name, maxlen);
            if (IsFakeClient(mvp))
                bBot = true;
        } 
        else
        {
            strcopy(name, maxlen, g_Statistics[mvp].m_szName);
        }
    } 
}

int FindMVP(int type, int excludeMeA = 0, int excludeMeB = 0, int excludeMeC = 0)
{
    int i, maxIndex = 0;
    switch (type)
    {
        case 1:
        {
            for (i = 0; i < L4D2_MAXPLAYERS; i++)
            {
                if (g_Statistics[i].m_iAllDamage > g_Statistics[maxIndex].m_iAllDamage  && i != excludeMeA && i != excludeMeB && i != excludeMeC)
                    maxIndex = i;
            }
        }

        case 2:
        {
            for (i = 0; i < L4D2_MAXPLAYERS; i++)
            {
                if (g_Statistics[i].m_iCIKills > g_Statistics[maxIndex].m_iCIKills && i != excludeMeA && i != excludeMeB && i != excludeMeC)
                    maxIndex = i;
            }
        }

        case 3:
        {
            for (i = 0; i < L4D2_MAXPLAYERS; i++)
            {
                if (g_Statistics[i].m_iFFDamage > g_Statistics[maxIndex].m_iFFDamage && i != excludeMeA && i != excludeMeB && i != excludeMeC)
                    maxIndex = i;
            }
        }
    }

    return maxIndex;
}

stock int getSurvivor(int exclude[4])
{
    for (int i = 1; i <= MaxClients; i++) 
    {
        if (IsSurvivor(i)) 
        {
            int tagged = false;
            // exclude already tagged survs
            for (int j = 0; j < 4; j++) 
            {
                if (exclude[j] == i) 
                    tagged = true;
            }

            if (!tagged)
                return i;
        }
    }

    return 0;
}

stock void LoadTranslation(const char[] translation)
{
	char sPath[PLATFORM_MAX_PATH], sName[PLATFORM_MAX_PATH];
	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}

stock bool IsClientAndInGame(int index)
{
    return (index > 0 && index <= MaxClients && IsClientInGame(index));
}

stock bool IsWitch(int iEntity)
{
	if (iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		char strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "witch");
	}
	return false;
}

// simply return current round MVP client
int Native_GetMVP(Handle plugin, int numParams)
{
    return FindMVP(1);
}

// return damage percent of client
any Native_GetMVPDmgPercent(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    float dmgprc = (client && g_iTotalDamageAll > 0 ? (float(g_Statistics[client].m_iAllDamage) / float(g_iTotalDamageAll)) * 100 : 0.0);
    return dmgprc;
}

// return damage of client
int Native_GetMVPDmgCount(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int dmg = (client && g_iTotalDamageAll > 0 ? g_Statistics[client].m_iAllDamage : 0);
    return dmg;
}

// return SI kills of client
int Native_GetMVPKills(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int dmg = (client && g_iTotalKills > 0 ? g_Statistics[client].m_iSIKills : 0);
    return dmg;
}

// simply return current round MVP client (Common)
int Native_GetMVPCI(Handle plugin, int numParams)
{
    return FindMVP(2);
}

// return common kills for client
int Native_GetMVPCIKills(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int dmg = (client && g_iTotalCommon > 0 ? g_Statistics[client].m_iCIKills : 0);
    return dmg;
}

// return CI percent of client
any Native_GetMVPCIPercent(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    float dmgprc = (client && g_iTotalCommon > 0 ? (float(g_Statistics[client].m_iCIKills) / float(g_iTotalCommon)) * 100 : 0.0);
    return dmgprc;
}

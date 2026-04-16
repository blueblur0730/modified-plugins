#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

// Bit flags to enable individual features of the plugin
#define FLAG_POUNCING_AI_HUNTER   (1 << 0)
#define FLAG_NERF_AI_CHARGER      (1 << 1)
#define FLAG_LEAPPING_JOCKEY      (1 << 2)

#define L4D2_MAXPLAYERS 32

bool bLateLoad = false;
int g_iHunterSkeetDamage[L4D2_MAXPLAYERS + 1] = { 0, ... };           // How much damage done in a single hunter leap so far
int g_iJockeySkeetDamage[L4D2_MAXPLAYERS + 1] = { 0, ... };           // How much damage done in a single jockey leap so far

ConVar g_hCvar_PounceInterrupt;
int g_iPounceInterrupt = 150;

ConVar g_hCvar_PounceInterrupt_Default;
int g_iPounceInterrupt_Default = 150;

ConVar g_hCvar_Enabled;
int g_iEnabled = 0;

ConVar g_hCvar_LeapingInterrupt;
int g_iLeapingInterrupt = 250;

#define PLUGIN_VERSION "r1.0.1"
public Plugin myinfo =
{
    name = "[L4D2] SI Damage Adjustment",
    author = "Tabun, dcx2, blueblur",
    description = "Mechanicsim adjustments for SI.",
    version = PLUGIN_VERSION,
    url = "https://github.com/blueblur0730/modified-plugins"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    bLateLoad = late;
    RegPluginLibrary("l4d2_si_damage_adjustment");
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_hCvar_PounceInterrupt = CreateConVar("l4d2_si_damage_adjustment_pounce_damage_interrupt", "150", "Skeet threshold for AI hunters.", _, true, 0.0);
    g_iPounceInterrupt = g_hCvar_PounceInterrupt.IntValue;

    g_hCvar_PounceInterrupt_Default = FindConVar("z_pounce_damage_interrupt");
    g_iPounceInterrupt_Default = g_hCvar_PounceInterrupt_Default.IntValue;

    g_hCvar_Enabled = CreateConVar("l4d2_si_damage_adjustment_enable", "7", "Bit flag: Enables plugin features (add together): 1=Skeet pouncing AI hunter, 2=Debuff charging AI charger, 4=Skeet leapping jockey, 0=off", _, true, 0.0, true, 3.0);
    g_iEnabled = g_hCvar_Enabled.IntValue;

    g_hCvar_LeapingInterrupt = CreateConVar("l4d2_si_damage_adjustment_leap_damage_interrupt", "250", "Skeet threshold for AI jockeys.", _, true, 0.0);
    g_iLeapingInterrupt = g_hCvar_LeapingInterrupt.IntValue;

    g_hCvar_PounceInterrupt.AddChangeHook(OnConVarChanged);
    g_hCvar_PounceInterrupt_Default.AddChangeHook(OnConVarChanged);
    g_hCvar_Enabled.AddChangeHook(OnConVarChanged);
    g_hCvar_LeapingInterrupt.AddChangeHook(OnConVarChanged);

    // events
    HookEvent("ability_use", Event_AbilityUse, EventHookMode_Post);
    
    // hook when loading late
    if (bLateLoad) 
    {
        for (int i = 1; i <= MaxClients; i++) 
        {
            if (IsClientInGame(i)) 
                OnClientPutInServer(i);
        }
    }
}

public void OnClientPutInServer(int client)
{
    // hook bots spawning
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    g_iHunterSkeetDamage[client] = 0;
    g_iJockeySkeetDamage[client] = 0;  
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!g_iEnabled)
        return Plugin_Continue;

    if (victim <= 0 || victim > MaxClients || attacker <= 0 || attacker > MaxClients)
        return Plugin_Continue;

    if (!IsClientInGame(victim) || !IsClientInGame(attacker))
        return Plugin_Continue;

    if (GetClientTeam(victim) != 3 || GetClientTeam(attacker) != 2)
        return Plugin_Continue;

    int zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");

    switch (zombieClass)
    {
        case L4D2ZombieClass_Hunter:
        {
            // only for coop ai hunters.
            // for versus, obey the game rules.
            if (g_iEnabled & FLAG_POUNCING_AI_HUNTER)
            {
                if (!IsFakeClient(victim))
                    return Plugin_Continue;

                if (!GetEntProp(victim, Prop_Send, "m_isAttemptingToPounce"))
                    return Plugin_Continue;
                
                g_iHunterSkeetDamage[victim] += RoundToFloor(damage);
                
                // have we skeeted it?
                if (g_iHunterSkeetDamage[victim] >= (L4D_HasPlayerControlledZombies() ? g_iPounceInterrupt_Default : g_iPounceInterrupt))
                {
                    // Skeet the hunter
                    g_iHunterSkeetDamage[victim] = 0;
                    damage = float(GetClientHealth(victim));
                    return Plugin_Changed;
                }
            }
        }

        case L4D2ZombieClass_Charger:
        {
            if (g_iEnabled & FLAG_NERF_AI_CHARGER)
            {
                if (!IsFakeClient(victim))
                    return Plugin_Continue;

                // Is this AI charger charging?
                int abilityEnt = GetEntPropEnt(victim, Prop_Send, "m_customAbility");
                if (IsValidEntity(abilityEnt) && GetEntProp(abilityEnt, Prop_Send, "m_isCharging") > 0)
                {
                    // Game does Floor(Floor(damage) / 3 - 1) to charging AI chargers, so multiply Floor(damage)+1 by 3
                    damage = (damage - FloatFraction(damage) + 1.0) * 3.0;
                    return Plugin_Changed;
                }
            }
        }

        case L4D2ZombieClass_Jockey:
        {
            if (g_iEnabled & FLAG_LEAPPING_JOCKEY)
            {
                int abilityEnt = GetEntPropEnt(victim, Prop_Send, "m_customAbility");
                if (!IsValidEntity(abilityEnt))
                    return Plugin_Continue;

                if (GetEntProp(abilityEnt, Prop_Send, "m_isLeaping") == 0)
                    return Plugin_Continue;

                g_iJockeySkeetDamage[victim] += RoundToFloor(damage);
                if (g_iJockeySkeetDamage[victim] >= g_iLeapingInterrupt)
                {
                    g_iJockeySkeetDamage[victim] = 0;
                    damage = float(GetClientHealth(victim));
                    return Plugin_Changed;
                }
            }
        }
    }
    
    return Plugin_Continue;
}

// hunters pouncing / tracking
void Event_AbilityUse(Event event, const char[] name, bool dontBroadcast)
{
    // track hunters pouncing
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if (client <= 0 || client > MaxClients)
        return;

    if (!IsClientInGame(client) || GetClientTeam(client) != 3)
        return;
    
    char abilityName[64];
    event.GetString("ability", abilityName, sizeof(abilityName));
    
    if (strcmp(abilityName, "ability_lunge", false) == 0)
    {
        // Clear skeet tracking damage each time the hunter starts a pounce
        g_iHunterSkeetDamage[client] = 0;
    }

    if (strcmp(abilityName, "ability_leap", false) == 0)
    {
        g_iJockeySkeetDamage[client] = 0;
    }
}

void OnConVarChanged(ConVar convar, const char[] oldvalue, const char[] newvalue)
{
    g_iPounceInterrupt = g_hCvar_PounceInterrupt.IntValue;
    g_iPounceInterrupt_Default = g_hCvar_PounceInterrupt_Default.IntValue;
    g_iEnabled = g_hCvar_Enabled.IntValue;
    g_iLeapingInterrupt = g_hCvar_LeapingInterrupt.IntValue;
}
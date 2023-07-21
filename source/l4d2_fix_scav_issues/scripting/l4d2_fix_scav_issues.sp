#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <scavenge_func>

float   g_fMapStartTime;

ConVar
    g_hGamemode,
    g_hRoundLimits,
    g_secret,
    g_hscav_rounds;

public Plugin myinfo =
{
	name = "[L4D2] Fix Scavenge Issues",
	author = "Eyal282, blueblur",
	description = "Fix bug when first round start there are no gascans and set the round number",
	version = "1.3",
	url = "https://github.com/blueblur0730/modified-plugins/tree/main/source/l4d2_fix_scav_issues"
}

public void OnPluginStart()
{
    // ConVars
    g_hGamemode                     = FindConVar("mp_gamemode");
    g_hRoundLimits                  = FindConVar("mp_roundlimit");
    g_secret                        = CreateConVar("l4d2_allow_enrich_gascan", "0", "Allow Enriching Gascan", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hscav_rounds	                = CreateConVar("l4d2_scavenge_rounds", "5", "Set the number of rounds", FCVAR_NOTIFY, true, 1.0, true, 5.0);

    // Hook
    HookEvent("scavenge_round_start", Event_ScavRoundStart, EventHookMode_PostNoCopy);

    RegAdminCmd("sm_enrichgascan", SpawnGasCan, ADMFLAG_SLAY, "enrich gas cans. warning! ues it fun and carefull!!");
}

public void OnMapStart()
{
    g_fMapStartTime = GetGameTime();
    g_hRoundLimits.SetInt(g_hscav_rounds.IntValue);
    CreateTimer(1.0, Timer_Fix, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}


public void Event_ScavRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    // when round starts and the round number is the first round (round 1), sets the round limit.
    int round = GetScavengeRoundNumber();
    if(round == 1)
    {
        SetScavengeRoundLimit(g_hscav_rounds.IntValue);
    }
}

public Action Timer_Fix(Handle hTimer)
{
    char sValue[32];
    g_hGamemode.GetString(sValue, sizeof(sValue));

    if(StrEqual(sValue, "scavenge") && GetGameTime() - g_fMapStartTime > 5.0 &&  GetScavengeItemsRemaining() == 0 && GetScavengeItemsGoal() == 0 && GetGasCanCount() == 0)
    {
        L4D2_SpawnAllScavengeItems();
    }

    return Plugin_Handled;
}

public Action SpawnGasCan(int client, int args)
{
    if(g_secret.IntValue == 1)
    {
        L4D2_SpawnAllScavengeItems();
    }
    else
    {
        ReplyToCommand(client, "Please turn on the convar before using.");
    }
    return Plugin_Handled;
}
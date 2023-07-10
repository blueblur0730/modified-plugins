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
    l4d2_scavenge_rounds;

public Plugin myinfo =
{
	name = "[L4D2] Fix Scavenge Issues",
	author = "Eyal282",
	description = "Fix bug when first round start there are no gascans and set the round number",
	version = "1.1",
	url = "https://github.com/blueblur0730/modified-plugins/tree/main/source/l4d2_fix_scav_issues"
}

public void OnPluginStart()
{
    // ConVars
    g_hGamemode                 = FindConVar("mp_gamemode");
    l4d2_scavenge_rounds	    = CreateConVar("l4d2_scavenge_rounds", "5", "Set the number of rounds", FCVAR_NOTIFY, true, 1.0, true, 5.0);

    // Hook
    HookEvent("scavenge_round_start", Event_ScavRoundStart, EventHookMode_PostNoCopy);
}

public void OnMapStart()
{
    g_fMapStartTime = GetGameTime();
    CreateTimer(1.0, Timer_Fix, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public void Event_ScavRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    // when round starts and the round number is the first round (round 1), sets the round limit.
    int round = GetScavengeRoundNumber();
    if(round == 1)
    {
        SetScavengeRoundLimit(l4d2_scavenge_rounds.IntValue);
    }
}

public Action Timer_Fix(Handle hTimer)
{
    char sValue[32];
    g_hGamemode.GetString(sValue, sizeof(sValue));

    if(StrEqual(sValue, "scavenge") && GetScavengeRoundNumber() == 1 && GetGameTime() - g_fMapStartTime > 5.0 &&  GetScavengeItemsRemaining() == 0 && GetScavengeItemsGoal() == 0 && GetGasCanCount() == 0)
    {
        Scavenge_FixNoGascanSpawnBug();
    }

    return Plugin_Handled;
}

stock void Scavenge_FixNoGascanSpawnBug()
{   
    char sSignature[128];
    sSignature = "@_ZN9CDirector21SpawnAllScavengeItemsEv";
   
	Handle Call = INVALID_HANDLE;
	if (Call == INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Raw);
		if (!PrepSDKCall_SetSignature(SDKLibrary_Server, sSignature, strlen(sSignature)-1))
		{
			return;
		}

		Call = EndPrepSDKCall();
		if (Call == INVALID_HANDLE)
		{
			return;
		}
	}

	SDKCall(Call, L4D_GetPointer(POINTER_DIRECTOR));
}
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
    g_hPrintDebug,
    l4d2_scavenge_rounds;

public Plugin myinfo =
{
	name = "[L4D2] Fix Scavenge Issues",
	author = "Eyal282, Lechuga16, blueblur",
	description = "Fix bug when first round start there are no gascans and set the round number, finally restart the round after a match finished.",
	version = "1.1",
	url = "https://github.com/blueblur0730/modified-plugins/tree/main/source/l4d2_fix_scav_issues"
}

public void OnPluginStart()
{
    // ConVars
    g_hGamemode                 = FindConVar("mp_gamemode");
    g_hPrintDebug               = CreateConVar("l4d2_fix_scav_debug", "1", _, FCVAR_NOTIFY, true, 1.0, true, 5.0);
    l4d2_scavenge_rounds	    = CreateConVar("l4d2_scavenge_rounds", "5", "Set the number of rounds", FCVAR_NOTIFY, true, 1.0, true, 5.0);

    // Hook
    HookEvent("scavenge_round_start", Event_ScavRoundStart, EventHookMode_PostNoCopy);
    HookEvent("scavenge_round_finished", Event_ScavRoundFinished, EventHookMode_PostNoCopy);
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

public void Event_ScavRoundFinished(Event event, const char[] name, bool dontBroadcast)
{
    // when round ends, check both team's match score
    CreateTimer(3.0, CheckTeamMatchScore);
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

// fix when a team reached team score 3 but the round doesn't restart.
Action CheckTeamMatchScore(Handle Timer)
{
    switch (l4d2_scavenge_rounds.IntValue)
    {
        // when a team reached the match score which declares they are the winner, restart rounds.
        case 1:
        {
            if(GetScavengeMatchScore(2) == 1)
            {
                CreateTimer(3.0, RestartRound);
            }

            if(GetScavengeMatchScore(3) == 1)
            {
                CreateTimer(3.0, RestartRound);
            }  
        }

        case 3:
        {
            if(GetScavengeMatchScore(2) == 2)
            {
                CreateTimer(3.0, RestartRound);
            }

            if(GetScavengeMatchScore(3) == 2)
            {
                CreateTimer(3.0, RestartRound);
            }  
        }

        case 5:
        {
            if(GetConVarBool(g_hPrintDebug))
            {
                int score = GetScavengeMatchScore(2);
                PrintToChatAll("Survivor match score: %d", score);
            }
            if(GetScavengeMatchScore(2) == 3)
            {
                CreateTimer(3.0, RestartRound);
                if(GetConVarBool(g_hPrintDebug))
                {
                    PrintToChatAll("Starting round");
                }
            }

            if(GetConVarBool(g_hPrintDebug))
            {
                int score = GetScavengeMatchScore(3);
                PrintToChatAll("Infected match score: %d", score);
            }
            if(GetScavengeMatchScore(3) == 3)
            {
                CreateTimer(3.0, RestartRound);
                if(GetConVarBool(g_hPrintDebug))
                {
                    PrintToChatAll("Starting round");
                }
            }  
        }
    }
    return Plugin_Continue;
}

// credit to Lechuga16 from plugin 'readyup_scav'
public Action RestartRound(Handle Timer)
{
    StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(LoadGameConfigFile("left4dhooks.l4d2"), SDKConf_Signature, "CTerrorGameRules_ResetRoundNumber");
	Handle func = EndPrepSDKCall();
	if (func == INVALID_HANDLE)
	{
		ThrowError("Failed to end prep sdk call");
	}
	SDKCall(func);
	CloseHandle(func);

    char currentmap[128];
	GetCurrentMap(currentmap, sizeof(currentmap));
	
	Call_StartForward(CreateGlobalForward("OnReadyRoundRestarted", ET_Event));
	Call_Finish();
	
    // resets the round.
	L4D_RestartScenarioFromVote(currentmap);

    return Plugin_Handled;
}
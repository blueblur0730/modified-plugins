#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

float   g_fMapStartTime;

ConVar  
    g_hGamemode,
    l4d2_scavenge_rounds;

public Plugin myinfo =
{
	name = "[L4D2] Fix Scavenge No Gascan First Round",
	author = "Eyal282, modified by blueblur",
	description = "Fix bug when first round start there are no gascans and set the round number.",
	version = "1.1",
	url = "https://github.com/blueblur0730/modified-plugins/tree/main/source/l4d2_fix_scav_no_gascan_firstround"
}

public void OnPluginStart()
{
    g_hGamemode             = FindConVar("mp_gamemode");
    l4d2_scavenge_rounds	    = CreateConVar("l4d2_scavenge_rounds", "5", "Set the number of rounds", FCVAR_NOTIFY, true, 1.0, true, 5.0);
}

public void OnMapStart()
{
    g_fMapStartTime = GetGameTime();
    GameRules_SetProp("m_nRoundLimit", l4d2_scavenge_rounds.IntValue);
    CreateTimer(1.0, Timer_Fix, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public Action Timer_Fix(Handle hTimer)
{
    char sValue[32];
    g_hGamemode.GetString(sValue, sizeof(sValue));

    if(StrEqual(sValue, "scavenge") && GetGameTime() - g_fMapStartTime > 5.0 && GameRules_GetProp("m_nScavengeItemsRemaining") == 0 && GameRules_GetProp("m_nScavengeItemsGoal") == 0 && GetGasCanCount() == 0)
    {
        Scavenge_FixNoGascanSpawnBug();
    }

    return Plugin_Handled;
}

stock int GetGasCanCount()
{
    int count;
    int entCount = GetEntityCount();

    for(int ent=MaxClients+1;ent < entCount;ent++)
    {
        if(!IsValidEdict(ent))
            continue;

        char sClassname[64];
        GetEdictClassname(ent, sClassname, sizeof(sClassname));

        if(StrEqual(sClassname, "weapon_gascan") || StrEqual(sClassname, "weapon_gascan_spawn"))
            count++;
    }

    return count;
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
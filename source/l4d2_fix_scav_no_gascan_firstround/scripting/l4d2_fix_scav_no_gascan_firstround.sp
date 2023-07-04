#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

float   g_fMapStartTime;
ConVar  g_hGamemode;

public Plugin myinfo =
{
	name = "[L4D2] Fix Scavenge No Gascan First Round",
	author = "Eyal282",
	description = "",
	version = "1.0",
	url = "None."
}

public void OnPluginStart()
{
    g_hGamemode = FindConVar("mp_gamemode");
}

public void OnMapStart()
{
    g_fMapStartTime = GetGameTime();

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
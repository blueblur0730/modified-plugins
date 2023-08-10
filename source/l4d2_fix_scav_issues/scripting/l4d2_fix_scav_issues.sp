#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <scavenge_func>

float g_fMapStartTime;

ConVar
	g_hCvarGamemode,
	g_hCvarAllowEnrich,
	g_hCvarScavengeRound,
	g_hCvarRestartRound;

bool g_bReadyUpAvailable;

public Plugin myinfo =
{
	name		= "[L4D2] Fix Scavenge Issues",
	author		= "blueblur, Credit to Eyal282, Lechuga16",
	description = "Fix bug when first round start there are no gascans and set the round number, resets the game on match end.",
	version		= "1.8",
	url			= "https://github.com/blueblur0730/modified-plugins"
}

public void
	OnPluginStart()
{
	// ConVars
	g_hCvarGamemode			= FindConVar("mp_gamemode");
	g_hCvarAllowEnrich		= CreateConVar("l4d2_scavenge_allow_enrich_gascan", "0", "Allow admin to enriching gascan", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarScavengeRound 	= CreateConVar("l4d2_scavenge_rounds", "5", "Set the total number of rounds", FCVAR_NOTIFY, true, 1.0, true, 5.0);
	g_hCvarRestartRound 	= CreateConVar("l4d2_scavenge_match_end_restart", "1", "Enable auto end match restart? (in case we use vanilla rematch vote)", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	// Hook
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("scavenge_match_finished", Event_ScavMatchFinished, EventHookMode_Post);

	// Cmd
	RegAdminCmd("sm_enrichgascan", SpawnGasCan, ADMFLAG_SLAY, "enrich gas cans. warning! ues it to be fun and carefull!!");
}

//-----------------
//		Events
//-----------------

public void OnAllPluginsLoaded()
{
	g_bReadyUpAvailable = LibraryExists("readyup");
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "readyup"))
	{
		g_bReadyUpAvailable = false;
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "readyup"))
	{
		g_bReadyUpAvailable = true;
	}
}

public void OnMapStart()
{
	g_fMapStartTime = GetGameTime();

	// Delay for a while to do it.
	if (!g_bReadyUpAvailable)
	{
		CreateTimer(12.0, Timer_Fix);
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// when round starts and the round number is the first round (round 1), sets the round limit.
	int iRound = GetScavengeRoundNumber();
	if (iRound == 1 && !InSecondHalfOfRound())
	{
		SetScavengeRoundLimit(g_hCvarScavengeRound.IntValue);
	}
}

public void Event_ScavMatchFinished(Event event, const char[] name, bool dontBroadcast)
{
	// give them time to see the scores.
	CreateTimer(7.0, Timer_RestartRound);
}

//---------------------
// Readyup Forwards
//---------------------

public void OnReadyUpInitiate()
{
	// Delay for a while to do it.
	// becasue for no reason gascans enriched double OnMapStart immediately.
	CreateTimer(12.0, Timer_DelayToSpawnGasCan);
}

//----------------------
//		Commander
//----------------------

public Action SpawnGasCan(int client, int args)
{
	if (g_hCvarAllowEnrich.IntValue == 1)
	{
		L4D2_SpawnAllScavengeItems();
	}
	else
	{
		ReplyToCommand(client, "Please turn on the convar before using.");
	}

	return Plugin_Handled;
}

//----------------------
//		Actions
//----------------------

Action Timer_DelayToSpawnGasCan(Handle Timer)
{
	SpawnGascanDuringReadyup();

	return Plugin_Handled;
}

void SpawnGascanDuringReadyup()
{
	char sValue[32];
	g_hCvarGamemode.GetString(sValue, sizeof(sValue));

	if (StrEqual(sValue, "scavenge") && GetScavengeItemsRemaining() == 0 && GetScavengeItemsGoal() == 0 && GetGasCanCount() == 0)
	{
		L4D2_SpawnAllScavengeItems();
	}
}

Action Timer_Fix(Handle Timer)
{
	char sValue[32];
	g_hCvarGamemode.GetString(sValue, sizeof(sValue));

	if (StrEqual(sValue, "scavenge") && GetGameTime() - g_fMapStartTime > 5.0 && GetScavengeItemsRemaining() == 0 && GetScavengeItemsGoal() == 0 && GetGasCanCount() == 0 && !g_bReadyUpAvailable)
	{
		L4D2_SpawnAllScavengeItems();
	}

	return Plugin_Handled;
}

Action Timer_RestartRound(Handle Timer)
{
	RestartRound();

	return Plugin_Handled;
}

/* belows are from plugin readyup_scav, Credits to lechuga16 */
void RestartRound()
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

	if (g_hCvarRestartRound.BoolValue)		// do we use vanilla rematch vote?
	{
		CreateTimer(2.0, Timer_RestartCampaign);
	}
}


Action Timer_RestartCampaign(Handle Timer)		// restart twice. because the first one freezes the survivors.
{
	char currentmap[128];
	GetCurrentMap(currentmap, sizeof(currentmap));
	
	L4D_RestartScenarioFromVote(currentmap);
	CreateTimer(2.0, Timer_RestartCampaign_Second, _);

	return Plugin_Handled;
}

Action Timer_RestartCampaign_Second(Handle Timer)
{
	char currentmap[128];
	GetCurrentMap(currentmap, sizeof(currentmap));
	
	L4D_RestartScenarioFromVote(currentmap);

	return Plugin_Handled;
}

//-----------------
//	Stock to use
//-----------------

stock bool InSecondHalfOfRound()
{
	return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound", 1));
}
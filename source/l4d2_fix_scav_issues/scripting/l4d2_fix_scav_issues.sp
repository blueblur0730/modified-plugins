#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <scavenge_func>
#undef REQUIRE_PLUGIN
#include <readyup>

float g_fMapStartTime;

ConVar
	g_hGamemode,
	g_secret,
	g_scav_rounds;

bool g_bReadyUpAvailable;

public Plugin myinfo =
{
	name		= "[L4D2] Fix Scavenge Issues",
	author		= "blueblur, Credit to Eyal282, Lechuga16",
	description = "Fix bug when first round start there are no gascans and set the round number, resets the game on match end.",
	version		= "1.6",
	url			= "https://github.com/blueblur0730/modified-plugins/tree/main/source/l4d2_fix_scav_issues"
}

public void
	OnPluginStart()
{
	// ConVars
	g_hGamemode	  = FindConVar("mp_gamemode");
	g_secret	  = CreateConVar("l4d2_allow_enrich_gascan", "0", "Allow Enriching Gascan", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_scav_rounds = CreateConVar("l4d2_scavenge_rounds", "5", "Set the number of rounds", FCVAR_NOTIFY, true, 1.0, true, 5.0);

	// Hook
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("scavenge_match_finished", Event_ScavMatchFinished, EventHookMode_Post);

	// Cmd
	RegAdminCmd("sm_enrichgascan", SpawnGasCan, ADMFLAG_SLAY, "enrich gas cans. warning! ues it fun and carefull!!");
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

	// when readyup is available (most likely we are using confogl), dont create timer. the timer is only suitable in vanilla mode
	if (!g_bReadyUpAvailable)
	{
		CreateTimer(1.0, Timer_Fix, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// when round starts and the round number is the first round (round 1), sets the round limit.
	int round = GetScavengeRoundNumber();
	if (round == 1 && !InSecondHalfOfRound())
	{
		SetScavengeRoundLimit(g_scav_rounds.IntValue);
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
	// Because when triggering OnMapStart, in some cases the gascans have already spawned but players haven't entered the game,
	// GetScavengeItemsRemaining() == 0 && GetScavengeItemsGoal() == 0 && GetGasCanCount() == 0 dont work. then gascans enriched double.
	CreateTimer(15.0, Timer_DelayedToSpawnGasCan);
}

//----------------------
//		Commander
//----------------------

public Action SpawnGasCan(int client, int args)
{
	if (g_secret.IntValue == 1)
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

Action Timer_DelayedToSpawnGasCan(Handle htimer)
{
	SpawnGascanDuringReadyup();

	return Plugin_Handled;
}

void SpawnGascanDuringReadyup()
{
	char sValue[32];
	g_hGamemode.GetString(sValue, sizeof(sValue));

	if (StrEqual(sValue, "scavenge") && GetGasCanCount() == 0)
	{
		L4D2_SpawnAllScavengeItems();
	}
}

Action Timer_RestartRound(Handle htimer)
{
	RestartRound();

	return Plugin_Handled;
}

Action Timer_Fix(Handle hTimer)
{
	char sValue[32];
	g_hGamemode.GetString(sValue, sizeof(sValue));

	if (StrEqual(sValue, "scavenge") && GetGameTime() - g_fMapStartTime > 5.0 && GetScavengeItemsRemaining() == 0 && GetScavengeItemsGoal() == 0 && GetGasCanCount() == 0)
	{
		L4D2_SpawnAllScavengeItems();
	}

	return Plugin_Handled;
}

void RestartRound()		// Thanks to lechuga16
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
	//CreateTimer(2.0, Timer_RestartCampaign);
}

/*
Action Timer_RestartCampaign(Handle htimer)
{
	char currentmap[128];
	GetCurrentMap(currentmap, sizeof(currentmap));
	
	Call_StartForward(CreateGlobalForward("OnReadyRoundRestarted", ET_Event));
	Call_Finish();
	
	L4D_RestartScenarioFromVote(currentmap);

	return Plugin_Handled;
}
*/

//-----------------
//	Stock to use
//-----------------

stock bool InSecondHalfOfRound()
{
	return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound", 1));
}


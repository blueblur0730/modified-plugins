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
	author		= "blueblur, Credit to Eyal282",
	description = "Fix bug when first round start there are no gascans and set the round number",
	version		= "1.5",
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

	// Cmd
	RegAdminCmd("sm_enrichgascan", SpawnGasCan, ADMFLAG_SLAY, "enrich gas cans. warning! ues it fun and carefull!!");
}

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

public void OnReadyUpInitiate()
{
	SpawnGascanDuringReadyup();
}

public void OnRoundLiveCountdownPre()	  // if OnReadyUpInitiate() dose not work.
{
	SpawnGascanDuringReadyup();
}

void SpawnGascanDuringReadyup()
{
	char sValue[32];
	g_hGamemode.GetString(sValue, sizeof(sValue));

	if (StrEqual(sValue, "scavenge") && GetGasCanCount() == 0 && GetScavengeItemsRemaining() == 0)
	{
		L4D2_SpawnAllScavengeItems();
	}
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

stock bool InSecondHalfOfRound()
{
	return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound", 1));
}
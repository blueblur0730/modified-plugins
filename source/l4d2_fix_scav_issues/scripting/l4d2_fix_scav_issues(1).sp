#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <scavenge_func>

ConVar
	g_hCvarAllowEnrich,
	g_hCvarScavengeRound,
	g_hCvarRestartRound;

public Plugin myinfo =
{
	name 		= "[L4D2] Fix Scavenge Issues",
	author		= "blueblur, Credit to Eyal282",
	description = "Fixes bug when first round started there were no gascans, sets the round number and resets the game on match end.",
	version		= "1.9",
	url			= "https://github.com/blueblur0730/modified-plugins"
}

public void OnPluginStart()
{
	// ConVars
	g_hCvarAllowEnrich		= CreateConVar("l4d2_scavenge_allow_enrich_gascan", "0", "Allow admin to enriching gascan", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarScavengeRound 	= CreateConVar("l4d2_scavenge_rounds", "5", "Set the total number of rounds", FCVAR_NOTIFY, true, 1.0, true, 5.0);
	g_hCvarRestartRound 	= CreateConVar("l4d2_scavenge_match_end_restart", "1", "Enable auto end match restart? (in case we use vanilla rematch vote)", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	// Hook
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("scavenge_match_finished", Event_ScavMatchFinished, EventHookMode_Post);

	// Cmd
	RegAdminCmd("sm_enrichgascan", SpawnGasCan, ADMFLAG_SLAY, "enrich gas cans. warning! ues it to be fun and carefull!!");

	CheckGameMode();
}

public Action CheckGameMode()
{
	if (IsScavengeMode())
		return Plugin_Continue;
	else
		return Plugin_Handled;
}

//-----------------
//		Events
//-----------------

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// when round starts and the round number is the first round (round 1), sets the round limit.
	int iRound = GetScavengeRoundNumber();
	if (iRound == 1 && !InSecondHalfOfRound())
	{
		SetScavengeRoundLimit(g_hCvarScavengeRound.IntValue);
	}

	CreateTimer(16.0, Timer_FixScavenge);
}

public void Event_ScavMatchFinished(Event event, const char[] name, bool dontBroadcast)
{
	// give them time to see the scores.
	CreateTimer(10.0, Timer_RestartMatch);
}

//----------------------
//		Commander
//----------------------

public Action SpawnGasCan(int client, int args)
{
	if (g_hCvarAllowEnrich.IntValue == 1)
		L4D2_SpawnAllScavengeItems();
	else
		ReplyToCommand(client, "[SM] Please turn on the convar before using.");

	return Plugin_Handled;
}

//----------------------
//		Actions
//----------------------

public Action Timer_FixScavenge(Handle timer)
{
    FixCans();
    return Plugin_Handled;
}

void FixCans()
{
    int entity = -1;

    while ((entity = FindEntityByClassname(entity, "weapon_gascan")) != -1)
    {
        // Thanks to Mart for the method! (https://forums.alliedmods.net/showthread.php?p=2723602)
        if (GetEntProp(entity, Prop_Send, "m_nSkin") > 0)
            return;
    }

    L4D2_SpawnAllScavengeItems();
}

Action Timer_RestartMatch(Handle Timer)
{
	if (g_hCvarRestartRound.BoolValue)
	{
		L4D2_Rematch();
	}
	return Plugin_Handled;
}

//-----------------
//	Stock to use
//-----------------

stock bool InSecondHalfOfRound()
{
	return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound", 1));
}
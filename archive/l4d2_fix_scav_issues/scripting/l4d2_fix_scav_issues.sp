#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define DEBUG 0

float g_fMapStartTime;

ConVar
	g_hCvarAllowEnrich,
	g_hCvarScavengeRound,
	g_hCvarRestartRound;

bool 
	g_bIsOutputFired = false;

public Plugin myinfo =
{
	name 		= "[L4D2] Fix Scavenge Issues",
	author 		= "blueblur, Credit to Eyal282",
	description = "Fixes bug when first round started there were no gascans, sets the round number and resets the game on match end.",
	version		= "1.10.1",
	url			= "https://github.com/blueblur0730/modified-plugins"
}

public void
	OnPluginStart()
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
}

//-----------------
//		Events
//-----------------
public void OnMapStart()
{
	g_bIsOutputFired = false;

	g_fMapStartTime = GetGameTime();

	// the reason gascans dont spawn is that OnGameplayStart was not called.
	HookEntityOutput("info_director", "OnGameplayStart", EntEvent_OnGameplayStart);
#if DEBUG
	PrintToServer("[Fix Scavenge Issues] info_director Hooked.");
#endif
}

// wait for the lazy OnGamePlayStart :(
public void OnConfigsExecuted()
{
	CreateTimer(25.0, Timer_Fix);
#if DEBUG
	PrintToServer("[Fix Scavenge Issues] Timer Created.");
#endif
}

public void EntEvent_OnGameplayStart(const char[] output, int caller, int activator, float delay)
{
#if DEBUG
	PrintToServer("[Fix Scavenge Issues] Output OnGameplayStart Fired.");
#endif
	g_bIsOutputFired = true;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// when round starts and the round number is the first round (round 1), sets the round limit.
	if (GetScavengeRoundNumber() == 1 && !InSecondHalfOfRound())
	{
		SetScavengeRoundLimit(g_hCvarScavengeRound.IntValue);
	}
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
	if (g_hCvarAllowEnrich.BoolValue)
		L4D2_SpawnAllScavengeItems();
	else
		ReplyToCommand(client, "Please turn on the convar before using.");

	return Plugin_Handled;
}

//----------------------
//		Actions
//----------------------
Action Timer_Fix(Handle Timer)
{
	if (L4D2_IsScavengeMode() && GetGameTime() - g_fMapStartTime > 5.0 
	&& GetScavengeItemsRemaining() == 0 && GetScavengeItemsGoal() == 0 
	&& GetGasCanCount() == 0 && !g_bIsOutputFired)
	{
		L4D2_SpawnAllScavengeItems();
#if DEBUG
	PrintToServer("[Fix Scavenge Issues] Gascan Spawned By Plugin.");
#endif
	}

	return Plugin_Handled;
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
/*
 * Returns current round status.
 *
 * @return			True if in second half of second, false otherwise.
 */
stock bool InSecondHalfOfRound()
{
	return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound", 1));
}

/*
 * Returns the current round number of current scavenge match.
 *
 * @return       	Round numbers
 */
stock int GetScavengeRoundNumber()
{
	return GameRules_GetProp("m_nRoundNumber");
}

/*
 * Sets the round limit.
 *
 * @param round		round limit to set. valid round number is 1, 3, 5.
 * @noreturn
 */
stock void SetScavengeRoundLimit(int round)
{
	GameRules_SetProp("m_nRoundLimit", round);
}

/*
 * Returns the amount of current remaining gascans.
 *
 * @return 			amount of current remaining gascans
 */
stock int GetScavengeItemsRemaining()
{
	return GameRules_GetProp("m_nScavengeItemsRemaining");
}

/*
 * Returns the goal amount of this match.
 *
 * @return 			goal amount of this match
 */
stock int GetScavengeItemsGoal()
{
	return GameRules_GetProp("m_nScavengeItemsGoal");
}

/*
 * Returns current gascan count.
 *
 * @param count		index to return
 * @return			gascan count
 */
stock int GetGasCanCount()
{
	int count;
	int entCount = GetEntityCount();

	for (int ent = MaxClients + 1; ent < entCount; ent++)
	{
		if (!IsValidEdict(ent))
			continue;

		char sClassname[64];
		GetEdictClassname(ent, sClassname, sizeof(sClassname));

		if (StrEqual(sClassname, "weapon_gascan") || StrEqual(sClassname, "weapon_gascan_spawn"))
			count++;
	}

	return count;
}
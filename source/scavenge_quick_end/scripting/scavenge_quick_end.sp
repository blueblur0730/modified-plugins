#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
//#include <smlib>
#include <scavenge_func>
#include <colors>

// We must wait longer because of cases where the game doesn't
// do the compare at the same time as us.
#define SAFETY_BUFFER_TIME 1.0

float
	g_flDefaultLossTime;

bool
	g_bInScavengeRound,
	g_bInSecondHalf;

ConVar
	g_hQuickEndSwitch;

// GetRoundTime(&minutes, &seconds, team)
#define GetRoundTime(%0,%1,%2) %1 = GetScavengeRoundDuration(%2);	%0 = RoundToFloor(%1)/60; %1 -= 60 * %0

#define boolalpha(%0) (%0 ? "true" : "false")

public Plugin myinfo =
{
	name		= "Scavenge Quick End",
	author		= "ProdigySim, modified by blueblur",
	description = "Checks various tiebreaker win conditions mid-round and ends the round as necessary.",
	version		= "2.1.2",
	url			= "http://bitbucket.org/ProdigySim/misc-sourcemod-plugins/"

}

public void
	OnPluginStart()
{
	HookEvent("gascan_pour_completed", OnCanPoured, EventHookMode_PostNoCopy);
	HookEvent("scavenge_round_start", RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", RoundEnd, EventHookMode_PostNoCopy);
	LoadTranslations("scavenge_quick_end.phrases");
	RegConsoleCmd("sm_time", TimeCmd);

	g_hQuickEndSwitch = CreateConVar("l4d2_enable_scavenge_quick_end", "1", "Only enable quick end or not, Printing time is not included by this cvar", FCVAR_NOTIFY, true, 0.0, true, 1.0);
}

public Action TimeCmd(int client, any args)
{
	if (!g_bInScavengeRound) return Plugin_Handled;

	if (g_bInSecondHalf)
	{
		float lastRoundTime;
		int	  lastRoundMinutes;
		GetRoundTime(lastRoundMinutes, lastRoundTime, 3);

		CPrintToChat(client, "%t", "PrintRoundTime", GetScavengeRoundNumber(), GetScavengeTeamScore(3, GetScavengeRoundNumber()), lastRoundMinutes, lastRoundTime);
	}

	float thisRoundTime;
	int	  thisRoundMinutes;
	GetRoundTime(thisRoundMinutes, thisRoundTime, 2);

	if (g_bInSecondHalf)
	{
		CPrintToChat(client, "%t", "PrintRoundTimeInHalf", GetScavengeRoundNumber(), GetScavengeTeamScore(2, GetScavengeRoundNumber()), thisRoundMinutes, thisRoundTime);
	}
	else
	{
		CPrintToChat(client, "%t", "PrintRoundTime", GetScavengeRoundNumber(), GetScavengeTeamScore(2, GetScavengeRoundNumber()), thisRoundMinutes, thisRoundTime);
	}

	return Plugin_Handled;
}

public void OnGameFrame()
{
	if (g_flDefaultLossTime != 0.0 && GetGameTime() > g_flDefaultLossTime)
	{
		EndRoundEarlyOnTime(1);
		g_flDefaultLossTime = 0.0;
	}
}

public void RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bInScavengeRound) PrintRoundEndTimeData(g_bInSecondHalf);

	g_flDefaultLossTime = 0.0;
	g_bInScavengeRound	= false;
	g_bInSecondHalf		= false;
}

public void RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bInSecondHalf		= !GetEventBool(event, "firsthalf");
	g_bInScavengeRound	= true;
	g_flDefaultLossTime = 0.0;
	if (g_bInScavengeRound && g_bInSecondHalf)
	{
		int lastRoundScore = GetScavengeTeamScore(3);
		if (lastRoundScore == 0 || lastRoundScore == GameRules_GetProp("m_nScavengeItemsGoal"))
		{
			g_flDefaultLossTime = GameRules_GetPropFloat("m_flRoundStartTime") + GetScavengeRoundDuration(3) + SAFETY_BUFFER_TIME;
		}
	}
}

public void OnCanPoured(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bInScavengeRound && g_bInSecondHalf)
	{
		int remaining = GameRules_GetProp("m_nScavengeItemsRemaining");
		if (remaining > 0)
		{
			int scoreA = GetScavengeTeamScore(2);
			int scoreB = GetScavengeTeamScore(3);
			if (scoreA == scoreB && GetScavengeRoundDuration(2) < GetScavengeRoundDuration(3))
			{
				EndRoundEarlyOnTime(1);
			}
		}
	}
}

public void PrintRoundEndTimeData(bool secondHalf)
{
	float LastRoundTime;
	int	  LastRoundMinutes;
	if (secondHalf)
	{
		GetRoundTime(LastRoundMinutes, LastRoundTime, 3);
		CPrintToChatAll("%t", "PrintRoundEndTime", GetScavengeRoundNumber(), GetScavengeTeamScore(3, GetScavengeRoundNumber()), LastRoundMinutes, LastRoundTime);
	}

	float ThisRoundTime;
	int	  ThisRoundMinutes;
	GetRoundTime(ThisRoundMinutes, ThisRoundTime, 2);
	if (secondHalf)
	{
		CPrintToChatAll("%t", "PrintRoundEndTimeInHalf", GetScavengeRoundNumber(), GetScavengeTeamScore(2, GetScavengeRoundNumber()), ThisRoundMinutes, ThisRoundTime);
	}
	else
	{
		CPrintToChatAll("%t", "PrintRoundEndTime", GetScavengeRoundNumber(), GetScavengeTeamScore(2, GetScavengeRoundNumber()), ThisRoundMinutes, ThisRoundTime);
	}
}

public Action EndRoundEarlyOnTime(int client)
{
	if (!GetConVarBool(g_hQuickEndSwitch))	  // check enabled quick end or not
	{
		return Plugin_Handled;
	}

	int oldFlags;
	oldFlags = GetCommandFlags("scenario_end");
	// FCVAR_LAUNCHER is actually FCVAR_DEVONLY`
	SetCommandFlags("scenario_end", oldFlags & ~(FCVAR_CHEAT | FCVAR_DEVELOPMENTONLY));
	ServerCommand("scenario_end");
	ServerExecute();
	SetCommandFlags("scenario_end", oldFlags);
	CPrintToChatAll("%t", "RoundEndEarly", client);

	return Plugin_Continue;
}
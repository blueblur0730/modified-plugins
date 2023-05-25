#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
//#include <smlib>
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
#define GetRoundTime(%0,%1,%2) %1 = GameRules_GetRoundDuration(%2);	%0 = RoundToFloor(%1)/60; %1 -= 60 * %0

#define boolalpha(%0) (%0 ? "true" : "false")

public Plugin myinfo = 
{
	name = "Scavenge Quick End",
	author = "ProdigySim, modified by blueblur",
	description = "Checks various tiebreaker win conditions mid-round and ends the round as necessary.",
	version = "2.0",
	url = "http://bitbucket.org/ProdigySim/misc-sourcemod-plugins/"
}

public void OnPluginStart()
{
	HookEvent("gascan_pour_completed", OnCanPoured, EventHookMode_PostNoCopy);
	HookEvent("scavenge_round_start", RoundStart,EventHookMode_PostNoCopy);
	HookEvent("round_end", RoundEnd, EventHookMode_PostNoCopy);
	LoadTranslations("scavenge_quick_end.phrases");
	RegConsoleCmd("sm_time", TimeCmd);

	g_hQuickEndSwitch = CreateConVar("l4d2_enable_scavenge_quick_end", "1", "Only enable quick end or not, Printing time is not included by this cvar", FCVAR_NOTIFY, true, 0.0, true, 1.0);
}

public Action TimeCmd(int client, any args)
{
	if(!g_bInScavengeRound) return Plugin_Handled;
	
	if(g_bInSecondHalf)
	{
		float lastRoundTime;
		int lastRoundMinutes;
		GetRoundTime(lastRoundMinutes,lastRoundTime,3);
		
		CPrintToChat(client, "%t","PrintLastRoundTime", GameRules_GetScavengeTeamScore(3), lastRoundMinutes, lastRoundTime);		// [TIME] Last Round: {OG}%d {N}in {OG}%d:%05.2f
	}
	
	float thisRoundTime;
	int thisRoundMinutes;
	GetRoundTime(thisRoundMinutes,thisRoundTime,2);
	CPrintToChat(client, "%t", "PrintThisRoundTime", GameRules_GetScavengeTeamScore(2), thisRoundMinutes, thisRoundTime);		//[TIME] This Round: {OG}%d {N}in {OG}%d:%05.2f
	
	return Plugin_Handled;
}

public void OnGameFrame()
{
	if(g_flDefaultLossTime != 0.0 && GetGameTime() > g_flDefaultLossTime)
	{
		EndRoundEarlyOnTime(1);
		g_flDefaultLossTime=0.0;
	}
}

public void RoundEnd(Event event, const char[]name, bool dontBroadcast)
{
	if(g_bInScavengeRound) PrintRoundEndTimeData(g_bInSecondHalf);
	
	g_flDefaultLossTime=0.0;	
	g_bInScavengeRound=false;
	g_bInSecondHalf=false;
}

public void RoundStart(Event event, const char[]name, bool dontBroadcast)
{
	g_bInSecondHalf = !GetEventBool(event, "firsthalf");
	g_bInScavengeRound=true;
	g_flDefaultLossTime = 0.0;
	if(g_bInScavengeRound && g_bInSecondHalf)
	{
		int lastRoundScore = GameRules_GetScavengeTeamScore(3);
		if(lastRoundScore == 0 || lastRoundScore == GameRules_GetProp("m_nScavengeItemsGoal"))
		{
			g_flDefaultLossTime = GameRules_GetPropFloat("m_flRoundStartTime") + GameRules_GetRoundDuration(3) + SAFETY_BUFFER_TIME;
		}
	}
}

public void OnCanPoured(Event event, const char[]name, bool dontBroadcast)
{
	if(g_bInScavengeRound && g_bInSecondHalf)
	{
		int remaining = GameRules_GetProp("m_nScavengeItemsRemaining");
		if(remaining > 0)
		{
			int scoreA = GameRules_GetScavengeTeamScore(2);
			int scoreB = GameRules_GetScavengeTeamScore(3);
			if(scoreA == scoreB && GameRules_GetRoundDuration(2) < GameRules_GetRoundDuration(3))
			{
				EndRoundEarlyOnTime(1);
			}
		}
	}
}

public void PrintRoundEndTimeData(bool secondHalf)
{
	float time;
	int minutes;
	if(secondHalf)
	{
		GetRoundTime(minutes,time,3);
		CPrintToChatAll("%t", "PrintLastRoundEndTime", GameRules_GetScavengeTeamScore(3), minutes, time);		//[TIME] Last Round: {OG}%d {N}in {OG}%d:%05.2f"
	}

	GetRoundTime(minutes,time,2);
	CPrintToChatAll("%t", "PrintThisRoundEndTime", GameRules_GetScavengeTeamScore(2), minutes, time);		//[TIME] This Round: {OG}%d {N}in {OG}%d:%05.2f"
}

public Action EndRoundEarlyOnTime(int client)
{
	if (!GetConVarBool(g_hQuickEndSwitch)) 		//check enabled quick end or not
	{
		return Plugin_Handled;
	}

	int oldFlags;
	oldFlags = GetCommandFlags("scenario_end");
	// FCVAR_LAUNCHER is actually FCVAR_DEVONLY`
	SetCommandFlags("scenario_end", oldFlags & ~(FCVAR_CHEAT|FCVAR_DEVELOPMENTONLY));
	ServerCommand("scenario_end");
	ServerExecute();
	SetCommandFlags("scenario_end", oldFlags);
	CPrintToChatAll("%t", "RoundEndEarly", client);			//"[{G}Scavogl{N}] Round Ended Early: Win condition decided on time."

	return Plugin_Continue;
}

stock float GameRules_GetRoundDuration(int team)
{
	float flRoundStartTime = GameRules_GetPropFloat("m_flRoundStartTime");
	if(team == 2 && flRoundStartTime != 0.0 && GameRules_GetPropFloat("m_flRoundEndTime") == 0.0)
	{
		// Survivor team still playing round.
		return GetGameTime()-flRoundStartTime;
	}
	team = L4D2_TeamNumberToTeamIndex(team);
	if(team == -1) return -1.0;
	
	return GameRules_GetPropFloat("m_flRoundDuration", team);
}

stock int GameRules_GetScavengeTeamScore(int team, int round=-1)
{
	team = L4D2_TeamNumberToTeamIndex(team);
	if(team == -1) return -1;
	
	if(round <= 0 || round > 5)
	{
		round = GameRules_GetProp("m_nRoundNumber");
	}
	--round;
	return GameRules_GetProp("m_iScavengeTeamScore", _, (2*round)+team);
}

// convert "2" or "3" to "0" or "1" for global static indices
stock int L4D2_TeamNumberToTeamIndex(int team)
{
	// must be team 2 or 3 for this stupid function
	if(team != 2 && team != 3) return -1;

	// Tooth table:
	// Team | Flipped | Correct index
	// 2	   0		 0
	// 2	   1		 1
	// 3	   0		 1
	// 3	   1		 0
	// index = (team & 1) ^ flipped
	// index = team-2 XOR flipped, or team%2 XOR flipped, or this...	
	int flipped;
	flipped = GameRules_GetProp("m_bAreTeamsFlipped", 1);
	if(flipped) ++team;
	return team % 2;
}

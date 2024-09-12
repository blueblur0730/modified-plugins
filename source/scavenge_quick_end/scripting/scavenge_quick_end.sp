#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools_gamerules>
#include <l4d2_scav_stocks>
#include <colors>

// We must wait longer because of cases where the game doesn't
// do the compare at the same time as us.
#define SAFETY_BUFFER_TIME 1.0
#define L4D2Team_Survivor  2
#define L4D2Team_Infected  3

// SDK function
#define GAMEDATA_FILE "scavenge_quick_end"
#define TRANSLATION_FILE "scavenge_quick_end.phrases"
#define SDKCALL_FUNCTION "CDirectorScavengeMode::EndScavengeRound"
#define ADDRESS_THEDIRECTOR "CDirector"
#define OFFSET_SCAVENGEMODEPTR "ScavengeModePtr"

#define PL_VERSION "4.1"

float g_flDefaultLossTime;
bool g_bLateLoad, g_bInScavengeRound, g_bIsRoundActivated;
int	g_iLateLoadRound;

ArrayList g_hArrSurDur, g_hArrInfDur;
ConVar g_hcvarQuickEndSwitch;
ScavStocksWrapper g_Wrapper;

Handle g_hSDKCall_EndScavengeRound = null;
Address TheDirector = Address_Null;

enum EndType
{
	QE_SameTargetCompareUsedTime,
	QE_AchievedTargetSetDeadLine,
	QE_WhoSurvivedLonger,
	QE_None
} 
EndType g_eEndType;

public Plugin myinfo =
{
	name = "[L4D2] Scavenge Quick End",
	author = "ProdigySim, blueblur",
	description = "Checks various tiebreaker win conditions mid-round and ends the round as necessary.",
	version	= PL_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int errMax)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	IniGameData();

	CreateConVar("scavenge_quick_end_version", PL_VERSION, "Plugin version", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY);
	g_hcvarQuickEndSwitch = CreateConVar("l4d2_enable_scavenge_quick_end", "1", "Only enable quick end or not, Printing time is not included by this cvar", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	RegConsoleCmd("sm_time", Cmd_QuaryTime, "Usage: sm_time <round>, if round argument is empty it prints the current round status.");
	HookEvent("gascan_pour_completed", Event_GascanPourCompleted, EventHookMode_PostNoCopy);
	HookEvent("scavenge_match_finished", Event_ScavMatchFinished, EventHookMode_PostNoCopy);	// if they decided to rematch, the map wont change.
	HookEvent("player_left_start_area", Event_PlayerLeftStartArea, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);

	if (!g_hArrSurDur)
		g_hArrSurDur = new ArrayList();

	if (!g_hArrInfDur)
		g_hArrInfDur = new ArrayList();

	if (g_bLateLoad)
	{
		if (g_Wrapper.m_nRoundNumber == 1 && !g_Wrapper.m_bInSecondHalfOfRound && g_bInScavengeRound)
			g_bLateLoad = false;
		else
			g_iLateLoadRound = g_Wrapper.m_nRoundNumber;
	}

	LoadTranslation(TRANSLATION_FILE);
}

public void OnPluginEnd()
{
	if (g_hArrSurDur)
		delete g_hArrSurDur;

	if (g_hArrInfDur)
		delete g_hArrInfDur;
}

public void OnMapStart()
{
	if (!g_hArrSurDur)
		g_hArrSurDur = new ArrayList();

	if (!g_hArrInfDur)
		g_hArrInfDur = new ArrayList();
}

public void OnMapEnd()
{
	if (g_hArrSurDur)
		delete g_hArrSurDur;

	if (g_hArrInfDur)
		delete g_hArrInfDur;

	g_bLateLoad		 = false;	 // refresh the late load status on map change.
	g_iLateLoadRound = 0;
}

Action Cmd_QuaryTime(int client, any args)
{
	if (GetCmdArgs() > 0)
	{
		if (GetCmdArgs() > 1)
		{
			CReplyToCommand(client, "%t", "Usage");
			return Plugin_Handled;
		}

		int round = GetCmdArgInt(1);
		if (round < 1 || round > g_Wrapper.m_nRoundNumber)
		{
			CReplyToCommand(client, "%t", "InvalidRound");
			return Plugin_Handled;
		}

		if (round == g_Wrapper.m_nRoundNumber)
		{
			if (!g_bIsRoundActivated)
			{
				CReplyToCommand(client, "%t", "NotStartedYet");
				return Plugin_Handled;
			}
			else
			{
				PrintRoundTime(g_Wrapper.m_nRoundNumber, client, g_Wrapper.m_bInSecondHalfOfRound);
				return Plugin_Handled;
			}
		}

		if (g_bLateLoad)	// we cant retrieve the previous round duration if the plugin is loaded lately.
		{
			if (round <= g_iLateLoadRound)
			{
				CReplyToCommand(client, "%t", "LateLoaded", g_iLateLoadRound);
				return Plugin_Handled;
			}
		}

		PrintRoundTime(round, client, true, true);	  // previous round must have played two halves.
		return Plugin_Handled;
	}

	if (!g_bIsRoundActivated)
	{
		CReplyToCommand(client, "%t", "NotStartedYet");
		return Plugin_Handled;
	}

	PrintRoundTime(g_Wrapper.m_nRoundNumber, client, g_Wrapper.m_bInSecondHalfOfRound);
	return Plugin_Handled;
}

void PrintRoundTime(int round, int client, bool bInSecondHalf, bool bIsPreviousRound = false)
{
	if (bInSecondHalf)	  // in second half of round, infected are survivors who played on last round.
	{
		char SurTime[128], InfTime[128];
		if (bIsPreviousRound)
		{
			float fSur = g_hArrSurDur.Get(round - 1); int iSur = RoundToFloor(fSur) / 60;
			float fInf = g_hArrInfDur.Get(round - 1); int iInf = RoundToFloor(fInf) / 60;
			fSur -= iSur * 60; fInf -= iInf * 60;
			Format(SurTime, sizeof(SurTime), "%d:%02.2f", iSur, fSur);
			Format(InfTime, sizeof(InfTime), "%d:%02.2f", iInf, fInf);
		}
		else
		{
			FormatDurationTime(InfTime, sizeof(InfTime), L4D2Team_Infected);
			FormatDurationTime(SurTime, sizeof(SurTime), L4D2Team_Survivor);
		}

		CPrintToChat(client, "%t", "PrintRoundTime", round,
					 g_Wrapper.GetTeamScore(L4D2Team_Infected, round, bIsPreviousRound),
					 InfTime);
		CPrintToChat(client, "%t", "PrintRoundTimeInHalf", round,
					 g_Wrapper.GetTeamScore(L4D2Team_Survivor, round, bIsPreviousRound),
					 SurTime);
	}
	else
	{
		char SurTime[128];
		FormatDurationTime(SurTime, sizeof(SurTime), L4D2Team_Survivor);	// only survivors are playing on this round.
		CPrintToChat(client, "%t", "PrintRoundTime", round,
					 g_Wrapper.GetTeamScore(L4D2Team_Survivor),
					 SurTime);
	}
}

void Event_ScavMatchFinished(Event hEvent, const char[] name, bool dontBroadcast)
{
	// just do the clearing if they rematch. handle will be deleted on map change.
	if (g_hArrSurDur.Length > 0)
		g_hArrSurDur.Clear();

	if (g_hArrInfDur.Length > 0)
		g_hArrInfDur.Clear();

	g_bLateLoad	= false;	 // refresh the late load status on match end.
	g_iLateLoadRound = 0;
}

void Event_PlayerLeftStartArea(Event hEvent, const char[] name, bool dontBroadcast)
{
	g_bIsRoundActivated = true;
}

void Event_RoundEnd(Event hEvent, const char[] name, bool dontBroadcast)
{
	if (g_Wrapper.m_bInSecondHalfOfRound)
	{
		g_hArrSurDur.Push(g_Wrapper.GetRoundDuration(L4D2Team_Survivor));
		g_hArrInfDur.Push(g_Wrapper.GetRoundDuration(L4D2Team_Infected));
	}

	if (g_bInScavengeRound)
		PrintRoundEndTimeData(g_Wrapper.m_bInSecondHalfOfRound);

	g_flDefaultLossTime = 0.0;
	g_bInScavengeRound	= false;
	g_bIsRoundActivated = false;
}

void Event_RoundStart(Event hEvent, const char[] name, bool dontBroadcast)
{
	g_bInScavengeRound = true;
	g_flDefaultLossTime = 0.0;
	g_eEndType = QE_None;

	if (g_bInScavengeRound && g_Wrapper.m_bInSecondHalfOfRound)	   // we are in second half of round now.
	{
		// record the loss condition deadline.
		if (g_Wrapper.GetTeamScore(L4D2Team_Infected) == g_Wrapper.m_nScavengeItemsGoal ||
			g_Wrapper.GetTeamScore(L4D2Team_Infected) == 0)
			g_flDefaultLossTime = GameRules_GetPropFloat("m_flRoundStartTime") + g_Wrapper.GetRoundDuration(L4D2Team_Infected) + SAFETY_BUFFER_TIME;
	}
}

void Event_GascanPourCompleted(Event hEvent, const char[] name, bool dontBroadcast)
{
	if (g_bInScavengeRound && g_Wrapper.m_bInSecondHalfOfRound)	   // we are in second half of round now.
	{
		if (g_Wrapper.m_nScavengeItemsRemaining > 0)	// to check if there is anymore gascans, which reduce the condition that survivor team complete the target.
		{
			// Same Target Compare Time. Survivors use less time to acheive the same target?
			if (g_Wrapper.GetTeamScore(L4D2Team_Survivor) == g_Wrapper.GetTeamScore(L4D2Team_Infected) &&
				g_Wrapper.GetRoundDuration(L4D2Team_Survivor) < g_Wrapper.GetRoundDuration(L4D2Team_Infected))
			{
				g_eEndType = QE_SameTargetCompareUsedTime;
				EndRoundEarlyOnTime();
			}
		}
	}
}

public void OnGameFrame()
{
	if (g_flDefaultLossTime != 0.0 && GetGameTime() > g_flDefaultLossTime && g_Wrapper.m_bInSecondHalfOfRound)
	{
		// fully completed or totally lost?
		if (g_Wrapper.GetTeamScore(L4D2Team_Infected) == g_Wrapper.m_nScavengeItemsGoal)
			g_eEndType = QE_AchievedTargetSetDeadLine;
		else if (g_Wrapper.GetTeamScore(L4D2Team_Infected) == 0)
			g_eEndType = QE_WhoSurvivedLonger;

		EndRoundEarlyOnTime();
		g_flDefaultLossTime = 0.0;
	}
}

void PrintRoundEndTimeData(bool bSecondHalf)
{
	if (bSecondHalf)
	{
		char SurTime[128], InfTime[128];
		FormatDurationTime(InfTime, sizeof(InfTime), L4D2Team_Infected);
		CPrintToChatAll("%t", "PrintRoundEndTime", g_Wrapper.m_nRoundNumber,
						g_Wrapper.GetTeamScore(L4D2Team_Infected),
						InfTime);

		FormatDurationTime(SurTime, sizeof(SurTime), L4D2Team_Survivor);
		CPrintToChatAll("%t", "PrintRoundEndTimeInHalf", g_Wrapper.m_nRoundNumber,
						g_Wrapper.GetTeamScore(L4D2Team_Survivor),
						SurTime);
	}
	else
	{
		char SurTime[128];
		FormatDurationTime(SurTime, sizeof(SurTime), L4D2Team_Survivor);
		CPrintToChatAll("%t", "PrintRoundEndTime", g_Wrapper.m_nRoundNumber,
						g_Wrapper.GetTeamScore(L4D2Team_Survivor),
						SurTime);
	}
}

void EndRoundEarlyOnTime()
{
	if (!g_hcvarQuickEndSwitch.BoolValue)	 // check enabled quick end or not
		return;

	switch (g_eEndType)
	{
		case QE_SameTargetCompareUsedTime:
		{
			CPrintToChatAll("%t", "RoundEndEarly_Type1");
		}
		case QE_AchievedTargetSetDeadLine:
		{
			CPrintToChatAll("%t", "RoundEndEarly_Type2");
		}
		case QE_WhoSurvivedLonger:
		{
			CPrintToChatAll("%t", "RoundEndEarly_Type3");
		}
	}

	SDKCall(g_hSDKCall_EndScavengeRound, TheDirector);
}

void IniGameData()
{
	GameData gd = new GameData(GAMEDATA_FILE);
	if (!gd)
		SetFailState("Failed to load gamedata \""...GAMEDATA_FILE..."\".");
		
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(gd, SDKConf_Signature, SDKCALL_FUNCTION))
		SetFailState("Failed to set SDK call signature for \""...SDKCALL_FUNCTION..."\".");

	g_hSDKCall_EndScavengeRound = EndPrepSDKCall();
	if (!g_hSDKCall_EndScavengeRound)
		SetFailState("Failed to prepare SDK call for \""...SDKCALL_FUNCTION..."\".");

	TheDirector = gd.GetAddress(ADDRESS_THEDIRECTOR);
	if (TheDirector == Address_Null)
		SetFailState("Failed to get address of \""...ADDRESS_THEDIRECTOR..."\".");

	int iOff_ScavengeModePtr = -1;
	iOff_ScavengeModePtr = gd.GetOffset(OFFSET_SCAVENGEMODEPTR);
	if (iOff_ScavengeModePtr == -1)
		SetFailState("Failed to get offset of \""...OFFSET_SCAVENGEMODEPTR..."\".");

	TheDirector += view_as<Address>(iOff_ScavengeModePtr);

	delete gd;
}

/**
 * Check if the translation file exists
 *
 * @param translation	Translation name.
 * @noreturn
 */
stock void LoadTranslation(const char[] translation)
{
	char
		sPath[PLATFORM_MAX_PATH],
		sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}
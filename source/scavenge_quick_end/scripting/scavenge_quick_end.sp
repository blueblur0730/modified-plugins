#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
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

#define PL_VERSION "5.0"

float g_flDefaultLossTime;
bool g_bLateLoad, g_bInScavengeRound, g_bIsRoundActivated;
int	g_iLateLoadRound;

enum struct RoundStatus
{
	ArrayList m_hArrSurDur;
	ArrayList m_hArrInfDur;

	void Ini() {
		if (!this.m_hArrSurDur)
			this.m_hArrSurDur = new ArrayList();

		if (!this.m_hArrInfDur)
			this.m_hArrInfDur = new ArrayList();
	}

	void Clear() {
		this.m_hArrInfDur.Clear();
		this.m_hArrSurDur.Clear();
	}

	void Delete() {
		if (this.m_hArrSurDur)
			delete this.m_hArrSurDur;

		if (this.m_hArrInfDur)
			delete this.m_hArrInfDur;
	}

	void PushDuration(int team, float duration) {
		switch (team) {
			case L4D2Team_Survivor: this.m_hArrSurDur.Push(duration);
			case L4D2Team_Infected: this.m_hArrInfDur.Push(duration);
		}
	}

	float PopDuration(int team, int round) {
		// stupid switch.
		float duration;

		switch (team) {
			case L4D2Team_Survivor: duration = this.m_hArrSurDur.Get(round - 1);
			case L4D2Team_Infected: duration = this.m_hArrInfDur.Get(round - 1);
		}

		return duration;
	}

	int GetRound() {
		return GameRules_GetProp("m_nRoundNumber");
	}

	bool IsInSecondHalf() {
		return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound"));
	}

	int GetGoal() {
		return GameRules_GetProp("m_iScavengeRoundGoal");
	}

	int GetRemaining() {
		return GameRules_GetProp("m_iScavengeRoundRemaining");
	}

	int GetScore(int team, int round = -1, bool bIsPreviousRound = false) {
		if (round <= 0 || round > 5)
			round = this.GetRound();

		team = this.TeamNumberToTeamIndex(team, bIsPreviousRound);
		if (team == -1) return -1;

		return GameRules_GetProp("m_iScavengeTeamScore", _, (2 * (round - 1)) + team);
	}

	float GetDuration(int team) {
		if (team == 2 && GameRules_GetPropFloat("m_flRoundStartTime") != 0.0 && GameRules_GetPropFloat("m_flRoundEndTime") == 0.0)
			return (GetGameTime() - GameRules_GetPropFloat("m_flRoundStartTime"));

		team = this.TeamNumberToTeamIndex(team);
		if (team == -1) return -1.0;

		return GameRules_GetPropFloat("m_flRoundDuration", team);
	}

	void FormatDuration(char[] buffer, int maxlen, int team) {
		float seconds = this.GetDuration(team);
		int	  minutes = RoundToFloor(seconds) / 60;
		seconds -= 60 * minutes;

		Format(buffer, maxlen, "%d:%02.2f", minutes, seconds);
	}

	int TeamNumberToTeamIndex(int team, bool bIsPreviousRound = false) {
		if (team != 2 && team != 3) return -1;

		if (!bIsPreviousRound)
		{
			bool flipped = view_as<bool>(GameRules_GetProp("m_bAreTeamsFlipped"));
			if (flipped) ++team;
		}
		else 
			++team;

		return team % 2;
	}
}
RoundStatus g_esRoundStatus;

ConVar g_hcvarQuickEndSwitch;
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
	LoadTranslation(TRANSLATION_FILE);

	CreateConVar("scavenge_quick_end_version", PL_VERSION, "Plugin version", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY);
	g_hcvarQuickEndSwitch = CreateConVar("l4d2_enable_scavenge_quick_end", "1", "Only enable quick end or not, Printing time is not included by this cvar", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	RegConsoleCmd("sm_time", Cmd_QuaryTime, "Usage: sm_time <round>, if round argument is empty it prints the current round status.");

	HookEvent("gascan_pour_completed", Event_GascanPourCompleted, EventHookMode_PostNoCopy);
	HookEvent("scavenge_match_finished", Event_ScavMatchFinished, EventHookMode_PostNoCopy);	// if they decided to rematch, the map wont change.
	HookEvent("player_left_start_area", Event_PlayerLeftStartArea, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);

	g_esRoundStatus.Ini();

	if (g_bLateLoad)
	{
		if (g_esRoundStatus.GetRound() == 1 && !g_esRoundStatus.IsInSecondHalf() && g_bInScavengeRound)
			g_bLateLoad = false;
		else
			g_iLateLoadRound = g_esRoundStatus.GetRound();
	}
}

public void OnPluginEnd()
{
	g_esRoundStatus.Delete();
}

public void OnMapStart()
{
	g_esRoundStatus.Ini();
}

public void OnMapEnd()
{
	g_esRoundStatus.Clear();
	g_bLateLoad		 = false;	 // refresh the late load status on map change.
	g_iLateLoadRound = 0;
}

Action Cmd_QuaryTime(int client, int args)
{
	if (GetCmdArgs() > 0)
	{
		if (GetCmdArgs() > 1)
		{
			CReplyToCommand(client, "%t", "Usage");
			return Plugin_Handled;
		}

		int round = GetCmdArgInt(1);
		if (round < 1 || round > g_esRoundStatus.GetRound())
		{
			CReplyToCommand(client, "%t", "InvalidRound");
			return Plugin_Handled;
		}

		if (round == g_esRoundStatus.GetRound())
		{
			if (!g_bIsRoundActivated)
			{
				CReplyToCommand(client, "%t", "NotStartedYet");
				return Plugin_Handled;
			}
			else
			{
				PrintRoundTime(g_esRoundStatus.GetRound(), client, g_esRoundStatus.IsInSecondHalf());
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

	PrintRoundTime(g_esRoundStatus.GetRound(), client, g_esRoundStatus.IsInSecondHalf());
	return Plugin_Handled;
}

void PrintRoundTime(int round, int client, bool bInSecondHalf, bool bIsPreviousRound = false)
{
	if (bInSecondHalf)	  // in second half of round, infected are survivors who played on last round.
	{
		char SurTime[128], InfTime[128];
		if (bIsPreviousRound)
		{
			float fSur = g_esRoundStatus.PopDuration(L4D2Team_Survivor, round); 
			int iSur = RoundToFloor(fSur) / 60;
			fSur -= iSur * 60;

			float fInf = g_esRoundStatus.PopDuration(L4D2Team_Infected, round); 
			int iInf = RoundToFloor(fInf) / 60;
			fInf -= iInf * 60;

			Format(SurTime, sizeof(SurTime), "%d:%02.2f", iSur, fSur);
			Format(InfTime, sizeof(InfTime), "%d:%02.2f", iInf, fInf);
		}
		else
		{
			g_esRoundStatus.FormatDuration(InfTime, sizeof(InfTime), L4D2Team_Infected);
			g_esRoundStatus.FormatDuration(SurTime, sizeof(SurTime), L4D2Team_Survivor);
		}

		CPrintToChat(client, "%t", "PrintRoundTime", round,
					 g_esRoundStatus.GetScore(L4D2Team_Infected, round, bIsPreviousRound),
					 InfTime);

		CPrintToChat(client, "%t", "PrintRoundTimeInHalf", round,
					 g_esRoundStatus.GetScore(L4D2Team_Survivor, round, bIsPreviousRound),
					 SurTime);
	}
	else
	{
		char SurTime[128];
		g_esRoundStatus.FormatDuration(SurTime, sizeof(SurTime), L4D2Team_Survivor);	// only survivors are playing on this round.
		CPrintToChat(client, "%t", "PrintRoundTime", round,
					 g_esRoundStatus.GetScore(L4D2Team_Survivor),
					 SurTime);
	}
}

void Event_ScavMatchFinished(Event hEvent, const char[] name, bool dontBroadcast)
{
	g_esRoundStatus.Clear();	// just do the clearing if they rematch.
	g_bLateLoad	= false;	 // refresh the late load status on match end.
	g_iLateLoadRound = 0;
}

void Event_PlayerLeftStartArea(Event hEvent, const char[] name, bool dontBroadcast)
{
	g_bIsRoundActivated = true;
}

void Event_RoundEnd(Event hEvent, const char[] name, bool dontBroadcast)
{
	if (g_esRoundStatus.IsInSecondHalf())
	{
		g_esRoundStatus.PushDuration(L4D2Team_Survivor, g_esRoundStatus.GetDuration(L4D2Team_Infected));
		g_esRoundStatus.PushDuration(L4D2Team_Infected, g_esRoundStatus.GetDuration(L4D2Team_Infected));
	}

	if (g_bInScavengeRound)
		PrintRoundEndTimeData(g_esRoundStatus.IsInSecondHalf());

	g_flDefaultLossTime = 0.0;
	g_bInScavengeRound	= false;
	g_bIsRoundActivated = false;
}

void Event_RoundStart(Event hEvent, const char[] name, bool dontBroadcast)
{
	g_bInScavengeRound = true;
	g_flDefaultLossTime = 0.0;
	g_eEndType = QE_None;

	if (g_bInScavengeRound && g_esRoundStatus.IsInSecondHalf())	   // we are in second half of round now.
	{
		// record the loss condition deadline.
		if (g_esRoundStatus.GetScore(L4D2Team_Infected) == g_esRoundStatus.GetGoal() ||
			g_esRoundStatus.GetScore(L4D2Team_Infected) == 0)
			g_flDefaultLossTime = GameRules_GetPropFloat("m_flRoundStartTime") + g_esRoundStatus.GetDuration(L4D2Team_Infected) + SAFETY_BUFFER_TIME;
	}
}

void Event_GascanPourCompleted(Event hEvent, const char[] name, bool dontBroadcast)
{
	// we are in second half of round now.
	if (g_bInScavengeRound && g_esRoundStatus.IsInSecondHalf())	   
	{
		// to check if there is anymore gascans, which reduce the condition that survivor team complete the target.
		if (g_esRoundStatus.GetRemaining()> 0)	
		{
			// Same Target Compare Time. Survivors use less time to acheive the same target?
			if (g_esRoundStatus.GetScore(L4D2Team_Survivor) == g_esRoundStatus.GetScore(L4D2Team_Infected) &&
				g_esRoundStatus.GetDuration(L4D2Team_Survivor) < g_esRoundStatus.GetDuration(L4D2Team_Infected))
			{
				g_eEndType = QE_SameTargetCompareUsedTime;
				EndRoundEarlyOnTime();
			}
		}
	}
}

public void OnGameFrame()
{
	if (g_flDefaultLossTime != 0.0 && GetGameTime() > g_flDefaultLossTime && g_esRoundStatus.IsInSecondHalf())
	{
		// fully completed or totally lost?
		if (g_esRoundStatus.GetScore(L4D2Team_Infected) == g_esRoundStatus.GetGoal())
			g_eEndType = QE_AchievedTargetSetDeadLine;
		else if (g_esRoundStatus.GetScore(L4D2Team_Infected) == 0)
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
		g_esRoundStatus.FormatDuration(InfTime, sizeof(InfTime), L4D2Team_Infected);
		CPrintToChatAll("%t", "PrintRoundEndTime", g_esRoundStatus.GetRound(),
						g_esRoundStatus.GetScore(L4D2Team_Infected),
						InfTime);

		g_esRoundStatus.FormatDuration(SurTime, sizeof(SurTime), L4D2Team_Survivor);
		CPrintToChatAll("%t", "PrintRoundEndTimeInHalf", g_esRoundStatus.GetRound(),
						g_esRoundStatus.GetScore(L4D2Team_Survivor),
						SurTime);
	}
	else
	{
		char SurTime[128];
		g_esRoundStatus.FormatDuration(SurTime, sizeof(SurTime), L4D2Team_Survivor);
		CPrintToChatAll("%t", "PrintRoundEndTime", g_esRoundStatus.GetRound(),
						g_esRoundStatus.GetScore(L4D2Team_Survivor),
						SurTime);
	}
}

void EndRoundEarlyOnTime()
{
	if (!g_hcvarQuickEndSwitch.BoolValue)	 // check enabled quick end or not
		return;

	switch (g_eEndType)
	{
		case QE_SameTargetCompareUsedTime: CPrintToChatAll("%t", "RoundEndEarly_Type1");
		case QE_AchievedTargetSetDeadLine: CPrintToChatAll("%t", "RoundEndEarly_Type2");
		case QE_WhoSurvivedLonger: CPrintToChatAll("%t", "RoundEndEarly_Type3");
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

stock void LoadTranslation(const char[] translation)
{
	char sPath[PLATFORM_MAX_PATH], sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}
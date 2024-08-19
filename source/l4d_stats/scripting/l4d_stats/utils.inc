#if defined _l4d_stats_utils_included
	#endinput
#endif
#define _l4d_stats_utils_included

bool IsTeamGamemode()
{
	return IsGamemode("versus") || IsGamemode("teamversus") || IsGamemode("realismversus") || IsGamemode("scavenge") || IsGamemode("teamscavenge") || IsGamemode("mutation11") ||	 // Healthpackalypse!
		   IsGamemode("mutation12") ||																																				 // Realism Versus
		   IsGamemode("mutation13") ||																																				 // Follow the Liter
		   IsGamemode("mutation15") ||																																				 // Versus Survival
		   IsGamemode("mutation18") ||																																				 // Bleed Out Versus
		   IsGamemode("mutation19") ||																																				 // Taaannnkk!
		   IsGamemode("community3") ||																																				 // Riding My Survivor
		   IsGamemode("l4d1vs") ||																																					 // L4D1 Versus
		   IsGamemode("community6");																																				 // Confogl
}

int GetCurrentGamemodeID()
{
	char CurrentMode[16];
	g_hCvar_Gamemode.GetString(CurrentMode, sizeof(CurrentMode));

	return GetGamemodeID(CurrentMode);
}

bool ChangeRankPlayerTeam(int client, int team)
{
	if (GetClientTeam(client) == team) return true;

	if (team != TEAM_SURVIVORS)
	{
		// we can always swap to infected or spectator, it has no actual limit
		ChangeClientTeam(client, team);
		return true;
	}

	if (GetRankTeamHumanCount(team) == GetRankTeamMaxHumans(team))
		return false;

	int bot;
	// for survivors its more tricky
	for (bot = 1; bot < MaxClients + 1 && (!IsClientConnected(bot) || !IsFakeClient(bot) || (GetClientTeam(bot) != TEAM_SURVIVORS)); bot++) {}

	if (bot == MaxClients + 1)
	{
		char command[] = "sb_add";
		int	 flags	   = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		ServerCommand("sb_add");
		SetCommandFlags(command, flags);

		return false;
	}

	// have to do this to give control of a survivor bot
	SDKCall(g_hSDKCall_SetHumanSpec, bot, client);
	SDKCall(g_hSDCall_TakeOverBot, client, true);

	return true;
}

bool CheckDatabaseValidity(const char[] Prefix)
{
	if (!DoFastQuery(0, "SELECT * FROM %splayers WHERE 1 = 2", Prefix) ||
			!DoFastQuery(0, "SELECT * FROM %smaps WHERE 1 = 2", Prefix) ||
			!DoFastQuery(0, "SELECT * FROM %stimedmaps WHERE 1 = 2", Prefix) ||
			!DoFastQuery(0, "SELECT * FROM %ssettings WHERE 1 = 2", Prefix))
	{
		return false;
	}

	return true;
}

bool TimedMapsMenuInfoMarker(char[] Info, int MenuNumber)
{
	if (Info[0] == '\0' || MenuNumber < 2)
		return false;

	int Position = -1, TempPosition;
	for (int i = 0; i < MenuNumber; i++)
	{
		TempPosition = FindCharInString(Info[Position + 1], '\\');

		if (TempPosition < 0)
		{
			if (i + 2 == MenuNumber)
				return true;
			else
				return false;
		}

		Position += 1 + TempPosition;
		if (i + 2 >= MenuNumber)
		{
			Info[Position] = '\0';
			return true;
		}
	}

	return false;
}

bool IsRankClientInGameHuman(int client)
{
	if (client > 0) return (IsClientInGame(client) && !IsFakeClient(client));
	return false;
}

int GetRankTeamHumanCount(int team)
{
	int humans = 0;

	for (int i = 1; i < MaxClients + 1; i++)
	{
		if (IsRankClientInGameHuman(i) && GetClientTeam(i) == team)
			humans++;
	}

	return humans;
}

int GetRankTeamMaxHumans(int team)
{
	switch (team)
	{
		case TEAM_SURVIVORS: return g_hCvar_SurvivorLimit.IntValue;
		case TEAM_INFECTED: return g_hCvar_InfectedLimit.IntValue;
		case TEAM_SPECTATORS: return MaxClients;
	}

	return -1;
}

void GetClientRankAuthString(int client, char[] auth, int maxlength)
{
	if (g_hCvar_Lan.IntValue)
	{
		GetClientAuthId(client, AuthId_Steam2, auth, maxlength);
		if (!StrEqual(auth, "BOT", false))
			GetClientIP(client, auth, maxlength);
	}
	else
	{
		GetClientAuthId(client, AuthId_Steam2, auth, maxlength);
		if (StrEqual(auth, "STEAM_ID_LAN", false))
			GetClientIP(client, auth, maxlength);
	}
}

void StatsPrintToChatAll(const char[] Message, any...)
{
	char FormattedMessage[MAX_MESSAGE_WIDTH];
	VFormat(FormattedMessage, sizeof(FormattedMessage), Message, 2);

	StatsPrintToChatAllPreFormatted(FormattedMessage);
}

void StatsPrintToChatAll2(bool Forced, const char[] Message, any...)
{
	char FormattedMessage[MAX_MESSAGE_WIDTH];
	VFormat(FormattedMessage, sizeof(FormattedMessage), Message, 2);

	StatsPrintToChatAllPreFormatted2(Forced, FormattedMessage);
}

void StatsPrintToChatAllPreFormatted(const char[] Message)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			StatsPrintToChatPreFormatted(i, Message);
	}
}

void StatsPrintToChatAllPreFormatted2(bool Forced, const char[] Message)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			StatsPrintToChatPreFormatted2(i, Forced, Message);
	}
}

void StatsPrintToChat(int Client, const char[] Message, any...)
{
	// CHECK IF CLIENT HAS MUTED THE PLUGIN
	if (g_bClientRankMute[Client])
		return;

	char FormattedMessage[MAX_MESSAGE_WIDTH];
	VFormat(FormattedMessage, sizeof(FormattedMessage), Message, 3);
	StatsPrintToChatPreFormatted(Client, FormattedMessage);
}

void StatsPrintToChat2(int Client, bool Forced, const char[] Message, any...)
{
	// CHECK IF CLIENT HAS MUTED THE PLUGIN
	if (!Forced && g_bClientRankMute[Client])
		return;

	char FormattedMessage[MAX_MESSAGE_WIDTH];
	VFormat(FormattedMessage, sizeof(FormattedMessage), Message, 4);
	StatsPrintToChatPreFormatted2(Client, Forced, FormattedMessage);
}

void StatsPrintToChatPreFormatted(int Client, const char[] Message)
{
	StatsPrintToChatPreFormatted2(Client, false, Message);
}

void StatsPrintToChatPreFormatted2(int Client, bool Forced, const char[] Message)
{
	// CHECK IF CLIENT HAS MUTED THE PLUGIN
	if (!Forced && g_bClientRankMute[Client])
		return;

	PrintToChat(Client, "\x04[\x03RANK\x04] \x01%s", Message);
}

int StatsGetClientTeam(int client)
{
	if (client <= 0 || !IsClientConnected(client))
		return TEAM_UNDEFINED;

	if (IsFakeClient(client) || IsClientInGame(client))
		return GetClientTeam(client);

	return TEAM_UNDEFINED;
}

void SetTimeLabel(float TheSeconds, char[] TimeLabel, int maxsize)
{
	int	FlooredSeconds = RoundToFloor(TheSeconds);
	int	FlooredSecondsMod = FlooredSeconds % 60;
	float Seconds = TheSeconds - float(FlooredSeconds) + float(FlooredSecondsMod);
	int	Minutes	= (TheSeconds < 60.0 ? 0 : RoundToNearest(float(FlooredSeconds - FlooredSecondsMod) / 60));
	int	MinutesMod = Minutes % 60;
	int	Hours = (Minutes < 60 ? 0 : RoundToNearest(float(Minutes - MinutesMod) / 60));
	Minutes = MinutesMod;

	if (Hours > 0)
		Format(TimeLabel, maxsize, "%ih %im %.1fs", Hours, Minutes, Seconds);
	else if (Minutes > 0)
		Format(TimeLabel, maxsize, "%i min %.1f sec", Minutes, Seconds);
	else
		Format(TimeLabel, maxsize, "%.1f seconds", Seconds);
}

int GetCurrentDifficulty()
{
	char Difficulty[MAX_LINE_WIDTH];
	g_hCvar_Difficulty.GetString(Difficulty, sizeof(Difficulty));

	if (StrEqual(Difficulty, "normal", false)) return 1;
	else if (StrEqual(Difficulty, "hard", false)) return 2;
	else if (StrEqual(Difficulty, "impossible", false)) return 3;
	else return 0;
}

// Disable map timings when opposing team has human players. The time is too much depending on opposing team that is is comparable.
bool MapTimingEnabled()
{
	return (g_bMapTimingBlocked || g_iCurrentGamemodeID == GAMEMODE_COOP || g_iCurrentGamemodeID == GAMEMODE_SURVIVAL || g_iCurrentGamemodeID == GAMEMODE_REALISM || g_iCurrentGamemodeID == GAMEMODE_OTHERMUTATIONS);
}

// Print a chat message to a specific team instead of all players
void StatsPrintToChatTeam(int Team, const char[] Message, any...)
{
	char FormattedMessage[MAX_MESSAGE_WIDTH];
	VFormat(FormattedMessage, sizeof(FormattedMessage), Message, 3);

	int AnnounceToTeam = g_hCvar_AnnounceToTeam.IntValue;
	if (Team > 0 && AnnounceToTeam)
	{
		int ClientTeam;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			{
				ClientTeam = GetClientTeam(i);
				if (ClientTeam == Team || (ClientTeam == TEAM_SPECTATORS && AnnounceToTeam == 2))
					StatsPrintToChatPreFormatted(i, FormattedMessage);
			}
		}
	}
	else
		StatsPrintToChatAllPreFormatted(FormattedMessage);
}

bool IsClientIncapacitated(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0 || GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0;
}

bool IsClientAlive(int client)
{
	if (!IsClientConnected(client))
		return false;

	if (IsFakeClient(client)) return (GetClientHealth(client) > 0 && GetEntProp(client, Prop_Send, "m_lifeState") == 0);
	else if (!IsClientInGame(client)) return false;

	return IsPlayerAlive(client);
}

bool IsGamemode(const char[] Gamemode)
{
	if (StrContains(g_sCurrentGamemode, Gamemode, false) != -1) return true;
	return false;
}

int GetGamemodeID(const char[] Gamemode)
{
	if (StrEqual(Gamemode, "coop", false)) return GAMEMODE_COOP;
	else if (StrEqual(Gamemode, "survival", false)) return GAMEMODE_SURVIVAL;
	else if (StrEqual(Gamemode, "versus", false)) return GAMEMODE_VERSUS;
	else if (StrEqual(Gamemode, "teamversus", false) && g_hCvar_GameMode[GAMEMODE_TEAMVERSUS].BoolValue) return GAMEMODE_VERSUS;
	else if (StrEqual(Gamemode, "scavenge", false)) return GAMEMODE_SCAVENGE;
	else if (StrEqual(Gamemode, "teamscavenge", false) && g_hCvar_GameMode[GAMEMODE_TEAMSCAVENGE].BoolValue) return GAMEMODE_SCAVENGE;
	else if (StrEqual(Gamemode, "realism", false)) return GAMEMODE_REALISM;
	else if (StrEqual(Gamemode, "mutation12", false)) return GAMEMODE_REALISMVERSUS;
	else if (StrEqual(Gamemode, "teamrealismversus", false) && g_hCvar_GameMode[GAMEMODE_TEAMREALISMVERSUS].BoolValue) return GAMEMODE_REALISMVERSUS;
	else if (StrContains(Gamemode, "mutation", false) == 0 || StrContains(Gamemode, "community", false) == 0) return GAMEMODE_OTHERMUTATIONS;

	return -1;
}

bool IsGamemodeVersus()
{
	return (IsGamemode("versus") || (IsGamemode("teamversus") && g_hCvar_GameMode[GAMEMODE_TEAMVERSUS].BoolValue));
}
/*
IsGamemodeRealism()
{
	return IsGamemode("realism");
}

IsGamemodeRealismVersus()
{
	return IsGamemode("mutation12");
}

IsGamemodeScavenge()
{
	return IsGamemode("scavege") || (IsGamemode("teamscavege") && GetConVarBool(g_hCvar_GameMode[GAMEMODE_TEAMSCAVENGE],MMODE_TEAMSCAVENGE]));
}

IsGamemodeCoop()
{
	return IsGamemode("coop");
}
*/
int GetSurvivorKillScore()
{
	return ModifyScoreDifficultyFloat(g_hCvar_SurvivorDeathScore.IntValue, 0.75, 0.5, TEAM_INFECTED);
}

bool IsSingleTeamGamemode()
{
	if (g_iCurrentGamemodeID == GAMEMODE_SCAVENGE || g_iCurrentGamemodeID == GAMEMODE_VERSUS || g_iCurrentGamemodeID == GAMEMODE_REALISMVERSUS)
		return false;

	return true;
}

// Check that player the score is in the map score limits and return the value that is addable.
int AddScore(int Client, int Score)
{
	// ToDo: use g_hCvar_MaxPoints to check if the score is within the map limits
	g_iCurrentPoints[Client] += Score;

	// if (GetConVarBool(g_hCvar_AnnounceRankChange))
	//{
	// }

	return Score;
}

bool StatsDisabled(bool MapCheck = false)
{
	if (!g_hCvar_Enable.BoolValue)
		return true;

	if (InvalidGameMode())
		return true;

	if (!MapCheck && IsDifficultyEasy())
		return true;

	if (!MapCheck && CheckHumans())
		return true;

	if (!MapCheck && g_hCvar_Cheats.BoolValue)
		return true;

	if (!db)
		return true;

	return false;
}

bool IsDifficultyEasy()
{
	char Difficulty[MAX_LINE_WIDTH];
	g_hCvar_Difficulty.GetString(Difficulty, sizeof(Difficulty));

	if (StrEqual(Difficulty, "easy", false)) return true;
	return false;
}

bool InvalidGameMode()
{
	// Currently will always return False in Survival and Versus gamemodes.
	// This will be removed in a future version when stats for those versions work.

	if (g_iCurrentGamemodeID == GAMEMODE_COOP && (g_hCvar_GameMode[GAMEMODE_COOP].BoolValue)) return false;
	else if (g_iCurrentGamemodeID == GAMEMODE_SURVIVAL && (g_hCvar_GameMode[GAMEMODE_SURVIVAL].BoolValue)) return false;
	else if (g_iCurrentGamemodeID == GAMEMODE_VERSUS && (g_hCvar_GameMode[GAMEMODE_VERSUS].BoolValue)) return false;
	else if (g_iCurrentGamemodeID == GAMEMODE_SCAVENGE && (g_hCvar_GameMode[GAMEMODE_SCAVENGE].BoolValue)) return false;
	else if (g_iCurrentGamemodeID == GAMEMODE_REALISM && (g_hCvar_GameMode[GAMEMODE_REALISM].BoolValue)) return false;
	else if (g_iCurrentGamemodeID == GAMEMODE_REALISMVERSUS && (g_hCvar_GameMode[GAMEMODE_REALISMVERSUS].BoolValue)) return false;
	else if (g_iCurrentGamemodeID == GAMEMODE_OTHERMUTATIONS && (g_hCvar_GameMode[GAMEMODE_OTHERMUTATIONS].BoolValue)) return false;

	return true;
}

bool CheckHumans()
{
	int MinHumans  = g_hCvar_HumansNeeded.IntValue;
	int Humans	   = 0;
	int maxplayers = MaxClients;

	for (int i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
			Humans++;
	}

	if (Humans < MinHumans) return true;
	return false;
}

bool IsClientBot(int client)
{
	if (client == 0 || !IsClientConnected(client) || IsFakeClient(client))
		return true;

	char SteamID[MAX_LINE_WIDTH];
	GetClientRankAuthString(client, SteamID, sizeof(SteamID));

	if (StrEqual(SteamID, "BOT", false))
		return true;

	return false;
}

int ModifyScoreRealism(int BaseScore, int ClientTeam, bool ToCeil = true)
{
	if (g_bLeft4Dead2)
	{
		ConVar Multiplier;

		if (g_iCurrentGamemodeID == GAMEMODE_REALISM)
			Multiplier = g_hCvar_RealismMultiplier;
		else if (g_iCurrentGamemodeID == GAMEMODE_REALISMVERSUS)
		{
			if (ClientTeam == TEAM_SURVIVORS)
				Multiplier = g_hCvar_RealismVersusSurMultiplier;
			else if (ClientTeam == TEAM_INFECTED)
				Multiplier = g_hCvar_RealismVersusInfMultiplier;
			else
				return BaseScore;
		}
		else
			return BaseScore;

		if (ToCeil)
			BaseScore = RoundToCeil(Multiplier.FloatValue * BaseScore);
		else
			BaseScore = RoundToFloor(Multiplier.FloatValue * BaseScore);
	}

	return BaseScore;
}

int ModifyScoreDifficultyFloatNR(int BaseScore, float AdvMult, float ExpMult, int ClientTeam, bool ToCeil = true)
{
	return ModifyScoreDifficultyFloat(BaseScore, AdvMult, ExpMult, ClientTeam, ToCeil, false);
}

int ModifyScoreDifficultyFloat(int BaseScore, float AdvMult, float ExpMult, int ClientTeam, bool ToCeil = true, bool Reduction = true)
{
	if (BaseScore <= 0)
		return 0;

	char Difficulty[MAX_LINE_WIDTH];
	g_hCvar_Difficulty.GetString(Difficulty, sizeof(Difficulty));

	float ModifiedScore;

	if (StrEqual(Difficulty, "Hard", false)) ModifiedScore = BaseScore * AdvMult;
	else if (StrEqual(Difficulty, "Impossible", false)) ModifiedScore = BaseScore * ExpMult;
	else return ModifyScoreRealism(BaseScore, ClientTeam);

	int Score = 0;
	if (ToCeil) Score = RoundToCeil(ModifiedScore);
	else Score = RoundToFloor(ModifiedScore);

	if (ClientTeam == TEAM_SURVIVORS && Reduction)
		Score = GetMedkitPointReductionScore(Score);

	return ModifyScoreRealism(Score, ClientTeam, ToCeil);
}

// Score modifier without point reduction. Usable for minus points.
int ModifyScoreDifficultyNR(int BaseScore, int AdvMult, int ExpMult, int ClientTeam)
{
	return ModifyScoreDifficulty(BaseScore, AdvMult, ExpMult, ClientTeam, false);
}

int ModifyScoreDifficulty(int BaseScore, int AdvMult, int ExpMult, int ClientTeam, bool Reduction = true)
{
	char Difficulty[MAX_LINE_WIDTH];
	g_hCvar_Difficulty.GetString(Difficulty, sizeof(Difficulty));

	if (StrEqual(Difficulty, "hard", false)) BaseScore = BaseScore * AdvMult;
	if (StrEqual(Difficulty, "impossible", false)) BaseScore = BaseScore * ExpMult;

	if (ClientTeam == TEAM_SURVIVORS && Reduction)
		BaseScore = GetMedkitPointReductionScore(BaseScore);

	return ModifyScoreRealism(BaseScore, ClientTeam);
}

// Get Boomer points
int GetBoomerPoints(int VictimCount)
{
	if (VictimCount <= 0)
		return 0;

	return (g_hCvar_BoomerSuccessScore.IntValue * VictimCount);
}

int GetInfType(int Client)
{
	// Client > 0 && ClientTeam == TEAM_INFECTED checks are done by the caller
	int InfType = GetEntProp(Client, Prop_Send, "m_zombieClass");

	// Make the conversion so that everything gets stored in the correct fields
	if (g_bLeft4Dead)
	{
		if (InfType == INF_ID_WITCH_L4D1)
			return INF_ID_WITCH_L4D2;

		if (InfType == INF_ID_TANK_L4D1)
			return INF_ID_TANK_L4D2;
	}

	return InfType;
}

float GetMedkitPointReductionFactor()
{
	if (g_iMedkitsUsedCounter <= 0)
		return 1.0;

	float Penalty = g_hCvar_MedkitUsedPointPenalty.FloatValue;

	// If Penalty is set to ZERO: There is no reduction.
	if (Penalty <= 0.0)
		return 1.0;

	int PenaltyFree = -1;

	if (g_iCurrentGamemodeID == GAMEMODE_REALISM || g_iCurrentGamemodeID == GAMEMODE_REALISMVERSUS)
		PenaltyFree = g_hCvar_MedkitUsedRealismFree.IntValue;

	if (PenaltyFree < 0)
		PenaltyFree = g_hCvar_MedkitUsedFree.IntValue;

	if (PenaltyFree >= g_iMedkitsUsedCounter)
		return 1.0;

	Penalty *= g_iMedkitsUsedCounter - PenaltyFree;

	float PenaltyMax = g_hCvar_MedkitUsedPointPenaltyMax.FloatValue;

	if (Penalty > PenaltyMax)
		return 1.0 - PenaltyMax;

	return 1.0 - Penalty;
}

// Calculate the score with the medkit point reduction
int GetMedkitPointReductionScore(int Score, bool ToCeil = false)
{
	float ReductionFactor = GetMedkitPointReductionFactor();

	if (ReductionFactor == 1.0)
		return Score;

	if (ToCeil)
		return RoundToCeil(Score * ReductionFactor);
	else
		return RoundToFloor(Score * ReductionFactor);
}

int GetClientInfectedType(int Client)
{
	if (Client > 0 && GetClientTeam(Client) == TEAM_INFECTED)
		return GetInfType(Client);

	return 0;
}

bool DoFastQuery(int Client, const char[] Query, any ...)
{
	char FormattedQuery[4096];
	VFormat(FormattedQuery, sizeof(FormattedQuery), Query, 3);

	char Error[1024];

	if (!SQL_FastQuery(db, FormattedQuery))
	{
		if (SQL_GetError(db, Error, sizeof(Error)))
		{
			PrintToConsole(Client, "[RANK] Fast query failed! (Error = \"%s\") Query = \"%s\"", Error, FormattedQuery);
			LogError("Fast query failed! (Error = \"%s\") Query = \"%s\"", Error, FormattedQuery);
		}
		else
		{
			PrintToConsole(Client, "[RANK] Fast query failed! Query = \"%s\"", FormattedQuery);
			LogError("Fast query failed! Query = \"%s\"", FormattedQuery);
		}

		return false;
	}

	return true;
}

void FormatInGameMode(char[] sString, int maxlenth, bool bIsPanicEvent = false)
{
	if (!bIsPanicEvent)
	{
		switch (g_iCurrentGamemodeID)
		{
			case GAMEMODE_VERSUS: Format(sString, maxlenth, "points_survivors");
			case GAMEMODE_REALISM: Format(sString, maxlenth, "points_realism");
			case GAMEMODE_SURVIVAL: Format(sString, maxlenth, "points_survival");
			case GAMEMODE_SCAVENGE: Format(sString, maxlenth, "points_scavenge_survivors");
			case GAMEMODE_REALISMVERSUS: Format(sString, maxlenth, "points_realism_survivors");
			case GAMEMODE_OTHERMUTATIONS: Format(sString, maxlenth, "points_mutations");
			default:
			{
				Format(sString, maxlenth, "points");
			}
		}
	}
	else
	{
		switch (g_iCurrentGamemodeID)
		{
			case GAMEMODE_VERSUS: Format(sString, maxlenth, "points_survivors");
			case GAMEMODE_REALISM: Format(sString, maxlenth, "points_realism");
			case GAMEMODE_SCAVENGE: Format(sString, maxlenth, "points_scavenge_survivors");
			case GAMEMODE_REALISMVERSUS: Format(sString, maxlenth, "points_realism_survivors");
			case GAMEMODE_OTHERMUTATIONS: Format(sString, maxlenth, "points_mutations");
			default:
			{
				Format(sString, maxlenth, "points");
			}
		}
	}

}
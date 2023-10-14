#if defined _server_management_hours_limiter_included
 #endinput
#endif
#define _server_management_hours_limiter_included

/*
 * coded by TouchMe.
 **/

/* hours_limiter */
static ConVar
	hl_cvMinPlayedHours = null, hl_cvMaxPlayedHours = null, hl_cvMaxTryCheckPlayerHours = null;

static int hl_iClientTry[MAXPLAYERS + 1];

void HL_OnPluginStart()
{
	hl_cvMinPlayedHours = CreateConVar("sm_min_played_hours", "100.0", "Minimum number of hours allowed to play");
	hl_cvMaxPlayedHours = CreateConVar("sm_max_played_hours", "99999.0", "Maximum number of hours allowed to play");
	hl_cvMaxTryCheckPlayerHours = CreateConVar("sm_max_try_check_player_hours", "5", "Maximum number of attempts to check the played time");
}

void HL_OnClientPostAdminCheck(int iClient)
{
	if (!SteamWorks_IsConnected())
	{
		LogError("Steamworks: No Steam Connection!");
		return;
	}

	hl_iClientTry[iClient] = 0;

	TryCheckPlayerHours(iClient);
}

Action Timer_TryCheckPlayerHours(Handle hTimer, int iClient)
{
	TryCheckPlayerHours(iClient);
	return Plugin_Stop;
}

void TryCheckPlayerHours(int iClient)
{
	if (IsFakeClient(iClient) || !IsClientInGame(iClient)) {
		return;
	}

	if (++ hl_iClientTry[iClient] > GetConVarInt(hl_cvMaxTryCheckPlayerHours))
	{
		ServerCommand("sm_kick #%i \"Attempt #%d to determine the time played was unsuccessful\"", GetClientUserId(iClient), hl_iClientTry[iClient]);
		return;
	}

	if (!CheckPlayerHours(iClient)) {
		CreateTimer(1.0, Timer_TryCheckPlayerHours, iClient);
	}
}

bool CheckPlayerHours(int iClient)
{
	int iPlayedTime;
	bool bRequestStats = SteamWorks_RequestStats(iClient, APP_L4D2);
	bool bGetStatCell = SteamWorks_GetStatCell(iClient, "Stat.TotalPlayTime.Total", iPlayedTime);

	if (!bRequestStats || !bGetStatCell) {
		return false;
	}

	if (!iPlayedTime)
	{
		ServerCommand("sm_kick #%i \"Your game hours are hidden\"", GetClientUserId(iClient));
		return true;
	}

	float fHours = SecToHours(iPlayedTime);
	float fMinPlayedHours = GetConVarFloat(hl_cvMinPlayedHours);
	float fMaxPlayedHours = GetConVarFloat(hl_cvMaxPlayedHours);

	if (fHours < fMinPlayedHours) {
		ServerCommand("sm_kick #%i \"Must have more than %.1f hours of play\"", GetClientUserId(iClient), fMinPlayedHours);
	}

	else if (fHours > fMaxPlayedHours) {
		ServerCommand("sm_kick #%i \"There should be no more than %.1f hours of play\"", GetClientUserId(iClient), fMaxPlayedHours);
	}

	return true;
}
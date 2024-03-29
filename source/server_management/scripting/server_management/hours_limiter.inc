#if defined _server_management_hours_limiter_included
 #endinput
#endif
#define _server_management_hours_limiter_included

#define TRANSLATIONS_HOURSLIMITER "hours_limiter.phrases"

/*
 * originally coded by TouchMe.
 * implemented by blueblur.
 **/

/* hours_limiter */
static ConVar
	hl_cvMinPlayedHours = null, hl_cvMaxPlayedHours = null, hl_cvMaxTryCheckPlayerHours = null, hl_cvKickHiddenHours = null;

static GlobalForward hl_fwOnVerifiedHiddenHoursPlayer = null;

static int hl_iClientTry[MAXPLAYERS + 1];

void HL_APL()
{
	hl_fwOnVerifiedHiddenHoursPlayer = new GlobalForward("OnVerifiedHiddenHoursPlayer", ET_Ignore, Param_Cell);
}

void HL_OnPluginStart()
{
	LoadTranslations(TRANSLATIONS_HOURSLIMITER);

	hl_cvMinPlayedHours = CreateConVar("sm_min_played_hours", "100.0", "Minimum number of hours allowed to play");
	hl_cvMaxPlayedHours = CreateConVar("sm_max_played_hours", "99999.0", "Maximum number of hours allowed to play");
	hl_cvMaxTryCheckPlayerHours = CreateConVar("sm_max_try_check_player_hours", "5", "Maximum number of attempts to check the played time");
	hl_cvKickHiddenHours = CreateConVar("sm_kick_hidden_hours", "1", "Kick hidden hours?");
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
	if (IsFakeClient(iClient) || !IsClientInGame(iClient))
		return;

	if (++ hl_iClientTry[iClient] > hl_cvMaxTryCheckPlayerHours.IntValue)
	{
		KickClient(iClient, "%t", "TryCheckPlayerHours", hl_iClientTry[iClient]);
		return;
	}

	if (!CheckPlayerHours(iClient))
		CreateTimer(1.0, Timer_TryCheckPlayerHours, iClient);
}

bool CheckPlayerHours(int iClient)
{
	int iPlayedTime;
	bool bRequestStats = SteamWorks_RequestStats(iClient, APP_L4D2);
	bool bGetStatCell = SteamWorks_GetStatCell(iClient, "Stat.TotalPlayTime.Total", iPlayedTime);
	bool bPassHidden = false;

	if (!bRequestStats || !bGetStatCell)
		return false;

	if (!iPlayedTime && hl_cvKickHiddenHours.BoolValue)
	{
		KickClient(iClient, "%t", "KickHiddenHours");
		Call_StartForward(hl_fwOnVerifiedHiddenHoursPlayer);
		Call_PushCell(iClient);
		Call_Finish();
		return true;
	}
	else bPassHidden = true

	float fHours = SecToHours(iPlayedTime);
	float fMinPlayedHours = hl_cvMinPlayedHours.FloatValue;
	float fMaxPlayedHours = hl_cvMaxPlayedHours.FloatValue;

	if (!bPassHidden)
	{
		if (fHours < fMinPlayedHours) KickClient(iClient, "%t", "KickUnDesiredHoursMin", fMinPlayedHours);
		else if (fHours > fMaxPlayedHours) KickClient(iClient, "%t", "KickUnDesiredHoursMax", fMaxPlayedHours);
	}

	return true;
}
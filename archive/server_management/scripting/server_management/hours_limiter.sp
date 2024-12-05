#if defined _server_management_hours_limiter_included
 #endinput
#endif
#define _server_management_hours_limiter_included

/*
 * originally coded by TouchMe.
 * implemented by blueblur.
 **/

/* hours_limiter */
static ConVar
	g_hCvar_cvMinPlayedHours = null, g_hCvar_cvMaxPlayedHours = null, g_hCvar_cvMaxTryCheckPlayerHours = null, g_hCvar_cvKickHiddenHours = null;

static GlobalForward g_hFWD_OnVerifiedHiddenHoursPlayer = null;

static int g_iClientTry[MAXPLAYERS + 1];

void _hours_limiter_AskPluginLoad2()
{
	g_hFWD_OnVerifiedHiddenHoursPlayer = new GlobalForward("OnVerifiedHiddenHoursPlayer", ET_Ignore, Param_Cell);
}

void _hours_limiter_OnPluginStart()
{
	LoadTranslation("server_management.hours_limiter.phrases")
	g_hCvar_cvMinPlayedHours = CreateConVar("sm_min_played_hours", "100.0", "Minimum number of hours allowed to play");
	g_hCvar_cvMaxPlayedHours = CreateConVar("sm_max_played_hours", "99999.0", "Maximum number of hours allowed to play");
	g_hCvar_cvMaxTryCheckPlayerHours = CreateConVar("sm_max_try_check_player_hours", "5", "Maximum number of attempts to check the played time");
	g_hCvar_cvKickHiddenHours = CreateConVar("sm_kick_hidden_hours", "1", "Kick hidden hours?");
}

void _hours_limiter_OnClientPostAdminCheck(int iClient)
{
	if (!IsClientInGame(iClient) || IsFakeClient(iClient)) {
		return;
	}

	if (!SteamWorks_IsConnected())
	{
		LogError("Steamworks: No Steam Connection!");
		return;
	}

	g_iClientTry[iClient] = 0;
	TryCheckPlayerHours(iClient);
}

static void Timer_TryCheckPlayerHours(Handle hTimer, int iClient)
{
	TryCheckPlayerHours(iClient);
}

static void TryCheckPlayerHours(int iClient)
{
	if (IsFakeClient(iClient) || !IsClientInGame(iClient))
		return;

	if (++ g_iClientTry[iClient] > g_hCvar_cvMaxTryCheckPlayerHours.IntValue)
	{
		KickClient(iClient, "%T", "TryCheckPlayerHours", g_iClientTry[iClient], iClient);
		return;
	}

	if (!HL_CheckPlayerHours(iClient))
		CreateTimer(1.0, Timer_TryCheckPlayerHours, iClient);
}

static bool HL_CheckPlayerHours(int iClient)
{
	int iPlayedTime;
	bool bRequestStats = SteamWorks_RequestStats(iClient, APP_L4D2);
	bool bGetStatCell = SteamWorks_GetStatCell(iClient, "Stat.TotalPlayTime.Total", iPlayedTime);

	if (!bRequestStats || !bGetStatCell){
		return false;
	}

	if (!iPlayedTime && g_hCvar_cvKickHiddenHours.BoolValue)
	{
		KickClient(iClient, "%T", "KickHiddenHours", iClient);
		Call_StartForward(g_hFWD_OnVerifiedHiddenHoursPlayer);
		Call_PushCell(iClient);
		Call_Finish();
		return true;
	}

	float fHours = SecToHours(iPlayedTime);
	float fMinPlayedHours = g_hCvar_cvMinPlayedHours.FloatValue;
	float fMaxPlayedHours = g_hCvar_cvMaxPlayedHours.FloatValue;

	if (iPlayedTime > 0)
	{
		if (fHours < fMinPlayedHours) KickClient(iClient, "%T", "KickUnDesiredHoursMin", fMinPlayedHours, iClient);
		else if (fHours > fMaxPlayedHours) KickClient(iClient, "%T", "KickUnDesiredHoursMax", fMaxPlayedHours, iClient);
	}

	return true;
}
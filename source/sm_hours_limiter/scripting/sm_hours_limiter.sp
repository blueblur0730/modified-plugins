#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <SteamWorks>

/*
 * originally coded by TouchMe.
 * implemented by blueblur.
 **/

/* hours_limiter */
ConVar
	g_hCvar_MinPlayedHours,
	g_hCvar_MaxPlayedHours,
	g_hCvar_MaxTryCheckPlayerHours,
	g_hCvar_KickHiddenHours,
	g_hCvar_ShouldKickMaxTry,
	g_hCvar_APPID;

GlobalForward g_hFWD_OnVerifiedHiddenHoursPlayer;

#define PLUGIN_VERSION "r1.0"

public Plugin myinfo =
{
	name = "[ANY] Hours Limiter",
	author = "TouchMe, blueblur, stars (Majestymo)",
	description = "Invited by hours only.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

int g_iClientTry[MAXPLAYERS + 1];

public APLRes AskPluginLoad2()
{
	g_hFWD_OnVerifiedHiddenHoursPlayer = new GlobalForward("OnVerifiedHiddenHoursPlayer", ET_Ignore, Param_Cell);
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslation("sm_hours_limiter.phrases");
	CreateConVar("sm_hours_limiter_version", PLUGIN_VERSION, "Advertisement version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_hCvar_MinPlayedHours		   = CreateConVar("sm_min_played_hours", "100.0", "Minimum number of hours allowed to play");
	g_hCvar_MaxPlayedHours		   = CreateConVar("sm_max_played_hours", "99999.0", "Maximum number of hours allowed to play");
	g_hCvar_MaxTryCheckPlayerHours = CreateConVar("sm_max_try_check_player_hours", "10", "Maximum number of attempts to check the played time");
	g_hCvar_KickHiddenHours		   = CreateConVar("sm_kick_hidden_hours", "1", "Kick hidden hours?");
	g_hCvar_ShouldKickMaxTry	   = CreateConVar("sm_should_kick_max_try", "0", "Should kick when max try check player hours?");
	g_hCvar_APPID				   = CreateConVar("sm_hours_limiter_appid", "550", "AppID of the game you want to check the played time of");
}

public void OnClientPostAdminCheck(int iClient)
{
	if (!IsClientInGame(iClient) || IsFakeClient(iClient))
		return;
	
	if (!SteamWorks_IsConnected())
	{
		LogError("Steamworks: No Steam Connection!");
		return;
	}

	g_iClientTry[iClient] = 0;
	TryCheckPlayerHours(iClient);
}

void Timer_TryCheckPlayerHours(Handle hTimer, int iClient)
{
	TryCheckPlayerHours(iClient);
}

void TryCheckPlayerHours(int iClient)
{
	if (IsFakeClient(iClient) || !IsClientInGame(iClient))
		return;

	if (++g_iClientTry[iClient] > g_hCvar_MaxTryCheckPlayerHours.IntValue && g_hCvar_ShouldKickMaxTry.BoolValue)
	{
		KickClient(iClient, "%T", "TryCheckPlayerHours", iClient, g_iClientTry[iClient]);
		g_iClientTry[iClient] = 0;
		return;
	}

	if (!HL_CheckPlayerHours(iClient))
		CreateTimer(1.0, Timer_TryCheckPlayerHours, iClient);
}

bool HL_CheckPlayerHours(int iClient)
{
	int	 iPlayedTime;
	bool bRequestStats = SteamWorks_RequestStats(iClient, g_hCvar_APPID.IntValue);
	bool bGetStatCell  = SteamWorks_GetStatCell(iClient, "Stat.TotalPlayTime.Total", iPlayedTime);

	if (!bRequestStats || !bGetStatCell)
		return false;
	
	if (!iPlayedTime && g_hCvar_KickHiddenHours.BoolValue)
	{
		KickClient(iClient, "%T", "KickHiddenHours", iClient);
		Call_StartForward(g_hFWD_OnVerifiedHiddenHoursPlayer);
		Call_PushCell(iClient);
		Call_Finish();
		return true;
	}

	float fHours		  = SecToHours(iPlayedTime);
	float fMinPlayedHours = g_hCvar_MinPlayedHours.FloatValue;
	float fMaxPlayedHours = g_hCvar_MaxPlayedHours.FloatValue;

	if (iPlayedTime > 0)
	{
		if (fHours < fMinPlayedHours) KickClient(iClient, "%T", "KickUnDesiredHoursMin", iClient, fMinPlayedHours);
		else if (fHours > fMaxPlayedHours) KickClient(iClient, "%T", "KickUnDesiredHoursMax", iClient, fMaxPlayedHours);
		g_iClientTry[iClient] = 0;
	}

	return true;
}

stock void LoadTranslation(const char[] translation)
{
	char sPath[PLATFORM_MAX_PATH], sName[PLATFORM_MAX_PATH];
	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}

stock float SecToHours(int iSeconds)
{
	float fHours = float(iSeconds) / 3600;
	return fHours;
}
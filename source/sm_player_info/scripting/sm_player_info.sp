#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <geoip>

#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>

enum DisconnectType
{
	TYPE_NONE,
	TYPE_CONNECTION_REJECTED,
	TYPE_TIMED_OUT,
	TYPE_BY_CONSOLE,
	TYPE_BY_USER,
	TYPE_HIGH_PING,
	TYPE_NO_STEAM_LOGEN,
	TYPE_ACCOUNT_BEING_USED,
	TYPE_CONNECTION_LOST,
	TYPE_NOT_OWNER,
	TYPE_VALIDATION_REJECTED,
	TYPE_CERTIFICATE_LENGTH,
	TYPE_PURE_SERVER
}

ConVar
	g_hCvar_AnnounceType, 
	g_hCvar_EnableDisconnect, 
	g_hCvar_MaxTryPlayerInfo,
	g_hCvar_ShouldBlockIdleMsg,
	g_hCvar_APPID;

int g_iAAnnounceType = 0;
int g_iClientTry[MAXPLAYERS + 1];
bool g_bSteamWorksAvailable = false;
bool g_bLerpMonitorAvailable = false;

GlobalForward g_hFWD_OnGetPlayTime = null;

#define PLUGIN_VERSION "r1.0"

public Plugin myinfo =
{
	name = "[ANY/L4D2] Player Info",
	author = "TouchMe, blueblur, stars (Majestymo)",
	description = "Query player's game time and id, show connect message, block idle message.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_hFWD_OnGetPlayTime = new GlobalForward("OnGetPlayerHours", ET_Event, Param_Cell, Param_Cell);
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslation("sm_player_info.phrases");

	CreateConVar("sm_player_info_version", PLUGIN_VERSION, "Plugin version.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_hCvar_AnnounceType		= CreateConVar("sm_player_info_announce_type", "3", "Announce type. 0=none, 1=add geoip, 2=add playtime, 3=add both.");
	g_hCvar_EnableDisconnect 	= CreateConVar("sm_player_info_enable_disconnect", "1", "Enable custom disconnect message");
	g_hCvar_ShouldBlockIdleMsg 	= CreateConVar("sm_player_info_block_idle_message", "1", "Block idle message");
	g_hCvar_MaxTryPlayerInfo 	= CreateConVar("sm_player_info_try_check_player_time", "10", "Maximum number of attempts to check the played time");
	g_hCvar_APPID				= CreateConVar("sm_player_info_appid", "550", "APP ID for requesting.");

	g_hCvar_AnnounceType.AddChangeHook(OnCvarChanged);
	OnCvarChanged(null, "", "");

	// remove notification.
	HookEvent("player_disconnect", Event_PlayerDisconnect_Pre, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_PlayerDisconnect_Post, EventHookMode_Post);
	HookUserMessage(GetUserMessageId("TextMsg"), TextMsg, true);

	RegConsoleCmd("sm_playerinfo", Cmd_Info);
}

public void OnAllPluginsLoaded() 
{ 
	g_bSteamWorksAvailable = LibraryExists("SteamWorks");
	g_bLerpMonitorAvailable = LibraryExists("lerpmonitor");
}

public void OnLibraryAdded(const char[] name)
{ 
	if (StrEqual(name, "SteamWorks")) g_bSteamWorksAvailable = true;
	if (StrEqual(name, "lerpmonitor")) g_bLerpMonitorAvailable = true;
}

public void OnLibraryRemoved(const char[] name)
{ 
	if (StrEqual(name, "SteamWorks")) g_bSteamWorksAvailable = false;
	if (StrEqual(name, "lerpmonitor")) g_bLerpMonitorAvailable = false;
}

void OnCvarChanged(ConVar convar, const char[] oldvalue, const char[] newvalue)
{
	g_iAAnnounceType = g_hCvar_AnnounceType.IntValue;
}

public void SteamWorks_OnValidateClient(int iAuthId)
{
	if (!g_bSteamWorksAvailable)
		return;

	int iClient = GetClientFromSteamID(iAuthId);

	if (!IsValidClient(iClient))
		return;

	SteamWorks_RequestStats(iClient, g_hCvar_APPID.IntValue);
}

public void OnClientConnected(int iClient)
{
	if (IsValidClient(iClient))
		return;

	char sName[128];
	GetClientName(iClient, sName, sizeof(sName));
	CPrintToChatAll("%t", "Connecting", sName);
}

public void OnClientPutInServer(int iClient)
{
	if (!IsClientInGame(iClient) || IsFakeClient(iClient))
		return;

	g_iClientTry[iClient] = 0;

	char  sName[128];
	GetClientName(iClient, sName, sizeof(sName));

	char IP[16];
	GetClientIP(iClient, IP, sizeof(IP));

	float fLerpTime = GetLerpTime(iClient) * 1000;

	bool bGeo = false;
	char ccode[3];
	if (g_iAAnnounceType == 1 || g_iAAnnounceType == 3)
		bGeo = GeoipCode2(IP, ccode);
	
	if ((g_iAAnnounceType == 2 || g_iAAnnounceType == 3) && g_bSteamWorksAvailable)
	{
		if (!SteamWorks_IsConnected())
		{
			LogError("Steamworks: No Steam Connection!");

			char sCountry[32];
			if (bGeo) Format(sCountry, sizeof(sCountry), "[{olive}%s{default}]", ccode);
			CPrintToChatAll("%t", "Connected", sName, fLerpTime, bGeo ? sCountry : "", "");
		}
		else
		{
			g_iClientTry[iClient] = 0;
			ShowPlayerInfo(iClient, bGeo, ccode);
		}

		// gotta go another.
		return;
	}

	char sCountry[32];
	if (bGeo) Format(sCountry, sizeof(sCountry), "[{olive}%s{default}]", ccode);
	CPrintToChatAll("%t", "Connected", sName, fLerpTime, bGeo ? sCountry : "", "");
}

void ShowPlayerInfo(int iClient, bool bGeo = false, const char[] ccode = "")
{
	// failed to retreive, abort.
	if (++g_iClientTry[iClient] > g_hCvar_MaxTryPlayerInfo.IntValue) 
	{
		if (IsValidClient(iClient) && !IsFakeClient(iClient)) 
		{
			char  sName[128];
			char sCountry[32];
			float fLerpTime = GetLerpTime(iClient) * 1000;
			GetClientName(iClient, sName, sizeof(sName));
			if (bGeo) Format(sCountry, sizeof(sCountry), "[{olive}%s{default}]", ccode);
			CPrintToChatAll("%t", "Connected", sName, fLerpTime, bGeo ? sCountry : "", "");
		}

		g_iClientTry[iClient] = 0;
		return;
	}

	DataPack dp = new DataPack();
	dp.WriteCell(iClient);
	dp.WriteCell(bGeo);
	dp.WriteString(ccode);
	if (!CheckPlayerInfo(dp)) 
		CreateTimer(0.1, Timer_TryShowPlayerInfo, dp);
}

void Timer_TryShowPlayerInfo(Handle hTimer, DataPack dp)
{
	char ccode[3];
	dp.Reset();
	int iClient = dp.ReadCell();
	bool bGeo = dp.ReadCell();
	dp.ReadString(ccode, sizeof(ccode));
	delete dp;

	if (!IsClientInGame(iClient) || IsFakeClient(iClient) ) 
		return;

	ShowPlayerInfo(iClient, bGeo, ccode);
}

bool CheckPlayerInfo(DataPack dp)
{
	char ccode[3];
	dp.Reset();
	int iClient = dp.ReadCell();
	bool bGeo = dp.ReadCell();
	dp.ReadString(ccode, sizeof(ccode));

	int	 iPlayedTime;
	bool bRequestStats = SteamWorks_RequestStats(iClient, g_hCvar_APPID.IntValue);
	bool bGetStatCell  = SteamWorks_GetStatCell(iClient, "Stat.TotalPlayTime.Total", iPlayedTime);

	if (!bRequestStats || !bGetStatCell) 
		return false;

	delete dp;

	// only call the success callback.
	Call_StartForward(g_hFWD_OnGetPlayTime);
	Call_PushCell(iClient);
	Call_PushCell(SecToHours(iPlayedTime));
	Call_Finish();

	char  sName[128];
	float fLerpTime;
		
	fLerpTime = GetLerpTime(iClient) * 1000;
	GetClientName(iClient, sName, sizeof(sName));

	char sBuffer[128], sCountry[32];
	if (bGeo) Format(sCountry, sizeof(sCountry), "[{olive}%s{default}]", ccode);
	Format(sBuffer, sizeof(sBuffer), " (Hours: {olive}%.02f{default}h)", SecToHours(iPlayedTime));
	CPrintToChatAll("%t", "Connected", sName, fLerpTime, bGeo ? sCountry : "", sBuffer);

	return true;
}

Action Event_PlayerDisconnect_Pre(Event hEvent, const char[] sName, bool dontBroadcast)
{
	char reason[PLATFORM_MAX_PATH], message[PLATFORM_MAX_PATH];
	int	 iClient = GetClientOfUserId(hEvent.GetInt("userid"));

	// this will only block the original disconnect message.
	if (!g_hCvar_EnableDisconnect.BoolValue)
		return Plugin_Continue;

	if (!IsValidClient(iClient))
		return Plugin_Handled;

	hEvent.GetString("reason", reason, sizeof(reason));
	GetDisconnectString(reason, message, sizeof(message));
	CPrintToChatAll("%t", "Disconnected", iClient, message);

	return Plugin_Handled;
}

void Event_PlayerDisconnect_Post(Event hEvent, const char[] sName, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));

	if  (client <= 0 || client > MaxClients)
		return;

	if (!IsClientInGame(client) || IsFakeClient(client))
		return;

	g_iClientTry[client] = 0;
}

Action TextMsg(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init) 
{
	if (!g_hCvar_ShouldBlockIdleMsg.BoolValue)
		return Plugin_Continue;

	char sMsg[254];
	msg.ReadString(sMsg, sizeof sMsg);

	if (StrContains(sMsg, "L4D_idle_spectator") != -1)
		return Plugin_Handled;

	return Plugin_Continue;
}

Action Cmd_Info(int iClient, int iArgs)
{
	if (!IsValidClient(iClient))
		return Plugin_Handled;

	int iTotalPlayers = 0;
	int[] iPlayers	  = new int[MaxClients];

	for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if (!IsClientInGame(iPlayer)
			|| IsFakeClient(iPlayer))
		{
			continue;
		}

		iPlayers[iTotalPlayers++] = iPlayer;
	}

	if (!iTotalPlayers)
		return Plugin_Handled;

	char sBracketStart[16];
	FormatEx(sBracketStart, sizeof(sBracketStart), "%T", "BRACKET_START", iClient);

	char sBracketMiddle[16];
	FormatEx(sBracketMiddle, sizeof(sBracketMiddle), "%T", "BRACKET_MIDDLE", iClient);

	char sBracketEnd[16];
	FormatEx(sBracketEnd, sizeof(sBracketEnd), "%T", "BRACKET_END", iClient);

	CReplyToCommand(iClient, "%s%T", sBracketStart, "HEADER", iClient);

	char  sSteamID[64];
	int	  iPlayer, iPlayedTime = 0;
	float fLerpTime, iMin, iMax;

	if (g_bLerpMonitorAvailable)
	{
		iMin = FindConVar("sm_min_lerp").FloatValue;
		iMax = FindConVar("sm_max_lerp").FloatValue;
	}

	char sPlayedTime[32];
	for (int iItem = 0; iItem < iTotalPlayers; iItem++)
	{
		char ccode[3];
		iPlayer = iPlayers[iItem];

		if (g_bSteamWorksAvailable)
			SteamWorks_GetStatCell(iPlayer, "Stat.TotalPlayTime.Total", iPlayedTime);

		fLerpTime = GetLerpTime(iPlayer) * 1000;
		GetClientAuthId(iPlayer, AuthId_Steam2, sSteamID, sizeof(sSteamID));
		
		!iPlayedTime ? 
		Format(sPlayedTime, sizeof(sPlayedTime), "%T", "Unknown_PlayedTime", iClient) :
		Format(sPlayedTime, sizeof(sPlayedTime), "%.02f", SecToHours(iPlayedTime));

		char IP[32];
		GetClientIP(iPlayer, IP, sizeof(IP));

		if (!GeoipCode2(IP, ccode))
			strcopy(ccode, sizeof(ccode), "[x]");

		CReplyToCommandEx(iClient, iPlayer, "%s%t", (iItem + 1) == iTotalPlayers ? sBracketEnd : sBracketMiddle,
						  "INFO", iPlayer, ccode,
						  (g_bLerpMonitorAvailable && ((iMin < fLerpTime) && (fLerpTime < iMax))) ? "{olive}" : "{green}",
						  fLerpTime, sPlayedTime, sSteamID);
	}

	return Plugin_Handled;
}

void GetDisconnectString(char[] reason, char[] message, int maxlen)
{
	switch (GetDisconnectType(reason))
	{
		case TYPE_NONE:					strcopy(message, maxlen, "TYPE_NONE");
		case TYPE_CONNECTION_REJECTED:	strcopy(message, maxlen, "TYPE_CONNECTION_REJECTED");
		case TYPE_TIMED_OUT:			strcopy(message, maxlen, "TYPE_TIMED_OUT");
		case TYPE_BY_CONSOLE:			strcopy(message, maxlen, "TYPE_BY_CONSOLE");
		case TYPE_BY_USER:				strcopy(message, maxlen, "TYPE_BY_USER");
		case TYPE_HIGH_PING:			strcopy(message, maxlen, "TYPE_HIGH_PING");
		case TYPE_NO_STEAM_LOGEN:		strcopy(message, maxlen, "TYPE_NO_STEAM_LOGEN");
		case TYPE_ACCOUNT_BEING_USED:	strcopy(message, maxlen, "TYPE_ACCOUNT_BEING_USED");
		case TYPE_CONNECTION_LOST:		strcopy(message, maxlen, "TYPE_CONNECTION_LOST");
		case TYPE_NOT_OWNER:			strcopy(message, maxlen, "TYPE_NOT_OWNER");
		case TYPE_VALIDATION_REJECTED:	strcopy(message, maxlen, "TYPE_VALIDATION_REJECTED");
		case TYPE_CERTIFICATE_LENGTH:	strcopy(message, maxlen, "TYPE_CERTIFICATE_LENGTH");
		case TYPE_PURE_SERVER:			strcopy(message, maxlen, "TYPE_PURE_SERVER");
	}
}

DisconnectType GetDisconnectType(char[] reason)
{
	if (StrContains(reason, "connection rejected", false) != -1) return TYPE_CONNECTION_REJECTED;
	else if (StrContains(reason, "timed out", false) != -1) return TYPE_TIMED_OUT;
	else if (StrContains(reason, "by console", false) != -1) return TYPE_BY_CONSOLE;
	else if (StrContains(reason, "by user", false) != -1) return TYPE_BY_USER;
	else if (StrContains(reason, "ping is too high", false) != -1) return TYPE_HIGH_PING;
	else if (StrContains(reason, "No Steam logon", false) != -1) return TYPE_NO_STEAM_LOGEN;
	else if (StrContains(reason, "Steam account is being used in another", false) != -1) return TYPE_ACCOUNT_BEING_USED;
	else if (StrContains(reason, "Steam Connection lost", false) != -1) return TYPE_CONNECTION_LOST;
	else if (StrContains(reason, "This Steam account does not own this game", false) != -1) return TYPE_NOT_OWNER;
	else if (StrContains(reason, "Validation Rejected", false) != -1) return TYPE_VALIDATION_REJECTED;
	else if (StrContains(reason, "Certificate Length", false) != -1) return TYPE_CERTIFICATE_LENGTH;
	else if (StrContains(reason, "Pure server", false) != -1) return TYPE_PURE_SERVER;

	return TYPE_NONE;
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client));
}

stock int GetClientFromSteamID(int authid)
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientConnected(iClient) || GetSteamAccountID(iClient) != authid)
			continue;

		return iClient;
	}

	return -1;
}

stock float SecToHours(int iSeconds)
{
	float fHours = float(iSeconds) / 3600;
	return fHours;
}

stock float max(float a, float b)
{
	return (a > b) ? a : b;
}

stock float clamp(float inc, float low, float high)
{
	return (inc > high) ? high : ((inc < low) ? low : inc);
}

stock float GetLerpTime(int iClient)
{
	char  buffer[32];
	float fLerpRatio, fLerpAmount, fUpdateRate;

	ConVar 
		cvMinUpdateRate = null, cvMaxUpdateRate = null,
	 	cvMinInterpRatio = null, cvMaxInterpRatio = null;

	cvMinUpdateRate		= FindConVar("sv_minupdaterate");
	cvMaxUpdateRate		= FindConVar("sv_maxupdaterate");
	cvMinInterpRatio 	= FindConVar("sv_client_min_interp_ratio");
	cvMaxInterpRatio 	= FindConVar("sv_client_max_interp_ratio");

	if (GetClientInfo(iClient, "cl_interp_ratio", buffer, sizeof(buffer)))
		fLerpRatio = StringToFloat(buffer);

	if (cvMinUpdateRate != null && cvMaxInterpRatio != null && cvMinInterpRatio.FloatValue != -1.0)
		fLerpRatio = clamp(fLerpRatio, cvMinInterpRatio.FloatValue, cvMaxInterpRatio.FloatValue);

	if (GetClientInfo(iClient, "cl_interp", buffer, sizeof(buffer)))
		fLerpAmount = StringToFloat(buffer);

	if (GetClientInfo(iClient, "cl_updaterate", buffer, sizeof(buffer)))
		fUpdateRate = StringToFloat(buffer);

	fUpdateRate = clamp(fUpdateRate, cvMinUpdateRate.FloatValue, cvMaxUpdateRate.FloatValue);

	return max(fLerpAmount, fLerpRatio / fUpdateRate);
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
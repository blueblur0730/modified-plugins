#if defined _server_management_player_info_included
	#endinput
#endif
#define _server_management_player_info_included

/*
 * originally coded by TouchMe.
 * implemented by blueblur.
 **/

#define TRANSLATIONS_PLAYERINFO "player_info.phrases"

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

/* native cvars */
static ConVar
	pi_cvMinUpdateRate = null,
	pi_cvMaxUpdateRate = null, pi_cvMinInterpRatio = null, pi_cvMaxInterpRatio = null;

/* player_info */
static ConVar
	 pi_cvEnableGeoip = null, pi_cvEnableDisconnect = null;

static char
	 ip[MAXPLAYERS + 1][64];

static GlobalForward pi_fwOnGetPlayerTime = null;

void PL_APL()
{
	pi_fwOnGetPlayerTime = new GlobalForward("OnGetPlayerHours", ET_Ignore, Param_Cell, Param_Cell);
}

void PI_OnPluginStart()
{
	LoadTranslations(TRANSLATIONS_PLAYERINFO);

	pi_cvMinUpdateRate		= FindConVar("sv_minupdaterate");
	pi_cvMaxUpdateRate		= FindConVar("sv_maxupdaterate");
	pi_cvMinInterpRatio 	= FindConVar("sv_client_min_interp_ratio");
	pi_cvMaxInterpRatio 	= FindConVar("sv_client_max_interp_ratio");

	pi_cvEnableGeoip		= CreateConVar("player_info_enable_geoip", "1", "Enable geoip message");
	pi_cvEnableDisconnect 	= CreateConVar("player_info_enable_disconnect", "1", "Enable custom disconnect message")

	HookEvent("player_disconnect", PI_Event_PlayerDisconnect, EventHookMode_Pre);

	RegConsoleCmd("sm_playerinfo", Cmd_Info);
}

void PI_SteamWorks_OnValidateClient(int iAuthId)
{
	int iClient = GetClientFromSteamID(iAuthId);

	if (IsValidClient_Pre(iClient) && !IsFakeClient(iClient))
		SteamWorks_RequestStats(iClient, APP_L4D2);
}

void PI_OnClientConnected(int iClient)
{
	if (IsValidClient_Pre(iClient) && !IsFakeClient(iClient))
	{
		char sName[128];
		GetClientName(iClient, sName, sizeof(sName));
		CPrintToChatAll("%t", "Connecting", sName);

		if (pi_cvEnableGeoip.BoolValue)
			GetClientIP(iClient, ip[iClient], sizeof(ip));
	}
}

public Action PI_Event_PlayerDisconnect(Handle hEvent, const char[] sName, bool dontBroadcast)
{
	char reason[PLATFORM_MAX_PATH], message[PLATFORM_MAX_PATH];
	int	 iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (!pi_cvEnableDisconnect.BoolValue)
		return Plugin_Handled;

	if (!IsValidClient(iClient))
		return Plugin_Handled;

	GetEventString(hEvent, "reason", reason, sizeof(reason));

	// to use specific translation
	for (int i = 1; i < MaxClients; i++)
	{
		GetDisconnectString(reason, message, i);
		if (IsClientConnected(i) && !IsFakeClient(i))
			CPrintToChat(i, "%t", "Disconnected", iClient, message);
	}

	return Plugin_Handled;
}

void PI_OnClientPutInServer(int iClient)
{
	if (IsValidClient_Pre(iClient) && !IsFakeClient(iClient))
	{
		char  ccode[3];
		char  sName[128];
		float fLerpTime;
		int	  iPlayedTime;
		fLerpTime = GetLerpTime(iClient) * 1000;
		GetClientName(iClient, sName, sizeof(sName));
		SteamWorks_GetStatCell(iClient, "Stat.TotalPlayTime.Total", iPlayedTime);
		Call_StartForward(pi_fwOnGetPlayerTime);
		Call_PushCell(iClient);
		Call_PushCell(SecToHours(iPlayedTime));
		Call_Finish();

		if (pi_cvEnableGeoip.BoolValue && GeoipCode2(ip[iClient], ccode))
			CPrintToChatAll("%t", "Connected_Geoip", sName, ccode, fLerpTime, SecToHours(iPlayedTime));
		else
			CPrintToChatAll("%t", "Connected", sName, fLerpTime, SecToHours(iPlayedTime));
	}
}

public Action Cmd_Info(int iClient, int iArgs)
{
	if (!IsValidClient_Pre(iClient))
	{
		return Plugin_Continue;
	}

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
	{
		return Plugin_Handled;
	}

	char sBracketStart[16];
	FormatEx(sBracketStart, sizeof(sBracketStart), "%T", "BRACKET_START", iClient);
	char sBracketMiddle[16];
	FormatEx(sBracketMiddle, sizeof(sBracketMiddle), "%T", "BRACKET_MIDDLE", iClient);
	char sBracketEnd[16];
	FormatEx(sBracketEnd, sizeof(sBracketEnd), "%T", "BRACKET_END", iClient);

	CReplyToCommand(iClient, "%s%T", sBracketStart, "HEADER", iClient);

	char  sSteamID[STEAMID_SIZE];
	int	  iPlayer, iPlayedTime;
	float fLerpTime, iMin, iMax;

	if (g_bIsLerpmonitorAvailable)
	{
		ConVar sm_min_lerp = FindConVar("sm_min_lerp"); iMin = sm_min_lerp.FloatValue;
		ConVar sm_max_lerp = FindConVar("sm_max_lerp"); iMax = sm_max_lerp.FloatValue;
	}

	for (int iItem = 0; iItem < iTotalPlayers; iItem++)
	{
		char ccode[3];
		iPlayer = iPlayers[iItem];
		SteamWorks_GetStatCell(iPlayer, "Stat.TotalPlayTime.Total", iPlayedTime);
		fLerpTime = GetLerpTime(iPlayer) * 1000;
		GetClientAuthId(iPlayer, AuthId_Steam2, sSteamID, sizeof(sSteamID));

		if (pi_cvEnableGeoip.BoolValue)
			GeoipCode2(ip[iPlayer], ccode);

		CReplyToCommand(iClient, "%s%T", (iItem + 1) == iTotalPlayers ? sBracketEnd : sBracketMiddle,
						  "INFO", iClient, iPlayer, pi_cvEnableGeoip.BoolValue ? ccode : "[x]",
						  (g_bIsLerpmonitorAvailable && ((iMin < fLerpTime) && (fLerpTime < iMax))) ? "{olive}" : "{green}",
						  fLerpTime, SecToHours(iPlayedTime), sSteamID);
	}

	return Plugin_Handled;
}

stock float GetLerpTime(int iClient)
{
	char  buffer[32];
	float fLerpRatio, fLerpAmount, fUpdateRate;

	if (GetClientInfo(iClient, "cl_interp_ratio", buffer, sizeof(buffer)))
		fLerpRatio = StringToFloat(buffer);

	if (pi_cvMinUpdateRate != null && pi_cvMaxInterpRatio != null && pi_cvMinInterpRatio.FloatValue != -1.0)
		fLerpRatio = clamp(fLerpRatio, pi_cvMinInterpRatio.FloatValue, pi_cvMaxInterpRatio.FloatValue);

	if (GetClientInfo(iClient, "cl_interp", buffer, sizeof(buffer)))
		fLerpAmount = StringToFloat(buffer);

	if (GetClientInfo(iClient, "cl_updaterate", buffer, sizeof(buffer)))
		fUpdateRate = StringToFloat(buffer);

	fUpdateRate = clamp(fUpdateRate, pi_cvMinUpdateRate.FloatValue, pi_cvMaxUpdateRate.FloatValue);

	return max(fLerpAmount, fLerpRatio / fUpdateRate);
}
#if defined _server_management_player_info_included
 #endinput
#endif
#define _server_management_player_info_included

/*
 * coded by TouchMe.
 **/

#define TRANSLATIONS_PLAYERINFO        "player_info.phrases"

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
	pi_cvMinUpdateRate = null, pi_cvMaxUpdateRate = null, pi_cvMinInterpRatio = null, pi_cvMaxInterpRatio = null;

/* player_info */
static ConVar
	pi_cvEnableLerp = null, pi_cvEnableTime = null, pi_cvEnableGeoip = null, pi_cvEnableDisconnect = null;

static char 
	ip[MAXPLAYERS + 1][64];

void PI_OnPluginStart()
{
	LoadTranslations(TRANSLATIONS_PLAYERINFO);

	pi_cvMinUpdateRate = FindConVar("sv_minupdaterate");
	pi_cvMaxUpdateRate = FindConVar("sv_maxupdaterate");
	pi_cvMinInterpRatio = FindConVar("sv_client_min_interp_ratio");
	pi_cvMaxInterpRatio = FindConVar("sv_client_max_interp_ratio");

	pi_cvEnableGeoip = CreateConVar("player_info_enable_geoip", "1", "Enable geoip message");

	HookEvent("player_disconnect", PI_Event_PlayerDisconnect, EventHookMode_Pre);

	RegConsoleCmd("sm_playerinfo", Cmd_Info);
}

void PI_SteamWorks_OnValidateClient(int iOwnerAuthId, int iAuthId)
{
	int iClient = GetClientFromSteamID(iAuthId);

	if (IsValidClient_Pre(iClient) && !IsFakeClient(iClient)) {
		SteamWorks_RequestStats(iClient, APP_L4D2);
	}
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
    int iClient = GetClientOfUserId(GetEventInt(hEvent,"userid"));

    if (!(1 <= iClient <= MaxClients))
        return Plugin_Handled;

    if (!IsClientInGame(iClient))
        return Plugin_Handled;

    if (IsFakeClient(iClient))
        return Plugin_Handled;

    char reason[64], message[64];
    GetEventString(hEvent, "reason", reason, sizeof(reason));

	for (int i = 0; i < MaxClients; i++)
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
		char ccode[3];
		char sName[128]; float fLerpTime; int iPlayedTime;
		fLerpTime = GetLerpTime(iClient) * 1000;
		GetClientName(iClient, sName, sizeof(sName));
		SteamWorks_GetStatCell(iClient, "Stat.TotalPlayTime.Total", iPlayedTime);

		if (pi_cvEnableGeoip.BoolValue)
			GeoipCode2(ip[iClient], ccode);

		CPrintToChatAll("%t", "Connected", sName, pi_cvEnableGeoip.BoolValue ? ccode : "", fLerpTime, SecToHours(iPlayedTime));
	}
}

public Action Cmd_Info(int iClient, int iArgs)
{
	if (!IsValidClient_Pre(iClient)) {
		return Plugin_Continue;
	}

	int iTotalPlayers = 0;
	int[] iPlayers = new int[MaxClients];

	for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer ++)
	{
		if (!IsClientInGame(iPlayer)
		|| IsFakeClient(iPlayer)) {
			continue;
		}

		iPlayers[iTotalPlayers++] = iPlayer;
	}

	if (!iTotalPlayers) {
		return Plugin_Handled;
	}

	char sBracketStart[16]; FormatEx(sBracketStart, sizeof(sBracketStart), "%T", "BRACKET_START", iClient);
	char sBracketMiddle[16]; FormatEx(sBracketMiddle, sizeof(sBracketMiddle), "%T", "BRACKET_MIDDLE", iClient);
	char sBracketEnd[16]; FormatEx(sBracketEnd, sizeof(sBracketEnd), "%T", "BRACKET_END", iClient);

	CReplyToCommand(iClient, "%s%T", sBracketStart, "HEADER", iClient);

	char sSteamID[STEAMID_SIZE];
	int iPlayer, iPlayedTime;
	float fLerpTime, iMin, iMax;

	if (g_bIsLerpmonitorAvailable)
	{
		ConVar sm_min_lerp = FindConVar("sm_min_lerp"); iMin = sm_min_lerp.FloatValue;
		ConVar sm_max_lerp = FindConVar("sm_max_lerp"); iMax = sm_max_lerp.FloatValue;
	}

	for (int iItem = 0; iItem < iTotalPlayers; iItem ++)
	{
		char ccode[3];
		iPlayer = iPlayers[iItem];
		SteamWorks_GetStatCell(iPlayer, "Stat.TotalPlayTime.Total", iPlayedTime);
		fLerpTime = GetLerpTime(iPlayer) * 1000;
		GetClientAuthId(iPlayer, AuthId_Steam2, sSteamID, sizeof(sSteamID));

		if (pi_cvEnableGeoip.BoolValue)
			GeoipCode2(ip[iPlayer], ccode);

		CReplyToCommandEx(iClient, iClient, "%s%T", (iItem + 1) == iTotalPlayers ? sBracketEnd : sBracketMiddle,
		"INFO", iClient, iPlayer, pi_cvEnableGeoip.BoolValue ? ccode : "", 
		(g_bIsLerpmonitorAvailable && ((iMin < fLerpTime) && (fLerpTime < iMax))) ? "{olive}" : "{red}", 
		fLerpTime, SecToHours(iPlayedTime), sSteamID);
	}

	return Plugin_Handled;
}

stock float GetLerpTime(int iClient)
{
	char buffer[32];
	float fLerpRatio, fLerpAmount, fUpdateRate;

	if (GetClientInfo(iClient, "cl_interp_ratio", buffer, sizeof(buffer))) {
		fLerpRatio = StringToFloat(buffer);
	}

	if (pi_cvMinUpdateRate != null && pi_cvMaxInterpRatio != null && GetConVarFloat(pi_cvMinInterpRatio) != -1.0) {
		fLerpRatio = clamp(fLerpRatio, GetConVarFloat(pi_cvMinInterpRatio), GetConVarFloat(pi_cvMaxInterpRatio));
	}

	if (GetClientInfo(iClient, "cl_interp", buffer, sizeof(buffer))) {
		fLerpAmount = StringToFloat(buffer);
	}

	if (GetClientInfo(iClient, "cl_updaterate", buffer, sizeof(buffer))) {
		fUpdateRate = StringToFloat(buffer);
	}

	fUpdateRate = clamp(fUpdateRate, GetConVarFloat(pi_cvMinUpdateRate), GetConVarFloat(pi_cvMaxUpdateRate));

	return max(fLerpAmount, fLerpRatio / fUpdateRate);
}
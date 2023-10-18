#if defined _server_management_includes_util_included
	#endinput
#endif
#define _server_management_includes_util_included

//-----------------------
//      Welcome Msg
//-----------------------
stock int GetTotalPlayers()
{
	int players;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) > 1 && !IsFakeClient(i))
			players++;
	}

	return players;
}

stock int GetScavengeRoundNumber()
{
	return GameRules_GetProp("m_nRoundNumber");
}

stock bool InSecondHalfOfRound()
{
	return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound"));
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client)) ? true : false;
}

//----------------------
//      Player Info
//----------------------

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

stock bool IsValidClient_Pre(int iClient)
{
	return (iClient > 0 && iClient <= MaxClients);
}

stock float SecToHours(int iSeconds)
{
	return float(iSeconds) / 3600.0;
}

stock float max(float a, float b)
{
	return (a > b) ? a : b;
}

stock float clamp(float inc, float low, float high)
{
	return (inc > high) ? high : ((inc < low) ? low : inc);
}

stock void GetDisconnectString(char[] reason, char[] message, int client)
{
	SetGlobalTransTarget(client);
	switch(GetDisconnectType(reason))
	{
		case TYPE_NONE:					{Format(message, PLATFORM_MAX_PATH, "%t", "TYPE_NONE");}
		case TYPE_CONNECTION_REJECTED:	{Format(message, PLATFORM_MAX_PATH, "%t", "TYPE_CONNECTION_REJECTED");}
		case TYPE_TIMED_OUT:			{Format(message, PLATFORM_MAX_PATH, "%t", "TYPE_TIMED_OUT");}
		case TYPE_BY_CONSOLE:			{Format(message, PLATFORM_MAX_PATH, "%t", "TYPE_BY_CONSOLE");}
		case TYPE_BY_USER:				{Format(message, PLATFORM_MAX_PATH, "%t", "TYPE_BY_USER");}
		case TYPE_HIGH_PING:			{Format(message, PLATFORM_MAX_PATH, "%t", "TYPE_HIGH_PING");}
		case TYPE_NO_STEAM_LOGEN:		{Format(message, PLATFORM_MAX_PATH, "%t", "TYPE_NO_STEAM_LOGEN");}
		case TYPE_ACCOUNT_BEING_USED:	{Format(message, PLATFORM_MAX_PATH, "%t", "TYPE_ACCOUNT_BEING_USED");}
		case TYPE_CONNECTION_LOST:		{Format(message, PLATFORM_MAX_PATH, "%t", "TYPE_CONNECTION_LOST");}
		case TYPE_NOT_OWNER:			{Format(message, PLATFORM_MAX_PATH, "%t", "TYPE_NOT_OWNER");}
		case TYPE_VALIDATION_REJECTED:	{Format(message, PLATFORM_MAX_PATH, "%t", "TYPE_VALIDATION_REJECTED");}
		case TYPE_CERTIFICATE_LENGTH:	{Format(message, PLATFORM_MAX_PATH, "%t", "TYPE_CERTIFICATE_LENGTH");}
		case TYPE_PURE_SERVER:			{Format(message, PLATFORM_MAX_PATH, "%t", "TYPE_PURE_SERVER");}
	}
}

stock DisconnectType GetDisconnectType(char[] reason)
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
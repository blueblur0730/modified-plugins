#if defined _server_management_includes_util_included
	#endinput
#endif
#define _server_management_includes_util_included

// Constants are used in the game code, there is definitely no such enum
enum /*L4D2_Team*/
{
	L4D2Team_None = 0,
	L4D2Team_Spectator,
	L4D2Team_Survivor,
	L4D2Team_Infected,
	L4D2Team_L4D1_Survivor, // Used for maps where there are survivors from the first chapter and from the second, for example c7m3_port

	L4D2Team_Size // 5 size
};

stock int GetTotalPlayers()
{
	int players = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
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

stock bool IsClientAndInGame(int index)
{
	if (index > 0 && index <= MaxClients)
		return IsClientInGame(index);

	return false;
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client)) ? true : false;
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

stock bool IsValidClient_Pre(int iClient)
{
	return (iClient > 0 && iClient <= MaxClients);
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

stock void GetDisconnectString(char[] reason, char[] message, int maxlen)
{
	switch(GetDisconnectType(reason))
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

stock bool CheckPlayerInGame(int client)
{
	for (int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i) && i!=client)
			return true;

	return false;
}

stock bool CheckPlayerConnectingSV()
{
	for (int i = 1; i <= MaxClients; i++)
		if(IsClientConnected(i) && !IsClientInGame(i) && !IsFakeClient(i))
			return true;

	return false;
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

stock ConVar CreateConVarHook(const char[] name,
						const char[] defaultValue,
						const char[] description = "",
						int	 flags				 = 0,
						bool hasMin = false, float min = 0.0,
						bool hasMax = false, float max = 0.0,
						ConVarChanged callback)
{
	ConVar cv = CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
	cv.AddChangeHook(callback);

	return cv;
}

stock void StrToLower(char[] arg) 
{
    for (int i = 0; i < strlen(arg); i++) 
        arg[i] = CharToLower(arg[i]);
}

stock int GetCurrentMapLower(char[] buffer, int buflen) 
{
    int iBytesWritten = GetCurrentMap(buffer, buflen);
    StrToLower(buffer);
    return iBytesWritten;
}

stock void CS_SetClientName(int client, const char[] name, bool silent=false)
{
    char oldname[MAX_NAME_LENGTH];
    GetClientName(client, oldname, sizeof(oldname));

    SetClientInfo(client, "name", name);
    SetEntPropString(client, Prop_Data, "m_szNetname", name);

    Event event = CreateEvent("player_changename");

    if (event != null)
    {
        event.SetInt("userid", GetClientUserId(client));
        event.SetString("oldname", oldname);
        event.SetString("newname", name);
		event.BroadcastDisabled = true;	// silent!
        event.Fire();
    }

    if (silent)
        return;
/*
    Handle msg = StartMessageAll("SayText2");

    if (msg != null)
    {
        BfWriteByte(msg, client);
        BfWriteByte(msg, true);
        BfWriteString(msg, "#Cstrike_Name_Change");
        BfWriteString(msg, oldname);
        BfWriteString(msg, name);
        EndMessage();
    }
*/
}

stock bool IsClientAdmin(int client)
{
	if( !IsClientInGame(client) ) return false;
	return( GetUserAdmin(client) != INVALID_ADMIN_ID && GetUserFlagBits(client) != 0 );
}

stock float maximum(float a, float b)
{
	return (a > b) ? a : b;
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
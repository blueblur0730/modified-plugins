#if defined _server_management_lerpmonitor_included
    #endinput
#endif
#define _server_management_lerpmonitor_included

//----------------------------------------------------------
// LerpMonitor++ by ProdigySim, Die Teetasse, vintik, A1m`
//----------------------------------------------------------

#define L4D_TEAM_SPECTATE 1
#define L4D_TEAM_SURVIVORS 2

static StringMap
	g_hMapLerpsValue = null,
	g_hMapLerpsCountChanges = null;
	
static ConVar 
	g_hCVar_ReadyUpLerpChanges = null,
	g_hCVar_AllowedLerpChanges = null,
	g_hCVar_LerpChangeSpec = null,
	g_hCVar_BadLerpAction = null,
	g_hCVar_MinLerp = null,
	g_hCVar_MaxLerp = null,
	g_hCVar_ShowLerpTeamChange = null;

static bool
	g_bIsLateLoad = false,
	g_bIsFirstHalf = true,
	g_bIsMatchLife = true,
	g_bIsTransfer = false;

void _lerpmonitor_AskPluginLoad2(bool late)
{
	g_bIsLateLoad = late;
	CreateNative("LM_GetLerpTime", LM_GetLerpTime);
	CreateNative("LM_GetCurrentLerpTime", LM_GetCurrentLerpTime);
}

int LM_GetLerpTime(Handle plugin, int numParams) 
{
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d!", client);
	
	if (!IsClientInGame(client)) 
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in game!", client);
	
	float fLerpValue = -1.0;
	char sSteamID[STEAMID_SIZE];
	GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID));
	if (g_hMapLerpsValue.GetValue(sSteamID, fLerpValue)) 
		return view_as<int>(fLerpValue);

	return view_as<int>(-1.0);
}

int LM_GetCurrentLerpTime(Handle plugin, int numParams) 
{
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients) 
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d!", client);
	
	if (!IsClientConnected(client)) 
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d not connected!", client);
	
	return view_as<int>(GetLerpTime(client));
}

void _lerpmonitor_OnPluginStart()
{
    LoadTranslation("server_management.lerpmonitor.phrases");

	g_hCVar_AllowedLerpChanges = CreateConVar("sm_allowed_lerp_changes", "100", "Allowed number of lerp changes for a half", _, true, 0.0, true, 20.0);
	g_hCVar_LerpChangeSpec = CreateConVar("sm_lerp_change_spec", "1", "Move to spectators on exceeding lerp changes count?", _, true, 0.0, true, 1.0);
	g_hCVar_BadLerpAction = CreateConVar("sm_bad_lerp_action", "1", "What to do with a player if he is out of allowed lerp range? 1 - move to spectators, 0 - kick from server", _, true, 0.0, true, 1.0);
	g_hCVar_ReadyUpLerpChanges = CreateConVar("sm_readyup_lerp_changes", "100", "Allow lerp changes during ready-up", _, true, 0.0, true, 1.0);
	g_hCVar_ShowLerpTeamChange = CreateConVar("sm_show_lerp_team_changes", "100", "show a message about the player's lerp if he changes the team", _, true, 0.0, true, 1.0);
	g_hCVar_MinLerp = CreateConVar("sm_min_lerp", "0.000", "Minimum allowed lerp value", _, true, 0.000, true, 0.500);
	g_hCVar_MaxLerp = CreateConVar("sm_max_lerp", "0.100", "Maximum allowed lerp value", _, true, 0.000, true, 0.500);
	
	RegConsoleCmd("sm_lerps", Lerps_Cmd, "List the Lerps of all players in game");
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_team", OnTeamChange, EventHookMode_Post);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
	HookEvent("player_left_start_area", Event_RoundGoesLive, EventHookMode_PostNoCopy);
	
	// create arrays
	g_hMapLerpsValue = new StringMap();
	g_hMapLerpsCountChanges = new StringMap();
	
	if (g_bIsLateLoad) 
    {
		// process current players
		for (int i = 1; i <= MaxClients; i++) 
        {
			if (IsClientInGame(i) && !IsFakeClient(i)) 
				ProcessPlayerLerp(i, true);
		}
	}
}

void _lerpmonitor_OnClientPutInServer(int client)
{
	if (IsValidEntity(client) && !IsFakeClient(client)) 
		CreateTimer(1.0, Process, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

static void Process(Handle hTimer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && GetClientTeam(client) > L4D_TEAM_SPECTATE) 
		ProcessPlayerLerp(client);
}

void _lerpmonitor_OnMapStart()
{
	g_bIsMatchLife = false;
}

void _lerpmonitor_OnMapEnd()
{
	g_bIsFirstHalf = true;
	g_hMapLerpsValue.Clear();
	g_hMapLerpsCountChanges.Clear();
}

void _lerpmonitor_OnClientSettingsChanged(int client)
{
	if (IsValidEntity(client) && !IsFakeClient(client)) 
		ProcessPlayerLerp(client);
}

static void Event_RoundGoesLive(Event hEvent, const char[] name, bool dontBroadcast)
{
	//This event works great with the plugin readyup.smx (does not conflict)
	//This event works great in different game modes: versus, coop, scavenge and etc
	g_bIsMatchLife = true;
}

static void Event_PlayerDisconnect(Event hEvent, const char[] name, bool dontBroadcast)
{
	char SteamID[64];
	hEvent.GetString("networkid", SteamID, sizeof(SteamID));
	
	if (StrContains(SteamID, "STEAM") != 0) 
		return;
	
	g_hMapLerpsValue.Remove(SteamID);
	//g_hMapLerpsCountChanges.Remove(SteamID);
}

static void OnTeamChange(Event hEvent, const char[] eName, bool dontBroadcast)
{
	if (hEvent.GetInt("team") > L4D_TEAM_SPECTATE) 
    {
		int userid = hEvent.GetInt("userid");
		int client = GetClientOfUserId(userid);
		if (client > 0 && IsClientInGame(client) && !IsFakeClient(client)) 
        {
			if (!g_bIsTransfer) 
				CreateTimer(0.1, OnTeamChangeDelay, userid, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

static void OnTeamChangeDelay(Handle hTimer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (client > 0) 
		ProcessPlayerLerp(client, false, true);
}

static void Event_RoundEnd(Event hEvent, const char[] name, bool dontBroadcast)
{
	// little delay for other round end used modules
	CreateTimer(0.5, Timer_RoundEndDelay, _, TIMER_FLAG_NO_MAPCHANGE);
}

static void Timer_RoundEndDelay(Handle hTimer)
{
	g_bIsFirstHalf = false;
	g_bIsTransfer = true;
	g_bIsMatchLife = false;

	g_hMapLerpsCountChanges.Clear();
}

static Action Lerps_Cmd(int client, int args)
{
	bool isEmpty = true;
	if (g_hMapLerpsValue.Size > 0) 
    {
		CReplyToCommand(client, "%t", "SettingList");
		
		float fLerpValue;
		char sSteamID[STEAMID_SIZE];
		for (int i = 1; i <= MaxClients; i++) 
        {
			if (IsClientInGame(i) && !IsFakeClient(i)) 
            {
				GetClientAuthId(i, AuthId_Steam2, sSteamID, sizeof(sSteamID));
				
				if (g_hMapLerpsValue.GetValue(sSteamID, fLerpValue)) 
                {
					CReplyToCommand(client, "%t", "ListFormat", i, sSteamID, fLerpValue * 1000);
					isEmpty = false;
				}
			}
		}
	}
	
	if (isEmpty) 
		CReplyToCommand(client, "%t", "NothingHere");

	return Plugin_Handled;
}

static void Event_RoundStart(Event hEvent, const char[] name, bool dontBroadcast)
{
	// delete change count for second half
	if (!g_bIsFirstHalf) 
		g_hMapLerpsCountChanges.Clear();
	
	CreateTimer(0.5, OnTransfer, _, TIMER_FLAG_NO_MAPCHANGE);
}

static void OnTransfer(Handle hTimer)
{
	g_bIsTransfer = false;
}

static void ProcessPlayerLerp(int client, bool load = false, bool team = false) 
{
	float newLerpTime = GetLerpTime(client); // get lerp
	
	// set lerp for fixing differences between server and client with cl_interp_ratio 0
	SetEntPropFloat(client, Prop_Data, "m_fLerpTime", newLerpTime);
	
	// check lerp first
	if (GetClientTeam(client) < L4D_TEAM_SURVIVORS) 
		return;
	
	// Get steamid
	char steamID[STEAMID_SIZE];
	GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));

	if ((FloatCompare(newLerpTime, g_hCVar_MinLerp.FloatValue) == -1)  || (FloatCompare(newLerpTime, g_hCVar_MaxLerp.FloatValue) == 1)) {
		//PrintToChatAll("%N's lerp changed to %.01f", client, newLerpTime * 1000);
		if (!load) 
        {
			float currentLerpTime = 0.0;
			if (g_hMapLerpsValue.GetValue(steamID, currentLerpTime)) 
            {
				if (currentLerpTime == newLerpTime) { // no change?
					if (g_hCVar_BadLerpAction.IntValue == 1) 
						ChangeClientTeam(client, L4D_TEAM_SPECTATE); 
					else
                    {
                        char sMessage[256];
                        Format(sMessage, sizeof(sMessage), "%T", "KickMessage", client, g_hCVar_MinLerp.FloatValue * 1000, g_hCVar_MaxLerp.FloatValue * 1000);
						KickClient(client, sMessage);
                    }

					return;
				}
			}
			
			if (g_hCVar_BadLerpAction.IntValue == 1) 
            {
				CPrintToChatAllEx(client, "%t", "MovedToSpec", client, newLerpTime * 1000);
				CPrintToChatEx(client, client, "%t", "IllegalLerp", g_hCVar_MinLerp.FloatValue * 1000, g_hCVar_MaxLerp.FloatValue * 1000);
				ChangeClientTeam(client, L4D_TEAM_SPECTATE);
			} else 
            {
				CPrintToChatAllEx(client, "%t", "DirectKick", client, newLerpTime * 1000);
				KickClient(client, "%T", "KickMessage", client, g_hCVar_MinLerp.FloatValue * 1000, g_hCVar_MaxLerp.FloatValue * 1000);
			}
		}
		
		// nothing else to do
		return;
	}
	
	float currentLerpTime = 0.0;
	if (!g_hMapLerpsValue.GetValue(steamID, currentLerpTime)) 
    {
		// add to array
		if (team && g_hCVar_ShowLerpTeamChange.BoolValue) 
			CPrintToChatAllEx(client, "%t", "LerpNotify", client, newLerpTime * 1000);

		g_hMapLerpsValue.SetValue(steamID, newLerpTime, true);
		//g_hMapLerpsCountChanges.SetValue(steamID, 0, true); 
		return;
	}
	
    // no change?
	if (currentLerpTime == newLerpTime) 
    { 
		if (team && g_hCVar_ShowLerpTeamChange.BoolValue) 
			CPrintToChatAllEx(client, "%t", "LerpNotify", client, newLerpTime * 1000); 

		return;
	}

    // Midgame?
	if (g_bIsMatchLife || !g_hCVar_ReadyUpLerpChanges.BoolValue) 
    { 
		int count = 0;
		g_hMapLerpsCountChanges.GetValue(steamID, count);
		count++;
		
		int maxAllowed = g_hCVar_AllowedLerpChanges.IntValue;
		CPrintToChatAllEx(client, "%t", "LerpChanged", client, newLerpTime * 1000, currentLerpTime * 1000, ((count > maxAllowed) ? "{teamcolor} ": ""), count, maxAllowed);
	
		if (g_hCVar_LerpChangeSpec.BoolValue && (count > maxAllowed)) 
        {
			CPrintToChatAllEx(client, "%t", "MoveToSpec_Changed", client);
			ChangeClientTeam(client, L4D_TEAM_SPECTATE);
			CPrintToChatEx(client, client, "%t", "ChangeBack", currentLerpTime * 1000);
			// no lerp update
			return;
		}
		
		g_hMapLerpsCountChanges.SetValue(steamID, count); // update changes
	} 
    else 
		CPrintToChatAllEx(client, "%t", "LerpChanged_NoLimit", client, newLerpTime * 1000, currentLerpTime * 1000);
	
	g_hMapLerpsValue.SetValue(steamID, newLerpTime); // update lerp
	//g_hMapLerpsCountChanges.SetValue(steamID, 0, true); 
}
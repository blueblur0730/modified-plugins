#if defined _server_management_player_info_included
	#endinput
#endif
#define _server_management_player_info_included

//----------------------------------------------
// Player Info by TouchMe modified by blueblur.
//----------------------------------------------

#include <geoip>

// for nomasters server this may not work.
// use http request extentions instead.
#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>

#undef REQUIRE_EXTENSIONS
#tryinclude <ripext>

// Steamworks constants
#define APP_L4D2 550

// ripext constants
#define HOST_PATH					"https://partner.steam-api.com"
#define TOTAL_PLAYTIME_URL			"IPlayerService/GetOwnedGames/v1/?format=json&appids_filter[0]=550"
#define REAL_PLAYTIME_URL			"ISteamUserStats/GetUserStatsForGame/v2/?"
#define VALVEKEY					"64FB8F83E5A7D8A9055FCA25A7F7D9EF"

#define ANNOUNCE_GEOIP			(1<<0)
#define ANNOUNCE_PLAYTIME		(1<<1)

enum struct PlayerStruct {
	int totalplaytime;
	int realplaytime;
	int last2weektime;
	bool retrieved;
}
PlayerStruct player_t[MAXPLAYERS + 1];

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

/* player_info */
static ConVar
	g_hCvar_AnnounceType = null, g_hCvar_EnableDisconnect = null;

static ConVar
	g_hCvar_RequestMethod = null; //g_hCvar_HoursStyle = null;

static int g_iAAnnounceType = 0;

static char
	ip[MAXPLAYERS + 1][64];

void _player_info_OnPluginStart()
{
	LoadTranslation("server_management.player_info.phrases");

	g_hCvar_AnnounceType		= CreateConVar("player_info_announce_type", "1", "Announce type. 0=none, 1=add geoip, 2=add playtime, 3=add both.");
	g_hCvar_EnableDisconnect 	= CreateConVar("player_info_enable_disconnect", "1", "Enable custom disconnect message");

	g_hCvar_RequestMethod		= CreateConVar("player_info_request_method", "1", "Request method: 0=SteamWorks, 1=ripext.");
	//g_hCvar_HoursStyle			= CreateConVar("player_info_hours_style", "1", "Hours style: 1=total, 2=real, 3=last2week.");

	g_hCvar_AnnounceType.AddChangeHook(OnCvarChanged);
	OnCvarChanged(null, "", "");

	// remove notification.
	HookEvent("player_disconnect", Event_PlayerDisconnect_Pre, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_PlayerDisconnect_Post, EventHookMode_Post);
	HookUserMessage(GetUserMessageId("TextMsg"), TextMsg, true);

	RegConsoleCmd("sm_playerinfo", Cmd_Info);
}

static void OnCvarChanged(ConVar convar, const char[] oldvalue, const char[] newvalue)
{
	g_iAAnnounceType = g_hCvar_AnnounceType.IntValue;
}

void _player_info_SteamWorks_OnValidateClient(int iAuthId)
{
	if (g_hCvar_RequestMethod.IntValue == 0)
	{
		int iClient = GetClientFromSteamID(iAuthId);
		SteamWorks_RequestStats(iClient, APP_L4D2);
	}
}

void _player_info_OnClientConnected(int iClient)
{
	if (IsValidClient_Pre(iClient) && !IsFakeClient(iClient))
	{
		char sName[128];
		GetClientName(iClient, sName, sizeof(sName));
		CPrintToChatAll("%t", "Connecting", sName);

		if (g_hCvar_AnnounceType.BoolValue)
			GetClientIP(iClient, ip[iClient], sizeof(ip));
	}
}

void _player_info_OnClientPutInServer(int iClient)
{
	if (IsValidClient_Pre(iClient) && !IsFakeClient(iClient))
	{
		char  ccode[3];
		char  sName[128];
		float fLerpTime;
		
		fLerpTime = GetLerpTime(iClient) * 1000;
		GetClientName(iClient, sName, sizeof(sName));

		// this, is gonna be a suck look like
		// and translaion is the stupidest thing in the world
		if (!g_iAAnnounceType)
			CPrintToChatAll("%t", "Connected", sName, fLerpTime);

		if (g_iAAnnounceType == ANNOUNCE_GEOIP)
		{
			if (GeoipCode2(ip[iClient], ccode))
				CPrintToChatAll("%t", "Connected_Geoip", sName, ccode, fLerpTime);
			else
				CPrintToChatAll("%t", "Connected_Unknown_Geoip", sName, fLerpTime);
		}
		
		if (g_iAAnnounceType == ANNOUNCE_PLAYTIME)
		{
			char sPlayedTime[32];
			switch (g_hCvar_RequestMethod.IntValue)
			{
				case 0:
				{
					int	iPlayedTime = 0;
					SteamWorks_GetStatCell(iClient, "Stat.TotalPlayTime.Total", iPlayedTime);
					if (iPlayedTime <= 0)
						CPrintToChatAll("%t", "Connected_Unknown_PlayedTime", sName, fLerpTime);
					else
					{
						Format(sPlayedTime, sizeof(sPlayedTime), "%.02f", SecToHours(iPlayedTime));
						CPrintToChatAll("%t", "Connected_PlayeTime", sName, fLerpTime, sPlayedTime);
					}
				}

				case 1:
				{
					GetPlayerTime(iClient);
					if (player_t[iClient].realplaytime <= 0)
						CPrintToChatAll("%t", "Connected_Unknown_PlayedTime", sName, fLerpTime);
					else
					{
						Format(sPlayedTime, sizeof(sPlayedTime), "%.02f", SecToHours(player_t[iClient].realplaytime));
						CPrintToChatAll("%t", "Connected_PlayeTime", sName, fLerpTime, sPlayedTime);
					}
				}
			}
		}

		if (g_iAAnnounceType == (ANNOUNCE_PLAYTIME | ANNOUNCE_GEOIP))
		{
			char sBuffer[32], sPlayedTime[32];
			if (GeoipCode2(ip[iClient], ccode))
				Format(sBuffer, sizeof(sBuffer), "[{olive}%s{defaault}]", ccode);
			else
				Format(sBuffer, sizeof(sBuffer), "[{olive}X{defaault}]");

			switch (g_hCvar_RequestMethod.IntValue)
			{
				case 0:
				{
					int	iPlayedTime = 0;
					SteamWorks_GetStatCell(iClient, "Stat.TotalPlayTime.Total", iPlayedTime);
					if (iPlayedTime <= 0)
						CPrintToChatAll("%t", "Connected_Geoip_Unknown_PlayedTime", sName, sBuffer, fLerpTime);
					else
					{
						Format(sPlayedTime, sizeof(sPlayedTime), "%.02f", SecToHours(iPlayedTime));
						CPrintToChatAll("%t", "Connected_Geoip_PlayeTime", sName, sBuffer, fLerpTime, sPlayedTime);
					}
				}

				case 1:
				{
					GetPlayerTime(iClient);
					if (player_t[iClient].realplaytime <= 0)
						CPrintToChatAll("%t", "Connected_Geoip_Unknown_PlayedTime", sName, sBuffer, fLerpTime);
					else
					{
						Format(sPlayedTime, sizeof(sPlayedTime), "%.02f", SecToHours(player_t[iClient].realplaytime));
						CPrintToChatAll("%t", "Connected_Geoip_PlayeTime", sName, sBuffer, fLerpTime, sPlayedTime);
					}
				}
			}
		}	
	}
}

static Action Event_PlayerDisconnect_Pre(Event hEvent, const char[] sName, bool dontBroadcast)
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

static void Event_PlayerDisconnect_Post(Event hEvent, const char[] sName, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent,"userid"));

	if  (client <= 0 || client > MaxClients)
		return;

	if (!IsClientInGame(client) || IsFakeClient(client))
		return;

	player_t[client].totalplaytime = 0;
	player_t[client].realplaytime = 0;
	player_t[client].last2weektime = 0;
}

static Action TextMsg(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init) 
{
	static char sMsg[254];
	msg.ReadString(sMsg, sizeof sMsg);

	if(StrContains(sMsg, "L4D_idle_spectator") != -1)
		return Plugin_Handled;

	return Plugin_Continue;
}

static Action Cmd_Info(int iClient, int iArgs)
{
	if (!IsValidClient_Pre(iClient))
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

	char  sSteamID[STEAMID_SIZE];
	int	  iPlayer, iPlayedTime = 0;
	float fLerpTime, iMin, iMax;

	if (g_bCoopSystem)
	{
		ConVar sm_min_lerp = FindConVar("sm_min_lerp"); iMin = sm_min_lerp.FloatValue;
		ConVar sm_max_lerp = FindConVar("sm_max_lerp"); iMax = sm_max_lerp.FloatValue;
	}

	char sPlayedTime[32];
	for (int iItem = 0; iItem < iTotalPlayers; iItem++)
	{
		char ccode[3];
		iPlayer = iPlayers[iItem];
		if (g_hCvar_RequestMethod.IntValue == 0)
			SteamWorks_GetStatCell(iPlayer, "Stat.TotalPlayTime.Total", iPlayedTime);
		else if (g_hCvar_RequestMethod.IntValue == 1)
			GetPlayerTime(iPlayer);

		fLerpTime = GetLerpTime(iPlayer) * 1000;
		GetClientAuthId(iPlayer, AuthId_Steam2, sSteamID, sizeof(sSteamID));
		
		if (g_hCvar_RequestMethod.IntValue == 0)
		{
			iPlayedTime == 0 ? 
				Format(sPlayedTime, sizeof(sPlayedTime), "%T", "Unknown_PlayedTime", iClient) :
				Format(sPlayedTime, sizeof(sPlayedTime), "%.02f", SecToHours(iPlayedTime));
		}
		else
		{
			!player_t[iPlayer].retrieved ?
				Format(sPlayedTime, sizeof(sPlayedTime), "%T", "Unknown_PlayedTime", iClient) :
				Format(sPlayedTime, sizeof(sPlayedTime), "%.02f", SecToHours(player_t[iPlayer].realplaytime));
		}

		if (!GeoipCode2(ip[iPlayer], ccode))
			strcopy(ccode, sizeof(ccode), "[x]");

		CReplyToCommandEx(iClient, iPlayer, "%s%t", (iItem + 1) == iTotalPlayers ? sBracketEnd : sBracketMiddle,
						  "INFO", iPlayer, ccode,
						  (g_bCoopSystem && ((iMin < fLerpTime) && (fLerpTime < iMax))) ? "{olive}" : "{green}",
						  fLerpTime, sPlayedTime, sSteamID);
	}

	return Plugin_Handled;
}

static stock void GetPlayerTime(int client)
{
	char authId64[65], URL[1024];
	GetClientAuthId(client, AuthId_SteamID64, authId64, sizeof(authId64));
	if (StrEqual(authId64, "STEAM_ID_STOP_IGNORING_RETVALS")) return;

	Format(URL, sizeof(URL), "%s/%s&key=%s&steamid=%s", HOST_PATH, TOTAL_PLAYTIME_URL, VALVEKEY, authId64);
	HTTPRequest httpRequest = new HTTPRequest(URL);
	httpRequest.Get(HTTPResponse_GetOwnedGames, client);
	
	CreateTimer(1.0, GetRealTime, client);
}

static stock void GetRealTime(Handle hTimer, int client)
{
	char authId64[65], URL[1024];
	GetClientAuthId(client, AuthId_SteamID64, authId64, sizeof(authId64));
	if (StrEqual(authId64, "STEAM_ID_STOP_IGNORING_RETVALS")) return;
	
	Format(URL, sizeof(URL), "%s/%skey=%s&steamid=%s&appid=550", HOST_PATH, REAL_PLAYTIME_URL, VALVEKEY, authId64);
	HTTPRequest httpRequest = new HTTPRequest(URL);
	httpRequest.Get(HTTPResponse_GetUserStatsForGame, client);
}

// playtime
static void HTTPResponse_GetOwnedGames(HTTPResponse response, int client)
{
	if (response.Status != HTTPStatus_OK || response.Data == null)
	{
		LogError("Failed to retrieve response (GetOwnedGames) - HTTPStatus: %i", view_as<int>(response.Status));
		player_t[client].totalplaytime = 0;
		player_t[client].retrieved = false;
		return;
	}
	
	// go to response body
	JSONObject dataObj = view_as<JSONObject>(view_as<JSONObject>(response.Data).Get("response"));
	
	// invalid json data due to privacy?
	if (!dataObj)
	{
		player_t[client].totalplaytime = 0;
		player_t[client].last2weektime = 0;
		return;
	}
	if (!dataObj.Size || !dataObj.HasKey("games") || dataObj.IsNull("games"))
	{
		player_t[client].totalplaytime = 0;
		player_t[client].last2weektime = 0;
		delete dataObj;
		return;
	}
	
	// jump to "games" array section
	JSONArray jsonArray = view_as<JSONArray>(dataObj.Get("games"));
	delete dataObj;
	
	// right here is the data requested
	dataObj = view_as<JSONObject>(jsonArray.Get(0));
	
	// playtime is formatted in minutes
	player_t[client].totalplaytime = dataObj.GetInt("playtime_forever");
	player_t[client].last2weektime = dataObj.GetInt("playtime_2weeks");
	delete jsonArray;
	delete dataObj;
}

// real playtime
static void HTTPResponse_GetUserStatsForGame(HTTPResponse response, int client)
{	
	if (response.Status != HTTPStatus_OK || response.Data == null)
	{
		LogError("Failed to retrieve response (GetUserStatsForGame) - HTTPStatus: %i", view_as<int>(response.Status));
		player_t[client].realplaytime = 0;
		player_t[client].retrieved = false;
		return;
	}
	
	// go to response body
	JSONObject dataObj = view_as<JSONObject>(view_as<JSONObject>(response.Data).Get("playerstats"));
	
	// invalid json data due to privacy?
	if (dataObj)
	{
		if ( !dataObj.Size
			|| !dataObj.HasKey("stats")
			|| dataObj.IsNull("stats") )
		{
			player_t[client].realplaytime = 0;
			delete dataObj;
			return;
		}
	}
	else
	{
		player_t[client].realplaytime = 0;
		return;
	}
	
	// jump to "stats" array section
	JSONArray jsonArray = view_as<JSONArray>(dataObj.Get("stats"));
	
	char keyname[64];
	int size = jsonArray.Length;
	for (int i = 0; i < size; i++)
	{
		delete dataObj;
		dataObj = view_as<JSONObject>(jsonArray.Get(i));
		
		if ( dataObj.GetString("name", keyname, sizeof(keyname))
			&& strcmp(keyname, "Stat.TotalPlayTime.Total") == 0 )
		{
			// playtime is formatted in seconds
			player_t[client].realplaytime = dataObj.GetInt("value") / 60;
			break;
		}
	}
	
	delete jsonArray;
	delete dataObj;
}
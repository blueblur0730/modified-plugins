#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <geoip>
#include <log4sp>

#define TEAM_UNASSIGNED 0
#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define CONFIG_PATH "configs/savechat.cfg"

ConVar g_hMaxFile = null, g_hHostport = null;
char g_sDate[32], g_sChatFilePath[PLATFORM_MAX_PATH];
bool g_bLateLoad = false;
int g_iMaxFile = 1;
Logger g_hLogger = null;

#define PLUGIN_VERSION "r1.0"	// 1.3 reworked.

public Plugin myinfo = 
{
	name = "[Any] SaveChat",
	author = "citkabuto, sorallll, blueblur",	/* Extentsion: Log for SourcePawn by F1F88*/
	description = "Records player chat messages to a file",
	version = PLUGIN_VERSION,
	url = "https://github.com/blueblur0730/modified-plugins"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_savechat_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_hHostport = FindConVar("hostport");
	g_hMaxFile = CreateConVar("sm_savechat_maxfile", "10", "Maximum number of log files to keep", _, true, 1.0);
	g_hMaxFile.AddChangeHook(OnCvarChanged);
	OnCvarChanged(null, "", "");

	// if this is late load, sm handle is cleared, but the instance in the extension is still valid.
	// so we just retreive the existed logger instance.
	if (!g_bLateLoad)
	{
		FormatTime(g_sDate, sizeof(g_sDate), "%d-%m-%y", -1);
		BuildPath(Path_SM, g_sChatFilePath, sizeof(g_sChatFilePath), "/logs/savechat[%s]-port[%i].log", g_sDate, g_hHostport.IntValue);
		g_hLogger = Logger.CreateDailyFileLogger("savechat", g_sChatFilePath, 23, 59, _, g_iMaxFile);
	}
	else
	{
		g_hLogger = Logger.Get("savechat");
	}

	if (!g_hLogger) SetFailState("Failed to create log file.");
	g_hLogger.SetLevel(LogLevel_Info);
	g_hLogger.SetPattern("[%Y-%m-%d %H:%M:%S.%e] [%n] %v");
	g_hLogger.Info("--- [Any] SaveChat "...PLUGIN_VERSION..." Loaded. ---");
	g_hLogger.Flush();

	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);

	char sPath[128];
	KeyValues kv = new KeyValues("");
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_PATH);
	if (kv.ImportFromFile(sPath) && kv.GotoFirstSubKey())
	{
		do
		{
			static char sCommand[64];
			kv.GetString(NULL_STRING, sCommand, sizeof(sCommand));
			AddCommandListener(CommandListener, sCommand);
		}
		while (kv.GotoNextKey());
	}

	delete kv;
}

void OnCvarChanged(ConVar convar, const char[] oldvalue, const char[] newvalue)
{
	g_iMaxFile = g_hMaxFile.IntValue;
}

public void OnPluginEnd()
{
	if (g_hLogger) delete g_hLogger;
}

public void OnMapStart()
{
	StartOrEndPhrase(true);
}

public void OnMapEnd()
{
	StartOrEndPhrase(false);
}

void StartOrEndPhrase(bool bMapStatus)
{
	char sMap[255];
	GetCurrentMap(sMap, sizeof(sMap));

	g_hLogger.Info("--=================================================================--");
	g_hLogger.InfoAmxTpl("--- %s: %s ---", bMapStatus ? "Map Started" : "Map Ended", sMap);
	g_hLogger.Info("--=================================================================--");
}

public void OnClientPostAdminCheck(int client)
{
	if (IsFakeClient(client))
		return;

	char sCountry[3];
	char sPlayerIP[32];

	if (!GetClientIP(client, sPlayerIP, sizeof(sPlayerIP), true)) 
		strcopy(sCountry, sizeof(sCountry), "N/A");
	else 
	{
		if (!GeoipCode2(sPlayerIP, sCountry)) 
			strcopy(sCountry, sizeof(sCountry), "N/A");
	}

	g_hLogger.InfoAmxTpl("---[%s] %L 加入游戏 (%s)---", sCountry, client, sPlayerIP);
}

Action CommandListener(int client, char[] command, int argc)
{
	if (!IsClientInGame(client))
		return Plugin_Continue;

	int iIdleCient = -1;
	bool bIdle = false;
	if (IsFakeClient(client))
	{
		if (GetClientTeam(client) != TEAM_SURVIVOR)
			return Plugin_Continue;

		if (!(iIdleCient = GetIdlePlayerOfBot(client)))
			return Plugin_Continue;
		else bIdle = true;
	}

	static char sTeamName[12];
	static char sMessage[255];

	if (client > 0 && !bIdle) GetTeamNameEx(GetClientTeam(client), sTeamName, sizeof(sTeamName));
	GetCmdArgString(sMessage, sizeof(sMessage));
	StripQuotes(sMessage);

	g_hLogger.InfoAmxTpl("[%s] %N: [%s] %s",
			!client ? "Console" : (bIdle ? "Idle" : sTeamName),
			bIdle ? iIdleCient : client,
			command,
			sMessage);

	return Plugin_Continue;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	char sMap[255];
	GetCurrentMap(sMap, sizeof(sMap));

	g_hLogger.Info("--=================================================================--");
	g_hLogger.InfoAmxTpl("--- 回合结束: %s ---", sMap);
	g_hLogger.Info("--=================================================================--");
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	char sMap[255];
	GetCurrentMap(sMap, sizeof(sMap));

	g_hLogger.Info("--=================================================================--");
	g_hLogger.InfoAmxTpl("--- 回合开始: %s ---", sMap);
	g_hLogger.Info("--=================================================================--");
}

void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || IsFakeClient(client))
		return;

	char sMessage[255];
	event.GetString("reason", sMessage, sizeof(sMessage));
	g_hLogger.InfoAmxTpl("---%L 离开游戏 (reason: %s)---", client, sMessage);
}

void GetTeamNameEx(int team, char[] szName, int iMaxLen)
{
	switch (team)
	{
		case TEAM_UNASSIGNED:
			strcopy(szName, iMaxLen, "Unassigned");
		case TEAM_SPECTATOR:
			strcopy(szName, iMaxLen, "Spectator");
		case TEAM_SURVIVOR:
			strcopy(szName, iMaxLen, "Survivor");
		case TEAM_INFECTED:
			strcopy(szName, iMaxLen, "Infected");
	}
}

int GetIdlePlayerOfBot(int client) 
{
	if (!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
		return 0;

	return GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
}
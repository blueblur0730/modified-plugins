#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <regex>

// Requires l4d2_changelevel by Lux.
native void L4D2_ChangeLevel(const char[] sMapName, bool bShouldResetScores=true);

Handle g_hCoolDownTimer;

bool 
	g_bNoOneInServer, 
	g_bFirstMap, 
	g_bCmdMap,
	g_bAnyoneConnectedBefore;

ConVar 
	g_hCvar_DelayForMapRestart, 
	g_hCvar_DelayForServerRestart;

ConVar g_hCvar_Hibernate;
char g_sPath[256];
bool g_bChangeLevelAvailable = false;

#define PLUGIN_VERSION "r1.0"

public Plugin myinfo =
{
	name = "[ANY] Restarter",
	author = "Harry Potter, HatsuneImagin, devilesk, blueblur",
	description = "Map restarter and server restarter merger.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("L4D2_ChangeLevel");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslation("sm_restarter.phrases");

	CreateConVar("sm_restarter_version", PLUGIN_VERSION, "Plugin Version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_hCvar_DelayForMapRestart = CreateConVar("sm_restarter_map_delay", "5.0", "Delay for map restart.");
	g_hCvar_DelayForServerRestart = CreateConVar("sm_restarter_server_delay", "5.0", "Delay for server restart.");

	g_hCvar_Hibernate = FindConVar("sv_hibernate_when_empty");
	g_hCvar_Hibernate.AddChangeHook(ConVarChanged_Hibernate);

	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);	

	RegAdminCmd("sm_crash", Cmd_RestartServer, ADMFLAG_ROOT, "sm_crash - manually force the server to crash");
	RegAdminCmd("sm_restartmap", Command_RestartMap, ADMFLAG_CHEATS, "Admin starts a restart map action");

	g_bFirstMap = true;
	g_bCmdMap = false;
	AddCommandListener(ServerCmd_map, "map");

	BuildPath(Path_SM, g_sPath, sizeof(g_sPath), "logs/linux_auto_restart.log");
}

public void OnAllPluginsLoaded() { g_bChangeLevelAvailable = LibraryExists("l4d2_changelevel"); }
public void OnLibraryAdded(const char[] name){ if (StrEqual(name, "l4d2_changelevel")) g_bChangeLevelAvailable = true; }
public void OnLibraryRemoved(const char[] name){ if (StrEqual(name, "l4d2_changelevel")) g_bChangeLevelAvailable = false; }

public void OnPluginEnd()
{
	if (g_hCoolDownTimer)
	{
		g_hCoolDownTimer = null;
		delete g_hCoolDownTimer;
	}
}

public void OnMapEnd()
{
	if (g_hCoolDownTimer)
	{
		g_hCoolDownTimer = null;
		delete g_hCoolDownTimer;
	}	
}

public void OnConfigsExecuted()
{
	if (g_bNoOneInServer || ( !g_bFirstMap &&  (g_bCmdMap || g_bAnyoneConnectedBefore) ))
	{
		if (!CheckPlayerInGame(0))
		{
			if (g_hCoolDownTimer)
			{
				g_hCoolDownTimer = null;
				delete g_hCoolDownTimer;
			}

			g_hCoolDownTimer = CreateTimer(20.0, Timer_CoolDown);
		}
	}

	g_bFirstMap = false;
	g_bCmdMap = false;
}

public void OnClientConnected(int client)
{
	if (IsFakeClient(client)) 
		return;

	if (!g_bAnyoneConnectedBefore)
		g_hCvar_Hibernate.BoolValue = false;

	g_bAnyoneConnectedBefore = true;
}

void ConVarChanged_Hibernate(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	g_hCvar_Hibernate.BoolValue = false;
}

Action Cmd_RestartServer(int client, int args)
{
	if (client > 0 && !IsFakeClient(client))
	{
		char steamid[32];
		GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid), true);

		LogToFileEx(g_sPath, "Manually restarting server... by %N [%s]", client, steamid);
		PrintToServer("Manually restarting server in %.02f seconds later... by %N", g_hCvar_DelayForServerRestart.FloatValue, client);
		CPrintToChatAll("%t", "ManuallyRestartServer", client, g_hCvar_DelayForServerRestart.FloatValue);
	}
	else
	{
		LogToFileEx(g_sPath, "Manually restarting server by server console...");
		PrintToServer("Manually restarting server in %.02f seconds later... by %N", g_hCvar_DelayForServerRestart.FloatValue, client);
		CPrintToChatAll("%t", "ManuallyRestartServer_NoName", g_hCvar_DelayForServerRestart.FloatValue);
	}

	CreateTimer(g_hCvar_DelayForServerRestart.FloatValue, Timer_Cmd_RestartServer);

	return Plugin_Continue;
}

void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!client || IsFakeClient(client)) 
		return;

	if (!CheckPlayerInGame(client))
	{
		g_bNoOneInServer = true;

		if (g_hCoolDownTimer)
		{
			g_hCoolDownTimer = null;
			delete g_hCoolDownTimer;
		}	

		g_hCoolDownTimer = CreateTimer(15.0, Timer_CoolDown);
	}
}

void Timer_CoolDown(Handle timer, int client)
{
	if (CheckPlayerInGame(0))
	{
		g_bNoOneInServer = false;
		g_hCoolDownTimer = null;
		return;
	}
	
	if (CheckPlayerConnectingSV())
	{
		g_hCoolDownTimer = CreateTimer(20.0, Timer_CoolDown);
		return;
	}
	
	LogToFileEx(g_sPath, "Last one player left the server, Restart server now");
	PrintToServer("Last one player left the server, Restart server now");

	UnloadAccelerator();
	CreateTimer(0.1, Timer_RestartServer);

	g_hCoolDownTimer = null;
}

void Timer_Cmd_RestartServer(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) 
			continue;

		if (IsFakeClient(i)) 
			continue;

		KickClient(i, "%T", "ServerRestarting", i);	// Server is restarting
	}

	UnloadAccelerator();
	CreateTimer(0.2, Timer_RestartServer);
}

void Timer_RestartServer(Handle timer)
{
	SetCommandFlags("crash", GetCommandFlags("crash") &~ FCVAR_CHEAT);
	ServerCommand("crash");
}

void UnloadAccelerator()
{
	char responseBuffer[4096];
	
	// fetch a list of sourcemod extensions
	ServerCommandEx(responseBuffer, sizeof(responseBuffer), "%s", "sm exts list");
	
	// matching ext name only should sufiice
	Regex regex = new Regex("\\[([0-9]+)\\] Accelerator");
	
	// actually matched?
	// CapcureCount == 2? (see @note of "Regex.GetSubString" in regex.inc)
	if (regex.Match(responseBuffer) > 0 && regex.CaptureCount() == 2)
	{
		char sAcceleratorExtNum[4];
		
		// 0 is the full string "[?] Accelerator"
		// 1 is the matched extension number
		regex.GetSubString(1, sAcceleratorExtNum, sizeof(sAcceleratorExtNum));
		
		// unload it
		ServerCommand("sm exts unload %s 0", sAcceleratorExtNum);
		ServerExecute();
	}
	
	delete regex;
}

Action ServerCmd_map(int client, const char[] command, int argc)
{
	g_bCmdMap = true;
	return Plugin_Continue;
}

void RestartMap() 
{
	char sMap[128];
    GetCurrentMapLower(sMap, sizeof(sMap));
    g_bChangeLevelAvailable ? L4D2_ChangeLevel(sMap) : ServerCommand("changelevel %s", sMap);
}

Action Command_RestartMap(int client, int args)
{
    CPrintToChatAll("%t", "RestartingMap", g_hCvar_DelayForMapRestart);
    CreateTimer(g_hCvar_DelayForMapRestart.FloatValue, Timer_RestartMapPre);
    return Plugin_Handled;
}

void Timer_RestartMapPre(Handle Timer)
{
    RestartMap();
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

stock bool CheckPlayerInGame(int client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && i !=client)
			return true;
	}

	return false;
}

stock bool CheckPlayerConnectingSV()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsClientInGame(i) && !IsFakeClient(i))
			return true;
	}

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
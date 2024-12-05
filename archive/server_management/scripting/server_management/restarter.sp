#if defined _server_management_restarter_included
	#endinput
#endif
#define _server_management_restarter_included

#include <regex>

#undef REQUIRE_PLUGIN
#include <l4d2_changelevel>

#define MAXMAP                  32

//----------------------------------------------------------------------------------------------------
// Server Restarter & Map Restarter by Harry Potter, HatsuneImagin, devilesk, modified by blueblur
//----------------------------------------------------------------------------------------------------

static ConVar g_hConVarHibernate;
static Handle g_hCoolDownTimer;

static bool 
	g_bNoOneInServer, 
	g_bFirstMap, 
	g_bCmdMap,
	g_bAnyoneConnectedBefore;

static int g_iMapRestarts;         // current number of restart attempts
static bool g_bIsMapRestarted;		// whether map has been restarted by this plugin

static ConVar 
	g_hCvarDebug, 
	g_hCvarAutofix, 
	g_hCvarAutofixMaxTries; // max number of restart attempts convar

static int g_iSurvivorScore;
static int g_iInfectedScore;
static char g_sMapName[MAXMAP] = "";

static char g_sPath[256];

void _restarter_OnPluginStart()
{
	LoadTranslation("server_management.restarter.phrases");

    g_hCvarDebug = CreateConVar("sm_restartmap_debug", "0", "Restart Map debug mode", 0, true, 0.0, true, 1.0);
    g_hCvarAutofix = CreateConVar("sm_restartmap_autofix", "1", "Check for broken flow on map load and automatically restart.", 0, true, 0.0, true, 1.0);
    g_hCvarAutofixMaxTries = CreateConVar("sm_restartmap_autofix_max_tries", "1", "Max number of automatic restart attempts to fix broken flow.", 0, true, 1.0);

	g_hConVarHibernate = FindConVar("sv_hibernate_when_empty");
	g_hConVarHibernate.AddChangeHook(ConVarChanged_Hibernate);

    g_iMapRestarts = 0;
    g_bIsMapRestarted = false;

	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);	

	RegAdminCmd("sm_crash", Cmd_RestartServer, ADMFLAG_ROOT, "sm_crash - manually force the server to crash");
	RegAdminCmd("sm_restartmap", Command_RestartMap, ADMFLAG_CHEATS, "Admin starts a restart map action");

	g_bFirstMap = true;
	g_bCmdMap = false;
	AddCommandListener(ServerCmd_map, "map");

	BuildPath(Path_SM, g_sPath, sizeof(g_sPath), "logs/linux_auto_restart.log");
}

void _restarter_OnPluginEnd()
{
	if (g_hCoolDownTimer)
		delete g_hCoolDownTimer;
}

void _restarter_OnMapStart()
{
    // Compare current map to previous map and reset if different.
    char sBuffer[MAXMAP];
    GetCurrentMapLower(sBuffer, sizeof(sBuffer));
    if (!StrEqual(g_sMapName, sBuffer, false)) 
    {
        g_bIsMapRestarted = false;
        g_iMapRestarts = 0;
    }
    
    // Start broken flow check timer if autofix enabled and max tries not reached
    if (g_hCvarAutofix.BoolValue && g_iMapRestarts < g_hCvarAutofixMaxTries.IntValue)
        CreateTimer(2.0, CheckFlowBroken, _, TIMER_FLAG_NO_MAPCHANGE);
    
    // Set scores if map restarted
    if (g_bIsMapRestarted) 
	{
        PrintDebug("[OnMapStart] Restarted. Setting scores... survivor score %i, infected score %i", g_iSurvivorScore, g_iInfectedScore);
        
        //Set the scores
        SDKCall(g_hSDKCall_fSetCampaignScores, g_iSurvivorScore, g_iInfectedScore); //visible scores
        L4D2Direct_SetVSCampaignScore(0, g_iSurvivorScore); //real scores
        L4D2Direct_SetVSCampaignScore(1, g_iInfectedScore);
        
        g_bIsMapRestarted = false;
    }
}

void _restarter_OnMapEnd()
{
	if (g_hCoolDownTimer)
		delete g_hCoolDownTimer;
}

void _restarter_OnConfigsExecuted()
{
	if(g_bNoOneInServer || ( !g_bFirstMap &&  (g_bCmdMap || g_bAnyoneConnectedBefore) ))
	{
		if(CheckPlayerInGame(0) == false) //沒有玩家在伺服器中
		{
			if (g_hCoolDownTimer)
				delete g_hCoolDownTimer;

			g_hCoolDownTimer = CreateTimer(20.0, COLD_DOWN);
		}
	}

	g_bFirstMap = false;
	g_bCmdMap = false;
}

void _restarter_OnClientConnected(int client)
{
	if(IsFakeClient(client)) return;

	if(!g_bAnyoneConnectedBefore)
		g_hConVarHibernate.SetBool(false);

	g_bAnyoneConnectedBefore = true;
}

static void ConVarChanged_Hibernate(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	g_hConVarHibernate.SetBool(false);
}

static Action Cmd_RestartServer(int client, int args)
{
	if(client > 0 && !IsFakeClient(client))
	{
		static char steamid[32];
		GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid), true);

		LogToFileEx(g_sPath, "Manually restarting server... by %N [%s]", client, steamid);
		PrintToServer("Manually restarting server in 5 seconds later... by %N", client);
		CPrintToChatAll("%t", "ManuallyRestartServer", client);
	}
	else
	{
		LogToFileEx(g_sPath, "Manually restarting server by server console...");
		PrintToServer("Manually restarting server in 5 seconds later...");
		CPrintToChatAll("%t", "ManuallyRestartServer_NoName");
	}

	CreateTimer(5.0, Timer_Cmd_RestartServer);

	return Plugin_Continue;
}

static void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || IsFakeClient(client) /*|| (IsClientConnected(client) && !IsClientInGame(client))*/) return;

	if(!CheckPlayerInGame(client)) //檢查是否還有玩家以外的人還在伺服器
	{
		g_bNoOneInServer = true;

		if (g_hCoolDownTimer)
			delete g_hCoolDownTimer;

		g_hCoolDownTimer = CreateTimer(15.0, COLD_DOWN);
	}
}

static Action COLD_DOWN(Handle timer, any client)
{
	if(CheckPlayerInGame(0)) //有玩家在伺服器中
	{
		g_bNoOneInServer = false;
		g_hCoolDownTimer = null;
		return Plugin_Continue;
	}
	
	if(CheckPlayerConnectingSV()) //沒有玩家在伺服器但是有玩家正在連線
	{
		g_hCoolDownTimer = CreateTimer(20.0, COLD_DOWN); //重新計時
		return Plugin_Continue;
	}
	
	LogToFileEx(g_sPath, "Last one player left the server, Restart server now");
	PrintToServer("Last one player left the server, Restart server now");

	UnloadAccelerator();

	CreateTimer(0.1, Timer_RestartServer);

	g_hCoolDownTimer = null;
	return Plugin_Continue;
}

static Action Timer_RestartServer(Handle timer)
{
	SetCommandFlags("crash", GetCommandFlags("crash") &~ FCVAR_CHEAT);
	ServerCommand("crash");

	//SetCommandFlags("sv_crash", GetCommandFlags("sv_crash") &~ FCVAR_CHEAT);
	//ServerCommand("sv_crash");//crash server, make linux auto restart server

	return Plugin_Continue;
}

static Action Timer_Cmd_RestartServer(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i)) continue;
		if(IsFakeClient(i)) continue;

		char sBuffer[32];
		Format(sBuffer, sizeof(sBuffer), "%T", "ServerRestarting", i);
		KickClient(i, "Server is restarting");
	}
	UnloadAccelerator();
	CreateTimer(0.2, Timer_RestartServer);

	return Plugin_Continue;
}

static void UnloadAccelerator()
{
	/*if( g_iCvarUnloadExtNum )
	{
		ServerCommand("sm exts unload %i 0", g_iCvarUnloadExtNum);
	}*/

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

//從大廳匹配觸發map
static Action ServerCmd_map(int client, const char[] command, int argc)
{
	g_bCmdMap = true;

	return Plugin_Continue;
}

static Action CheckFlowBroken(Handle timer) 
{
    bool bIsFlowBroken = IsFlowBroken();
    PrintDebug("[CheckFlowBroken] Flow broken: %i", bIsFlowBroken);
    if (bIsFlowBroken) 
    {
        PrintToChatAll("%t", "BrokenFlowDetected");
        PrintToConsoleAll("Broken flow detected.");
        PrintDebug("Broken flow detected.");
        CreateTimer(5.0, RestartMapPre);
    }
    else
        g_iMapRestarts = 0;


    return Plugin_Continue;
}

static void RestartMap() 
{
    if (L4D_IsVersusMode())
    {

        int iSurvivorTeamIndex = GameRules_GetProp("m_bAreTeamsFlipped") ? 1 : 0;
        int iInfectedTeamIndex = GameRules_GetProp("m_bAreTeamsFlipped") ? 0 : 1;

        g_iSurvivorScore = L4D2Direct_GetVSCampaignScore(iSurvivorTeamIndex);
        g_iInfectedScore = L4D2Direct_GetVSCampaignScore(iInfectedTeamIndex);
    
        g_bIsMapRestarted = true;
        g_iMapRestarts++;
    
        PrintToConsoleAll("[RestartMap] Restarting map. Attempt: %i of %i... survivor: %i, score %i, infected: %i, score %i", g_iMapRestarts, g_hCvarAutofixMaxTries.IntValue, iSurvivorTeamIndex, g_iSurvivorScore, iInfectedTeamIndex, g_iInfectedScore);
        PrintDebug("[RestartMap] Restarting map. Attempt: %i of %i...  survivor: %i, score %i, infected: %i, score %i", g_iMapRestarts, g_hCvarAutofixMaxTries.IntValue, iSurvivorTeamIndex, g_iSurvivorScore, iInfectedTeamIndex, g_iInfectedScore);
    }

    GetCurrentMapLower(g_sMapName, sizeof(g_sMapName));

    if (g_bChangeLevelAvailable)
        L4D2_ChangeLevel(g_sMapName);
    else
        ServerCommand("sm_map %s", g_sMapName);
}

static bool IsFlowBroken() 
{
    return (L4D2Direct_GetMapMaxFlowDistance() == 0);
}

static Action Command_RestartMap(int client, int args)
{
    if (CheckCommandAccess(client, "sm_restartmap", ADMFLAG_CHEATS, true)) 
    {
        if (L4D_IsVersusMode()) CPrintToChatAll("%t", "VersusRestarting");
        else CPrintToChatAll("%t", "Restarting");
        
        CreateTimer(5.0, RestartMapPre);
    }

    return Plugin_Handled;
}

static Action RestartMapPre(Handle Timer)
{
    RestartMap();
    return Plugin_Continue;
}

static stock void PrintDebug(const char[] Message, any ...) 
{
    if (g_hCvarDebug.BoolValue) 
    {
        char DebugBuff[256];
        VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
        LogMessage(DebugBuff);
    }
}
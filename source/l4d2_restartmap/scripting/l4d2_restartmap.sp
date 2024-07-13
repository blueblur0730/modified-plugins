#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <colors>
#undef REQUIRE_PLUGIN
#include <l4d2_changelevel>

#define TEAM_SPECTATOR          1
#define MAXMAP                  32

// Used to set the scores
Handle g_hSDKCall_fSetCampaignScores;

int g_iMapRestarts;                                     // current number of restart attempts
bool g_bIsMapRestarted;                             // whether map has been restarted by this plugin
ConVar g_hCvarDebug, g_hCvarAutofix, g_hCvarAutofixMaxTries;     // max number of restart attempts convar

int g_iSurvivorScore;
int g_iInfectedScore;
char g_sMapName[MAXMAP] = "";
bool g_ChangeLevelAvailable = false;

public Plugin myinfo = 
{
    name = "[L4D2] Restart Map",
    author = "devilesk, modified by blueblur",
    description = "Adds sm_restartmap to restart the current map and keep current scores. Automatically restarts map when broken flow detected.",
    version = "1.2.0",
    url = "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart() 
{
    g_hCvarDebug = CreateConVar("sm_restartmap_debug", "0", "Restart Map debug mode", 0, true, 0.0, true, 1.0);
    g_hCvarAutofix = CreateConVar("sm_restartmap_autofix", "1", "Check for broken flow on map load and automatically restart.", 0, true, 0.0, true, 1.0);
    g_hCvarAutofixMaxTries = CreateConVar("sm_restartmap_autofix_max_tries", "1", "Max number of automatic restart attempts to fix broken flow.", 0, true, 1.0);
    
    RegAdminCmd("sm_restartmap", Command_RestartMap, ADMFLAG_CHEATS, "Admin starts a restart map action");
    LoadTranslations("l4d2_restartmap.phrases");
    
    g_iMapRestarts = 0;
    g_bIsMapRestarted = false;
    
    GameData gd = new GameData("left4dhooks.l4d2");
    if(gd == null)
        SetFailState("Could not load gamedata/left4dhooks.l4d2.txt");

    StartPrepSDKCall(SDKCall_GameRules);
    if (!PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "CTerrorGameRules::SetCampaignScores"))
        SetFailState("Function 'SetCampaignScores' not found.");

    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    g_hSDKCall_fSetCampaignScores = EndPrepSDKCall();
    if (g_hSDKCall_fSetCampaignScores == null)
        SetFailState("Failed to prepare SDK call for 'SetCampaignScores'.");

    delete gd;
}

public void OnAllPluginsLoaded() 
{
    g_ChangeLevelAvailable = LibraryExists("l4d2_changelevel");
}

public void OnLibraryAdded(const char[] name) 
{
    if (StrEqual(name, "l4d2_changelevel")) g_ChangeLevelAvailable = true;
}

public void OnLibraryRemoved(const char[] name) 
{
    if ( StrEqual(name, "l4d2_changelevel") ) { g_ChangeLevelAvailable = false; }
}

public void OnMapStart() 
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
    if (g_bIsMapRestarted) {
        PrintDebug("[OnMapStart] Restarted. Setting scores... survivor score %i, infected score %i", g_iSurvivorScore, g_iInfectedScore);
        
        //Set the scores
        SDKCall(g_hSDKCall_fSetCampaignScores, g_iSurvivorScore, g_iInfectedScore); //visible scores
        L4D2Direct_SetVSCampaignScore(0, g_iSurvivorScore); //real scores
        L4D2Direct_SetVSCampaignScore(1, g_iInfectedScore);
        
        g_bIsMapRestarted = false;
    }
}

Action CheckFlowBroken(Handle timer) 
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

void RestartMap() 
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

    if (g_ChangeLevelAvailable)
        L4D2_ChangeLevel(g_sMapName);
    else
        ServerCommand("sm_map %s", g_sMapName);
}

bool IsFlowBroken() 
{
    return (L4D2Direct_GetMapMaxFlowDistance() == 0);
}

Action Command_RestartMap(int client, int args)
{
    if (CheckCommandAccess(client, "sm_restartmap", ADMFLAG_CHEATS, true)) 
    {
        if (L4D_IsVersusMode()) CPrintToChatAll("%t", "VersusRestarting");
        else CPrintToChatAll("%t", "Restarting");
        
        CreateTimer(5.0, RestartMapPre);
    }

    return Plugin_Handled;
}

Action RestartMapPre(Handle Timer)
{
    RestartMap();
    return Plugin_Continue;
}

void PrintDebug(const char[] Message, any ...) 
{
    if (g_hCvarDebug.BoolValue) 
    {
        char DebugBuff[256];
        VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
        LogMessage(DebugBuff);
    }
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
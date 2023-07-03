#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
//#include <builtinvotes>
#undef REQUIRE_PLUGIN
#include <team_consistency>
#include <l4d2_changelevel>
#define REQUIRE_PLUGIN
#include "includes/rl4d2l_util"
#include <colors>

#pragma newdecls required

#define TEAM_SPECTATOR          1
#define MAXMAP                  32

// Used to set the scores
Handle gConf = INVALID_HANDLE;
Handle fSetCampaignScores = INVALID_HANDLE;

int g_iMapRestarts;                                     // current number of restart attempts
bool g_bIsMapRestarted;                             // whether map has been restarted by this plugin
Handle g_hCvarDebug = INVALID_HANDLE;
Handle g_hCvarAutofix = INVALID_HANDLE;
Handle g_hCvarAutofixMaxTries = INVALID_HANDLE;     // max number of restart attempts convar
//Handle hVote;                                       // restart vote handle
int g_iSurvivorScore;
int g_iInfectedScore;
char g_sMapName[MAXMAP] = "";
bool g_L4D2ChangeLevelAvailable = false;
bool g_bTeamConsistencyAvailable = false;

ConVar cvarGameMode;

public Plugin myinfo = {
    name = "L4D2 Restart Map",
    author = "devilesk, modified by blueblur",
    description = "Adds sm_restartmap to restart the current map and keep current scores. Automatically restarts map when broken flow detected.",
    version = "1.1.1",
    url = "https://github.com/devilesk/rl4d2l-plugins"
};

public void OnPluginStart() {
    g_hCvarDebug = CreateConVar("sm_restartmap_debug", "0", "Restart Map debug mode", 0, true, 0.0, true, 1.0);
    g_hCvarAutofix = CreateConVar("sm_restartmap_autofix", "1", "Check for broken flow on map load and automatically restart.", 0, true, 0.0, true, 1.0);
    g_hCvarAutofixMaxTries = CreateConVar("sm_restartmap_autofix_max_tries", "1", "Max number of automatic restart attempts to fix broken flow.", 0, true, 1.0);
    
    RegAdminCmd("sm_restartmap", Command_RestartMap, ADMFLAG_CONFIG, "Admin starts a restart map action");
    LoadTranslations("l4d2_restartmap.phrases");
    
    g_iMapRestarts = 0;
    g_bIsMapRestarted = false;

    cvarGameMode = FindConVar("mp_gamemode");
    
    gConf = LoadGameConfigFile("left4dhooks.l4d2");
    if(gConf == INVALID_HANDLE) {
        LogError("Could not load gamedata/left4dhooks.l4d2.txt");
    }

    StartPrepSDKCall(SDKCall_GameRules);
    if (PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "CTerrorGameRules::SetCampaignScores")) {
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        fSetCampaignScores = EndPrepSDKCall();
        if (fSetCampaignScores == INVALID_HANDLE) {
            LogError("Function 'SetCampaignScores' found, but something went wrong.");
        }
    }
    else {
        LogError("Function 'SetCampaignScores' not found.");
    }
}

public void OnAllPluginsLoaded() {
    g_L4D2ChangeLevelAvailable = LibraryExists("l4d2_changelevel");
    g_bTeamConsistencyAvailable = LibraryExists("team_consistency");
}
public void OnLibraryRemoved(const char[] name) {
    if ( StrEqual(name, "l4d2_changelevel") ) { g_L4D2ChangeLevelAvailable = false; }
    else if ( StrEqual(name, "team_consistency") ) { g_bTeamConsistencyAvailable = false; }
}
public void OnLibraryAdded(const char[] name) {
    if ( StrEqual(name, "l4d2_changelevel") ) { g_L4D2ChangeLevelAvailable = true; }
    else if ( StrEqual(name, "team_consistency") ) { g_bTeamConsistencyAvailable = true; }
}

public void OnMapStart() {
    // Compare current map to previous map and reset if different.
    char sBuffer[MAXMAP];
    GetCurrentMapLower(sBuffer, sizeof(sBuffer));
    if (!StrEqual(g_sMapName, sBuffer, false)) {
        g_bIsMapRestarted = false;
        g_iMapRestarts = 0;
    }
    
    // Start broken flow check timer if autofix enabled and max tries not reached
    if (GetConVarBool(g_hCvarAutofix) && g_iMapRestarts < GetConVarInt(g_hCvarAutofixMaxTries)) {
        CreateTimer(2.0, CheckFlowBroken, _, TIMER_FLAG_NO_MAPCHANGE);
    }
    
    // Set scores if map restarted
    if (g_bIsMapRestarted) {
        PrintDebug("[OnMapStart] Restarted. Setting scores... survivor score %i, infected score %i", g_iSurvivorScore, g_iInfectedScore);
        
        //Set the scores
        SDKCall(fSetCampaignScores, g_iSurvivorScore, g_iInfectedScore); //visible scores
        L4D2Direct_SetVSCampaignScore(0, g_iSurvivorScore); //real scores
        L4D2Direct_SetVSCampaignScore(1, g_iInfectedScore);
        
        g_bIsMapRestarted = false;
    }
}

public Action CheckFlowBroken(Handle timer) {
    bool bIsFlowBroken = IsFlowBroken();
    PrintDebug("[CheckFlowBroken] Flow broken: %i", bIsFlowBroken);
    if (bIsFlowBroken) {
        PrintToChatAll("%t", "BrokenFlowDetected");
        // Broken flow detected.
        PrintToConsoleAll("Broken flow detected.");
        PrintDebug("Broken flow detected.");
        CreateTimer(5.0, RestartMapPre);
        //RestartMap();
    }
    else {
        g_iMapRestarts = 0;
    }

    return Plugin_Continue;
}

public void RestartMap() 
{
    if (IsVersusMode())
    {

        int iSurvivorTeamIndex = GameRules_GetProp("m_bAreTeamsFlipped") ? 1 : 0;
        int iInfectedTeamIndex = GameRules_GetProp("m_bAreTeamsFlipped") ? 0 : 1;

        g_iSurvivorScore = L4D2Direct_GetVSCampaignScore(iSurvivorTeamIndex);
        g_iInfectedScore = L4D2Direct_GetVSCampaignScore(iInfectedTeamIndex);
    
        g_bIsMapRestarted = true;
        g_iMapRestarts++;
    
        PrintToConsoleAll("[RestartMap] Restarting map. Attempt: %i of %i... survivor: %i, score %i, infected: %i, score %i", g_iMapRestarts, GetConVarInt(g_hCvarAutofixMaxTries), iSurvivorTeamIndex, g_iSurvivorScore, iInfectedTeamIndex, g_iInfectedScore);
        PrintDebug("[RestartMap] Restarting map. Attempt: %i of %i...  survivor: %i, score %i, infected: %i, score %i", g_iMapRestarts, GetConVarInt(g_hCvarAutofixMaxTries), iSurvivorTeamIndex, g_iSurvivorScore, iInfectedTeamIndex, g_iInfectedScore);
    }

    GetCurrentMapLower(g_sMapName, sizeof(g_sMapName));
    if (g_bTeamConsistencyAvailable)
        ClearTeamConsistency();

    if (g_L4D2ChangeLevelAvailable)
        L4D2_ChangeLevel(g_sMapName);
    else
        ServerCommand("sm_map %s", g_sMapName);
}
/*
bool IsSpectator(int client) {
    return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_SPECTATOR;
}

bool CanStartVote(int client) {
    if (IsSpectator(client)) {
        PrintToChat(client, "%t", "OnlyPlayer");
        // \x01[\x04Restart Map\x01] Vote can only be started by a player!
        return false;
    }
    return true;
}
*/
bool IsFlowBroken() {
    return L4D2Direct_GetMapMaxFlowDistance() == 0;
}

public Action Command_RestartMap(int client, int args)
{
    if (CheckCommandAccess(client, "sm_restartmap", ADMFLAG_KICK, true)) 
    {
        if (IsVersusMode())
        {
            CPrintToChatAll("%t", "VersusRestarting");
        }
        else
        {
            CPrintToChatAll("%t", "Restarting");
        }
        
        CreateTimer(5.0, RestartMapPre);
        //RestartMap();
    }
    /*
    else if (CanStartVote(client)) {
        char prompt[100];
        Format(prompt, sizeof(prompt), "%t", "Confirm");
        // Restart map? Scores will be preserved.
        if (StartVote(client, prompt)) {
            FakeClientCommand(client, "Vote Yes");
        }
    }
    */
    return Plugin_Handled;
}

public Action RestartMapPre(Handle Timer)
{
    RestartMap();
    return Plugin_Continue;
}

/*
bool StartVote(int client, const char[] sVoteHeader) {
    if (IsNewBuiltinVoteAllowed()) {
        int iNumPlayers;
        int[] players = new int[MaxClients];
        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientConnected(i) || !IsClientInGame(i)) continue;
            if (IsSpectator(i) || IsFakeClient(i)) continue;
            
            players[iNumPlayers++] = i;
        }

        hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
        SetBuiltinVoteArgument(hVote, sVoteHeader);
        SetBuiltinVoteInitiator(hVote, client);
        SetBuiltinVoteResultCallback(hVote, VoteResultHandler);
        DisplayBuiltinVote(hVote, players, iNumPlayers, 20);
        return true;
    }

    PrintToChat(client, "%t", "CannotVote");
    // \x01[\x04Restart Map\x01] Vote cannot be started now.
    return false;
}

public void VoteActionHandler(Handle vote, BuiltinVoteAction action, int param1, int param2) {
    switch (action) {
        case BuiltinVoteAction_End: {
            hVote = INVALID_HANDLE;
            CloseHandle(vote);
        }
        case BuiltinVoteAction_Cancel: {
            DisplayBuiltinVoteFail(vote, view_as<BuiltinVoteFailReason>(param1));
        }
    }
}

public void VoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info) {
    for (int i = 0; i < num_items; i++) {
        if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES) {
            if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_clients / 2)) {
                DisplayBuiltinVotePass(vote, "Restarting map...");
                PrintToChatAll("%t", "Restarting");
                // \x01[\x04Restart Map\x01] Vote passed! Restarting map...
                RestartMap();
                return;
            }
        }
    }
    DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}
*/

stock void PrintDebug(const char[] Message, any ...) {
    if (GetConVarBool(g_hCvarDebug)) {
        char DebugBuff[256];
        VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
        LogMessage(DebugBuff);
    }
}

stock bool IsVersusMode()
{
    char sGameMode[32];
	GetConVarString(cvarGameMode, sGameMode, sizeof(sGameMode));
	if (StrContains(sGameMode, "versus") > -1)
	{
		return true;
	}
	else
	{
		return false;
	}
}

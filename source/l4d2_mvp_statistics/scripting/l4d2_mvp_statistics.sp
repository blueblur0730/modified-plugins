#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>
#include <l4d2util>
#include <colors>
#include <l4d2_ff_manager>

#define ZC_SMOKER				1
#define ZC_BOOMER				2
#define ZC_HUNTER				3
#define ZC_SPITTER				4
#define ZC_JOCKEY				5
#define ZC_CHARGER				6
#define ZC_WITCH				7
#define ZC_TANK					8

#define BREV_SI                 1
#define BREV_CI                 2
#define BREV_FF                 4
#define BREV_RANK               8

#define CONBUFSIZE              1024
#define CONBUFSIZELARGE         4096

#define CHARTHRESHOLD           160         // detecting unicode stuff
#define L4D2_MAXPLAYERS 32

Handle g_hTimer;

ConVar
    g_hCvar_PluginEnabled,      // whether the plugin is enabled
    g_hCvar_CountTankDamage,    // whether we're tracking tank damage for MVP-selection
    g_hCvar_CountWitchDamage,   // whether we're tracking witch damage for MVP-selection
    g_hCvar_BrevityFlags,       // how verbose/brief the output should be:
    g_hCvar_RankOrder,          // how to arrange the MVP-list.
    g_hCvar_ListLimit,          // how many MVPs to display.

    g_hCvar_AdRank,             // ad rank for the chat.
    g_hCvar_AdInterval,         // ad interval for the chat.

    g_hCvar_RecordBeforeLeave;  // whether to record stats before leaving the safe area.

bool 
    g_bCountTankDamage,
    g_bCountWitchDamage;

int g_iBrevityFlags;

bool
    g_bTankSpawn_Evented = false,              // When tank is spawned
    g_bInRound,
    g_bPlayerLeftStartArea;                    // used for tracking FF when RUP enabled

#include "l4d2_mvp_statistics/tracking.sp"
#include "l4d2_mvp_statistics/reporting.sp"

#define PLUGIN_VERSION "r2.3.4"
public Plugin myinfo =
{
	name = "[L4D2] Survivor MVP Statistics",
	author = "Tabun, Artifacial, Competitive Reowrk Team, blueblur",
	description = "MVP Statistics for the Survivor team.",
	version = PLUGIN_VERSION,
	url = "https://github.com/blueblur0730/modified-plugins"
};

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int errMax)
{
	return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslation("l4d2_mvp_statistics.phrases");

    // Round triggers
    HookEvent("finale_vehicle_leaving", FinaleEnd_Event, EventHookMode_PostNoCopy);
    HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
    HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);
    HookEvent("map_transition", RoundEnd_Event, EventHookMode_PostNoCopy);
    HookEvent("scavenge_round_start", ScavRoundStart_Event, EventHookMode_PostNoCopy);
    HookEvent("player_left_safe_area", PlayerLeftSafeArea_Event, EventHookMode_PostNoCopy);
    HookEvent("charger_carry_end", ChargerCarryEnd_Event);
    HookEvent("jockey_ride", JockeyRide_Event);
    HookEvent("lunge_pounce", HunterLunged_Event);
    HookEvent("choke_start", SmokerChoke_Event);
    HookEvent("tank_killed", TankKilled_Event);
    HookEvent("tank_spawn", TankSpawn_Event);
    
    // Catching data
    HookEvent("player_hurt", PlayerHurt_Event, EventHookMode_Post);
    HookEvent("player_death", PlayerDeath_Event, EventHookMode_Post);
    HookEvent("player_incapacitated", PlayerIncapacitated_Event, EventHookMode_Post);
    HookEvent("infected_hurt" ,InfectedHurt_Event, EventHookMode_Post);
    HookEvent("infected_death", InfectedDeath_Event, EventHookMode_Post);
    
    // Cvars
    g_hCvar_PluginEnabled =    CreateConVar("l4d2_mvp_statistics_enabled", "1", "Enable display of MVP at end of round");
    g_hCvar_CountTankDamage =  CreateConVar("l4d2_mvp_statistics_counttank", "1", "Damage on tank counts towards MVP-selection if enabled.");
    g_hCvar_CountWitchDamage = CreateConVar("l4d2_mvp_statistics_countwitch", "1", "Damage on witch counts towards MVP-selection if enabled.");
    g_hCvar_BrevityFlags =     CreateConVar("l4d2_mvp_statistics_brevity", "15", "Flags for setting brevity of MVP report (hide 1:SI, 2:CI, 4:FF, 8:rank).");
    g_hCvar_RankOrder =        CreateConVar("l4d2_mvp_statistics_rank_order", "1", "1: SI first, 2: SI Damage First, 3: SI + CI Total Damage First.");
    g_hCvar_ListLimit =        CreateConVar("l4d2_mvp_statistics_list_limit", "4", "How many MVPs to display.");

    g_hCvar_AdRank =           CreateConVar("l4d2_mvp_statistics_ad_rank", "1", "Ad rank for the chat.");
    g_hCvar_AdInterval =       CreateConVar("l4d2_mvp_statistics_ad_interval", "80", "Ad interval for the chat.");

    g_hCvar_RecordBeforeLeave = CreateConVar("l4d2_mvp_statistics_record_before_leave", "1", "Record stats before leaving the safe area.");
    
    g_bCountTankDamage =  g_hCvar_CountTankDamage.BoolValue;
    g_bCountWitchDamage = g_hCvar_CountWitchDamage.BoolValue;
    g_iBrevityFlags =     g_hCvar_BrevityFlags.IntValue;
    
    g_hCvar_CountTankDamage.AddChangeHook(ConVarChange_CountTankDamage);
    g_hCvar_CountWitchDamage.AddChangeHook(ConVarChange_CountWitchDamage);
    g_hCvar_BrevityFlags.AddChangeHook(ConVarChange_BrevityFlags);
    
    g_bPlayerLeftStartArea = false;
    
    // Commands
    RegConsoleCmd("sm_mvp", SurvivorMVP_Cmd, "Prints the current MVP for the survivor team");
    RegConsoleCmd("sm_mvpme", ShowMVPStats_Cmd, "Prints the client's own MVP-related stats");
}

Action SurvivorMVP_Cmd(int client, int args)
{
    PrintMVPString();
    PrintLoserz(true, client);
    return Plugin_Handled;
}

Action ShowMVPStats_Cmd(int client, int args)
{
    PrintLoserz(true, client);
    return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
    char tmpBuffer[64];
    GetClientName(client, tmpBuffer, sizeof(tmpBuffer));
    
    // if previously stored name for same client is not the same, delete stats & overwrite name
    if (strcmp(tmpBuffer, g_Statistics[client].m_szName, true) != 0)
    {
        g_Statistics[client].Clear();

        // store name for later reference
        strcopy(g_Statistics[client].m_szName, sizeof(tmpBuffer), tmpBuffer);
    }
}

void ConVarChange_CountTankDamage(ConVar cvar, const char[] oldValue, const char[] newValue) 
{
    g_bCountTankDamage = StringToInt(newValue) != 0;
}

void ConVarChange_CountWitchDamage(ConVar cvar, const char[] oldValue, const char[] newValue) 
{
    g_bCountWitchDamage = StringToInt(newValue) != 0;
}

void ConVarChange_BrevityFlags(ConVar cvar, const char[] oldValue, const char[] newValue) 
{
    g_iBrevityFlags = StringToInt(newValue);
}

public void OnMapStart()
{
    g_bPlayerLeftStartArea = false;
}

public void OnMapEnd()
{
    g_bInRound = false;
    g_hTimer = null;
}

void ClearGlobals()
{
    g_iTotalKills = 0;
    g_iTotalCommon = 0;
    g_iTotalDamageAll = 0;
    g_iTotalFF = 0;
    g_TotalCommonKilledDuringTank = 0;
    
    g_bInRound = true;
    g_bTankSpawn_Evented = false;
}

void Timer_AdRank(Handle timer)
{
    PrintRank();
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

stock bool IsClientAndInGame(int index)
{
    return (index > 0 && index <= MaxClients && IsClientInGame(index));
}

stock bool IsWitch(int iEntity)
{
	if (iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		char strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "witch");
	}
	return false;
}
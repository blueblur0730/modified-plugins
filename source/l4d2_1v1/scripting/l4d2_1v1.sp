#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <l4d2util>
#include <colors>
#include <dhooks>

#define PLUGIN_VERSION		 "1.5"

#define GAMEDATA_FILE		 "l4d2_1v1"
#define TRANSLATION_FILE	 "l4d2_1v1.phrases"
#define DETOUR_FUNCTION		 "CTerrorPlayer::IsDominatedBySpecialInfected"
//#define SDKCALL_FUNCTION	 "CTerrorPlayer::GetSpecialInfectedDominatingMe"	// for unknow reason this function keeps returning 0. abandon.
#define DEBUG				 0

#define TAUNT_HIGH_THRESHOLD 0.4
#define TAUNT_MID_THRESHOLD	 0.2
#define TAUNT_LOW_THRESHOLD	 0.04

enum SIType
{
	SIType_Smoker = 1,
	SIType_Boomer,
	SIType_Hunter,
	SIType_Spitter,
	SIType_Jockey,
	SIType_Charger,
	SIType_Witch,
	SIType_Tank,
	
	SIType_Size //8 size
}

static const char SINames[SIType_Size][] =
{
    "",
    "gas",          // smoker
    "exploding",    // boomer
    "hunter",
    "spitter",
    "jockey",
    "charger",
    "witch",
    "tank",
};

//Handle g_hSDKCall_GetSIDominatingMe = null;

ConVar
	g_hCvar_DmgDone		,
	g_hCvar_ShouldDoDamage,
	g_hCvar_ShouldPassToHook,
	g_hCvar_ShouldChargerDieOnCarry,
	g_hCvar_ShouldTaunt;

ConVar g_hCvar_SpecialInfectedHP[SIType_Size] = {null, ...};

bool g_bIsHooked[MAXPLAYERS + 1] = {false, ...};

public Plugin myinfo =
{
	name = "[L4D2] 1 vs 1 (maybe 1+)",
	author = "blueblur, 东, Blade + Confogl Team, Tabun, Visor",
	description = "Fight against dominators in a pure aim.",
	version	= PLUGIN_VERSION,
	url = "https://github.com/fantasylidong/CompetitiveWithAnne"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	RegPluginLibrary("l4d2_1v1");
	return APLRes_Success;
}

public void OnPluginStart()
{
	IniGameData();
	CreateConVar("l4d2_1v1", PLUGIN_VERSION, "The version of 1 vs 1 plugin", FCVAR_NOTIFY | FCVAR_DEVELOPMENTONLY);

	char buffer[32];
	for (int i = 0; i < view_as<int>(SIType_Size); i++)
	{
		Format(buffer, sizeof(buffer), "z_%s_health", SINames[i]);
		g_hCvar_SpecialInfectedHP[i] = FindConVar(buffer);
	}

	g_hCvar_DmgDone					= CreateConVar("1v1_ability_dmg_done", "24.0", "Damage done from dominator SIs' ability.");
	g_hCvar_ShouldDoDamage			= CreateConVar("1v1_should_do_damage", "1", "Whether dominator SIs should do ability damage or not.", _, true, 0.0, true, 1.0);
	g_hCvar_ShouldPassToHook		= CreateConVar("1v1_should_pass_to_hook", "0", "Whether to pass this plugin's damage to OnTakeDamage hook or not. (To tell other plugins.)", _, true, 0.0, true, 1.0);
	g_hCvar_ShouldChargerDieOnCarry = CreateConVar("1v1_should_charger_die_on_carry", "0", "Whether the charger should be killed or not when carrying a you.", _, true, 0.0, true, 1.0);
	g_hCvar_ShouldTaunt				= CreateConVar("1v1_should_taunt", "1", "Whether to taunt or not", _, true, 0.0, true, 1.0);

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_team", Event_PlayerTeam);
	LoadTranslation(TRANSLATION_FILE);
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	if (!g_bIsHooked[client])
	{
		SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}

	return Plugin_Continue;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_bIsHooked[i])
			g_bIsHooked[i] = false;
	}
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int team = event.GetInt("team");
	bool bDisconnected = event.GetBool("disconnected");
	bool bIsBot = event.GetBool("isbot");

	// ignore bots.
	if (bIsBot && g_bIsHooked[client])
	{
		g_bIsHooked[client] = false;
		return;
	}

	// SDKHook will unhook themselves when hooked client is disconnected, we don't need to do anything here.
	if ((!IsClientAndInGame(client) || bDisconnected) && g_bIsHooked[client])
	{
		g_bIsHooked[client] = false;
		return;
	}

	// player swapped away from team survivors, unhook.
	if (team != 2 && g_bIsHooked[client])
	{
		SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		g_bIsHooked[client] = false;
		return;
	}

	// player swapped into team survivors, hook.
	else if (team == 2 && !g_bIsHooked[client])
	{
		if (SDKHookEx(client, SDKHook_PostThinkPost, OnPostThinkPost)
			&& SDKHookEx(client, SDKHook_OnTakeDamage, OnTakeDamage))
		{
			g_bIsHooked[client] = true;
		}
	}
}

// credit to 东
// this cancels get up animation of survivor.
void OnPostThinkPost(int client)
{
	if (IsClientAndInGame(client))
		SetEntPropFloat(client, Prop_Send, "m_flCycle", 1000.0, 0);
}

Action OnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamagetype)
{
	if (!IsClientAndInGame(iVictim) || !IsClientAndInGame(iAttacker))
		return Plugin_Continue;

	if (GetClientTeam(iVictim) != L4D2Team_Survivor || GetClientTeam(iAttacker) != L4D2Team_Infected)
		return Plugin_Continue;

	SIType zClass = view_as<SIType>(GetInfectedClass(iAttacker));

#if DEBUG
	PrintToServer("### OnTakeDamage called, victim: %d, attacker: %d, inflictor: %d, damage: %f, damagetype: %d", iVictim, iAttacker, iInflictor, fDamage, iDamagetype);
#endif

	if (zClass == SIType_Charger || zClass == SIType_Jockey || zClass == SIType_Smoker || zClass == SIType_Hunter)
	{
		// only block the damage from their ability, more specifically, a DMG_GENERIC damage from this plugin.
		if (!g_hCvar_ShouldDoDamage.BoolValue && (iDamagetype & DMG_GENERIC))
		{
			fDamage = 0.0;
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

// dominators are: hunter, jockey, charger, smoker.
MRESReturn DTR_CTerrorPlayer_OnIsDominatedBySpecialInfected(int pPlayer, DHookReturn hReturn)
{
#if DEBUG
	//PrintToServer("### DTR_CTerrorPlayer_OnIsDominatedBySpecialInfected called, pPlayer: %d, hReturn: %d", pPlayer, hReturn.Value);
#endif
	// dominated by SI ?
	if (hReturn.Value)
	{
		// this function also calls on infected. (wth)
		if (!IsClientAndInGame(pPlayer) || GetClientTeam(pPlayer) != L4D2Team_Survivor)
			return MRES_Ignored;
#if DEBUG
		PrintToServer("### Player %N is dominated.", pPlayer);
#endif
/*
		int iAttacker = SDKCall(g_hSDKCall_GetSIDominatingMe, pPlayer);
#if DEBUG
		PrintToServer("### Dominator: %N.", iAttacker);
#endif
*/
		for (int i = 0; i < MaxClients; i++)
		{
			if (IsClientAndInGame(i) && GetClientTeam(i) == L4D2Team_Infected)
			{
				if (pPlayer == GetVictim(i))
				{
#if DEBUG
					PrintToServer("### Dominator: %N.", i);
#endif
					ProcessDomination(i, pPlayer);
				}
			}
		}	
	}

	return MRES_Ignored;
}

void ProcessDomination(int iAttacker, int iVictim)
{
	SIType zClass = view_as<SIType>(GetInfectedClass(iAttacker));
	int	iRemainingHealth = GetClientHealth(iAttacker);

	bool bIsBot = false;
	char sName[MAX_NAME_LENGTH];
	if (IsFakeClient(iAttacker)) bIsBot = true;
	else 
	{
		GetClientName(iAttacker, sName, sizeof(sName));
		bIsBot = false;
	}

	CPrintToChatAll("%t", "DamageReport", bIsBot ? "AI" : sName, L4D2_InfectedNames[zClass], iRemainingHealth, g_hCvar_DmgDone		.FloatValue);

	if (g_hCvar_ShouldDoDamage.BoolValue)
		SDKHooks_TakeDamage(iVictim, iAttacker, iAttacker, g_hCvar_DmgDone		.FloatValue, DMG_GENERIC, _, _, _, g_hCvar_ShouldPassToHook.BoolValue);

	// do damage first, then kill the infected.
	ForcePlayerSuicide(iAttacker);

	// otherwise you will be carried by 'nothing'
	if (g_hCvar_ShouldChargerDieOnCarry.BoolValue && zClass == SIType_Charger && GetEntPropEnt(iVictim, Prop_Send, "m_carryAttacker") != 0)
		L4D2_Charger_EndCarry(iVictim, iAttacker);

	if (g_hCvar_ShouldTaunt.BoolValue)
		DoTaunt(iRemainingHealth, iAttacker, zClass);
}

// credit to 东
void DoTaunt(int iRemainingHealth, int iVictim, SIType iZclass)
{
	int maxHealth = GetSpecialInfectedHP(iZclass);
	if (!maxHealth)
		return;    
                
	if (iRemainingHealth == 1) CPrintToChat(iVictim, "%t", "Taunt_HP1");
	else if (iRemainingHealth <= RoundToCeil(maxHealth * TAUNT_LOW_THRESHOLD)) CPrintToChat(iVictim, "%t", "Taunt_HPLow");
	else if (iRemainingHealth <= RoundToCeil(maxHealth * TAUNT_MID_THRESHOLD)) CPrintToChat(iVictim, "%t", "Taunt_HPMid");
	else if (iRemainingHealth <= RoundToCeil(maxHealth * TAUNT_HIGH_THRESHOLD)) CPrintToChat(iVictim, "%t", "Taunt_HPHigh");
}

bool IsClientAndInGame(int client)
{
	return (client > 0 && client < MaxClients && IsClientInGame(client));
}

int GetSpecialInfectedHP(SIType zClass)
{
    if (g_hCvar_SpecialInfectedHP[zClass])
        return g_hCvar_SpecialInfectedHP[zClass].IntValue;
    
    return 0;
}

int GetVictim(int iAttacker)
{
	SIType class = view_as<SIType>(GetInfectedClass(iAttacker));

	switch (class)
	{
		
		case SIType_Smoker: return L4D_GetVictimSmoker(iAttacker);
		case SIType_Hunter: return L4D_GetVictimHunter(iAttacker);
		case SIType_Jockey: return L4D_GetVictimJockey(iAttacker);
		case SIType_Charger:
		{
			if (g_hCvar_ShouldChargerDieOnCarry.BoolValue)
			{
				int victim = L4D_GetVictimCarry(iAttacker);

				if (!victim)
					return L4D_GetVictimCharger(iAttacker);

				return victim;
			}

			return L4D_GetVictimCharger(iAttacker);
		} 
	}

	return 0;
}

void IniGameData()
{
	GameData gd = new GameData(GAMEDATA_FILE);

	if (!gd) SetFailState("Failed to load game data \"" ... GAMEDATA_FILE... "\" ");

	DynamicDetour hDetour = DynamicDetour.FromConf(gd, DETOUR_FUNCTION);
	if (!hDetour) SetFailState("Failed to create detour for \"" ... DETOUR_FUNCTION... "\" ");

	if (!hDetour.Enable(Hook_Post, DTR_CTerrorPlayer_OnIsDominatedBySpecialInfected))
		SetFailState("Failed to enable detour for \"" ... DETOUR_FUNCTION... "\" ");
/*
	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(gd, SDKConf_Signature, SDKCALL_FUNCTION))
		SetFailState("Failed to load function from gamedata for \"" ... SDKCALL_FUNCTION... "\" ");

	g_hSDKCall_GetSIDominatingMe = EndPrepSDKCall();
	if (!g_hSDKCall_GetSIDominatingMe)
		SetFailState("Failed to create SDK call for \"" ... SDKCALL_FUNCTION... "\" ");
*/
	delete hDetour;
	delete gd;
}

stock void LoadTranslation(const char[] translation)
{
	char sPath[PLATFORM_MAX_PATH], sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>

#define GAMEDATA_FILE  "l4d2_block_idle_reload"
#define SDKCALL_FUNCTION "CBaseCombatCharacter::Reload"
#define DHOOK_FUNCTION "CBaseCombatWeapon::FinishReload"
#define PLUGIN_VERSION "1.0"

#define DEBUG 0

bool g_bInReload[MAXPLAYERS + 1] = { false, ...};
bool g_bIsIdleReloading[MAXPLAYERS + 1] = { false, ...};

Handle g_hSDKCall_Reload = null;
DynamicHook g_hDHook = null;

public Plugin myinfo =
{
	name = "[L4D2] Block Idle Reload",
	author = "blueblur",
	description = "Blocks the little trick which haves you an \"Infinite\" fire power.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();

	if (engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d2_block_idle_reload_version", PLUGIN_VERSION, "Block Idle Reload version.", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	InitGameData();

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_bot_replace", Event_PlayerBotReplace, EventHookMode_Post);
}

public void OnMapStart()
{
	HookEntityOutput("info_director", "OnGameplayStart", OnGameplayStart);
}

void OnGameplayStart(const char[] output, int caller, int activator, float delay)
{
	HookPlayers();
}

public void OnClientPutInServer(int client)
{
	if (!IsFakeClient(client) && GetClientTeam(client) == 2)
		SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

public void OnClientDisconnect(int client)
{
	g_bInReload[client] = false;
	g_bIsIdleReloading[client] = false;
}

void Event_RoundStart(Event hEvent, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			g_bInReload[i] = false;
			g_bIsIdleReloading[i] = false;
		}
	}
}

void Event_PlayerBotReplace(Event hEvent, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("player"));
	if (client <= 0 || client > MaxClients)
		return;

	if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2)
	{
#if DEBUG
		PrintToServer("### Event_PlayerBotReplace: client = %d", client);
#endif
		// if you reload before idling.
		if (g_bInReload[client])
			g_bIsIdleReloading[client] = true;
	}
}

void OnWeaponEquipPost(int client, int weapon)
{
	if (!IsWeaponFireArm(weapon))
		return;

#if DEBUG
	PrintToServer("### OnWeaponEquipPost: client = %d, weapon = %d", client, weapon);
#endif

	SDKHook(weapon, SDKHook_ReloadPost, OnReloadPost);
	g_hDHook.HookEntity(Hook_Post, weapon, OnFinishReload);
}

void OnReloadPost(int weapon, bool bSuccessful)
{
#if DEBUG
	PrintToServer("### OnReloadPost: weapon = %d, bSuccessful = %d", weapon, bSuccessful);
#endif

	// first we reload then we idle.
	if (!bSuccessful)
		return;

	if (!IsValidEdict(weapon))
		return;

	int client = GetWeaponOwner(weapon);
	if (client <= 0 || client > MaxClients)
		return;

	if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
		return;

	// at first I was tryna use sendproxy or think to get m_bInReload state,
	// but have it a thought this is a sourcepawn variable man.
	g_bInReload[client] = true;
}

MRESReturn OnFinishReload(int pThis)
{
#if DEBUG
	PrintToServer("### OnFinishReload: Called. pThis: %d", pThis);
#endif

	int client = GetWeaponOwner(pThis);
	if (client <= 0 || client > MaxClients)
		return MRES_Ignored;

	if (IsFakeClient(client))
		return MRES_Ignored;

	if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2)
		return MRES_Ignored;

	// stop CBaseCombatWeapon::FinishReload to be done.
	// we will make client re-reload again when taking over the bot.

	// FIXME: Why supercede (in prehook state, this is now a posthook.) not functioning? this is a pre hook.
	// ammo and clip should be remained as before reload. but in fact they are normally set.
	if (g_bInReload[client] && g_bIsIdleReloading[client])
	{
#if DEBUG
		PrintToServer("### OnFinishReload: Superceded. client: %d", client);
#endif
		g_bInReload[client] = false;
		g_bIsIdleReloading[client] = false;
		SDKCall(g_hSDKCall_Reload, pThis);	// do reload. at this term you cant do anything.
		return MRES_Handled;
	}

	// if this is just a normal reload, let it pass.
	g_bInReload[client] = false;
	return MRES_Ignored;
}

// AMMO_TYPE
#define AMMO_ASSAULTRIFLE	3
#define AMMO_SMG			5
#define AMMO_M60			6
#define AMMO_SHOTGUN		7
#define AMMO_AUTOSHOTGUN	8
#define AMMO_HUNTINGRIFLE	9
#define AMMO_SNIPERRIFLE	10
#define AMMO_GRENADELAUNCHER	17

// from IA_l4d2 by IA-Nana.
stock bool IsWeaponFireArm(int weapon)
{
	int i = FindDataMapInfo(weapon, "m_iPrimaryAmmoType");
	if(i == -1) return false;
	switch(GetEntData(weapon, i))
	{
		case AMMO_ASSAULTRIFLE, AMMO_SMG, AMMO_M60, AMMO_SHOTGUN, AMMO_AUTOSHOTGUN, AMMO_HUNTINGRIFLE, AMMO_SNIPERRIFLE, AMMO_GRENADELAUNCHER: return true;
		default: return false;
	}
}

stock int GetWeaponOwner(int weapon)
{
	int m_hOwner = FindDataMapInfo(weapon, "m_hOwner");
	return GetEntDataEnt2(weapon, m_hOwner);
}

void HookPlayers()
{
    for (int i = 1; i < MaxClients; i++)
    {
        if (!IsClientInGame(i) || !IsPlayerAlive(i))
            continue;

        if (GetClientTeam(i) != 2)
            continue;

		SDKHook(i, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
    }
}

void InitGameData()
{
	GameData gd = new GameData(GAMEDATA_FILE);

	if (!gd) SetFailState("Failed to load gamedata \""... GAMEDATA_FILE ..."\".");

	g_hDHook = DynamicHook.FromConf(gd, DHOOK_FUNCTION);
	if (!g_hDHook) SetFailState("Failed to prepare dynamic hook \""... DHOOK_FUNCTION ..."\".");

	StartPrepSDKCall(SDKCall_Entity);
	if (!PrepSDKCall_SetFromConf(gd, SDKConf_Virtual, SDKCALL_FUNCTION)) 
		SetFailState("Failed to set SDK call signature \""...SDKCALL_FUNCTION... "\".");

	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_hSDKCall_Reload = EndPrepSDKCall();

	if (!g_hSDKCall_Reload) SetFailState("Failed to prepare SDK call \""... SDKCALL_FUNCTION ..."\".");

	delete gd;
}
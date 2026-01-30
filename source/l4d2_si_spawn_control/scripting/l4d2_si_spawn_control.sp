#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <sourcescramble>

#include "l4d2_si_spawn_control/consts.sp"

ConVar
	z_special_limit[SI_CLASS_SIZE],
	z_attack_flow_range,
	z_spawn_flow_limit,
	director_spectate_specials,
	z_spawn_safety_range,
	z_finale_spawn_safety_range,
	z_spawn_range,
	z_discard_range;

ConVar
	g_hCvar_Enable,
	g_hCvar_SpecialLimit[SI_CLASS_SIZE],
	g_hCvar_MaxSILimit,
	g_hCvar_SpawnTime,
	g_hCvar_FirstSpawnTime,
	g_hCvar_KillSITime,
	g_hCvar_BlockSpawn,
	g_hCvar_SpawnMode,
	g_hCvar_NormalSpawnRange,
	g_hCvar_NavAreaSpawnRange,
	g_hCvar_TogetherSpawn;

int
	g_iSpecialLimit[SI_CLASS_SIZE],
	g_iMaxSILimit,
	g_iSpawnMode,
	g_iSpawnAttributesOffset,
	g_iFlowDistanceOffset,
	g_iNavCountOffset,
	g_iSurvivors[MAXPLAYERS+1],
	g_iSurCount;

float
	g_fSpawnTime,
	g_fFirstSpawnTime,
	g_fKillSITime,
	g_fNormalSpawnRange,
	g_fNavAreaSpawnRange,
	g_fNearestSpawnRange,
	g_fSpecialActionTime[MAXPLAYERS+1];

bool
	g_bEnable,
	g_bBlockSpawn,
	g_bCanSpawn,
	g_bFinalMap,
	g_bLeftSafeArea,
	g_bMark[MAXPLAYERS+1],
	g_bTogetherSpawn;

Handle
	g_hSpawnTimer[MAXPLAYERS+1],
	g_hSDKIsVisibleToPlayer,
	g_hSDKFindRandomSpot;

Address
	g_pPanicEventStage; 

ArrayList g_aSurPosData;
int g_iSurPosDataLen;

MemoryPatch g_hPatch;

TheNavAreas g_pTheNavAreas;

#define PLUGIN_VERSION "4.0.1"
#include "l4d2_si_spawn_control/setup.sp"
#include "l4d2_si_spawn_control/utils.sp"
#include "l4d2_si_spawn_control/hooks.sp"
#include "l4d2_si_spawn_control/actions.sp"

public Plugin myinfo = 
{
	name = "[L4D2] Special Infected Spawn Control",
	author = "fdxx, blueblur",
	version = PLUGIN_VERSION,
	description = "Director's successor.",
	url = "https://github.com/blueblur0730/modified-plugins"
};

// L4D2_CanSpawnSpecial(bool bCanSpawn);
int Native_CanSpawnSpecial(Handle plugin, int numParams)
{
	bool bCanSpawn = GetNativeCell(1);
	g_bCanSpawn = bCanSpawn;
	return 0;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("L4D2_CanSpawnSpecial", Native_CanSpawnSpecial);
	RegPluginLibrary("l4d2_si_spawn_control");
	return APLRes_Success;
}

public void OnPluginStart()
{
	Init();
	SetupConVars();
	SetupEvents();

	CreateTimer(1.0, KillSICheck_Timer, _, TIMER_REPEAT);
}

public void OnPluginEnd()
{
	RestoreConVars();
	delete g_hPatch;
}

public void OnConfigsExecuted()
{
	SetConVars();
}

public void OnMapStart()
{
	g_bFinalMap = L4D_IsMissionFinalMap();
}

public void OnMapEnd()
{
	Reset();
}

public void OnClientPutInServer(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

public void OnClientDisconnect(int client)
{
	// Special Infected are kicked by other plugin before dying. Or be take over by other real players.
	if (g_bMark[client])
	{
		Event event = CreateEvent("player_death", true);
		event.SetInt("userid", GetClientUserId(client));
		Event_PlayerDeath(event, "shit", true);
		event.Cancel();
	}
}
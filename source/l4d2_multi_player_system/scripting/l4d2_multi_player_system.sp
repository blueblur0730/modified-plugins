#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>
#include <colors>

Handle
	g_hSDK_NextBotCreatePlayerBot_SurvivorBot,
	g_hSDK_CTerrorPlayer_RoundRespawn,
	g_hSDK_CCSPlayer_State_Transition,
	g_hSDK_SurvivorBot_SetHumanSpectator,
	g_hSDK_CTerrorPlayer_TakeOverBot,
	g_hSDK_CDirector_IsInTransition;

Handle g_hBotsTimer;
StringMap g_smSteamIDs;
ArrayList g_aMeleeScripts;

Address
	g_pDirector,
	g_pStatsCondition,
	g_pSavedSurvivorBotsCount;

ConVar
	g_hCvar_BotLimit,
	g_hCvar_JoinLimit,
	g_hCvar_JoinFlags,
	g_hCvar_JoinRespawn,
	g_hCvar_SpecNotify,
	g_hCvar_GiveType,
	g_hCvar_GiveTime,
	g_hCvar_SurLimit;

int
	g_iSurvivorBot,
	g_iBotLimit,
	g_iJoinLimit,
	g_iJoinFlags,
	g_iJoinRespawn,
	g_iSpecNotify;

int
	g_iOff_m_hWeaponHandle,
	g_iOff_m_iRestoreAmmo,
	g_iOff_m_restoreWeaponID,
	g_iOff_m_hHiddenWeapon,
	g_iOff_m_isOutOfCheckpoint,
	g_iOff_RestartScenarioTimer;

bool
	g_bLateLoad,
	g_bGiveType,
	g_bGiveTime,
	g_bInSpawnTime,
	g_bRoundStart,
	g_bShouldFixAFK,
	g_bShouldIgnore,
	g_bBlockUserMsg;

#include "l4d2_multi_player_system/consts.sp"

enum struct Weapon
{
	ConVar Flags;

	int	   Count;
	int	   Allowed[20];
}
Weapon g_esWeapon[MAX_SLOT];

enum struct Player
{
	int	 Bot;
	int	 Player;

	bool Notify;

	char Model[128];
	char AuthId[32];
}
Player g_esPlayer[MAXPLAYERS + 1];

#define PLUGIN_VERSION "1.13.0"
public Plugin myinfo =
{
	name = "[L4D2] Multi-Player System",
	author = "DDRKhat, Marcus101RR, Merudo, Lux, Shadowysn, sorallll, blueblur",
	description = "Multi-player system and management desinged for coop mode.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
	/* Original post: https://forums.alliedmods.net/showthread.php?p=2405322#post2405322 */
};

#include "l4d2_multi_player_system/utils.sp"
#include "l4d2_multi_player_system/setup.sp"
#include "l4d2_multi_player_system/hooks.sp"
#include "l4d2_multi_player_system/commands.sp"
#include "l4d2_multi_player_system/events.sp"
#include "l4d2_multi_player_system/actions.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslation("l4d2_multi_player_system.phrases");

	InitData();
	SetupConVars();
	SetupCommands();
	SetupEvents();

	g_smSteamIDs	= new StringMap();
	g_aMeleeScripts = new ArrayList(ByteCountToCells(64));

	if (g_bLateLoad)
		g_bRoundStart = !OnEndScenario();
}

public void OnPluginEnd()
{
	StatsConditionPatch(false);
}

public void OnConfigsExecuted()
{
	static bool once;
	if (!once)
	{
		once = true;
		GetCvars_Limit();
	}

	GetCvars_Weapon();
	GetCvars_General();
}

public void OnClientDisconnect(int client)
{
	if (IsFakeClient(client))
		return;

	g_esPlayer[client].AuthId[0] = '\0';

	if (g_bRoundStart)
	{
		delete g_hBotsTimer;
		g_hBotsTimer = CreateTimer(1.0, tmrBotsUpdate);
	}
}

// 给玩家近战
// L4D2- Melee In The Saferoom (https://forums.alliedmods.net/showpost.php?p=2611529&postcount=484)
public void OnMapStart()
{
	GetMeleeStringTable();
	PrecacheSound(SOUND_SPECMENU);

	int i;
	for (; i < sizeof g_sWeaponModels; i++)
		PrecacheModel(g_sWeaponModels[i], true);

	char buffer[64];
	for (i = 3; i < sizeof g_sWeaponName[]; i++)
	{
		FormatEx(buffer, sizeof buffer, "scripts/melee/%s.txt", g_sWeaponName[1][i]);
		PrecacheGeneric(buffer, true);
	}
}

public void OnMapEnd()
{
	ResetPlugin();
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
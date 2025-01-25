#pragma semicolon 1
#pragma newdecls required

#define DEBUG_ALL				   0

#define PLUGIN_VERSION			   "1.2"    // rework of 2.4.5

// Load this plugin always before confogl_system, always after left4dhooks.

// Using these macros, you can disable unnecessary modules,
// and they will not be included in the plugin at compile time,
// to disable, specify 0 for the required module.
#define MODULE_MAPINFO			   1	// MapInfo
#define MODULE_WEAPONINFORMATION   1	// WeaponInformation
#define MODULE_GHOSTTANK		   1	// GhostTank
#define MODULE_GHOSTWARP		   0	// GhostWarp (plugin l4d2_ghost_warp replaces this functionality)
#define MODULE_SCOREMOD			   1	// ScoreMod
#define MODULE_FINALESPAWN		   1	// FinaleSpawn
#define MODULE_BOSSSPAWNING		   1	// BossSpawning
#define MODULE_ITEMTRACKING		   1	// ItemTracking
#define MODULE_WATERSLOWDOWN	   1	// WaterSlowdown (config 'pmelite' uses it)
#define MODULE_UNPROHIBITBOSSES	   0	// UnprohibitBosses (duplicate code, plugin 'bossspawningfix' does the same).
#define MODULE_ENTITYREMOVER	   0	// EntityRemover (the same can be done with the extension 'stripper').
#define MODULE_WEAPONCUSTOMIZATION 0	// WeaponCustomization (this is deprecated and disabled, plugin 'l4d_weapon_limits' does the same).

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <colors>
//#include <l4d2lib> //ItemTracking (commented out)

#include "confoglcompmod/includes/constants.sp"
#include "confoglcompmod/includes/functions.sp"
#include "confoglcompmod/includes/debug.sp"
#include "confoglcompmod/includes/survivorindex.sp"
#include "confoglcompmod/includes/configs.sp"

#if MODULE_MAPINFO
	#include "confoglcompmod/MapInfo.sp"
#endif

#if MODULE_WEAPONINFORMATION
	#include "confoglcompmod/WeaponInformation.sp"
#endif

#if MODULE_GHOSTTANK
	#include "confoglcompmod/GhostTank.sp"
#endif

#if MODULE_GHOSTWARP
	#include "confoglcompmod/GhostWarp.sp"
#endif

#if MODULE_SCOREMOD
	#include "confoglcompmod/ScoreMod.sp"
#endif

#if MODULE_FINALESPAWN
	#include "confoglcompmod/FinaleSpawn.sp"
#endif

#if MODULE_BOSSSPAWNING
	#include "confoglcompmod/BossSpawning.sp"
#endif

#if MODULE_ITEMTRACKING
	#include "confoglcompmod/ItemTracking.sp"
#endif

#if MODULE_WATERSLOWDOWN
	#include "confoglcompmod/WaterSlowdown.sp"
#endif

#if MODULE_UNPROHIBITBOSSES
	#include "confoglcompmod/UnprohibitBosses.sp"
#endif

#if MODULE_ENTITYREMOVER
	#include "confoglcompmod/EntityRemover.sp"
#endif

#if MODULE_WEAPONCUSTOMIZATION
	#include "confoglcompmod/WeaponCustomization.sp"
#endif

// Competitive Rework Team:
// Confogl Team, A1m` (for confogl itself)
// vintik, Sir (for match_vote.sp)
// other contributors: Sir, Forgetest, sheo, StarterX4 and so on...
public Plugin myinfo =
{
	name = "[L4D2] Confogl's Competitive Versus Mod",
	author = "Competitive Rework Team, blueblur",
	description = "A competitive versus mod for L4D2.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// Modules
#if MODULE_MAPINFO
	MI_APL();	 // MapInfo
#endif

#if MODULE_SCOREMOD
	SM_APL();
#endif

	return APLRes_Success;
}

public void OnPluginStart()
{
	// Plugin functions
	Fns_OnModuleStart();		// functions
	Debug_OnModuleStart();		// debug
	SI_OnModuleStart();			// survivorindex
	Configs_OnModuleStart();	// configs

	// Modules
#if MODULE_MAPINFO
	MI_OnModuleStart();	   // MapInfo
#endif

#if MODULE_WEAPONINFORMATION
	WI_OnModuleStart();	   // WeaponInformation
#endif

#if MODULE_ENTITYREMOVER
	ER_OnModuleStart();	   // EntityRemover
#endif

#if MODULE_GHOSTWARP
	GW_OnModuleStart();	   // GhostWarp
#endif

#if MODULE_WATERSLOWDOWN
	WS_OnModuleStart();	   // WaterSlowdown
#endif

#if MODULE_GHOSTTANK
	GT_OnModuleStart();	   // GhostTank
#endif

#if MODULE_UNPROHIBITBOSSES
	UB_OnModuleStart();	   // UnprohibitBosses
#endif

#if MODULE_SCOREMOD
	SM_OnModuleStart();	   // ScoreMod
#endif

#if MODULE_FINALESPAWN
	FS_OnModuleStart();	   // FinaleSpawn
#endif

#if MODULE_BOSSSPAWNING
	BS_OnModuleStart();	   // BossSpawning
#endif

#if MODULE_WEAPONCUSTOMIZATION
	WC_OnModuleStart();	   // WeaponCustomization
#endif

#if MODULE_ITEMTRACKING
	IT_OnModuleStart();	   // ItemTracking
#endif
}

public void OnPluginEnd()
{
	// Modules
#if MODULE_ENTITYREMOVER
	ER_OnModuleEnd();	 // EntityRemover
#endif

#if MODULE_SCOREMOD
	SM_OnModuleEnd();	 // ScoreMod
#endif

#if MODULE_WATERSLOWDOWN
	WS_OnModuleEnd();	 // WaterSlowdown
#endif

#if MODULE_MAPINFO
	MI_OnModuleEnd();	 // MapInfo
#endif
}

#if MODULE_MAPINFO || MODULE_SCOREMOD || MODULE_BOSSSPAWNING || MODULE_ITEMTRACKING

public void OnMapStart()
{
	// Modules
	#if MODULE_MAPINFO
	MI_OnMapStart();	// MapInfo
	#endif

	#if MODULE_SCOREMOD
	SM_OnMapStart();	// ScoreMod
	#endif

	#if MODULE_BOSSSPAWNING
	BS_OnMapStart();	// BossSpawning
	#endif

	#if MODULE_ITEMTRACKING
	IT_OnMapStart();	// ItemTracking
	#endif
}
#endif

#if MODULE_MAPINFO || MODULE_WEAPONINFORMATION || MODULE_WATERSLOWDOWN

public void OnMapEnd()
{
	// Modules
	#if MODULE_MAPINFO
	MI_OnMapEnd();	  // MapInfo
	#endif

	#if MODULE_WEAPONINFORMATION
	WI_OnMapEnd();	  // WeaponInformation
	#endif

	#if MODULE_WATERSLOWDOWN
	WS_OnMapEnd();	  // WaterSlowdown
	#endif
}
#endif

#if MODULE_FINALESPAWN
public void OnClientPutInServer(int client)
{
	// Modules
	#if MODULE_FINALESPAWN
	FS_OnClientPutInServer(client);	   // FinaleSpawn
	#endif
}
#endif

// Hot functions =)

#if MODULE_WATERSLOWDOWN

public void OnGameFrame()
{
	// Modules
	WS_OnGameFrame();	 // WaterSlowdown
}
#endif

#if MODULE_GHOSTWARP

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon,
					  int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	// Modules
	if (GW_OnPlayerRunCmd(client, buttons))
	{	 // GhostWarp
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
#endif

// Left4Dhooks or Left4Downtown functions

#if MODULE_GHOSTTANK

public Action L4D_OnCThrowActivate(int ability)
{
	// Modules
	if (GT_OnCThrowActivate() == Plugin_Handled)
	{	 // GhostTank
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
#endif

#if MODULE_GHOSTTANK

public Action L4D_OnSpawnTank(const float vector[3], const float qangle[3])
{
	// Modules
	if (GT_OnTankSpawn_Forward() == Plugin_Handled)
	{	 // GhostTank
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
#endif

#if MODULE_BOSSSPAWNING

public void L4D_OnSpawnTank_Post(int client, const float vecPos[3], const float vecAng[3])
{
	// Modules
	BS_OnTankSpawnPost_Forward(client);	   // BossSpawning
}
#endif

#if MODULE_GHOSTTANK

public Action L4D_OnSpawnMob(int &amount)
{
	// Modules
	if (GT_OnSpawnMob_Forward(amount) == Plugin_Handled)
	{	 // GhostTank
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
#endif

#if MODULE_GHOSTTANK

public Action L4D_OnTryOfferingTankBot(int tank_index, bool &enterStasis)
{
	// Modules
	if (GT_OnTryOfferingTankBot(enterStasis) == Plugin_Handled)
	{	 // GhostTank
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
#endif

#if MODULE_UNPROHIBITBOSSES

public Action L4D_OnGetMissionVSBossSpawning(float &spawn_pos_min, float &spawn_pos_max, float &tank_chance, float &witch_chance)
{
	// Modules
	if (UB_OnGetMissionVSBossSpawning() == Plugin_Handled)
	{	 // UnprohibitBosses
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
#endif

#if MODULE_UNPROHIBITBOSSES

public Action L4D_OnGetScriptValueInt(const char[] key, int &retVal)
{
	// Modules
	if (UB_OnGetScriptValueInt(key, retVal) == Plugin_Handled)
	{	 // UnprohibitBosses
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
#endif

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	if (IsPluginEnabled())
	{
		CreateTimer(0.1, OFSLA_ForceMobSpawnTimer);
	}

	return Plugin_Continue;
}

static Action OFSLA_ForceMobSpawnTimer(Handle hTimer)
{
	// Workaround to make tank horde blocking always work
	// Makes the first horde always start 100s after survivors leave saferoom
	static ConVar hCvarMobSpawnTimeMin = null;
	static ConVar hCvarMobSpawnTimeMax = null;

	if (hCvarMobSpawnTimeMin == null)
	{
		hCvarMobSpawnTimeMin = FindConVar("z_mob_spawn_min_interval_normal");
		hCvarMobSpawnTimeMax = FindConVar("z_mob_spawn_max_interval_normal");
	}

	float fRand = GetRandomFloat(hCvarMobSpawnTimeMin.FloatValue, hCvarMobSpawnTimeMax.FloatValue);
	L4D2_CTimerStart(L4D2CT_MobSpawnTimer, fRand);

	return Plugin_Stop;
}

/**
 * changelog.
 * 
 * a1.1: 9/3/23
 *  - initial constuctions of file loading and varibles definitions
 * 
 * a1.0: 8/31/23
 *  - initial build.
 *  - basic thought: there will spawn 1-2 replicator(s) in one map. Players can use it by press +USE then a menu will be created for them.
 *    the items listed in the menu can be requested (need time to make a weapon) by paying enough materials, which can be obtained by 
 *    killing SIs. A configuration file is required to decide which item can be created through replicator. These items will be cleared
 *    from the map and can only request from replicator. Extra replicator sound is optional.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <l4d2util>
#include <left4dhooks>
#include <colors>

#define CONFIG_PATH "configs/l4d2_apex_replicator.cfg"

int
	g_iTotalItems = 0;
	g_iRequestAmount[MAXPLAYERS + 1],
	g_iMetarialAmount[MAXPLAYERS + 1];

char
	g_sModlePath[256],
	g_sSoundPath[256],
	g_sSoundAnnounce[256],
	g_sSoundMaking[256];

bool
	g_IsMapSwitched = false,
	g_bCanReplicatorSpawn = false;

ArrayList
	g_harrayItemList;

ConVar
	g_hcvarEnablePlugin,
	g_hcvarEnableSounds,
	g_hcvarAllowedGameMode,
	g_hcvarMinMetarial,
	g_hcvarMaxMetarial,
	g_hcvarKillItemSwitch,
	g_hcvarTimeToSpawn;

public Plugin myinfo =
{
	name = "[L4D2] Apex Replicator",
	author = "blueblur",
	description = "Bring apex replicator to l4d2.",
	version = "a1.0",
	url = "https://github.com/blueblur0730/modified-plugins"
};

//-----------------
// Initializations
//-----------------
public void OnPluginStart()
{
	// Events
    HookEvent("player_left_start_area", Event_PlayerLeftStartArea, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);

	// ConVars
	g_hcvarEnablePlugin = CreateConVar("l4d2_apex_replicator_enable", "1", "Enable the plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hcvarEnableSounds = CreateConVar("l4d2_apex_replicator_sound_enable", "1", "Should we use extra sound resource ?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hcvarAllowedGameMode = CreateConVar("l4d2_apex_replicator_gamemod", "", "Game mode to enable. 1 = coop, 2 = realism, 4 = versus, 8 = scavenge, 16 = survival", FCVAR_NOTIFY, true, 1.0);
	g_hcvarMinMetarial = CreateConVar("l4d2_apex_replicator_min_metarial", "5", "Minimum metarials we obtain by killing SIs");
	g_hcvarMaxMetarial = CreateConVar("l4d2_apex_replicator_max_metarial", "20", "Maximum metarials we obtain by killing SIs");
	g_hcvarKillItemSwitch = CreateConVar("l4d2_apex_replicator_kill_entity", "1", "Should we kill the entity we listed in the replicator ?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hcvarTimeToSpawn = CreateConVar("l4d2_apex_replicator_spawn_time", "8", "Seconds to spawn the replicator after the first survivor left the start area.");

	// Cmd
    RegConsoleCmd("sm_replist", Commander_ReplicateList, "Open the item list menu.");

	// KeyValue Config
	char sBuffer[128];
	KeyValue kv = new KeyValues("Path");
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), CONFIG_PATH);
	if (!FileToKeyValues(kv, sBuffer))
	{
		SetFailState("File %s may be missed!", CONFIG_PATH);
	}
	IniConfig(kv);

	// Extra resources
	IniResources();

	// Translations
	LoadTranslations("l4d2_apex_replicator.phrases");
}

void IniConfig(KeyValue kv)
{
	kv.Rewind();

	if (kv.JumpToKey("Model_Path"))
		kv.GetString("replicator_path", g_sModlePath, sizeof(g_sModlePath))

	if (g_hcvarEnableSounds.BoolValue)
	{
		if (kv.JumpToKey("Sound_Path"))
		{
			kv.GetString("sound_path", g_sSoundPath, sizeof(g_sSoundPath));
			kv.GetString("sound_announce", g_sSoundAnnounce, sizeof(g_sSoundAnnounce));
			kv.GetString("sound_making", g_sSoundMaking, sizeof(g_sSoundMaking));
		}
	}

	// Get total items the replicator can have. you can edit this in config file.
	// Note: this number should not be larger than the items Weapon_List has.
	if (kv.JumpToKey("Total_Items"))
		kv.GetNum("number", g_iTotalItems);

	g_harrayItemList = new ArrayList();
	if (kv.JumpToKey("Weapon_List"))
	{
		char sBuffer[16], sItem[128];
		for (i = 1, i < g_iTotalItems, i++)
		{
			Format(sBuffer, sizeof(sBuffer), "item%i", i);
			kv.GetString(sBuffer, sItem, sizeof(sItem));
			g_harrayItemList.Push(sItem);
		}
	}
}

void IniResources()
{
	if (!StrEqual(g_sModlePath, ""))
		PrecacheSound(g_sModlePath, true);
	else
		LogError("Modle path error: path dose not exists or file was missing!");
		
	if (g_hcvarEnableSounds.BoolValue)
	{
		if (!StrEqual(g_sSoundPath, ""))
			PrecacheSound(g_sSoundPath, true);
		else
			LogError("Sound path error: path dose not exists or file was missing!");

		if (!StrEqual(g_sSoundAnnounce, ""))
			PrecacheSound(g_sSoundAnnounce, true);
		else
			LogError("Announce Sound error: path dose not exists or file was missing!")

		if (!StrEqual(g_sSoundMaking, ""))
			PrecacheSound((g_sSoundMaking, true));
		else
			LogError("Making Sound error: path dose not exists or file was missing!");
	}
}

//------------------------------
// Events and Global Managment
//------------------------------
public void Event_PlayerLeftStartArea(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	g_bCanReplicatorSpawn = true;
	CreateTimer(g_hcvarTimeToSpawn.IntValue, Timer_SpawnReplicator);
}

public void Event_RoundStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	// delay for a while to do it
	CreateTimer(1.0, Timer_RemoveEntity);
}

// if a survivor died, clear his data.
public void Event_PlayerDeath(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	for (int i = 0, i <= MaxClients, i++)
	{
		if (!IsPlayerAlive(i) && IsSurvivor(i))
		{
			g_iRequestAmount[i] = 0;
			g_iMetarialAmount[i] = 0;
		}
	}
}

public void OnMapStart()
{

}

public void OnMapEnd()
{

}

//-------------
// Commander
//-------------
public Action Commander_ReplicateList()
{

}

//---------------
// Remove Entity
//---------------
public Action Timer_RemoveEntity(Handle Timer)
{

}

//-------------------
// Spawn Replicator
//-------------------
public Action Timer_SpawnReplicator(Handle Timer)
{

}

//------------
// Interact
//------------

//---------------------
// Metarial Obtaintion
//---------------------

//----------
// Menu
//----------

//---------
// Stocks
//---------
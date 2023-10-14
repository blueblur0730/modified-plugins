/**
 * changelog.
 * 
 * a1.3: 9/7/23
 *  - Entity removal construction. 
 *  - Metarial obtaining construction (not completed yet).
 *  - More gloabal management on OnMapStart() and OnMapEnd().
 * 
 * a1.2: 9/5/23
 *  - Commander menu construction.
 *  - Optimized part code of Initializations.
 * 
 * a1.1: 9/3/23
 *  - initial constuctions of file loading and varibles definitions.
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

enum struct ItemInfo 
{
	char name[128];
	char info[128];
	int metarial;
}

int
	g_iTotalItems = 0,
	g_iRequestAmount[MAXPLAYERS + 1],
	g_iMetarialAmount[MAXPLAYERS + 1];

char
	g_sModelPath[256],
	g_sSoundEnter[256],
	g_sSoundAnnounce[256],
	g_sSoundMaking[256];

ArrayList
	g_harrayItemList;

ConVar
	g_hcvarEnablePlugin,
	g_hcvarEnableSounds,
	g_hcvarAllowedGameMode,
	g_hcvarMinMetarial,
	g_hcvarMaxMetarial,
	g_hcvarKillItemSwitch,
	g_hcvarRequestAmount,
	g_hcvarTimeToSpawn;

public Plugin myinfo =
{
	name = "[L4D2] Apex Replicator",
	author = "blueblur",
	description = "Bring apex replicator to l4d2.",
	version = "a1.3",
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
	g_hcvarAllowedGameMode = CreateConVar("l4d2_apex_replicator_gamemode", "", "Game mode to enable. 1 = coop, 2 = realism, 4 = versus, 8 = scavenge, 16 = survival, 32 = mutations, 64 = All", FCVAR_NOTIFY, true, 1.0);
	g_hcvarMinMetarial = CreateConVar("l4d2_apex_replicator_min_metarial", "5", "Minimum metarials we obtain by killing SIs");
	g_hcvarMaxMetarial = CreateConVar("l4d2_apex_replicator_max_metarial", "20", "Maximum metarials we obtain by killing SIs");
	g_hcvarKillItemSwitch = CreateConVar("l4d2_apex_replicator_kill_entity", "1", "Should we kill the entity we listed in the replicator ?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hcvarRequestAmount = CreateConVar("l4d2_apex_replicator_request_amount", "5", "Amount we can request during a round");
	g_hcvarTimeToSpawn = CreateConVar("l4d2_apex_replicator_spawn_time", "8", "Seconds to spawn the replicator after the first survivor left the start area.");

	// Cmd
    RegConsoleCmd("sm_replist", Commander_ReplicateList, "Open the item list menu.");

	// KeyValue Config
	char sBuffer[128];
	KeyValues kv = new KeyValues("Path");
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

	// Check Enable Status
	CheckStatus();
}

Action CheckStatus()
{
	if (g_hcvarEnablePlugin.BoolValue)
	{
		if (!IsAllowedGameMode())
		{
			return Plugin_Handled;
		}
	}
	else
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

void IniConfig(KeyValues kv)
{
	kv.Rewind();

	if (kv.JumpToKey("Model_Path"))
		kv.GetString("replicator_path", g_sModelPath, sizeof(g_sModelPath));

	if (g_hcvarEnableSounds.BoolValue)
	{
		if (kv.JumpToKey("Sound_Path"))
		{
			kv.GetString("sound_enter", g_sSoundEnter, sizeof(g_sSoundEnter));
			kv.GetString("sound_announce", g_sSoundAnnounce, sizeof(g_sSoundAnnounce));
			kv.GetString("sound_making", g_sSoundMaking, sizeof(g_sSoundMaking));
		}
	}

	// Get total items the replicator can have. you can edit this in config file.
	// Note: this number should not be larger than the items Weapon_List has.
	if (kv.JumpToKey("Total_Items"))
		kv.GetNum("number", g_iTotalItems);

	g_harrayItemList = new ArrayList(sizeof(ItemInfo));
	ItemInfo esItemInfo;

	if (kv.JumpToKey("Weapon_List"))
	{
		char sBuffer[16];
		for (int i = 1; i < g_iTotalItems; i++)
		{
			Format(sBuffer, sizeof(sBuffer), "item%i", i);
			kv.GetString(sBuffer, esItemInfo.name, sizeof(esItemInfo.name));
			
		}
	}

	if (kv.JumpToKey("Weapon_Info"))
	{
		char sBuffer[16];
		for (int i = 1; i < g_iTotalItems; i++)
		{
			Format(sBuffer, sizeof(sBuffer), "item%i", i);
			kv.GetString(sBuffer, esItemInfo.info, sizeof(esItemInfo.info));
		}
	}

	if (kv.JumpToKey("Weapon_Metarial"))
	{
		char sBuffer[16];
		for (int i = 1; i < g_iTotalItems; i++)
		{
			Format(sBuffer, sizeof(sBuffer), "item%i", i);
			kv.GetNum(sBuffer, esItemInfo.metarial);
		}
	}

	g_harrayItemList.PushArray(esItemInfo, sizeof(esItemInfo));
}

void IniResources()
{
	if (!StrEqual(g_sModelPath, ""))
	{
		if (PrecacheModel(g_sModelPath, true) == 0)
		{
			LogError("Model error: Failed to pre-cache model! File dose not exists or file path is wrong to fetch!");
		}
	}
	else
	{
		LogError("Model path error: you haven't set a required model path yet!");
	}

	if (g_hcvarEnableSounds.BoolValue)
	{
		if (!StrEqual(g_sSoundEnter, ""))
		{
			if (!PrecacheSound(g_sSoundEnter, true))
			{
				LogError("Enter sound error: Failed to pre-cache sound! File dose not exists or file path is wrong to fetch!");
			}
		}
		else
		{
			LogError("Enter sound error: you haven't set a required sound path yet!");
		}

		if (!StrEqual(g_sSoundAnnounce, ""))
		{
			if (!PrecacheSound(g_sSoundAnnounce, true))
			{
				LogError("Announce sound error: Failed to pre-cache sound! File dose not exists or file path is wrong to fetch!");
			}
		}
		else
		{
			LogError("Announce Sound error: you haven't set a required sound path yet!");
		}
			
		if (!StrEqual(g_sSoundMaking, ""))
		{
			if (!PrecacheSound(g_sSoundMaking, true))
			{
				LogError("Making sound error: Failed to pre-cache sound! File dose not exists or file path is wrong to fetch!");
			}
		}
		else
		{
			LogError("Making Sound error: you haven't set a required sound path yet!");
		}
	}
}

//-------------------
// Global Managment
//-------------------
public void Event_PlayerLeftStartArea(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	CreateTimer(g_hcvarTimeToSpawn.IntValue, Timer_SpawnReplicator);
}

public void Event_RoundStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (g_hcvarKillItemSwitch.BoolValue)
	{
		// delay for a while to do it
		CreateTimer(1.0, Timer_RemoveEntity);
	}
}

public void OnMapStart()
{
	// Check every map start
	CheckStatus();
}

public void OnMapEnd()
{
	// clear all players' data on map end
	for (int i = 0; i < MaxClients; i++)
	{
		if (IsValidClient(i) && IsSurvivor(i))
		{
			g_iRequestAmount[i] = 0;
			g_iMetarialAmount[i] = 0;
		}
	}
}

//----------------
// Commander Menu
//----------------
public Action Commander_ReplicateList(int client, int args)
{
	char sBuffer[64];
	int iSize = g_harrayItemList.Length;

	Menu hMenu = new Menu(CmdMenuHandler, MENU_ACTIONS_DEFAULT);
	Format(sBuffer, sizeof(sBuffer), "%t", "ReplicateList");
	hMenu.SetTitle(sBuffer);
	
	ItemInfo esItemInfo;
	for (int i = 0; i < iSize; i++)
	{
		g_harrayItemList.GetArray(i, esItemInfo, sizeof(esItemInfo));
		hMenu.AddItem(esItemInfo.info);
	}

	hMenu.Display(client, 30);

	return Plugin_Handled;
}

public int CmdMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[128];
			ItemInfo esItemInfo;
			Panel hPanel = new Panel();
			menu.GetItem(param2, sInfo, sizeof(sInfo));

			for (int i = 0; i < g_iTotalItems; i++)
			{
				g_harrayItemList.GetArray(i, esItemInfo, sizeof(esItemInfo));
				if (StrEqual(sInfo, esItemInfo.info))
				{
					char sBuffer1[128], sBuffer2[128], sBuffer3[128];
					Format(sBuffer1, sizeof(sBuffer1), "%t", "PanelTitle");
					Format(sBuffer2, sizeof(sBuffer2), "%t: %i", "MetarialNeed", esItemInfo.metarial);
					Format(sBuffer3, sizeof(sBuffer3), "%t", "Return");
					hPanel.SetTitle(sBuffer1);
					hPanel.DrawItem(esItemInfo.info);
					hPanel.DrawText(sBuffer2);
					hPanel.DrawItem(sBuffer3);
					hPanel.Send(param1, PanelHandler, 3);
					delete hPanel;
					return;
				}
				else
				{
					continue;
				}
			}
		}

		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public int PanelHandler(Menu hMenu, MenuAction action, int param1, int param2) { return 1; }

//---------------
// Remove Entity
//---------------
public Action Timer_RemoveEntity(Handle Timer)
{
	int iEntity = INVALID_ENT_REFERENCE;
	ItemInfo esItemInfo;

	for (int i = 0; i < g_iTotalItems; i++)
	{
		g_harrayItemList.GetArray(i, esItemInfo, sizeof(esItemInfo));
		while (iEntity = FindEntityByClassname(iEntity, esItemInfo.name) != INVALID_ENT_REFERENCE)
		{
			if (iEntity <= MaxClients || !IsValidEntity(iEntity)) 
			{
				continue;
			}

			RemoveEntity(iEntity);
			break;
		}
	}

	return Plugin_Handled;
}

//---------------------
// Metarial Obtaining
//---------------------
public void Event_PlayerDeath(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	/* from l4d_stats.sp */
	int iAttackerTeam = -1, iVictimTeam = -1;
	int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	int iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	bool bIsAttackerBot = GetEventBool(hEvent, "attackerisbot");
	//bool bIsVictimBot = GetEventBool(hEvent, "victimisbot");		// for futuer pvp use

	iAttackerTeam = GetClientTeam(iAttacker);
	iVictimTeam = GetClientTeam(iVictim);

	// if a survivor died, no matter if the killer is a bot or player
	if (iVictimTeam == 2)
	{
		// clear his/her data
		g_iRequestAmount[iAttacker] = 0;
		g_iMetarialAmount[iAttacker] = 0;
	}

	// if a survivor killed a SI
	if (iAttackerTeam == 2 && iVictimTeam == 3 && !bIsAttackerBot)
	{
		if (iAttacker > 0)
		{
			ObtainMetarial(iAttacker);
		}
	}
}

void ObtainMetarial(int iAttacker)
{
	// get a value between this zone
	int iAmount = GetRandomInt(g_hcvarMinMetarial.IntValue, g_hcvarMaxMetarial.IntValue);
	g_iMetarialAmount[iAttacker] += iAmount;
}

//-------------------
// Spawn Replicator
//-------------------
public Action Timer_SpawnReplicator(Handle Timer)
{
	// native void L4D_FindRandomSpot(int NavArea, float vecPos[3]);
	// native float L4D2Direct_GetFlowDistance(int client);
	// native float L4D2Direct_GetMapMaxFlowDistance()
	// native Address L4D2Direct_GetTerrorNavArea(float pos[3], float beneathLimit = 120.0);
	// native float L4D2Direct_GetTerrorNavAreaFlow(Address pTerrorNavArea)
	// native Address L4D_GetPointer(PointerType ptr_type);
}

//-----------
// Interact
//-----------

//------------------
// Replicator Menu
//------------------

//---------
// Stocks
//---------
stock bool IsAllowedGameMode()
{
	// forward void L4D_OnGameModeChange(int gamemode);
	int 	iNumber = 0;
	char 	sBuffer[128];
	ConVar 	hcvarGameMode = FindConVar("mp_gamemode");
	hcvarGameMode.GetString(sBuffer, sizeof(sBuffer));
	if (StrEqual(sBuffer, "coop"))			{iNumber = 1;}
	else if (StrEqual(sBuffer, "realism"))	{iNumber = 2;}
	else if (StrEqual(sBuffer, "versus"))	{iNumber = 4;}
	else if (StrEqual(sBuffer, "scavenge"))	{iNumber = 8;}
	else if (StrEqual(sBuffer, "survival"))	{iNumber = 16;}
	else									{iNumber = 32;}

	if (g_hcvarAllowedGameMode.IntValue == iNumber || g_hcvarAllowedGameMode.IntValue == 64)
		return true;
	else
		return false;
}

stock bool IsValidClient(int client)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client)) return false; 
    return true;
}

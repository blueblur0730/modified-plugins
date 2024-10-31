#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <dhooks>

#define GAMEDATA_FILE "fix_null_activator.games"
#define DHOOK_FUNCTION "CBaseEntity::AcceptInput"
#define KEY_MAX_ENTITY_COUNT "MaxEntityCount"
#define STRING_LENTH	32

#define PLUGIN_VERSION 	"1.0"
#define DEBUG 1

DynamicHook g_hAcceptInput = null;
ArrayList g_hArrEntityList = null;

// Original Author: GoD-Tony. 
// Modified by blueblur.
public Plugin myinfo =
{
	name = "[ANY] Fix Null Activator",
	author = "GoD-Tony, blueblur",
	description = "Fixes a crash caused by null activator when AcceptInput is called.",
	version = PLUGIN_VERSION,
	url = "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
	CreateConVar("fix_null_activator_version", PLUGIN_VERSION, "Version of the plugin", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	GameData gd = new GameData(GAMEDATA_FILE);
	if (!gd) SetFailState("Failed to load gamedata file \""... GAMEDATA_FILE ..."\"");

	int iOff = -1;
	iOff = gd.GetOffset(DHOOK_FUNCTION);
	if (iOff == -1) SetFailState("Failed to find \""...  DHOOK_FUNCTION ..."\" offset");

	int iMaxEntityCount = 0;
	char szEntityCount[STRING_LENTH];
	if (!gd.GetKeyValue("MaxEntityCount", szEntityCount, sizeof(szEntityCount)))
		SetFailState("Failed to get key section \""... KEY_MAX_ENTITY_COUNT ..."\" from gamedata file \""... GAMEDATA_FILE ..."\".");

	iMaxEntityCount = StringToInt(szEntityCount);
	if (!iMaxEntityCount) SetFailState("Key section \""... KEY_MAX_ENTITY_COUNT ..."\" is 0. Plugin Disabled.");

	g_hArrEntityList = new ArrayList(ByteCountToCells(STRING_LENTH));

	char szEntityName[STRING_LENTH];
	for (int i = 1; i < iMaxEntityCount; i++)
	{
		static char number[STRING_LENTH];
		Format(number, sizeof(number), "HookEntity%d", i);
		if (!gd.GetKeyValue(number, szEntityName, sizeof(szEntityName)))
			continue;

		g_hArrEntityList.PushString(szEntityName);
	}

	delete gd;
	
	g_hAcceptInput = DynamicHook.FromConf(gd, DHOOK_FUNCTION);
	if (!g_hAcceptInput) SetFailState("Failed to create dynamic hook for \""...  DHOOK_FUNCTION ..."\"");
}

public void OnPluginEnd()
{
	if (g_hAcceptInput) delete g_hAcceptInput;
	if (g_hArrEntityList) delete g_hArrEntityList;
}

// HACKHACK: This is too resource comsuming. Any better way to hook entity?
public void OnEntityCreated(int entity, const char[] classname)
{
	for (int i = 0; i < g_hArrEntityList.Length; i++)
	{
		static char szEntityName[STRING_LENTH];
		g_hArrEntityList.GetString(i, szEntityName, sizeof(szEntityName));

		if (StrEqual(classname, szEntityName))
			g_hAcceptInput.HookEntity(Hook_Pre, entity, DHook_CBaseEntity_AcceptInput);
	}
}

MRESReturn DHook_CBaseEntity_AcceptInput(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	char szInputName[128];
	hParams.GetString(1, szInputName, sizeof(szInputName));
	int pActivator = hParams.Get(2);

	if (StrEqual(szInputName, "Deactivate") || 	// entity 'game_ui' inputs "Deactivate".
		StrEqual(szInputName, "TestActivator"))	// entity 'filter_*' inputs "TestActivator".
	{
		// player disconnected or entity vanished.
		if (pActivator == -1)
		{
			// Manually disable think.
			SetEntProp(pThis, Prop_Data, "m_nNextThinkTick", -1);
			
			hReturn.Value = false;
			return MRES_Supercede;
		}
	}

	hReturn.Value = true;
	return MRES_Ignored;
}
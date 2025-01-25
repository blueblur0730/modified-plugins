#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <dhooks>

#define GAMEDATA_FILE "fix_null_activator.games"
#define DHOOK_FUNCTION "CBaseEntity::AcceptInput"
#define KEY_MAX_ENTITY_COUNT "MaxEntityCount"
#define STRING_LENTH	64

#define PLUGIN_VERSION 	"1.2.2"

DynamicHook g_hHook_AcceptInput = null;
StringMap g_hMapEntityList = null;

// Original Author: GoD-Tony. 
// Modified by blueblur.
public Plugin myinfo =
{
	name = "[ANY] Fix Null Activator",
	author = "GoD-Tony, blueblur",
	description = "Fixes a crash caused by null activator when calling AcceptInput.",
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
	if (iOff == -1) SetFailState("Failed to find \""... DHOOK_FUNCTION ..."\" offset");

	int iMaxEntityCount = 0;
	char szEntityCount[STRING_LENTH];
	if (!gd.GetKeyValue("MaxEntityCount", szEntityCount, sizeof(szEntityCount)))
		SetFailState("Failed to get key section \""... KEY_MAX_ENTITY_COUNT ..."\" from gamedata file \""... GAMEDATA_FILE ..."\".");

	iMaxEntityCount = StringToInt(szEntityCount);
	if (!iMaxEntityCount) SetFailState("Key section \""... KEY_MAX_ENTITY_COUNT ..."\" is 0. Plugin Disabled.");

	g_hMapEntityList = new StringMap();

	char szEntityName[STRING_LENTH];
	for (int i = 1; i < iMaxEntityCount; i++)
	{
		static char number[STRING_LENTH];
		Format(number, sizeof(number), "HookEntity%d", i);
		if (!gd.GetKeyValue(number, szEntityName, sizeof(szEntityName)))
			continue;

		g_hMapEntityList.SetString(number, szEntityName);
	}

	g_hHook_AcceptInput = DynamicHook.FromConf(gd, DHOOK_FUNCTION);
	if (!g_hHook_AcceptInput) SetFailState("Failed to create dynamic hook for \""...  DHOOK_FUNCTION ..."\"");

	delete gd;
}

public void OnPluginEnd()
{
	if (g_hHook_AcceptInput) delete g_hHook_AcceptInput;
	if (g_hMapEntityList) delete g_hMapEntityList;
}

// currently the entities related to this bug is created before the map start.
// use OnMapStart to save some cycles.
// let's just finish this huge cycle before we play. :D
public void OnMapStart()
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		static char szEntityName[STRING_LENTH];
		GetEntityClassname(entity, szEntityName, sizeof(szEntityName));

		for (int i = 0; i < g_hMapEntityList.Size; i++)
		{
			static char szListName[STRING_LENTH];
			static char number[STRING_LENTH];
			Format(number, sizeof(number), "HookEntity%d", i + 1);
			g_hMapEntityList.GetString(number, szListName, sizeof(szListName));

			if (StrEqual(szEntityName, szListName))
			{
				g_hHook_AcceptInput.HookEntity(Hook_Pre, entity, DHook_CBaseEntity_AcceptInput);
				break;
			}
		}
	}
}

/*
// HACKHACK: This is too resource consuming. Any better way to hook entity?
public void OnEntityCreated(int entity, const char[] classname)
{
	for (int i = 0; i < g_hMapEntityList.Size; i++)
	{
		static char szEntityName[STRING_LENTH];
		static char number[STRING_LENTH];
		Format(number, sizeof(number), "HookEntity%d", i + 1);
		g_hMapEntityList.GetString(number, szEntityName, sizeof(szEntityName));

		if (StrEqual(classname, szEntityName))
		{
			g_hHook_AcceptInput.HookEntity(Hook_Pre, entity, DHook_CBaseEntity_AcceptInput);
			break;
		}
	}
}
*/

MRESReturn DHook_CBaseEntity_AcceptInput(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	//int pActivator = hParams.Get(2);

	// if player disconnected or activator entity destroyed.
	if (hParams.IsNull(2))
	{
		char szEntityName[128];
		GetEntityClassname(pThis, szEntityName, sizeof(szEntityName));

		char szInputName[128];
		hParams.GetString(1, szInputName, sizeof(szInputName));

		LogMessage("Entity %s called AcceptInput with null activator. InuputName: %s.", szEntityName, szInputName);

		if (StrEqual(szEntityName, "game_ui") && StrEqual(szInputName, "Deactivate"))
			SetEntProp(pThis, Prop_Data, "m_nNextThinkTick", -1);

		// this operation is not successful.
		hReturn.Value = false;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}
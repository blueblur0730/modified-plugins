#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <dhooks>

#define GAMEDATA_FILE "fix_null_activator.games"
#define DETOUR_FUNCTION "CBaseEntity::AcceptInput"
#define KEY_MAX_ENTITY_COUNT "MaxEntityCount"
#define KEY_MAX_COMMAND_COUNT "MaxCommandCount"
#define STRING_LENTH	64

#define PLUGIN_VERSION 	"1.1"

DynamicDetour g_hDTR_AcceptInput = null;
ArrayList g_hArrEntityList = null;
ArrayList g_hArrCommandNames = null;

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
	iOff = gd.GetOffset(DETOUR_FUNCTION);
	if (iOff == -1) SetFailState("Failed to find \""...  DETOUR_FUNCTION ..."\" offset");

	int iMaxEntityCount = 0;
	char szEntityCount[STRING_LENTH];
	if (!gd.GetKeyValue("MaxEntityCount", szEntityCount, sizeof(szEntityCount)))
		SetFailState("Failed to get key section \""... KEY_MAX_ENTITY_COUNT ..."\" from gamedata file \""... GAMEDATA_FILE ..."\".");

	int iMaxCommandCount = 0;
	char szCommandCount[STRING_LENTH];
	if (!gd.GetKeyValue("MaxCommandCount", szCommandCount, sizeof(szCommandCount)))
		SetFailState("Failed to get key section \""... KEY_MAX_COMMAND_COUNT ..."\" from gamedata file \""... GAMEDATA_FILE ..."\".");

	iMaxEntityCount = StringToInt(szEntityCount);
	if (!iMaxEntityCount) SetFailState("Key section \""... KEY_MAX_ENTITY_COUNT ..."\" is 0. Plugin Disabled.");

	iMaxCommandCount = StringToInt(szCommandCount);
	if (!iMaxCommandCount) SetFailState("Key section \""... KEY_MAX_COMMAND_COUNT ..."\" is 0. Plugin Disabled.");

	g_hArrEntityList = new ArrayList(ByteCountToCells(STRING_LENTH));
	g_hArrCommandNames = new ArrayList(ByteCountToCells(STRING_LENTH));

	char szEntityName[STRING_LENTH];
	for (int i = 1; i < iMaxEntityCount; i++)
	{
		static char number[STRING_LENTH];
		Format(number, sizeof(number), "HookEntity%d", i);
		if (!gd.GetKeyValue(number, szEntityName, sizeof(szEntityName)))
			continue;

		g_hArrEntityList.PushString(szEntityName);
	}

	char szCommandName[STRING_LENTH];
	for (int i = 1; i < iMaxEntityCount; i++)
	{
		static char number[STRING_LENTH];
		Format(number, sizeof(number), "Command%d", i);
		if (!gd.GetKeyValue(number, szCommandName, sizeof(szCommandName)))
			continue;

		g_hArrCommandNames.PushString(szCommandName);
	}

	g_hDTR_AcceptInput = DynamicDetour.FromConf(gd, DETOUR_FUNCTION);
	if (!g_hDTR_AcceptInput) SetFailState("Failed to create detour for \""...  DETOUR_FUNCTION ..."\"");

	if (!g_hDTR_AcceptInput.Enable(Hook_Pre, DTR_CBaseEntity_AcceptInput))
		SetFailState("Failed to enable detour for \""...  DETOUR_FUNCTION ..."\"");

	delete gd;
}

public void OnPluginEnd()
{
	if (g_hDTR_AcceptInput)
	{
		g_hDTR_AcceptInput.Disable(Hook_Pre, DTR_CBaseEntity_AcceptInput);
		delete g_hDTR_AcceptInput;
	} 

	if (g_hArrEntityList) delete g_hArrEntityList;
	if (g_hArrCommandNames) delete g_hArrCommandNames;
}

/*
// HACKHACK: This is too resource consuming. Any better way to hook entity?
public void OnEntityCreated(int entity, const char[] classname)
{
	for (int i = 0; i < g_hArrEntityList.Length; i++)
	{
		static char szEntityName[STRING_LENTH];
		g_hArrEntityList.GetString(i, szEntityName, sizeof(szEntityName));

		if (StrEqual(classname, szEntityName))
			g_hDTR_AcceptInput.HookEntity(Hook_Pre, entity, DTR_CBaseEntity_AcceptInput);
	}
}
*/

// Use detour for AcceptInput. much better than check every entity in OnEntityCreated?
MRESReturn DTR_CBaseEntity_AcceptInput(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	char szInputName[128];
	hParams.GetString(1, szInputName, sizeof(szInputName));
	int pActivator = hParams.Get(2);

	char szEntityName[128];
	if (!GetEntityClassname(pThis, szEntityName, sizeof(szEntityName)))
		return MRES_Ignored;

	for (int i = 0; i < g_hArrEntityList.Length; i++)
	{
		static char szEntityName2[STRING_LENTH];
		g_hArrEntityList.GetString(i, szEntityName2, sizeof(szEntityName2));

		// is this the entity we want to check
		if (!StrEqual(szEntityName, szEntityName2))
			continue;

		for (int j = 0; j < g_hArrCommandNames.Length; j++)
		{
			static char szCommandName[STRING_LENTH];
			g_hArrCommandNames.GetString(j, szCommandName, sizeof(szCommandName));

			// is this the input command we want to check
			if (!StrEqual(szInputName, szCommandName))
				continue;

			// if player disconnected or activator entity destroyed.
			if (pActivator == -1)
			{
				// Manually disable the think which should be set to -1 on CGameUI::Deactivate.
				if (StrEqual(szEntityName, "game_ui") && StrEqual(szInputName, "Deactivate"))
					SetEntProp(pThis, Prop_Data, "m_nNextThinkTick", -1);

				hReturn.Value = false;
				return MRES_Supercede;
			}
		}
	}

	return MRES_Ignored;
}
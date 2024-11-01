#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <dhooks>

#define GAMEDATA_FILE "fix_null_activator.games"
#define DETOUR_FUNCTION "CBaseEntity::AcceptInput"

#define PLUGIN_VERSION 	"1.2"

DynamicDetour g_hDTR_AcceptInput = null;

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
}

// Use detour for AcceptInput. much better than check every entity in OnEntityCreated?
MRESReturn DTR_CBaseEntity_AcceptInput(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	char szInputName[128];
	hParams.GetString(1, szInputName, sizeof(szInputName));
	int pActivator = hParams.Get(2);

	// if player disconnected or activator entity destroyed or not.
	if (pActivator > -1)
		return MRES_Ignored;
	
	char szEntityName[128];
	if (!GetEntityClassname(pThis, szEntityName, sizeof(szEntityName)))
		return MRES_Ignored;

	// Manually disable the think which should be set to -1 on CGameUI::Deactivate.
	if (StrEqual(szEntityName, "game_ui") && StrEqual(szInputName, "Deactivate"))
		SetEntProp(pThis, Prop_Data, "m_nNextThinkTick", -1);

	// this operation is not successful.
	hReturn.Value = false;
	return MRES_Supercede;
}
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <animating_library>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "[L4D2/ANY?] Library for CBaseAnimating Test Plugin",
	author = "blueblur",
	description = "Test the library for CBaseAnimating.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"

}

public void OnPluginStart()
{
	RegAdminCmd("sm_animtest", Command_AnimationTest, ADMFLAG_ROOT, "Test the library for CBaseAnimating.");
}

Action Command_AnimationTest(int client, int args)
{
	int entity = GetClientActiveWeapon(client);

	if (!HasModel(entity))
	{
		PrintToChat(client, "Entity does not have a model.");
		return Plugin_Handled;
	}

/*
    // get pointer.
    Address p = view_as<Address>(CBaseAnimating(entity));
    PrintToChat(client, "Pointer: %d", p);
    return Plugin_Handled;
*/

/*
	// let's take an example of "v_models\v_smg.mdl", which has a bodygroup name:

	// $bodygroup "v_smg"
	// {
	//     studio "v_smg_uzi_ref.smd"
	// }

	CBaseAnimating pAnimating = CBaseAnimating(entity);
	int	bodygroup  = pAnimating.FindBodyGroupByName("v_smg");

	PrintToChat(client, "Bodygroup: %d", bodygroup);

	return Plugin_Handled;
*/

/*
    // seems most original models only have one bodygroup.
    CBaseAnimating pAnimating = CBaseAnimating(entity);
    int	bodygroup  = pAnimating.FindBodyGroupByName("v_smg");
    pAnimating.SetBodyGroup(bodygroup, 0);
*/
}

stock bool HasModel(int entity)
{
	char buffer[PLATFORM_MAX_PATH];
	GetEntPropString(entity, Prop_Data, "m_ModelName", buffer, sizeof(buffer));
	return buffer[0] != '\0' ? true : false;
}

stock int GetClientActiveWeapon(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}
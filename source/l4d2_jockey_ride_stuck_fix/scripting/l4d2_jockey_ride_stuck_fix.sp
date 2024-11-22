#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define GAMEDATA_FILE "l4d2_jockey_ride_stuck_fix"
#define SDKCALL_FUNCTION "CTerrorPlayer::OnRideEnded"

#define PLUGIN_VERSION "1.1"

Handle g_hSDKCall_OnRideEnded = null;

public Plugin myinfo = 
{
	name = "[L4D2] Jockey Ride Stuck Fix",
	author = "sorallll, blueblur",
	description = "When the survivor bot controlled by jockey is kicked out of the game, jockey will get stuck in the air, this plugin fixes it",
	version = PLUGIN_VERSION,
	url = "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart() 
{
	CreateConVar("jockey ride stuck fix_version", PLUGIN_VERSION, "Jockey Ride Stuck Fix plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	GameData gd = new GameData(GAMEDATA_FILE);
	if (!gd) SetFailState("Failed to load gamedata file \""...GAMEDATA_FILE..."\".");

	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(gd, SDKConf_Signature, SDKCALL_FUNCTION))
		SetFailState("Failed to find SDK call \""...SDKCALL_FUNCTION..."\".");

	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDKCall_OnRideEnded = EndPrepSDKCall();
	if (!g_hSDKCall_OnRideEnded) SetFailState("Failed to hook SDK call \""...SDKCALL_FUNCTION..."\".");

	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}

void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || !IsFakeClient(client) || GetClientTeam(client) != 2)
		return;

	int jockey = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");

	if (jockey != -1) 
	{
		// seconds param is rescurer. if it is null it is okey. 0 will be passed to the event.
		SDKCall(g_hSDKCall_OnRideEnded, jockey, 0);
/*
		int flags = GetCommandFlags("dismount");
		SetCommandFlags("dismount", flags & ~FCVAR_CHEAT);
		FakeClientCommand(jockey, "dismount");
		SetCommandFlags("dismount", flags);
*/
	}
}
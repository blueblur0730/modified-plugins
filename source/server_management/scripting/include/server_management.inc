#if defined _server_management_included
 #endinput
#endif
#define _server_management_included

/**
 * Called when retrieved player's game play hours
 * 
 * @param client        client index to retrive
 * @param hours         hours retrieved
 * 
*/
forward void OnGetPlayerHours(int client, int hours)

/**
 * Called when player's game play hours is hidden
 * 
 * @param client        client index to be verified as hidden game play hours
*/
forward void OnVerifiedHiddenHoursPlayer(int client)

public SharedPlugin __pl_server_management =
{
	name = "server_management",
	file = "server_management.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
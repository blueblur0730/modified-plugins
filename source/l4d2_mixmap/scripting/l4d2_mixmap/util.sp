#if defined _l4d2_mixmap_util_included
 #endinput
#endif
#define _l4d2_mixmap_util_included

stock bool IsClientAndInGame(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) != 1);
}

stock bool IsClientOrBotAndInGame(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) != 1);
}

stock bool IsBotAndInGame(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) != 1);
}

stock bool IsSurvivorClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientConnected(client) && GetClientTeam(client) == 2);
}

stock void CheatCommand(int client, const char[] cmd) 
{
	int flags = GetCommandFlags(cmd);
	int bits = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	SetCommandFlags(cmd, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, cmd);
	SetCommandFlags(cmd, flags);
	SetUserFlagBits(client, bits);
}
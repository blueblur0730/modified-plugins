#if defined _l4d2_mixmap_util_included
 #endinput
#endif
#define _l4d2_mixmap_util_included

static const char g_sFakeMissions[][] = {
	"HoldoutChallenge",
	"DeadCenterChallenge",
	"HoldoutTraining",
	"parishdash",
	"shootzones",
	"credits"
};

static const char g_sOfficialMaps[][] = {
	"L4D2C1",
	"L4D2C2",
	"L4D2C3",
	"L4D2C4",
	"L4D2C5",
	"L4D2C6",
	"L4D2C7",
	"L4D2C8",
	"L4D2C9",
	"L4D2C10",
	"L4D2C11",
	"L4D2C12",
	"L4D2C13",
	"L4D2C14"
}

stock bool IsFakeMission(const char[] sMissionName)
{
	for (int i = 0; i < sizeof(g_sFakeMissions); i++)
	{
		if (StrEqual(sMissionName, g_sFakeMissions[i], false))
		{
			return true;
		}
	}
	return false;
}

stock bool IsOfficialMap(const char[] sMapName)
{
	for (int i = 0; i < sizeof(g_sOfficialMaps); i++)
	{
		if (StrEqual(sMapName, g_sOfficialMaps[i], false))
		{
			return true;
		}
	}
	return false;
}

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
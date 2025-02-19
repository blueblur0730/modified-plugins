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

enum /*SurvivorCharacterType*/
{
	SurvivorCharacter_Nick = 0,
	SurvivorCharacter_Rochelle,
	SurvivorCharacter_Coach,
	SurvivorCharacter_Ellis,
	SurvivorCharacter_Bill,
	SurvivorCharacter_Zoey,
	SurvivorCharacter_Francis,
	SurvivorCharacter_Louis,
	SurvivorCharacter_Invalid, // 8

	SurvivorCharacter_Size // 9 size
};

static const char g_sSurvivorNames[][] = {
	"Nick",
	"Rochelle",
	"Coach",
	"Ellis",
	"Bill",
	"Zoey",
	"Francis",
	"Louis"
}

static const char g_sSurvivorModels[][] = {
		"models/survivors/survivor_gambler.mdl",
		"models/survivors/survivor_producer.mdl",
		"models/survivors/survivor_coach.mdl",
		"models/survivors/survivor_mechanic.mdl",
		"models/survivors/survivor_namvet.mdl",
		"models/survivors/survivor_teenangst.mdl",
		"models/survivors/survivor_biker.mdl",
		"models/survivors/survivor_manager.mdl"
};

stock void PrecacheAllModels()
{
	for (int i = 0; i < sizeof(g_sSurvivorModels); i++)
		PrecacheModel(g_sSurvivorModels[i], true);
}

stock void GetCorrespondingModel(int character, char[] model, int size)
{
	strcopy(model, size, g_sSurvivorModels[character]);
}

stock void GetCorrespondingName(int character, char[] name, int size)
{
	strcopy(name, size, g_sSurvivorNames[character]);
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

stock void CheatCommand(int client, const char[] cmd, const char[] args = "") 
{
	char sBuffer[128];
	int flags = GetCommandFlags(cmd);
	int bits = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	SetCommandFlags(cmd, flags & ~FCVAR_CHEAT);
	Format(sBuffer, sizeof(sBuffer), "%s %s", cmd, args);
	FakeClientCommand(client, sBuffer);
	SetCommandFlags(cmd, flags);
	SetUserFlagBits(client, bits);
}
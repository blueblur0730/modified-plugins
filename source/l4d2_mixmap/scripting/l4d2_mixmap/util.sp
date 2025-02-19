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

stock bool IsClientInSafeArea(int client)
{
	if (client <= 0 || client > MaxClients)
		return false

	if (!IsClientInGame(client))
		return false;

	if (!IsPlayerAlive(client))
		return false;

	Address nav = L4D_GetLastKnownArea(client);
	if (!nav) return false;

	int iAttr = L4D_GetNavArea_SpawnAttributes(nav);
	bool bInStartPoint = !!(iAttr & NAV_SPAWN_PLAYER_START);
	bool bInCheckPoint = !!(iAttr & NAV_SPAWN_CHECKPOINT);
	if (!bInStartPoint && !bInCheckPoint)
		return false;

	return true;
}

stock bool IsNavInSafeArea(Address nav)
{
	int iAttr = L4D_GetNavArea_SpawnAttributes(nav);
	bool bInStartPoint = !!(iAttr & NAV_SPAWN_PLAYER_START);
	bool bInCheckPoint = !!(iAttr & NAV_SPAWN_CHECKPOINT);
	if (!bInStartPoint && !bInCheckPoint)
		return false;

	return true;
}

stock void GetSafeAreaOrigin(float vec[3])
{
	Address pCheckPoint = SDKCall(g_hSDKCall_GetInitialCheckPoint, L4D_GetPointer(POINTER_NAVMESH));
	g_hLogger.DebugEx("### GetSafeAreaOrigin: pCheckPoint: %d.", pCheckPoint);
	if (pCheckPoint != Address_Null)
	{
		Address pLargest = SDKCall(g_hSDKCall_GetLargestArea, pCheckPoint);
		g_hLogger.DebugEx("### GetSafeAreaOrigin: pLargest: %d.", pLargest);
		if (pLargest != Address_Null && IsNavInSafeArea(pLargest))
		{
			do
			{
				L4D_FindRandomSpot(pLargest, vec);
			}
			while (WillStuck(vec))
		}	
	}
}

stock void GetSafeAreaOriginEx(float vec[3])
{
	int checkPoint = L4D_GetCheckpointFirst();
	g_hLogger.DebugEx("### GetSafeAreaOriginEx: checkPoint: %d.", checkPoint);
	if (checkPoint != -1)
	{
		float fDirection[3] = { 0.0 }, fEndPos[3] = { 0.0 };
		float fMins[3] = { 0.0 }, fMaxs[3] = { 0.0 };
		float flBuffer[3] = { 0.0 };
		GetAbsOrigin(checkPoint, vec);

		fMins[0]				= vec[0] - 100.0;
		fMaxs[0]				= vec[0] + 100.0;

		fMins[1]				= vec[1] - 100.0;
		fMaxs[1]				= vec[1] + 100.0;

		fMaxs[2]				= vec[2] + 100.0;
		fDirection[0]			= 90.0;
		fDirection[1] 			= fDirection[2] = 0.0;

		flBuffer[0]			= GetRandomFloat(fMins[0], fMaxs[0]);
		flBuffer[1]			= GetRandomFloat(fMins[1], fMaxs[1]);
		flBuffer[2]			= GetRandomFloat(vec[2], fMaxs[2]);

		int count				= 0;

		while (!IsOnValidMesh(flBuffer) || WillStuck(flBuffer))
		{
			count++;

			if (count > 50)
				break;

			// try again with a new position on each searching failure.
			flBuffer[0] = GetRandomFloat(fMins[0], fMaxs[0]);
			flBuffer[1] = GetRandomFloat(fMins[1], fMaxs[1]);
			flBuffer[2] = GetRandomFloat(flBuffer[2], fMaxs[2]);

			TR_TraceRay(flBuffer, fDirection, MASK_SOLID, RayType_Infinite);
			if (TR_DidHit())
			{
				TR_GetEndPosition(fEndPos);
				flBuffer = fEndPos;
				flBuffer[2] += 25.0;
			}
		}

		vec[0] = flBuffer[0];
		vec[1] = flBuffer[1];
		vec[2] = flBuffer[2];

		if (count > 50)
		{
			g_hLogger.Debug("### GetSafeAreaOriginEx: Failed to find valid point. Try Default");
			GetSafeAreaOrigin(vec);
		}
/*
		do
		{	
			if (i > 20)
				break;

			pNav = L4D_GetNearestNavArea(vec, 1000.0, true, true, true, 2);
			++i;
		}
		while (view_as<int>(pNav) <= 0 || !IsNavInSafeArea(pNav));

		if (view_as<int>(pNav) > 0 && IsNavInSafeArea(pNav))
		{
			do
			{
				L4D_FindRandomSpot(pNav, vec);
			}
			while (WillStuck(vec));
		}
		else
		{
			g_hLogger.DebugEx("### GetSafeAreaOriginEx: Failed to find random spot. pNav: %d. Try Default", pNav);
			GetSafeAreaOrigin(vec);
		}
*/
	}
	else
	{
		g_hLogger.Debug("### GetSafeAreaOriginEx: Failed to find check point entity. pNav: Try Default");
		GetSafeAreaOrigin(vec);
	}
}

bool IsOnValidMesh(float fReferencePos[3])
{
	Address pNavArea = L4D_GetNearestNavArea(fReferencePos, _, _, _, _, 3);
	return (pNavArea != Address_Null && (L4D_GetNavArea_SpawnAttributes(pNavArea) & NAV_SPAWN_CHECKPOINT));
}

// credits to fdxx from L4D2 Special infected spawn control.
bool WillStuck(const float fPos[3])
{
	// All clients seem to be the same size.
	static const float fClientMinSize[3] = {-16.0, -16.0, 0.0};
	static const float fClientMaxSize[3] = {16.0, 16.0, 71.0};

	static bool bHit;
	static Handle hTrace;

	hTrace = TR_TraceHullFilterEx(fPos, fPos, fClientMinSize, fClientMaxSize, MASK_PLAYERSOLID, TraceFilter_Stuck);
	bHit = TR_DidHit(hTrace);

	delete hTrace;
	return bHit;
}

bool TraceFilter_Stuck(int entity, int contentsMask)
{
	if (entity <= MaxClients || !IsValidEntity(entity))
		return false;
	return true;
}

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
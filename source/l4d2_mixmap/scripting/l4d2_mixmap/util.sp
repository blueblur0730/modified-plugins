#if defined _l4d2_mixmap_util_included
	#endinput
#endif
#define _l4d2_mixmap_util_included

enum MapSetType {
	MapSet_None = 0,
	MapSet_Official = 1,
	MapSet_Custom = 2,
	MapSet_Mixtape = 3,
	MapSet_Manual = 4
}

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
	SurvivorCharacter_Invalid,	  // 8

	SurvivorCharacter_Size	  // 9 size
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

stock void GetSafeAreaOrigin(float vec[3])
{
	// HACKHACK: Some third party map's first checkpoint door's classname may not be "prop_door_rotating_checkpoint",
	// chould be unreliable.
	// how could we know the first checkpoint's classname?
	int checkPoint = L4D_GetCheckpointFirst();
	if (checkPoint != -1)
	{
		bool bFound = false;
		int count   = 0;
		do
		{
			bFound = SearchForValidPoint(checkPoint, vec);
			count++;
		}
		while (!bFound && g_hCvar_ShouldSearchAgain.BoolValue && count < g_hCvar_SearchAgainCount.IntValue)
		
		if (count > g_hCvar_CheckPointSearchCount.IntValue)
		{
			g_hLogger.Debug("### GetSafeAreaOriginEx: Failed to find valid point. Trying Default");
			GetSafeAreaOriginEx(checkPoint, vec);
		}
	}
	else
	{
		g_hLogger.DebugEx("### GetSafeAreaOriginEx: Failed to find checkpoint entity. checkPoint: %d. Abort action.", checkPoint);
	}
}

stock void GetSafeAreaOriginEx(int checkPoint, float vec[3])
{
// TerrorNavMesh::GetInitialCheckPoint get the first checkpoint door by finding info_landmark through s_landmarkname.
// since we have meesed up with the landmark driving around in different compaigns, this is probably not work,
// at least everytime I call this function it just throws me a pretty 0. Nice.
// Let's just use the old way.
/*
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
*/
	if (checkPoint != -1)
	{
		int i = 0;
		int count = 0;
		Address pNav = Address_Null;
		bool bFound = false;
		GetAbsOrigin(checkPoint, vec);

		while (!bFound)
		{
			count = 0;
			if (i > g_hCvar_CheckPointSearchCount.IntValue)
				break;

			pNav = L4D_GetNearestNavArea(vec, 1000.0, true, true, true, 2);
			++i;

			if (view_as<int>(pNav) > 0 && IsNavInSafeArea(pNav))
			{
				do
				{
					L4D_FindRandomSpot(pNav, vec);
					count++;
				}
				while (WillStuck(vec) && count <= g_hCvar_CheckPointSearchCount.IntValue);
			}

			if (count <= g_hCvar_CheckPointSearchCount.IntValue)
				bFound = true;
		}

		if (!bFound)
			g_hLogger.DebugEx("### GetSafeAreaOriginEx: Failed to find random spot. pNav: %d.", pNav);
	}
}

bool SearchForValidPoint(int checkPoint, float vec[3])
{
	float fDirection[3] = { 0.0 }, fEndPos[3] = { 0.0 };
	float fMins[3] = { 0.0 }, fMaxs[3] = { 0.0 };
	float flBuffer[3] = { 0.0 };
	GetAbsOrigin(checkPoint, vec);

	fMins[0]	  = vec[0] - 100.0;
	fMaxs[0]	  = vec[0] + 100.0;

	fMins[1]	  = vec[1] - 100.0;
	fMaxs[1]	  = vec[1] + 100.0;

	fMaxs[2]	  = vec[2] + 100.0;
	fDirection[0] = 90.0;
	fDirection[1] = fDirection[2] = 0.0;

	flBuffer[0]					  = GetRandomFloat(fMins[0], fMaxs[0]);
	flBuffer[1]					  = GetRandomFloat(fMins[1], fMaxs[1]);
	flBuffer[2]					  = GetRandomFloat(vec[2], fMaxs[2]);

	int count					  = 0;

	while (!IsOnValidMesh(flBuffer) || WillStuck(flBuffer))
	{
		count++;

		if (count > g_hCvar_CheckPointSearchCount.IntValue)
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

	if (count > g_hCvar_CheckPointSearchCount.IntValue)
		return false;

	vec[0] = flBuffer[0];
	vec[1] = flBuffer[1];
	vec[2] = flBuffer[2];

	return true;
}

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

	int	 iAttr		   = L4D_GetNavArea_SpawnAttributes(nav);
	bool bInStartPoint = !!(iAttr & NAV_SPAWN_PLAYER_START);
	bool bInCheckPoint = !!(iAttr & NAV_SPAWN_CHECKPOINT);
	if (!bInStartPoint && !bInCheckPoint)
		return false;

	return true;
}

stock bool IsNavInSafeArea(Address nav)
{
	int	 iAttr		   = L4D_GetNavArea_SpawnAttributes(nav);
	bool bInStartPoint = !!(iAttr & NAV_SPAWN_PLAYER_START);
	bool bInCheckPoint = !!(iAttr & NAV_SPAWN_CHECKPOINT);
	if (!bInStartPoint && !bInCheckPoint)
		return false;

	return true;
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
	static const float fClientMinSize[3] = { -16.0, -16.0, 0.0 };
	static const float fClientMaxSize[3] = { 16.0, 16.0, 71.0 };

	static bool		   bHit;
	static Handle	   hTrace;

	hTrace = TR_TraceHullFilterEx(fPos, fPos, fClientMinSize, fClientMaxSize, MASK_PLAYERSOLID, TraceFilter_Stuck);
	bHit   = TR_DidHit(hTrace);

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
	return CheckMap(sMissionName, g_sFakeMissions, sizeof(g_sFakeMissions));
}

stock bool IsOfficialMap(const char[] sMapName)
{
	return CheckMap(sMapName, g_sOfficialMaps, sizeof(g_sOfficialMaps));
}

stock void SetGod(int client, bool on)
{
	int flags = GetEntityFlags(client);

	if (!on && (flags & FL_GODMODE))
	{
		SetEntityFlags(client, flags & ~FL_GODMODE)
	}
	else if (on && !(flags & FL_GODMODE))
	{
		SetEntityFlags(client, flags | FL_GODMODE);
	}
}

bool CheckMap(const char[] sMapName, const char[][] sList, int listSize)
{
	for (int i = 0; i < listSize; i++)
	{
		if (StrEqual(sMapName, sList[i], false))
		{
			return true;
		}
	}
	return false;
}

stock void CheatCommand(int client, const char[] cmd, const char[] args = "")
{
	char sBuffer[128];
	int	 flags = GetCommandFlags(cmd);
	int	 bits  = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	SetCommandFlags(cmd, flags & ~FCVAR_CHEAT);
	Format(sBuffer, sizeof(sBuffer), "%s %s", cmd, args);
	FakeClientCommand(client, sBuffer);
	SetCommandFlags(cmd, flags);
	SetUserFlagBits(client, bits);
}

// get real gamemode. this is for mutation and community modes,
// and even custom modes (need to set mp_gamemode to the value).
// compatible for official modes.
stock void GetBasedMode(char[] sMode, int size)
{
	// could actually use CMatchExtL4D::GetGameModeInfo... well whatever.
	SourceKeyValues kvGameModes = SDKCall(g_hSDKCall_GetAllModes, g_pMatchExtL4D);

	// HACKHACK: is "teamversus", "teamscavenge" valid?
	char sBuffer[64];
	Format(sBuffer, sizeof(sBuffer), "%s/base", sMode);
	SourceKeyValues kvBase = kvGameModes.FindKey(sBuffer);

	// found. get base.
	if (kvBase && !kvBase.IsNull())
	{
		kvBase.GetString(NULL_STRING, sMode, size);

		// except for realism mode. this is actualy coop since no mission uses "realism" as a key.
		if (!strcmp(sMode, "realism"))
			strcopy(sMode, size, "coop");
	}
}

// bye bye sourcemod keyvalues.
stock void BuildBlackList(int client)
{
	char sPath[128];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_BLACKLIST);

	SourceKeyValues kv = SourceKeyValues("BlackList");
	if (kv.LoadFromFile(sPath))
	{
		delete g_hArrayBlackList;
		g_hArrayBlackList = new ArrayList(ByteCountToCells(64));

		char sMap[64];
		int count = 0;
		SourceKeyValues kvSub = kv.FindKey("global_filter");
		if (kvSub && !kvSub.IsNull())
		{
			for (SourceKeyValues kvValue = kvSub.GetFirstValue(); kvValue && !kvValue.IsNull(); kvValue = kvValue.GetNextValue())
			{
				kvValue.GetString(NULL_STRING, sMap, sizeof(sMap));
				g_hArrayBlackList.PushString(sMap);
				count++;

				// reached limit. return.
				if (count >= g_hCvar_BlackListLimit.IntValue)
				{
					kv.deleteThis();
					g_hLogger.WarnEx("Reached limit of %d blacklisted maps. Abort the rest.", g_hCvar_BlackListLimit.IntValue);

					if (client != -1 && client > 0 && client <= MaxClients)
						CPrintToChat(client, "%t", "BlackListLoaded");

					return;
				}
			}
		}

		char sMode[32];
		FindConVar("mp_gamemode").GetString(sMode, sizeof(sMode));
		GetBasedMode(sMode, sizeof(sMode));

		kvSub = kv.FindKey(sMode);
		if (kvSub && !kvSub.IsNull())
		{
			for (SourceKeyValues kvValue = kvSub.GetFirstValue(); kvValue && !kvValue.IsNull(); kvValue = kvValue.GetNextValue())
			{
				kvValue.GetString(NULL_STRING, sMap, sizeof(sMap));
				g_hArrayBlackList.PushString(sMap);
				count++;

				// reached limit. return.
				if (count >= g_hCvar_BlackListLimit.IntValue)
				{
					kv.deleteThis();
					g_hLogger.WarnEx("Reached limit of %d blacklisted maps. Abort the rest.", g_hCvar_BlackListLimit.IntValue);

					if (client != -1 && client > 0 && client <= MaxClients)
						CPrintToChat(client, "%t", "BlackListLoaded");

					return;
				}
			}
		}

		if (!g_hArrayBlackList || !g_hArrayBlackList.Length)
		{
			kv.deleteThis();
			g_hLogger.ErrorEx("No keys found in \""...CONFIG_BLACKLIST..."\" on node %s and global filter.", sMode);

			if (client != -1 && client > 0 && client <= MaxClients)
				CPrintToChat(client, "%t", "NoKeysFoundInBlackList");

			return;
		}
	}
	else
	{
		kv.deleteThis();
		g_hLogger.Error("Failed to load black list file from \""...CONFIG_BLACKLIST..."\".");

		if (client != -1 && client > 0 && client <= MaxClients)
			CPrintToChat(client, "%t", "FailedToLoadBlackList");

		return;
	}

	if (client != -1 && client > 0 && client <= MaxClients)
		CPrintToChat(client, "%t", "BlackListLoaded");

	kv.deleteThis();
}

stock bool CheckBlackList(const char[] sMap)
{
	int found = g_hArrayBlackList.FindString(sMap);
	if (found != -1)
		return true;
	
	return false;
}

stock void LoadTranslation(const char[] translation)
{
	char sPath[PLATFORM_MAX_PATH], sName[64];
	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("[MixMap] Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}
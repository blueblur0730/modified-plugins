#if defined _l4d2_mixmap_util_included
	#endinput
#endif
#define _l4d2_mixmap_util_included

enum MapSetType
{
	MapSet_None		= 0,
	MapSet_Official = 1,
	MapSet_Custom	= 2,
	MapSet_Mixtape	= 3,
	MapSet_Manual	= 4,
	MapSet_Preset	= 5
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

stock void Patch(MemoryPatch hPatch, bool bPatch)
{
	static bool bPatched = false;
	if (bPatch && !bPatched)
	{
		hPatch.Enable();
		bPatched = true;
	}
	else if (!bPatch && bPatched)
	{
		hPatch.Disable();
		bPatched = false;
	}
}

stock void GetSafeAreaOrigin(float vec[3])
{
/*
	// HACKHACK: Some third party map's first checkpoint door's classname may not be "prop_door_rotating_checkpoint",
	// chould be unreliable.
	// how could we know the first checkpoint's classname?
	int checkPoint = L4D_GetCheckpointFirst();
	if (checkPoint != -1)
	{
		bool bFound = false;
		int	 count	= 0;
		do
		{
			bFound = SearchForValidPoint(checkPoint, vec);
			count++;
		}
		while (!bFound && g_hCvar_ShouldSearchAgain.BoolValue && count < g_hCvar_SearchAgainCount.IntValue)

		if (count > g_hCvar_CheckPointSearchCount.IntValue)
		{
			g_hLogger.Debug("### GetSafeAreaOrigin: Failed to find valid point. Trying Default");
			GetSafeAreaOriginEx(checkPoint, vec);
		}
	}
	else
	{
		g_hLogger.DebugEx("### GetSafeAreaOrigin: Failed to find checkpoint entity. checkPoint: %d. Abort action.", checkPoint);
	}
*/

	// every level has at least one info_landmark entity and should always be inside of saferoom.
	int ent = INVALID_ENT_REFERENCE;
	while ((ent = FindEntityByClassname(ent, "info_landmark")) != INVALID_ENT_REFERENCE)
	{
		GetAbsOrigin(ent, vec);

#if REQUIRE_LOG4SP
		g_hLogger.DebugEx("### GetSafeAreaOrigin: Found landmark entity: %d.", ent);
#else
		g_hLogger.debug("### GetSafeAreaOrigin: Found landmark entity: %d.", ent);
#endif
		
		Address pNav = L4D_GetNearestNavArea(vec, 100.0, true, false, false, 2);
		if (pNav != Address_Null && IsNavInSafeArea(pNav))
		{
#if REQUIRE_LOG4SP
			g_hLogger.DebugEx("### GetSafeAreaOrigin: Found valid point: %f, %f, %f.", vec[0], vec[1], vec[2]);
#else
			g_hLogger.debug("### GetSafeAreaOrigin: Found valid point: %f, %f, %f.", vec[0], vec[1], vec[2]);
#endif
			return;
		}
	}

#if REQUIRE_LOG4SP
	g_hLogger.DebugEx("### GetSafeAreaOrigin: Failed to find valid point. Trying Default");
#else
	g_hLogger.debug("### GetSafeAreaOrigin: Failed to find valid point. Trying Default");
#endif
	GetSafeAreaOriginEx(vec);
}

void GetSafeAreaOriginEx(float vec[3])
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
	int checkPoint = L4D_GetCheckpointFirst();

	if (checkPoint != -1)
	{
		int		i	   = 0;
		int		count  = 0;
		Address pNav   = Address_Null;
		bool	bFound = false;
		GetAbsOrigin(checkPoint, vec);

		while (!bFound)
		{
			count = 0;
			if (i > g_hCvar_CheckPointSearchCount.IntValue)
				break;

			pNav = L4D_GetNearestNavArea(vec, 1000.0, true, true, true, 2);
			++i;

			if (pNav != Address_Null && IsNavInSafeArea(pNav))
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
		{
#if REQUIRE_LOG4SP
			g_hLogger.DebugEx("### GetSafeAreaOriginEx: Failed to find random spot. pNav: %d.", pNav);
#else
			g_hLogger.debug("### GetSafeAreaOriginEx: Failed to find random spot. pNav: %d.", pNav);
#endif
		}
			
	}
}

/*
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
*/

stock bool IsClientInSafeArea(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	if (!IsClientInGame(client)) 
		return false;

	if (!IsPlayerAlive(client))
		return false;

	Address nav = L4D_GetLastKnownArea(client);
	if (!nav) return false;

	return IsNavInSafeArea(nav);
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

// credits to fdxx from L4D2 Special infected spawn control.
stock bool WillStuck(const float fPos[3])
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

stock bool IsOnValidMesh(float fReferencePos[3])
{
	Address pNavArea = L4D_GetNearestNavArea(fReferencePos, _, _, _, _, 2);
	return (pNavArea != Address_Null && (L4D_GetNavArea_SpawnAttributes(pNavArea) & NAV_SPAWN_CHECKPOINT));
}

void PrecacheAllModels()
{
	for (int i = 0; i < sizeof(g_sSurvivorModels); i++)
		PrecacheModel(g_sSurvivorModels[i], true);
}

void GetCorrespondingModel(int character, char[] model, int size)
{
	strcopy(model, size, g_sSurvivorModels[character]);
}

void GetCorrespondingName(int character, char[] name, int size)
{
	strcopy(name, size, g_sSurvivorNames[character]);
}

bool IsFakeMission(const char[] sMissionName)
{
	return CheckMap(sMissionName, g_sFakeMissions, sizeof(g_sFakeMissions));
}

bool IsOfficialMap(const char[] sMapName)
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
stock void GetBasedMode(char[] sMode, int size)
{
	SourceKeyValues kvGameMode = TheMatchExt.GetGameModeInfo(sMode);
	if (!kvGameMode || kvGameMode.IsNull())
	{
#if REQUIRE_LOG4SP
		g_hLogger.ErrorEx("Failed to get gamemode info for gamnemode \"%s\".", sMode);
#else
		g_hLogger.error("Failed to get gamemode info for gamnemode \"%s\".", sMode);
#endif
		return;
	}

	kvGameMode.GetString("base", sMode, size);

	// except for realism mode. this is actualy coop since no mission uses "realism" as a key.
	if (!strcmp(sMode, "realism"))
		strcopy(sMode, size, "coop");
}

// credits to shqke: https://github.com/shqke/imatchext/blob/main/src/natives.cpp#L30
stock SourceKeyValues GetServerGameDetails(Address &pkvRequest = Address_Null)
{
	Address pMatchNetworkMsgController = SDKCall(g_hSDKCall_GetMatchNetworkMsgController, g_MatchFramework);
#if REQUIRE_LOG4SP
	g_hLogger.DebugEx("### pMatchNetworkMsgController: %d", pMatchNetworkMsgController);
#else
	g_hLogger.debug("### pMatchNetworkMsgController: %d", pMatchNetworkMsgController);
#endif

	Address pkvDetails;
	if (pMatchNetworkMsgController != Address_Null)
	{
		pkvDetails = SDKCall(g_hSDKCall_GetActiveServerGameDetails, pMatchNetworkMsgController, pkvRequest);
#if REQUIRE_LOG4SP
		g_hLogger.DebugEx("### kvDetails: %d", pkvDetails);
#else
		g_hLogger.debug("### kvDetails: %d", pkvDetails);
#endif
	}

	return view_as<SourceKeyValues>(pkvDetails);
}

stock void ConvertTagAndTranslate(char[] sTag, int size, int client, bool bIsOfficial)
{
	if (bIsOfficial)
	{
		// strip "#"
		if (!strncmp(sTag[0], "#", false))
			strcopy(sTag, size, sTag[1]);

    	StrToLowerCase(sTag, sTag, size);
    	Format(sTag, size, "%T", sTag, client);
	}
	else
	{
		// else use file's default.
		if (TranslationPhraseExists(sTag) && IsTranslatedForLanguage(sTag, GetClientLanguage(client)))
		{
			Format(sTag, size, "%T", sTag, client);
		}
		else
		{
#if REQUIRE_LOG4SP
			g_hLogger.DebugEx("Failed to translate phrase \"%s\" for language \"%s\".", sTag, GetClientLanguage(client));
#else
			g_hLogger.debug("Failed to translate phrase \"%s\" for language \"%s\".", sTag, GetClientLanguage(client));
#endif
		}
	}
}

// from attachment_api by Silvers.
stock void StrToLowerCase(const char[] input, char[] output, int maxlength)
{
	int pos;
	while ( input[pos] != 0 && pos < maxlength )
	{
		output[pos] = CharToLower(input[pos]);
		pos++;
	}

	output[pos] = 0;
}
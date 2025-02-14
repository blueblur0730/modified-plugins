#if defined _l4d2_mixmap_logic_included
 #endinput
#endif
#define _l4d2_mixmap_logic_included

// ----------------------------------------------------------
// 		Map pool logic
// ----------------------------------------------------------

// Get all missions and their map names.
void CollectAllMaps()
{
	if (!g_hArrayMissionsAndMaps)
		g_hArrayMissionsAndMaps = new ArrayList();

	char sMode[32], sKey[256];
	ConVar mp_gamemode = FindConVar("mp_gamemode");
	mp_gamemode.GetString(sMode, sizeof(sMode));

	// In this case we iterate only the subkeys.
	SourceKeyValues kvMissions = SDKCall(g_hSDKCall_GetAllMissions, g_pMatchExtL4D);
	for (SourceKeyValues kvSub = kvMissions.GetFirstTrueSubKey(); !kvSub.IsNull(); kvSub = kvSub.GetNextTrueSubKey())
	{
		char sMissionName[128];
		kvSub.GetName(sMissionName, sizeof(sMissionName));  // "Name"   "xxx"

		if (IsFakeMission(sMissionName))
			continue;

		// we find the key modes/<mode> , continue the subkey iteration.
		FormatEx(sKey, sizeof(sKey), "modes/%s", sMode);
		SourceKeyValues kvMode = kvSub.FindKey(sKey);

		if (!kvMode.IsNull())
		{
            // should be free.
			ArrayList hArray = new ArrayList(ByteCountToCells(64));

			// on this case we are iterating "1", "2"... subkeys.
			for (SourceKeyValues kvMapNumber = kvMode.GetFirstTrueSubKey(); !kvMapNumber.IsNull(); kvMapNumber = kvMapNumber.GetNextTrueSubKey())
			{
                char sTest[64];
                kvMapNumber.GetName(sTest, sizeof(sTest));

				// iterating sub-keyvalues.
				for (SourceKeyValues kvMap = kvMapNumber.GetFirstValue(); !kvMap.IsNull(); kvMap = kvMap.GetNextValue())
				{
					char sKeyName[64], sValue[64];
					kvMap.GetName(sKeyName, sizeof(sKeyName));
					if (StrEqual(sKeyName, "Map", false))
					{
						kvMap.GetString(NULL_STRING, sValue, sizeof(sValue));
						hArray.PushString(sValue);
                        break;	// found, break.
					}
				}
			}

			// pack mission and map names up. into an arraylist so we can sort them.
			DataPack dp = new DataPack();
			dp.WriteString(sMissionName);
			dp.WriteCell(hArray);
			g_hArrayMissionsAndMaps.Push(dp);
		}
	}
}

bool SelectRandomMap()
{
	g_bMaplistFinalized = true;
	SetRandomSeed(view_as<int>(GetEngineTime()));

	if (!g_hArrayMissionsAndMaps || !g_hArrayMissionsAndMaps.Length)
		return false;

	if (g_hArrayMissionsAndMaps.Length < g_cvMapPoolCapacity.IntValue)
	{
		CPrintToChatAll("%t", "Change_Map_NotEnoughMaps", g_cvMapPoolCapacity.IntValue);
		CleanMemory();
		return false;
	}
	
	DataPack dp;
	delete g_hArrayPools;
	g_hArrayPools = new ArrayList(ByteCountToCells(64));
	bool bReachedFinale = false;
	for (int i = 0; i < g_cvMapPoolCapacity.IntValue; i++)
	{
		char sMissionName[64], sMap[64];
		// first random sort the main arraylist, meaning choosing a mission here randomly.
		// everytime we loop through the arraylist we sort again.
		g_hArrayMissionsAndMaps.Sort(Sort_Random, Sort_Integer);
		int index = GetRandomInt(0, g_hArrayMissionsAndMaps.Length - 1);
		dp = g_hArrayMissionsAndMaps.Get(index);

		// earse this one for next selection.
		g_hArrayMissionsAndMaps.Erase(index);

		// have reached the finale map.
		if (i == g_cvMapPoolCapacity.IntValue)
			bReachedFinale = true;

		dp.Reset();
		dp.ReadString(sMissionName, sizeof(sMissionName));
		ArrayList hArray = dp.ReadCell();
		if (hArray && hArray.Length)
		{
			// here we choose a map from the mission.
			hArray.Sort(Sort_Random, Sort_String);
			int random;

			if (!bReachedFinale)
			{
				// do not let a finale map be selected beyong the end of map sequence. we earse the last map.
				random = GetRandomInt(0, hArray.Length - 2);
			}
			else
			{
				random = GetRandomInt(0, hArray.Length - 1);
			}

			hArray.GetString(random, sMap, sizeof(sMap));
			g_hArrayPools.PushString(sMap);
			delete hArray;
		}

		delete dp;
	}

	delete g_hArrayMissionsAndMaps;
	CPrintToChatAll(">---{green}Map List{default}---<");

	// call starting forward
	char sBuffer[64];
	for (int i = 0; i < g_hArrayPools.Length; i++)
	{
		g_hArrayPools.GetString(i, sBuffer, sizeof(sBuffer));
		CPrintToChatAll("{green}-> {olive}%s", sBuffer);
	}

	CPrintToChatAll("Prepare to change the map.");
	CreateTimer(10.0, Timed_GiveThemTimeToReadTheMapList);

	return true;
}

void Timed_GiveThemTimeToReadTheMapList(Handle timer)
{
	Call_StartForward(g_hForwardStart);
	Call_PushCell(g_iMapCount);
	Call_PushCell(g_hArrayPools);
	Call_Finish();

	GotoNextMap(true);
}

bool IsFakeMission(const char[] sMissionName)
{
	return (StrEqual(sMissionName, "HoldoutChallenge", false)
		||  StrEqual(sMissionName, "DeadCenterChallenge", false)
		||  StrEqual(sMissionName, "HoldoutTraining", false)
		||  StrEqual(sMissionName, "parishdash", false)
		||  StrEqual(sMissionName, "shootzones", false)
		||  StrEqual(sMissionName, "credits", false))
}

bool IsOfficialMap(const char[] map)
{
	return (StrEqual(map, "L4D2C1", false)
		||  StrEqual(map, "L4D2C2", false)
		||  StrEqual(map, "L4D2C3", false)
		||  StrEqual(map, "L4D2C4", false)
		||  StrEqual(map, "L4D2C5", false)
		||  StrEqual(map, "L4D2C6", false)
		||  StrEqual(map, "L4D2C7", false)
		||  StrEqual(map, "L4D2C8", false)
		||  StrEqual(map, "L4D2C9", false)
		||  StrEqual(map, "L4D2C10", false)
		||  StrEqual(map, "L4D2C11", false)
		||  StrEqual(map, "L4D2C12", false)
		||  StrEqual(map, "L4D2C13", false)
		||  StrEqual(map, "L4D2C14", false))
}

void CleanMemory()
{
	if (g_hArrayMissionsAndMaps && g_hArrayMissionsAndMaps.Length)
	{
		for (int i = 0; i < g_hArrayMissionsAndMaps.Length; i++)
		{
			char string[64];
			DataPack dp = g_hArrayMissionsAndMaps.Get(i);
			dp.Reset();
			dp.ReadString(string, sizeof(string));
			ArrayList hArray = dp.ReadCell();
			delete hArray;
			delete dp;
		}
	}
}
/*
void SelectRandomMap() 
{
	g_bMaplistFinalized = true;
	SetRandomSeed(view_as<int>(GetEngineTime()));

	int mapIndex;
	int mapsmax = g_cvMaxMapsNum.IntValue;
	ArrayList hArrayPool;
	char tag[64], map[64];

	// Select 1 random map for each rank out of the remaining ones
	for (int i = 0; i < g_hArrayTagOrder.Length; i++) 
	{
		g_hArrayTagOrder.GetString(i, tag, 64);
		g_hTriePools.GetValue(tag, hArrayPool);
		hArrayPool.Sort(Sort_Random, Sort_String);	//randomlize the array
		mapIndex = GetRandomInt(0, hArrayPool.Length - 1);

		hArrayPool.GetString(mapIndex, map, 64);
		hArrayPool.Erase(mapIndex);
		if (mapsmax)	//if limit the number of missions in one campaign, check the number.
		{
			if (CheckSameCampaignNum(map) >= mapsmax)
			{
				while (hArrayPool.Length > 0)	// Reselect if the number will exceed the limit 
				{
					mapIndex = GetRandomInt(0, hArrayPool.Length - 1);
					hArrayPool.GetString(mapIndex, map, 64);
					hArrayPool.Erase(mapIndex);
					if (CheckSameCampaignNum(map) < mapsmax) break;
				}
				if (CheckSameCampaignNum(map) >= mapsmax)	//Reselect some missions (like only 1 mission4, the mission4 can't select)
				{
					g_hTriePools.GetValue(tag, hArrayPool);
					hArrayPool.Sort(Sort_Random, Sort_String);
					mapIndex = GetRandomInt(0, hArrayPool.Length - 1);
					hArrayPool.GetString(mapIndex, map, 64);
					ReSelectMapOrder(map);
				}
			}
		}
		g_hArrayMapOrder.PushString(map);
	}

	// Clear things because we only need the finalised map order in memory
	g_hTriePools.Clear();
	g_hArrayTagOrder.Clear();

	// Show final maplist to everyone
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i) && !IsFakeClient(i)) 
			FakeClientCommand(i, "sm_maplist");
	}

	CPrintToChatAll("%t", "Change_Map_First", g_bServerForceStart ? 5 : 15);	//Alternative for remixmap
	g_hCountDownTimer = CreateTimer(g_bServerForceStart ? 5.0 : 15.0, Timed_GiveThemTimeToReadTheMapList);	//Alternative for remixmap
}
*/

/*
void ReSelectMapOrder(char[] confirm)	//hope this will work
{
	char buffer[64];
	ArrayList hArrayPool;
	int mapindex;
	
	for (int i = g_hArrayMapOrder.Length - 1; i >= 0; i--) 
	{
		g_hArrayMapOrder.GetString(i, buffer, 64);
		if (IsSameCampaign(confirm, buffer)) 
		{
			g_hArrayTagOrder.GetString(i, buffer, 64);
			g_hTriePools.GetValue(buffer, hArrayPool);
			hArrayPool.Erase(hArrayPool.FindString(confirm));
			for (int j = 0; j <= i; j++) 
			{
				hArrayPool.Sort(Sort_Random, Sort_String);	//randomlize the array
				mapindex = GetRandomInt(0, hArrayPool.Length - 1);
				hArrayPool.GetString(mapindex, buffer, 64);
				hArrayPool.Erase(mapindex);
				if (CheckSameCampaignNum(buffer) < g_cvMaxMapsNum.IntValue) 
				{
					g_hArrayMapOrder.SetString(i, buffer);
					break;
				}
			}
			return;
		}
	}
}
*/
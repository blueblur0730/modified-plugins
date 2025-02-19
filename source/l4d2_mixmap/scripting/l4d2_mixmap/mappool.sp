#if defined _l4d2_mixmap_mappool_included
 #endinput
#endif
#define _l4d2_mixmap_mappool_included

// Get all missions and their map names.
void CollectAllMaps(MapSetType type)
{
	if (!g_hArrayMissionsAndMaps)
		g_hArrayMissionsAndMaps = new ArrayList();

	delete g_hArraySurvivorSets;
	g_hArraySurvivorSets = new ArrayList();

	char sMode[32], sKey[256];
	ConVar mp_gamemode = FindConVar("mp_gamemode");
	mp_gamemode.GetString(sMode, sizeof(sMode));

	// In this case we iterate only the subkeys.
	SourceKeyValues kvMissions = SDKCall(g_hSDKCall_GetAllMissions, g_pMatchExtL4D);
	for (SourceKeyValues kvSub = kvMissions.GetFirstTrueSubKey(); !kvSub.IsNull(); kvSub = kvSub.GetNextTrueSubKey())
	{
		char sMissionName[128];
		kvSub.GetName(sMissionName, sizeof(sMissionName));  // "Name"   "xxx"

		// no fake compaign. these are not playable.
		if (IsFakeMission(sMissionName))
			continue;

		switch (type)
		{
			case MapSet_Custom:
			{
				if (IsOfficialMap(sMissionName))
					continue;
			}
				
			case MapSet_Official:
			{
				if (!IsOfficialMap(sMissionName))
					continue;
			}
		}

		int survivorSet = kvSub.GetInt("survivor_set", 2);	// L4D2 = 2, L4D1 = 1

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
			dp.WriteCell(hArray);
			dp.WriteCell(survivorSet);
			dp.WriteString(sMissionName);
			g_hArrayMissionsAndMaps.Push(dp);
		}
	}
}

bool SelectRandomMap()
{
	SetRandomSeed(view_as<int>(GetEngineTime()));

	if (!g_hArrayMissionsAndMaps || !g_hArrayMissionsAndMaps.Length)
		return false;

	if (g_hArrayMissionsAndMaps.Length < g_hCvar_MapPoolCapacity.IntValue)
	{
		CPrintToChatAll("%t", "NotEnoughMaps");
		CleanMemory();
		return false;
	}
	
	delete g_hArrayPools;
	g_hArrayPools = new ArrayList(ByteCountToCells(64));

	delete g_hMapChapterNames;
	g_hMapChapterNames = new StringMap();

	delete g_hArraySurvivorSets;
	g_hArraySurvivorSets = new ArrayList();

	ArrayList hArrayBlackList = null;
	if (g_hCvar_EnableBlackList.BoolValue)
	{
		char sPath[128];
		BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_BLACKLIST);
		KeyValues kv = new KeyValues("");
		if (kv.ImportFromFile(sPath))
		{
			if (kv.GotoFirstSubKey())
			{
				hArrayBlackList = new ArrayList(ByteCountToCells(64));

				do
				{
					char sMap[64];
					kv.GetString(NULL_STRING, sMap, sizeof(sMap));
					hArrayBlackList.PushString(sMap);
				}
				while (kv.GotoNextKey());
			}
			else
			{
				LogError("No keys found in \""...CONFIG_BLACKLIST..."\", black list disabled.");
			}
		}
		else
		{
			LogError("Failed to load black list file from \""...CONFIG_BLACKLIST..."\", black list disabled.");
		}

		delete kv;
	}

	for (int i = 0; i < g_hCvar_MapPoolCapacity.IntValue; i++)
	{
		// first random sort the main arraylist, meaning choosing a mission here randomly.
		// everytime we loop through the arraylist we sort again.
		char sMissionName[64], sMap[64];
		g_hArrayMissionsAndMaps.Sort(Sort_Random, Sort_Integer);
		int index = GetRandomInt(0, g_hArrayMissionsAndMaps.Length - 1);
		DataPack dp = g_hArrayMissionsAndMaps.Get(index);

		dp.Reset();
		ArrayList hArray = dp.ReadCell();
		int survivorSet = dp.ReadCell();
		dp.ReadString(sMissionName, sizeof(sMissionName));

		// set the mission's first map name, as we need the mission name to transfer to the first map.
		char sFirstMap[128];
		hArray.GetString(0, sFirstMap, sizeof(sFirstMap));
		g_hMapChapterNames.SetString(sFirstMap, sMissionName);
		
		// hArray is only one time used.
		if (hArray && hArray.Length)
		{
			// the first map should be always the first one.
			if (i == 0)
			{
				hArray.GetString(0, sMap, sizeof(sMap));
				if (CheckBlackList(hArrayBlackList, sMap))
				{
					i--;	// do not take this into count.
					continue;
				}

				g_hArrayPools.PushString(sMap);
				g_hArraySurvivorSets.Push(survivorSet);
			}
			else if (i == g_hCvar_MapPoolCapacity.IntValue - 1)	// the last selection must be the finale.
			{
				hArray.GetString(hArray.Length - 1, sMap, sizeof(sMap));
				if (CheckBlackList(hArrayBlackList, sMap))
				{
					// dont need this, as it only have one map and it's on the blacklist.
					if (hArray.Length == 1)
						delete hArray;

					i--;
					continue;
				}

				g_hArrayPools.PushString(sMap);
				g_hArraySurvivorSets.Push(survivorSet);
			}
			else
			{
				if (hArray.Length > 2)	// we need at least 2 maps to make a selection.
				{
					// erase the head and tail.
					hArray.Erase(hArray.Length - 1);
					hArray.Erase(0);

					if (g_hCvar_EnableBlackList.BoolValue && hArrayBlackList)
					{
						do
						{
							// all the thing are removed so stop it.
							if (!hArray.Length)
								break;

							hArray.Sort(Sort_Random, Sort_String);	// randomlize the array
							int random = GetRandomInt(0, hArray.Length - 1);
							hArray.GetString(random, sMap, sizeof(sMap));
							if (CheckBlackList(hArrayBlackList, sMap))
								hArray.Erase(random);	// in case all the array are the hater, we erase it.
						}
						while (CheckBlackList(hArrayBlackList, sMap));

						// we got nothing from here, do not take this into count and remove this.
						if (!hArray.Length)
						{
							i--;	// do not take this into count.
							delete hArray;
							continue;
						}
					}
					else
					{
						hArray.Sort(Sort_Random, Sort_String);	// randomlize the array
						int random = GetRandomInt(0, hArray.Length - 1);
						hArray.GetString(random, sMap, sizeof(sMap));
					}

					g_hArrayPools.PushString(sMap);
					g_hArraySurvivorSets.Push(survivorSet);
				}
				else if (hArray.Length == 2)
				{
					// else we use the first map, and make sure it is not a finale.
					hArray.GetString(0, sMap, sizeof(sMap));
					if (CheckBlackList(hArrayBlackList, sMap))
					{
						i--;
						continue;
					}

					g_hArrayPools.PushString(sMap);
					g_hArraySurvivorSets.Push(survivorSet);
				}
				else if (hArray.Length == 1)	// do not take any action, as this can be a finale map.
				{
					// we need to decrease the index, as we do not push any map into the arraylist.
					i--;
					continue;	// save this if it is finale.
				}
			}

			delete hArray;
		}

		// earse this one you've made this far for next selection. make sure no same compaign map.
		g_hArrayMissionsAndMaps.Erase(index);

		delete dp;
	}

	delete g_hArrayMissionsAndMaps;
	delete hArrayBlackList;

	for (int i = 1; i < MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;

		NotifyMapList(i);
	}

	return true;
}

bool CheckBlackList(ArrayList hArrayBlackList, const char[] sMap)
{
	if (g_hCvar_EnableBlackList.BoolValue && hArrayBlackList)
	{
		int found = hArrayBlackList.FindString(sMap);
		if (found != -1)
			return true;
	}

	return false;
}

void CleanMemory()
{
	if (g_hArrayMissionsAndMaps && g_hArrayMissionsAndMaps.Length)
	{
		for (int i = 0; i < g_hArrayMissionsAndMaps.Length; i++)
		{
			DataPack dp = g_hArrayMissionsAndMaps.Get(i);
			dp.Reset();
			ArrayList hArray = dp.ReadCell();
			delete hArray;
			delete dp;
		}
	}
}
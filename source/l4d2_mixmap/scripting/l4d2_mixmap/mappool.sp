#if defined _l4d2_mixmap_mappool_included
 #endinput
#endif
#define _l4d2_mixmap_mappool_included

/**
 * -----------------------------
 * Randomly select map section.
 * -----------------------------
*/

// Get all missions and their map names.
void CollectAllMaps(MapSetType type)
{
	delete g_hArrayMissionsAndMaps;
	g_hArrayMissionsAndMaps = new ArrayList();

	delete g_hArraySurvivorSets;
	g_hArraySurvivorSets = new ArrayList();

	char sMode[64], sKey[256];
	FindConVar("mp_gamemode").GetString(sMode, sizeof(sMode));
	GetBasedMode(sMode, sizeof(sMode));

	SourceKeyValues kvMissions = SDKCall(g_hSDKCall_GetAllMissions, g_pMatchExtL4D);
	for (SourceKeyValues kvSub = kvMissions.GetFirstTrueSubKey(); !kvSub.IsNull(); kvSub = kvSub.GetNextTrueSubKey())
	{
		char sMissionName[128];
		kvSub.GetName(sMissionName, sizeof(sMissionName));  
		// will be something like this:
		/**
		 * "Missions"
		 * {
		 * 		"<MissionName>"		// the string from: "Name"	"<MissionName>" on the mission file.
		 * 		{
		 * 				...
		 * 		}
		 * }
		*/

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
				char sValue[64];
				kvMapNumber.GetString("Map", sValue, sizeof(sValue));
				hArray.PushString(sValue);
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
				if ((g_hCvar_EnableBlackList.BoolValue && g_hArrayBlackList) && CheckBlackList(sMap))
				{
					i--;	// do not take this into count.
					continue;
				}

				g_hArrayPools.PushString(sMap);
				g_hArraySurvivorSets.Push(survivorSet);
			}
			// the last selection must be the finale.
			else if (i == g_hCvar_MapPoolCapacity.IntValue - 1)
			{
				hArray.GetString(hArray.Length - 1, sMap, sizeof(sMap));
				if ((g_hCvar_EnableBlackList.BoolValue && g_hArrayBlackList) && CheckBlackList(sMap))
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
				// we need at least 2 maps to make a selection. we are in the middle of the pool.
				if (hArray.Length > 2)
				{
					// erase the head and tail.
					hArray.Erase(hArray.Length - 1);
					hArray.Erase(0);

					if (g_hCvar_EnableBlackList.BoolValue && g_hArrayBlackList)
					{
						do
						{
							// all the thing are removed so stop it.
							if (!hArray.Length)
								break;

							// randomlize the array
							hArray.Sort(Sort_Random, Sort_String);
							int random = GetRandomInt(0, hArray.Length - 1);
							hArray.GetString(random, sMap, sizeof(sMap));

							// in case all the array are the hater, we erase it.
							if (CheckBlackList(sMap))
								hArray.Erase(random);
						}
						while (CheckBlackList(sMap));

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
						// randomlize the array
						hArray.Sort(Sort_Random, Sort_String);
						int random = GetRandomInt(0, hArray.Length - 1);
						hArray.GetString(random, sMap, sizeof(sMap));
					}

					g_hArrayPools.PushString(sMap);
					g_hArraySurvivorSets.Push(survivorSet);
				}
				// else we use the first map, and make sure it is not a finale.
				else if (hArray.Length == 2)
				{
					hArray.GetString(0, sMap, sizeof(sMap));
					if ((g_hCvar_EnableBlackList.BoolValue && g_hArrayBlackList) && CheckBlackList(sMap))
					{
						i--;
						continue;
					}

					g_hArrayPools.PushString(sMap);
					g_hArraySurvivorSets.Push(survivorSet);
				}
				// do not take any action, as this can be a finale map.
				else if (hArray.Length == 1)	
				{
					// we need to decrease the index, as we do not push any map into the arraylist.
					i--;
					continue;	// skip this, this is a finale map in the middle of pool.
				}
			}

			delete hArray;
		}

		// earse this one you've made this far for next selection. make sure no same compaign map.
		g_hArrayMissionsAndMaps.Erase(index);

		delete dp;
	}

	delete g_hArrayMissionsAndMaps;
	
	for (int i = 1; i < MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;

		NotifyMapList(i);
	}

	return true;
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

/**
 * -----------------------------
 * Manully select map section.
 * -----------------------------
*/

// menu is BAAAAAAAAAAAAAAAAD.
static int g_iSelectIndex = 0;
static int g_iSelectedSet = 2;
static int g_iParam = -1;
static int g_iClientWhoIsSelecting = -1;

void CollectAllMapsEx(int client, MapSetType type)
{
	if (!CollectMissionsToMenu(type))
		return;

	g_bManullyChoosingMap = true;
	g_iSelectIndex = 0;
	g_iSelectedSet = 2;
	g_iParam = -1;
	g_iClientWhoIsSelecting = client;

	CreateManullySelectMapMenu(client);
}

void CreateManullySelectMapMenu(int client)
{
	DataPack dp = g_hArrayMissionsAndMaps.Get(g_iSelectIndex);
	dp.Reset();

	char sDisplayTitle[128];
	ArrayList hArray = dp.ReadCell();
	StringMap hMap = dp.ReadCell();
	g_iSelectedSet = dp.ReadCell();
	dp.ReadString(sDisplayTitle, sizeof(sDisplayTitle))

	char sBuffer[128];
	Menu menu = new Menu(MenuHandler_ChooseMap);

	FormatEx(sBuffer, sizeof(sBuffer), "%T", "MenuTitle_ChooseFrom", client, sDisplayTitle);
	menu.SetTitle(sBuffer);

	if (!g_iSelectIndex)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%T", "MenuTitle_NextMission", client);
		menu.AddItem("", sBuffer);
	}
	else if (g_iSelectIndex == g_hArrayMissionsAndMaps.Length - 1)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%T", "MenuTitle_LastMission", client);
		menu.AddItem("", sBuffer);
	}
	else if (g_iSelectIndex > 0)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%T", "MenuTitle_LastMission", client);
		menu.AddItem("", sBuffer);

		FormatEx(sBuffer, sizeof(sBuffer), "%T", "MenuTitle_NextMission", client);
		menu.AddItem("", sBuffer);
	}

	// if this is not -1 it means we have selected one map. Erase this selected one.
	if (g_iParam != -1) hArray.Erase(g_iParam);

	for (int i = 0; i < hArray.Length; i++)
	{
		char sMap[64], sDisplayName[64], sCombined[128];
		hArray.GetString(i, sMap, sizeof(sMap));
		hMap.GetString(sMap, sDisplayName, sizeof(sDisplayName));
		Format(sCombined, sizeof(sCombined), "%s - %s", sMap, sDisplayName);
		menu.AddItem(sMap, sCombined);
	}

	// after adding items, immediately set this to -1.
	g_iParam = -1;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

void MenuHandler_ChooseMap(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			// selected "Next Mission" on the first page of all mission.
			if (!g_iSelectIndex && !param2)
			{
				g_iSelectIndex++;
				CreateManullySelectMapMenu(param1);
				return;
			}
			// in the middle page of all missions.
			else if (g_iSelectIndex > 0)
			{
				// selected "Last Mission" on the last page of all mission.
				if (g_iSelectIndex == g_hArrayMissionsAndMaps.Length - 1 && !param2)
				{
					g_iSelectIndex--;
					CreateManullySelectMapMenu(param1);
					return;
				}
				else 
				{
					// selected "Last Mission" on the middle page of all mission.
					if (!param2)
					{
						g_iSelectIndex--;
						CreateManullySelectMapMenu(param1);
						return;
					}
					// selected "Next Mission" on the middle page of all mission.
					else if (param2 == 1 && g_iSelectIndex != g_hArrayMissionsAndMaps.Length - 1)
					{
						g_iSelectIndex++;
						CreateManullySelectMapMenu(param1);
						return;
					}
				}
			}

			// here we did not restrict too much on m1 choosing.
			// since we change map using CDirector::OnChangeChapterVote,
			// we can change to any map if we want.
			// so go select freely.

			// you shouldn't select a finale when you have not reached finale.
			if (g_hArrayPools.Length != g_hCvar_MapPoolCapacity.IntValue - 1 &&
				param2 == menu.ItemCount - 1)
			{
				CPrintToChat(param1, "%t", "CannotSelectUntil");
				CreateManullySelectMapMenu(param1);
				return;
			}

			// here we wish that user always choose the last map as the finale map.
			// so that this could be a consistent compaign. and also have a better gameplay experience.
			if (g_hArrayPools.Length == g_hCvar_MapPoolCapacity.IntValue - 1 
				&& param2 != menu.ItemCount - 1)
			{
				CPrintToChat(param1, "%t", "ShouldSelectLastMap");
				CreateManullySelectMapMenu(param1);
				return;
			}

			char sMap[64];
			menu.GetItem(param2, sMap, sizeof(sMap));

			// @blueblur: the original thought was to make this line where the map name is on the menu
			// appears to be grey and add a word (In blacklist), which is a good way to show the notification.
			// but soon I realized you can't handle this on the menu callback if them choose this grey line,
			// which is a MenuAction_End with a MenuEnd_Selected passed, you can not know if them choose a normal item or a blacklisted item.
			if ((g_hCvar_EnableBlackList.BoolValue && g_hArrayBlackList) && CheckBlackList(sMap))
			{
				CPrintToChat(param1, "%t", "BlackListed");
				CreateManullySelectMapMenu(param1);
				return;
			}

			g_hArrayPools.PushString(sMap);
			g_hArraySurvivorSets.Push(g_iSelectedSet);
			CPrintToChat(param1, "%t", "AddedInto", sMap);

			// save the option we choose to the global varible to earse.
			if (!g_iSelectIndex || g_iSelectIndex == g_hArrayMissionsAndMaps.Length - 1)
				g_iParam = param2 - 1;
			else if (g_iSelectIndex > 0)
				g_iParam = param2 - 2;

			if (g_hArrayPools.Length == g_hCvar_MapPoolCapacity.IntValue)
			{
				CleanMemoryEx();
				CPrintToChat(param1, "%t", "FullSelected", g_hCvar_ManualSelectDelay.IntValue);
				CreateTimer(g_hCvar_ManualSelectDelay.FloatValue, Timer_PreparedToVote, param1);
			}
			else
			{
				CreateManullySelectMapMenu(param1);
			}
		}

		case MenuAction_End:
		{
			switch (param1)
			{
				case MenuEnd_Exit:
				{
					delete menu;
					CleanMemoryEx();
					CPrintToChat(g_iClientWhoIsSelecting, "%t", "AbortedSelection");
					g_bManullyChoosingMap = false;
					g_iClientWhoIsSelecting = -1;
				}

				case MenuEnd_Cancelled:
				{
					switch (param2)
					{
						case MenuCancel_Disconnected, MenuCancel_Exit, MenuCancel_NoDisplay:
						{
							delete menu;
							CleanMemoryEx();

							if (IsClientInGame(g_iClientWhoIsSelecting))
								CPrintToChat(g_iClientWhoIsSelecting, "%t", "AbortedSelection");

							g_bManullyChoosingMap = false;
							g_iClientWhoIsSelecting = -1;
						}
					}
				}

				case MenuEnd_Selected:
					delete menu;
				
				case MenuEnd_ExitBack:
				{
					delete menu;
					CleanMemoryEx();
					CPrintToChat(g_iClientWhoIsSelecting, "%t", "AbortedSelection");
					ManullySelectMap_ChooseMapSetType(g_iClientWhoIsSelecting);
					g_bManullyChoosingMap = false;
					g_iClientWhoIsSelecting = -1;
				}
			}
		}

		case MenuAction_Cancel:
		{
			// cannot delete the menu here, it is just being taken over with another contents, not really ends,
			// otherwise server crashes.
			// as what it says this is just a cancel.
			if (param2 == MenuCancel_Interrupted)
			{
				CleanMemoryEx();
				CPrintToChat(g_iClientWhoIsSelecting, "%t", "AbortedSelection");
				g_bManullyChoosingMap = false;
				g_iClientWhoIsSelecting = -1;
			}
		}
	}
}

void Timer_PreparedToVote(Handle timer, int client)
{
	g_bManullyChoosingMap = false;
	g_iClientWhoIsSelecting = -1;
	CreateMixmapVote(client, MapSet_Manual);
}

void CleanMemoryEx()
{
	if (g_hArrayMissionsAndMaps && g_hArrayMissionsAndMaps.Length)
	{
		for (int i = 0; i < g_hArrayMissionsAndMaps.Length; i++)
		{
			DataPack dp = g_hArrayMissionsAndMaps.Get(i);
			dp.Reset();

			ArrayList hArray = dp.ReadCell();
			StringMap hMap = dp.ReadCell();

			delete hArray;
			delete hMap;
			delete dp;
		}
	}
}

bool CollectMissionsToMenu(MapSetType type)
{
	delete g_hArrayPools;
	g_hArrayPools = new ArrayList(ByteCountToCells(64));

	delete g_hArrayMissionsAndMaps;
	g_hArrayMissionsAndMaps = new ArrayList();

	delete g_hArraySurvivorSets;
	g_hArraySurvivorSets = new ArrayList();

	char sMode[64];
	FindConVar("mp_gamemode").GetString(sMode, sizeof(sMode));
	GetBasedMode(sMode, sizeof(sMode));	// note that this plugin won't consider survival/versus survival.

	SourceKeyValues kvAllMissions = SDKCall(g_hSDKCall_GetAllMissions, g_pMatchExtL4D);
	for (SourceKeyValues kvSub = kvAllMissions.GetFirstTrueSubKey(); !kvSub.IsNull(); kvSub = kvSub.GetNextTrueSubKey())
	{
		if (kvSub.IsNull())
			continue;

		char sMissionName[128];
		kvSub.GetName(sMissionName, sizeof(sMissionName));  

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

		char sDisplayTitle[128];
		kvSub.GetString("DisplayTitle", sDisplayTitle, sizeof(sDisplayTitle));

		char sKey[64];
		FormatEx(sKey, sizeof(sKey), "modes/%s", sMode);
		SourceKeyValues kvMode = kvSub.FindKey(sKey);

		if (kvMode.IsNull())
			continue;

		ArrayList hArray = new ArrayList(ByteCountToCells(64));
		StringMap hMap = new StringMap();
		for (SourceKeyValues kvMapNumber = kvMode.GetFirstTrueSubKey(); !kvMapNumber.IsNull(); kvMapNumber = kvMapNumber.GetNextTrueSubKey())
		{
			char sValue[64], sDisplayName[64];
			kvMapNumber.GetString("Map", sValue, sizeof(sValue));
			kvMapNumber.GetString("DisplayName", sDisplayName, sizeof(sDisplayName));
			hMap.SetString(sValue, sDisplayName);
			hArray.PushString(sValue);
		}

		DataPack dp = new DataPack();
		dp.WriteCell(hArray);
		dp.WriteCell(hMap);
		dp.WriteCell(survivorSet);
		dp.WriteString(sDisplayTitle);
		g_hArrayMissionsAndMaps.Push(dp);
	}

	if (!g_hArrayMissionsAndMaps || !g_hArrayMissionsAndMaps.Length)
		return false;

	if (g_hArrayMissionsAndMaps.Length < g_hCvar_MapPoolCapacity.IntValue)
	{
		CPrintToChatAll("%t", "NotEnoughMaps");
		CleanMemoryEx();
		return false;
	}

	return true;
}
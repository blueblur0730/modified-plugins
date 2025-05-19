#if defined _l4d2_mixmap_actions_included
	#endinput
#endif
#define _l4d2_mixmap_actions_included

void InitiateMixmap(MapSetType type)
{
	switch (type)
	{
		case MapSet_Official, MapSet_Custom, MapSet_Mixtape:
		{
			CollectAllMaps(type);
			if (!SelectRandomMap())
			{
				CPrintToChatAll("%t", "FailedToGet");
				g_bMapsetInitialized = false;
				return;
			}

			g_iMapsetType = type;
			CPrintToChatAll("%t", "StartingIn", g_hCvar_SecondsToRead.IntValue);
			CreateTimer(g_hCvar_SecondsToRead.FloatValue, Timer_StartFirstMissionMixmap);
		}

		case MapSet_Manual, MapSet_Preset:
		{
			g_iMapsetType = type;
			CPrintToChatAll("%t", "StartingIn", g_hCvar_SecondsToRead.IntValue);
			CreateTimer(g_hCvar_SecondsToRead.FloatValue, Timer_StartFirstMapMixmap);
		}
	}
}

// OnChangeMissionVote needs mission name.
void Timer_StartFirstMissionMixmap(Handle timer)
{
	char sMap[128], sMissionName[128];
	g_hArrayPools.GetString(0, sMap, sizeof(sMap));
	g_hMapChapterNames.GetString(sMap, sMissionName, sizeof(sMissionName));

#if REQUIRE_LOG4SP
	g_hLogger.InfoEx("### Starting Mixmap with %s", sMissionName);
#else
	g_hLogger.info("### Starting Mixmap with %s", sMissionName);
#endif
	

	g_bMapsetInitialized = true;
	Call_StartForward(g_hForwardStart);
	Call_PushCell(g_hArrayPools.Length);
	Call_PushCell(g_iMapsetType);
	Call_PushString("");
	Call_Finish();

	TheDirector.OnChangeMissionVote(sMissionName);
}

void Timer_StartFirstMapMixmap(Handle timer)
{
	char sMap[128];
	g_hArrayPools.GetString(0, sMap, sizeof(sMap));

#if REQUIRE_LOG4SP
	g_hLogger.InfoEx("### Starting Mixmap with %s", sMap);
#else
	g_hLogger.info("### Starting Mixmap with %s", sMap);
#endif
	
	g_bMapsetInitialized = true;
	Call_StartForward(g_hForwardStart);
	Call_PushCell(g_hArrayPools.Length);
	Call_PushCell(g_iMapsetType);
	Call_PushString(g_sPresetName);
	Call_Finish();

	TheDirector.OnChangeChapterVote(sMap);
}

void Timer_Notify(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (client <= 0 || client > MaxClients)
		return;

	if (!IsClientInGame(client))
		return;

	NotifyMixmap(client);
}

void Timer_ShowMaplist(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (client <= 0 || client > MaxClients)
		return;

	if (!IsClientInGame(client))
		return;

	NotifyMapList(client);
}

void NotifyMixmap(int client)
{
	char sCurrentMap[64], sNextMap[64];
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));

	if (g_iMapsPlayed >= g_hArrayPools.Length)
		Format(sNextMap, sizeof(sNextMap), "%T", "None", client);
	else
		g_hArrayPools.GetString(g_iMapsPlayed, sNextMap, sizeof(sNextMap));

	CPrintToChat(client, "%t", "MapProgress", sCurrentMap, sNextMap);

	if (g_iMapsPlayed == g_hArrayPools.Length)
		CPrintToChat(client, "%t", "HaveReachedTheEnd");
}

void NotifyMapList(int client)
{
	if (g_hArrayPools.Length > 6)
		CPrintToChat(client, "%t", "SeeConsole");

	g_hArrayPools.Length > 6 ?	  // we have a small chat right?
	PrintToConsole(client, "%t", "MapList_NoColor") : 
	CPrintToChat(client, "%t", "MapList");

	char sBuffer[64], sCurrentMap[64], sCurrent[32];
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
	Format(sCurrent, sizeof(sCurrent), "%T", "Current", client);
	for (int i = 0; i < g_hArrayPools.Length; i++)
	{
		g_hArrayPools.GetString(i, sBuffer, sizeof(sBuffer));
		g_hArrayPools.Length > 6 ? PrintToConsole(client, "-> %s %s", sBuffer, (!strcmp(sCurrentMap, sBuffer) && g_iMapsPlayed == i + 1) ? sCurrent : "") : CPrintToChat(client, "{green}-> {olive}%s{default} {orange}%s{default}", sBuffer, (!strcmp(sCurrentMap, sBuffer) && g_iMapsPlayed == i + 1) ? sCurrent : "");
	}
}

// bye bye sourcemod keyvalues.
// @blueblur: not going to check whether the map name is valid or not, since this array is not the one to be used to change map.
void BuildBlackList(int client)
{
	char sPath[128];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_BLACKLIST);

	SourceKeyValues kv = SourceKeyValues("BlackList");
	if (kv.LoadFromFile(sPath))
	{
		delete g_hArrayBlackList;
		g_hArrayBlackList = new ArrayList(ByteCountToCells(64));

		char			sMap[64];
		int				count = 0;
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
#if REQUIRE_LOG4SP
					g_hLogger.WarnEx("Reached limit of %d blacklisted maps. Abort the rest.", g_hCvar_BlackListLimit.IntValue);
#else
					g_hLogger.warning("Reached limit of %d blacklisted maps. Abort the rest.", g_hCvar_BlackListLimit.IntValue);
#endif

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
#if REQUIRE_LOG4SP
					g_hLogger.WarnEx("Reached limit of %d blacklisted maps. Abort the rest.", g_hCvar_BlackListLimit.IntValue);
#else
					g_hLogger.warning("Reached limit of %d blacklisted maps. Abort the rest.", g_hCvar_BlackListLimit.IntValue);
#endif
					if (client != -1 && client > 0 && client <= MaxClients)
						CPrintToChat(client, "%t", "BlackListLoaded");

					return;
				}
			}
		}

		if (!g_hArrayBlackList || !g_hArrayBlackList.Length)
		{
			kv.deleteThis();
#if REQUIRE_LOG4SP
			g_hLogger.ErrorEx("No keys found in \""... CONFIG_BLACKLIST..."\" on node %s and global filter.", sMode);
#else
			g_hLogger.error("No keys found in \""... CONFIG_BLACKLIST..."\" on node %s and global filter.", sMode);
#endif

			if (client != -1 && client > 0 && client <= MaxClients)
				CPrintToChat(client, "%t", "NoKeysFoundInBlackList");

			return;
		}
	}
	else
	{
		kv.deleteThis();
#if REQUIRE_LOG4SP
		g_hLogger.Error("Failed to load black list file from \""... CONFIG_BLACKLIST..."\".");
#else
		g_hLogger.error("Failed to load black list file from \""... CONFIG_BLACKLIST..."\".");
#endif

		if (client != -1 && client > 0 && client <= MaxClients)
			CPrintToChat(client, "%t", "FailedToLoadBlackList");

		return;
	}

	if (client != -1 && client > 0 && client <= MaxClients)
		CPrintToChat(client, "%t", "BlackListLoaded");

	kv.deleteThis();
}

void LoadFolderFiles(int client)
{
	delete g_hArrayPresetList;
	g_hArrayPresetList = new ArrayList(ByteCountToCells(512));

	delete g_hArrayPresetNames;
	g_hArrayPresetNames = new ArrayList(ByteCountToCells(512));

	char sPath[128];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_PRESET_FOLDER);

	DirectoryListing hDir = OpenDirectory(sPath);

	// no directory found.
	if (!hDir)
	{
		if (client != -1 && client > 0 && client <= MaxClients)
			CPrintToChat(client, "%t", "NoPresetFolderFound");

		delete g_hArrayPresetNames;
		delete g_hArrayPresetList;
#if REQUIRE_LOG4SP
		g_hLogger.ErrorEx("Failed to open directory \"%s\".", sPath);
#else
		g_hLogger.error("Failed to open directory \"%s\".", sPath);
#endif
		return;
	}

	FileType type;
	char	 sFile[128];
	while (hDir.GetNext(sFile, sizeof(sFile), type))
	{
		if (StrEqual(sFile, ".") || StrEqual(sFile, ".."))
			continue;

		if (type != FileType_File)
			continue;

		char sFilePath[128];
		Format(sFilePath, sizeof(sFilePath), "%s/%s", sPath, sFile);

		SourceKeyValues kv = SourceKeyValues("Presets");
		if (!kv.LoadFromFile(sFilePath))
		{
			kv.deleteThis();
#if REQUIRE_LOG4SP
			g_hLogger.ErrorEx("Failed to load preset file: \"%s\"", sFilePath);
#else
			g_hLogger.error("Failed to load preset file: \"%s\"", sFilePath);
#endif
			continue;
		}

		g_hArrayPresetList.PushString(sFilePath);

		char sPresetName[512];
		kv.GetString("presetName", sPresetName, sizeof(sPresetName), "untitled_preset");
		g_hArrayPresetNames.PushString(sPresetName);
		kv.deleteThis();
	}

	if (client != -1 && client > 0 && client <= MaxClients)
		CPrintToChat(client, "%t", "PresetFileReLoaded");

	delete hDir;
}

void LoadPreset(const char[] sFile, int client)
{
	delete g_hArrayPools;
	g_hArrayPools = new ArrayList(ByteCountToCells(128));

	delete g_hArraySurvivorSets;
	g_hArraySurvivorSets = new ArrayList();

	SourceKeyValues kv	 = SourceKeyValues("Presets");
	if (!kv.LoadFromFile(sFile))
	{
		kv.deleteThis();
		delete g_hArrayPools;
		delete g_hArraySurvivorSets;
#if REQUIRE_LOG4SP
		g_hLogger.ErrorEx("Failed to load preset file: \"%s\"", sFile);
#else
		g_hLogger.error("Failed to load preset file: \"%s\"", sFile);
#endif
		CPrintToChat(client, "%t", "PresetFileLoadFailed");
		return;
	}

	kv.GetString("presetName", g_sPresetName, sizeof(g_sPresetName), "untitled_preset");

	int				iUseBased  = kv.GetInt("useBased", 1);
	SourceKeyValues kvGameMode = kv.FindKey("gamemode");

	if (!kvGameMode || kvGameMode.IsNull())
	{
		kv.deleteThis();
		delete g_hArrayPools;
		delete g_hArraySurvivorSets;
#if REQUIRE_LOG4SP
		g_hLogger.ErrorEx("Failed to find subkey \"gamemode\" in preset file: \"%s\"", sFile);
#else
		g_hLogger.error("Failed to find subkey \"gamemode\" in preset file: \"%s\"", sFile);
#endif
		CPrintToChat(client, "%t", "PresetFileLoadFailed");
		return;
	}

	char sMode[32];
	FindConVar("mp_gamemode").GetString(sMode, sizeof(sMode));

	bool bFound = false;
	if (iUseBased)
		GetBasedMode(sMode, sizeof(sMode));

	for (SourceKeyValues kvSub = kvGameMode.GetFirstValue(); !kvSub.IsNull(); kvSub = kvGameMode.GetNextValue())
	{
		char sBuffer[32];
		kvSub.GetString(NULL_STRING, sBuffer, sizeof(sBuffer));
		if (!strcmp(sMode, sBuffer))
		{
			bFound = true;
			break;
		}
	}

	if (!bFound)
	{
		kv.deleteThis();
		delete g_hArrayPools;
		delete g_hArraySurvivorSets;
#if REQUIRE_LOG4SP
		g_hLogger.ErrorEx("Failed to find gamemode \"%s\" in preset file: \"%s\", useBased: \"%d\"", sMode, sFile, iUseBased);
#else
		g_hLogger.error("Failed to find gamemode \"%s\" in preset file: \"%s\", useBased: \"%d\"", sMode, sFile, iUseBased);
#endif
		CPrintToChat(client, "%t", "PresetFileLoadFailed_GameModeNotMatched");
		return;
	}

	SourceKeyValues kvMapPool = kv.FindKey("MapPool");
	if (!kvMapPool || kvMapPool.IsNull())
	{
		kv.deleteThis();
		delete g_hArrayPools;
		delete g_hArraySurvivorSets;
#if REQUIRE_LOG4SP
		g_hLogger.ErrorEx("Failed to find subkey \"MapPool\" in preset file: \"%s\"", sFile);
#else
		g_hLogger.error("Failed to find subkey \"MapPool\" in preset file: \"%s\"", sFile);
#endif
		CPrintToChat(client, "%t", "PresetFileLoadFailed");
		return;
	}

	for (SourceKeyValues kvSub = kvMapPool.GetFirstValue(); !kvSub.IsNull(); kvSub = kvSub.GetNextValue())
	{
		char sBuffer[64];
		kvSub.GetString(NULL_STRING, sBuffer, sizeof(sBuffer));

		// check blacklist.
		if (g_hCvar_EnableBlackList.BoolValue && g_hArrayBlackList && g_hArrayBlackList.Length)
		{
			if (CheckBlackList(sBuffer))
			{
#if REQUIRE_LOG4SP
				g_hLogger.InfoEx("Found map \"%s\" in blacklist.", sBuffer);
#else
				g_hLogger.info("Found map \"%s\" in blacklist.", sBuffer);
#endif
				continue;
			}
		}

		// erase the invalid map name.
		SourceKeyValues kvMissionInfo;
		SourceKeyValues kvMapInfo = TheMatchExt.GetMapInfoByBspName(sBuffer, sMode, view_as<Address>(kvMissionInfo));
		if (!kvMapInfo || kvMapInfo.IsNull())
		{
#if REQUIRE_LOG4SP
			g_hLogger.WarnEx("Failed to find map \"%s\" in gamemode \"%s\".", sBuffer, sMode);
#else
			g_hLogger.warning("Failed to find map \"%s\" in gamemode \"%s\".", sBuffer, sMode);
#endif
			continue;
		}

		if (!kvMissionInfo || kvMissionInfo.IsNull())
		{
#if REQUIRE_LOG4SP
			g_hLogger.WarnEx("Failed to find mission info for map \"%s\" in gamemode \"%s\". kvMissionInfo: %d", sBuffer, sMode, kvMissionInfo);
#else
			g_hLogger.warning("Failed to find mission info for map \"%s\" in gamemode \"%s\". kvMissionInfo: %d", sBuffer, sMode, kvMissionInfo);
#endif
			continue;
		}

		g_hArraySurvivorSets.Push(kvMissionInfo.GetInt("survivor_set", 2));
		g_hArrayPools.PushString(sBuffer);
	}

	// ignore the map pool capacity cvar.
	if (!g_hArrayPools.Length)
	{
		kv.deleteThis();
		delete g_hArrayPools;
		delete g_hArraySurvivorSets;
#if REQUIRE_LOG4SP
		g_hLogger.ErrorEx("Preset file \"%s\" is empty because all map name is invalid.", sFile);
#else
		g_hLogger.error("Preset file \"%s\" is empty because all map name is invalid.", sFile);
#endif
		CPrintToChat(client, "%t", "PresetFileLoadFailed");
		return;
	}

	CPrintToChat(client, "%t", "PresetFileLoaded", g_sPresetName, g_hCvar_PresetLoadDelay.IntValue);
	CreateTimer(g_hCvar_PresetLoadDelay.FloatValue, Timer_LoadPresetFile, client);
	kv.deleteThis();
}

void Timer_LoadPresetFile(Handle hTimer, int client)
{
	CreateMixmapVote(client, MapSet_Preset);
}

void PluginStartInit()
{
	g_bMapsetInitialized = false;
	g_iMapsPlayed		 = 0;
	g_iMapsetType		 = MapSet_None;
	delete g_hArrayPools;
	delete g_hMapChapterNames;
	delete g_hArraySurvivorSets;

	StoreToAddress(g_bNeedRestore, 1, NumberType_Int8);
}
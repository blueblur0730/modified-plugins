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
	g_hLogger.InfoEx("### Starting Mixmap with %s", sMissionName);
	
	g_bMapsetInitialized = true;
	Call_StartForward(g_hForwardStart);
	Call_PushCell(g_hArrayPools.Length);
	Call_PushCell(g_iMapsetType);
	Call_PushString("");
	Call_Finish();

	SDKCall(g_hSDKCall_OnChangeMissionVote, g_pTheDirector, sMissionName);
}

void Timer_StartFirstMapMixmap(Handle timer)
{
	char sMap[128];
	g_hArrayPools.GetString(0, sMap, sizeof(sMap));
	g_hLogger.InfoEx("### Starting Mixmap with %s", sMap);
	
	g_bMapsetInitialized = true;
	Call_StartForward(g_hForwardStart);
	Call_PushCell(g_hArrayPools.Length);
	Call_PushCell(g_iMapsetType);
	Call_PushString(g_sPresetName);
	Call_Finish();

	SDKCall(g_hSDKCall_OnChangeChapterVote, g_pTheDirector, sMap);
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

	g_hArrayPools.Length > 6 ?	// we have a small chat right?
	PrintToConsole(client, "%t", "MapList_NoColor") :
	CPrintToChat(client, "%t", "MapList");
	
	char sBuffer[64], sCurrentMap[64], sCurrent[32];
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
	Format(sCurrent, sizeof(sCurrent), "%T", "Current", client);
	for (int i = 0; i < g_hArrayPools.Length; i++)
	{
		g_hArrayPools.GetString(i, sBuffer, sizeof(sBuffer));
		g_hArrayPools.Length > 6 ?
		PrintToConsole(client, "-> %s %s", sBuffer, (!strcmp(sCurrentMap, sBuffer) && g_iMapsPlayed == i + 1) ? sCurrent : "") :
		CPrintToChat(client, "{green}-> {olive}%s{default} {orange}%s{default}", sBuffer, (!strcmp(sCurrentMap, sBuffer) && g_iMapsPlayed == i + 1) ? sCurrent : "");
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
		g_hLogger.ErrorEx("Failed to open directory \"%s\".", sPath);
		return; 
	}

	FileType type;
	char sFile[128];
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
			g_hLogger.ErrorEx("Failed to load preset file: \"%s\"", sFilePath);
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

	SourceKeyValues kv = SourceKeyValues("Presets");
	if (!kv.LoadFromFile(sFile))
	{
		kv.deleteThis();
		delete g_hArrayPools;
		g_hLogger.ErrorEx("Failed to load preset file: \"%s\"", sFile);
		CPrintToChat(client, "%t", "PresetFileLoadFailed");
		return;
	}

	kv.GetString("presetName", g_sPresetName, sizeof(g_sPresetName), "untitled_preset");

	int iUseBased = kv.GetInt("useBased", 1);
	SourceKeyValues kvGameMode = kv.FindKey("gamemode");

	if (!kvGameMode || kvGameMode.IsNull())
	{
		kv.deleteThis();
		delete g_hArrayPools;
		g_hLogger.ErrorEx("Failed to find subkey \"gamemode\" in preset file: \"%s\"", sFile);
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
		g_hLogger.ErrorEx("Failed to find matched gamemode \"%s\" in preset file: \"%s\", useBased: \"%d\"", sMode, sFile, iUseBased);
		CPrintToChat(client, "%t", "PresetFileLoadFailed_GameModeNotMatched");
		return;
	}

	SourceKeyValues kvMapPool = kv.FindKey("MapPool");
	if (!kvMapPool || kvMapPool.IsNull())
	{
		kv.deleteThis();
		delete g_hArrayPools;
		g_hLogger.ErrorEx("Failed to find subkey \"MapPool\" in preset file: \"%s\"", sFile);
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
				continue;
		}

		// erase the invalid map name.
		bool bMatched = false;
		GetBasedMode(sMode, sizeof(sMode));
		SourceKeyValues kvMissions = SDKCall(g_hSDKCall_GetAllMissions, g_pMatchExtL4D);
		for (SourceKeyValues kvMissionSub = kvMissions.GetFirstTrueSubKey(); !kvMissionSub.IsNull(); kvMissionSub = kvMissionSub.GetNextTrueSubKey())
		{
			if (bMatched)
				break;

			char sMissionName[128];
			kvMissionSub.GetName(sMissionName, sizeof(sMissionName)); 

			if (IsFakeMission(sMissionName))
				continue;

			char sKey[64];
			FormatEx(sKey, sizeof(sKey), "modes/%s", sMode);
			SourceKeyValues kvMode = kvMissionSub.FindKey(sKey);

			if (!kvMode || kvMode.IsNull())
				continue;
				
			int survivorSet = kvSub.GetInt("survivor_set", 2);	// L4D2 = 2, L4D1 = 1

			for (SourceKeyValues kvMapNumber = kvMode.GetFirstTrueSubKey(); !kvMapNumber.IsNull(); kvMapNumber = kvMapNumber.GetNextTrueSubKey())
			{
				char sValue[64];
				kvMapNumber.GetString("Map", sValue, sizeof(sValue));

				if (!strcmp(sValue, sBuffer))
				{
					g_hArraySurvivorSets.Push(survivorSet);
					bMatched = true;
					break;
				}
			}
		}

		if (bMatched)
			g_hArrayPools.PushString(sBuffer);
		else
			g_hLogger.WarnEx("Failed to find matched map \"%s\" in gamemode \"%s\".", sBuffer, sMode);
	}

	// ignore the map pool capacity cvar.
	if (!g_hArrayPools.Length)
	{
		kv.deleteThis();
		delete g_hArrayPools;
		g_hLogger.ErrorEx("Preset file \"%s\" is empty because all map name is invalid.", sFile);
		CPrintToChat(client, "%t", "PresetFileLoadFailed");
		delete g_hArrayPools;
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

void Patch(bool bPatch)
{
	static bool bPatched = false;
	if (bPatch && !bPatched)
	{
		g_hPatch_BlockRestoring.Enable();
		bPatched = true;
	}
	else if (!bPatch && bPatched)
	{
		g_hPatch_BlockRestoring.Disable();
		bPatched = false;
	}
}

void PluginStartInit()
{
	g_bMapsetInitialized = false;
	g_iMapsPlayed		 = 0;
	g_iMapsetType        = MapSet_None;
	delete g_hArrayPools;
	delete g_hMapChapterNames;
	delete g_hArraySurvivorSets;

	StoreToAddress(g_bNeedRestore, 1, NumberType_Int8);
}


void ParseMenuModels()
{
    char sBuffer[PLATFORM_MAX_PATH]
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), CFG_MENU);

	g_kvList = new KeyValues("Commands");
	g_kvList.ImportFromFile(sBuffer);

	if (!g_kvList.GotoFirstSubKey()) 
		return;

	do
	{
		bool bVModel = false;
		bVModel = view_as<bool>(g_kvList.GetNum("vmodel", 0));

		g_kvList.JumpToKey("List");
		g_kvList.GotoFirstSubKey();

		do
		{
			g_kvList.GetString("path", sBuffer, sizeof(sBuffer));
			if (PrecacheModel(sBuffer, true)) 
				g_iTotalSkins++;

			if (!bVModel)
			{
				g_kvList.GetString("turned", sBuffer, sizeof(sBuffer), "");
				//PrintToServer("Precaching turned model: %s", sBuffer);
				if (sBuffer[0] != '\0' && PrecacheModel(sBuffer, true))
					g_iTurnedSkins++;
			}
		}
		while (g_kvList.GotoNextKey());

		g_kvList.GoBack();
		g_kvList.GoBack();
	}
	while (g_kvList.GotoNextKey());

    g_kvList.Rewind();
}

void ParseDownloadList()
{
	if (g_bCVar[CV_Enable])
	{
        char sBuffer[PLATFORM_MAX_PATH];
		char path[PLATFORM_MAX_PATH], tmp_path[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, sBuffer, sizeof(sBuffer), CFG_DL);

		File hFile = OpenFile(sBuffer, "r");
		if (!hFile)
		{
			LogError("Can't open file '%s'.", sBuffer);
			return;
		}

		g_bDLType = true;
		DirectoryListing hDir;
		FileType type;

        int len;
		while (hFile.ReadLine(path, sizeof(path)))
		{
			len = strlen(path);
			if (path[len - 1] == '\n') 
				path[--len] = 0;

			TrimString(path);

			if (IsEndOfFile(hFile)) 
				break;

			if (!path[0]) 
				continue;

			if (DirExists(path))
			{
				hDir = OpenDirectory(path);
				if (!hDir)
				{
					LogError("Can't open directory '%s'.", path);
					continue;
				}

				while (hDir.GetNext(sBuffer, sizeof(sBuffer), type))
				{
					len = strlen(sBuffer);
					if (sBuffer[len - 1] == '\n') 
						sBuffer[--len] = 0;

					TrimString(sBuffer);

					if (!StrEqual(sBuffer, "", false) && !StrEqual(sBuffer, ".", false) && !StrEqual(sBuffer, "..", false))
					{
						strcopy(tmp_path, sizeof(tmp_path), path);
						StrCat(tmp_path, sizeof(tmp_path), "/");
						StrCat(tmp_path, sizeof(tmp_path), sBuffer);

						if (type == FileType_File && g_bDLType) 
							ReadItem(tmp_path);
					}
				}
			}
			else if (g_bDLType) 
			{
				ReadItem(path);
			}

			if (hDir) 
				delete hDir;
		}

		if (hFile) 
			delete hFile;
	}
}

void ReadItem(char[] sBuffer)
{
	int len = strlen(sBuffer);
	if (sBuffer[len - 1] == '\n') 
		sBuffer[--len] = 0;

	TrimString(sBuffer);

	if (len > 1 && sBuffer[0] == '/' && sBuffer[1] == '/')
	{
		if (StrContains(sBuffer, "//") > -1) 
			ReplaceString(sBuffer, 255, "//", "");
	}
	else if (sBuffer[0]/* && FileExists(sBuffer)*/) 
	{
		AddFileToDownloadsTable(sBuffer);
	}
}
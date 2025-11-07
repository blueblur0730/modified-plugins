

void ParseMenuModels()
{
    char sBuffer[PLATFORM_MAX_PATH]
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), CFG_MENU);

	KeyValues kvList = new KeyValues("Models");
	kvList.ImportFromFile(sBuffer);

	if (!kvList.GotoFirstSubKey()) 
		return;

	do
	{
		bool bVModel = false;
		bVModel = view_as<bool>(kvList.GetNum("vmodel", 0));

		kvList.JumpToKey("List");
		kvList.GotoFirstSubKey();

		do
		{
			kvList.GetString("path", sBuffer, sizeof(sBuffer));
			if (PrecacheModel(sBuffer, true)) 
				g_iTotalSkins++;

			if (!bVModel)
			{
				kvList.GetString("turned", sBuffer, sizeof(sBuffer), "");
				//PrintToServer("Precaching turned model: %s", sBuffer);
				if (sBuffer[0] != '\0' && PrecacheModel(sBuffer, true))
					g_iTurnedSkins++;
			}
		}
		while (kvList.GotoNextKey());

		kvList.GoBack();
		kvList.GoBack();
	}
	while (kvList.GotoNextKey());

    delete kvList;
}

void ParseMainSection(Menu menu, AdminId admin, int client, int& items)
{
	char sBuffer[30], accessFlag[12];
	bool bDefault = false;
	bDefault = view_as<bool>(g_kvList[client].GetNum("default", 0));

	bool bAdminGroup = false;
	bool bAdminAccess = false;

	if (!bDefault)
	{
		if (g_bCVar[CV_Group])
		{	
			// check if they have access
			char group[30], temp[2];
			g_kvList[client].GetString("AdminGroup", group, sizeof(group));
			GroupId id = FindAdmGroup(group);

			if (id == INVALID_GROUP_ID || group[0] == '\0')
			{
				bAdminGroup = true;
			}
			else
			{
				int count;
				count = GetAdminGroupCount(admin);

				for (int i; i < count; i++) 
				{
					if (id == GetAdminGroup(admin, i, temp, sizeof(temp)))
					{
						bAdminGroup = true;
						break;
					}
				}
			}
		}

		g_kvList[client].GetString("AdminFlag", accessFlag, sizeof(accessFlag));
		if (accessFlag[0] == '\0' || !accessFlag[0])
		{
			bAdminAccess = true;
		}
		else
		{
			for (int i = 0; i < sizeof(accessFlag); i++)
			{
				if (CheckFlagAccess(client, accessFlag[i]))
				{
					bAdminAccess = true;
					break;
				}
			}
		}
	}

	if (!bDefault)
	{
		if (!bAdminGroup || !bAdminAccess)
			return;
	}

	char sPhrase[PLATFORM_MAX_PATH];
	g_kvList[client].GetString("SectionPhrase", sPhrase, sizeof(sPhrase));
	if (TranslationPhraseExists(sPhrase) && IsTranslatedForLanguage(sPhrase, GetClientLanguage(client)))
	{
		g_kvList[client].GetSectionName(sBuffer, sizeof(sBuffer));
		Format(sPhrase, sizeof(sPhrase), "%T", sPhrase, client);
		menu.AddItem(sBuffer, sPhrase);
	}
	else
	{
		g_kvList[client].GetSectionName(sBuffer, sizeof(sBuffer));
		menu.AddItem(sBuffer, sBuffer);
	}

	items++;
}

bool ParseBodyGroupName(const char[] sSection, char[] buffer, int maxlength, int client)
{
	char sBuffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), CFG_MENU_BODYGROUP);

	KeyValues kvList = new KeyValues("bodygroups");
	if (!kvList.ImportFromFile(sBuffer))
	{
		delete kvList;
		return false;
	}

	char sSectionStripped[256];
	strcopy(sSectionStripped, sizeof(sSectionStripped), sSection);
	StripSpaces(sSectionStripped, sizeof(sSectionStripped));

	char sLabelStripped[256];
	strcopy(sLabelStripped, sizeof(sLabelStripped), g_sWModelLabel[client]);
	StripSpaces(sLabelStripped, sizeof(sLabelStripped));

	Format(sBuffer, sizeof(sBuffer), "%s/%s", sLabelStripped, sSectionStripped);
	if (!kvList.JumpToKey(sBuffer))
	{
		delete kvList;
		return false;
	}

	char sPhrase[64];
	kvList.GetString("phrase", sPhrase, sizeof(sPhrase));
	if (sPhrase[0] != '\0' && TranslationPhraseExists(sPhrase) && IsTranslatedForLanguage(sPhrase, GetClientLanguage(client)))
	{
		Format(buffer, maxlength, "%T", sPhrase, client);
	}
	else
	{
		Format(buffer, maxlength, "%s", sSection);
	}

	delete kvList;
	return true;
}

bool ParseBodyPartName(const char[] sBodyPart, char[] buffer, int maxlength, int client, const char[] sBodyGroup)
{
	char sBuffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), CFG_MENU_BODYGROUP);

	KeyValues kvList = new KeyValues("bodygroups");
	if (!kvList.ImportFromFile(sBuffer))
	{
		delete kvList;
		return false;
	}

	char sSectionStripped[256];
	strcopy(sSectionStripped, sizeof(sSectionStripped), sBodyGroup);
	StripSpaces(sSectionStripped, sizeof(sSectionStripped));

	char sLabelStripped[256];
	strcopy(sLabelStripped, sizeof(sLabelStripped), g_sWModelLabel[client]);
	StripSpaces(sLabelStripped, sizeof(sLabelStripped));

	Format(sBuffer, sizeof(sBuffer), "%s/%s/bodypart", sLabelStripped, sSectionStripped);
	if (!kvList.JumpToKey(sBuffer))
	{
		delete kvList;
		return false;
	}

	/**
		$bodygroup "cape"
		{
			studio "cape.smd"
			blank
		}
	*/
	char sPhrase[64];
	if (sBodyPart[0] == '\0')
	{
		kvList.GetString("blank", sPhrase, sizeof(sPhrase));
	}
	else
	{
		kvList.GetString(sBodyPart, sPhrase, sizeof(sPhrase));
	}

	if (sPhrase[0] != '\0' && TranslationPhraseExists(sPhrase) && IsTranslatedForLanguage(sPhrase, GetClientLanguage(client)))
	{
		Format(buffer, maxlength, "%T", sPhrase, client);
	}
	else
	{
		Format(buffer, maxlength, "%s", sBodyGroup);
	}

	delete kvList;
	return true;
}

stock void StripSpaces(char[] str, int maxlen)
{
    int read = 0, write = 0;
    int len = strlen(str);

    if (len <= 0) 
		return;

    if (len > maxlen - 1) 
		len = maxlen - 1;

    for (read = 0; read < len; read++)
    {
        char c = str[read];
        if (c != ' ')
        {
            str[write++] = c;
        }
    }

    str[write] = '\0';
}
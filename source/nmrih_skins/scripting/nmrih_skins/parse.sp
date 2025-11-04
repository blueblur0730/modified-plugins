

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

void ParseAdminAccess(Menu menu, AdminId admin, int client, int& items)
{
	static char sBuffer[30], accessFlag[12];
	static bool bDefault = false;
	bDefault = view_as<bool>(g_kvList.GetNum("default", 0));

	static bool bAdminGroup = false;
	static bool bAdminAccess = false;

	if (!bDefault)
	{
		if (g_bCVar[CV_Group])
		{	
			// check if they have access
			static char group[30], temp[2];
			g_kvList.GetString("AdminGroup", group, sizeof(group));
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

		g_kvList.GetString("AdminFlag", accessFlag, sizeof(accessFlag));
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

	g_kvList.GetSectionName(sBuffer, sizeof(sBuffer));
	menu.AddItem(sBuffer, sBuffer);
	items++;
}


void SendMainMenu(int client)
{
	if (!g_kvList.GotoFirstSubKey()) 
		return;

	static char sBuffer[30], accessFlag[12];
	int items;

	AdminId admin = GetUserAdmin(client);
	Menu menu = new Menu(Menu_Group, MenuAction_Display);

	do
	{
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
				continue;
		}

		g_kvList.GetSectionName(sBuffer, sizeof(sBuffer));
		menu.AddItem(sBuffer, sBuffer);
		items++;
	}
	while (g_kvList.GotoNextKey());

	g_kvList.Rewind();

	if (!items)
	{
		delete menu;
		CPrintToChat(client, "%t", "NoSkins");
		return;
	}

	menu.SetTitle("%s\n ", PL_NAME);
	menu.Display(client, MENU_TIME_FOREVER);
}

void Menu_Group(Menu menu, MenuAction action, int client, int param)
{
	switch (action)
	{
		case MenuAction_Display:
		{
			g_bTPView[client] = true;
			ToggleView(client);
		}

		// User has selected a model group
		case MenuAction_Select:
		{
			if (!IsValidClient(client)) 
				return;

			if (GetClientTeam(client))
			{
				CPrintToChat(client, "%t", "NoSpectator");
				return;
			}

			char info[30];
			if (!menu.GetItem(param, info, sizeof(info))) 
				return;
				
			// User selected a group
			// advance kv to this group
			g_kvList.JumpToKey(info);
            bool bVModel = view_as<bool>(g_kvList.GetNum("vmodel", 0));

			// Show models
			g_kvList.JumpToKey("List");

			Menu tempmenu = new Menu(Menu_Model, MenuAction_Display);
			
			// Add the models to the menu
			static int items;
			static char sBuffer[PLATFORM_MAX_PATH], path[PLATFORM_MAX_PATH], turned[PLATFORM_MAX_PATH];
			items = 0;

			// Get the first model
			if (!g_kvList.GotoFirstSubKey())
			{
				delete menu;
				return;
			}

			do
			{
				// Add the model to the menu
				g_kvList.GetSectionName(sBuffer, sizeof(sBuffer));
				g_kvList.GetString("path", path, sizeof(path));
				tempmenu.AddItem(path, sBuffer);
				items++;
			}
			while (g_kvList.GotoNextKey());

			g_kvList.GoBack();
			if (!g_kvList.GotoFirstSubKey())
			{
				delete menu;
				return;
			}

			do
			{
				// Add the model to the menu
				g_kvList.GetString("turned", turned, sizeof(turned), "");
				g_kvList.GetString("path", path, sizeof(path));
				tempmenu.AddItem(path, turned, ITEMDRAW_IGNORE);
			}
			while (g_kvList.GotoNextKey());

			// Rewind the KVs
			g_kvList.Rewind();

			// Set the menu title to the model group name
			tempmenu.SetTitle("%s\n  %s (%i pcs):\n ", PL_NAME, info, items);

			IntToString(items, sBuffer, sizeof(sBuffer));
			tempmenu.AddItem(sBuffer, "", ITEMDRAW_IGNORE);

            if (bVModel)
            {
                tempmenu.AddItem("vmodel", "", ITEMDRAW_IGNORE);
            }

			tempmenu.ExitBackButton = true;
			tempmenu.ExitButton = false;
			tempmenu.Display(client, MENU_TIME_FOREVER);
		}

		case MenuAction_Cancel:
		{
			g_bTPView[client] = false;
			ToggleView(client);
		}

		case MenuAction_End: 
			delete menu;
	}
}

void Menu_Model(Menu menu, MenuAction action, int client, int param)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			g_bTPView[client] = true;
			ToggleView(client);
		}
		
		// User choose a model
		case MenuAction_Select:
		{
			if (!IsValidClient(client)) 
				return;

			// how did you get there?
			if (GetClientTeam(client))
			{
				CPrintToChat(client, "%t", "NoSpectator");
				return;
			}

			char model[PLATFORM_MAX_PATH], name[PLATFORM_MAX_PATH];
			if (!menu.GetItem(param, model, sizeof(model), _, name, sizeof(name))) 
				return;

            char sTemp[8];
            int style;
            menu.GetItem(menu.ItemCount - 1, sTemp, sizeof(sTemp), style);

            if (!strcmp(sTemp, "vmodel") && style == ITEMDRAW_IGNORE)
            {
                ApplyvModel(client, model);
				strcopy(g_sViewModel[client], sizeof(g_sViewModel[client]), model);
				g_hCookie_VModel.Set(client, model);
				CPrintToChat(client, "%t", "SetViewModel", name);
            }
            else
            {
				char sItems[8];
				menu.GetItem(menu.ItemCount - 1, sItems, sizeof(sItems));
				int items = StringToInt(sItems);

				static char sWModel[128];
				static char sTurnedModel[128];
				bool bFound = false;
				for (int i = items; i < menu.ItemCount - 1; i++)
				{
					//PrintToServer("items: %d, i: %d, menu.ItemCount: %d", items, i, menu.ItemCount);
					menu.GetItem(i, sWModel, sizeof(sWModel), style, sTurnedModel, sizeof(sTurnedModel));

					// this means this world model has a turned model.
					if (!strcmp(sWModel, model) && style == ITEMDRAW_IGNORE)
					{
						g_hCookie_TurnedModel.Set(client, sTurnedModel);
						strcopy(g_sTurnedModel[client], sizeof(g_sTurnedModel[client]), sTurnedModel);
						//PrintToServer("Setting Turned Model: %s, %s, %d", sTurnedModel, g_sTurnedModel[client], client);
						bFound = true;
						break;
					}
				}

				if (!bFound)
				{
					// else set turned model to nothing, finally it will pick the original randomly.
					g_sTurnedModel[client][0] = '\0';
					g_hCookie_TurnedModel.Set(client, g_sTurnedModel[client]);
				}

                ApplyModel(client, model);
				g_hCookie_WModel.Set(client, model);
				strcopy(g_sModel[client], sizeof(g_sModel[client]), model);
				CPrintToChat(client, "%t", "SetModel", name);

				g_bRandom[client] = false;
            }
			
			SendMainMenu(client);
		}

		case MenuAction_Cancel:
		{
			if (param == MenuCancel_ExitBack) 
			{
				SendMainMenu(client);
			}
			else
			{
				g_bTPView[client] = false;
				ToggleView(client);
			}
		}

		// If they picked exit, close the menu handle
		case MenuAction_End: 
			delete menu;
	}
}
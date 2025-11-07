

void SendMainMenu(int client)
{
	if (!g_kvList[client].GotoFirstSubKey()) 
		return;

	int items;
	AdminId admin = GetUserAdmin(client);
	Menu menu = new Menu(Menu_Group, MenuAction_Display);
	menu.SetTitle("%s\n ", PL_NAME);

	do
	{
		ParseMainSection(menu, admin, client, items);
	}
	while (g_kvList[client].GotoNextKey());
	g_kvList[client].Rewind();

	if (!items)
	{
		CPrintToChat(client, "%t", "NoSkins");
	}

	char sBodyGroup[PLATFORM_MAX_PATH];
	Format(sBodyGroup, sizeof(sBodyGroup), "%T", "Menu_ChooseBodyGroup", client);
	menu.AddItem("bodygroup", sBodyGroup);

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

static void Menu_Group(Menu menu, MenuAction action, int client, int param)
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

			if (param == menu.ItemCount - 1)
			{
				CreateBodygroupMenu(client);
				return;
			}

			char info[64], sDisplay[64];
			if (!menu.GetItem(param, info, sizeof(info), _, sDisplay, sizeof(sDisplay)))
				return;
				
			// User selected a group
			// advance kv to this group
			g_kvList[client].JumpToKey(info);
            bool bVModel = view_as<bool>(g_kvList[client].GetNum("vmodel", 0));

			// Show models
			g_kvList[client].JumpToKey("List");

			Menu tempmenu = new Menu(Menu_Model, MenuAction_Display);
			
			// Add the models to the menu
			int items = 0;
			char sBuffer[PLATFORM_MAX_PATH], path[PLATFORM_MAX_PATH], turned[PLATFORM_MAX_PATH];

			// Get the first model
			if (!g_kvList[client].GotoFirstSubKey())
			{
				CPrintToChat(client, "%t", "NoModels");
				delete menu;
				return;
			}

			do
			{
				// Add the model to the menu
				g_kvList[client].GetSectionName(sBuffer, sizeof(sBuffer));
				g_kvList[client].GetString("path", path, sizeof(path));
				tempmenu.AddItem(path, sBuffer);
				items++;
			}
			while (g_kvList[client].GotoNextKey());

			g_kvList[client].GoBack();
			if (!g_kvList[client].GotoFirstSubKey())
			{
				delete menu;
				return;
			}

			do
			{
				// Add the model to the menu
				g_kvList[client].GetString("turned", turned, sizeof(turned), "");
				g_kvList[client].GetString("path", path, sizeof(path));
				tempmenu.AddItem(path, turned, ITEMDRAW_IGNORE);
			}
			while (g_kvList[client].GotoNextKey());

			// Rewind the KVs
			g_kvList[client].Rewind();

			// Set the menu title to the model group name
			tempmenu.SetTitle("%s\n  %s (%i skins):\n ", PL_NAME, sDisplay, items);

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

static void Menu_Model(Menu menu, MenuAction action, int client, int param)
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

				char sWModel[128];
				char sTurnedModel[128];
				bool bFound = false;
				for (int i = items; i < menu.ItemCount - 1; i++)
				{
					menu.GetItem(i, sWModel, sizeof(sWModel), style, sTurnedModel, sizeof(sTurnedModel));

					// this means this world model has a turned model.
					if (!strcmp(sWModel, model) && style == ITEMDRAW_IGNORE)
					{
						g_hCookie_TurnedModel.Set(client, sTurnedModel);
						strcopy(g_sTurnedModel[client], sizeof(g_sTurnedModel[client]), sTurnedModel);

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
				g_hCookie_WModelLable.Set(client, name);
				strcopy(g_sModel[client], sizeof(g_sModel[client]), model);
				strcopy(g_sWModelLabel[client], sizeof(g_sWModelLabel[client]), name);
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

void CreateBodygroupMenu(int client)
{
	Menu menu = new Menu(Menu_Bodygroup);
	menu.SetTitle("%T", "Menu_BodyGroupTitle", client, PL_NAME);

	CBaseAnimating baseanimating = CBaseAnimating(client);
	int numgroups = baseanimating.GetNumBodyGroups();

	char sTranslations[128];
	for (int i = 0; i < numgroups; i++)
	{
		char name[PLATFORM_MAX_PATH];
		baseanimating.GetBodyGroupName(i, name, sizeof(name));
		menu.AddItem(name, ParseBodyGroupName(name, sTranslations, sizeof(sTranslations), client) ? sTranslations : name);
	}
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

void Menu_Bodygroup(Menu menu, MenuAction action, int client, int param)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (!IsValidClient(client)) 
				return;

			char bodygroup[PLATFORM_MAX_PATH];
			if (!menu.GetItem(param, bodygroup, sizeof(bodygroup))) 
				return;

			CreateBodyPartMenu(client, bodygroup);
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

		case MenuAction_End: 
			delete menu;
	}
}

void CreateBodyPartMenu(int client, const char[] bodygroup)
{
	Menu tempmenu = new Menu(Menu_Bodygroup_Part);
	tempmenu.SetTitle("%T", "Menu_ChooseBodyPart", client, PL_NAME, bodygroup);

	CBaseAnimating baseanimating = CBaseAnimating(client);
	int group = baseanimating.FindBodygroupByName(bodygroup);
	int numgroups = baseanimating.GetBodyGroupCount(group);

	char sTemp[8];
	char sTranslations[128];
	for (int j = 0; j < numgroups; j++)
	{
		char name[PLATFORM_MAX_PATH];
		baseanimating.GetBodyGroupPartName(group, j, name, sizeof(name));

		IntToString(j, sTemp, sizeof(sTemp))
		tempmenu.AddItem(sTemp, ParseBodyPartName(name, sTranslations, sizeof(sTranslations), client, bodygroup) ? sTranslations : name);
	}

	tempmenu.AddItem(bodygroup, "", ITEMDRAW_IGNORE);
	tempmenu.ExitBackButton = true;
	tempmenu.Display(client, MENU_TIME_FOREVER);
}

void Menu_Bodygroup_Part(Menu menu, MenuAction action, int client, int param)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (!IsValidClient(client)) 
				return;

			if (GetClientTeam(client))
			{
				CPrintToChat(client, "%t", "NoSpectator");
				return;
			}

			char bodygroup[PLATFORM_MAX_PATH];
			if (!menu.GetItem(menu.ItemCount - 1, bodygroup, sizeof(bodygroup))) 
				return;

			char part[PLATFORM_MAX_PATH], sDisplay[PLATFORM_MAX_PATH];
			if (!menu.GetItem(param, part, sizeof(part), _, sDisplay, sizeof(sDisplay))) 
				return;

			CBaseAnimating baseanimating = CBaseAnimating(client);
			int group = baseanimating.FindBodygroupByName(bodygroup);

			int partid = StringToInt(part);
			baseanimating.SetBodyGroup(group, partid);
			CPrintToChat(client, "%t", "SetBodygroupPart", sDisplay);

			CreateBodyPartMenu(client, bodygroup);
		}

		case MenuAction_Cancel:
		{
			if (param == MenuCancel_ExitBack) 
			{
				CreateBodygroupMenu(client);
			}
			else
			{
				g_bTPView[client] = false;
				ToggleView(client);
			}
		}

		case MenuAction_End: 
			delete menu;
	}
}
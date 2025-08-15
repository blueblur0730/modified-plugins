int	g_iGiveItemType[NMR_MAXPLAYERS + 1];

void GiveItem_TypeSelect(int client)
{
	Menu menu = new Menu(GiveItem_TypeSelect_MenuHandler);
	menu.SetTitle("选择物品类型:");
	menu.AddItem("", "武器");
	menu.AddItem("", "近战");
	menu.AddItem("", "医疗和工具");
	menu.AddItem("", "子弹与投掷");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

static int GiveItem_TypeSelect_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			g_iGiveItemType[client] = itemNum;
			GiveItem_Select(client);
		}

		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
				g_TopMenu.Display(client, TopMenuPosition_LastCategory);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

static void GiveItem_Select(int client)
{
	Menu menu = new Menu(GiveItem_Select_MenuHandler);

	switch (g_iGiveItemType[client])
	{
		case 0:
		{
			menu.SetTitle("产生武器:");
			for (int i = 0; i < sizeof(g_sWeapons); i++)
			{
				menu.AddItem(g_sWeapons[i][ITEM_NAME], g_sWeapons[i][ITEM_DISPLAY]);
			}
		}
		case 1:
		{
			menu.SetTitle("产生近战:");
			for (int i = 0; i < sizeof(g_sMelees); i++)
			{
				menu.AddItem(g_sMelees[i][ITEM_NAME], g_sMelees[i][ITEM_DISPLAY]);
			}
		}
		case 2:
		{
			menu.SetTitle("产生医疗和工具:");
			for (int i = 0; i < sizeof(g_sItem); i++)
			{
				menu.AddItem(g_sItem[i][ITEM_NAME], g_sItem[i][ITEM_DISPLAY]);
			}
		}
		case 3:
		{
			menu.SetTitle("产生子弹与投掷:");
			for (int i = 0; i < sizeof(g_sAmmo); i++)
			{
				menu.AddItem(g_sAmmo[i][ITEM_NAME], g_sAmmo[i][ITEM_DISPLAY]);
			}
		}
	}

	menu.ExitBackButton = true;
	menu.DisplayAt(client, g_iGiveItemMenuPos[client][g_iGiveItemType[client]], MENU_TIME_FOREVER);
}

static int GiveItem_Select_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sName[128], sDisplay[128];
			menu.GetItem(itemNum, sName, sizeof(sName), _, sDisplay, sizeof(sDisplay));

			float vecOrigin[3];
			GetClientAbsOrigin(client, vecOrigin);

			float vecAngles[3]
			GetClientAbsAngles(client, vecAngles);

			if (strcmp(sName, "nmrih_health_station") == 0 || strcmp(sName, "nmrih_safezone_supply") == 0 || strcmp(sName, "item_inventory_box") == 0)
			{
				if (strcmp(sName, "nmrih_health_station") == 0)
				{
					CreateHealthStation(vecOrigin, vecAngles);
				}
				else if (strcmp(sName, "nmrih_safezone_supply") == 0)
				{
					CreateSupplyBox(vecOrigin, vecAngles);
				}
				else if (strcmp(sName, "item_inventory_box") == 0)
				{
					CreateInventoryBox(vecOrigin, vecAngles);
				}
			}
			else
			{
				if (CreateDesiredThingFromRandomSpawner(sName, vecOrigin, vecAngles, 100, 100, 6))
				{
					PrintToChat(client, "[DevMenu] 产生物品: %s", sDisplay);
				}
				else
				{
					PrintToChat(client, "[DevMenu] 产生物品失败: %s", sDisplay);
				}
			}
			
			g_iGiveItemMenuPos[client][g_iGiveItemType[client]] = menu.Selection;
			GiveItem_Select(client);
		}

		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
				GiveItem_TypeSelect(client);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

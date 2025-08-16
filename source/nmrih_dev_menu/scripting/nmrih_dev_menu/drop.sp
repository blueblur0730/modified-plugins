
void Drop_TargetSelect(int client)
{
	Menu menu = new Menu(Drop_TargetSelect_MenuHandler);
	menu.SetTitle("选择装备掉落目标:");
	menu.AddItem("", "自己");
	menu.AddItem("", "所有幸存者");

	char sName[128], sUserid[16];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsClientInGame(i) && IsPlayerAlive(i))
		{
			FormatEx(sName, sizeof(sName), "%N", i);
			FormatEx(sUserid, sizeof(sUserid), "%i", GetClientUserId(i));
			menu.AddItem(sUserid, sName);
		}
	}

	menu.ExitBackButton = true;
	menu.DisplayAt(client, g_iDropMenuPos[client], MENU_TIME_FOREVER);
}

static int Drop_TargetSelect_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (itemNum)
			{
				case 0:
				{
					if (IsPlayerAlive(client))
					{
						SelectDropType(client, GetClientUserId(client), itemNum);
					}
				}

				case 1:
				{
					SelectDropType(client, _, itemNum);
				}

				default:
				{
					char sUserid[16];
					menu.GetItem(itemNum, sUserid, sizeof(sUserid));
					int userid	= StringToInt(sUserid);
					int iTarget = GetClientOfUserId(userid);
					if (iTarget > 0 && iTarget <= MaxClients && IsClientInGame(iTarget) && IsPlayerAlive(iTarget))
					{
						SelectDropType(client, userid, itemNum);
					}
					else
					{
						PrintToChat(client, "[DevMenu] 无效的目标.");
					}
				}
			}

			g_iDropMenuPos[client] = menu.Selection;
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

int	g_iInnerDropMenuPos[NMR_MAXPLAYERS + 1];

static void SelectDropType(int client = -1, int userid = -1, int itemNum)
{
	Menu menu = new Menu(SelectDropType_MenuHandler);
	menu.SetTitle("选择装备掉落类型:");
	menu.AddItem("", "所有物品");
	menu.AddItem("", "所有武器");
	menu.AddItem("", "所有弹药");

	char sUserid[16];
	IntToString(userid, sUserid, sizeof(sUserid));
	menu.AddItem(sUserid, "", ITEMDRAW_IGNORE);

	char sItemNUm[16];
	IntToString(itemNum, sItemNUm, sizeof(sItemNUm));
	menu.AddItem(sItemNUm, "", ITEMDRAW_IGNORE);

	menu.ExitBackButton = true;
	menu.DisplayAt(client, g_iInnerDropMenuPos[client], MENU_TIME_FOREVER);
}

static void SelectDropType_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	char sUserid[16];
	menu.GetItem(3, sUserid, sizeof(sUserid));

	char sUpperItemNum[16];
	menu.GetItem(4, sUpperItemNum, sizeof(sUpperItemNum));
	int iUpperItemNum = StringToInt(sUpperItemNum);

	int iTarget		  = GetClientOfUserId(StringToInt(sUserid));
	if ((iTarget <= 0 || iTarget > MaxClients || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget)) && iUpperItemNum != 1)
	{
		PrintToChat(client, "[DevMenu] 无效的目标.");
		return;
	}

	switch (action)
	{
		case MenuAction_Select:
		{
			switch (itemNum)
			{
				case 0:
				{
					if (iUpperItemNum == 1)
					{
						for (int i = 1; i <= MaxClients; i++)
						{
							if (IsClientInGame(i) && IsPlayerAlive(i))
							{
								// CNMRiH_Player::DropEverything() is a little bit special, it just removes your fist and zippo.
								// so we use another approach.
								DropAllWeapons(i);
								NMR_Player(i).ThrowAllAmmo();
							}
						}

						PrintToChat(client, "[DevMenu] 已掉落所有幸存者的所有装备.");
					}
					else
					{
						DropAllWeapons(iTarget);
						NMR_Player(iTarget).ThrowAllAmmo();
						PrintToChat(client, "[DevMenu] 已掉落 %N 的所有装备.", iTarget);
					}
				}

				case 1:
				{
					if (iUpperItemNum == 1)
					{
						for (int i = 1; i <= MaxClients; i++)
						{
							if (IsClientInGame(i) && IsPlayerAlive(i))
							{
								DropAllWeapons(i);
							}
						}

						PrintToChat(client, "[DevMenu] 已掉落所有幸存者的所有武器.");
					}
					else
					{
						DropAllWeapons(iTarget);
						PrintToChat(client, "[DevMenu] 已掉落 %N 的所有武器.", iTarget);
					}
				}

				case 2:
				{
					if (iUpperItemNum == 1)
					{
						for (int i = 1; i <= MaxClients; i++)
						{
							if (IsClientInGame(i) && IsPlayerAlive(i))
							{
								NMR_Player(i).ThrowAllAmmo();
							}
						}

						PrintToChat(client, "[DevMenu] 已掉落所有幸存者的所有弹药.");
					}
					else
					{
						NMR_Player(iTarget).ThrowAllAmmo();
						PrintToChat(client, "[DevMenu] 已掉落 %N 的所有弹药.", iTarget);
					}
				}
			}

			g_iInnerDropMenuPos[client] = menu.Selection;
			Drop_TargetSelect(client);
		}

		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
				g_TopMenu.Display(client, TopMenuPosition_LastCategory);
		}

		case MenuAction_End:
			delete menu;
	}
}
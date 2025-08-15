
void Deprive_TargetSelect(int client)
{
	Menu menu = new Menu(Deprive_TargetSelect_MenuHandler);
	menu.SetTitle("选择装备剥夺目标:");
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
	menu.Display(client, MENU_TIME_FOREVER);
}

static int Deprive_TargetSelect_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
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
						SelectDepriveType(client, GetClientUserId(client), itemNum);
					}
				}

				case 1:
				{
					SelectDepriveType(client, _, itemNum);
				}

				default:
				{
					char sUserid[16];
					menu.GetItem(itemNum, sUserid, sizeof(sUserid));

					int userid = StringToInt(sUserid);
					int iTarget = GetClientOfUserId(userid);

					if (iTarget > 0 && iTarget <= MaxClients && IsClientInGame(iTarget) && IsPlayerAlive(iTarget))
					{
						SelectDepriveType(client, userid, itemNum);
					}
					else
					{
						PrintToChat(client, "[DevMenu] 无效的目标.");
					}
				}
			}
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

static void SelectDepriveType(int client = -1, int userid = -1, int itemNum)
{
	Menu menu = new Menu(SelectDepriveType_MenuHandler);
	menu.SetTitle("选择装备剥夺类型:");
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
	menu.Display(client, MENU_TIME_FOREVER);
}

static void SelectDepriveType_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	char sUserid[16];
	menu.GetItem(3, sUserid, sizeof(sUserid));

	char sUpperItemNum[16];
	menu.GetItem(4, sUpperItemNum, sizeof(sUpperItemNum));
	int iUpperItemNum = StringToInt(sUpperItemNum);

	int iTarget = GetClientOfUserId(StringToInt(sUserid));
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
								// hack: DestroyEverything() dose not remove the carried weight.
								// also your viewmodel will stay still to the current weapon, even if you dose not have it.
								// to fix this we need to switch to fist.
								NMR_Player(i).DestroyEverything();
								NMR_Player(i).RemoveCarriedWeight(NMR_Player(i).GetCarriedWeight());
								SetActiveWeapon(i, FindFists(i));
							}
						}

						PrintToChat(client, "[DevMenu] 已剥夺所有幸存者的所有装备.");
					}
					else
					{
						NMR_Player(iTarget).DestroyEverything();
						NMR_Player(iTarget).RemoveCarriedWeight(NMR_Player(iTarget).GetCarriedWeight());
						SetActiveWeapon(iTarget, FindFists(iTarget));
						PrintToChat(client, "[DevMenu] 已剥夺 %N 的所有装备.", iTarget);
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
								NMR_Player(i).DestroyAllWeapons();
								NMR_Player(i).RemoveCarriedWeight(NMR_Player(i).GetCarriedWeight() - NMR_Player(i).GetAmmoCarryWeight());
								SetActiveWeapon(i, FindFists(i));
							}
						}

						PrintToChat(client, "[DevMenu] 已剥夺所有幸存者的所有武器.");
					}
					else
					{
						NMR_Player(iTarget).DestroyAllWeapons();
						NMR_Player(iTarget).RemoveCarriedWeight(NMR_Player(iTarget).GetCarriedWeight() - NMR_Player(iTarget).GetAmmoCarryWeight());
						SetActiveWeapon(iTarget, FindFists(iTarget));
						PrintToChat(client, "[DevMenu] 已剥夺 %N 的所有武器.", iTarget);
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
								NMR_Player(i).DestroyAllAmmo();
								NMR_Player(i).RemoveCarriedWeight(NMR_Player(i).GetAmmoCarryWeight());
							}
						}

						PrintToChat(client, "[DevMenu] 已剥夺所有幸存者的所有弹药.");
					}
					else
					{
						NMR_Player(iTarget).DestroyAllAmmo();
						NMR_Player(iTarget).RemoveCarriedWeight(NMR_Player(iTarget).GetAmmoCarryWeight());
						PrintToChat(client, "[DevMenu] 已剥夺 %N 的所有弹药.", iTarget);
					}
				}
			}

			Deprive_TargetSelect(client);
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
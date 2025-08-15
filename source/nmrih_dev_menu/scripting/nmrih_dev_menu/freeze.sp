void Freeze_TargetSelect(int client)
{
	Menu menu = new Menu(Freeze_TargetSelect_MenuHandler);
	menu.SetTitle("选择冻结目标:");
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

static int Freeze_TargetSelect_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
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
						FreezeClient(client, client);
					}
				}

				case 1:
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if (IsClientInGame(i) && IsPlayerAlive(i))
						{
							FreezeClient(client, i);
						}
					}
				}

				default:
				{
					char sUserid[16];
					menu.GetItem(itemNum, sUserid, sizeof(sUserid));
					int iTarget = GetClientOfUserId(StringToInt(sUserid));
					if (iTarget > 0 && iTarget <= MaxClients && IsClientInGame(iTarget) && IsPlayerAlive(iTarget))
					{
						FreezeClient(client, iTarget);
					}
				}
			}

			Freeze_TargetSelect(client);
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

static void FreezeClient(int client, int iTarget)
{
	MoveType movetype = GetEntityMoveType(iTarget);

	if (movetype != MOVETYPE_NONE)
	{
		SetEntityMoveType(iTarget, MOVETYPE_NONE);
		PrintToChat(client, "[DevMenu] 设置冻结模式: %N", iTarget);
	}
	else
	{
		SetEntityMoveType(iTarget, MOVETYPE_WALK);
		PrintToChat(client, "[DevMenu] 解除冻结模式: %N", iTarget);
	}
}
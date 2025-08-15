
void GodMode_TargetSelect(int client)
{
	Menu menu = new Menu(GodMode_TargetSelect_MenuHandler);
	menu.SetTitle("选择无敌模式目标:");
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
	menu.DisplayAt(client, g_iGodModeMenuPos[client], MENU_TIME_FOREVER);
}

static int GodMode_TargetSelect_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (itemNum)
			{
				case 0, 1: DoGodMode(client, itemNum);
				default:
				{
					char sUserid[16];
					menu.GetItem(itemNum, sUserid, sizeof(sUserid));
					int iTarget = GetClientOfUserId(StringToInt(sUserid));
					if (iTarget > 0 && iTarget <= MaxClients && IsClientInGame(iTarget) && IsPlayerAlive(iTarget))
					{
						SetClientGodMode(client, iTarget);
					}
				}
			}

			g_iGodModeMenuPos[client] = menu.Selection;
			GodMode_TargetSelect(client);
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

static void DoGodMode(int client, int iType)
{
	switch (iType)
	{
		case 0:
		{
			if (IsPlayerAlive(client))
			{
				SetClientGodMode(client, client);
			}
		}

		case 1:
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					SetClientGodMode(client, i);
				}
			}
		}
	}
}

static void SetClientGodMode(int client, int iTarget)
{
	int flags = GetEntityFlags(iTarget);

	if (flags & FL_GODMODE)
	{
		SetEntityFlags(iTarget, flags & ~FL_GODMODE);
		PrintToChat(client, "[DevMenu] 关闭无敌模式: %N", iTarget);
	}
	else
	{
		SetEntityFlags(iTarget, flags | FL_GODMODE);
		PrintToChat(client, "[DevMenu] 开启无敌模式: %N", iTarget);
	}
}
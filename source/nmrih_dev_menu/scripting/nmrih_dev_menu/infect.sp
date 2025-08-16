void Infect_TargetSelect(int client)
{
	Menu menu = new Menu(MenuHandler_Infect);
	menu.SetTitle("选择感染目标:");
	menu.AddItem("", "自己");
	menu.AddItem("", "所有幸存者");

	for (int i = 1; i < MaxClients; i++)
	{
		if (i == client)
			continue;

		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		static char sUserid[16];
		IntToString(GetClientUserId(i), sUserid, sizeof(sUserid));

		static char sName[128];
		GetClientName(i, sName, sizeof(sName));

		menu.AddItem(sUserid, sName);
	}

	menu.ExitBackButton = true;
	menu.DisplayAt(client, g_iInfectMenuPos[client], MENU_TIME_FOREVER);
}

static void MenuHandler_Infect(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (itemNum)
			{
				case 0, 1: DoInfect(client, itemNum);
				default:
				{
					char sUserid[16];
					menu.GetItem(itemNum, sUserid, sizeof(sUserid));
					int iTarget = GetClientOfUserId(StringToInt(sUserid));
					if (iTarget > 0 && iTarget <= MaxClients && IsClientInGame(iTarget) && IsPlayerAlive(iTarget))
					{
						DoInfect(client, 0, iTarget);
					}
					else
					{
						PrintToChat(client, "[DevMenu] 无效的目标: %N", iTarget);
					}
				}
			}

			g_iInfectMenuPos[client] = menu.Selection;
			Infect_TargetSelect(client);
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

static void DoInfect(int client, int itemNum, int iTarget = -1)
{
	switch (itemNum)
	{
		case 0:
		{
			if (NMR_Player(client).IsInfected())
			{
				NMR_Player(client).CureInfection();
				PrintToChat(client, "[DevMenu] 已治愈目标感染: %N", client);
			}
			else
			{
				NMR_Player(client).BecomeInfected();
				PrintToChat(client, "[DevMenu] 已感染目标: %N", client);
			}
		}

		case 1:
		{
			for (int i = 1; i < MaxClients; i++)
			{
				if (!IsClientInGame(i) || !IsPlayerAlive(i))
					continue;

				NMR_Player(i).BecomeInfected();
			}

			PrintToChat(client, "[DevMenu] 已感染所有幸存者.");
		}

		default:
		{
			if (NMR_Player(iTarget).IsInfected())
			{
				NMR_Player(iTarget).CureInfection();
				PrintToChat(client, "[DevMenu] 已治愈目标感染: %N", client);
			}
			else
			{
				NMR_Player(iTarget).BecomeInfected();
				PrintToChat(client, "[DevMenu] 已感染目标: %N", client);
			}
		}
	}
}
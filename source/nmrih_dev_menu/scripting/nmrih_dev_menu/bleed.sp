
void Bleed_TargetSelect(int client)
{
    Menu menu = new Menu(Bleed_TargetSelect_MenuHandler);
    menu.SetTitle("选择流血目标:");
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
	menu.DisplayAt(client, g_iBleedMenuPos[client], MENU_TIME_FOREVER);
}

static void Bleed_TargetSelect_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (itemNum)
			{
				case 0, 1: DoBleed(client, itemNum);
				default:
				{
					char sUserid[16];
					menu.GetItem(itemNum, sUserid, sizeof(sUserid));
					int iTarget = GetClientOfUserId(StringToInt(sUserid));
					if (iTarget > 0 && iTarget <= MaxClients && IsClientInGame(iTarget) && IsPlayerAlive(iTarget))
					{
                        DoBleed(client, itemNum, iTarget);
					}
                    else
                    {
                        PrintToChat(client, "[DevMenu] 无效的目标: %N", iTarget);
                    }
				}
			}

			g_iBleedMenuPos[client] = menu.Selection;
			Bleed_TargetSelect(client);
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

static void DoBleed(int client, int itemNum, int iTarget = -1)
{
    switch (itemNum)
    {
        case 0: {
            if (NMR_Player(client).IsBleedingOut())
            {
                NMR_Player(client).StopBleedingOut();
                PrintToChat(client, "[DevMenu] 已停止流血: %N", client);
            }
            else
            {
                NMR_Player(client).BleedOut();
                PrintToChat(client, "[DevMenu] 已让 %N 流血.", client);
            }
        }

        case 1: {
            for (int i = 1; i < MaxClients; i++)
            {
                if (!IsClientInGame(i) || !IsPlayerAlive(i))
                    continue;

                NMR_Player(i).BleedOut();
            }

            PrintToChat(client, "[DevMenu] 已让所有幸存者流血.");
        }

        default: {
            if (NMR_Player(iTarget).IsBleedingOut())
            {
                NMR_Player(iTarget).StopBleedingOut();
                PrintToChat(client, "[DevMenu] 已停止流血: %N", iTarget);
            }
            else
            {
                NMR_Player(iTarget).BleedOut();
                PrintToChat(client, "[DevMenu] 已让 %N 流血.", iTarget);
            }
		}
    }
}
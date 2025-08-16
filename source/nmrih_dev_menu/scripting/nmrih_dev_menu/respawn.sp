
void Respawn_TargetSelect(int client)
{
	Menu menu = new Menu(Respawn_TargetSelect_MenuHandler);
	menu.SetTitle("选择复活目标:");
	menu.AddItem("", "自己");
	menu.AddItem("", "所有幸存者");

	char sName[128], sUserid[16];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsClientInGame(i) && !IsPlayerAlive(i))
		{
			FormatEx(sName, sizeof(sName), "%N", i);
			FormatEx(sUserid, sizeof(sUserid), "%i", GetClientUserId(i));
			menu.AddItem(sUserid, sName);
		}
	}

	menu.ExitBackButton = true;
	menu.DisplayAt(client, g_iRespawnMenuPos[client], MENU_TIME_FOREVER);
}

static int Respawn_TargetSelect_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (itemNum)
			{
				case 0:
				{
					if (!IsPlayerAlive(client))
					{
						NMR_Player(client).RespawnPlayer();
						PrintToChat(client, "[DevMenu] 复活: %N", client);
					}
				}

				case 1:
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if (IsClientInGame(i) && !IsPlayerAlive(i))
						{
							NMR_Player(i).RespawnPlayer();
						}
					}

					PrintToChat(client, "[DevMenu]: 已复活所有幸存者.");
				}

				default:
				{
					char sUserid[16];
					menu.GetItem(itemNum, sUserid, sizeof(sUserid));
					int iTarget = GetClientOfUserId(StringToInt(sUserid));
					if (iTarget > 0 && iTarget <= MaxClients && IsClientInGame(iTarget) && !IsPlayerAlive(iTarget))
					{
						NMR_Player(iTarget).RespawnPlayer();
						PrintToChat(client, "[DevMenu]: 复活 %N", iTarget);
					}
					else
					{
						PrintToChat(client, "[DevMenu] 无效的目标: %N", iTarget);
					}
				}
			}

			g_iRespawnMenuPos[client] = menu.Selection;
			Respawn_TargetSelect(client);
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
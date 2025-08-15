
void GiveHp_TargetSelect(int client)
{
	Menu menu = new Menu(GiveHp_TargetSelect_MenuHandler);
	menu.SetTitle("选择回血目标:");
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

int GiveHp_TargetSelect_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (itemNum)
			{
				case 0:
				{
					SetEntProp(client, Prop_Send, "m_iHealth", GetEntProp(client, Prop_Data, "m_iMaxHealth"));
					PrintToChat(client, "[DevMenu] 回血: %N", client);
				}
				
				case 1:
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if (IsClientInGame(i) && IsPlayerAlive(i))
						{
							SetEntProp(i, Prop_Send, "m_iHealth", GetEntProp(i, Prop_Data, "m_iMaxHealth"));
							PrintToChat(client, "[DevMenu] 回血: %N", i);
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
						SetEntProp(iTarget, Prop_Send, "m_iHealth", GetEntProp(iTarget, Prop_Data, "m_iMaxHealth"));
						PrintToChat(client, "[DevMenu] 回血: %N", iTarget);
					}
					else
					{
						PrintToChat(client, "[DevMenu] 无效的目标: %N", iTarget);
					}
				}
			}

			GiveHp_TargetSelect(client);
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
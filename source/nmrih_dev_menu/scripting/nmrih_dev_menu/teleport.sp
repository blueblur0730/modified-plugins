
void Teleport_TypeSelect(int client)
{
	Menu menu = new Menu(Teleport_TypeSelect_MenuHandler);
	menu.SetTitle("选择传送类型:");
	menu.AddItem("", "传送所有幸存者到自己");
	menu.AddItem("", "传送所有幸存者到准心处");
	menu.AddItem("", "传送所有幸存者至撤离点");
	menu.AddItem("", "传送指定幸存者");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Teleport_TypeSelect_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (itemNum)
			{
				case 0, 1, 2: {
					DoTeleport(client, itemNum);
					Teleport_TypeSelect(client);
				} 
				
				case 3: DoTeleportSelected(client);
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

void DoTeleport(int client, int iType)
{
	switch (iType)
	{
		case 0:
		{
			float fPos[3];
			GetClientAbsOrigin(client, fPos);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (i != client && IsClientInGame(i) && IsPlayerAlive(i))
				{
					TeleportEntity(i, fPos, NULL_VECTOR, NULL_VECTOR);
					PrintToChat(client, "[DevMenu] 已传送所有幸存者到自己");
				}
			}
		}

		case 1:
		{
			float pos[3];
			if (GetCrosshairPos(client, pos))
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && IsPlayerAlive(i))
					{
						TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
						PrintToChat(client, "[DevMenu] 已传送所有幸存者到准心处");
					}
				}
			}
			else
			{
				PrintToChat(client, "[DevMenu] 准星所选位置无效.");
			}
		}

		case 2:
		{
			int nmrih_extract_point = FindEntityByClassname(-1, "nmrih_extract_point");
			if (nmrih_extract_point != INVALID_ENT_REFERENCE && IsValidEntity(nmrih_extract_point))
			{
				float fPos[3];
				GetEntPropVector(nmrih_extract_point, Prop_Data, "m_vecAbsOrigin", fPos);
				
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && IsPlayerAlive(i))
					{
						TeleportEntity(i, fPos, NULL_VECTOR, NULL_VECTOR);
						PrintToChat(client, "[DevMenu] 已传送所有幸存者至撤离点");
					}
				}
			}
			else
			{
				PrintToChat(client, "[DevMenu] 未找到撤离点.");
			}
		}
	}
}

void DoTeleportSelected(int client)
{
	Menu menu = new Menu(MenuHandler_TeleportSelected);
	menu.SetTitle("选择指定的玩家:");

	for (int i = 1; i < MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		static char sName[64];
		GetClientName(i, sName, sizeof(sName));

		static char sUserid[16];
		IntToString(GetClientUserId(i), sUserid, sizeof(sUserid));

		menu.AddItem(sUserid, sName);
	}

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

void MenuHandler_TeleportSelected(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sUserid[16];
			menu.GetItem(itemNum, sUserid, sizeof(sUserid));

			Menu newmenu = new Menu(MenuHandler_ChooseMethod);
			newmenu.SetTitle("选择传送方式");
			newmenu.AddItem("", "传送到自己");
			newmenu.AddItem("", "传送到准心处");
			newmenu.AddItem("", "传送到撤离点");
			newmenu.AddItem(sUserid, "", ITEMDRAW_IGNORE);

			newmenu.ExitBackButton = true;
			newmenu.Display(client, MENU_TIME_FOREVER);
			//DoTeleportSelected(client);
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

void MenuHandler_ChooseMethod(Menu menu, MenuAction action, int client, int itemNum)
{
	char sUserid[16];
	menu.GetItem(3, sUserid, sizeof(sUserid));

	int userid = StringToInt(sUserid);
	int target = GetClientOfUserId(userid);

	if (!target || !IsClientInGame(target) || !IsPlayerAlive(target))
	{
		delete menu;
		PrintToChat(client, "[DevMenu] 目标不再有效.");
		DoTeleportSelected(client);
		return;
	}

	switch (action)
	{
		case MenuAction_Select:
		{

			switch (itemNum)
			{
				case 0: {
					float fPos[3];
					GetClientAbsOrigin(client, fPos);
					TeleportEntity(target, fPos);
					PrintToChat(client, "[DevMenu] 已传送 %N 到自己.", target);
				}

				case 1: {
					float fPos[3];
					if (GetCrosshairPos(client, fPos))
					{
						TeleportEntity(target, fPos);
						PrintToChat(client, "[DevMenu] 已传送 %N 到准星处.", target);
					}
					else
					{
						PrintToChat(client, "[DevMenu] 准星所选位置无效.");
					}
				}

				case 2: {
					int nmrih_extract_point = FindEntityByClassname(-1, "nmrih_extract_point");
					if (nmrih_extract_point != INVALID_ENT_REFERENCE && IsValidEntity(nmrih_extract_point))
					{
						float fPos[3];
						GetEntPropVector(nmrih_extract_point, Prop_Data, "m_vecAbsOrigin", fPos);

						TeleportEntity(target, fPos);
						PrintToChat(client, "[DevMenu] 已传送 %N 至撤离点.", target);
					}
					else
					{
						PrintToChat(client, "[DevMenu] 未找到撤离点.");
					}
				}
			}

			DoTeleportSelected(client);
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
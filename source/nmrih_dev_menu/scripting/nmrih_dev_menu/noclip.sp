
void NoClip_TargetSelect(int client)
{
	Menu menu = new Menu(NoClip_TargetSelect_MenuHandler);
	menu.SetTitle("选择穿墙模式目标:");
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
	menu.DisplayAt(client, g_iNoClipMenuPos[client], MENU_TIME_FOREVER);
}

static int NoClip_TargetSelect_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (itemNum)
			{
				case 0, 1, 2: DoNoclip(client, itemNum);
				default:
				{
					char sUserid[16];
					menu.GetItem(itemNum, sUserid, sizeof(sUserid));
					int iTarget = GetClientOfUserId(StringToInt(sUserid));
					if (iTarget > 0 && iTarget <= MaxClients && IsClientInGame(iTarget) && IsPlayerAlive(iTarget))
					{
						SetClientNoClip(client, iTarget);
					}
				}
			}

			g_iNoClipMenuPos[client] = menu.Selection;
			NoClip_TargetSelect(client);
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

static void DoNoclip(int client, int iType)
{
	switch (iType)
	{
		case 0:
		{
			if (IsPlayerAlive(client))
			{
				SetClientNoClip(client, client);
			}
		}

		case 1:
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					SetClientNoClip(client, i);
				}
			}
		}
	}
}

static void SetClientNoClip(int client, int iTarget)
{
	MoveType movetype = GetEntityMoveType(iTarget);

	if (movetype != MOVETYPE_NOCLIP)
	{
		SetEntityMoveType(iTarget, MOVETYPE_NOCLIP);
		PrintToChat(client, "[DevMenu] 开启穿墙模式: %N", iTarget);
	}
	else
	{
		SetEntityMoveType(iTarget, MOVETYPE_WALK);
		PrintToChat(client, "[DevMenu] 关闭穿墙模式: %N", iTarget);
	}
}
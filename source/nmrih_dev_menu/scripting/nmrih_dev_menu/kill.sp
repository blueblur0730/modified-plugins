void Kill_TargetSelect(int client)
{
	Menu menu = new Menu(Kill_TargetSelect_MenuHandler);
	menu.SetTitle("选择处死目标:");
	menu.AddItem("", "所有丧尸");
	menu.AddItem("", "所有走尸");
    menu.AddItem("", "所有跑尸");
    menu.AddItem("", "所有小孩丧尸");
    menu.AddItem("", "所有转变丧尸");
	menu.AddItem("", "自己");
    menu.AddItem("", "指定幸存者");
	menu.AddItem("", "所有幸存者");

	menu.ExitBackButton = true;
	menu.DisplayAt(client, g_iKillMenuPos[client], MENU_TIME_FOREVER);
}

static int Kill_TargetSelect_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (itemNum)
			{
                case 0:
                {
                    int count = 0;
                    int ent = INVALID_ENT_REFERENCE;
                    while ((ent = FindEntityByClassname(ent, "npc_nmrih_*")) != INVALID_ENT_REFERENCE)
                    {
                        char sClassname[64];
                        GetEntityClassname(ent, sClassname, sizeof(sClassname));

                        // ignore npc_nmrih_basenpc
                        if (strcmp(sClassname[10], "b") == 0)
                            continue;

                        AcceptEntityInput(ent, "Kill");
                        count++;
                    }

                    PrintToChat(client, "[DevMenu] 处死所有丧尸: %i 个", count);
                }

                case 1:
                {
                    int count = 0;
                    int ent = INVALID_ENT_REFERENCE;
                    while ((ent = FindEntityByClassname(ent, "npc_nmrih_shamblerzombie")) != INVALID_ENT_REFERENCE)
                    { 
                        AcceptEntityInput(ent, "Kill");
                        count++;
                    }

                    PrintToChat(client, "[DevMenu] 处死走尸: %i 个", count);
                }

                case 2:
                {
                    int count = 0;
                    int ent = INVALID_ENT_REFERENCE;
                    while ((ent = FindEntityByClassname(ent, "npc_nmrih_runnerzombie")) != INVALID_ENT_REFERENCE)
                    { 
                        AcceptEntityInput(ent, "Kill");
                        count++;
                    }

                    PrintToChat(client, "[DevMenu] 处死跑尸: %i 个", count);
                }

                case 3:
                {
                    int count = 0;
                    int ent = INVALID_ENT_REFERENCE;
                    while ((ent = FindEntityByClassname(ent, "npc_nmrih_kidzombie")) != INVALID_ENT_REFERENCE)
                    { 
                        AcceptEntityInput(ent, "Kill");
                        count++;
                    }

                    PrintToChat(client, "[DevMenu] 处死小跑尸: %i 个", count);
                }

                case 4:
                {
                    int count = 0;
                    int ent = INVALID_ENT_REFERENCE;
                    while ((ent = FindEntityByClassname(ent, "npc_nmrih_turnedzombie")) != INVALID_ENT_REFERENCE)
                    { 
                        AcceptEntityInput(ent, "Kill");
                        count++;
                    }

                    PrintToChat(client, "[DevMenu] 处死转变丧尸: %i 个", count);
                }

                case 5:
                {
                    if (IsPlayerAlive(client))
                    {
                        ForcePlayerSuicide(client);
                        PrintToChat(client, "[DevMenu] 处死: %N", client);
                    }
                }

                case 6:
                {
                    Menu slaymenu = new Menu(SlayMenuHandler);
                    slaymenu.SetTitle("选择处死的幸存者:");

                    for (int i = 1; i <= MaxClients; i++)
                    {
                        if (IsClientInGame(i) && IsPlayerAlive(i))
                        {
                            char name[MAX_NAME_LENGTH];
                            GetClientName(i, name, sizeof(name));

                            char userid[32];
                            IntToString(GetClientUserId(i), userid, sizeof(userid));

                            slaymenu.AddItem(userid, name);
                        }
                    }

                    slaymenu.ExitBackButton = true;
                    slaymenu.Display(client, MENU_TIME_FOREVER);
                }

                case 7:
                {
                    for (int i = 1; i <= MaxClients; i++)
                    {
                        if (IsClientInGame(i) && IsPlayerAlive(i))
                        {
                            ForcePlayerSuicide(i);
                        }
                    }

                    PrintToChat(client, "[DevMenu] 已处死所有幸存者");
                }
			}

			g_iKillMenuPos[client] = menu.Selection;
			Kill_TargetSelect(client);
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

static void SlayMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            menu.GetItem(itemNum, info, sizeof(info));
            
            int userid = StringToInt(info);
            int target = GetClientOfUserId(userid);

            if (target <= 0 || target > MaxClients || !IsClientInGame(target) || !IsPlayerAlive(target))
            {
                PrintToChat(client, "[DevMenu] 玩家不在线或已死亡");
            }
            else
            {
                ForcePlayerSuicide(target);
                PrintToChat(client, "[DevMenu] 已处死: %N", target);
            }

            g_iKillMenuPos[client] = menu.Selection;
            Kill_TargetSelect(client);
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
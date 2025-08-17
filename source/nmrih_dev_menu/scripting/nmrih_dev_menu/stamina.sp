
bool g_bInfiniteStamina[NMR_MAXPLAYERS +1] = { false, ... };

void Stamina_TargetSelect(int client)
{
    Menu menu = new Menu(Stamina_TargetSelect_MenuHandler);
	menu.SetTitle("选择切换无限体力目标:");
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
	menu.DisplayAt(client, g_iStaminaMenuPos[client], MENU_TIME_FOREVER);
}

static void Stamina_TargetSelect_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
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
                        g_bInfiniteStamina[client] = !g_bInfiniteStamina[client];
                        PrintToChat(client, "[DevMenu] 已 %s 无限体力: %N", g_bInfiniteStamina[client] ? "开启" : "关闭", client);
                    }
                }

                case 1:
                {
                    for (int i = 1; i <= MaxClients; i++)
                    {
                        if (IsClientInGame(i) && IsPlayerAlive(i))
                        {
                            g_bInfiniteStamina[i] = !g_bInfiniteStamina[i];
                        }
                    }

                    PrintToChat(client, "[DevMenu]: 已切换所有幸存者的无限体力.");
                }

                default:
                {
                    char sUserid[16];
                    menu.GetItem(itemNum, sUserid, sizeof(sUserid));
                    int iTarget = GetClientOfUserId(StringToInt(sUserid));
                    if (iTarget > 0 && iTarget <= MaxClients && IsClientInGame(iTarget) && IsPlayerAlive(iTarget))
                    {
                        g_bInfiniteStamina[iTarget] = !g_bInfiniteStamina[iTarget];
                        PrintToChat(client, "[DevMenu] 已 %s 无限体力: %N", g_bInfiniteStamina[iTarget] ? "开启" : "关闭", iTarget);
                    }
                }
            }

			g_iStaminaMenuPos[client] = menu.Selection;
			Stamina_TargetSelect(client);
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

// CSDKPlayerShared *m_Shared in class CNMRiH_Player is at offset 4812.
MRESReturn DTR_SetStamina(Address pThis, DHookParam hParams)
{
    static int s_iOff_m_Shared = -1;
    if (s_iOff_m_Shared == -1)
    {
        s_iOff_m_Shared = FindSendPropInfo("CNMRiH_Player", "m_Shared");
        if (s_iOff_m_Shared <= 0)
            return MRES_Ignored;
    }

    static ConVar sv_max_stamina;
    if (sv_max_stamina == null)
    {
        sv_max_stamina = FindConVar("sv_max_stamina");
        if (sv_max_stamina == null)
            return MRES_Ignored;
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;

        if (!g_bInfiniteStamina[i])
            continue;

        Address m_pPlayer = view_as<Address>(LoadFromAddress(pThis + view_as<Address>(g_iOff_m_pPlayer), NumberType_Int32));
        if (m_pPlayer != GetEntityAddress(i))
            continue;

        hParams.Set(1, sv_max_stamina.FloatValue);
        return MRES_ChangedHandled;      
    }

    return MRES_Ignored;
}
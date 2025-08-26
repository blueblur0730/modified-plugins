
void MiscSelected(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	MiscCookieSelected(client);
}

void MiscCookieSelected(int client)
{
    Menu menu = new Menu(MiscPrefsMenuHandler);

	char sBuffer[256];
    FormatEx(sBuffer, sizeof(sBuffer), "%T", "MenuTitle", client);
    menu.SetTitle(sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%T", "CurrentRange_Menu", client, g_hCookie.GetInt(client, g_iHideRange[client]));
	menu.AddItem("", sBuffer, ITEMDRAW_DISABLED);

	char info[16];
	IntToString(BIT_TOGGLE_TRANSMIT, info, sizeof(info));
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "ToggleHide_Menu", client, (CheckPrefsBit(client, BIT_TOGGLE_TRANSMIT) ? "Yes" : "No"), client);
	menu.AddItem(info, sBuffer, ITEMDRAW_DEFAULT);

	IntToString(BIT_TOGGLE_TRANSMIT_WHEN_HOLDING_MED, info, sizeof(info));
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "ToggleHideMed_Menu", client, (CheckPrefsBit(client, BIT_TOGGLE_TRANSMIT_WHEN_HOLDING_MED) ? "Yes" : "No"), client);
	menu.AddItem(info, sBuffer, ITEMDRAW_DEFAULT);

	IntToString(BIT_TOGGLE_TRANSMIT_WHEN_BLACK_WHITE, info, sizeof(info));
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "ToggleHideBlackWhite_Menu", client, (CheckPrefsBit(client, BIT_TOGGLE_TRANSMIT_WHEN_BLACK_WHITE) ? "Yes" : "No"), client);
	menu.AddItem(info, sBuffer, ITEMDRAW_DEFAULT);

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

static int MiscPrefsMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            int client = param1;
            int option = param2;

            // item info - bit (int)
            char info[16];
            menu.GetItem(option, info, sizeof(info));

            int reverseBit = StringToInt(info);

            char newValue[16];
            IntToString(reverseBit ^ GetCookieValue(client), newValue, sizeof(newValue));

            g_hCookie_Misc.Set(client, newValue);
            MiscCookieSelected(client);
        }

		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
				ShowCookieMenu(param1);
		}

		case MenuAction_End:
			delete menu;
    }
    return 0;
}
#if defined _l4d2_hit_feedback_commands_included
 #endinput
#endif
#define _l4d2_hit_feedback_commands_included

Action Command_HM(int client, int args)
{
	if (!g_hCvEnable.BoolValue)
	{
		PrintToChat(client, "\x04[提示]\x03击中反馈被禁用了!");	   //聊天窗提示.
		return Plugin_Handled;
	}

	HMMenu(client);
	return Plugin_Handled;
}

Action HMMenu(int client)
{
	Menu menu = CreateMenu(Callback_HMMenu);
	SetMenuTitle(menu, "==================\n请选择你的命中反馈风格\n==================");
	AddMenuItem(menu, "option1", "原版");
	AddMenuItem(menu, "option2", "屏幕字幕+聊天窗提示");
	AddMenuItem(menu, "option3", "关闭");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return Plugin_Continue;
}

int Callback_HMMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Select)
	{
		char item[64];
		GetMenuItem(menu, itemNum, item, sizeof(item));
		if (StrEqual(item, "option1"))
		{
			g_iStyle[client] = 1;
			PrintToChat(client, "\x04[提示]\x03击中反馈风格为\x05原版");	//聊天窗提示.
		}

		else if (StrEqual(item, "option2"))
		{
			g_iStyle[client] = 2;
			PrintToChat(client, "\x04[提示]\x03击中反馈风格为\x05屏幕字幕+聊天窗提示");	   //聊天窗提示.
		}

		else if (StrEqual(item, "option3"))
		{
			g_iStyle[client] = 3;
			PrintToChat(client, "\x04[提示]\x03击中反馈风格为\x05关闭");	//聊天窗提示.
		}
	}
	return 0;
}
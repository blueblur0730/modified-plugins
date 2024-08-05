#if defined _l4d2_hit_feedback_menu_included
 #endinput
#endif
#define _l4d2_hit_feedback_menu_included

Action Command_HM(int client, int args)
{
	MainMenu(client);
	return Plugin_Handled;
}

void MainMenu(int client)
{
	Menu menu = new Menu(Callback_MainMenu);
	menu.SetTitle("==================\nManage your hit feedback style\n==================");
	menu.AddItem("option1", "HitMarker");
	menu.AddItem("option2", "Damage Number");
	menu.ExitButton = true;
	menu.Display(menu, client, 20);
}

int Callback_MainMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_End)
		delete menu;

	if (action == MenuAction_Select)
	{
		char item[64];
		menu.GetItem(menu, itemNum, item, sizeof(item));
		switch (item)
		{
			case "option1":
			{
				Menu hMenu = new Menu(Callback_HitMarker);
				hMenu.SetTitle("==================\nChoose your hitmarker style\n==================");
				hMenu.AddItem("option1", "Static");
				hMenu.AddItem("option2", "Animated");
				hMenu.ExitButton = true;
				hMenu.Display(hMenu, client, 20);
				return Plugin_Handled;
			}

			case "option2":
			{
				Menu hMenu = new Menu(Callback_DamageNumber);
				hMenu.SetTitle("==================\nManage your damage number style\n=");
				hMenu.AddItem("option1", "Hide");
				hMenu.AddItem("option2", "Scale");
				hMenu.AddItem("option3", "Fade Distant");
				hMenu.AddItem("option4", "Color");
				hMenu.ExitButton = true;
				hMenu.Display(hMenu, client, 20);
				return Plugin_Handled;
			}
		}
	}
	return 0;
}

int Callback_HitMarker(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_End)
		delete menu;

	if (action == MenuAction_Cancel)
		MainMenu(client);

	if (action == MenuAction_Select)
	{
		char item[64];
		menu.GetItem(menu, itemNum, item, sizeof(item));
		switch (item)
		{
			case "option1":
			{
				Menu hMenu = new Menu(Callback_Static);
				hMenu.SetTitle("==================\nChoose your static hitmarker style\n==================");
				hMenu.AddItem("option1", "Red");
				hMenu.AddItem("option3", "Blue");
				hMenu.AddItem("option4", "Yellow");
				hMenu.ExitButton = true;
				hMenu.Display(hMenu, client, 20);
				return Plugin_Handled;
			}

			case "option2":
			{
				g_iStyle[client] = Style_Animated;
				CPrintToChat(client, "%t", "AnimatedStyle");
			}
		}
	}

	return 0;
}

int Callback_Static(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_End)
		delete menu;

	if (action == MenuAction_Cancel)
		MainMenu(client);

	if (action == MenuAction_Select)
	{
		char item[64];
		menu.GetItem(menu, itemNum, item, sizeof(item));
		switch (item)
		{
			case "option1":
			{

			}
			case "option2":
			{

			}
			case "option3":
			{
				
			}
		}
		g_iStyle[client] = Style_Static;
		CPrintToChat(client, "%t", "StaticlStyle");
	}
}
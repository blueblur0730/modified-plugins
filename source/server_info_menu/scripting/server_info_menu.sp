#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define CONFIG_PATH		   "configs/server_info_menu.cfg"
#define TRANSLATION_PATH   "server_info_menu.phrases"
#define MAX_MESSAGE_LENGTH 250

KeyValues
	Kv;

ArrayList
	g_harrayDescription,
	g_harrayCmd;

char
	g_sBuffer1[32],
	g_sBuffer2[32];

public Plugin myinfo =
{
	name = "Server Info Menu",
	description = "Integrated menu to query various info.",
	author	= "blueblur",
	version	= "1.0",
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_info", Cmd_OpenMenu, "Open the info menu");

	char sBuffer[128];
	Kv = new KeyValues("Info");
	BuildPath(Path_SM, sBuffer, 128, CONFIG_PATH);
	Kv.SetEscapeSequences(true);	// Allow newline characters to be read.

	if (!Kv.ImportFromFile(sBuffer))
		SetFailState("File %s may be missed!", CONFIG_PATH);

	LoadTranslations(TRANSLATION_PATH);
}

public Action Cmd_OpenMenu(int client, int arg)
{
	Menu menu = new Menu(Menu_HandlerFunction);
	LoadKeyValues();
	SetGlobalTransTarget(client);

	char title[64], sBuffer1[64], sBuffer2[64], sBuffer3[64];
	Format(title, sizeof(title), "%t", "title_main");
	Format(sBuffer1, sizeof(sBuffer1), "%t", "Player");
	Format(sBuffer2, sizeof(sBuffer2), "%t", "Server");
	Format(sBuffer3, sizeof(sBuffer3), "%t", "Command");
	SetMenuTitle(menu, title);

	menu.AddItem("a", sBuffer1);
	menu.AddItem("b", sBuffer2);
	menu.AddItem("c", sBuffer3);

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

int Menu_HandlerFunction(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_End:
			delete menu;
		case MenuAction_Select:
		{
			char sItem[2];
			if (menu.GetItem(itemNum, sItem, sizeof(sItem)))
			{
				switch (sItem[0])
				{
					case 'a': FakeClientCommand(client, g_sBuffer1);
					case 'b': FakeClientCommand(client, g_sBuffer2);
					case 'c': MenuCommands(client);
				}
			}

			delete g_harrayCmd;
		}
	}
	return 0;
}

void MenuCommands(int client)
{
	Menu menu = new Menu(MenuCommand_HandlerFunction);
	SetGlobalTransTarget(client);

	char title[64];
	Format(title, sizeof(title), "%t", "title_command");
	SetMenuTitle(menu, title);

	for (int i = 0; i < g_harrayDescription.Length; i++)
	{
		char sBuffer[64], iBuffer[64];
		g_harrayDescription.GetString(i, sBuffer, sizeof(sBuffer));
		Format(sBuffer, sizeof(sBuffer), "%t", sBuffer);
		IntToString(i, iBuffer, sizeof(iBuffer));
		menu.AddItem(iBuffer, sBuffer);
	}

	delete g_harrayDescription;
}

int MenuCommand_HandlerFunction(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_End:
			delete menu;
		case MenuAction_Select:
		{
			char sItem[16];
			if (menu.GetItem(itemNum, sItem, sizeof(sItem)))
			{
				g_harrayCmd.GetString(itemNum, sItem, sizeof(sItem));
				FakeClientCommand(client, sItem);
			}
		}
	}
	return 0;
}

void LoadKeyValues()
{
	char cBuffer[64];
	g_harrayDescription = new ArrayList(ByteCountToCells(MAX_MESSAGE_LENGTH));
	g_harrayCmd			= new ArrayList(ByteCountToCells(MAX_MESSAGE_LENGTH));

	Kv.Rewind();
	if (Kv.JumpToKey("Players"))
		Kv.GetString("Players", g_sBuffer1, sizeof(g_sBuffer1));

	if (Kv.JumpToKey("Server_Status"))
		Kv.GetString("Server_Status", g_sBuffer2, sizeof(g_sBuffer2));

	if (Kv.JumpToKey("Descriptions") && Kv.GotoFirstSubKey())
	{
		do
		{
			Kv.GetString(NULL_STRING, cBuffer, sizeof(cBuffer));
			g_harrayDescription.PushString(cBuffer);
		}
		while (Kv.GotoNextKey(false));
	}

	if (Kv.JumpToKey("Commands") && Kv.GotoFirstSubKey())
	{
		do
		{
			Kv.GetString(NULL_STRING, cBuffer, sizeof(cBuffer));
			g_harrayCmd.PushString(cBuffer);
		}
		while (Kv.GotoNextKey(false));
	}

	delete Kv;
}
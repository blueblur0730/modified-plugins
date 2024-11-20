#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION "1.0"
#define CONFIG_PATH "configs/command_menu.cfg"
char g_sPath[64];
KeyValues kv[MAXPLAYERS + 1] = { null, ... };

public Plugin myinfo =
{
	name = "[Any] Command Menu",
	author = "blueblur",
	description = "Quick Access to various commands cuz you are a lazy guy :)", // jesus i hate kv + menu go fuck yourself
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
}

public void OnPluginStart()
{    
    BuildPath(Path_SM, g_sPath, sizeof(g_sPath), CONFIG_PATH);
    if (!FileExists(g_sPath)) SetFailState("Config file \"" ...CONFIG_PATH... "\" not found.");

    CreateConVar("command_menu_version", PLUGIN_VERSION, "The version of the Command Menu plugin.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    RegConsoleCmd("sm_menu", Cmd_CommandMenu, "Opens the Command Menu.");
}

Action Cmd_CommandMenu(int client, int args)
{
	if (!kv[client])
	{
		kv[client] = new KeyValues("");
		kv[client].ImportFromFile(g_sPath);
	}

    kv[client].Rewind();
    static char sBuffer[128];
    Menu menu = new Menu(MenuHandler_CommandMenu);
    menu.SetTitle("查看或点击访问指令");

    if (kv[client].GotoFirstSubKey(false))
    {
		do
		{
            kv[client].GetString(NULL_STRING, sBuffer, sizeof(sBuffer));
            menu.AddItem(sBuffer, sBuffer);
		}
		while (kv[client].GotoNextKey(false));
    }

    menu.ExitBackButton = true;
    menu.Display(client, 30);
    return Plugin_Handled;
}

void MenuHandler_CommandMenu(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char sBuffer[128];
            menu.GetItem(param2, sBuffer, sizeof(sBuffer));
            FakeClientCommand(param1, sBuffer);
        }

        case MenuAction_End:
            delete menu;
    }
}
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION "1.1"
#define CONFIG_PATH "configs/command_menu.cfg"
#define TRANSLATION_FILE "command_menu.phrases"

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

    LoadTranslation(TRANSLATION_FILE);

    CreateConVar("command_menu_version", PLUGIN_VERSION, "The version of the Command Menu plugin.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    RegConsoleCmd("sm_menu", Cmd_CommandMenu, "Opens the Command Menu.");
}

public void OnPluginEnd()
{
    for (int i = 1; i < MaxClients; i++)
    {
        if (kv[i]) delete kv[i];
    }
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
    FormatEx(sBuffer, sizeof(sBuffer), "%T", "MenuTitle", client);
    Menu menu = new Menu(MenuHandler_CommandMenu);
    menu.SetTitle(sBuffer);

    if (kv[client].GotoFirstSubKey(false))
    {
		do
		{
            static char sTranslated[512], sKey[128];
            kv[client].GetString(NULL_STRING, sKey, sizeof(sKey));
            !TranslationPhraseExists(sKey) ?
            FormatEx(sTranslated, sizeof(sTranslated), "%T", "UnknownCommand", client) :
            FormatEx(sTranslated, sizeof(sTranslated), "%T", sKey, client);

            menu.AddItem(sKey, sTranslated);
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

stock void LoadTranslation(const char[] translation)
{
	char sPath[PLATFORM_MAX_PATH], sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}
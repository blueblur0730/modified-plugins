#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <nmrih_objective>

#define PLUGIN_VERSION "1.2"

public Plugin myinfo = 
{
    name = "[NMRiH] Objective Manager",
    author = "blueblur",
    description = "Overall Objective Manager for NMRiH.",
    version = PLUGIN_VERSION,
    url = "https://github.com/blueblur0730/modified-plugins"
};

#include "nmrih_objective_manager/utils.sp"
#include "nmrih_objective_manager/current_obj.sp"
#include "nmrih_objective_manager/all_obj.sp"
#include "nmrih_objective_manager/manage_obj.sp"

public void OnPluginStart()
{
    LoadTranslation("nmrih_objective_manager.phrases");
    CreateConVar("nmrih_objective_manager_version", PLUGIN_VERSION, "Version of the Objective Manager plugin.", FCVAR_DONTRECORD | FCVAR_NOTIFY);

    RegConsoleCmd("sm_objmenu", Command_ObjectiveMenu, "Open the objective menu.");
}

Action Command_ObjectiveMenu(int client, int args)
{
    if (!IsClientInGame(client))
        return Plugin_Handled;
    
    ShowObjectiveMenu(client);
    return Plugin_Handled;
}

void ShowObjectiveMenu(int client)
{
    Menu menu = new Menu(ObjectiveMenuHandler);
    menu.SetTitle("%T", "Menu_Main", client);

    char buffer[256];
    Format(buffer, sizeof(buffer), "%T", "Menu_ViewCurrentObjDetail", client);
    menu.AddItem("1", buffer);

    Format(buffer, sizeof(buffer), "%T", "Menu_ViewAllObjDetail", client);
    menu.AddItem("2", buffer);

    Format(buffer, sizeof(buffer), "%T", "Menu_ManageObj", client);
    menu.AddItem("3", buffer, IsClientAdmin(client, ADMFLAG_ROOT) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

void ObjectiveMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (itemNum)
			{
                case 0:
                {
                    ShowCurrentObjectives(client);
                }

                case 1:
                {
                    ShowAllObjectives(client);
                }

                case 2:
                {
                    if (IsClientAdmin(client, ADMFLAG_ROOT))
                    {
                        ShowManageObjectivesMenu(client);
                    }
                }
            }
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
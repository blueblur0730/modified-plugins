#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <nmrih_objective>

#define NMR_MAXPLAYERS 9

#define PLUGIN_VERSION "1.1"

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
    menu.SetTitle("Objective Menu");
    menu.AddItem("1", "View Current Objectives' Detail");
    menu.AddItem("2", "View all Objectives' Detail");

    if (IsClientAdmin(client, ADMFLAG_ROOT))
    {
        menu.AddItem("3", "Manage Objectives");
    }

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
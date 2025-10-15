
void ShowManageObjectivesMenu(int client)
{
    Menu menu = new Menu(ManageObjectivesMenuHandler);
    menu.SetTitle("Manage Objectives:");
    menu.AddItem("1", "Complete Current Objective and Start the Next One");
    menu.AddItem("2", "Fail Current Objective");
    menu.AddItem("3", "Update All Objective Boundary");

    Objective obj = ObjectiveManager.Instance()._pCurrentObjective;
    if (obj.IsNull())
    {
        PrintToChat(client, "[Objective Manager] There is no current objective.");
        return;
    }

    obj.IsEndObjective() ?
    menu.AddItem("4", "Finish The Mission") :
    menu.AddItem("4", "Finish The Mission (Currently not in End Objective)", ITEMDRAW_DISABLED);

    menu.AddItem("5", "Clear All Objectives");
    
    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

void ManageObjectivesMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            switch (itemNum)
            {
                case 0:
                {
                    Menu submenu = new Menu(CompleteObjectivesMenuHandler);
                    submenu.SetTitle("Are you sure to complete the current objective and start next one?");
                    submenu.AddItem("yes", "Yes");
                    submenu.AddItem("no", "No");
                    submenu.Display(client, MENU_TIME_FOREVER);
                }

                case 1:
                {
                    Menu submenu = new Menu(FailCurrentObjectivesMenuHandler);
                    submenu.SetTitle("Are you sure to fail the current objective?");
                    submenu.AddItem("yes", "Yes");
                    submenu.AddItem("no", "No");
                    submenu.Display(client, MENU_TIME_FOREVER);
                }

                case 2:
                {
                    Menu submenu = new Menu(UpdateAllObjectiveBoundaryMenuHandler);
                    submenu.SetTitle("Are you sure to update all objective boundary?");
                    submenu.AddItem("yes", "Yes");
                    submenu.AddItem("no", "No");
                    submenu.Display(client, MENU_TIME_FOREVER);
                }

                case 3:
                {
                    Menu submenu = new Menu(FinishTheMissionMenuHandler);
                    submenu.SetTitle("Are you sure to finish the mission?");
                    submenu.AddItem("yes", "Yes");
                    submenu.AddItem("no", "No");
                    submenu.Display(client, MENU_TIME_FOREVER);
                }

                case 4:
                {
                    Menu submenu = new Menu(ClearAllObjectivesMenuHandler);
                    submenu.SetTitle("Are you sure to clear all objectives? (Think Twice!)");
                    submenu.AddItem("yes", "Yes");
                    submenu.AddItem("no", "No");
                    submenu.Display(client, MENU_TIME_FOREVER);
                }
            }
        }

        case MenuAction_Cancel:
        {
            if (itemNum == MenuCancel_Exit)
                return;

            ShowObjectiveMenu(client);
        }

        case MenuAction_End:
            delete menu;
    }
}

void CompleteObjectivesMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            switch (itemNum)
            {
                case 0:
                {
                    ObjectiveManager.CompleteCurrentObjective();
                    PrintToChat(client, "[Objective Manager] Completed the current objective.");
                }

                case 1:
                {
                    ShowManageObjectivesMenu(client);
                }
            }
        }

        case MenuAction_End:
            delete menu;
    }
}

void FailCurrentObjectivesMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            switch (itemNum)
            {
                case 0:
                {
                    ObjectiveManager.FailCurrentObjective();
                    PrintToChat(client, "[Objective Manager] Failed the current objective.");
                }

                case 1:
                {
                    ShowManageObjectivesMenu(client);
                }
            }
        }

        case MenuAction_End:
            delete menu;
    }
}

void UpdateAllObjectiveBoundaryMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            switch (itemNum)
            {
                case 0:
                {
                    ObjectiveManager.UpdateObjectiveBoundaries();
                    PrintToChat(client, "[Objective Manager] Updated all objective boundary.");
                }

                case 1:
                {
                    ShowManageObjectivesMenu(client);
                }
            }
        }

        case MenuAction_End:
            delete menu;
    }
}

void FinishTheMissionMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            switch (itemNum)
            {
                case 0:
                {
                    ObjectiveManager.Finish();
                    PrintToChat(client, "[Objective Manager] Finished the mission.");
                }

                case 1:
                {
                    ShowManageObjectivesMenu(client);
                }
            }
        }

        case MenuAction_End:
            delete menu;
    }
}

void ClearAllObjectivesMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            switch (itemNum)
            {
                case 0:
                {
                    ObjectiveManager.Clear();
                    PrintToChat(client, "[Objective Manager] Cleared all objectives.");
                }

                case 1:
                {
                    ShowManageObjectivesMenu(client);
                }
            }
        }

        case MenuAction_End:
            delete menu;
    }
}
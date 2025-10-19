
void ShowManageObjectivesMenu(int client)
{
    Menu menu = new Menu(ManageObjectivesMenuHandler);
    menu.SetTitle("%T", "Menu_ManageObjectives", client);

    char buffer[256];
    Format(buffer, sizeof(buffer), "%T", "Menu_CompleteAndStartNextOne", client);
    menu.AddItem("1", buffer);

    Format(buffer, sizeof(buffer), "%T", "Menu_FailCurrentOne", client);
    menu.AddItem("2", buffer);

    Format(buffer, sizeof(buffer), "%T", "Menu_UpdateAllObjectiveBoundary", client);
    menu.AddItem("3", buffer);

    Objective obj = ObjectiveManager.Instance()._pCurrentObjective;
    if (!obj.IsNull())
    {
        if (obj.IsEndObjective())
        {
            Format(buffer, sizeof(buffer), "%T", "Menu_FinishTheMission", client);
            menu.AddItem("4", buffer);
        }
        else
        {
            Format(buffer, sizeof(buffer), "%T %T", "Menu_FinishTheMission", client, "Menu_CurrentlyNotEndObjective", client);
            menu.AddItem("4", buffer, ITEMDRAW_DISABLED);
        }
    }

    Format(buffer, sizeof(buffer), "%T", "Menu_ClearAllObjectives", client);
    menu.AddItem("5", buffer);
    
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
                    submenu.SetTitle("%T", "Menu_AreYouSure1", client);

                    char buffer[64];
                    Format(buffer, sizeof(buffer), "%T", "Yes", client);
                    submenu.AddItem("yes", buffer);

                    Format(buffer, sizeof(buffer), "%T", "No", client);
                    submenu.AddItem("no", buffer);

                    submenu.Display(client, MENU_TIME_FOREVER);
                }

                case 1:
                {
                    Menu submenu = new Menu(FailCurrentObjectivesMenuHandler);

                    char buffer[64];
                    submenu.SetTitle("%T", "Menu_AreYouSure2", client);
                    Format(buffer, sizeof(buffer), "%T", "Yes", client);
                    submenu.AddItem("yes", buffer);

                    Format(buffer, sizeof(buffer), "%T", "No", client);
                    submenu.AddItem("no", buffer);

                    submenu.Display(client, MENU_TIME_FOREVER);
                }

                case 2:
                {
                    Menu submenu = new Menu(UpdateAllObjectiveBoundaryMenuHandler);
                    submenu.SetTitle("%T", "Menu_AreYouSure3", client);

                    char buffer[64];
                    submenu.SetTitle("%T", "Menu_AreYouSure2", client);
                    Format(buffer, sizeof(buffer), "%T", "Yes", client);
                    submenu.AddItem("yes", buffer);

                    Format(buffer, sizeof(buffer), "%T", "No", client);
                    submenu.AddItem("no", buffer);

                    submenu.Display(client, MENU_TIME_FOREVER);
                }

                case 3:
                {
                    Menu submenu = new Menu(FinishTheMissionMenuHandler);
                    submenu.SetTitle("%T", "Menu_AreYouSure4", client);

                    char buffer[64];
                    submenu.SetTitle("%T", "Menu_AreYouSure2", client);
                    Format(buffer, sizeof(buffer), "%T", "Yes", client);
                    submenu.AddItem("yes", buffer);

                    Format(buffer, sizeof(buffer), "%T", "No", client);
                    submenu.AddItem("no", buffer);

                    submenu.Display(client, MENU_TIME_FOREVER);
                }

                case 4:
                {
                    Menu submenu = new Menu(ClearAllObjectivesMenuHandler);
                    submenu.SetTitle("%T", "Menu_AreYouSure5", client);

                    char buffer[64];
                    submenu.SetTitle("%T", "Menu_AreYouSure2", client);
                    Format(buffer, sizeof(buffer), "%T", "Yes", client);
                    submenu.AddItem("yes", buffer);

                    Format(buffer, sizeof(buffer), "%T", "No", client);
                    submenu.AddItem("no", buffer);

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
                    PrintToChat(client, "%t", "CompletedCurrentObjective");
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
                    PrintToChat(client, "%t", "FailedCurrentObjective");
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
                    PrintToChat(client, "%t", "UpdatedAllObjectiveBoundary");
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
                    PrintToChat(client, "%t", "FinishedMission");
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
                    PrintToChat(client, "%t", "ClearedAllObjectives");
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
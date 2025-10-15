
void ShowAllObjectives(int client)
{
    ObjectiveManager manager = ObjectiveManager.Instance();
    if (manager.IsNull())
    {
        PrintToChat(client, "[Objective Manager] Manager instance is null, cannot show the menu.");
        return;
    }

    Menu menu = new Menu(ShowAllObjectivesMenuHandler);
    menu.SetTitle("Objectives Detail");

    char buffer[256];
    int obj_count = manager._iObjectivesCount;
    Format(buffer, sizeof(buffer), "Objectives in Total: %d", obj_count);
    menu.AddItem("obj_count", buffer, ITEMDRAW_DISABLED);

    int chain_count = manager._iObjectiveChainCount;
    Format(buffer, sizeof(buffer), "Objective Chains(Links) in Total: %d", chain_count);
    menu.AddItem("chain_count", buffer, ITEMDRAW_DISABLED);

    if (obj_count > 0)
    {
        menu.AddItem("all_obj", "View Every Objective->");
    }

    if (chain_count > 0)
    {
        menu.AddItem("all_chain", "View Every Objective Chain->");
    }

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

void ShowAllObjectivesMenuHandler(Menu menu, MenuAction action, int client, int item)
{
	switch (action)
	{
		case MenuAction_Select:
		{
            ObjectiveManager manager = ObjectiveManager.Instance();
            if (manager.IsNull())
            {
                PrintToChat(client, "[Objective Manager] Manager instance is null, cannot show the menu.");
                return;
            }

            char info[256];
            menu.GetItem(item, info, sizeof(info));

            if (strcmp(info, "all_obj") == 0)
            {
                ShowObjectiveListMenu(client);
            }
            else if (strcmp(info, "all_chain") == 0)
            {
                char buffer[256];
                UtlVector chains = manager._pObjectiveChainVector;
                int chain_count = manager._iObjectiveChainCount;

                if (!chains.IsNull())
                {
                    Menu submenu = new Menu(DummyHandler2);
                    submenu.SetTitle("All Objective Chain IDs:");

                    for (int i = 1; i < chain_count; i++)
                    {
                        int chainID = chains.Get(i - 1);

                        Format(buffer, sizeof(buffer), "Index: %d | ID: %d", i - 1, chainID);
                        submenu.AddItem("", buffer, ITEMDRAW_DISABLED);
                    }

                    submenu.ExitBackButton = true;
                    submenu.Display(client, MENU_TIME_FOREVER);
                }
                else
                {
                    PrintToChat(client, "[Objective Manager] The chain list is null.");
                }
            }
        }

        case MenuAction_Cancel:
        {
            if (item == MenuCancel_Exit)
                return;

            ShowObjectiveMenu(client);
        }

		case MenuAction_End:
			delete menu;
    }
}

void ShowObjectiveListMenu(int client)
{
    char buffer[256];
    ObjectiveManager manager = ObjectiveManager.Instance();
    if (manager.IsNull())
    {
        PrintToChat(client, "[Objective Manager] Manager instance is null, cannot show the menu.");
        return;
    }

    int obj_count = manager._iObjectivesCount;
    UtlVector objectives = manager._pObjectivesVector;
    Objective current_obj = manager._pCurrentObjective;

    int current_obj_id = -1;
    if (!current_obj.IsNull())
    {
        current_obj_id = current_obj.m_iId;
    }

    if (obj_count != 0 && !objectives.IsNull())
    {
        Menu submenu = new Menu(AllObjectiveMenuHandler);
        submenu.SetTitle("Select an Objective to View:");

        for (int i = 1; i < obj_count; i++)
        {
            Objective obj = objectives.Get(i - 1);
            if (obj.IsNull())
                continue;

            obj._sName.ToCharArray(buffer, sizeof(buffer));

            int id = obj.m_iId;
            if (id == current_obj_id)
            {
                Format(buffer, sizeof(buffer), "%s (Current)", buffer);
            }
            
            static char sId[8];
            IntToString(id, sId, sizeof(sId));
            submenu.AddItem(sId, buffer);
        }

        submenu.ExitBackButton = true;
        submenu.Display(client, MENU_TIME_FOREVER); 
    }
    else
    {
        PrintToChat(client, "[Objective Manager] There's no objective, or the list is null.");
    }
}

void AllObjectiveMenuHandler(Menu menu, MenuAction action, int client, int item)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[8], name[256];
            menu.GetItem(item, info, sizeof(info), _, name, sizeof(name));

            ShowSelectedObjectiveMenu(client, info, name);
        }

        case MenuAction_Cancel:
        {
            if (item == MenuCancel_Exit)
                return;

            ShowAllObjectives(client);
        }
            
        case MenuAction_End:
            delete menu;
    }
}

void ShowSelectedObjectiveMenu(int client, const char[] info, const char[] name)
{
    int id = StringToInt(info);
    Objective obj = ObjectiveManager.GetObjectiveById(id);
    if (obj.IsNull())
    {
        PrintToChat(client, "[Objective Manager] Objective instance is null, cannot show the menu.");
        return;
    }

    char buffer[256];
    Menu submenu = new Menu(SelectedObjectiveMenuHandler);
    submenu.SetTitle("Selected Objective's Detail");

    Format(buffer, sizeof(buffer), "Name: %s", name);
    submenu.AddItem(name, buffer, ITEMDRAW_DISABLED);

    obj._sDescription.ToCharArray(buffer, sizeof(buffer));
    submenu.AddItem(buffer, "Show Description->");

    Format(buffer, sizeof(buffer), "Objective Id: %d", id);
    submenu.AddItem("id", buffer, ITEMDRAW_DISABLED);

    Format(buffer, sizeof(buffer), "%d", id);
    submenu.AddItem(buffer, "", ITEMDRAW_IGNORE);    // pass the id for the callback.

    int link_count = obj._iLinksCount;
    Format(buffer, sizeof(buffer), "Link Count: %d", link_count);
    submenu.AddItem("link_count", buffer, ITEMDRAW_DISABLED);

    int entity_count = obj._iEntitysCount;
    Format(buffer, sizeof(buffer), "Entity Count: %d", entity_count);
    submenu.AddItem("entity_count", buffer, ITEMDRAW_DISABLED);

    bool isend = obj.IsEndObjective();
    Format(buffer, sizeof(buffer), "Is End Objective: %s", isend ? "Yes" : "No");
    submenu.AddItem("is_end", buffer, ITEMDRAW_DISABLED);

    bool isanti = obj._bIsAntiObjective;
    Format(buffer, sizeof(buffer), "Is Anti Objective: %s", isanti ? "Yes" : "No");
    submenu.AddItem("is_anti", buffer, ITEMDRAW_DISABLED);

    obj._sObjectiveBoundaryName.ToCharArray(buffer, sizeof(buffer));
    Format(buffer, sizeof(buffer), "Objective Boundary Name: %s", buffer);
    submenu.AddItem("boundary", buffer, ITEMDRAW_DISABLED);

    ObjectiveBoundary boundary = obj.GetObjectiveBoundary();
    if (!boundary.IsNull())
    {
        int boundray_entity = GetEntityFromAddress(boundary.addr);
        if (boundray_entity > MaxClients && IsValidEntity(boundray_entity))
        {
            Format(buffer, sizeof(buffer), "Boundary Entity Index: %d", boundray_entity);
            submenu.AddItem("boundary_entity", buffer, ITEMDRAW_DISABLED);
        }
    }

    Format(buffer, sizeof(buffer), "Show All Links->");
    submenu.AddItem("links", buffer, link_count != 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    Format(buffer, sizeof(buffer), "Show All Entities->");
    submenu.AddItem("entities", buffer, entity_count != 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    if (IsClientAdmin(client, ADMFLAG_ROOT))
    {
        submenu.AddItem("update", "Update Boundary->");
        submenu.AddItem("control_boundray", "Control Objective Boundary->");
    }

    submenu.ExitBackButton = true;
    submenu.Display(client, MENU_TIME_FOREVER);
}

void SelectedObjectiveMenuHandler(Menu menu, MenuAction action, int client, int item)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[256];
            menu.GetItem(item, info, sizeof(info));

            if (item == 1)
            {
                char mapname[64];
                GetCurrentMap(mapname, sizeof(mapname));

                if (IsOfficialMap(mapname))
                {
                    StripNumberSign(info, sizeof(info));

                    char language[32];
                    GetLanguageInfo(GetClientLanguage(client), _, _, language, sizeof(language));

                    char input[256], output[256];
                    Format(input, sizeof(input), "maps/%s_%s.txt", mapname, language);
                    Format(output, sizeof(output), "resource/%s_%s.txt", mapname, language);
                    
                    if (!ConvertFile_UTF16LE_UTF8(input, output))
                    {
                        PrintToChat(client, "[Objective Manager] No description file found for this map and language.");
                    }
                    else
                    {
                        if (FileExists(output))
                        {
                            StringMap map = new StringMap();
                            ParseFile(output, true, map);

                            if (map.ContainsKey(info))
                            {
                                char value[512];
                                map.GetString(info, value, sizeof(value));

                                char name[256], id[8];
                                menu.GetItem(0, name, sizeof(name));
                                menu.GetItem(3, id, sizeof(id));

                                Menu submenu = new Menu(DummyHandler3);
                                submenu.SetTitle("Objective Description:");
                                submenu.AddItem("desc", value, ITEMDRAW_DISABLED);
                                submenu.AddItem(id, "", ITEMDRAW_IGNORE);
                                submenu.AddItem(name, "", ITEMDRAW_IGNORE);
                                submenu.ExitBackButton = true;
                                submenu.Display(client, MENU_TIME_FOREVER);
                            }
                            else
                            {
                                PrintToChat(client, "[Objective Manager] No description found for this objective.");
                            }

                            delete map;
                            DeleteFile(output);
                        }
                        else
                        {
                            PrintToChat(client, "[Objective Manager] No description found for this objective, decoded file missing.");
                        }
                    }
                }
                else
                {
                    char name[256], id[8];
                    menu.GetItem(0, name, sizeof(name));
                    menu.GetItem(3, id, sizeof(id));

                    Menu submenu = new Menu(DummyHandler3);
                    submenu.SetTitle("Objective Description:");
                    submenu.AddItem("desc", info, ITEMDRAW_DISABLED);
                    submenu.AddItem(id, "", ITEMDRAW_IGNORE);
                    submenu.AddItem(name, "", ITEMDRAW_IGNORE);
                    submenu.ExitBackButton = true;
                    submenu.Display(client, MENU_TIME_FOREVER);
                }
            }
            else if (strcmp(info, "links") == 0)
            {
                char sIndex[8];
                menu.GetItem(3, sIndex, sizeof(sIndex));

                int iIndex = StringToInt(sIndex);
                Objective obj = ObjectiveManager.GetObjectiveById(iIndex);
                if (obj.IsNull())
                {
                    PrintToChat(client, "[Objective Manager] There is no objective with id: %d.", iIndex);
                    return;
                }

                int count = obj._iLinksCount;
                UtlVector links = obj._pLinksVector;
                if (links.IsNull())
                {
                    PrintToChat(client, "[Objective Manager] This objective's link instance is null.");
                    return;
                }

                Menu linkmenu = new Menu(DummyHandler4);
                linkmenu.SetTitle("Objective Link List:");
                for (int i = 1; i <= count; i++)
                {
                    static char buffer[64];
                    int linkId = links.Get(i - 1);
                    Format(buffer, sizeof(buffer), "Index %d | Link ID: %d", i - 1, linkId);
                    linkmenu.AddItem("", buffer, ITEMDRAW_DISABLED);
                }

                char name[256];
                menu.GetItem(0, name, sizeof(name));

                linkmenu.AddItem(sIndex, "", ITEMDRAW_IGNORE);
                linkmenu.AddItem(name, "", ITEMDRAW_IGNORE);
                linkmenu.ExitBackButton = true;
                linkmenu.Display(client, MENU_TIME_FOREVER);
            }
            else if (strcmp(info, "entities") == 0)
            {
                char sIndex[8];
                menu.GetItem(3, sIndex, sizeof(sIndex));

                int iIndex = StringToInt(sIndex);
                Objective obj = ObjectiveManager.GetObjectiveById(iIndex);
                if (obj.IsNull())
                {
                    PrintToChat(client, "[Objective Manager] There is no objective with id: %d.", iIndex);
                    return;
                }

                UtlVector entities = obj._pEntitysVector;
                int count = obj._iEntitysCount;
                if (entities.IsNull())
                {
                    PrintToChat(client, "[Objective Manager] This objective's entity instance is null.");
                    return;
                }

                Menu entitymenu = new Menu(DummyHandler4);
                entitymenu.SetTitle("Objective Entity List:");
                entitymenu.Pagination = 3;

                for (int i = 1; i <= count; i++)
                {
                    static char buffer[256];
                    Stringt name = entities.Get(i - 1);
                    name.ToCharArray(buffer, sizeof(buffer));

                    int entity = CGlobalEntityList.FindEntityByName(_, buffer);
                    //PrintToServer("name: %s, entity: %d", buffer, entity);

                    if (entity == -1 || !IsValidEntity(entity))
                    {
                        entity = FindEntityByTargetName(buffer);
                        //PrintToServer("Refinding: name: %s, entity: %d", buffer, entity);
                        if (entity == -1 || !IsValidEntity(entity))
                            continue;
                    }
                    
                    // wired. why you return the ref?
                    if (entity < -1 || entity > 2048)
                    {
                        entity = EntRefToEntIndex(entity);

                        // something wrong with the ref conversion?
                        if (entity > 2048)
                            entity -= 2048; // i just gusse.
                    }

                    static float vecOrigin[3];
                    static char classname[64];
                    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);
                    GetEntityClassname(entity, classname, sizeof(classname));
                    Format(buffer, sizeof(buffer), "Name: %s\nEntity Index: %d | Classname: %s\nCoordinates: %.02f, %.02f, %.02f\n ", buffer, entity, classname, vecOrigin[0], vecOrigin[1], vecOrigin[2]);
                    entitymenu.AddItem("", buffer, ITEMDRAW_DISABLED);
                }

                char name[256];
                menu.GetItem(0, name, sizeof(name));

                entitymenu.AddItem(sIndex, "", ITEMDRAW_IGNORE);
                entitymenu.AddItem(name, "", ITEMDRAW_IGNORE);

                entitymenu.ExitBackButton = true;
                entitymenu.Display(client, MENU_TIME_FOREVER);
            }
            else if (strcmp(info, "update") == 0 && IsClientAdmin(client, ADMFLAG_ROOT))
            {
                char sIndex[8];
                menu.GetItem(3, sIndex, sizeof(sIndex));

                int iIndex = StringToInt(sIndex);
                Objective obj = ObjectiveManager.GetObjectiveById(iIndex);
                if (obj.IsNull())
                {
                    PrintToChat(client, "[Objective Manager] There is no objective with id: %d.", iIndex);
                    return;
                }

                obj.UpdateBoundary();
                PrintToChat(client, "[Objective Manager] Objective boundary updated.");
            }
            else if (strcmp(info, "control_boundray") == 0 && IsClientAdmin(client, ADMFLAG_ROOT))
            {
                char sIndex[8];
                menu.GetItem(3, sIndex, sizeof(sIndex));

                int iIndex = StringToInt(sIndex);
                Objective obj = ObjectiveManager.GetObjectiveById(iIndex);
                if (obj.IsNull())
                {
                    PrintToChat(client, "[Objective Manager] There is no objective with id: %d.", iIndex);
                    return;
                }

                ObjectiveBoundary boundary = obj.GetObjectiveBoundary();
                if (boundary.IsNull())
                {
                    PrintToChat(client, "[Objective Manager] This objective's boundary is invalid.");
                    return;
                }

                Menu boundaryMenu = new Menu(BoundrayMenuHandler2);
                boundaryMenu.SetTitle("Objective Boundary Control:");
                boundaryMenu.AddItem("start", "Start");
                boundaryMenu.AddItem("finish", "Finish");

                char name[256];
                menu.GetItem(0, name, sizeof(name));

                boundaryMenu.AddItem(sIndex, "", ITEMDRAW_IGNORE); // pass the id for the callback.
                boundaryMenu.AddItem(name, "", ITEMDRAW_IGNORE);
                boundaryMenu.ExitBackButton = true;
                boundaryMenu.Display(client, MENU_TIME_FOREVER);
            }
        }

        case MenuAction_Cancel:
        {
            if (item == MenuCancel_Exit)
                return;

            ShowObjectiveListMenu(client);
        }

        case MenuAction_End:
            delete menu;
    }
}

void BoundrayMenuHandler2(Menu menu, MenuAction action, int client, int item)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[256];
            menu.GetItem(item, info, sizeof(info));

            char sIndex[8];
            menu.GetItem(2, sIndex, sizeof(sIndex));

            int iIndex = StringToInt(sIndex);
            Objective obj = ObjectiveManager.GetObjectiveById(iIndex);
            if (obj.IsNull())
            {
                PrintToChat(client, "[Objective Manager] There is no objective with id: %d.", iIndex);
                return;
            }

            ObjectiveBoundary boundary = obj.GetObjectiveBoundary();
            if (boundary.IsNull())
            {
                PrintToChat(client, "[Objective Manager] This objective's boundary is invalid.");
                return;
            }

            if (strcmp(info, "start") == 0)
            {
                boundary.Start();
                PrintToChat(client, "[Objective Manager] Started the current objective boundary.");
            }
            else if (strcmp(info, "finish") == 0)
            {
                boundary.Finish();
                PrintToChat(client, "[Objective Manager] Finished the current objective boundary.");
            }
        }

        case MenuAction_Cancel:
        {
            if (item == MenuCancel_Exit)
                return;

            char sIndex[8];
            menu.GetItem(2, sIndex, sizeof(sIndex));

            char name[256]
            menu.GetItem(3, name, sizeof(name));

            ShowSelectedObjectiveMenu(client, sIndex, name);
        }
        
        case MenuAction_End:
            delete menu;
    }
}

void DummyHandler2(Menu menu, MenuAction action, int client, int item)
{
    switch (action)
    {
        case MenuAction_Cancel:
        {
            if (item == MenuCancel_Exit)
                return;

            ShowAllObjectives(client);
        }
        
        case MenuAction_End:
            delete menu;
    }
}

void DummyHandler3(Menu menu, MenuAction action, int client, int item)
{
    switch (action)
    {
        case MenuAction_Cancel:
        {
            if (item == MenuCancel_Exit)
                return;

            char name[256], id[8];
            menu.GetItem(1, id, sizeof(id));
            menu.GetItem(2, name, sizeof(name));
            ShowSelectedObjectiveMenu(client, id, name);
        }
            
        case MenuAction_End:
            delete menu;
    }
}

void DummyHandler4(Menu menu, MenuAction action, int client, int item)
{
    switch (action)
    {
        case MenuAction_Cancel:
        {
            if (item == MenuCancel_NoDisplay)
            {
                PrintToChat(client, "[Objective Manager] Entities may not have created, or something went wrong.")
                return;
            }

            if (item == MenuCancel_Exit)
                return;

            char name[256], id[8];
            menu.GetItem(menu.ItemCount - 1, name, sizeof(name));
            menu.GetItem(menu.ItemCount - 2, id, sizeof(id));
            ShowSelectedObjectiveMenu(client, id, name);
        }
            
        case MenuAction_End:
            delete menu;
    }
}
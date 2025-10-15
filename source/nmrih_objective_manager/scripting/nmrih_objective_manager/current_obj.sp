
void ShowCurrentObjectives(int client)
{
    Objective obj = ObjectiveManager.Instance()._pCurrentObjective;
    if (obj.IsNull())
    {
        PrintToChat(client, "[Objective Manager] There is no current objective.");
        return;
    }
    
    //ArrayList objChains = ObjectiveManager.GetObjectiveChain();

    Menu menu = new Menu(CurrentObjectiveMenuHandler);
    menu.SetTitle("Current Objective's Detail");

    char buffer[256];
    obj._sName.ToCharArray(buffer, sizeof(buffer));
    Format(buffer, sizeof(buffer), "Name: %s", buffer);
    menu.AddItem("name", buffer, ITEMDRAW_DISABLED);

    obj._sDescription.ToCharArray(buffer, sizeof(buffer));
    menu.AddItem(buffer, "Show Description->");

    int index = obj.m_iId;
    Format(buffer, sizeof(buffer), "Objective Id: %d", index);
    menu.AddItem("index", buffer, ITEMDRAW_DISABLED);

    Format(buffer, sizeof(buffer), "%d", index);
    menu.AddItem(buffer, "", ITEMDRAW_IGNORE);    // pass the id for the callback.

    int link_count = obj._iLinksCount;
    Format(buffer, sizeof(buffer), "Link Count: %d", link_count);
    menu.AddItem("link_count", buffer, ITEMDRAW_DISABLED);

    int entity_count = obj._iEntitysCount;
    Format(buffer, sizeof(buffer), "Entity Count: %d", entity_count);
    menu.AddItem("entity_count", buffer, ITEMDRAW_DISABLED);

    bool isend = obj.IsEndObjective();
    Format(buffer, sizeof(buffer), "Is End Objective: %s", isend ? "Yes" : "No");
    menu.AddItem("is_end", buffer, ITEMDRAW_DISABLED);

    bool isanti = obj._bIsAntiObjective;
    Format(buffer, sizeof(buffer), "Is Anti Objective: %s", isanti ? "Yes" : "No");
    menu.AddItem("is_anti", buffer, ITEMDRAW_DISABLED);

    obj._sObjectiveBoundaryName.ToCharArray(buffer, sizeof(buffer));
    Format(buffer, sizeof(buffer), "Objective Boundary Name: %s", buffer);
    menu.AddItem("boundary", buffer, ITEMDRAW_DISABLED);

    ObjectiveBoundary boundary = obj.GetObjectiveBoundary();
    if (!boundary.IsNull())
    {
        int boundray_entity = GetEntityFromAddress(boundary.addr);
        if (boundray_entity > MaxClients && IsValidEntity(boundray_entity))
        {
            Format(buffer, sizeof(buffer), "Boundary Entity Index: %d", boundray_entity);
            menu.AddItem("boundary_entity", buffer, ITEMDRAW_DISABLED);
        }
    }

    Format(buffer, sizeof(buffer), "Show All Links->");
    menu.AddItem("links", buffer, link_count != 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    Format(buffer, sizeof(buffer), "Show All Entities->");
    menu.AddItem("entities", buffer, entity_count != 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    if (IsClientAdmin(client, ADMFLAG_ROOT))
    {
        menu.AddItem("update", "Update Boundary->");
        menu.AddItem("control_boundray", "Control Objective Boundary->");
    }

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

void CurrentObjectiveMenuHandler(Menu menu, MenuAction action, int client, int item)
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
                                Menu submenu = new Menu(DummyHandler);
                                submenu.SetTitle("Objective Description:");
                                submenu.AddItem("desc", value, ITEMDRAW_DISABLED);
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
                    Menu submenu = new Menu(DummyHandler);
                    submenu.SetTitle("Objective Description:");
                    submenu.AddItem("desc", info, ITEMDRAW_DISABLED);
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

                Menu linkmenu = new Menu(DummyHandler);
                linkmenu.SetTitle("Objective Link List:");
                for (int i = 1; i <= count; i++)
                {
                    static char buffer[64];
                    int linkId = links.Get(i - 1);
                    Format(buffer, sizeof(buffer), "Index %d | Link ID: %d", i - 1, linkId);
                    linkmenu.AddItem("", buffer, ITEMDRAW_DISABLED);
                }

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

                Menu entitymenu = new Menu(DummyHandler);
                entitymenu.SetTitle("Objective Entity List:");

                entitymenu.Pagination = 3;

                for (int i = 1; i <= count; i++)
                {
                    static char buffer[256];
                    Stringt name = entities.Get(i - 1);
                    name.ToCharArray(buffer, sizeof(buffer));

                    int entity = obj.GetEntity(i - 1);
                    if (!IsValidEntity(entity))
                    {
                        entity = FindEntityByTargetName(buffer);
                        if (!IsValidEntity(entity))
                            continue;
                    }

                    static float vecOrigin[3];
                    static char classname[64];
                    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);
                    GetEntityClassname(entity, classname, sizeof(classname));
                    Format(buffer, sizeof(buffer), "Name: %s\nEntity Index: %d | Classname: %s\nCoordinates: %.02f, %.02f, %.02f\n ", buffer, entity, classname, vecOrigin[0], vecOrigin[1], vecOrigin[2]);
                    entitymenu.AddItem("", buffer, ITEMDRAW_DISABLED);
                }

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

                Menu boundaryMenu = new Menu(BoundrayMenuHandler);
                boundaryMenu.SetTitle("Objective Boundary Control:");
                boundaryMenu.AddItem("start", "Start");
                boundaryMenu.AddItem("finish", "Finish");
                boundaryMenu.AddItem(sIndex, "", ITEMDRAW_IGNORE); // pass the id for the callback.
                boundaryMenu.ExitBackButton = true;
                boundaryMenu.Display(client, MENU_TIME_FOREVER);
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

void DummyHandler(Menu menu, MenuAction action, int client, int item)
{
    switch (action)
    {
        case MenuAction_Cancel:
        {
            if (item == MenuCancel_Exit)
                return;

            ShowCurrentObjectives(client);
        }

        case MenuAction_End:
            delete menu;
    }
}

void BoundrayMenuHandler(Menu menu, MenuAction action, int client, int item)
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

            ShowCurrentObjectives(client);
        }
        
        case MenuAction_End:
            delete menu;
    }
}

void ShowCurrentObjectives(int client)
{
    Objective obj = ObjectiveManager.Instance()._pCurrentObjective;
    if (obj.IsNull())
    {
        PrintToChat(client, "%t", "NoSuchCurrentObjective");
        return;
    }

    Menu menu = new Menu(CurrentObjectiveMenuHandler);
    menu.SetTitle("%T", "Menu_CurrentObjDetail", client);

    char buffer[256];
    obj._sName.ToCharArray(buffer, sizeof(buffer));
    Format(buffer, sizeof(buffer), "%T", "Menu_Name", client, buffer);
    menu.AddItem("name", buffer, ITEMDRAW_DISABLED);

    char sPhrase[256];
    obj._sDescription.ToCharArray(sPhrase, sizeof(sPhrase));
    Format(buffer, sizeof(buffer), "%T", "Menu_ShowDescription", client);
    menu.AddItem(sPhrase, buffer);

    int index = obj.m_iId;
    Format(buffer, sizeof(buffer), "%T", "Menu_ObjectiveId", client, index);
    menu.AddItem("index", buffer, ITEMDRAW_DISABLED);

    Format(buffer, sizeof(buffer), "%d", index);
    menu.AddItem(buffer, "", ITEMDRAW_IGNORE);    // pass the id for the callback.

    int link_count = obj._iLinksCount;
    Format(buffer, sizeof(buffer), "%T", "Menu_LinkCount", client, link_count);
    menu.AddItem("link_count", buffer, ITEMDRAW_DISABLED);

    int entity_count = obj._iEntitysCount;
    Format(buffer, sizeof(buffer), "%T", "Menu_EntityCount", client, entity_count);
    menu.AddItem("entity_count", buffer, ITEMDRAW_DISABLED);

    bool isend = obj.IsEndObjective();
    Format(buffer, sizeof(buffer), "%T", "Menu_IsEndObjective", client, isend ? "Yes" : "No", client);
    menu.AddItem("is_end", buffer, ITEMDRAW_DISABLED);

    bool isanti = obj._bIsAntiObjective;
    Format(buffer, sizeof(buffer), "%T", "Menu_IsAntiObjective", client, isanti ? "Yes" : "No", client);
    menu.AddItem("is_anti", buffer, ITEMDRAW_DISABLED);

    obj._sObjectiveBoundaryName.ToCharArray(buffer, sizeof(buffer));
    Format(buffer, sizeof(buffer), "%T", "Menu_ObjectiveBoundaryName", client, buffer);
    menu.AddItem("boundary", buffer, ITEMDRAW_DISABLED);

    ObjectiveBoundary boundary = obj.GetObjectiveBoundary();
    if (!boundary.IsNull())
    {
        int boundary_entity = GetEntityFromAddress(boundary.addr);
        if (boundary_entity > MaxClients && IsValidEntity(boundary_entity))
        {
            Format(buffer, sizeof(buffer), "%T", "Menu_BoundaryEntityIndex", client, boundary_entity);
            menu.AddItem("boundary_entity", buffer, ITEMDRAW_DISABLED);
        }
    }

    Format(buffer, sizeof(buffer), "%T", "Menu_ShowAllLinks", client);
    menu.AddItem("links", buffer, link_count != 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    Format(buffer, sizeof(buffer), "%T", "Menu_ShowAllEntities", client);
    menu.AddItem("entities", buffer, entity_count != 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    if (!boundary.IsNull())
    {
        Format(buffer, sizeof(buffer), "%T", "Menu_UpdateBoundary", client);
        menu.AddItem("update", buffer, IsClientAdmin(client, ADMFLAG_ROOT) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

        Format(buffer, sizeof(buffer), "%T", "Menu_ControlBoundary", client);
        menu.AddItem("control_boundary", buffer, IsClientAdmin(client, ADMFLAG_ROOT) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
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
                        PrintToChat(client, "%t", "NoDescriptionFound");
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
                                submenu.SetTitle("%T", "Menu_ObjectiveDescription", client);
                                submenu.AddItem("desc", value, ITEMDRAW_DISABLED);
                                submenu.ExitBackButton = true;
                                submenu.Display(client, MENU_TIME_FOREVER);
                            }
                            else
                            {
                                PrintToChat(client, "%t", "NoDescriptionFound2");
                            }

                            delete map;
                            DeleteFile(output);
                        }
                        else
                        {
                            PrintToChat(client, "%t", "NoDescriptionFound3");
                        }
                    }
                }
                else
                {
                    Menu submenu = new Menu(DummyHandler);
                    submenu.SetTitle("%T", "Menu_ObjectiveDescription", client);
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
                    PrintToChat(client, "%t", "NoObjectiveWithId", iIndex);
                    return;
                }

                int count = obj._iLinksCount;
                UtlVector links = obj._pLinksVector;
                if (links.IsNull())
                {
                    PrintToChat(client, "%t", "LinkInstanceIsNull");
                    return;
                }

                Menu linkmenu = new Menu(DummyHandler);
                linkmenu.SetTitle("%T", "Menu_ObjectiveLinkList", client);
                for (int i = 1; i <= count; i++)
                {
                    char buffer[64];
                    int linkId = links.Get(i - 1);
                    Format(buffer, sizeof(buffer), "%T", "Menu_LinkIndexAndId", client, i - 1, linkId);
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
                    PrintToChat(client, "%t", "NoObjectiveWithId", iIndex);
                    return;
                }

                UtlVector entities = obj._pEntitysVector;
                int count = obj._iEntitysCount;
                if (entities.IsNull())
                {
                    PrintToChat(client, "%t", "EntityInstanceIsNull");
                    return;
                }

                Menu entitymenu = new Menu(DummyHandler);
                entitymenu.SetTitle("%T", "Menu_ObjectiveEntityList", client);

                entitymenu.Pagination = 3;

                for (int i = 1; i <= count; i++)
                {
                    char buffer[256];
                    Stringt name = entities.Get(i - 1);
                    name.ToCharArray(buffer, sizeof(buffer));

                    int entity = obj.GetEntity(i - 1);
                    if (!IsValidEntity(entity))
                    {
                        entity = FindEntityByTargetName(buffer);
                        if (!IsValidEntity(entity))
                            continue;
                    }

                    float vecOrigin[3];
                    char classname[64];
                    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);
                    GetEntityClassname(entity, classname, sizeof(classname));
                    Format(buffer, sizeof(buffer), "%T", "Menu_EntityDetails", client, buffer, entity, classname, vecOrigin[0], vecOrigin[1], vecOrigin[2]);
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
                    PrintToChat(client, "%t", "NoObjectiveWithId", iIndex);
                    return;
                }

                obj.UpdateBoundary();
                PrintToChat(client, "%t", "ObjectiveBoundaryUpdated");
            }
            else if (strcmp(info, "control_boundary") == 0 && IsClientAdmin(client, ADMFLAG_ROOT))
            {
                char sIndex[8];
                menu.GetItem(3, sIndex, sizeof(sIndex));

                int iIndex = StringToInt(sIndex);
                Objective obj = ObjectiveManager.GetObjectiveById(iIndex);
                if (obj.IsNull())
                {
                    PrintToChat(client, "%t", "NoObjectiveWithId", iIndex);
                    return;
                }

                ObjectiveBoundary boundary = obj.GetObjectiveBoundary();
                if (boundary.IsNull())
                {
                    PrintToChat(client, "%t", "ObjectiveBoundaryInvalid");
                    return;
                }

                Menu boundaryMenu = new Menu(BoundaryMenuHandler);
                boundaryMenu.SetTitle("%T", "Menu_BoundaryControl", client);

                char sTemp[256];
                Format(sTemp, sizeof(sTemp), "%T", "Menu_Start", client);
                boundaryMenu.AddItem("start", sTemp);

                Format(sTemp, sizeof(sTemp), "%T", "Menu_Finish", client);
                boundaryMenu.AddItem("finish", sTemp);

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

void BoundaryMenuHandler(Menu menu, MenuAction action, int client, int item)
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
                PrintToChat(client, "%t", "NoObjectiveWithId", iIndex);
                return;
            }

            ObjectiveBoundary boundary = obj.GetObjectiveBoundary();
            if (boundary.IsNull())
            {
                PrintToChat(client, "%t", "ObjectiveBoundaryInvalid");
                return;
            }

            if (strcmp(info, "start") == 0)
            {
                boundary.Start();
                PrintToChat(client, "%t", "StartedBoundary");
            }
            else if (strcmp(info, "finish") == 0)
            {
                boundary.Finish();
                PrintToChat(client, "%t", "FinishedBoundary");
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
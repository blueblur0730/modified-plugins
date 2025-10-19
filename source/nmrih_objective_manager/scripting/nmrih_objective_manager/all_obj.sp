
void ShowAllObjectives(int client)
{
    ObjectiveManager manager = ObjectiveManager.Instance();
    if (manager.IsNull())
    {
        PrintToChat(client, "%t", "ManagerInstanceIsNull");
        return;
    }

    Menu menu = new Menu(ShowAllObjectivesMenuHandler);
    menu.SetTitle("%T", "Menu_ObjectivesDetail", client);

    char buffer[256];
    int obj_count = manager._iObjectivesCount;
    Format(buffer, sizeof(buffer), "%T", "Menu_ObjectivesInTotal", client, obj_count);
    menu.AddItem("obj_count", buffer, ITEMDRAW_DISABLED);

    int anti_obj_count = manager._iAntiObjectivesCount;
    Format(buffer, sizeof(buffer), "%T", "Menu_AntiObjectivesInTotal", client, anti_obj_count);
    menu.AddItem("anti_obj_count", buffer, ITEMDRAW_DISABLED);

    int chain_count = manager._iObjectiveChainCount;
    Format(buffer, sizeof(buffer), "%T", "Menu_ObjectiveChainsInTotal", client, chain_count);
    menu.AddItem("chain_count", buffer, ITEMDRAW_DISABLED);

    Format(buffer, sizeof(buffer), "%T", "Menu_ViewEveryObjective", client);
    menu.AddItem("all_obj", buffer, obj_count > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
    
    Format(buffer, sizeof(buffer), "%T", "Menu_ViewEveryAntiObjective", client);
    menu.AddItem("all_anti_obj", buffer, anti_obj_count > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    Format(buffer, sizeof(buffer), "%T", "Menu_ViewEveryObjectiveChain", client);
    menu.AddItem("all_chain", buffer, chain_count > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
    
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
                PrintToChat(client, "%t", "ManagerInstanceIsNull");
                return;
            }

            char info[256];
            menu.GetItem(item, info, sizeof(info));

            if (strcmp(info, "all_obj") == 0)
            {
                ShowObjectiveListMenu(client);
            }
            else if (strcmp(info, "all_anti_obj") == 0)
            {
                ShowAntiObjectiveListMenu(client);
            }
            else if (strcmp(info, "all_chain") == 0)
            {
                char buffer[256];
                UtlVector chains = manager._pObjectiveChainVector;
                int chain_count = manager._iObjectiveChainCount;

                if (!chains.IsNull())
                {
                    Menu submenu = new Menu(DummyHandler2);
                    submenu.SetTitle("%T", "Menu_AllObjectiveIds", client);

                    for (int i = 1; i < chain_count; i++)
                    {
                        int chainID = chains.Get(i - 1);

                        Format(buffer, sizeof(buffer), "%T", "Menu_LinkIndexAndId", client, i - 1, chainID);
                        submenu.AddItem("", buffer, ITEMDRAW_DISABLED);
                    }

                    submenu.ExitBackButton = true;
                    submenu.Display(client, MENU_TIME_FOREVER);
                }
                else
                {
                    PrintToChat(client, "%t", "TheChainListIsNull");
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
        PrintToChat(client, "%t", "ManagerInstanceIsNull");
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
        submenu.SetTitle("%T", "Menu_SelectToView", client);

        for (int i = 1; i < obj_count; i++)
        {
            Objective obj = objectives.Get(i - 1);
            if (obj.IsNull())
                continue;

            obj._sName.ToCharArray(buffer, sizeof(buffer));

            int id = obj.m_iId;
            if (id == current_obj_id)
            {
                Format(buffer, sizeof(buffer), "%s %T", buffer, "Current", client);
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
        PrintToChat(client, "%t", "NoObjectiveOrListIsNull");
    }
}

void ShowAntiObjectiveListMenu(int client)
{
    char buffer[256];
    ObjectiveManager manager = ObjectiveManager.Instance();
    if (manager.IsNull())
    {
        PrintToChat(client, "%t", "ManagerInstanceIsNull");
        return;
    }

    int anti_obj_count = manager._iAntiObjectivesCount;
    UtlVector antiObjectives = manager._pAntiObjectivesVector;

    if (anti_obj_count != 0 && !antiObjectives.IsNull())
    {
        Menu submenu = new Menu(AllAntiObjectiveMenuHandler);
        submenu.SetTitle("%T", "Menu_SelectAntiToView", client);

        for (int i = 1; i < anti_obj_count; i++)
        {
            Objective obj = antiObjectives.Get(i - 1);
            if (obj.IsNull())
                continue;

            obj._sName.ToCharArray(buffer, sizeof(buffer));

            int id = obj.m_iId;
            static char sId[8];
            IntToString(id, sId, sizeof(sId));
            submenu.AddItem(sId, buffer);
        }

        submenu.ExitBackButton = true;
        submenu.Display(client, MENU_TIME_FOREVER); 
    }
    else
    {
        PrintToChat(client, "%t", "NoAntiObjectiveOrListIsNull");
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

void AllAntiObjectiveMenuHandler(Menu menu, MenuAction action, int client, int item)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[8], name[256];
            menu.GetItem(item, info, sizeof(info), _, name, sizeof(name));

            ShowSelectedAntiObjectiveMenu(client, info, name);
        }

        case MenuAction_Cancel:
        {
            if (item == MenuCancel_Exit)
                return;

            ShowAntiObjectiveListMenu(client);
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
        PrintToChat(client, "%t", "NoObjectiveWithId", id);
        return;
    }

    char buffer[256];
    Menu submenu = new Menu(SelectedObjectiveMenuHandler);
    submenu.SetTitle("%T", "Menu_SelectObjectiveDetails", client);

    Format(buffer, sizeof(buffer), "%T", "Menu_Name", client, name);
    submenu.AddItem("name", buffer, ITEMDRAW_DISABLED);

    char sPhrase[256];
    obj._sDescription.ToCharArray(sPhrase, sizeof(sPhrase));
    Format(buffer, sizeof(buffer), "%T", "Menu_ShowDescription", client);
    submenu.AddItem(sPhrase, buffer);

    Format(buffer, sizeof(buffer), "%T", "Menu_ObjectiveId", client, id);
    submenu.AddItem("index", buffer, ITEMDRAW_DISABLED);

    Format(buffer, sizeof(buffer), "%d", id);
    submenu.AddItem(buffer, "", ITEMDRAW_IGNORE);    // pass the id for the callback.

    int link_count = obj._iLinksCount;
    Format(buffer, sizeof(buffer), "%T", "Menu_LinkCount", client, link_count);
    submenu.AddItem("link_count", buffer, ITEMDRAW_DISABLED);

    int entity_count = obj._iEntitysCount;
    Format(buffer, sizeof(buffer), "%T", "Menu_EntityCount", client, entity_count);
    submenu.AddItem("entity_count", buffer, ITEMDRAW_DISABLED);

    bool isend = obj.IsEndObjective();
    Format(buffer, sizeof(buffer), "%T", "Menu_IsEndObjective", client, isend ? "Yes" : "No", client);
    submenu.AddItem("is_end", buffer, ITEMDRAW_DISABLED);

    obj._sObjectiveBoundaryName.ToCharArray(buffer, sizeof(buffer));
    Format(buffer, sizeof(buffer), "%T", "Menu_ObjectiveBoundaryName", client, buffer);
    submenu.AddItem("boundary", buffer, ITEMDRAW_DISABLED);

    ObjectiveBoundary boundary = obj.GetObjectiveBoundary();
    if (!boundary.IsNull())
    {
        int boundary_entity = GetEntityFromAddress(boundary.addr);
        if (boundary_entity > MaxClients && IsValidEntity(boundary_entity))
        {
            Format(buffer, sizeof(buffer), "%T", "Menu_BoundaryEntityIndex", client, boundary_entity);
            submenu.AddItem("boundary_entity", buffer, ITEMDRAW_DISABLED);
        }
    }

    Format(buffer, sizeof(buffer), "%T", "Menu_ShowAllLinks", client);
    submenu.AddItem("links", buffer, link_count != 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    Format(buffer, sizeof(buffer), "%T", "Menu_ShowAllEntities", client);
    submenu.AddItem("entities", buffer, entity_count != 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    if (!boundary.IsNull())
    {
        Format(buffer, sizeof(buffer), "%T", "Menu_UpdateBoundary", client);
        submenu.AddItem("update", buffer, IsClientAdmin(client, ADMFLAG_ROOT) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

        Format(buffer, sizeof(buffer), "%T", "Menu_ControlBoundary", client);
        submenu.AddItem("control_boundary", buffer, IsClientAdmin(client, ADMFLAG_ROOT) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
    }

    submenu.ExitBackButton = true;
    submenu.Display(client, MENU_TIME_FOREVER);
}

void ShowSelectedAntiObjectiveMenu(int client, const char[] info, const char[] name)
{
    int id = StringToInt(info);
    UtlVector antiObjectives = ObjectiveManager.Instance()._pAntiObjectivesVector;
    int anti_obj_count = ObjectiveManager.Instance()._iAntiObjectivesCount;

    Objective obj;
    if (anti_obj_count != 0 && !antiObjectives.IsNull())
    {
        for (int i = 1; i < anti_obj_count; i++)
        {
            obj = antiObjectives.Get(i - 1);
            if (obj.IsNull())
                continue;

            if (obj.m_iId == id)
            {
                break;
            }
        }
    }

    if (obj.IsNull())
    {
        PrintToChat(client, "%t", "AntiObjectiveIsNull");
        return;
    }

    char buffer[256];
    Menu submenu = new Menu(SelectedObjectiveMenuHandler);
    submenu.SetTitle("%T", "Menu_SelectAntiObjectiveDetails", client);

    Format(buffer, sizeof(buffer), "%T", "Menu_Name", client, name);
    submenu.AddItem("name", buffer, ITEMDRAW_DISABLED);

    Stringt desc = obj._sDescription;
    if (!desc.IsNull())
    {
        char sPhrase[256];
        desc.ToCharArray(sPhrase, sizeof(sPhrase));
        Format(buffer, sizeof(buffer), "%T", "Menu_ShowDescription", client);
        submenu.AddItem(sPhrase, buffer);
    }
    else
    {
        submenu.AddItem("anti", "", ITEMDRAW_IGNORE);
    }

    Format(buffer, sizeof(buffer), "%T", "Menu_ObjectiveId", client, id);
    submenu.AddItem("index", buffer, ITEMDRAW_DISABLED);

    Format(buffer, sizeof(buffer), "%d", id);
    submenu.AddItem(buffer, "", ITEMDRAW_IGNORE);    // pass the id for the callback.

    int link_count = obj._iLinksCount;
    Format(buffer, sizeof(buffer), "%T", "Menu_LinkCount", client, link_count);
    submenu.AddItem("link_count", buffer, ITEMDRAW_DISABLED);

    int entity_count = obj._iEntitysCount;
    Format(buffer, sizeof(buffer), "%T", "Menu_EntityCount", client, entity_count);
    submenu.AddItem("entity_count", buffer, ITEMDRAW_DISABLED);

    obj._sObjectiveBoundaryName.ToCharArray(buffer, sizeof(buffer));
    Format(buffer, sizeof(buffer), "%T", "Menu_ObjectiveBoundaryName", client, buffer);
    submenu.AddItem("boundary", buffer, ITEMDRAW_DISABLED);

    Stringt boundary_name = obj._sObjectiveBoundaryName;
    if (!boundary_name.IsNull())
    {
        obj._sObjectiveBoundaryName.ToCharArray(buffer, sizeof(buffer));
        Format(buffer, sizeof(buffer), "%T", "Menu_ObjectiveBoundaryName", client, buffer);
        submenu.AddItem("boundary", buffer, ITEMDRAW_DISABLED);
    }

    ObjectiveBoundary boundary = obj.GetObjectiveBoundary();
    if (!boundary.IsNull())
    {
        int boundary_entity = GetEntityFromAddress(boundary.addr);
        if (boundary_entity > MaxClients && IsValidEntity(boundary_entity))
        {
            Format(buffer, sizeof(buffer), "%T", "Menu_BoundaryEntityIndex", client, boundary_entity);
            submenu.AddItem("boundary_entity", buffer, ITEMDRAW_DISABLED);
        }
    }

    Format(buffer, sizeof(buffer), "%T", "Menu_ShowAllEntities", client);
    submenu.AddItem("entities", buffer, entity_count != 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    if (!boundary.IsNull())
    {
        Format(buffer, sizeof(buffer), "%T", "Menu_UpdateBoundary", client);
        submenu.AddItem("update", buffer, IsClientAdmin(client, ADMFLAG_ROOT) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

        Format(buffer, sizeof(buffer), "%T", "Menu_ControlBoundary", client);
        submenu.AddItem("control_boundary", buffer, IsClientAdmin(client, ADMFLAG_ROOT) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
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

            char anti[8];
            menu.GetItem(1, anti, sizeof(anti));

            if (item == 1 && strcmp(info, "anti") != 0)
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

                                char name[256], id[8];
                                menu.GetItem(0, name, sizeof(name));
                                menu.GetItem(3, id, sizeof(id));

                                Menu submenu = new Menu(DummyHandler3);
                                submenu.SetTitle("%T", "Menu_ObjectiveDescription", client);
                                submenu.AddItem("desc", value, ITEMDRAW_DISABLED);
                                submenu.AddItem(id, "", ITEMDRAW_IGNORE);
                                submenu.AddItem(name, "", ITEMDRAW_IGNORE);
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
                    char name[256], id[8];
                    menu.GetItem(0, name, sizeof(name));
                    menu.GetItem(3, id, sizeof(id));

                    Menu submenu = new Menu(DummyHandler3);
                    submenu.SetTitle("%T", "Menu_ObjectiveDescription", client);
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

                Objective obj;
                int iIndex = StringToInt(sIndex);

                if (strcmp(anti, "anti") != 0)
                {
                    obj = ObjectiveManager.GetObjectiveById(iIndex);
                    if (obj.IsNull())
                    {
                        PrintToChat(client, "%t", "NoObjectiveWithId", iIndex);
                        return;
                    }
                }
                else
                {
                    UtlVector antiObjectives = ObjectiveManager.Instance()._pAntiObjectivesVector;
                    int anti_obj_count = ObjectiveManager.Instance()._iAntiObjectivesCount;

                    if (anti_obj_count != 0 && !antiObjectives.IsNull())
                    {
                        for (int i = 1; i < anti_obj_count; i++)
                        {
                            obj = antiObjectives.Get(i - 1);
                            if (obj.IsNull())
                                continue;

                            if (obj.m_iId == iIndex)
                            {
                                break;
                            }
                        }
                    }

                    if (obj.IsNull())
                    {
                        PrintToChat(client, "%t", "NoObjectiveWithId", iIndex);
                        return;
                    }
                }

                int count = obj._iLinksCount;
                UtlVector links = obj._pLinksVector;
                if (links.IsNull())
                {
                    PrintToChat(client, "%t", "LinkInstanceIsNull");
                    return;
                }

                Menu linkmenu = new Menu(DummyHandler4);
                linkmenu.SetTitle("%T", "Menu_ObjectiveLinkList", client);
                for (int i = 1; i <= count; i++)
                {
                    char buffer[64];
                    int linkId = links.Get(i - 1);
                    Format(buffer, sizeof(buffer), "%T", "Menu_LinkIndexAndId", client, i - 1, linkId);
                    linkmenu.AddItem("", buffer, ITEMDRAW_DISABLED);
                }

                char name[256];
                menu.GetItem(0, name, sizeof(name));

                linkmenu.AddItem(sIndex, "", ITEMDRAW_IGNORE);
                linkmenu.AddItem(name, "", ITEMDRAW_IGNORE);
                linkmenu.AddItem(anti, "", ITEMDRAW_IGNORE);
                linkmenu.ExitBackButton = true;
                linkmenu.Display(client, MENU_TIME_FOREVER);
            }
            else if (strcmp(info, "entities") == 0)
            {
                char sIndex[8];
                menu.GetItem(3, sIndex, sizeof(sIndex));

                Objective obj;
                int iIndex = StringToInt(sIndex);

                if (strcmp(anti, "anti") != 0)
                {
                    obj = ObjectiveManager.GetObjectiveById(iIndex);
                    if (obj.IsNull())
                    {
                        PrintToChat(client, "%t", "NoObjectiveWithId", iIndex);
                        return;
                    }
                }
                else
                {
                    UtlVector antiObjectives = ObjectiveManager.Instance()._pAntiObjectivesVector;
                    int anti_obj_count = ObjectiveManager.Instance()._iAntiObjectivesCount;

                    if (anti_obj_count != 0 && !antiObjectives.IsNull())
                    {
                        for (int i = 1; i < anti_obj_count; i++)
                        {
                            obj = antiObjectives.Get(i - 1);
                            if (obj.IsNull())
                                continue;

                            if (obj.m_iId == iIndex)
                            {
                                break;
                            }
                        }
                    }

                    if (obj.IsNull())
                    {
                        PrintToChat(client, "%t", "NoObjectiveWithId", iIndex);
                        return;
                    }
                }

                UtlVector entities = obj._pEntitysVector;
                int count = obj._iEntitysCount;
                if (entities.IsNull())
                {
                    PrintToChat(client, "%t", "EntityInstanceIsNull");
                    return;
                }

                Menu entitymenu = new Menu(DummyHandler4);
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

                char name[256];
                menu.GetItem(0, name, sizeof(name));

                entitymenu.AddItem(sIndex, "", ITEMDRAW_IGNORE);
                entitymenu.AddItem(name, "", ITEMDRAW_IGNORE);
                entitymenu.AddItem(anti, "", ITEMDRAW_IGNORE);
                entitymenu.ExitBackButton = true;
                entitymenu.Display(client, MENU_TIME_FOREVER);
            }
            else if (strcmp(info, "update") == 0 && IsClientAdmin(client, ADMFLAG_ROOT))
            {
                char sIndex[8];
                menu.GetItem(3, sIndex, sizeof(sIndex));

                Objective obj;
                int iIndex = StringToInt(sIndex);

                if (strcmp(anti, "anti") != 0)
                {
                    obj = ObjectiveManager.GetObjectiveById(iIndex);
                    if (obj.IsNull())
                    {
                        PrintToChat(client, "%t", "NoObjectiveWithId", iIndex);
                        return;
                    }
                }
                else
                {
                    UtlVector antiObjectives = ObjectiveManager.Instance()._pAntiObjectivesVector;
                    int anti_obj_count = ObjectiveManager.Instance()._iAntiObjectivesCount;

                    if (anti_obj_count != 0 && !antiObjectives.IsNull())
                    {
                        for (int i = 1; i < anti_obj_count; i++)
                        {
                            obj = antiObjectives.Get(i - 1);
                            if (obj.IsNull())
                                continue;

                            if (obj.m_iId == iIndex)
                            {
                                break;
                            }
                        }
                    }

                    if (obj.IsNull())
                    {
                        PrintToChat(client, "%t", "NoObjectiveWithId", iIndex);
                        return;
                    }
                }

                obj.UpdateBoundary();
                PrintToChat(client, "%t", "ObjectiveBoundaryUpdated");
            }
            else if (strcmp(info, "control_boundary") == 0 && IsClientAdmin(client, ADMFLAG_ROOT))
            {
                char sIndex[8];
                menu.GetItem(3, sIndex, sizeof(sIndex));

                Objective obj;
                int iIndex = StringToInt(sIndex);

                if (strcmp(anti, "anti") != 0)
                {
                    obj = ObjectiveManager.GetObjectiveById(iIndex);
                    if (obj.IsNull())
                    {
                        PrintToChat(client, "%t", "NoObjectiveWithId", iIndex);
                        return;
                    }
                }
                else
                {
                    UtlVector antiObjectives = ObjectiveManager.Instance()._pAntiObjectivesVector;
                    int anti_obj_count = ObjectiveManager.Instance()._iAntiObjectivesCount;

                    if (anti_obj_count != 0 && !antiObjectives.IsNull())
                    {
                        for (int i = 1; i < anti_obj_count; i++)
                        {
                            obj = antiObjectives.Get(i - 1);
                            if (obj.IsNull())
                                continue;

                            if (obj.m_iId == iIndex)
                            {
                                break;
                            }
                        }
                    }

                    if (obj.IsNull())
                    {
                        PrintToChat(client, "%t", "NoObjectiveWithId", iIndex);
                        return;
                    }
                }

                ObjectiveBoundary boundary = obj.GetObjectiveBoundary();
                if (boundary.IsNull())
                {
                    PrintToChat(client, "%t", "ObjectiveBoundaryInvalid");
                    return;
                }

                Menu boundaryMenu = new Menu(boundaryMenuHandler2);
                boundaryMenu.SetTitle("%T", "Menu_BoundaryControl", client);

                char sTemp[256];
                Format(sTemp, sizeof(sTemp), "%T", "Menu_Start", client);
                boundaryMenu.AddItem("start", sTemp);

                Format(sTemp, sizeof(sTemp), "%T", "Menu_Finish", client);
                boundaryMenu.AddItem("finish", sTemp);

                char name[256];
                menu.GetItem(0, name, sizeof(name));

                boundaryMenu.AddItem(sIndex, "", ITEMDRAW_IGNORE); // pass the id for the callback.
                boundaryMenu.AddItem(name, "", ITEMDRAW_IGNORE);
                boundaryMenu.AddItem(anti, "", ITEMDRAW_IGNORE);
                boundaryMenu.ExitBackButton = true;
                boundaryMenu.Display(client, MENU_TIME_FOREVER);
            }
        }

        case MenuAction_Cancel:
        {
            if (item == MenuCancel_Exit)
                return;

            char anti[8];
            menu.GetItem(1, anti, sizeof(anti));

            if (strcmp(anti, "anti") != 0)
            {
                ShowObjectiveListMenu(client);
            }
            else
            {
                ShowAntiObjectiveListMenu(client);
            }
        }

        case MenuAction_End:
            delete menu;
    }
}

void boundaryMenuHandler2(Menu menu, MenuAction action, int client, int item)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[256];
            menu.GetItem(item, info, sizeof(info));

            char sIndex[8];
            menu.GetItem(2, sIndex, sizeof(sIndex));

            char anti[8];
            menu.GetItem(4, anti, sizeof(anti));

            Objective obj;
            int iIndex = StringToInt(sIndex);

            if (strcmp(anti, "anti") != 0)
            {
                obj = ObjectiveManager.GetObjectiveById(iIndex);
                if (obj.IsNull())
                {
                    PrintToChat(client, "%t", "NoObjectiveWithId", iIndex);
                    return;
                }
            }
            else
            {
                UtlVector antiObjectives = ObjectiveManager.Instance()._pAntiObjectivesVector;
                int anti_obj_count = ObjectiveManager.Instance()._iAntiObjectivesCount;

                if (anti_obj_count != 0 && !antiObjectives.IsNull())
                {
                    for (int i = 1; i < anti_obj_count; i++)
                    {
                        obj = antiObjectives.Get(i - 1);
                        if (obj.IsNull())
                            continue;

                        if (obj.m_iId == iIndex)
                        {
                            break;
                        }
                    }
                }

                if (obj.IsNull())
                {
                    PrintToChat(client, "%t", "NoObjectiveWithId", iIndex);
                    return;
                }
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

            char sIndex[8];
            menu.GetItem(2, sIndex, sizeof(sIndex));

            char name[256]
            menu.GetItem(3, name, sizeof(name));

            char anti[8];
            menu.GetItem(4, anti, sizeof(anti));

            if (strcmp(anti, "anti") != 0)
            {
                ShowSelectedObjectiveMenu(client, sIndex, name);
            }
            else
            {
                ShowSelectedAntiObjectiveMenu(client, sIndex, name);
            }
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
                PrintToChat(client, "%t", "EntitiesMayNotCreated")
                return;
            }

            if (item == MenuCancel_Exit)
                return;

            char name[256], id[8], anti[8];
            menu.GetItem(menu.ItemCount - 1, anti, sizeof(anti));
            menu.GetItem(menu.ItemCount - 2, name, sizeof(name));
            menu.GetItem(menu.ItemCount - 3, id, sizeof(id));

            if (strcmp(anti, "anti") != 0)
            {
                ShowSelectedObjectiveMenu(client, id, name);
            }
            else
            {
                ShowSelectedAntiObjectiveMenu(client, id, name);
            }
        }
            
        case MenuAction_End:
            delete menu;
    }
}
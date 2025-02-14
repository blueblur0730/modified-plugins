#if defined _l4d2_mixmap_actions_included
 #endinput
#endif
#define _l4d2_mixmap_actions_included
	
// ----------------------------------------------------------
// 		Map switching logic
// ----------------------------------------------------------
void PerformMapProgression()
{

}

*/
// 查找地图实体
bool FindMapEntity() 
{
	/**
	 * 检查是否存在changelevel实体, 不存在则为终局地图, 插件不处理
	 * !!地图可能可以存在多个终点安全屋, 所以changelevel实体也可以多个!! (插件只服务官方地图, 不考虑mod地图, 所以只会存在一个终点安全屋)
	 * 但要支持上局地图过渡装备过来, 则肯定会有一个landmark实体没绑定changelevel实体, 该实体名字则为过渡数据到此章节用的实体名
	 * 第一章节可以修改, 但不可以添加配置(换图会出海报). 终局不可以修改, 但可以添加配置
	 */
	int CId, LId, ModifyLId = INVALID_ENT_REFERENCE;
	char LandMarkName[128], BindName[128];
	bool HasChangeLevel = true;

	// 如果找不到转换地图实体, 记录失败(因为终局图没此实体, 但有过渡到此地图的过渡实体, 下面会获取用于添加到配置, 然后再返回失败)
	if ((CId = FindEntityByClassname(CId, "info_changelevel")) == INVALID_ENT_REFERENCE) 
	{
		HasChangeLevel = false;
	} 
	else 
	{
		// 获取实体所绑定的LankMark实体名
		GetEntPropString(CId, Prop_Data, "m_landmarkName", BindName, sizeof BindName);
		// 如果 没拿到绑定名字, 记录失败
		if (BindName[0] == '\0') 
			HasChangeLevel = false;
	}

	// 遍历过渡实体, 找到没被绑定的实体名和可修改的实体ID
	while ((LId = FindEntityByClassname(LId, "info_landmark")) != INVALID_ENT_REFERENCE) 
	{
		GetEntPropString(LId, Prop_Data, "m_iName", LandMarkName, sizeof LandMarkName);
		// 如果与转换地图实体所绑的名字一样, 则为修改用的实体, 记录ID
		if (StrEqual(LandMarkName, BindName, false)) 
		{
			ModifyLId = LId;
		} 
		else 
		{
			if (! g_bFirstMap) 
			{
				// 把用于过渡到此地图的过渡实体名回写全局变量
				Format(g_sValidLandMarkName, sizeof g_sValidLandMarkName, "%s", LandMarkName); // 用于写配置项
			}
		}
	}
	// 如果 没找到可修改的实体 或 前面已经判定为失败, 返回失败
	if (ModifyLId == INVALID_ENT_REFERENCE || ! HasChangeLevel) 
		return false;
	
	// 把找到的信息回写全局变量
	g_iEnt_ChangeLevelId = CId;
	g_iEnt_LandMarkId = ModifyLId;

	return true;
}

// 修改实体属性
void ChangeEntityProp() 
{
	char MapName[64];
	g_sTransitionMap[0] = '\0';

	// 如果找不到转换地图实体, 返回失败
	if (g_iEnt_ChangeLevelId == INVALID_ENT_REFERENCE || ! IsValidEntity(g_iEnt_ChangeLevelId)) 
	{
		g_bIsValid = false;
		return;
	}
	// 如果找不到可修改的实体, 返回失败
	if (g_iEnt_LandMarkId == INVALID_ENT_REFERENCE || ! IsValidEntity(g_iEnt_LandMarkId)) 
	{
		g_bIsValid = false;
		return;
	}

	// 没到触发概率, 返回失败
	if (! AllowModify()) 
	{
		PrintToChatAll("%s Currently space-time is stable, with no unusual fluctuations.", PREFIX);
		g_bIsValid = false;
		return;
	}

	// 获取要切换到的地图属性, 如果获取不到则返回信息并终止修改
	if (! GetChangeLevelMap(MapName, sizeof MapName)) 
	{
		PrintToChatAll("%s Currently in a single timeline without any temporal fluctuations.", PREFIX);
		//PrintToChatAll("%s 没找到符合要求的地图, 终止修改.", PREFIX);
		g_bIsValid = false;
		return;
	}

	char LandMarkName[128];
	// 获取对应索引的地图名和过渡实体名
	g_mMapLandMarkSet.GetString(MapName, LandMarkName, sizeof LandMarkName);
	// 修改实体属性
	SetEntPropString(g_iEnt_ChangeLevelId, Prop_Data, "m_mapName", MapName);
	SetEntPropString(g_iEnt_ChangeLevelId, Prop_Data, "m_landmarkName", LandMarkName);
	SetEntPropString(g_iEnt_LandMarkId, Prop_Data, "m_iName", LandMarkName);
	g_sTransitionMap = MapName;
	PrintToChatAll("%s An uncharted rift in space-time has appeared. After changeLevel, you will travel to %s ...", PREFIX, MapName);
}

// 获取触发概率
bool AllowModify() 
{
	if (GetRandomFloat(0.0, 1.0) <= g_fChangeChance) 
		return true;

	return false;
}

MRESReturn DTR_OnRestoreTransitionedEntities()
{
	return MRES_Supercede;
}

MRESReturn DTR_CTerrorPlayer_OnTransitionRestore_Post(int pThis, DHookReturn hReturn) 
{
	if (GetClientTeam(pThis) > 2)
		return MRES_Ignored;

	// in case the size of the saferoom dose not match the size before the transition, we teleport them back.
	//CheatCommand(pThis, "warp_to_start_area");
	return MRES_Ignored;
}

/*
// here we store the match or game info for the next map.
Action Timed_NextMapInfo(Handle timer)
{
	char sMapName_New[64], sMapName_Old[64];
	g_hArrayPools.GetString(g_iMapsPlayed, sMapName_New, 64);
	g_hArrayPools.GetString(g_iMapsPlayed - 1, sMapName_Old, 64);

	g_cvNextMapPrint.BoolValue ? CPrintToChatAll("%t", "Show_Next_Map",  sMapName_New) : CPrintToChatAll("%t%t", "Show_Next_Map",  "", "Secret");

	if (L4D_IsVersusMode())
	{
		if ((StrEqual(sMapName_Old, "c6m2_bedlam") && !StrEqual(sMapName_New, "c7m1_docks"))
		|| (StrEqual(sMapName_Old, "c9m2_lots") && !StrEqual(sMapName_New, "c14m1_junkyard")))
		{
			s_iPointsTeam_A = L4D2Direct_GetVSCampaignScore(0);
			s_iPointsTeam_B = L4D2Direct_GetVSCampaignScore(1);
			g_bCMapTransitioned = true;
#if DEBUG
			PrintToServer("[Mixmap] Timer_Gotomap creating.");
#endif
			CreateTimer(9.0, Timed_Gotomap);	//this command must set ahead of the l4d2_map_transition plugin setting. Otherwise the map will be c7m1_docks/c14m1_junkyard after c6m2_bedlam/c9m2_lots
		}
		else if ((!StrEqual(sMapName_Old, "c6m2_bedlam") && StrEqual(sMapName_New, "c7m1_docks"))
		|| (!StrEqual(sMapName_Old, "c9m2_lots") && StrEqual(sMapName_New, "c14m1_junkyard")))
		{
			s_iPointsTeam_A = L4D2Direct_GetVSCampaignScore(0);
			s_iPointsTeam_B = L4D2Direct_GetVSCampaignScore(1);
			g_bCMapTransitioned = true;
#if DEBUG
			PrintToServer("[Mixmap] Timer_Gotomap creating.");
#endif
			CreateTimer(10.0, Timed_Gotomap);	//this command must set ahead of the l4d2_map_transition plugin setting. Otherwise the map will be c7m1_docks/c14m1_junkyard after c6m2_bedlam/c9m2_lots
		}
	}

	return Plugin_Handled;
}
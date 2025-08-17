
bool g_bAutoSpawn[NMR_MAXPLAYERS + 1];

/**
 * Solution:
 * 1): Spawn zombie via sourcemod. (steps from COverlord_Zombie_Helper::TrySpawnZombies)
 * 		-> Create entity -> Set position/angle -> Set Ground Entity -> DispatchSpawn -> call CAI_BaseNPC::InitRelationshipTable -> Set model -> so on...
 * Pretty complex, and not sure able to work.
 *
 * 2): via calling COverlord_Zombie_Helper::TrySpawnZombies(ZombieSpawnRequestInfo_t &)
 * 		-> Figure out the member of ZombieSpawnRequestInfo_t -> Allocate memory for it -> Call the function.
 *
 * Not safe and time consuming. But you can freely spawn zombies in anywhere.
 *
 * 3): via Firing entity input or event.
 * 		-> Find entity "overlord_zombie_helper" -> Fire input "InputSpawn/InputSpawnIgnoreVisibility" with parameters.
 * 		-> Find entity "func_zombie_spawn" -> Fire input "InputInstantSpawn" with parameters.
 * 		-> Fire game event "instant_zombie_spawn".
 *
 * The fastest and the most simple. But the position is limited to brushes.
 */

/**
 * overlord_zombie_helper
 *
 * EnableSpawning
 * 		Enable Spawning
 *
 * DisableSpawning
 * 		Disable Spawning
 *
 * InputSpawn <string>
 * 		Instantly spawn zombies across all active spawn brushes.  Optionally specify a spawn target name as well.
 *
 * InputSpawnIgnoreVisibility <string>
 * 		Instantly spawn zombies across all active spawn brushes, ignoring visibility.  Optionally specify a spawn target name as well.
 */

/*
 * func_zombie_spawn
 * 
 * InputInstantSpawn <integer> 
 * 		Instantly spawn zombies at this brush
 * 
 * InputSetTarget <string> 
 * 		Set target entity
 * 
 * InputEnable 
 * 		Enable this spawn brush
 * 
 * InputDisable 
 * 		Disable this spawn brush
 * 
 * InputSetIgnoreVisibility <integer> 
 * 		Set ignore visibility
 * 
 * InputSetSpawnDensity <float> 
 * 		Set Spawn Density
 * 
 * InputSetSpawnTarget <string> 
 * 		Set Smart Spawn Target
 * 
 * InputSetRegenTarget <float> 
 * 		Set Regeneration Fraction Goal
*/

/**
 * 	Event Name:	instant_zombie_spawn
 *	Structure:	
 *		short	spawn_amount	
 *		short	spawn_brush		// the target func_zombie_spawn brush entity, pass index.
 *		string	spawn_target	// the targetname once the zombie spawned to attack to.
 *		bool	ignore_visibility	
 *		bool	check_proximity	// check distance.
 *		bool	track	
 *		float	runner_chance	
 *		float	child_chance
 * 
*/

void SpawnZombie_ClassSelect(int client)
{
	static char sAutoSpawn[128];
	FormatEx(sAutoSpawn, sizeof(sAutoSpawn), "%s", g_bAutoSpawn[client] ? "设置产生方式 [当前: 通过实体或事件]" : "设置产生方式 [当前: 十字准星处生成]");

	Menu menu = new Menu(SpawnZombie_ClassSelect_MenuHandler);
	menu.SetTitle("产生丧尸:");
	menu.AddItem("", sAutoSpawn);

	if (g_bAutoSpawn[client])
	{
		menu.AddItem("overlord_zombie_helper", "使用实体 overlord_zombie_helper");
		menu.AddItem("func_zombie_spawn", "使用实体 func_zombie_spawn");
		menu.AddItem("instant_zombie_spawn", "使用事件 instant_zombie_spawn");
	}
	else
	{
		menu.AddItem("npc_nmrih_shamblerzombie", "走尸");
		menu.AddItem("npc_nmrih_runnerzombie", "跑尸");
		menu.AddItem("npc_nmrih_kidzombie", "小孩丧尸");
	}

	menu.ExitBackButton = true;
	menu.DisplayAt(client, g_iZombieClassMenuPos[client], MENU_TIME_FOREVER);
}

static int SpawnZombie_ClassSelect_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (itemNum)
			{
				case 0: g_bAutoSpawn[client] = !g_bAutoSpawn[client];
				default:
				{
					if (g_bAutoSpawn[client])
					{
						char sName[64], sDisplayName[64];
						menu.GetItem(itemNum, sName, sizeof(sName), _, sDisplayName, sizeof(sDisplayName));

						switch (itemNum)
						{
							case 1:
							{
								int overlord_zombie_helper = FindEntityByClassname(-1, "overlord_zombie_helper");
								if (overlord_zombie_helper != INVALID_ENT_REFERENCE && IsValidEntity(overlord_zombie_helper))
								{
									SetVariantString("");
									if (AcceptEntityInput(overlord_zombie_helper, "InputSpawn"))
									{
										PrintToChat(client, "[DevMenu] 已随机产生丧尸.");
									}
									else
									{
										PrintToChat(client, "[DevMenu] 错误: 无法触发输入 InputSpawn.");
									}
								}
								else
								{
									PrintToChat(client, "[DevMenu] 错误: 找不到 overlord_zombie_helper 实体.");
								}
							}

							case 2:
							{
								Menu funcmenu = new Menu(Entity_MenuHandler);
								funcmenu.SetTitle("选择 func_zombie_spawn 实体:");

								ArrayList array = CollectFuncZombieSpawnEntities();
								for (int i = 0; i < array.Length; i++)
								{
									FuncZombieSpawnInfo info;
									array.GetArray(i, info, sizeof(FuncZombieSpawnInfo));

									char sInfo[128];
									FormatEx(sInfo, sizeof(sInfo), "%s (Index: %d) (Origin: %.02f %.02f %.02f)", info.targetname[0] != '\0' ? info.targetname : "<no_name>", info.index, info.vecOrigin[0], info.vecOrigin[1], info.vecOrigin[2]);

									char sPass[128];
									IntToString(info.index, sPass, sizeof(sPass));
										
									funcmenu.AddItem(sPass, sInfo);
								}

								delete array;
								funcmenu.ExitBackButton = true;
								funcmenu.Display(client, MENU_TIME_FOREVER);

								return 0;
							}

							case 3:
							{
								Event instant_zombie_spawn = CreateEvent("instant_zombie_spawn");
								if (instant_zombie_spawn != null)
								{
									instant_zombie_spawn.SetInt("spawn_amount", 1);
									instant_zombie_spawn.SetInt("spawn_brush", 0);
									instant_zombie_spawn.SetString("spawn_target", "");
									instant_zombie_spawn.SetBool("ignore_visibility", false);
									instant_zombie_spawn.SetBool("check_proximity", true);
									instant_zombie_spawn.SetBool("track", false);
									instant_zombie_spawn.SetFloat("runner_chance", 1.0);
									instant_zombie_spawn.SetFloat("child_chance", 1.0);
									instant_zombie_spawn.Fire();
									PrintToChat(client, "[DevMenu] 已随机产生丧尸.");
								}
								else
								{
									PrintToChat(client, "[DevMenu] 错误: 无法创建事件 instant_zombie_spawn.");
								}
							}
						}
					}
					else
					{
						char sName[64], sDisplayName[64];
						menu.GetItem(itemNum, sName, sizeof(sName), _, sDisplayName, sizeof(sDisplayName));

						float fPos[3];
						if (!GetCrosshairPos(client, fPos))
						{
							PrintToChat(client, "[DevMenu] 错误: 无法获取十字准星位置");
							return 0;
						}
						else
						{
							switch (itemNum)
							{
								case 1:
								{
									if (CreateZombie(ZOMBIE_SHAMBLER, fPos, _, _, _, _, _, _, _, _, _, TwentyPercentTrue(), TwentyPercentTrue()) == INVALID_ENT_REFERENCE)
									{
										PrintToChat(client, "[DevMenu] 错误: 无法产生走尸");
									}
									else
									{
										PrintToChat(client, "[DevMenu] 已产生丧尸: %s", sDisplayName);
									}
								}

								case 2:
								{
									if (CreateZombie(ZOMBIE_RUNNER, fPos, _, _, _, _, _, _, _, _, _, false, TwentyPercentTrue()) == INVALID_ENT_REFERENCE)
									{
										PrintToChat(client, "[DevMenu] 错误: 无法产生跑尸");
									}
									else
									{
										PrintToChat(client, "[DevMenu] 已产生丧尸: %s", sDisplayName);
									}
								}

								case 3:
								{
									if (CreateZombie(ZOMBIE_KID, fPos) == INVALID_ENT_REFERENCE)
									{
										PrintToChat(client, "[DevMenu] 错误: 无法产生小孩丧尸");
									}
									else
									{
										PrintToChat(client, "[DevMenu] 已产生丧尸: %s", sDisplayName);
									}
								}
							}
						}
					}
				}
			}

			g_iZombieClassMenuPos[client] = menu.Selection;
			SpawnZombie_ClassSelect(client);
		}

		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
				g_TopMenu.Display(client, TopMenuPosition_LastCategory);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

static void Entity_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sIndex[128];
			menu.GetItem(itemNum, sIndex, sizeof(sIndex));
			int func_zombie_spawn = StringToInt(sIndex);
			if (func_zombie_spawn <= 0 || !IsValidEntity(func_zombie_spawn))
			{
				PrintToChat(client, "[DevMenu] 错误: 无法找到实体 func_zombie_spawn (TargetName: %s)", sIndex);
				return;
			}

			SetVariantInt(1);
			AcceptEntityInput(func_zombie_spawn, "InputInstantSpawn");
			PrintToChat(client, "[DevMenu] 已随机产生丧尸.");

			SpawnZombie_ClassSelect(client);
		}

		case MenuAction_Cancel:
		{
			if (itemNum == MenuCancel_ExitBack)
				g_TopMenu.Display(client, TopMenuPosition_LastCategory);
		}

		case MenuAction_End:
			delete menu;
	}
}
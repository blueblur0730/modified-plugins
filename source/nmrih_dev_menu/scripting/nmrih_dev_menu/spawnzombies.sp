
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

void SpawnZombie_ClassSelect(int client)
{
	static char sAutoSpawn[128];
	FormatEx(sAutoSpawn, sizeof(sAutoSpawn), "%s", g_bAutoSpawn[client] ? "设置产生位置 [当前: 自动找位]" : "设置产生位置 [当前: 十字准星处]");

	Menu menu = new Menu(SpawnZombie_ClassSelect_MenuHandler);
	menu.SetTitle("产生丧尸:");
	menu.AddItem("", sAutoSpawn);

	if (g_bAutoSpawn[client])
	{
		menu.AddItem("overlord_zombie_helper", "随机生成");
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
						// 自动找位
						int overlord_zombie_helper = FindEntityByClassname(-1, "overlord_zombie_helper");
						if (overlord_zombie_helper != INVALID_ENT_REFERENCE && IsValidEntity(overlord_zombie_helper))
						{
							AcceptEntityInput(overlord_zombie_helper, "InputSpawn");
							PrintToChat(client, "[DevMenu] 已随机产生丧尸.");
						}
						else
						{
							PrintToChat(client, "[DevMenu] 错误: 找不到 overlord_zombie_helper 实体.");
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
									if (CreateZombie(ZOMBIE_RUNNER, fPos, _, _, _, _, _, _, _, _, _, TwentyPercentTrue(), TwentyPercentTrue()) == INVALID_ENT_REFERENCE)
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
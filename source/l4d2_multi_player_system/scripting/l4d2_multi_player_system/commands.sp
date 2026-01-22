
void SetupCommands()
{
	RegConsoleCmd("sm_afk", cmdGoIdle, "Go awat from keyboard.");
	RegConsoleCmd("sm_teams", cmdTeamPanel, "Team panel.");
	RegConsoleCmd("sm_join", cmdJoinTeam2, "Join team 2.");
	RegConsoleCmd("sm_tkbot", cmdTakeOverBot, "Take over a specified bot.");

	RegConsoleCmd("sm_zs", cmdSuicide, "kill yourself.");
	RegConsoleCmd("sm_suicide", cmdSuicide, "kill yourself.");

	RegAdminCmd("sm_spec", cmdJoinTeam1, ADMFLAG_ROOT, "Join team 1.");
	RegAdminCmd("sm_bot", cmdBotSet, ADMFLAG_ROOT, "Set the number of bots to spawn at round start.");

	RegAdminCmd("sm_increase_bot", cmdIncreaseBot, ADMFLAG_ROOT, "Increase the number of bots by 1.");
	RegAdminCmd("sm_decrease_bot", cmdDecreaseBot, ADMFLAG_ROOT, "Decrease the number of bots by 1.");

	AddCommandListener(Listener_spec_next, "spec_next");
	HookUserMessage(GetUserMessageId("SayText2"), umSayText2, true);
}

static Action cmdGoIdle(int client, int args)
{
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	if (!g_bRoundStart)
	{
		CReplyToCommand(client, "[{green}!{default}] 回合尚未开始.");
		return Plugin_Handled;
	}

	if (GetClientTeam(client) != TEAM_SURVIVOR || !IsPlayerAlive(client))
		return Plugin_Handled;

	GoAFKTimer(client, 2.5);
	return Plugin_Handled;
}

static void GoAFKTimer(int client, float flDuration)
{
	static int m_GoAFKTimer = -1;
	if (m_GoAFKTimer == -1)
		m_GoAFKTimer = FindSendPropInfo("CTerrorPlayer", "m_lookatPlayer") - 12;

	SetEntDataFloat(client, m_GoAFKTimer + 4, flDuration);
	SetEntDataFloat(client, m_GoAFKTimer + 8, GetGameTime() + flDuration);
}

static Action cmdTeamPanel(int client, int args)
{
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	DrawTeamPanel(client, false);
	return Plugin_Handled;
}

static Action cmdJoinTeam2(int client, int args)
{
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	if (!g_bRoundStart)
	{
		CPrintToChat(client, "[{green}!{default}] 回合尚未开始.");
		return Plugin_Handled;
	}

	if (!(g_iJoinFlags & JOIN_MANUAL))
	{
		CPrintToChat(client, "[{green}!{default}] 手动加入已禁用.");
		return Plugin_Handled;
	}

	if (CheckJoinLimit())
	{
		CPrintToChat(client, "[{green}!{default}] 已达到生还者数量限制 {green}%d{default}.", g_iJoinLimit);
		return Plugin_Handled;
	}

	switch (GetClientTeam(client))
	{
		case TEAM_SPECTATOR:
		{
			if (GetBotOfIdlePlayer(client))
				return Plugin_Handled;
		}

		case TEAM_SURVIVOR:
		{
			CPrintToChat(client, "[{green}!{default}] 你当前已在生还者队伍.");
			return Plugin_Handled;
		}

		default:
			ChangeClientTeam(client, TEAM_SPECTATOR);
	}

	JoinSurTeam(client);
	return Plugin_Handled;
}

bool JoinSurTeam(int client)
{
	int	 bot		= GetClientOfUserId(g_esPlayer[client].Bot);
	bool canRespawn = g_iJoinRespawn == -1 || (g_iJoinRespawn && IsFirstTime(client));
	if (!bot || !IsValidSurBot(bot))
		bot = FindUselessSurBot(canRespawn);

	if (!bot && !canRespawn)
	{
		ChangeClientTeam(client, TEAM_SURVIVOR);
		if (IsPlayerAlive(client))
			State_Transition(client, 6);

		CPrintToChat(client, "[{green}!{default}] 重复加入默认为 {green}死亡状态{default}.");
		return true;
	}

	bool canTake;
	if (!canRespawn)
	{
		if (IsPlayerAlive(bot))
		{
			canTake = CheckForTake(bot, bot);
			SetHumanSpec(bot, client);
			if (canTake)
			{
				TakeOverBot(client);
				SetInvulnerable(client, 1.5);
			}
			else
			{
				SetInvulnerable(bot, 1.5);
				WriteTakeoverPanel(client, bot);
			}
		}
		else
		{
			SetHumanSpec(bot, client);
			TakeOverBot(client);
			CPrintToChat(client, "[{green}!{default}] 重复加入默认为 {green}死亡状态{default}.");
		}
	}
	else
	{
		bool addBot = !bot;
		if (addBot && (bot = SpawnSurBot()) == -1)
			return false;

		if (!IsPlayerAlive(bot))
		{
			RespawnPlayer(bot);
			canTake = CheckForTake(bot, TeleportPlayer(bot));
		}
		else
			canTake = CheckForTake(bot, addBot ? TeleportPlayer(bot) : bot);

		SetHumanSpec(bot, client);
		if (canTake)
		{
			TakeOverBot(client);
			SetInvulnerable(client, 1.5);
		}
		else
		{
			SetInvulnerable(bot, 1.5);
			WriteTakeoverPanel(client, bot);
		}
	}

	return true;
}

static Action cmdTakeOverBot(int client, int args)
{
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	if (!g_bRoundStart)
	{
		CReplyToCommand(client, "[{green}!{default}] 回合尚未开始.");
		return Plugin_Handled;
	}

	if (!IsTeamAllowed(client))
	{
		CPrintToChat(client, "[{green}!{default}] 不符合接管条件.");
		return Plugin_Handled;
	}

	if (CheckJoinLimit())
	{
		CPrintToChat(client, "[{green}!{default}] 已达到生还者数量限制 {green}%d{default}.", g_iJoinLimit);
		return Plugin_Handled;
	}

	if (!FindUselessSurBot(true))
	{
		CPrintToChat(client, "[{green}!{default}] 没有 {olive}空闲的电脑BOT{default} 可以接管.");
		return Plugin_Handled;
	}

	TakeOverBotMenu(client);
	return Plugin_Handled;
}

static void TakeOverBotMenu(int client)
{
	char info[12];
	char disp[64];
	Menu menu = new Menu(TakeOverBot_MenuHandler);
	menu.SetTitle("- 请选择接管目标 - [!tkbot]");
	menu.AddItem("o", "当前旁观目标");

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidSurBot(i))
			continue;

		FormatEx(info, sizeof info, "%d", GetClientUserId(i));
		FormatEx(disp, sizeof disp, "%s - %s", IsPlayerAlive(i) ? "存活" : "死亡", g_sSurvivorNames[GetCharacter(i)]);
		menu.AddItem(info, disp);
	}

	menu.ExitButton		= true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

static int TakeOverBot_MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (CheckJoinLimit())
			{
				CPrintToChat(param1, "[{green}!{default}] 已达到生还者数量限制 {green}%d{default}.", g_iJoinLimit);
				return 0;
			}

			int	 bot;
			char item[12];
			menu.GetItem(param2, item, sizeof item);
			if (item[0] == 'o')
			{
				bot = GetEntPropEnt(param1, Prop_Send, "m_hObserverTarget");
				if (bot > 0 && bot <= MaxClients && IsValidSurBot(bot))
				{
					SetHumanSpec(bot, param1);
					TakeOverBot(param1);
				}
				else
					CPrintToChat(param1, "[{green}!{default}] 当前旁观目标非可接管BOT.");
			}
			else {
				bot = GetClientOfUserId(StringToInt(item));
				if (!bot || !IsValidSurBot(bot))
					CPrintToChat(param1, "[{green}!{default}] 选定的目标BOT已失效.");
				else
				{
					int team = IsTeamAllowed(param1);
					if (!team)
						CPrintToChat(param1, "[{green}!{default}] 不符合接管条件.");
					else
					{
						if (team != TEAM_SPECTATOR)
							ChangeClientTeam(param1, TEAM_SPECTATOR);

						SetHumanSpec(bot, param1);
						TakeOverBot(param1);
					}
				}
			}
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

static Action cmdSuicide(int client, int args)
{
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	if (IsPlayerAlive(client))
	{
		CPrintToChatAllEx(client, "[{green}!{default}] {teamcolor}%N{default} 失去梦想自杀了...", client);
		ForcePlayerSuicide(client);
	}

	return Plugin_Handled;
}

static Action cmdJoinTeam1(int client, int args)
{
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	if (!g_bRoundStart)
	{
		CReplyToCommand(client, "[{green}!{default}] 回合尚未开始.");
		return Plugin_Handled;
	}

	bool idle = !!GetBotOfIdlePlayer(client);
	if (!idle && GetClientTeam(client) == TEAM_SPECTATOR)
	{
		CPrintToChat(client, "[{green}!{default}] 你当前已在旁观者队伍.");
		return Plugin_Handled;
	}

	if (idle)
		TakeOverBot(client);

	ChangeClientTeam(client, TEAM_SPECTATOR);
	return Plugin_Handled;
}

static Action cmdBotSet(int client, int args)
{
	if (!g_bRoundStart)
	{
		CReplyToCommand(client, "[{green}!{default}] 回合尚未开始.");
		return Plugin_Handled;
	}

	if (args != 1)
	{
		CReplyToCommand(client, "[{green}!{default}] !bot/sm_bot <{olive}数量{default}>.");
		return Plugin_Handled;
	}

	int arg = GetCmdArgInt(1);
	if (arg < 1 || arg > MaxClients - 1)
	{
		CReplyToCommand(client, "[{green}!{default}] 参数范围 {olive}1{default}~{olive}%d{default}.", MaxClients - 1);
		return Plugin_Handled;
	}

	delete g_hBotsTimer;
	g_hCvar_BotLimit.IntValue = arg;
	g_hBotsTimer		  = CreateTimer(1.0, tmrBotsUpdate);
	CReplyToCommand(client, "[{green}!{default}] 开局BOT数量已设置为 {green}%d{default}.", arg);
	return Plugin_Handled;
}

static Action Listener_spec_next(int client, char[] command, int argc)
{
	if (!g_bRoundStart)
		return Plugin_Continue;

	if (!(g_iJoinFlags & JOIN_MANUAL) || !g_esPlayer[client].Notify)
		return Plugin_Continue;

	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;

	if (GetClientTeam(client) != TEAM_SPECTATOR || GetBotOfIdlePlayer(client))
		return Plugin_Continue;

	if (CheckJoinLimit())
		return Plugin_Continue;

	if (PrepRestoreBots())
		return Plugin_Continue;

	g_esPlayer[client].Notify = false;

	switch (g_iSpecNotify)
	{
		case 1:
			CPrintToChat(client, "[{green}!{default}] 聊天栏输入 {olive}!join {default}加入游戏.");

		case 2:
			PrintHintText(client, "[!] 聊天栏输入 !join 加入游戏");

		case 3:
			JoinTeam2Menu(client);
	}

	return Plugin_Continue;
}

static void JoinTeam2Menu(int client)
{
	EmitSoundToClient(client, SOUND_SPECMENU, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);

	Menu menu = new Menu(JoinTeam2_MenuHandler);
	menu.SetTitle("加入生还者?");
	menu.AddItem("y", "是");
	menu.AddItem("n", "否");

	if (FindUselessSurBot(true))
		menu.AddItem("t", "接管指定BOT");

	menu.ExitButton		= false;
	menu.ExitBackButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}

static int JoinTeam2_MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 0:
					cmdJoinTeam2(param1, 0);

				case 2:
				{
					if (FindUselessSurBot(true))
						TakeOverBotMenu(param1);
					else
						CPrintToChat(param1, "[{green}!{default}] 没有 {olive}空闲的电脑BOT {default}可以接管.");
				}
			}
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

static Action umSayText2(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if (!g_bBlockUserMsg)
		return Plugin_Continue;

	msg.ReadByte();
	msg.ReadByte();

	char buffer[254];
	msg.ReadString(buffer, sizeof buffer, true);
	if (strcmp(buffer, "#Cstrike_Name_Change") == 0)
		return Plugin_Handled;

	return Plugin_Continue;
}

static Action cmdIncreaseBot(int client, int args)
{
	if (!g_bRoundStart)
	{
		CReplyToCommand(client, "[{green}!{default}] 回合尚未开始.");
		return Plugin_Handled;
	}

	delete g_hBotsTimer;
	g_hCvar_BotLimit.IntValue++;
	g_hBotsTimer = CreateTimer(1.0, tmrBotsUpdate);
	CReplyToCommand(client, "[{green}!{default}] 开局BOT数量已增加到 {green}%d{default}.", g_hCvar_BotLimit.IntValue);
	return Plugin_Handled;
}

static Action cmdDecreaseBot(int client, int args)
{
	if (!g_bRoundStart)
	{
		CReplyToCommand(client, "[{green}!{default}] 回合尚未开始.");
		return Plugin_Handled;
	}

	delete g_hBotsTimer;
	g_hCvar_BotLimit.IntValue--;
	CReplyToCommand(client, "[{green}!{default}] 开局BOT数量已减少到 {green}%d{default}.", g_hCvar_BotLimit.IntValue);
	return Plugin_Handled;
}

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
		CPrintToChat(client, "%t", "RoundNotAlive");
		return Plugin_Handled;
	}

	if (GetClientTeam(client) != TEAM_SURVIVOR || !IsPlayerAlive(client))
		return Plugin_Handled;

	GoAFKTimer(client, 2.5);
	return Plugin_Handled;
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
		CPrintToChat(client, "%t", "RoundNotAlive");
		return Plugin_Handled;
	}

	if (!(g_iJoinFlags & JOIN_MANUAL))
	{
		CPrintToChat(client, "%t", "ManualJoinDisabled");
		return Plugin_Handled;
	}

	if (CheckJoinLimit())
	{
		CPrintToChat(client, "%t", "ReachedLimit", g_iJoinLimit);
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
			CPrintToChat(client, "%t", "AlreadyInSurvivorTeam");
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

		CPrintToChat(client, "%t", "DeadWhenRejoin");
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
			CPrintToChat(client, "%t", "DeadWhenRejoin");
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
		CPrintToChat(client, "%t", "RoundNotAlive");
		return Plugin_Handled;
	}

	if (!IsTeamAllowed(client))
	{
		CPrintToChat(client, "%t", "NotAvailableToBeTakenOver");
		return Plugin_Handled;
	}

	if (CheckJoinLimit())
	{
		CPrintToChat(client, "%t", "ReachedLimit", g_iJoinLimit);
		return Plugin_Handled;
	}

	if (!FindUselessSurBot(true))
	{
		CPrintToChat(client, "%t", "NoAvailableToBeTaken");
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

	char sBuffer[256];
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "Menu_ChooseBot", client);
	menu.SetTitle(sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%T", "Menu_CurrentSpecTarget", client);
	menu.AddItem("o", sBuffer);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidSurBot(i))
			continue;

		FormatEx(info, sizeof info, "%d", GetClientUserId(i));
		FormatEx(disp, sizeof disp, "%T - %s", IsPlayerAlive(i) ? "Menu_Alive" : "Menu_Dead", client, g_sSurvivorNames[GetCharacter(i)]);
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
				CPrintToChat(param1, "%t", "ReachedLimit", g_iJoinLimit);
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
					CPrintToChat(param1, "%t", "CurrentSpecTargetNotAvailable");
			}
			else {
				bot = GetClientOfUserId(StringToInt(item));
				if (!bot || !IsValidSurBot(bot))
					CPrintToChat(param1, "%t", "SelectedBotNotAvailable");
				else
				{
					int team = IsTeamAllowed(param1);
					if (!team)
						CPrintToChat(param1, "%t", "NotAvailableToBeTakenOver");
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
		CPrintToChatAllEx(client, "%t", "Suicided", client);
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
		CPrintToChat(client, "%t", "RoundNotAlive");
		return Plugin_Handled;
	}

	bool idle = !!GetBotOfIdlePlayer(client);
	if (!idle && GetClientTeam(client) == TEAM_SPECTATOR)
	{
		CPrintToChat(client, "%t", "AlreadyInSpecTeam");
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
		CPrintToChat(client, "%t", "RoundNotAlive");
		return Plugin_Handled;
	}

	if (args != 1)
	{
		CReplyToCommand(client, "%t", "BotSetUsage");
		return Plugin_Handled;
	}

	int arg = GetCmdArgInt(1);
	if (arg < 1 || arg > MaxClients - 1)
	{
		CReplyToCommand(client, "%t", "ArgRange", MaxClients - 1);
		return Plugin_Handled;
	}

	delete g_hBotsTimer;
	g_hCvar_BotLimit.IntValue = arg;
	g_hBotsTimer		  = CreateTimer(1.0, tmrBotsUpdate);
	CReplyToCommand(client, "%t", "SettingBotNumber", arg);
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
			CPrintToChat(client, "%t", "TypeJoinCommandToJoin");

		case 2:
			PrintHintText(client, "%T", "TypeJoinCommandToJoin_NoColor", client);

		case 3:
			JoinTeam2Menu(client);
	}

	return Plugin_Continue;
}

static void JoinTeam2Menu(int client)
{
	EmitSoundToClient(client, SOUND_SPECMENU, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);

	char sBuffer[256];
	Menu menu = new Menu(JoinTeam2_MenuHandler);

	FormatEx(sBuffer, sizeof sBuffer, "%T", "Menu_JoinTeam2", client);
	menu.SetTitle(sBuffer);

	FormatEx(sBuffer, sizeof sBuffer, "%T", "Menu_Yes", client);
	menu.AddItem("y", sBuffer);

	FormatEx(sBuffer, sizeof sBuffer, "%T", "Menu_No", client);
	menu.AddItem("n", sBuffer);

	if (FindUselessSurBot(true))
	{
		FormatEx(sBuffer, sizeof sBuffer, "%T", "Menu_TakeOverSpecifiedBot", client);
		menu.AddItem("t", sBuffer);
	}
		

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
						CPrintToChat(param1, "%t", "NoAvailableToBeTaken");
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
		CPrintToChat(client, "%t", "RoundNotAlive");
		return Plugin_Handled;
	}

	delete g_hBotsTimer;
	g_hCvar_BotLimit.IntValue++;
	g_hBotsTimer = CreateTimer(1.0, tmrBotsUpdate);
	CReplyToCommand(client, "%t", "IncreasedBotNumber", g_hCvar_BotLimit.IntValue);
	return Plugin_Handled;
}

static Action cmdDecreaseBot(int client, int args)
{
	if (!g_bRoundStart)
	{
		CPrintToChat(client, "%t", "RoundNotAlive");
		return Plugin_Handled;
	}

	delete g_hBotsTimer;
	g_hCvar_BotLimit.IntValue--;
	CReplyToCommand(client, "%t", "DecreasedBotNumber", g_hCvar_BotLimit.IntValue);
	return Plugin_Handled;
}
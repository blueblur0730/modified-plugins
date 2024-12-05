#if defined _server_management__vote_manager_included
    #endinput
#endif
#define _server_management__vote_manager_included

#define CONFIG_PATH "configs/vote_manager.cfg"
#define DEBUG_VM 0

#include <l4d2_nativevote>

static KeyValues kv[MAXPLAYERS + 1] = { null, ... };
static ConVar g_hCvar_Balancer = null;
static int g_iBalancer = 0;
static char g_sConfigPath[PLATFORM_MAX_PATH];

void _vote_manager_OnPluginStart()
{
    if (!BuildConfigPath())
        SetFailState("Config File \""...CONFIG_PATH..."\" Not Found.");

    LoadTranslation("server_management.vote_manager.phrases");
    g_hCvar_Balancer = CreateConVar("vote_manager_balancer", "2", "Yes vote count required to pass a vote. 1=1/3, 2=1/2, 3=2/3, 4=1/1", _, true, 1.0, true, 4.0);
    g_hCvar_Balancer.AddChangeHook(OnCvarChange);
    OnCvarChange(null, "", "");
    RegConsoleCmd("sm_vote", Cmd_Vote, "Open Vote Menu");
    RegAdminCmd("sm_restoreallhealth", Cmd_RestoreHealth, ADMFLAG_ROOT, "Restore Health");
}

void _vote_manager_OnPluginEnd()
{
    for (int i = 0; i < MaxClients; i++)
    {
        if (kv[i]) delete kv[i];
    }
}

static void OnCvarChange(ConVar convar, const char[] sOldValue, const char[] sNewValue)
{
    g_iBalancer = g_hCvar_Balancer.IntValue;
}

static Action Cmd_Vote(int client, int args)
{
    if (client <= 0 || client > MaxClients)
        return Plugin_Handled;

    if (!IsClientInGame(client) || IsFakeClient(client))
        return Plugin_Handled;

    if (GetClientTeam(client) == L4D2Team_Spectator)
    {
        CReplyToCommand(client, "%t", "NoSpectator");
        return Plugin_Handled;
    }

    // if no args, open the default vote menu.
    if (!args)
        OpenDefaultMenu(client);

    return Plugin_Handled;
}

static void OpenDefaultMenu(int client)
{
    static char sTitle[64];
    Format(sTitle, sizeof(sTitle), "%T", "VoteMenuTitle", client);
    Menu menu = new Menu(MenuHandle_TraversalHandler);
    menu.SetTitle(sTitle);

    if (!kv[client])
    {
#if DEBUG_VM
        PrintToServer("Creating new KeyValues for client %N", client);
#endif
        kv[client] = new KeyValues("");
        kv[client].ImportFromFile(g_sConfigPath);
    }
    
    kv[client].Rewind();
    if (kv[client].GotoFirstSubKey(false))
    {
        do
        {
            TraverseKeys(menu, client);
        }
        while (kv[client].GotoNextKey(false));
        kv[client].Rewind(false);

        if (!menu.ItemCount)
        {
            CPrintToChat(client, "%t", "NoVoteItem");
            delete menu;
            delete kv[client];
            return;
        }
        else
        {
            menu.Display(client, 30);
        }
    }
    else
    {
        CPrintToChat(client, "%t", "NoVoteItem");
        delete menu;
        delete kv[client];
        return;
    }
}

static void MenuHandle_TraversalHandler(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char sBuffer[MAX_MESSAGE_LENGTH], sDisplayBuffer[MAX_MESSAGE_LENGTH];
            menu.GetItem(param2, sBuffer, sizeof(sBuffer), _, sDisplayBuffer, sizeof(sDisplayBuffer));
#if DEBUG_VM
            PrintToServer("Item selected: %s", sBuffer);
#endif
            // this is a section
            if (kv[param1].JumpToKey(sBuffer))
            {
#if DEBUG_VM
                PrintToServer("Jumping to sub section %s", sBuffer);
#endif
                kv[param1].SavePosition();
                if (kv[param1].GotoFirstSubKey(false))
                {
                    Menu menu2 = new Menu(MenuHandle_TraversalHandler);
                    Format(sBuffer, sizeof(sBuffer), "%T", "VoteMenuTitle2", param1, sDisplayBuffer);
                    menu2.SetTitle(sBuffer);

                    do
                    {
                        TraverseKeys(menu2, param1);
                    }
                    while (kv[param1].GotoNextKey(false));
                    kv[param1].GoBack();

                    if (!menu2.ItemCount)
                    {
                        CPrintToChat(param1, "%t", "NoVoteItem");
                        OpenDefaultMenu(param1);
                        delete menu2;
                    }
                    else
                    {
                        menu2.ExitBackButton = true;
                        menu2.Display(param1, 30);
                    }
                }
            }
            else
            {
#if DEBUG_VM
                PrintToServer("Prepare to vote for %s", sBuffer);
#endif
                if (!L4D2NativeVote_IsAllowNewVote())
                {
                    CPrintToChat(param1, "%t", "VoteInProgress");
                    return;
                }
                    
                L4D2NativeVote vote = L4D2NativeVote(VoteHandler);
                vote.SetTitle("通过 %s?", sDisplayBuffer);
                vote.Initiator = param1;
                vote.SetInfo(sBuffer);

                int iPlayerCount = 0;
	            int[] iClients = new int[MaxClients];

	            for (int i = 1; i <= MaxClients; i++)
	            {
		            if (IsClientInGame(i) && !IsFakeClient(i))
		            {
			            if (GetClientTeam(i) == L4D2Team_Spectator)
				             continue;

			            iClients[iPlayerCount++] = i;
		            }
	            }

                if (!vote.DisplayVote(iClients, iPlayerCount, 20))
                {
                    CPrintToChat(param1, "%t", "VoteFailedDisPlay");
                    LogError("Vote failed to display.");
                }
                    
            }
        }

        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack)
                OpenDefaultMenu(param1);
        }

        case MenuAction_End: delete menu;
    }
}

static void VoteHandler(L4D2NativeVote vote, VoteAction action, int param1, int param2)
{
    switch (action)
    {
		case VoteAction_Start:
			CPrintToChatAllEx(param1, "%t", "HasInitiatedVote", param1);

		case VoteAction_PlayerVoted:
		{
			CPrintToChatAllEx(param1, "%t", "Voted", param1);

			switch (param2)
			{
				case VOTE_YES: vote.YesCount++;
				case VOTE_NO: vote.NoCount++;
			}
		}

		case VoteAction_End:
		{
            int iFactor = 2;
            switch (g_iBalancer)
            {
                case 1: iFactor = 3; 
                case 2: iFactor = 2;
                case 3: iFactor = -1;
                case 4: iFactor = 1;
                default: iFactor = 2;
            }

			if (vote.YesCount >= RoundToFloor(float(vote.PlayerCount) / float(iFactor == -1 ? 3 / 2 : iFactor)))
			{
				vote.SetPass("正在执行...");
                CPrintToChatAll("%t", "PassingVote");

				char sInfo[256];
				vote.GetInfo(sInfo, sizeof(sInfo));
				ServerCommand(sInfo);
                ServerExecute();
			}
			else
            {
                CPrintToChatAll("%t", "VoteFailed");
                vote.SetFail();
            }
		}
    }
}

static void TraverseKeys(Menu menu, int client)
{
    static char sBuffer[MAX_MESSAGE_LENGTH], sKeyValue[MAX_MESSAGE_LENGTH]; //sTranslated[MAX_MESSAGE_LENGTH];
	if (kv[client].GetSectionName(sBuffer, sizeof(sBuffer)))
    {
#if DEBUG_VM
        PrintToServer("Traversing section %s", sBuffer);
#endif
        kv[client].GetString(NULL_STRING, sKeyValue, sizeof(sKeyValue), "NoKeyValue");
#if DEBUG_VM
        PrintToServer("Retrieving keyvalue %s", sKeyValue);
#endif
        //Format(sTranslated, sizeof(sTranslated), "%T", client, sBuffer);
        if (StrEqual(sKeyValue, "NoKeyValue"))
            menu.AddItem(sBuffer, sBuffer);
        else
            menu.AddItem(sKeyValue, sBuffer);
    }
}

static Action Cmd_RestoreHealth(int client, int args)
{
	if (client > MaxClients)
		return Plugin_Handled;

    for (int i = 1; i < MaxClients; i++)
    {
        if (!IsClientInGame(i) || GetClientTeam(i) != L4D2Team_Survivor)
            continue;

	    if (view_as<bool>(GetEntProp(i, Prop_Send, "m_isIncapacitated")))
		    L4D_ReviveSurvivor(i);

	    SetEntPropFloat(i, Prop_Send, "m_healthBuffer", 0.0);
	    SetEntityHealth(i, GetEntProp(i, Prop_Data, "m_iMaxHealth"));
	    SetEntPropFloat(i, Prop_Send, "m_healthBufferTime", GetGameTime());
	    SetEntProp(i, Prop_Send, "m_isGoingToDie", 0);
	    SetEntProp(i, Prop_Send, "m_currentReviveCount", 0);
	    SetEntProp(i, Prop_Send, "m_bIsOnThirdStrike", 0);
	    StopSound(i, SNDCHAN_STATIC, "player/heartbeatloop.wav");
    }

    !client ? CPrintToChatAll("%t", "HealthRestoredConsole") : CPrintToChatAllEx(client, "%t", "HealthRestored", client);
    return Plugin_Handled;
}

static stock bool BuildConfigPath()
{
    BuildPath(Path_SM, g_sConfigPath, sizeof(g_sConfigPath), CONFIG_PATH);
    return FileExists(g_sConfigPath);
}
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colors>
#include <l4d2_nativevote>

#define CONFIG_PATH "configs/vote_manager.cfg"
#define MAX_VOTEPANEL_TITLE_LENGTH 64

KeyValues 	kv[MAXPLAYERS + 1] 	= { null, ... };
char		g_sConfigPath[PLATFORM_MAX_PATH];
char		g_sTitle[MAXPLAYERS + 1][MAX_VOTEPANEL_TITLE_LENGTH];

#define PLUGIN_VERSION "1.2"

public Plugin myinfo =
{
	name = "[Any/L4D2] Vote Manager",
	author = "blueblur",
	description = "Vote Manager 3000 with whatever you want config.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
	if (!BuildConfigPath())
		SetFailState("Config File \"" ... CONFIG_PATH... "\" Not Found.");

	LoadTranslation("vote_manager.phrases");
	CreateConVar("vote_manager_version", PLUGIN_VERSION, "Vote Manager Version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	RegConsoleCmd("sm_vote", Cmd_Vote, "Open Vote Menu");
}

public void OnPluginEnd()
{
	for (int i = 0; i < MaxClients; i++)
		if (kv[i]) delete kv[i];
}

Action Cmd_Vote(int client, int args)
{
	if (client <= 0 || client > MaxClients)
		return Plugin_Handled;

	if (!IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	if (GetClientTeam(client) == 1)
	{
		CReplyToCommand(client, "%t", "NoSpectator");
		return Plugin_Handled;
	}

	OpenDefaultMenu(client);
	return Plugin_Handled;
}

void OpenDefaultMenu(int client)
{
	static char sTitle[64];
	Format(sTitle, sizeof(sTitle), "%T", "VoteMenuTitle", client);
	Menu menu = new Menu(MenuHandle_TraversalHandler);
	menu.SetTitle(sTitle);

	if (!kv[client])
	{
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
		kv[client].Rewind();

		if (!menu.ItemCount)
		{
			CPrintToChat(client, "%t", "NoVoteItem");
			delete menu;
			delete kv[client];
			return;
		}
		else
		{
			menu.Display(client, MENU_TIME_FOREVER);
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

void MenuHandle_TraversalHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sBuffer[MAX_MESSAGE_LENGTH], sDisplayBuffer[MAX_MESSAGE_LENGTH];
			menu.GetItem(param2, sBuffer, sizeof(sBuffer), _, sDisplayBuffer, sizeof(sDisplayBuffer));

			// this is a section
			if (kv[param1].JumpToKey(sBuffer))
			{
				kv[param1].SavePosition();
				if (kv[param1].GotoFirstSubKey(false))
				{
					Menu menu2 = new Menu(MenuHandle_TraversalHandler);
					Format(sBuffer, sizeof(sBuffer), "%T", "VoteMenuTitle2", param1, sDisplayBuffer);
					menu2.SetTitle(sBuffer);

					g_sTitle[param1][0] != '\0' ?
					Format(g_sTitle[param1], sizeof(g_sTitle[param1]), "%s - %s", g_sTitle[param1], sDisplayBuffer) :
					Format(g_sTitle[param1], sizeof(g_sTitle[param1]), "%s", sDisplayBuffer);

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
						g_sTitle[param1] = "";
						delete menu2;
					}
					else
					{
						menu2.ExitBackButton = true;
						menu2.Display(param1, MENU_TIME_FOREVER);
					}
				}
			}
			else
			{
				if (!L4D2NativeVote_IsAllowNewVote())
				{
					CPrintToChat(param1, "%t", "VoteInProgress");
					return;
				}	

				g_sTitle[param1][0] != '\0' ?
				Format(g_sTitle[param1], sizeof(g_sTitle[param1]), "%s - %s", g_sTitle[param1], sDisplayBuffer) :
				Format(g_sTitle[param1], sizeof(g_sTitle[param1]), "%s", sDisplayBuffer);

				L4D2NativeVote vote = L4D2NativeVote(VoteHandler);
				vote.SetTitle("Pass %s?", g_sTitle[param1]);
				vote.Initiator = param1;
				vote.SetInfo(sBuffer);

				int iPlayerCount = 0;
				int[] iClients	 = new int[MaxClients];

				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && !IsFakeClient(i))
					{
						if (GetClientTeam(i) == 1)
							continue;

						iClients[iPlayerCount++] = i;
					}
				}

				if (!vote.DisplayVote(iClients, iPlayerCount, 20))
				{
					CPrintToChat(param1, "%t", "VoteFailedDisPlay");
					LogError("Vote failed to display.");
				}

				delete kv[param1];
				g_sTitle[param1] = "";
			}
		}

		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				g_sTitle[param1] = "";
				OpenDefaultMenu(param1);
			}	
		}

		case MenuAction_End: 
			delete menu;
	}
}

void VoteHandler(L4D2NativeVote vote, VoteAction action, int param1, int param2)
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
			if (vote.YesCount >= vote.PlayerCount)
			{
				vote.SetPass("Excuting...");
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

void TraverseKeys(Menu menu, int client)
{
	static char sBuffer[MAX_MESSAGE_LENGTH], sKeyValue[MAX_MESSAGE_LENGTH];
	if (kv[client].GetSectionName(sBuffer, sizeof(sBuffer)))
	{
		char sText[64];
		kv[client].GetString("required", sText, sizeof(sText));

		if (sText[0] != '\0')
		{
			Format(sText, sizeof(sText), "%s.smx", sText);
			if (!FindPluginByFileEx(sText, strlen(sText)))
				return;
		}

		kv[client].GetString(NULL_STRING, sKeyValue, sizeof(sKeyValue), "NoKeyValue");

		int iPos;
		if (FindSeperator(sKeyValue, iPos))
		{
			char sFileName[64];
			strcopy(sFileName, sizeof(sFileName), sKeyValue[iPos + 1]);
			Format(sFileName, sizeof(sFileName), "%s.smx", sFileName);

			if (!FindPluginByFileEx(sFileName, strlen(sFileName)))
				return;

			sKeyValue[iPos] = '\0';
		}

		if (!strcmp(sBuffer, "required"))
			return;

		strcmp(sKeyValue, "NoKeyValue") ?
		menu.AddItem(sKeyValue, sBuffer) :
		menu.AddItem(sBuffer, sBuffer);
	}
}

stock bool BuildConfigPath()
{
	BuildPath(Path_SM, g_sConfigPath, sizeof(g_sConfigPath), CONFIG_PATH);
	return FileExists(g_sConfigPath);
}

stock bool FindSeperator(const char[] sText, int &iPos)
{
	for (int i = 0; i < strlen(sText); i++)
	{
		if (sText[i] == '#')
		{
			iPos = i;
			return true;
		}
	}

	return false;
}

stock bool FindPluginByFileEx(const char[] filename, int length)
{
	char buffer[256];
	Handle iter = GetPluginIterator();
	Handle pl;
	
	while (MorePlugins(iter))
	{
		pl = ReadPlugin(iter);
		
		GetPluginFilename(pl, buffer, sizeof(buffer));
		if (strlen(buffer) == length)
		{
			if (!strcmp(buffer, filename, true))
			{
				delete iter;
				return true;
			}
		}
		else if (strlen(buffer) - length > 0)
		{
			if (!strcmp(buffer[strlen(buffer) - length], filename, true))
			{
				delete iter;
				return true;
			}
		}
	}
	
	delete iter;
	return false;
}

stock void LoadTranslation(const char[] translation)
{
	char sPath[PLATFORM_MAX_PATH], sName[64];
	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}
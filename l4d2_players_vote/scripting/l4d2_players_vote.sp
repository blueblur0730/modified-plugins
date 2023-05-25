#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <builtinvotes>
#include <colors>
#undef REQUIRE_PLUGIN
#include <sourcebanspp>
#include <l4dstats>
//#include <match_vote>
char
	LoadingCFG[1024],
	VotingDone[1024],
	KickDone[1024],
	BanDone[1024],
	Reason[1024];

bool g_bSourceBansSystemAvailable = false, g_bl4dstatsSystemAvailable = false;
public void OnAllPluginsLoaded(){
	g_bSourceBansSystemAvailable = LibraryExists("sourcebans++");
	g_bl4dstatsSystemAvailable = LibraryExists("l4d_stats");
}
public void OnLibraryAdded(const char[] name)
{
    if ( StrEqual(name, "sourcebans++") ) { g_bSourceBansSystemAvailable = true; }
	else if ( StrEqual(name, "l4d_stats") ) { g_bl4dstatsSystemAvailable = true; }
}
public void OnLibraryRemoved(const char[] name)
{
    if ( StrEqual(name, "sourcebans++") ) { g_bSourceBansSystemAvailable = true; }
	else if ( StrEqual(name, "l4d_stats") ) { g_bl4dstatsSystemAvailable = true; }
}

public Plugin myinfo =
{
	name = "Vote for run command or cfg file",
	description = "使用!vote投票执行命令或cfg文件",
	author = "东, Bred, merged and modified by blueblur",
	version = "2.0",
	url = "https://github.com/fantasylidong/ | https://gitee.com/honghl5/open-source-plug-in"
};
/*
1.0 版本 初始发布
1.1 版本 限制旁观使用投票功能
1.2 版本 旁观不参与投票
1.3 版本 增加Cvar控制投票文件, 1.11新语法, 增加sourcebans 1天封禁投票[分数大于300000]
////////////////////////////////
1.4 版本 移植大红投票插件部分代码，移植多语言翻译文本支持，移植投票回血功能, 移植提示无相关cfg文件提示
1.5 版本 全面翻译输出文字
1.5.1 版本 完善翻译代码
2.0 版本 移植投票玩家使其成为旁观功能, 增加显示哪个管理员取消了投票
2.0.1 版本 更正翻译文件部分错误
2.0.2 版本 sm_cancelvote > sm_votecancel (为了使文字输出有颜色, 不和sm自带命令输出同样的语句)
2.0.3 版本 旁观不可投票踢人ban人旁观人
2.0.4 版本 解决不能ban人的问题
*/

Handle
	g_hVote,
	g_hVoteKick,
	g_hVoteBan,
	g_hVoteSpec,
	g_hCfgsKV;

ConVar
	g_hVoteFilelocation;

char
	g_sCfg[128],
	g_sVoteFile[128];

int 
	banclient,
	kickclient,
	voteclient,
	specclient;

public void OnPluginStart()
{
	char g_sBuffer[128];
	g_hVoteFilelocation = CreateConVar("votecfgfile", "configs/cfgs.txt", "投票文件的位置(位于sourcemod/文件夹)", FCVAR_NOTIFY);
	//GetGameFolderName(g_sBuffer, sizeof(g_sBuffer));
	GetConVarString(g_hVoteFilelocation, g_sVoteFile, sizeof(g_sVoteFile));
	RegConsoleCmd("sm_vote", VoteRequest);
	RegConsoleCmd("sm_votekick", KickRequest);
	RegConsoleCmd("sm_voteban", BanRequest);
	RegConsoleCmd("sm_votespec", SpecRequest);
	RegAdminCmd("sm_votecancel", VoteCancle, ADMFLAG_GENERIC, "管理员终止此次投票", "", 0);
	RegAdminCmd("sm_hp", Command_ServerHp, ADMFLAG_ROOT);
	g_hVoteFilelocation.AddChangeHook(FileLocationChanged);
	g_hCfgsKV = CreateKeyValues("Cfgs", "", "");
	LoadTranslations("l4d2_players_vote.phrases");
	BuildPath(Path_SM, g_sBuffer, 128, g_sVoteFile);
	if (!FileToKeyValues(g_hCfgsKV, g_sBuffer))
	{
		SetFailState("无法加载%s文件!", g_sVoteFile);
	}
}

public void FileLocationChanged(ConVar convar, const char[] oldValue, const char[] newValue){
	char g_sBuffer[128];
	GetConVarString(g_hVoteFilelocation, g_sVoteFile, sizeof(g_sVoteFile));
	//GetGameFolderName(g_sBuffer, sizeof(g_sBuffer));
	g_hCfgsKV = CreateKeyValues("Cfgs", "", "");
	BuildPath(Path_SM, g_sBuffer, 128, g_sVoteFile);
	if (!FileToKeyValues(g_hCfgsKV, g_sBuffer))
	{
		SetFailState("无法加载%s文件!", g_sVoteFile);
	}
}

public Action VoteCancle(int client, int args)
{
	if (IsBuiltinVoteInProgress())
	{
		AdminId id = GetUserAdmin(client);
		if (id != INVALID_ADMIN_ID && GetAdminFlag(id, Admin_Ban)) // Check for specific admin flag
		{
			CPrintToChatAll("%t", "VoteCancel", client);		//"[{olive}vote{default}] {blue}管理员 {olive}%N{blue} 取消了当前投票!"
		}
		CancelBuiltinVote();
		return Plugin_Handled;
	}
	else
	{
		CPrintToChat(client, "%t", "VoteCancelFailed");		//"[{olive}vote{default}] {blue}没有投票在进行!"
	}
	return Plugin_Handled;
}

stock void CheatCommand(int Client, const char[] command, const char[] arguments)
{
	int admindata = GetUserFlagBits(Client);
	SetUserFlagBits(Client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(Client, admindata);
}

public Action Command_ServerHp(int client, any args)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			CheatCommand(i, "give", "health");
		}
	}
	CPrintToChatAll("%t", "VoteRestoreHealthPass", client);			//"[{olive}vote{default}] {blue}投票回血通过!"
	return Plugin_Handled;
}

// *************************
// 			生还者
// *************************
// 判断是否有效玩家 id，有效返回 true，无效返回 false
stock bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		return true;
	}
	else
	{
		return false;
	}
}

stock bool IsPlayer(int client)
{
	int team = GetClientTeam(client);
	return (team == 2 || team == 3);
}

bool FindConfigName(char[] cfg, char[] message, int maxlength)
{
	KvRewind(g_hCfgsKV);
	if (KvGotoFirstSubKey(g_hCfgsKV, true))
	{
		while (KvJumpToKey(g_hCfgsKV, cfg, false))
		{
			if (KvGotoNextKey(g_hCfgsKV, true))
			{
			}
		}
		KvGetString(g_hCfgsKV, "message", message, maxlength, "");
		return true;
	}
	return false;
}

public int ConfigsMenuHandler(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char sInfo[128];
		char sBuffer[128];
		int style;
		GetMenuItem(menu, param2, sInfo, sizeof(sInfo), style, sBuffer, sizeof(sBuffer));
		strcopy(g_sCfg, sizeof(g_sCfg), sInfo);
		if (!StrEqual(g_sCfg, "sm_votekick", true))
		{
			if (StartVote(param1, sBuffer))
			{
				FakeClientCommand(param1, "Vote Yes");
			}
			else
			{
				ShowVoteMenu(param1);
			}
		}
		else
		{
			FakeClientCommand(param1, "sm_votekick");
		}
	}
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	if (action == MenuAction_Cancel)
	{
		ShowVoteMenu(param1);
	}
	return 0;
}

public Action VoteRequest(int client, int args)
{
	if (!client)
	{
		return Plugin_Handled;
	}
	if (IsValidClient(client) && !IsPlayer(client))
	{
		CPrintToChat(client, "%t", "NoSpecVoteRequest");		//"[{olive}vote{default}] {blue}旁观者不允许投票执行命令或cfg文件!"
		return Plugin_Handled;
	}
	if (args > 0)
	{
		char sCfg[128];
		char sBuffer[256];
		GetCmdArg(1, sCfg, sizeof(sCfg));
		BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "../../cfg/%s", sCfg);
		if (DirExists(sBuffer))
		{
			FindConfigName(sCfg, sBuffer, sizeof(sBuffer));
			if (StartVote(client, sBuffer))
			{
				strcopy(g_sCfg, sizeof(g_sCfg), sCfg);
				FakeClientCommand(client, "Vote Yes");
			}
			return Plugin_Handled;
		}
	}
	ShowVoteMenu(client);
	return Plugin_Handled;
}

void ShowVoteMenu(int client)
{
	Handle hMenu = CreateMenu(VoteMenuHandler, MENU_ACTIONS_DEFAULT);
	SetMenuTitle(hMenu, "%t", "Select1");		//选择:
	char sBuffer[64];
	KvRewind(g_hCfgsKV);
	if (KvGotoFirstSubKey(g_hCfgsKV, true))
	{
		do {
			KvGetSectionName(g_hCfgsKV, sBuffer, sizeof(sBuffer));
			AddMenuItem(hMenu, sBuffer, sBuffer, ITEMDRAW_DEFAULT);
		} while (KvGotoNextKey(g_hCfgsKV, true));
	}
	DisplayMenu(hMenu, client, 20);
}

bool StartVote(int client, char[] cfgname)
{
	if (!IsBuiltinVoteInProgress())
	{
		char sBuffer[64];
		g_hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BUILTINVOTE_ACTIONS_DEFAULT);
		Format(sBuffer, 64, "%t", "Execute", cfgname);		//执行 '%s' ?
		SetBuiltinVoteArgument(g_hVote, sBuffer);
		SetBuiltinVoteInitiator(g_hVote, client);
		SetBuiltinVoteResultCallback(g_hVote, VoteResultHandler);
		DisplayBuiltinVoteToAllNonSpectators(g_hVote, 12);
		CPrintToChatAll("%t", "StartVote", client);		//"[{olive}vote{default}] {blue}%N 发起了一个投票"
		return true;
	}
	CPrintToChat(client, "%t", "AlreadyInProgress");		//"[{olive}vote{default}] {red}已经有一个投票正在进行."
	return false;
}

public Action KickRequest(int client, int args)
{
	if (!client)
	{
		return Plugin_Handled;
	}
	if (IsValidClient(client) && !IsPlayer(client))
	{
		CPrintToChat(client, "%t", "NoSpecVoteRequest");		//"[{olive}vote{default}] {blue}旁观者不允许投票执行命令或cfg文件!"
		return Plugin_Handled;
	}
	if (client && client <= MaxClients)
	{
		CreateVotekickMenu(client);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

void CreateVotekickMenu(int client)
{
	Handle menu = CreateMenu(Menu_Voteskick, MENU_ACTIONS_DEFAULT);
	char name[126];
	char info[128];
	char playerid[128];
	SetMenuTitle(menu, "%t", "SelectKick");		//选择踢出玩家
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			Format(playerid, sizeof(playerid), "%i", GetClientUserId(i));
			if (GetClientName(i, name, sizeof(name)))
			{
				Format(info, sizeof(info), "%s", name);
				AddMenuItem(menu, playerid, info, ITEMDRAW_DEFAULT);
			}
		}
		i++;
	}
	if (GetMenuItemCount(menu) == 0)
	{
		CPrintToChat(client, "%t", "VoteNonePlayer");
		delete menu;
		ShowVoteMenu(client);
	}
	else
	{
		SetMenuExitBackButton(menu, true);
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 30);	
	}
}

public int Menu_Voteskick(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char name[128];
		GetMenuItem(menu, param2, name, sizeof(name));
		kickclient = GetClientOfUserId(StringToInt(name));
		CPrintToChatAll("%t", "VoteKickCilent", param1, kickclient);			//"[{olive}vote{default}] {blue}%N {default}发起投票踢出 {blue} %N"
		if (DisplayVoteKickMenu(param1))
		{
			FakeClientCommand(param1, "Vote Yes");
		}
	}
	return 0;
}

public bool DisplayVoteKickMenu(int client)
{
	if (!IsBuiltinVoteInProgress())
	{
		char sBuffer[128];
		g_hVoteKick = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BUILTINVOTE_ACTIONS_DEFAULT);
		Format(sBuffer, 128, "%t", "Kick", kickclient);		//踢出 '%N' ?
		SetBuiltinVoteArgument(g_hVoteKick, sBuffer);
		SetBuiltinVoteInitiator(g_hVoteKick, client);
		SetBuiltinVoteResultCallback(g_hVoteKick, VoteResultHandler);
		DisplayBuiltinVoteToAllNonSpectators(g_hVoteKick, 10);
		CPrintToChatAll("%t", "StartVote", client);			//"[{olive}vote{default}] {blue}%N 发起了一个投票"
		return true;
	}
	CPrintToChat(client, "%t", "AlreadyInProgress");		//"[{olive}vote{default}] {red}已经有一个投票正在进行."
	return false;
}

public Action BanRequest(int client, int args)
{
	if (!client)
	{
		return Plugin_Handled;
	}
	if (IsValidClient(client) && !IsPlayer(client))
	{
		CPrintToChat(client, "%t", "NoSpecVoteRequest");		//"[{olive}vote{default}] {blue}旁观者不允许投票执行命令或cfg文件!"
		return Plugin_Handled;
	}
	if(g_bl4dstatsSystemAvailable){
		if(l4dstats_GetClientScore(client) < 100000){
			CPrintToChat(client, "%t", "BanningRequirePoints");		//"[{olive}vote{default}] {red}未防止封禁被乱用，需要10w以上积分玩家才能使用."
			return Plugin_Handled;
		}else{
			CPrintToChat(client, "%t", "PowerWarning");			//"[{olive}vote{default}] {red}请谨慎使用您的权力，乱用封禁会导致您的账户面临封禁（首次7天，第二次一个月，第三次永久）."
		}
	}
	if (client && client <= MaxClients)
	{
		CreateVoteBanMenu(client);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

void CreateVoteBanMenu(int client)
{
	Handle menu = CreateMenu(Menu_VotesBan, MENU_ACTIONS_DEFAULT);
	char name[126];
	char info[128];
	char playerid[128];
	SetMenuTitle(menu, "%t", "SelectBan");		//选择封禁玩家
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			Format(playerid, sizeof(playerid), "%i", GetClientUserId(i));
			if (GetClientName(i, name, sizeof(name)))
			{
				Format(info, sizeof(info), "%s", name);
				AddMenuItem(menu, playerid, info, ITEMDRAW_DEFAULT);
			}
		}
		i++;
	}
	if (GetMenuItemCount(menu) == 0)
	{
		CPrintToChat(client, "%t", "VoteNonePlayer");
		delete menu;
		ShowVoteMenu(client);
	}
	else
	{
		SetMenuExitBackButton(menu, true);
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 30);	
	}
}

public int Menu_VotesBan(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char name[128];
		GetMenuItem(menu, param2, name, sizeof(name));
		banclient = GetClientOfUserId(StringToInt(name));
		CPrintToChatAll("%t", "VoteBanClient", param1, banclient);		//"[{olive}vote{default}] {blue}%N {default}发起投票封禁 {blue} %N 一天"
		voteclient = param1;
		if (DisplayVoteBanMenu(param1))
		{
			FakeClientCommand(param1, "Vote Yes");
		}
	}
	return 0;
}

public bool DisplayVoteBanMenu(int client)
{
	if (!IsBuiltinVoteInProgress())
	{
		int iNumPlayers;
		int iPlayers[MAXPLAYERS];
		int i = 1;
		while (i <= MaxClients)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				iNumPlayers++;
				iPlayers[iNumPlayers] = i;
			}
			i++;
		}
		char sBuffer[128];
		g_hVoteBan = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BUILTINVOTE_ACTIONS_DEFAULT);
		Format(sBuffer, 128, "%t", "OneDay", banclient);		//封禁 '%N' 一天?
		SetBuiltinVoteArgument(g_hVoteBan, sBuffer);
		SetBuiltinVoteInitiator(g_hVoteBan, client);
		SetBuiltinVoteResultCallback(g_hVoteBan, VoteResultHandler);
		DisplayBuiltinVoteToAll(g_hVoteBan, 10);
		CPrintToChatAll("%t", "StartVote", client);			//"[{olive}vote{default}] {blue}%N 发起了一个投票"
		return true;
	}
	CPrintToChat(client, "%t", "AlreadyInProgress");			//"[{olive}vote{default}] {red}已经有一个投票正在进行."
	return false;
}

public Action SpecRequest(int client, int args)
{
	if (!client)
	{
		return Plugin_Handled;
	}
	if (IsValidClient(client) && !IsPlayer(client))
	{
		CPrintToChat(client, "%t", "NoSpecVoteRequest");		//"[{olive}vote{default}] {blue}旁观者不允许投票执行命令或cfg文件!"
		return Plugin_Handled;
	}
	if (client && client <= MaxClients)
	{
		CreateVoteSpecMenu(client);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

void CreateVoteSpecMenu(int client)
{
	Handle menu = CreateMenu(Menu_VotesSpec, MENU_ACTIONS_DEFAULT);
	char name[126];
	char info[128];
	char playerid[128];
	SetMenuTitle(menu, "%t", "SelectSpec");		//选择踢出玩家
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			Format(playerid, sizeof(playerid), "%i", GetClientUserId(i));
			if (GetClientName(i, name, sizeof(name)))
			{
				Format(info, sizeof(info), "%s", name);
				AddMenuItem(menu, playerid, info, ITEMDRAW_DEFAULT);
			}
		}
		i++;
	}
	if (GetMenuItemCount(menu) == 0)
	{
		CPrintToChat(client, "%t", "VoteNonePlayer");
		delete menu;
		ShowVoteMenu(client);
	}
	else
	{
		SetMenuExitBackButton(menu, true);
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 30);	
	}
}

public int Menu_VotesSpec(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char name[128];
		GetMenuItem(menu, param2, name, sizeof(name));
		specclient = GetClientOfUserId(StringToInt(name));
		CPrintToChatAll("%t", "VoteSpecClient", param1, specclient);		//"[{olive}vote{default}] {blue}%N {default}发起投票使{blue} %N {default}成为旁观者"
		voteclient = param1;
		if (DisplayVoteSpecMenu(param1))
		{
			FakeClientCommand(param1, "Vote Yes");
		}
	}
	return 0;
}

public bool DisplayVoteSpecMenu(int client)
{
	if (!IsBuiltinVoteInProgress())
	{
		int iNumPlayers;
		int iPlayers[MAXPLAYERS];
		int i = 1;
		while (i <= MaxClients)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				iNumPlayers++;
				iPlayers[iNumPlayers] = i;
			}
			i++;
		}
		char sBuffer[128];
		g_hVoteSpec = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BUILTINVOTE_ACTIONS_DEFAULT);
		Format(sBuffer, 128, "%t", "Spec", kickclient);		//使 '%N' 旁观 ?
		SetBuiltinVoteArgument(g_hVoteSpec, sBuffer);
		SetBuiltinVoteInitiator(g_hVoteSpec, client);
		SetBuiltinVoteResultCallback(g_hVoteSpec, VoteResultHandler);
		DisplayBuiltinVoteToAllNonSpectators(g_hVoteSpec, 10);
		CPrintToChatAll("%t", "StartVote", client);			//"[{olive}vote{default}] {blue}%N 发起了一个投票"
		return true;
	}
	CPrintToChat(client, "%t", "AlreadyInProgress");		//"[{olive}vote{default}] {red}已经有一个投票正在进行."
	return false;
}

public int VoteMenuHandler(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char sInfo[128];
		char sBuffer[128];
		GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
		KvRewind(g_hCfgsKV);
		if (KvJumpToKey(g_hCfgsKV, sInfo, false) && KvGotoFirstSubKey(g_hCfgsKV, true))
		{
			Handle hMenu = CreateMenu(ConfigsMenuHandler, MENU_ACTIONS_DEFAULT);
			Format(sBuffer, sizeof(sBuffer), "%t", "Select2", sInfo);		//选择 %s :
			SetMenuTitle(hMenu, sBuffer);
			do {
				KvGetSectionName(g_hCfgsKV, sInfo,  sizeof(sInfo));
				KvGetString(g_hCfgsKV, "message", sBuffer, sizeof(sBuffer), "");
				AddMenuItem(hMenu, sInfo, sBuffer, ITEMDRAW_DEFAULT);
			} while (KvGotoNextKey(g_hCfgsKV, true));
			DisplayMenu(hMenu, param1, 20);
		}
		else
		{
			CPrintToChat(param1, "%t", "RelatedFileNoExist");		//"[{olive}vote{default}] {red}没有相关的文件存在."
			ShowVoteMenu(param1);
		}
	}
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	return 0;
}

public void VoteActionHandler(Handle vote, BuiltinVoteAction action, int param1, int param2)
{
	switch (action)
	{
		case BuiltinVoteAction_End:
		{
			g_hVote = INVALID_HANDLE;
			CloseHandle(vote);
		}
		case BuiltinVoteAction_Cancel:
		{
			DisplayBuiltinVoteFail(vote, view_as<BuiltinVoteFailReason>(param1));
		}
	}
}

public void VoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (int i = 0; i< num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_votes / 2))
			{
				if (g_hVote == vote)
				{
					Format(LoadingCFG, sizeof(LoadingCFG), "%t", "LoadingCFG");
					DisplayBuiltinVotePass(vote, LoadingCFG);		//Cfg文件正在加载...
					ServerCommand("%s", g_sCfg);
					return;
				}
				if (g_hVoteKick == vote)
				{
					Format(VotingDone, sizeof(VotingDone), "%t", "VotingDone");
					Format(KickDone, sizeof(KickDone), "%t", "KickDone");
					DisplayBuiltinVotePass(vote, VotingDone);		//投票已完成...
					KickClient(kickclient, KickDone);		//投票踢出
					return;
				}
				if (g_hVoteBan == vote)
				{
					DisplayBuiltinVotePass(vote, VotingDone);
					if(g_bSourceBansSystemAvailable)
					{
						Format(BanDone ,sizeof(BanDone), "%t", "BanDone");
						SBPP_BanPlayer(voteclient, banclient, 1440, BanDone);		//投票封禁
						return;
					}
					else
					{
						Format(Reason, sizeof(Reason), "%t", "Reason");
						Format(BanDone ,sizeof(BanDone), "%t", "BanDone");
						//ServerCommand("sm_ban %N %i %s", banclient, 1440, Reason);
						BanClient(banclient, 1440, BANFLAG_AUTO, BanDone, Reason);		//你已被当前服务器踢出，原因为投票封禁
						return;
					}
				}
				if (g_hVoteSpec == vote)
				{
					Format(VotingDone, sizeof(VotingDone), "%t", "VotingDone");
					DisplayBuiltinVotePass(vote, VotingDone);		//投票已完成...
					ServerCommand("sm_swapto 1 %N", specclient);		// 需要playermanagement.smx
					CPrintToChatAll("%t", "SpecDone", specclient);		//"[{olive}vote{default}] ({olive}%N){blue} 已被投票至旁观者."
					return;
				}
			}
		}
	}
	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}
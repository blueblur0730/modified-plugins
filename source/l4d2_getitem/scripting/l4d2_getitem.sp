#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <sdktools>
#include <colors>

/*
#undef REQUIRE_PLUGIN
#include <clientprefs>	
*/

#define NAME 			"L4D2 Item acquisition Plugin | L4D2物品获取插件"			//定义插件名字
#define AUTHOR 			"绪花✧(≖ ◡ ≖✿) | Ross | 鱼鱼 | blueblur"				//定义作者
#define DESCRIPTION 	"L4D2 Item acquisition Plugin | L4D2物品获取插件"			//定义插件描述
#define VERSION 		"1.3.1"														//定义插件版本
#define URL 			"https://steamcommunity.com/profiles/76561198100717207/"	//定义作者联系地址
/**
 * Original authors: 绪花✧(≖ ◡ ≖✿) | Ross | 鱼鱼
 * Replenishment author: blueblur
 * 
 * changelog:
 * 
 * 1.0.0:
 * 	- initial version by oringinal authors.
 * 
 * 1.1.0:
 *  - added optional readyup function. cvar support.
 * 
 * 1.1.1:
 * 	- added gamemode support. support coop/realism, versus, scavenge
 * 
 * 1.2.0:
 *  - added reqeust limit functions. cvar support.
 * 
 * 1.2.1:
 *  - optimized codes. issue fixing.
 * 
 * 1.2.2:
 * 	- added chat ad reminder, cvar support.
 * 
 * 1.3.0:
 *  - fully translation support. due to code format items on the menu only support sChi/En language (since we use string arrays).
 * 
 * 1.3.1:
 *  - ad logic optimized. more translations to remind player.
 * 
 * to do:
 *  - add cookie function, save players' preferences and choose whether automatically give their preferred weapons on the start or not. (also could be done by SQL, but really necessary?)
 * 
*/
#define IsValidPlayer(%1)	(%1 && IsClientInGame(%1) && GetClientTeam(%1) == 2 && IsPlayerAlive(%1))//&& !IsFakeClient(%1) 


public Plugin myinfo =
{
	name			=	NAME,
	author			=	AUTHOR,
	description		=	DESCRIPTION,
	version			=	VERSION,
	url				=	URL
};

ConVar g_hcmeleedefault, g_hcinitialgundefault, g_hcsafearea, g_hcAdvancedGunOpen,
		g_hcThrowableOpen, g_hcUseReadyup, g_hcEnableLimit, g_hcRequestCount, g_hcAd, g_hcAdTimer;
// char KVPath[PLATFORM_MAX_PATH];

Handle g_hTimer = null;

bool
	g_bmeleedefault,
	g_binitialgundefault,
	g_bsafearea,
	g_bMenuAdvancedGunOpen,
	g_bMenuThrowableOpen,
	g_bUseReadyup,
	g_bEnableLimit,
	g_bAd;

bool g_bReadyUpAvailable = true;

int 
	g_iRequestCount,
	g_iArrayCount[MAXPLAYERS + 1];

float g_fAdTimer;
	
static const char
	g_sMeleeModels[][] = {
		"models/weapons/melee/v_fireaxe.mdl",
		"models/weapons/melee/w_fireaxe.mdl",
		"models/weapons/melee/v_frying_pan.mdl",
		"models/weapons/melee/w_frying_pan.mdl",
		"models/weapons/melee/v_machete.mdl",
		"models/weapons/melee/w_machete.mdl",
		"models/weapons/melee/v_bat.mdl",
		"models/weapons/melee/w_bat.mdl",
		"models/weapons/melee/v_crowbar.mdl",
		"models/weapons/melee/w_crowbar.mdl",
		"models/weapons/melee/v_cricket_bat.mdl",
		"models/weapons/melee/w_cricket_bat.mdl",
		"models/weapons/melee/v_tonfa.mdl",
		"models/weapons/melee/w_tonfa.mdl",
		"models/weapons/melee/v_katana.mdl",
		"models/weapons/melee/w_katana.mdl",
		"models/weapons/melee/v_electric_guitar.mdl",
		"models/weapons/melee/w_electric_guitar.mdl",
		"models/v_models/v_knife_t.mdl",
		"models/w_models/weapons/w_knife_t.mdl",
		"models/weapons/melee/v_golfclub.mdl",
		"models/weapons/melee/w_golfclub.mdl",
		"models/weapons/melee/v_shovel.mdl",
		"models/weapons/melee/w_shovel.mdl",
		"models/weapons/melee/v_pitchfork.mdl",
		"models/weapons/melee/w_pitchfork.mdl",
		"models/weapons/melee/v_riotshield.mdl",
		"models/weapons/melee/w_riotshield.mdl"
	};

static const char
	g_sWeaponName[4][18][] =
	{
		{	//slot 0()
			"katana","fireaxe","machete","knife","pistol","pistol_magnum",
			"chainsaw","frying_pan","baseball_bat","crowbar","cricket_bat",
			"tonfa","electric_guitar","golfclub","shovel","pitchfork","riotshield",""
		},

		{	//slot 1()
			"pumpshotgun","shotgun_chrome","smg","smg_silenced","smg_mp5","ammo",
			"","","","","","","","","","","","",
		},

		{	//slot 2()
			"autoshotgun","shotgun_spas","hunting_rifle","sniper_military","rifle",
			"rifle_desert","rifle_ak47","rifle_sg552","sniper_scout","sniper_awp",
			"rifle_m60","grenade_launcher","","","","","","",
		},

		{	//slot 3()
			"first_aid_kit","defibrillator","pain_pills","adrenaline","molotov","pipe_bomb",
			"vomitjar","upgradepack_incendiary","upgradepack_explosive","gascan","propanetank",
			"oxygentank","fireworkcrate","cola_bottles","gnome","incendiary_ammo","explosive_ammo",
			"laser_sight",
		},
	};

static const char
	g_sItemNameChi[4][18][] =
	{
		{	/*slot 0()*/
			"武士刀","消防斧","砍刀","小刀","手枪","马格南","电锯",
			"平底锅","棒球棒","撬棍","板球棒","警棍","吉他","高尔夫",
			"铲子","草叉","防爆盾","",
		},

		{	/*slot 1()*/
			"木喷","铁喷","UZI微冲","消音微冲","MP5","备弹",
			"","","","","","","","","","","","",
		},

		{	/*slot 2()*/
			"一代连喷","二代连喷","木狙","军狙","M-16","SCAR","AK-47","SG552",
			"鸟狙","AWP","M60","榴弹发射器","","","","","","",
		},

		{	/*slot 3()*/
			"医疗包","除颤仪","止痛药","肾上腺素","燃烧瓶","土制炸弹","胆汁瓶",
			"燃烧弹药包","高爆弹药包","汽油桶","煤气罐","氧气瓶","烟花箱","可乐瓶",
			"小侏儒","燃烧弹药","高爆弹药","激光瞄准器",
		},
	};

static const char
	g_sItemNameEn[4][18][] =
	{
		{	/*slot 0()*/
			"Katana","Axe","Machete","Knife","Pistol","Deagle","Chainsaw","Frying Pan",
			"Baseball Bat","Crowbar","Cricket Bat","Tonfa","Guitar","Golf Club","Shovel",
			"Pitchfork","Riot Shield","",
		},

		{	/*slot 1()*/
			"Pump Shotgun","Chrome Shotgun","Uzi","Mac-10","MP5","Ammo",
			"","","","","","","","","","","","",
		},

		{	/*slot 2()*/
			"Autoshotgun","SPAS Shotgun","Hunting Rifle","Military Sniper","M-16",
			"Desert Rifle","AK-47","SG552","Scout","AWP","M60","Grenade Launcher",
			"","","","","","",
		},

		{	/*slot 3()*/
			"First Aid Kit","Defibrillator","Pills","Adrenaline","Molotov","Pipe Bomb",
			"Bile Bomb","Incendiary Ammo Pack","Explosive Ammo Pack","Gascan","Propane Tank",
			"Oxygen Tank","Fireworks","Cola Bottles","Gnome","Incendiary Ammo","Explosive Ammo",
			"Laser Sight",
		},
	};
	
public void OnPluginStart()
{
	RegAdminCmd("sm_getitem", Command_Item, ADMFLAG_GENERIC, "物品获取");
	//RegClientCookie("ERPrefs", "Weapon prefs on start", CookieAccess_Protected);
	
	g_hcmeleedefault		= CreateConVar("l4d2_er_meleedefault",		"1",	"默认是否开启副武器菜单",							FCVAR_NONE, true, 0.0, true, 1.0);
	g_hcinitialgundefault	= CreateConVar("l4d2_er_initialgundefault",	"1",	"默认是否开启小枪菜单",								FCVAR_NONE, true, 0.0, true, 1.0);
	g_hcsafearea			= CreateConVar("l4d2_er_safearea",			"1",	"默认是否限制安全区域内使用",						FCVAR_NONE, true, 0.0, true, 1.0);
	g_hcAdvancedGunOpen		= CreateConVar("l4d2_er_AdvancedGunOpen",	"0",	"默认是否开启大枪菜单",								FCVAR_NONE, true, 0.0, true, 1.0);
	g_hcThrowableOpen		= CreateConVar("l4d2_er_ThrowableOpen",		"0",	"默认是否开启物品菜单",								FCVAR_NONE, true, 0.0, true, 1.0);
	g_hcUseReadyup			= CreateConVar("l4d2_er_UseReadyup",		"1",	"默认是否额外搭配使用ReadyUp插件 (没有也不影响)",	FCVAR_NONE, true, 0.0, true, 1.0);
	g_hcEnableLimit			= CreateConVar("l4d2_er_EnableLimit",		"1",	"默认是否开启限制获取次数", 						FCVAR_NONE, true, 0.0, true, 1.0);
	g_hcRequestCount		= CreateConVar("l4d2_er_RequestCount",		"4",	"限制获取武器次数",									FCVAR_NONE);
	g_hcAd					= CreateConVar("l4d2_er_Ad",				"1",	"默认是否开启E+R广告提示",							FCVAR_NONE, true, 0.0, true, 1.0);
	g_hcAdTimer				= CreateConVar("l4d2_er_AdTimer",			"120.0","广告间隔",											FCVAR_NONE);		
	
	GetOtherCvars();
	g_hcmeleedefault.AddChangeHook(IsOtherConVarChanged);
	g_hcinitialgundefault.AddChangeHook(IsOtherConVarChanged);
	g_hcsafearea.AddChangeHook(IsOtherConVarChanged);
	g_hcAdvancedGunOpen.AddChangeHook(IsOtherConVarChanged);
	g_hcThrowableOpen.AddChangeHook(IsOtherConVarChanged);
	g_hcUseReadyup.AddChangeHook(IsOtherConVarChanged);
	g_hcEnableLimit.AddChangeHook(IsOtherConVarChanged);
	g_hcRequestCount.AddChangeHook(IsOtherConVarChanged);
	g_hcAd.AddChangeHook(IsOtherConVarChanged);
	g_hcAdTimer.AddChangeHook(IsOtherConVarChanged);

	if (L4D_IsVersusMode() || L4D2_IsScavengeMode())
		HookEvent("round_start", Event_RoundStart, EventHookMode_Post);

	if (L4D2_IsScavengeMode())
		HookEvent("scavenge_round_finished", Event_ScavRoundFinished, EventHookMode_Post);

	if (g_bEnableLimit)
		HookEvent("mission_lost", Event_MissionLost, EventHookMode_Post);

	LoadTranslations("l4d2_getitem.phrases");
}

public void IsOtherConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetOtherCvars();
}

void GetOtherCvars()
{
	g_bmeleedefault			=	g_hcmeleedefault.BoolValue;
	g_binitialgundefault	=	g_hcinitialgundefault.BoolValue;
	g_bsafearea				=	g_hcsafearea.BoolValue;
	g_bMenuAdvancedGunOpen	=	g_hcAdvancedGunOpen.BoolValue;
	g_bMenuThrowableOpen	=	g_hcThrowableOpen.BoolValue;
	g_bUseReadyup			=	g_hcUseReadyup.BoolValue;
	g_bEnableLimit			=	g_hcEnableLimit.BoolValue;
	g_iRequestCount			=	g_hcRequestCount.IntValue;
	g_bAd					=	g_hcAd.BoolValue;
	g_fAdTimer				=	g_hcAdTimer.FloatValue;
}

public void OnMapStart() 
{
	for (int i; i < sizeof g_sMeleeModels; i++) 
	{
		if (!IsModelPrecached(g_sMeleeModels[i]))
			PrecacheModel(g_sMeleeModels[i], true);
	}

	if (g_bAd && g_hTimer == null)
		g_hTimer = CreateTimer(g_fAdTimer, Timer_Ad, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapEnd()
{
	delete g_hTimer;
}

public Action Timer_Ad(Handle Timer)
{
	if (g_bReadyUpAvailable)
		g_bEnableLimit ? CPrintToChatAll("%t", "Advertisement_Readyup_Limit", g_iRequestCount) : CPrintToChatAll("%t", "Advertisement_Readyup");
	else
		g_bEnableLimit ? CPrintToChatAll("%t", "Advertisement_Limit", g_iRequestCount) : CPrintToChatAll("%t", "Advertisement");
		
	return Plugin_Continue;
}

public void L4D_OnGameModeChange(int gamemode)
{
	switch (gamemode)
	{
		case GAMEMODE_COOP: {if (g_bEnableLimit) HookEvent("mission_lost", Event_MissionLost, EventHookMode_Post);}
		case GAMEMODE_VERSUS: {HookEvent("round_start", Event_RoundStart, EventHookMode_Post);}
		case GAMEMODE_SCAVENGE: {HookEvent("round_start", Event_RoundStart, EventHookMode_Post); HookEvent("scavenge_round_finished", Event_ScavRoundFinished, EventHookMode_Post);}
	}
}

public void Event_RoundStart(Event hEvent, char[] sName, bool dontBroadcast)
{
	if (g_bEnableLimit)
	{
		for (int i; i < MaxClients; i++) 
			g_iArrayCount[i] = 0;
	}
}

public void Event_MissionLost(Event hEvent, char[] sName, bool dontBroadcast)
{
	if (g_bEnableLimit)
	{
		for (int i; i < MaxClients; i++) 
			g_iArrayCount[i] = 0;
	}
}

public void Event_ScavRoundFinished(Event hEvent, char[] sName, bool dontBroadcast)
{
	if (g_bEnableLimit)
	{
		for (int i; i < MaxClients; i++) 
			g_iArrayCount[i] = 0;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (g_bUseReadyup)
		if (StrEqual(name, "readyup")) g_bReadyUpAvailable = false;
}

public void OnLibraryAdded(const char[] name)
{
	if (g_bUseReadyup)
		if (StrEqual(name, "readyup")) g_bReadyUpAvailable = true;
}

public void OnRoundIsLive()
{
	if (g_bUseReadyup)
		g_bReadyUpAvailable = false;
}

public void OnReadyUpInitiate()
{
	if (g_bUseReadyup)
		g_bReadyUpAvailable = true;
}

public Action Command_Item(int client, int args)
{
	if (client && IsClientInGame(client))
		ChooseItem(client);
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (IsValidPlayer(client))
	{
		if (buttons & (IN_RELOAD | IN_USE) == IN_RELOAD | IN_USE) 
		{
			ChooseItem(client);
			if(buttons == (IN_RELOAD | IN_USE))
				buttons &= ~IN_USE;
		}
	}
	return Plugin_Continue;
}

void ChooseItem(int client)
{
	if (GetClientTeam(client) == 2 || GetUserFlagBits(client) > 0)		// you are the admin.
	{
		SetGlobalTransTarget(client);

		char title[64], secondaryon[64], secondaryoff[64], Tier1on[64], Tier1off[64], Tier2on[64], Tier2off[64], itemon[64], itemoff[64];
		Format(title, sizeof(title), "%t", "MainTitle"); 
		Format(secondaryon, sizeof(secondaryon), "%t", "SecondaryOn"); Format(secondaryoff, sizeof(secondaryoff), "%t", "SecondaryOff");
		Format(Tier1on, sizeof(Tier1on), "%t", "Tier1On"); Format(Tier1off, sizeof(Tier1off), "%t", "Tier1Off");
		Format(Tier2on, sizeof(Tier2on), "%t", "Tier2On"); Format(Tier2off, sizeof(Tier2off), "%t", "Tier2Off");
		Format(itemon, sizeof(itemon), "%t", "ItemOn");	Format(itemoff, sizeof(itemoff), "%t", "ItemOff");

		Menu menu = new Menu(Menu_HandlerFunction);
		SetMenuTitle(menu, title);
		menu.AddItem("a", g_bmeleedefault ? secondaryon : secondaryoff);	//"副武器            ★启用"
		menu.AddItem("b", g_binitialgundefault ? Tier1on : Tier1off);	//"小枪            ★启用"
		menu.AddItem("c", g_bMenuAdvancedGunOpen ? Tier2on : Tier2off);		//"大枪            ✰禁用"
		menu.AddItem("d", g_bMenuThrowableOpen ? itemon : itemoff);	//"物品            ★启用"

		char adminmenu[64];
		Format(adminmenu, sizeof(adminmenu), "%t", "AdminMenu");
		if (iGetClientImmunityLevel(client) > 49) 
			menu.AddItem("e", adminmenu);

		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

int Menu_HandlerFunction(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End:
			delete menu;
		case MenuAction_Select:
		{
			if (g_bReadyUpAvailable)
			{
				char sItem[2];
				if(menu.GetItem(itemNum, sItem, sizeof(sItem)))
				{
					switch(sItem[0])
					{
						case 'a':
							if(g_bmeleedefault)
								MenuGetMelee(client);
						case 'b':
							if(g_binitialgundefault)
								MenuGetInitialGun(client);
						case 'c':
							if(g_bMenuAdvancedGunOpen)
								MenuGetAdvancedGun(client);
						case 'd':
							if(g_bMenuThrowableOpen)
								MenuGetThrowable(client);
						case 'e':
							Menuadmin(client);
					}
				}
			}
			else
				CPrintToChat(client, "%t", "RoundStarted");
		}
	}
	return 0;
}

void MenuGetMelee(int client) 
{
	char secondary[64];
	Format(secondary, sizeof(secondary), "%t", "Secondary");
	Menu menu = new Menu(iMelees_MenuHandler);
	menu.SetTitle(secondary);
	for (int i = 0; i < 17; i++)
	{
		menu.AddItem(g_sWeaponName[0][i], (SpecifyLanguage(client)) ? g_sItemNameChi[0][i] : g_sItemNameEn[0][i]);
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int iMelees_MenuHandler(Menu menu, MenuAction action, int client, int param2) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			if((g_bsafearea && IsClientInSafeArea(client)) || !g_bsafearea)
			{
				int weaponid = GetPlayerWeaponSlot(client, 1);
				if (IsValidEntity(weaponid))
				{
					char classname[32];
					GetEntPropString(weaponid, Prop_Data, "m_ModelName", classname, sizeof(classname));
					if(StrContains(classname, g_sWeaponName[0][param2], false) == -1 || StrContains(classname, "pistol", false) !=-1)
					{
						char line[32];
						FormatEx(line, sizeof line, "give %s", g_sWeaponName[0][param2]);

						if (g_bEnableLimit)
						{
							if (g_iRequestCount > g_iArrayCount[client])
							{
								vCheatCommand(client, line);
								g_iArrayCount[client]++;
								CPrintToChatAll("%t", "GetItemWithLimit", client, (SpecifyLanguage(client)) ? g_sItemNameChi[0][param2] : g_sItemNameEn[0][param2], g_iArrayCount[client], g_iRequestCount);
							}
							else
								CPrintToChat(client, "%t", "ReachedLimit", g_iRequestCount);
						}
						else
						{	
							vCheatCommand(client, line);
							CPrintToChatAll("%t", "GetItem", client, (SpecifyLanguage(client)) ? g_sItemNameChi[0][param2] : g_sItemNameEn[0][param2]);
						}
					}
					else
						return 0;
				}
			}
			else
				CPrintToChat(client, "%t", "UseItInSafeRoom");
		}
		case MenuAction_Cancel: 
		{
			if (param2 == MenuCancel_ExitBack)
				ChooseItem(client);
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

void MenuGetInitialGun(int client) 
{
	char Tier1[64];
	Format(Tier1, sizeof(Tier1), "%t", "Tier1");
	Menu menu = new Menu(iInitialGun_MenuHandler);
	menu.SetTitle(Tier1);
	for (int i = 0; i < 6; i++)
	{
		menu.AddItem(g_sWeaponName[1][i], (SpecifyLanguage(client)) ? g_sItemNameChi[1][i] : g_sItemNameEn[1][i]);
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int iInitialGun_MenuHandler(Menu menu, MenuAction action, int client, int param2) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			if((g_bsafearea && IsClientInSafeArea(client)) || !g_bsafearea)
			{
				int weaponid = GetPlayerWeaponSlot(client, 0);
				if (IsValidEntity(weaponid))
				{
					char classname[32];
					GetEntityClassname(weaponid, classname, sizeof(classname));
					if(StrContains(classname, g_sWeaponName[1][param2], true) != -1)
						return 0;
					else
					{
						char line[32];
						FormatEx(line, sizeof line, "give %s", g_sWeaponName[1][param2]);

						if (g_bEnableLimit)
						{
							if (g_iRequestCount > g_iArrayCount[client])
							{
								vCheatCommand(client, line);
								g_iArrayCount[client]++;

								CPrintToChatAll("%t", "GetItemWithLimit", client, (SpecifyLanguage(client)) ? g_sItemNameChi[1][param2] : g_sItemNameEn[1][param2], g_iArrayCount[client], g_iRequestCount);
							}
							else
								CPrintToChat(client, "%t", "ReachedLimit", g_iRequestCount);
						}
						else
						{
							vCheatCommand(client, line);
							CPrintToChatAll("%t", "GetItem", client, g_sItemNameChi[1][param2]);
						}
					}
				}
				else
				{
					char line[32];
					FormatEx(line, sizeof line, "give %s", g_sWeaponName[1][param2]);

					if (g_bEnableLimit)
					{
						if (g_iRequestCount > g_iArrayCount[client])
						{
							vCheatCommand(client, line);
							g_iArrayCount[client]++;

							CPrintToChatAll("%t", "GetItemWithLimit", client, (SpecifyLanguage(client)) ? g_sItemNameChi[1][param2] : g_sItemNameEn[1][param2], g_iArrayCount[client], g_iRequestCount);
						}
						else
							CPrintToChat(client, "%t", "ReachedLimit", g_iRequestCount);
					}
					else
					{
						vCheatCommand(client, line);
						CPrintToChatAll("%t", "GetItem", client, (SpecifyLanguage(client)) ? g_sItemNameChi[1][param2] : g_sItemNameEn[1][param2]);
					}
				}
			}
			else
				CPrintToChat(client, "%t", "UseItInSafeRoom");
		}
		case MenuAction_Cancel: 
		{
			if (param2 == MenuCancel_ExitBack)
				ChooseItem(client);
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

void MenuGetAdvancedGun(int client) 
{
	char Tier2[64];
	Format(Tier2, sizeof(Tier2), "%t", "Tier2");
	Menu menu = new Menu(iAdvancedGun_MenuHandler);
	menu.SetTitle(Tier2);
	for (int i = 0; i < 12; i++)
	{
		menu.AddItem(g_sWeaponName[2][i], (SpecifyLanguage(client)) ? g_sItemNameChi[2][i] : g_sItemNameEn[2][i]);
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int iAdvancedGun_MenuHandler(Menu menu, MenuAction action, int client, int param2) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			if((g_bsafearea && IsClientInSafeArea(client)) || !g_bsafearea)
			{
				int weaponid = GetPlayerWeaponSlot(client, 0);
				if (IsValidEntity(weaponid))
				{
					char classname[32];
					GetEntityClassname(weaponid, classname, sizeof(classname));
					if(StrContains(classname, g_sWeaponName[2][param2], true) != -1)
						return 0;
					else
					{
						char line[32];
						FormatEx(line, sizeof line, "give %s", g_sWeaponName[2][param2]);

						if (g_bEnableLimit)
						{
							if (g_iRequestCount > g_iArrayCount[client])
							{
								vCheatCommand(client, line);
								g_iArrayCount[client]++;

								CPrintToChatAll("%t", "GetItemWithLimit", client, (SpecifyLanguage(client)) ? g_sItemNameChi[2][param2] : g_sItemNameEn[2][param2], g_iArrayCount[client], g_iRequestCount);
							}
							else
								CPrintToChat(client, "%t", "ReachedLimit", g_iRequestCount);
						}
						else
						{
							vCheatCommand(client, line);
							CPrintToChatAll("%t", "GetItem", client, (SpecifyLanguage(client)) ? g_sItemNameChi[2][param2] : g_sItemNameEn[2][param2]);
						}
					}
				}
				else
				{
					char line[32];
					FormatEx(line, sizeof line, "give %s", g_sWeaponName[2][param2]);

					if (g_bEnableLimit)
					{
						if (g_iRequestCount > g_iArrayCount[client])
						{
							vCheatCommand(client, line);
							g_iArrayCount[client]++;

							CPrintToChatAll("%t", "GetItemWithLimit", client, (SpecifyLanguage(client)) ? g_sItemNameChi[2][param2] : g_sItemNameEn[2][param2], g_iArrayCount[client], g_iRequestCount);
						}
						else
							CPrintToChat(client, "%t", "ReachedLimit", g_iRequestCount);
					}
					else
					{
						vCheatCommand(client, line);
						CPrintToChatAll("%t", "GetItem", client, (SpecifyLanguage(client)) ? g_sItemNameChi[2][param2] : g_sItemNameEn[2][param2]);
					}

				}
			}
			else
				CPrintToChat(client, "%t", "UseItInSafeRoom");
		}
		case MenuAction_Cancel: 
		{
			if (param2 == MenuCancel_ExitBack)
				ChooseItem(client);
		}
		case MenuAction_End:
			delete menu;
}
	return 0;
}

void MenuGetThrowable(int client) 
{
	char item[64];
	Format(item, sizeof(item), "%t", "Item");
	Menu menu = new Menu(iThrowable_MenuHandler);
	menu.SetTitle(item);
	for (int i = 0; i < 18; i++)
	{
		menu.AddItem(g_sWeaponName[3][i], (SpecifyLanguage(client)) ? g_sItemNameChi[3][i] : g_sItemNameEn[3][i]);
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int iThrowable_MenuHandler(Menu menu, MenuAction action, int client, int param2) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			if((g_bsafearea && IsClientInSafeArea(client)) || !g_bsafearea)
			{
				char line[32];
				if (param2 < 15)
					FormatEx(line, sizeof line, "give %s", g_sWeaponName[3][param2]);
				else
					FormatEx(line, sizeof line, "upgrade_add %s", g_sWeaponName[3][param2]);
				
				if (g_bEnableLimit)
				{
					if (g_iRequestCount > g_iArrayCount[client])
					{
						vCheatCommand(client, line);
						g_iArrayCount[client]++;

						CPrintToChatAll("%t", "GetItemWithLimit", client, (SpecifyLanguage(client)) ? g_sItemNameChi[3][param2] : g_sItemNameEn[3][param2], g_iArrayCount[client], g_iRequestCount);
					}
					else
						CPrintToChat(client,  "%t", "ReachedLimit", g_iRequestCount);
				}
				else
				{
					vCheatCommand(client, line);
					CPrintToChatAll("%t", "GetItem", client, (SpecifyLanguage(client)) ? g_sItemNameChi[3][param2] : g_sItemNameEn[3][param2]);
				}

			}
			else
				CPrintToChat(client, "%t", "UseItInSafeRoom");
		}
		case MenuAction_Cancel: 
		{
			if (param2 == MenuCancel_ExitBack)
				ChooseItem(client);
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

void Menuadmin(int client) 
{
	char adminmenu[64];
	char SecondaryMenuOn[64], SecondaryMenuOff[64], Tier1MenuOn[64], 
	Tier1MenuOff[64], Tier2MenuOn[64], Tier2MenuOff[64], ItemMenuOn[64], 
	ItemMenuOff[64], AllowOutOn[64], AllowOutOff[64];

	SetGlobalTransTarget(client);
	Format(adminmenu, sizeof(adminmenu), "%t", "AdminMenu");
	Menu menu = new Menu(iadmin_MenuHandler);
	menu.SetTitle(adminmenu);
	
	Format(SecondaryMenuOn, sizeof(SecondaryMenuOn), "%t", "SecondaryMenuOn"); Format(SecondaryMenuOff, sizeof(SecondaryMenuOff), "%t", "SecondaryMenuOff");
	Format(Tier1MenuOn, sizeof(Tier1MenuOn), "%t", "Tier1MenuOn"); Format(Tier1MenuOff, sizeof(Tier1MenuOff), "%t", "Tier1MenuOff");
	Format(Tier2MenuOn, sizeof(Tier2MenuOn), "%t", "Tier2MenuOn"); Format(Tier2MenuOff, sizeof(Tier2MenuOff), "%t", "Tier2MenuOff");
	Format(ItemMenuOn, sizeof(ItemMenuOn), "%t", "ItemMenuOn"); Format(ItemMenuOff, sizeof(ItemMenuOff), "%t", "ItemMenuOff");
	Format(AllowOutOn, sizeof(AllowOutOn), "%t", "AllowOutOn"); Format(AllowOutOff, sizeof(AllowOutOff), "%t", "AllowOutOff");

	menu.AddItem("e", g_bmeleedefault ? SecondaryMenuOff : SecondaryMenuOn);
	menu.AddItem("f", g_binitialgundefault ? Tier1MenuOff : Tier1MenuOn);
	menu.AddItem("g", g_bMenuAdvancedGunOpen ? Tier2MenuOff : Tier2MenuOn);
	menu.AddItem("h", g_bMenuThrowableOpen ? ItemMenuOff : ItemMenuOn);
	menu.AddItem("i", g_bsafearea ? AllowOutOff : AllowOutOn);
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int iadmin_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Cancel: 
		{
			if (itemNum == MenuCancel_ExitBack)
				ChooseItem(client);
		}
		case MenuAction_End:
			delete menu;
		case MenuAction_Select:
		{
			char sItem[2];
			if(menu.GetItem(itemNum, sItem, sizeof(sItem)))
			{
				char on[64], off[64], tag[64];
				char menue[256], menuf[256], menug[256], menuh[256], menui[256];
				SetGlobalTransTarget(client);
				Format(on, sizeof(on), "%t", "On"); Format(off, sizeof(off), "%t", "Off"); Format(tag, sizeof(tag), "%t", "admin");

				// before we turn the bool value upside down.
				Format(menue, sizeof(menue), "%t", "Menu_e", tag, client, g_bmeleedefault ? off : on);
				Format(menuf, sizeof(menuf), "%t", "Menu_f", tag, client, g_binitialgundefault ? off : on);
				Format(menug, sizeof(menug), "%t", "Menu_g", tag, client, g_bMenuAdvancedGunOpen ? off : on);
				Format(menuh, sizeof(menuh), "%t", "Menu_h", tag, client, g_bMenuThrowableOpen ? off : on);
				Format(menui, sizeof(menui), "%t", "Menu_i", tag, client, g_bsafearea ? off : on);
				switch(sItem[0])
				{

					case 'e':
					{
						g_bmeleedefault = !g_bmeleedefault;
						CPrintToChatAll(menue);
					}
					case 'f':
					{
						g_binitialgundefault = !g_binitialgundefault;
						CPrintToChatAll(menuf);
					}
					case 'g':
					{
						g_bMenuAdvancedGunOpen = !g_bMenuAdvancedGunOpen;
						CPrintToChatAll(menug);
					}
					case 'h':
					{
						g_bMenuThrowableOpen = !g_bMenuThrowableOpen;
						CPrintToChatAll(menuh);
					}
					case 'i':
					{
						g_bsafearea = !g_bsafearea;
						CPrintToChatAll(menui);
					}
				}
			}
		}
	}
	return 0;
}

void vCheatCommand(int client, const char[] sCommand) {
	if (!client || !IsClientInGame(client))
		return;

	char sCmd[32];
	if (SplitString(sCommand, " ", sCmd, sizeof sCmd) == -1)
		strcopy(sCmd, sizeof sCmd, sCommand);

	int iFlagBits, iCmdFlags;
	iFlagBits = GetUserFlagBits(client);
	iCmdFlags = GetCommandFlags(sCmd);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	SetCommandFlags(sCmd, iCmdFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, sCommand);
	SetUserFlagBits(client, iFlagBits);
	SetCommandFlags(sCmd, iCmdFlags);
	
	if (strcmp(sCmd, "give") == 0) {
		if (strcmp(sCommand[5], "ammo") == 0)
			vReloadAmmo(client); 
	}
}

void vReloadAmmo(int client) {
	int weapon = GetPlayerWeaponSlot(client, 0);
	if (weapon <= MaxClients || !IsValidEntity(weapon))
		return;

	int m_iPrimaryAmmoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (m_iPrimaryAmmoType == -1)
		return;

	char sWeapon[32];
	GetEntityClassname(weapon, sWeapon, sizeof sWeapon);
	if (strcmp(sWeapon[7], "grenade_launcher") == 0) {
		static ConVar hAmmoGrenadelau;
		if (hAmmoGrenadelau == null)
			hAmmoGrenadelau = FindConVar("ammo_grenadelauncher_max");

		SetEntProp(client, Prop_Send, "m_iAmmo", hAmmoGrenadelau.IntValue, _, m_iPrimaryAmmoType);
	}
}

int iGetClientImmunityLevel(int client) {

	char sSteamID[32];
	GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof sSteamID);
	AdminId admin = FindAdminByIdentity(AUTHMETHOD_STEAM, sSteamID);
	if (admin == INVALID_ADMIN_ID)
		return -999;
	return admin.ImmunityLevel;
}

//代码来自"https://steamcommunity.com/id/ChengChiHou/"
stock bool IsClientInSafeArea(int client)
{
	int nav = L4D_GetLastKnownArea(client);
	if(!nav)
		return false;
	int iAttr = L4D_GetNavArea_SpawnAttributes(view_as<Address>(nav));
	bool bInStartPoint = !!(iAttr & 0x80);
	bool bInCheckPoint = !!(iAttr & 0x800);
	if(!bInStartPoint && !bInCheckPoint)
		return false;
	return true;
}

/**
 * Specifiy sChinese and English that the given client index uses.
 * 
 * @param client		client index to specify.
 * 
 * @return				true if the client is using sChinese, false othwise.
 */
stock bool SpecifyLanguage(int client)
{
	int lang = GetClientLanguage(client);

	return lang == 13 ? true : false;
}
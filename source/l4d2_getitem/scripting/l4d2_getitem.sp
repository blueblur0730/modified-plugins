#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <sdktools>
#include <colors>

static const char g_sMeleeModels[][] = {
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

static const char g_sWeaponName[4][18][] =
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

static const char g_sItemNameChi[4][18][] =
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

static const char g_sItemNameEn[4][18][] =
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

#define IsValidPlayer(%1)	(%1 && IsClientInGame(%1) && !IsFakeClient(%1) && GetClientTeam(%1) == 2 && IsPlayerAlive(%1))

#define PLUGIN_VERSION	"1.4"

ConVar 
	g_hcmeleedefault, 
	g_hcinitialgundefault, 
	g_hcsafearea, 
	g_hcAdvancedGunOpen,
	g_hcThrowableOpen, 
	g_hcEnableLimit, 
	g_hcRequestCount, 
	g_hcAd, 
	g_hcAdTimer;

bool
	g_bMeleeDefault,
	g_bInitialGunDefault,
	g_bSafeArea,
	g_bMenuAdvancedGunOpen,
	g_bMenuThrowableOpen,
	g_bEnableLimit,
	g_bAd;

int 
	g_iRequestCount,
	g_iArrayCount[MAXPLAYERS + 1];

float g_fAdTimer;
float g_flLastTime[MAXPLAYERS + 1] = {0.0, ...};
bool g_bIsRoundAlive = false;

public Plugin myinfo =
{
	name = "[L4D2] StartUp Item acquisition",
	author = "绪花✧(≖ ◡ ≖✿), Ross, 鱼鱼, blueblur",
	description = "Acquire items before the game's on.",
	version = PLUGIN_VERSION,
	url = "https://github.com/blueblur0730/modified-plugins"
};
	
public void OnPluginStart()
{
	LoadTranslations("l4d2_getitem.phrases");
	RegAdminCmd("sm_getitem", Command_Item, ADMFLAG_GENERIC, "Acquire items.");
	
	CreateConVar("l4d2_getitem_version", PLUGIN_VERSION, "Plugin version.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_hcmeleedefault		= CreateConVar("l4d2_er_melee_enable",		"1",	"Enable melee weapon menu.",			_, true, 0.0, true, 1.0);
	g_hcinitialgundefault	= CreateConVar("l4d2_er_t1_enable",			"1",	"Enable T1 weapon menu.",				_, true, 0.0, true, 1.0);
	g_hcsafearea			= CreateConVar("l4d2_er_safearea_only",		"1",	"Only acquire items in safe area.",		_, true, 0.0, true, 1.0);
	g_hcAdvancedGunOpen		= CreateConVar("l4d2_er_t2_enable",			"0",	"Enable T2 weapon menu.",				_, true, 0.0, true, 1.0);
	g_hcThrowableOpen		= CreateConVar("l4d2_er_throwable_enable",	"0",	"Enable throwable menu.",				_, true, 0.0, true, 1.0);
	g_hcEnableLimit			= CreateConVar("l4d2_er_enable_limit",		"1",	"Enable limit for each acquisition.", 	_, true, 0.0, true, 1.0);
	g_hcRequestCount		= CreateConVar("l4d2_er_request_count",		"2",	"Count of acquisition.");
	g_hcAd					= CreateConVar("l4d2_er_ad_enable",			"1",	"Enable advertisement to notify.",		_, true, 0.0, true, 1.0);
	g_hcAdTimer				= CreateConVar("l4d2_er_ad_interval",		"120.0","Interval of advertisement.");		
	
	GetCvars();
	g_hcmeleedefault.AddChangeHook(OnConVarChanged);
	g_hcinitialgundefault.AddChangeHook(OnConVarChanged);
	g_hcsafearea.AddChangeHook(OnConVarChanged);
	g_hcAdvancedGunOpen.AddChangeHook(OnConVarChanged);
	g_hcThrowableOpen.AddChangeHook(OnConVarChanged);
	g_hcEnableLimit.AddChangeHook(OnConVarChanged);
	g_hcRequestCount.AddChangeHook(OnConVarChanged);
	g_hcAd.AddChangeHook(OnConVarChanged);
	g_hcAdTimer.AddChangeHook(OnConVarChanged);

	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bMeleeDefault			=	g_hcmeleedefault.BoolValue;
	g_bInitialGunDefault	=	g_hcinitialgundefault.BoolValue;
	g_bSafeArea				=	g_hcsafearea.BoolValue;
	g_bMenuAdvancedGunOpen	=	g_hcAdvancedGunOpen.BoolValue;
	g_bMenuThrowableOpen	=	g_hcThrowableOpen.BoolValue;
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
}

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
	g_bIsRoundAlive = true;
}

void Event_RoundStart(Event hEvent, char[] sName, bool dontBroadcast)
{
	Clear();
	if (g_bAd) CreateTimer(g_fAdTimer, Timer_Ad, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_Ad(Handle Timer)
{
	// once game started stop this.
	if (!g_bIsRoundAlive)
	{
		g_bEnableLimit ? CPrintToChatAll("%t", "Advertisement_Limit", g_iRequestCount) : CPrintToChatAll("%t", "Advertisement");
		return Plugin_Continue;
	}

	return Plugin_Stop;
}

void Clear()
{
	if (g_bEnableLimit)
	{
		for (int i; i < MaxClients; i++)
		{
			g_iArrayCount[i] = 0;
			g_flLastTime[i] = 0.0;
		}
	}

	g_bIsRoundAlive = false;
}

Action Command_Item(int client, int args)
{
	if (!client || !IsClientInGame(client))
		return Plugin_Handled;

	if (g_bSafeArea && !IsClientInSafeArea(client))
	{
		CPrintToChat(client, "%t", "UseItInSafeRoom");
		return Plugin_Handled;
	}

	ChooseItem(client);
	return Plugin_Handled;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (!IsValidPlayer(client))
		return;

	if ((buttons & IN_RELOAD) && (buttons & IN_USE))
	{
		if (g_bSafeArea && !IsClientInSafeArea(client))
			return;

		// prevent from creating menu in frames.
		if (g_flLastTime[client] + 1.5 < GetGameTime())
		{
			g_flLastTime[client] = GetGameTime();
			ChooseItem(client);
		}
	}
}

void ChooseItem(int client)
{
	// you are the admin.
	if (GetClientTeam(client) == 2 || GetUserFlagBits(client) > 0)		
	{
		char sBuffer[64];
		Menu menu = new Menu(Menu_HandlerFunction);
		
		FormatEx(sBuffer, sizeof(sBuffer), "%T", "MainTitle", client);
		menu.SetTitle(sBuffer);

		g_bMeleeDefault ? 
		FormatEx(sBuffer, sizeof(sBuffer), "%T", "SecondaryOn", client) :
		FormatEx(sBuffer, sizeof(sBuffer), "%T", "SecondaryOff", client);
		menu.AddItem("a", sBuffer);

		g_bInitialGunDefault ? 
		FormatEx(sBuffer, sizeof(sBuffer), "%T", "Tier1On", client) :
		FormatEx(sBuffer, sizeof(sBuffer), "%T", "Tier1Off", client);
		menu.AddItem("b", sBuffer);

		g_bMenuAdvancedGunOpen ? 
		FormatEx(sBuffer, sizeof(sBuffer), "%T", "Tier2On", client) :
		FormatEx(sBuffer, sizeof(sBuffer), "%T", "Tier2Off", client);
		menu.AddItem("c", sBuffer);

		g_bMenuThrowableOpen ? 
		FormatEx(sBuffer, sizeof(sBuffer), "%T", "ItemOn", client) :
		FormatEx(sBuffer, sizeof(sBuffer), "%T", "ItemOff", client);
		menu.AddItem("d", sBuffer);

		if (GetClientImmunityLevel(client) > 49) 
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%T", "AdminMenu", client);
			menu.AddItem("e", sBuffer);
		}
			
		menu.ExitButton = true;
		menu.Display(client, 30);
	}
}

int Menu_HandlerFunction(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_Select:
		{
			char sItem[2];
			if (menu.GetItem(itemNum, sItem, sizeof(sItem)))
			{
				switch(sItem[0])
				{
					case 'a': if(g_bMeleeDefault) MenuGetMelee(client);
					case 'b': if(g_bInitialGunDefault) MenuGetInitialGun(client);
					case 'c': if(g_bMenuAdvancedGunOpen) MenuGetAdvancedGun(client);
					case 'd': if(g_bMenuThrowableOpen) MenuGetThrowable(client);
					case 'e': Menuadmin(client);
				}
			}
		}
	}

	return 0;
}

void MenuGetMelee(int client) 
{
	char secondary[64];
	Menu menu = new Menu(Melees_MenuHandler);

	Format(secondary, sizeof(secondary), "%T", "Secondary", client);
	menu.SetTitle(secondary);

	// yea it's hardcoded.
	for (int i = 0; i < 17; i++)
		menu.AddItem(g_sWeaponName[0][i], (SpecifyLanguage(client)) ? g_sItemNameChi[0][i] : g_sItemNameEn[0][i]);

	menu.ExitBackButton = true;
	menu.Display(client, 30);
}

int Melees_MenuHandler(Menu menu, MenuAction action, int client, int param2) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			int weaponid = GetPlayerWeaponSlot(client, 1);
			if (IsValidEdict(weaponid))
			{
				char classname[32];
				GetEntPropString(weaponid, Prop_Data, "m_ModelName", classname, sizeof(classname));
				if (StrContains(classname, g_sWeaponName[0][param2], false) == -1 || StrContains(classname, "pistol", false) !=-1)
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

		case MenuAction_Cancel: 
		{
			if (param2 == MenuCancel_ExitBack)
				ChooseItem(client);
		}

		case MenuAction_End: delete menu;
	}
	return 0;
}

void MenuGetInitialGun(int client) 
{
	char Tier1[64];
	Menu menu = new Menu(InitialGun_MenuHandler);
	Format(Tier1, sizeof(Tier1), "%T", "Tier1", client);
	menu.SetTitle(Tier1);

	for (int i = 0; i < 6; i++)
		menu.AddItem(g_sWeaponName[1][i], (SpecifyLanguage(client)) ? g_sItemNameChi[1][i] : g_sItemNameEn[1][i]);

	menu.ExitBackButton = true;
	menu.Display(client, 30);
}

int InitialGun_MenuHandler(Menu menu, MenuAction action, int client, int param2) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			// you've already have that one right?
			int weaponid = GetPlayerWeaponSlot(client, 0);
			if (IsValidEntity(weaponid))
			{
				char classname[32];
				GetEntityClassname(weaponid, classname, sizeof(classname));
				if(StrContains(classname, g_sWeaponName[1][param2], true) != -1)
					return 0;
			}

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

		case MenuAction_Cancel: 
		{
			if (param2 == MenuCancel_ExitBack)
				ChooseItem(client);
		}

		case MenuAction_End: delete menu;
	}

	return 0;
}

void MenuGetAdvancedGun(int client) 
{
	char Tier2[64];
	Menu menu = new Menu(AdvancedGun_MenuHandler);
	Format(Tier2, sizeof(Tier2), "%T", "Tier2", client);
	menu.SetTitle(Tier2);

	for (int i = 0; i < 12; i++)
		menu.AddItem(g_sWeaponName[2][i], (SpecifyLanguage(client)) ? g_sItemNameChi[2][i] : g_sItemNameEn[2][i]);

	menu.ExitBackButton = true;
	menu.Display(client, 30);
}

int AdvancedGun_MenuHandler(Menu menu, MenuAction action, int client, int param2) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			int weaponid = GetPlayerWeaponSlot(client, 0);
			if (IsValidEntity(weaponid))
			{
				char classname[32];
				GetEntityClassname(weaponid, classname, sizeof(classname));
				if(StrContains(classname, g_sWeaponName[2][param2], true) != -1)
					return 0;
			}

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

		case MenuAction_Cancel: 
		{
			if (param2 == MenuCancel_ExitBack)
				ChooseItem(client);
		}

		case MenuAction_End: delete menu;
}
	return 0;
}

void MenuGetThrowable(int client) 
{
	char item[64];
	Menu menu = new Menu(Throwable_MenuHandler);
	Format(item, sizeof(item), "%T", "Item", client);
	menu.SetTitle(item);

	for (int i = 0; i < 18; i++)
		menu.AddItem(g_sWeaponName[3][i], (SpecifyLanguage(client)) ? g_sItemNameChi[3][i] : g_sItemNameEn[3][i]);

	menu.ExitBackButton = true;
	menu.Display(client, 30);
}

int Throwable_MenuHandler(Menu menu, MenuAction action, int client, int param2) 
{
	switch (action) 
	{
		case MenuAction_Select: 
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

		case MenuAction_Cancel: 
		{
			if (param2 == MenuCancel_ExitBack)
				ChooseItem(client);
		}

		case MenuAction_End: delete menu;
	}
	return 0;
}

void Menuadmin(int client) 
{
	char sBuffer[64];
	Menu menu = new Menu(admin_MenuHandler);
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "AdminMenu", client);
	menu.SetTitle(sBuffer);
	
	g_bMeleeDefault ?
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "SecondaryMenuOn") :
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "SecondaryMenuOff");
	menu.AddItem("e", sBuffer);

	g_bInitialGunDefault ?
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "Tier1MenuOn") :
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "Tier1MenuOff");
	menu.AddItem("f", sBuffer);

	g_bMenuAdvancedGunOpen ? 
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "Tier2MenuOn") :
 	FormatEx(sBuffer, sizeof(sBuffer), "%t", "Tier2MenuOff");
	menu.AddItem("g", sBuffer);

	g_bMenuThrowableOpen ?
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "ItemMenuOn") :
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "ItemMenuOff");
	menu.AddItem("h", sBuffer);

	g_bSafeArea ?
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "AllowOutOn") :
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "AllowOutOff");
	menu.AddItem("i", sBuffer);
	
	menu.ExitBackButton = true;
	menu.Display(client, 30);
}

int admin_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Cancel: 
		{
			if (itemNum == MenuCancel_ExitBack)
				ChooseItem(client);
		}

		case MenuAction_End: delete menu;

		case MenuAction_Select:
		{
			char sItem[2];
			if (menu.GetItem(itemNum, sItem, sizeof(sItem)))
			{
				switch(sItem[0])
				{

					case 'e':
					{
						g_bMeleeDefault = !g_bMeleeDefault;
						CPrintToChatAll("%t", "Menu_e", client, g_bMeleeDefault ? "On" : "Off");
					}

					case 'f':
					{
						g_bInitialGunDefault = !g_bInitialGunDefault;
						CPrintToChatAll("%t", "Menu_f", client, g_bInitialGunDefault ? "On" : "Off");
					}

					case 'g':
					{
						g_bMenuAdvancedGunOpen = !g_bMenuAdvancedGunOpen;
						CPrintToChatAll("%t", "Menu_g", client, g_bMenuAdvancedGunOpen ? "On" : "Off");
					}

					case 'h':
					{
						g_bMenuThrowableOpen = !g_bMenuThrowableOpen;
						CPrintToChatAll("%t", "Menu_h", client, g_bMenuThrowableOpen ? "On" : "Off");
					}

					case 'i':
					{
						g_bSafeArea = !g_bSafeArea;
						CPrintToChatAll("%t", "Menu_i", client, g_bSafeArea ? "On" : "Off");
					}
				}
			}
		}
	}
	return 0;
}

void vCheatCommand(int client, const char[] sCommand) 
{
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

void vReloadAmmo(int client) 
{
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

int GetClientImmunityLevel(int client) 
{

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
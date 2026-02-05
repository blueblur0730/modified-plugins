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

static const char g_sItemNamePhrases[4][18][] =
{
	{	/*slot 0()*/
		"Phrase_Katana","Phrase_Axe","Phrase_Machete","Phrase_Knife","Phrase_Pistol","Phrase_Deagle","Phrase_Chainsaw","Phrase_Frying Pan",
		"Phrase_BaseballBat","Phrase_Crowbar","Phrase_CricketBat","Phrase_Tonfa","Phrase_Guitar","Phrase_GolfClub","Phrase_Shovel",
		"Phrase_Pitchfork","Phrase_RiotShield","",
	},

	{	/*slot 1()*/
		"Phrase_PumpShotgun","Phrase_ChromeShotgun","Phrase_Uzi","Phrase_Mac-10","Phrase_MP5","Phrase_Ammo",
		"","","","","","","","","","","","",
	},

	{	/*slot 2()*/
		"Phrase_Autoshotgun","Phrase_SPASShotgun","Phrase_HuntingRifle","Phrase_MilitarySniper","Phrase_M-16",
		"Phrase_DesertRifle","Phrase_AK-47","Phrase_SG552","Phrase_Scout","Phrase_AWP","Phrase_M60","Phrase_Grenade Launcher",
		"","","","","","",
	},

	{	/*slot 3()*/
		"Phrase_FirstAidKit","Phrase_Defibrillator","Phrase_Pills","Phrase_Adrenaline","Phrase_Molotov","Phrase_PipeBomb",
		"Phrase_BileBomb","Phrase_IncendiaryAmmoPack","Phrase_ExplosiveAmmoPack","Phrase_Gascan","Phrase_PropaneTank",
		"Phrase_OxygenTank","Phrase_Fireworks","Phrase_ColaBottles","Phrase_Gnome","Phrase_IncendiaryAmmo","Phrase_ExplosiveAmmo",
		"Phrase_LaserSight",
	},
};

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

#define PLUGIN_VERSION	"1.6"
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
	RegConsoleCmd("sm_getitem", Command_Item, "Acquire items.");
	
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

public void OnMapStart() 
{
	for (int i; i < sizeof(g_sMeleeModels); i++) 
	{
		if (!IsModelPrecached(g_sMeleeModels[i]))
			PrecacheModel(g_sMeleeModels[i], true);
	}
}

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
	g_bIsRoundAlive = true;
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

void Event_RoundStart(Event hEvent, char[] sName, bool dontBroadcast)
{
	Clear();

	if (g_bAd) 
		CreateTimer(g_fAdTimer, Timer_Ad, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

void Timer_Ad(Handle hTimer)
{
	// once game started stop this.
	if (!g_bIsRoundAlive)
	{
		g_bEnableLimit ? 
		CPrintToChatAll("%t", "Advertisement_Limit", g_iRequestCount) : 
		CPrintToChatAll("%t", "Advertisement");
	}
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

void ChooseItem(int client)
{
	// you are the admin.
	if (GetClientTeam(client) == 2 || GetUserFlagBits(client) > 0)		
	{
		char sBuffer[64];
		Menu menu = new Menu(MainMenu_Handler);
		
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

		if (IsClientAdmin(client)) 
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%T", "AdminMenu", client);
			menu.AddItem("e", sBuffer);
		}
			
		menu.ExitButton = true;
		menu.Display(client, 30);
	}
}

void MainMenu_Handler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End: 
			delete menu;

		case MenuAction_Select:
		{
			char sItem[2];
			if (menu.GetItem(itemNum, sItem, sizeof(sItem)))
			{
				switch(sItem[0])
				{
					case 'a': if(g_bMeleeDefault) CreateSecondaryMenu(client);
					case 'b': if(g_bInitialGunDefault) CreateTier1Menu(client);
					case 'c': if(g_bMenuAdvancedGunOpen) CreateTier2Menu(client);
					case 'd': if(g_bMenuThrowableOpen) CreateThrowableMenu(client);
					case 'e': CreateAdminMenu(client);
				}
			}
		}
	}
}

void CreateSecondaryMenu(int client) 
{
	char sBuffer[64];
	Menu menu = new Menu(Secondary_MenuHandler);
	menu.SetTitle(sBuffer, sizeof(sBuffer), "%T", "Secondary", client);

	// yea it's hardcoded.
	for (int i = 0; i < sizeof(g_sItemNamePhrases[0]); i++)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%T", g_sItemNamePhrases[0][i], client);
		menu.AddItem(g_sWeaponName[0][i], sBuffer);
	}

	menu.ExitBackButton = true;
	menu.Display(client, 30);
}

void Secondary_MenuHandler(Menu menu, MenuAction action, int client, int param2) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			int weaponid = GetPlayerWeaponSlot(client, 1);
			if (weaponid != -1 && IsValidEdict(weaponid))
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
							CheatCommand(client, line);
							g_iArrayCount[client]++;

							CPrintToChatAll("%t", "GetItemWithLimit", client, g_sItemNamePhrases[0][param2], g_iArrayCount[client], g_iRequestCount);
						}
						else
						{
							CPrintToChat(client, "%t", "ReachedLimit", g_iRequestCount);
						}
					}
					else
					{	
						CheatCommand(client, line);
						CPrintToChatAll("%t", "GetItem", client, g_sItemNamePhrases[0][param2]);
					}
				}
			}
		}

		case MenuAction_Cancel: 
		{
			if (param2 == MenuCancel_ExitBack)
				ChooseItem(client);
		}

		case MenuAction_End: 
			delete menu;
	}
}

void CreateTier1Menu(int client) 
{
	char sBuffer[64];
	Menu menu = new Menu(Tier1_MenuHandler);
	menu.SetTitle(sBuffer, sizeof(sBuffer), "%T", "Tier1", client);

	for (int i = 0; i < sizeof(g_sItemNamePhrases[1]); i++)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%T", g_sItemNamePhrases[1][i], client);
		menu.AddItem(g_sWeaponName[1][i], sBuffer);
	}

	menu.ExitBackButton = true;
	menu.Display(client, 30);
}

void Tier1_MenuHandler(Menu menu, MenuAction action, int client, int param2) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			// you've already have that one right?
			int weaponid = GetPlayerWeaponSlot(client, 0);
			if (weaponid != -1 && IsValidEdict(weaponid))
			{
				char classname[32];
				GetEntityClassname(weaponid, classname, sizeof(classname));
				if (StrContains(classname, g_sWeaponName[1][param2], true) != -1)
					return;
			}

			char line[32];
			FormatEx(line, sizeof line, "give %s", g_sWeaponName[1][param2]);

			if (g_bEnableLimit)
			{
				if (g_iRequestCount > g_iArrayCount[client])
				{
					CheatCommand(client, line);
					g_iArrayCount[client]++;

					CPrintToChatAll("%t", "GetItemWithLimit", client, g_sItemNamePhrases[1][param2], g_iArrayCount[client], g_iRequestCount);
				}
				else
				{
					CPrintToChat(client, "%t", "ReachedLimit", g_iRequestCount);
				}
			}
			else
			{
				CheatCommand(client, line);
				CPrintToChatAll("%t", "GetItem", client, g_sItemNamePhrases[1][param2]);
			}
		}

		case MenuAction_Cancel: 
		{
			if (param2 == MenuCancel_ExitBack)
				ChooseItem(client);
		}

		case MenuAction_End:
			delete menu;
	}
}

void CreateTier2Menu(int client) 
{
	char sBuffer[64];
	Menu menu = new Menu(Tier2_MenuHandler);
	menu.SetTitle(sBuffer, sizeof(sBuffer), "%T", "Tier2", client);

	for (int i = 0; i < sizeof(g_sItemNamePhrases[2]); i++)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%T", g_sItemNamePhrases[2][i], client);
		menu.AddItem(g_sWeaponName[2][i], sBuffer);
	}

	menu.ExitBackButton = true;
	menu.Display(client, 30);
}

void Tier2_MenuHandler(Menu menu, MenuAction action, int client, int param2) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			int weaponid = GetPlayerWeaponSlot(client, 0);
			if (weaponid != -1 && IsValidEdict(weaponid))
			{
				char classname[32];
				GetEntityClassname(weaponid, classname, sizeof(classname));
				if (StrContains(classname, g_sWeaponName[2][param2], true) != -1)
					return;
			}

			char line[32];
			FormatEx(line, sizeof line, "give %s", g_sWeaponName[2][param2]);

			if (g_bEnableLimit)
			{
				if (g_iRequestCount > g_iArrayCount[client])
				{
					CheatCommand(client, line);
					g_iArrayCount[client]++;

					CPrintToChatAll("%t", "GetItemWithLimit", client, g_sItemNamePhrases[2][param2], g_iArrayCount[client], g_iRequestCount);
				}
				else
				{
					CPrintToChat(client, "%t", "ReachedLimit", g_iRequestCount);
				}
			}
			else
			{
				CheatCommand(client, line);
				CPrintToChatAll("%t", "GetItem", client, g_sItemNamePhrases[2][param2]);
			}
		}

		case MenuAction_Cancel: 
		{
			if (param2 == MenuCancel_ExitBack)
				ChooseItem(client);
		}

		case MenuAction_End: 
			delete menu;
	}
}

void CreateThrowableMenu(int client) 
{
	char sBuffer[64];
	Menu menu = new Menu(Throwable_MenuHandler);
	menu.SetTitle(sBuffer, sizeof(sBuffer), "%T", "Item", client);

	for (int i = 0; i < 18; i++)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%T", g_sItemNamePhrases[3][i], client);
		menu.AddItem(g_sWeaponName[3][i], sBuffer);
	}

	menu.ExitBackButton = true;
	menu.Display(client, 30);
}

void Throwable_MenuHandler(Menu menu, MenuAction action, int client, int param2) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			char line[32];

			param2 < 15 ?
			FormatEx(line, sizeof line, "give %s", g_sWeaponName[3][param2]) :
			FormatEx(line, sizeof line, "upgrade_add %s", g_sWeaponName[3][param2]);
				
			if (g_bEnableLimit)
			{
				if (g_iRequestCount > g_iArrayCount[client])
				{
					CheatCommand(client, line);
					g_iArrayCount[client]++;

					CPrintToChatAll("%t", "GetItemWithLimit", client, g_sItemNamePhrases[3][param2], g_iArrayCount[client], g_iRequestCount);
				}
				else
				{
					CPrintToChat(client,  "%t", "ReachedLimit", g_iRequestCount);
				}
			}
			else
			{
				CheatCommand(client, line);
				CPrintToChatAll("%t", "GetItem", client, g_sItemNamePhrases[3][param2]);
			}
		}

		case MenuAction_Cancel: 
		{
			if (param2 == MenuCancel_ExitBack)
				ChooseItem(client);
		}

		case MenuAction_End: 
			delete menu;
	}
}

void CreateAdminMenu(int client) 
{
	char sBuffer[64];
	Menu menu = new Menu(AdminMenu_MenuHandler);
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "AdminMenu", client);
	menu.SetTitle(sBuffer);
	
	g_bMeleeDefault ?
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "SecondaryMenuOn", client) :
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "SecondaryMenuOff", client);
	menu.AddItem("e", sBuffer);

	g_bInitialGunDefault ?
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "Tier1MenuOn", client) :
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "Tier1MenuOff", client);
	menu.AddItem("f", sBuffer);

	g_bMenuAdvancedGunOpen ? 
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "Tier2MenuOn", client) :
 	FormatEx(sBuffer, sizeof(sBuffer), "%T", "Tier2MenuOff", client);
	menu.AddItem("g", sBuffer);

	g_bMenuThrowableOpen ?
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "ItemMenuOn", client) :
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "ItemMenuOff", client);
	menu.AddItem("h", sBuffer);

	g_bSafeArea ?
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "AllowOutOn", client) :
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "AllowOutOff", client);
	menu.AddItem("i", sBuffer);
	
	menu.ExitBackButton = true;
	menu.Display(client, 30);
}

void AdminMenu_MenuHandler(Menu menu, MenuAction action, int client, int itemNum)
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

stock void CheatCommand(int client, const char[] sCommand) 
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
	
	if (strcmp(sCmd, "give") == 0) 
	{
		if (strcmp(sCommand[5], "ammo") == 0)
			ReloadAmmo(client); 
	}
}

stock void ReloadAmmo(int client) 
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

stock bool IsClientAdmin(int client)
{
	if (!IsClientInGame(client)) return false;
	int flag = GetUserFlagBits(client);
	return (GetUserAdmin(client) != INVALID_ADMIN_ID && ((flag & ADMFLAG_CHEATS) || (flag & ADMFLAG_ROOT)));
}

stock bool IsClientInSafeArea(int client)
{
	int nav = L4D_GetLastKnownArea(client);
	if (!nav)
		return false;

	int iAttr = L4D_GetNavArea_SpawnAttributes(view_as<Address>(nav));
	bool bInStartPoint = !!(iAttr & NAV_SPAWN_PLAYER_START);
	bool bInCheckPoint = !!(iAttr & NAV_SPAWN_CHECKPOINT);

	return (bInStartPoint || bInCheckPoint);
}

stock bool IsValidPlayer(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client));
}

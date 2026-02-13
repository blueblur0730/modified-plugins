#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <sdktools>
#include <colors>
#include <l4d2util_constants>

static const char g_sWeaponName[4][18][] =
{
    {    //slot 0()
        "katana","fireaxe","machete","knife","pistol","pistol_magnum",
        "chainsaw","frying_pan","baseball_bat","crowbar","cricket_bat",
        "tonfa","electric_guitar","golfclub","shovel","pitchfork","riotshield",""
    },

    {    //slot 1()
        "pumpshotgun","shotgun_chrome","smg","smg_silenced","smg_mp5","ammo",
        "","","","","","","","","","","","",
    },

    {    //slot 2()
        "autoshotgun","shotgun_spas","hunting_rifle","sniper_military","rifle",
        "rifle_desert","rifle_ak47","rifle_sg552","sniper_scout","sniper_awp",
        "rifle_m60","grenade_launcher","","","","","","",
    },

    {    //slot 3()
        "first_aid_kit","defibrillator","pain_pills","adrenaline","molotov","pipe_bomb",
        "vomitjar","upgradepack_incendiary","upgradepack_explosive","gascan","propanetank",
        "oxygentank","fireworkcrate","cola_bottles","gnome","incendiary_ammo","explosive_ammo",
        "laser_sight",
    },
};

static const char g_sItemNamePhrases[4][18][] =
{
    {    /*slot 0()*/
        "Phrase_Katana","Phrase_Axe","Phrase_Machete","Phrase_Knife","Phrase_Pistol","Phrase_Deagle","Phrase_Chainsaw","Phrase_Frying Pan",
        "Phrase_BaseballBat","Phrase_Crowbar","Phrase_CricketBat","Phrase_Tonfa","Phrase_Guitar","Phrase_GolfClub","Phrase_Shovel",
        "Phrase_Pitchfork","Phrase_RiotShield","",
    },

    {    /*slot 1()*/
        "Phrase_PumpShotgun","Phrase_ChromeShotgun","Phrase_Uzi","Phrase_Mac-10","Phrase_MP5","Phrase_Ammo",
        "","","","","","","","","","","","",
    },

    {    /*slot 2()*/
        "Phrase_Autoshotgun","Phrase_SPASShotgun","Phrase_HuntingRifle","Phrase_MilitarySniper","Phrase_M-16",
        "Phrase_DesertRifle","Phrase_AK-47","Phrase_SG552","Phrase_Scout","Phrase_AWP","Phrase_M60","Phrase_Grenade Launcher",
        "","","","","","",
    },

    {    /*slot 3()*/
        "Phrase_FirstAidKit","Phrase_Defibrillator","Phrase_Pills","Phrase_Adrenaline","Phrase_Molotov","Phrase_PipeBomb",
        "Phrase_BileBomb","Phrase_IncendiaryAmmoPack","Phrase_ExplosiveAmmoPack","Phrase_Gascan","Phrase_PropaneTank",
        "Phrase_OxygenTank","Phrase_Fireworks","Phrase_ColaBottles","Phrase_Gnome","Phrase_IncendiaryAmmo","Phrase_ExplosiveAmmo",
        "Phrase_LaserSight",
    },
};

ConVar 
    g_hCvar_SencondaryEnable, 
    g_hCvar_Tier1Enable, 
    g_hCvar_Tier2Enable,
    g_hCvar_ThrowableEnable,     
    g_hCvar_SafeAreaOnly, 
    g_hCvar_Ad, 
    g_hCvar_AdTimer,
    g_hCvar_EnableLimit, 
    g_hCvar_RequestCount, 
    g_hCvar_SeparateRequestCountEnable,
    g_hCvar_RequestCountSecondary,
    g_hCvar_RequestCountTier1,
    g_hCvar_RequestCountTier2,
    g_hCvar_RequestCountThrowable;

bool
    g_bSecondaryEnable,
    g_bTier1Enable,
    g_bTier2Enable,
    g_bThrowableEnable,
    g_bSafeAreaOnly,
    g_bEnableLimit,
    g_bAd,
    g_bSeparateRequestCountEnable;

int 
    g_iRequestCount,
    g_iSecondaryRequestCount,
    g_iTier1RequestCount,
    g_iTier2RequestCount,
    g_iThrowableRequestCount;

enum struct RequestCount_t
{
    int iGlobalCount;
    int iSecondaryCount;
    int iTier1Count;
    int iTier2Count;
    int iThrowableCount;

    void Init()
    {
        this.iGlobalCount = 0;
        this.iSecondaryCount = 0;
        this.iTier1Count = 0;
        this.iTier2Count = 0;
        this.iThrowableCount = 0;
    }
} 
RequestCount_t g_RequestCount[MAXPLAYERS + 1];

float g_fAdTimer;
float g_flLastTime[MAXPLAYERS + 1] = {0.0, ...};
bool g_bIsRoundAlive = false;
Handle g_hTimer = null;

#define PLUGIN_VERSION    "1.7.3"
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
    g_hCvar_SencondaryEnable    = CreateConVar("l4d2_er_secondary_enable",     "1",    "Enable secondary weapon menu.",         _, true, 0.0, true, 1.0);
    g_hCvar_Tier1Enable         = CreateConVar("l4d2_er_t1_enable",            "1",    "Enable T1 weapon menu.",                _, true, 0.0, true, 1.0);
    g_hCvar_Tier2Enable         = CreateConVar("l4d2_er_t2_enable",            "0",    "Enable T2 weapon menu.",                _, true, 0.0, true, 1.0);
    g_hCvar_ThrowableEnable     = CreateConVar("l4d2_er_throwable_enable",     "0",    "Enable throwable menu.",                _, true, 0.0, true, 1.0);
    g_hCvar_SafeAreaOnly        = CreateConVar("l4d2_er_safearea_only",        "1",    "Only acquire items in safe area.",      _, true, 0.0, true, 1.0);
    g_hCvar_Ad                  = CreateConVar("l4d2_er_ad_enable",            "1",    "Enable advertisement to notify.",       _, true, 0.0, true, 1.0);
    g_hCvar_AdTimer             = CreateConVar("l4d2_er_ad_interval",          "120.0","Interval of advertisement.",            _, true, 1.0);    

    g_hCvar_EnableLimit         = CreateConVar("l4d2_er_enable_limit",         "1",    "Enable limit for each acquisition. if separate request count is enabled, this is not effective.", _, true, 0.0, true, 1.0);
    g_hCvar_RequestCount        = CreateConVar("l4d2_er_request_count",        "2",    "Count of acquisition.",                 _, true, 1.0);

    g_hCvar_SeparateRequestCountEnable      = CreateConVar("l4d2_er_separate_request_count_enable",     "1",    "Enable separate request count for each category.",     _, true, 0.0, true, 1.0);
    g_hCvar_RequestCountSecondary           = CreateConVar("l4d2_er_request_count_secondary",           "2",    "Count of acquisition for secondary weapon.",     _, true, 1.0);
    g_hCvar_RequestCountTier1               = CreateConVar("l4d2_er_request_count_t1",                  "2",    "Count of acquisition for T1 weapon.",     _, true, 1.0);
    g_hCvar_RequestCountTier2               = CreateConVar("l4d2_er_request_count_t2",                  "2",    "Count of acquisition for T2 weapon.",     _, true, 1.0);
    g_hCvar_RequestCountThrowable           = CreateConVar("l4d2_er_request_count_throwable",           "1",    "Count of acquisition for throwable and meds.",     _, true, 1.0);
    
    GetCvars();
    g_hCvar_SencondaryEnable.AddChangeHook(OnConVarChanged);
    g_hCvar_Tier1Enable.AddChangeHook(OnConVarChanged);
    g_hCvar_Tier2Enable.AddChangeHook(OnConVarChanged);
    g_hCvar_ThrowableEnable.AddChangeHook(OnConVarChanged);
    g_hCvar_SafeAreaOnly.AddChangeHook(OnConVarChanged);
    g_hCvar_Ad.AddChangeHook(OnConVarChanged);

    g_hCvar_AdTimer.AddChangeHook(OnAdTimerConVarChanged);
    OnAdTimerConVarChanged(g_hCvar_AdTimer, "", "");

    g_hCvar_EnableLimit.AddChangeHook(OnConVarChanged);
    g_hCvar_RequestCount.AddChangeHook(OnConVarChanged);

    g_hCvar_SeparateRequestCountEnable.AddChangeHook(OnConVarChanged);
    g_hCvar_RequestCountSecondary.AddChangeHook(OnConVarChanged);
    g_hCvar_RequestCountTier1.AddChangeHook(OnConVarChanged);
    g_hCvar_RequestCountTier2.AddChangeHook(OnConVarChanged);
    g_hCvar_RequestCountThrowable.AddChangeHook(OnConVarChanged);


    HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
}

public void OnMapStart() 
{
    for (int i; i < WEPID_MELEES_SIZE; i++) 
    {
        if (MeleeWeaponModels[i][0] == '\0')
            continue;

        if (!IsModelPrecached(MeleeWeaponModels[i]))
            PrecacheModel(MeleeWeaponModels[i], true);
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
        if (g_bSafeAreaOnly && !IsClientInSafeArea(client))
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
    {
        g_hTimer = null;
        g_hTimer = CreateTimer(g_fAdTimer, Timer_Ad, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
}

void Timer_Ad(Handle hTimer)
{
    // once game started stop this.
    if (!g_bIsRoundAlive && g_bAd)
    {
        g_bEnableLimit && !g_bSeparateRequestCountEnable ? 
        CPrintToChatAll("%t", "Advertisement_Limit", g_iRequestCount) : 
        CPrintToChatAll("%t", "Advertisement");
    }
}

Action Command_Item(int client, int args)
{
    if (!client || !IsClientInGame(client))
        return Plugin_Handled;

    if (g_bSafeAreaOnly && !IsClientInSafeArea(client))
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

        g_bSecondaryEnable ? 
        FormatEx(sBuffer, sizeof(sBuffer), "%T", "SecondaryOn", client) :
        FormatEx(sBuffer, sizeof(sBuffer), "%T", "SecondaryOff", client);
        menu.AddItem("a", sBuffer);

        g_bTier1Enable ? 
        FormatEx(sBuffer, sizeof(sBuffer), "%T", "Tier1On", client) :
        FormatEx(sBuffer, sizeof(sBuffer), "%T", "Tier1Off", client);
        menu.AddItem("b", sBuffer);

        g_bTier2Enable ? 
        FormatEx(sBuffer, sizeof(sBuffer), "%T", "Tier2On", client) :
        FormatEx(sBuffer, sizeof(sBuffer), "%T", "Tier2Off", client);
        menu.AddItem("c", sBuffer);

        g_bThrowableEnable ? 
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
                    case 'a': if(g_bSecondaryEnable) CreateSecondaryMenu(client);
                    case 'b': if(g_bTier1Enable) CreateTier1Menu(client);
                    case 'c': if(g_bTier2Enable) CreateTier2Menu(client);
                    case 'd': if(g_bThrowableEnable) CreateThrowableMenu(client);
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
    menu.SetTitle("%T", "Secondary", client);

    // yea it's hardcoded.
    for (int i = 0; i < sizeof(g_sItemNamePhrases[0]); i++)
    {
        if (g_sItemNamePhrases[0][i][0] == '\0')
            continue;

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
                        if (g_bSeparateRequestCountEnable)
                        {
                            if (g_iSecondaryRequestCount > g_RequestCount[client].iSecondaryCount)
                            {
                                CheatCommand(client, line);
                                g_RequestCount[client].iSecondaryCount++;

                                CPrintToChatAll("%t", "GetItemWithLimit", client, g_sItemNamePhrases[0][param2], g_RequestCount[client].iSecondaryCount, g_iSecondaryRequestCount);
                            }
                            else
                            {
                                CPrintToChat(client, "%t", "ReachedLimit", g_iSecondaryRequestCount);
                            }
                        }
                        else
                        {
                            if (g_iRequestCount > g_RequestCount[client].iGlobalCount)
                            {
                                CheatCommand(client, line);
                                g_RequestCount[client].iGlobalCount++;

                                CPrintToChatAll("%t", "GetItemWithLimit", client, g_sItemNamePhrases[0][param2], g_RequestCount[client].iGlobalCount, g_iRequestCount);
                            }
                            else
                            {
                                CPrintToChat(client, "%t", "ReachedLimit", g_iRequestCount);
                            }
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
    menu.SetTitle("%T", "Tier1", client);

    for (int i = 0; i < sizeof(g_sItemNamePhrases[1]); i++)
    {
        if (g_sItemNamePhrases[1][i][0] == '\0')
            continue;

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
                if (g_bSeparateRequestCountEnable)
                {
                    if (g_iTier1RequestCount > g_RequestCount[client].iTier1Count)
                    {
                        CheatCommand(client, line);
                        g_RequestCount[client].iTier1Count++;

                        CPrintToChatAll("%t", "GetItemWithLimit", client, g_sItemNamePhrases[1][param2], g_RequestCount[client].iTier1Count, g_iTier1RequestCount);
                    }
                    else
                    {
                        CPrintToChat(client, "%t", "ReachedLimit", g_iTier1RequestCount);
                    }
                }
                else
                {
                    if (g_iRequestCount > g_RequestCount[client].iGlobalCount)
                    {
                        CheatCommand(client, line);
                        g_RequestCount[client].iGlobalCount++;

                        CPrintToChatAll("%t", "GetItemWithLimit", client, g_sItemNamePhrases[1][param2], g_RequestCount[client].iGlobalCount, g_iRequestCount);
                    }
                    else
                    {
                        CPrintToChat(client, "%t", "ReachedLimit", g_iRequestCount);
                    }
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
    menu.SetTitle("%T", "Tier2", client);

    for (int i = 0; i < sizeof(g_sItemNamePhrases[2]); i++)
    {
        if (g_sItemNamePhrases[2][i][0] == '\0')
            continue;

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
                if (g_bSeparateRequestCountEnable)
                {
                    if (g_iTier2RequestCount > g_RequestCount[client].iTier2Count)
                    {
                        CheatCommand(client, line);
                        g_RequestCount[client].iTier2Count++;

                        CPrintToChatAll("%t", "GetItemWithLimit", client, g_sItemNamePhrases[2][param2], g_RequestCount[client].iTier2Count, g_iTier2RequestCount);
                    }
                    else
                    {
                        CPrintToChat(client, "%t", "ReachedLimit", g_iTier2RequestCount);       
                    }
                }
                else
                {
                    if (g_iRequestCount > g_RequestCount[client].iGlobalCount)
                    {
                        CheatCommand(client, line);
                        g_RequestCount[client].iGlobalCount++;

                        CPrintToChatAll("%t", "GetItemWithLimit", client, g_sItemNamePhrases[2][param2], g_RequestCount[client].iGlobalCount, g_iRequestCount);
                    }
                    else
                    {
                        CPrintToChat(client, "%t", "ReachedLimit", g_iRequestCount);
                    }
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
    menu.SetTitle("%T", "Item", client);

    for (int i = 0; i < sizeof(g_sItemNamePhrases[3]); i++)
    {
        if (g_sItemNamePhrases[3][i][0] == '\0')
            continue;

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
                if (g_bSeparateRequestCountEnable)
                {
                    if (g_iThrowableRequestCount > g_RequestCount[client].iThrowableCount)
                    {
                        CheatCommand(client, line);
                        g_RequestCount[client].iThrowableCount++;

                        CPrintToChatAll("%t", "GetItemWithLimit", client, g_sItemNamePhrases[3][param2], g_RequestCount[client].iThrowableCount, g_iThrowableRequestCount);
                    }
                    else
                    {
                        CPrintToChat(client, "%t", "ReachedLimit", g_iThrowableRequestCount);
                    }
                }
                else
                {
                    if (g_iRequestCount > g_RequestCount[client].iGlobalCount)
                    {
                        CheatCommand(client, line);
                        g_RequestCount[client].iGlobalCount++;

                        CPrintToChatAll("%t", "GetItemWithLimit", client, g_sItemNamePhrases[3][param2], g_RequestCount[client].iGlobalCount, g_iRequestCount);
                    }
                    else
                    {
                        CPrintToChat(client,  "%t", "ReachedLimit", g_iRequestCount);
                    }
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
    menu.SetTitle("%T", "AdminMenu", client);
    
    g_bSecondaryEnable ?
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "SecondaryMenuOff", client) :
    FormatEx(sBuffer, sizeof(sBuffer), "%T", "SecondaryMenuOn", client);
    menu.AddItem("e", sBuffer);

    g_bTier1Enable ?
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "Tier1MenuOff", client) :
    FormatEx(sBuffer, sizeof(sBuffer), "%T", "Tier1MenuOn", client);
    menu.AddItem("f", sBuffer);

    g_bTier2Enable ? 
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "Tier2MenuOff", client) :
    FormatEx(sBuffer, sizeof(sBuffer), "%T", "Tier2MenuOn", client);
    menu.AddItem("g", sBuffer);

    g_bThrowableEnable ?
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "ItemMenuOff", client) :
    FormatEx(sBuffer, sizeof(sBuffer), "%T", "ItemMenuOn", client);
    menu.AddItem("h", sBuffer);

    g_bSafeAreaOnly ?
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
                        g_bSecondaryEnable = !g_bSecondaryEnable;
                        CPrintToChatAll("%t", "Menu_e", client, g_bSecondaryEnable ? "On" : "Off");
                    }

                    case 'f':
                    {
                        g_bTier1Enable = !g_bTier1Enable;
                        CPrintToChatAll("%t", "Menu_f", client, g_bTier1Enable ? "On" : "Off");
                    }

                    case 'g':
                    {
                        g_bTier2Enable = !g_bTier2Enable;
                        CPrintToChatAll("%t", "Menu_g", client, g_bTier2Enable ? "On" : "Off");
                    }

                    case 'h':
                    {
                        g_bThrowableEnable = !g_bThrowableEnable;
                        CPrintToChatAll("%t", "Menu_h", client, g_bThrowableEnable ? "On" : "Off");
                    }

                    case 'i':
                    {
                        g_bSafeAreaOnly = !g_bSafeAreaOnly;
                        CPrintToChatAll("%t", "Menu_i", client, g_bSafeAreaOnly ? "On" : "Off");
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

void OnAdTimerConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    delete g_hTimer;
    g_fAdTimer = convar.FloatValue;
    g_hTimer = CreateTimer(g_fAdTimer, Timer_Ad, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

void GetCvars()
{
    g_bSecondaryEnable          = g_hCvar_SencondaryEnable.BoolValue;
    g_bTier1Enable              = g_hCvar_Tier1Enable.BoolValue;
    g_bTier2Enable              = g_hCvar_Tier2Enable.BoolValue;
    g_bThrowableEnable          = g_hCvar_ThrowableEnable.BoolValue;
    g_bSafeAreaOnly             = g_hCvar_SafeAreaOnly.BoolValue;
    g_bEnableLimit              = g_hCvar_EnableLimit.BoolValue;
    g_iRequestCount             = g_hCvar_RequestCount.IntValue;
    g_bAd                       = g_hCvar_Ad.BoolValue;

    g_bSeparateRequestCountEnable = g_hCvar_SeparateRequestCountEnable.BoolValue;
    g_iSecondaryRequestCount    = g_hCvar_RequestCountSecondary.IntValue;
    g_iTier1RequestCount        = g_hCvar_RequestCountTier1.IntValue;
    g_iTier2RequestCount        = g_hCvar_RequestCountTier2.IntValue;
    g_iThrowableRequestCount    = g_hCvar_RequestCountThrowable.IntValue;
}

void Clear()
{
    if (g_bEnableLimit)
    {
        for (int i = 0; i < MaxClients; i++)
        {
            g_flLastTime[i] = 0.0;
            g_RequestCount[i].Init();
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

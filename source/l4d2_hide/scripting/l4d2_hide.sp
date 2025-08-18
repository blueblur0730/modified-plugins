#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <clientprefs>
#include <colors>
#include <l4d2util>

// from nmrih-notice by F1F88.
#define BIT_TOGGLE_TRANSMIT                  (1 << 0)
#define BIT_TOGGLE_TRANSMIT_WHEN_HOLDING_MED (1 << 1)
#define BIT_TOGGLE_TRANSMIT_WHEN_BLACK_WHITE (1 << 2)
#define BIT_ALL                              (1 << 2) - 1

public Plugin myinfo = 
{
    name = "[L4D2] Hide Players",
    author = "blueblur, qy087",
    description = "Adds command to show or hide other players.",
    version = "1.4",
    url = "https://github.com/blueblur0730/modified-plugins"
};

#define L4D2_MAXPLAYERS 32

bool 
	g_bHideStatus[L4D2_MAXPLAYERS + 1][L4D2_MAXPLAYERS + 1],
	g_bHoldingAlt[L4D2_MAXPLAYERS + 1];

int g_iHideRange[L4D2_MAXPLAYERS + 1];

bool g_bLate = false;
float g_flUseHoldSeconds;

int survivor_max_incapacitated_count;

Cookie 
	g_hCookie, 
	g_hCookie_Misc;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslation("hide.phrases");

	RegConsoleCmd("sm_hide", Cmd_Hide, "Show or hide other players. Usage: sm_hide <range>, 0 means off.");
	RegConsoleCmd("sm_hidemenu", Cmd_HideMenu, "Hide setting menu.");

	CreateConVarHook("sm_hide_use_hold_seconds", "0.5", "Seconds to hold on +use to reveal the hided player.", _, true, 0.0, _, _, OnHoldingSecondsChanged);
	ConVar cv = FindConVar("survivor_max_incapacitated_count");
	cv.AddChangeHook(OnCountChange);
	OnCountChange(cv, "", "");

	g_hCookie = FindOrCreateCookie("l4d2_hide", "Save the hide range.", CookieAccess_Protected);
	g_hCookie_Misc = FindOrCreateCookie("l4d2_hide_misc", "Ranged hide misc cookie.", CookieAccess_Protected);
	SetCookieMenuItem(MiscSelected, 0, "[Hide] Misc Menu");
	
	if (g_bLate)
	{
		OnMapStart();
		for (int i = 1; i < MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR)
			{
				OnClientPutInServer(i);
				OnClientCookiesCached(i);
			}
		}
	}
}

Handle g_hTimer;

public void OnPluginEnd()
{
	KillTimer(g_hTimer);
	delete g_hCookie;
}

public void OnMapStart()
{
	for (int i = 1; i < MaxClients; i++)
	{
		for (int j = 1; j < MaxClients; j++)
		{
			g_bHideStatus[i][j] = false;
		}
	}

	g_hTimer = CreateTimer(0.1, Timer_ThinkDistance, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientPutInServer(int client)
{
	g_iHideRange[client] = g_hCookie.GetInt(client, 0);
	SDKHook(client, SDKHook_SetTransmit, OnClientTransmit);
}

public void OnClientDisconnect(int client)
{
	for (int j = 1; j < MaxClients; j++)
	{
		g_bHideStatus[client][j] = false;
	}
	
	g_bHoldingAlt[client] = false;
	g_iHideRange[client] = 0;
}

public void OnClientCookiesCached(int client)
{
	g_iHideRange[client] = g_hCookie.GetInt(client, 0);
}

float g_flLastAltPress[L4D2_MAXPLAYERS + 1];

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (g_iHideRange[client] == 0)
		return;

	if (buttons & IN_USE)
	{
		if (!g_bHoldingAlt[client])
		{
			g_bHoldingAlt[client] = true;
			g_flLastAltPress[client] = GetGameTime();
		}

		if (GetGameTime() - g_flLastAltPress[client] > g_flUseHoldSeconds)
		{
			for (int i = 1; i < MaxClients; i++)
			{
				if (i == client || !IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != TEAM_SURVIVOR)
					continue;

				g_bHideStatus[client][i] = false;
			}	
		}
	}
	else
	{
		if (g_bHoldingAlt[client])
		{
			for (int i = 1; i < MaxClients; i++)
			{
				if (i == client || !IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != TEAM_SURVIVOR)
					continue;

				g_bHideStatus[client][i] = true;
			}

			g_bHoldingAlt[client] = false;
			g_flLastAltPress[client] = 0.0;
		}
	}
}

Action Timer_ThinkDistance(Handle hTimer)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (g_iHideRange[i] == 0)
			continue;

		if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != TEAM_SURVIVOR)
			continue;

		float vecMyself[3];
		GetClientAbsOrigin(i, vecMyself);

		for (int j = 1; j < MaxClients; j++)
		{
			if (i == j)
				continue;

			if (!IsClientInGame(j) || !IsPlayerAlive(j) || (GetClientTeam(j) != TEAM_SURVIVOR))
			{
				g_bHideStatus[i][j] = false;
				continue;
			}
				
			float vecTarget[3];
			GetClientAbsOrigin(j, vecTarget);

			g_bHideStatus[i][j] = (RoundToFloor(GetVectorDistance(vecMyself, vecTarget)) < g_iHideRange[i]);
		}
	}
	return Plugin_Continue;
}

Action OnClientTransmit(int target, int recipient)
{
	if (target == recipient) 
		return Plugin_Continue;

	if ((target <= 0 || target > MaxClients) || (recipient <= 0 || recipient > MaxClients))
		return Plugin_Continue;

	if (IsFakeClient(recipient) || GetClientTeam(recipient) == TEAM_SPECTATOR)
		return Plugin_Continue;

	if (!CheckPrefsBit(recipient, BIT_TOGGLE_TRANSMIT))
		return Plugin_Continue;

	if (g_iHideRange[recipient] == 0)
		return Plugin_Continue;

	if (!IsClientInGame(target) || !IsClientInGame(recipient))
		return Plugin_Continue;

	if (IsSurvivorAttacked(target) || IsIncapacitated(target) || IsHangingFromLedge(target))
		return Plugin_Continue;

	if (IsBlackAndWhite(target) && !CheckPrefsBit(recipient, BIT_TOGGLE_TRANSMIT_WHEN_BLACK_WHITE))
		return Plugin_Continue;

	if (IsHoldingMeds(recipient) && !CheckPrefsBit(recipient, BIT_TOGGLE_TRANSMIT_WHEN_HOLDING_MED))
		return Plugin_Continue;

	if (g_bHideStatus[recipient][target])
		return Plugin_Handled;

	return Plugin_Continue; 
}

Action Cmd_Hide(int client, int args)
{
	if (GetCmdArgs() != 1)
	{
		CReplyToCommand(client, "%t", "Usage");
		CReplyToCommand(client, "%t", "Current", g_iHideRange[client]);

		return Plugin_Handled;
	}

	g_iHideRange[client] = GetCmdArgInt(1);

	if (g_iHideRange[client] < 0)
		g_iHideRange[client] = 0;
		
	static char sCookie[10];
	Format(sCookie, sizeof(sCookie), "%d", g_iHideRange[client]);
	g_hCookie.Set(client, sCookie);
	CReplyToCommand(client, "%t", "SetRange", g_iHideRange[client]);
	return Plugin_Handled;
}

Action Cmd_HideMenu(int client, int args)
{
	vMiscCookieSelected(client);
	return Plugin_Handled;
}

void OnHoldingSecondsChanged(ConVar hConVar, const char[] strOldValue, const char[] strNewValue)
{
	g_flUseHoldSeconds = hConVar.FloatValue;
}

void OnCountChange(ConVar hConVar, const char[] strOldValue, const char[] strNewValue)
{
	survivor_max_incapacitated_count = hConVar.IntValue;
}

void MiscSelected(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	vMiscCookieSelected(client);
}

void vMiscCookieSelected(int client)
{
    Menu menu = new Menu(MiscPrefsMenuHandler);

	// adding a title will make this menu invisiable. wth?
    // Format(title, sizeof(title), "[Hide]控制菜单\n");
    // menu.SetTitle(title);

	char displayDesc[256];
	FormatEx(displayDesc, sizeof(displayDesc), "%T", "CurrentRange_Menu", client, g_hCookie.GetInt(client, g_iHideRange[client]));
	menu.AddItem("", displayDesc, ITEMDRAW_DISABLED);

	char info[16], display[256];

	IntToString(BIT_TOGGLE_TRANSMIT, info, sizeof(info));
	FormatEx(display, sizeof(display), "%T", "ToggleHide_Menu", client, (CheckPrefsBit(client, BIT_TOGGLE_TRANSMIT) ? "Yes" : "No"), client);
	menu.AddItem(info, display, ITEMDRAW_DEFAULT);

	IntToString(BIT_TOGGLE_TRANSMIT_WHEN_HOLDING_MED, info, sizeof(info));
	FormatEx(display, sizeof(display), "%T", "ToggleHideMed_Menu", client, (CheckPrefsBit(client, BIT_TOGGLE_TRANSMIT_WHEN_HOLDING_MED) ? "Yes" : "No"), client);
	menu.AddItem(info, display, ITEMDRAW_DEFAULT);

	IntToString(BIT_TOGGLE_TRANSMIT_WHEN_BLACK_WHITE, info, sizeof(info));
	FormatEx(display, sizeof(display), "%T", "ToggleHideBlackWhite_Menu", client, (CheckPrefsBit(client, BIT_TOGGLE_TRANSMIT_WHEN_BLACK_WHITE) ? "Yes" : "No"), client);
	menu.AddItem(info, display, ITEMDRAW_DEFAULT);

    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

int MiscPrefsMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            int client = param1;
            int option = param2;

            // item info - bit (int)
            char info[16];
            menu.GetItem(option, info, sizeof(info));

            int reverseBit = StringToInt(info);

            char newValue[16];
            IntToString(reverseBit ^ GetCookieValue(client), newValue, sizeof(newValue));

            g_hCookie_Misc.Set(client, newValue);
            vMiscCookieSelected(client);
        }

		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
				ShowCookieMenu(param1);
		}

		case MenuAction_End:
			delete menu;
    }
    return 0;
}

bool IsHoldingMeds(int client)
{
	int activeWep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	int	activeWepId	 = IdentifyWeapon(activeWep);

	switch (activeWepId)
	{
		case WEPID_FIRST_AID_KIT, WEPID_PAIN_PILLS, WEPID_ADRENALINE, WEPID_DEFIBRILLATOR:
			return true;

		default:
			return false;
	}
}

bool CheckPrefsBit(int client, int prefsBit)
{
    return (GetCookieValue(client) & prefsBit) != 0;
}

int GetCookieValue(int client)
{
    char buffer[16];
    g_hCookie_Misc.Get(client, buffer, sizeof(buffer));
    if (!buffer[0])
        return BIT_ALL;
    
    int value;
    if (!StringToIntEx(buffer, value))
        return BIT_ALL;
    
    return value;
}

stock bool IsBlackAndWhite(int client)
{
	return (GetEntProp(client, Prop_Send, "m_currentReviveCount") >= survivor_max_incapacitated_count);
}

stock void CreateConVarHook(const char[] name,
	const char[] defaultValue,
	const char[] description="",
	int flags=0,
	bool hasMin=false, float min=0.0,
	bool hasMax=false, float max=0.0,
	ConVarChanged callback)
{
	ConVar cv = CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
	
	Call_StartFunction(INVALID_HANDLE, callback);
	Call_PushCell(cv);
	Call_PushNullString();
	Call_PushNullString();
	Call_Finish();

	cv.AddChangeHook(callback);
}

stock void LoadTranslation(const char[] translation)
{
	char sPath[PLATFORM_MAX_PATH], sName[PLATFORM_MAX_PATH];
	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}

stock Cookie FindOrCreateCookie(const char[] name, const char[] description = "", CookieAccess access = CookieAccess_Public)
{
	Cookie hCookie = Cookie.Find(name);
	if (!hCookie)
	{
		hCookie = new Cookie(name, description, access);
		if (!hCookie)
			SetFailState("Unable to create cookie: %s.", name);
	}

	return hCookie;
}
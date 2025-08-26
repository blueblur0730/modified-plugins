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
    version = "1.4.1",
    url = "https://github.com/blueblur0730/modified-plugins"
};

#define L4D2_MAXPLAYERS 32

bool 
	g_bHideStatus[L4D2_MAXPLAYERS + 1][L4D2_MAXPLAYERS + 1],
	g_bHoldingUse[L4D2_MAXPLAYERS + 1];

int g_iHideRange[L4D2_MAXPLAYERS + 1];

bool g_bLate = false;
float g_flUseHoldSeconds;

int survivor_max_incapacitated_count;

Cookie 
	g_hCookie, 
	g_hCookie_Misc;

#include "l4d2_hide/menu.sp"
#include "l4d2_hide/stocks.sp"
#include "l4d2_hide/natives.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Hide_GetHideRange", Native_GetHideRange);
	CreateNative("Hide_SetHideRange", Native_SetHideRange);

	g_bLate = late;
	RegPluginLibrary("l4d2_hide");
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
	
	g_bHoldingUse[client] = false;
	g_iHideRange[client] = 0;
}

public void OnClientCookiesCached(int client)
{
	g_iHideRange[client] = g_hCookie.GetInt(client, 0);
}

float g_flLastUsePress[L4D2_MAXPLAYERS + 1];

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (g_iHideRange[client] == 0)
		return;

	if (buttons & IN_USE)
	{
		if (!g_bHoldingUse[client])
		{
			g_bHoldingUse[client] = true;
			g_flLastUsePress[client] = GetGameTime();
		}

		if (GetGameTime() - g_flLastUsePress[client] > g_flUseHoldSeconds)
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
		if (g_bHoldingUse[client])
		{
			for (int i = 1; i < MaxClients; i++)
			{
				if (i == client || !IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != TEAM_SURVIVOR)
					continue;

				g_bHideStatus[client][i] = true;
			}

			g_bHoldingUse[client] = false;
			g_flLastUsePress[client] = 0.0;
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

	if (!IsClientInGame(target) || !IsClientInGame(recipient))
		return Plugin_Continue;

	if (IsFakeClient(recipient) || GetClientTeam(recipient) == TEAM_SPECTATOR)
		return Plugin_Continue;

	if (!CheckPrefsBit(recipient, BIT_TOGGLE_TRANSMIT))
		return Plugin_Continue;

	if (g_iHideRange[recipient] == 0)
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
		
	g_hCookie.SetInt(client, g_iHideRange[client]);
	CReplyToCommand(client, "%t", "SetRange", g_iHideRange[client]);
	return Plugin_Handled;
}

Action Cmd_HideMenu(int client, int args)
{
	MiscCookieSelected(client);
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
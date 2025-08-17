#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <clientprefs>
#include <morecolors>

#define NMR_MAXPLAYERS 9

public Plugin myinfo = 
{
    name = "[NMRiH] Hide Players",
    author = "Dysphie, blueblur",
    description = "Adds command to show or hide other players.",
    version = "1.2.1",
    url = "https://github.com/blueblur0730/modified-plugins"
};

bool g_bHideStatus[NMR_MAXPLAYERS + 1][NMR_MAXPLAYERS + 1];
int g_iHideRange[NMR_MAXPLAYERS + 1];
bool g_bLate = false;
bool g_bEnableHideForSpec;
Cookie g_hCookie;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslation("hide.phrases");
	RegConsoleCmd("sm_hide", Cmd_Hide, "Show or hide other players. Usage: sm_hide <range>, 0 means off.");
	CreateConVarHook("sm_hide_enable_for_spec", "0", "Always applies hiding for spectators? 1 = yes, 0 = no.", _, true, 0.0, true, 1.0, OnConVarChanged);

	g_hCookie = Cookie.Find("nmrih_hide");
	if (!g_hCookie)
	{
		g_hCookie = new Cookie("nmrih_hide", "Save the hide range.", CookieAccess_Protected);
		if (!g_hCookie)
			SetFailState("Unable to create cookie.");
	}

	if (!g_bLate)
	{
		OnMapStart();
		for (int i = 1; i < MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				OnClientPutInServer(i);
				OnClientCookiesCached(i);
			}
		}
	}
}

public void OnPluginEnd()
{
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

	CreateTimer(0.1, Timer_ThinkDistance, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_SetTransmit, OnClientTransmit);
}

public void OnClientDisconnect(int client)
{
	for (int j = 1; j < MaxClients; j++)
	{
		g_bHideStatus[client][j] = false;
	}
	
	g_iHideRange[client] = 0;
}

public void OnClientCookiesCached(int client)
{
	g_iHideRange[client] = g_hCookie.GetInt(client, 0);
}

bool g_bHoldingAlt[NMR_MAXPLAYERS + 1];
float g_flLastAltPress[NMR_MAXPLAYERS + 1];

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (g_iHideRange[client] == 0)
		return;

	if (buttons & IN_ALT1)
	{
		if (!g_bHoldingAlt[client])
		{
			g_bHoldingAlt[client] = true;
			g_flLastAltPress[client] = GetGameTime();
		}

		if (GetGameTime() - g_flLastAltPress[client] > 1.0)
		{
			for (int i = 1; i < MaxClients; i++)
			{
				if (i == client || !IsClientInGame(i) || (IsClientObserver(i) && !g_bEnableHideForSpec))
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
				if (i == client || !IsClientInGame(i) || (IsClientObserver(i) && !g_bEnableHideForSpec))
					continue;

				g_bHideStatus[client][i] = true;
			}

			g_bHoldingAlt[client] = false;
			g_flLastAltPress[client] = 0.0;
		}
	}
}

void Timer_ThinkDistance(Handle hTimer)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (g_iHideRange[i] == 0)
			continue;

		if (!IsClientInGame(i) || (IsClientObserver(i) && !g_bEnableHideForSpec))
			continue;

		for (int j = 1; j < MaxClients; j++)
		{
			if (i == j)
				continue;

			if (!IsClientInGame(j) || !IsPlayerAlive(j))
			{
				g_bHideStatus[i][j] = false;
				continue;
			}
				
			float vecMyself[3], vecTarget[3];
			GetClientAbsOrigin(i, vecMyself);
			GetClientAbsOrigin(j, vecTarget);

			g_bHideStatus[i][j] = (RoundToFloor(GetVectorDistance(vecMyself, vecTarget)) < g_iHideRange[i]);
		}
	}
}

Action OnClientTransmit(int target, int recipient)
{
	if (target == recipient) 
		return Plugin_Continue;

	if ((target <= 0 || target > MaxClients) || (recipient <= 0 || recipient > MaxClients))
		return Plugin_Continue;

	if (g_iHideRange[recipient] == 0)
		return Plugin_Continue;

	if (!IsClientInGame(target) || !IsClientInGame(recipient))
		return Plugin_Continue;

	// transmit for the observer.
	if (IsClientObserver(recipient))
		return g_bEnableHideForSpec ? Plugin_Handled : Plugin_Continue;

	if (g_bHideStatus[recipient][target])
		return Plugin_Handled;

	return Plugin_Continue; 
}

Action Cmd_Hide(int client, int args)
{
	if (GetCmdArgs() != 1)
	{
		CReplyToCommand(client, "%t", "Usage");
		return Plugin_Handled;
	}	

	g_iHideRange[client] = GetCmdArgInt(1);

	if (g_iHideRange[client] < 0)
		g_iHideRange[client] = 0;

	g_hCookie.SetInt(client, g_iHideRange[client]);
	CReplyToCommand(client, "%t", "SetRange", g_iHideRange[client]);
	return Plugin_Handled;
}

void OnConVarChanged(ConVar hConVar, const char[] strOldValue, const char[] strNewValue)
{
	g_bEnableHideForSpec = hConVar.BoolValue;
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
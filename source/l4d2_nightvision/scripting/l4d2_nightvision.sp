#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define	UseTeam2	(1 << 0)
#define UseTeam3	(1 << 1)
#define UseTeamBoth (UseTeam2 | UseTeam3)
#define IMPULS_FLASHLIGHT 100

ConVar g_hCvar_NightVisionToWhom;
ConVar g_hCvar_NightVisionMode;

int g_iNightVisionToWhom;
int g_iNightVisionMode;
int g_iBrightness[MAXPLAYERS + 1];
int g_iPlayerLight[MAXPLAYERS + 1] = {-1, ...};
float g_fPressTime[MAXPLAYERS + 1];

#define PLUGIN_VERSION "r1.0"

public Plugin myinfo =
{
	name = "[L4D2] Nightvision",
	author = "Pan Xiaohai, Mr. Zero, blueblur",
	description = "Nightvision and dynamic light merger.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
	LoadTranslation("l4d2_nightvision.phrases");

	CreateConVar("l4d2_nightvision_version", PLUGIN_VERSION, "Version of Nightvision plugin", FCVAR_NOTIFY | FCVAR_REPLICATED);
	g_hCvar_NightVisionToWhom = CreateConVar("l4d2_nightvision_to_whom", "3", "0=off, 1=only survivor, 2=only infecteds, 3=both. Only when below is set to 1.");
	g_hCvar_NightVisionMode = CreateConVar("l4d2_nightvision_mode", "2", "1=birhgt light on your feet, 2=overall vision lighter.");
	g_hCvar_NightVisionToWhom.AddChangeHook(ConVarChange);
	g_hCvar_NightVisionMode.AddChangeHook(ConVarChange);
	GetConVar();

	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
}

void ConVarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetConVar();
}

void GetConVar()
{
	g_iNightVisionToWhom = g_hCvar_NightVisionToWhom.IntValue;
	g_iNightVisionMode = g_hCvar_NightVisionMode.IntValue;
}

public void OnConfigsExecuted()
{
	GetConVar();
}

public void OnClientDisconnect(int client)
{
	if (g_iNightVisionMode != 1)
		return;

	ResetSpriteNormal(client);
}

public void OnPlayerRunCmdPre(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (impulse == IMPULS_FLASHLIGHT)
	{
		if (((g_iNightVisionToWhom & UseTeam2) || (g_iNightVisionToWhom & UseTeamBoth)) && GetClientTeam(client) == 2)
		{
			float time = GetEngineTime();
			if(time - g_fPressTime[client] < 0.3)
				SwitchNightVision(client);

			g_fPressTime[client] = time; 
		}

		if (((g_iNightVisionToWhom & UseTeam3) || (g_iNightVisionToWhom & UseTeamBoth)) && GetClientTeam(client) == 3)
			SwitchNightVision(client);
	}
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
		ResetSpriteNormal(i);
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if (g_iNightVisionMode != 1)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return;

	ClientCommand(client, "slot10");
	int team = event.GetInt("team");

	switch (g_iNightVisionToWhom)
	{
		case 1:
		{
			if (team == 1 || team == 2)
				return;
		}
		case 2:
		{
			if (team == 3)
				return;
		}
		case 3: {}
	}

	ResetSpriteNormal(client);
}

void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	if (g_iNightVisionMode != 1)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!client || g_iBrightness[client] != 0 || IsFakeClient(client))
		return;

	g_iBrightness[client] = 0;
}

void SwitchNightVision(int client)
{
	if (g_iNightVisionMode == 1)
	{
		if (g_iPlayerLight[client] == -1)
		{
			CreateLight(client);
		}
		else
		{
			ResetSpriteNormal(client);
			ClientCommand(client, "slot10");
			PrintHintText(client, "%t", "NightVisionOff");
		}
	}
	else if (g_iNightVisionMode == 2)
	{
		int m_bNightVisionOn = GetEntProp(client, Prop_Send, "m_bNightVisionOn");
		if (!m_bNightVisionOn)
		{
			SetEntProp(client, Prop_Send, "m_bNightVisionOn", 1); 
			PrintHintText(client, "%t", "NightVisionOn");
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);
			PrintHintText(client, "%t", "NightVisionOff");
		}
	}
}

void CreateLight(int client)
{
	int iLight = CreateEntityByName("light_dynamic");
	if (IsValidEntity(iLight))
	{
		g_iPlayerLight[client] = EntIndexToEntRef(iLight);

		DispatchKeyValue(iLight, "_light", "255 255 255 255");

		char item[4];
		Format(item, sizeof item, "%d", g_iBrightness[client]);
		DispatchKeyValue(iLight, "brightness", item);

		DispatchKeyValueFloat(iLight, "spotlight_radius", 32.0);
		DispatchKeyValueFloat(iLight, "distance", 750.0);
		DispatchKeyValue(iLight, "style", "0");
		DispatchSpawn(iLight);
		AcceptEntityInput(iLight, "TurnOn");
		SetVariantString("!activator");
		AcceptEntityInput(iLight, "SetParent", client);
		TeleportEntity(iLight, view_as<float>({0.0, 0.0, 20.0}), view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR);
		SDKHook(iLight, SDKHook_SetTransmit, Hook_SetTransmit);
		PrintHintText(client, "%t", "NightVisionOn");
	}
}

Action Hook_SetTransmit(int entity, int client)
{
	int ref = EntIndexToEntRef(entity);

	if (g_iPlayerLight[client] == ref)
		return Plugin_Continue;

	return Plugin_Handled;
}

void RemoveRef(int &ref)
{
	int entity = EntRefToEntIndex(ref);

	if (entity != -1)
		RemoveEdict(entity);

	ref = -1;
}

void ResetSpriteNormal(int client)
{
	if (g_iPlayerLight[client] != -1)
		RemoveRef(g_iPlayerLight[client]);
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
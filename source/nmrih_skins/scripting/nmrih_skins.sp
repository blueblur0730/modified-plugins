#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <dhooks>
#include <nmrih_player>
#include <gamedata_wrapper>
#include <multicolors>
#include <stringt>

// Path to configuration files
#define	CFG_MENU "configs/nmrih_skins/skins_menu.cfg"
#define CFG_MENU_BODYGROUP "configs/nmrih_skins/skins_bodygroup_phrases.cfg"

enum
{
	CV_Enable,
	CV_Group,
	CV_Admin,
	CV_Timer,
	CV_UseTurned,

	CV_Total
};

int g_iFOV[NMR_MAXPLAYERS + 1];

KeyValues
	g_kvList[NMR_MAXPLAYERS + 1];

bool
	g_bLate,
	g_bCVar[CV_Total],
	g_bTPView[NMR_MAXPLAYERS + 1],
	g_bRandom[NMR_MAXPLAYERS + 1];

int
	g_iTurnedSkins,
	g_iTotalSkins;

char
	g_sModel[NMR_MAXPLAYERS + 1][PLATFORM_MAX_PATH],
	g_sTurnedModel[NMR_MAXPLAYERS + 1][PLATFORM_MAX_PATH],
	g_sViewModel[NMR_MAXPLAYERS + 1][PLATFORM_MAX_PATH],
	g_sWModelLabel[NMR_MAXPLAYERS + 1][PLATFORM_MAX_PATH];

Cookie
	g_hCookie_WModel,
	g_hCookie_VModel,
	g_hCookie_TurnedModel,
	g_hCookie_WModelLable;

#define	PL_NAME	"[NMRiH] Skins"
#define	PL_VER "2.5.0"

#include "nmrih_skins/bodygroup.sp"
#include "nmrih_skins/parse.sp"
#include "nmrih_skins/menu.sp"
#include "nmrih_skins/turned_process.sp"

// Based on the code of the plugin "SM Skinchooser HL2DM" v2.3 by Andi67
public Plugin myinfo =
{
	name = PL_NAME,
	version	= PL_VER,
	description	= "Skins menu with 3rd person view for NMRiH",
	author	= "Grey83, blueblur",
	url	= "https://github.com/blueblur0730/modified-plugins"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLate = late;
	RegPluginLibrary("nmrih_skins");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslation("nmrih_skins.phrases");
	LoadTranslations("nmrih_skins_configs.phrases");
	LoadGameData();
	LoadBodyGroupGameData();
	
	CreateConVar("nmrih_skins_version", PL_VER, PL_NAME, FCVAR_DONTRECORD | FCVAR_NOTIFY | FCVAR_SPONLY);

	CreateConVarHookEx("nmrih_skins_enable",	"1",	"Enable/Disable plugin", FCVAR_NOTIFY, CVarChange_Enable, CV_Enable);
	CreateConVarHookEx("nmrih_skins_admingroup","1",	"Enable/Disable the possebility to use the Groupsystem", _, CVarChange_AdminGroup, CV_Group);
	CreateConVarHookEx("nmrih_skins_adminonly",	"0",	"Enable/Disable deny of access to the menu except for admins", _, CVarChange_AdminOnly, CV_Admin);
	CreateConVarHookEx("nmrih_skins_spawntimer","1",	"Enable/Disable a timer that changes the model a second after the event 'player_spawn'", _, CVarChange_SpawnTimer, CV_Timer);
	CreateConVarHookEx("nmrih_skins_useturned", "1", 	"Enable/Disable the turned model being applied?", _, CVarChange_TurnedModel, CV_UseTurned);

	RegConsoleCmd("sm_model", Cmd_Model);
	RegConsoleCmd("sm_skin", Cmd_Model);
	HookEvent("player_spawn", Event_PlayerSpawn);

	g_hCookie_WModel = FindOrCreateCookie("nmrih_skins_wmodel", "World Model Prefs", CookieAccess_Protected);
	g_hCookie_VModel = FindOrCreateCookie("nmrih_skins_vmodel", "View Model Prefs", CookieAccess_Protected);
	g_hCookie_TurnedModel = FindOrCreateCookie("nmrih_skins_turnedmodel", "Turned Zombie Model", CookieAccess_Protected);
	g_hCookie_WModelLable = FindOrCreateCookie("nmrih_skins_wmodel_label", "World Model Label", CookieAccess_Protected);

	if (g_bLate) 
	{
		for (int i = 1; i <= MaxClients; i++) 
		{
			if (IsClientAuthorized(i))
			{
				OnClientCookiesCached(i);
				OnClientPostAdminCheck(i);
				OnClientPutInServer(i);
			}
		}
	}
}

public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; i++)
		delete g_kvList[i];

	g_hDetour.Disable(Hook_Pre, DTR_CNMRiH_TurnedZombie_Watcher_TurnThink_Pre);
	delete g_hDetour;

	delete g_hCookie_WModel;
	delete g_hCookie_VModel;
	delete g_hCookie_TurnedModel;
	delete g_hCookie_WModelLable;
}

public void OnMapStart()
{
	g_iTotalSkins = 0;
	g_iTurnedSkins = 0;

	ParseMenuModels();

	PrintToServer("%s:\n	Total: %d\n	Turned: %d", PL_NAME, g_iTotalSkins, g_iTurnedSkins);
}

public void OnClientPostAdminCheck(int client)
{
	g_bRandom[client] = true;
	g_bTPView[client] = false;
}

public void OnClientDisconnect(int client)
{
	// Reset the model for the client entry
	g_sModel[client][0] = '\0';
	g_sViewModel[client][0] = '\0';
	g_sTurnedModel[client][0] = '\0';

	g_iFOV[client] = 0;

	if (g_kvList[client])
		delete g_kvList[client];
}

public void OnClientPutInServer(int client)
{
	if (!IsClientInGame(client))
		return;

	if (!g_kvList[client])
	{
		char sBuffer[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, sBuffer, sizeof(sBuffer), CFG_MENU);

		g_kvList[client] = new KeyValues("Models");
		g_kvList[client].ImportFromFile(sBuffer);
	}
		
	g_iFOV[client] = GetEntProp(client, Prop_Send, "m_iFOV");
}

public void OnClientCookiesCached(int client)
{
	if (!IsClientInGame(client))
		return;

	char sBuffer[128];
	g_hCookie_WModel.Get(client, sBuffer, sizeof(sBuffer));
	strcopy(g_sModel[client], sizeof(g_sModel[client]), sBuffer);

	g_hCookie_VModel.Get(client, sBuffer, sizeof(sBuffer));
	strcopy(g_sViewModel[client], sizeof(g_sViewModel[client]), sBuffer);

	g_hCookie_TurnedModel.Get(client, sBuffer, sizeof(sBuffer));
	strcopy(g_sTurnedModel[client], sizeof(g_sTurnedModel[client]), sBuffer);

	g_hCookie_WModelLable.Get(client, sBuffer, sizeof(sBuffer));
	strcopy(g_sWModelLabel[client], sizeof(g_sWModelLabel[client]), sBuffer);
}

Action Cmd_Model(int client, int args)
{
	if (g_bCVar[CV_Enable] && IsValidClient(client) && (!g_bCVar[CV_Admin] || GetUserAdmin(client) != INVALID_ADMIN_ID)) 
		SendMainMenu(client);

	return Plugin_Handled;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bCVar[CV_Enable]) 
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bTPView[client] = false;

	if (!IsValidClient(client)) 
		return;

	// player_spawn may be fired earlier than cookies cahched.
	OnClientCookiesCached(client);

	if (g_bCVar[CV_Timer]) 
	{
		CreateTimer(1.0, Timer_Spawn, GetClientUserId(client));
	}
	else 
	{
		ApplyModelFromCache(client);
	}
}

void Timer_Spawn(Handle timer, int userid)
{
	ApplyModelFromCache(GetClientOfUserId(userid));
}

void ApplyModelFromCache(int client)
{
	if (!IsValidClient(client) || GetClientTeam(client)) 
		return;

	if (g_sModel[client][0] != '\0')
		ApplyModel(client, g_sModel[client]);

	if (g_sViewModel[client][0] != '\0')
		ApplyvModel(client, g_sViewModel[client]);
}

void ApplyModel(int client, const char[] model)
{
	if (model[0] == '\0' || !IsModelPrecached(model)) 
		return;

	SetEntityModel(client, model);
	SetEntityRenderColor(client);
}

void ApplyvModel(int client, const char[] model)
{
	if (model[0] == '\0' || !IsModelPrecached(model)) 
		return;

	NMR_Player(client).SetHandModelOverride(model);
}

void CreateConVarHookEx(const char[] name, const char[] defVal, const char[] descr = "", int flags = 0, ConVarChanged callback, int type)
{
	ConVar cvar = CreateConVar(name, defVal, descr, flags, true, 0.0, true, 1.0);
	cvar.AddChangeHook(callback);
	g_bCVar[type] = cvar.BoolValue;
}

void CVarChange_Enable(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	g_bCVar[CV_Enable] = cvar.BoolValue;
}

void CVarChange_AdminGroup(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	g_bCVar[CV_Group] = cvar.BoolValue;
}

void CVarChange_AdminOnly(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	g_bCVar[CV_Admin] = cvar.BoolValue;
}

void CVarChange_SpawnTimer(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	g_bCVar[CV_Timer] = cvar.BoolValue;
}

void CVarChange_TurnedModel(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	g_bCVar[CV_UseTurned] = cvar.BoolValue;
}

stock void ToggleView(int client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client)) 
		return;

	if (g_bTPView[client])
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
	}
	else
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", client);	// -1
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		SetEntProp(client, Prop_Send, "m_iFOV", g_iFOV[client]);
	}
}

stock bool CheckFlagAccess(int client, int access_flag)
{
	static AdminId id;
	if ((id = GetUserAdmin(client)) == INVALID_ADMIN_ID) return false;

	static AdminFlag flag;
	return FindFlagByChar(access_flag, flag) && GetAdminFlag(id, flag, Access_Effective);
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

stock void LoadTranslation(const char[] translation)
{
	char sPath[PLATFORM_MAX_PATH], sName[PLATFORM_MAX_PATH];
	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}
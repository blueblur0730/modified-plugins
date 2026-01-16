#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <gamedata_wrapper>

#define PLUGIN_NAME		"l4d2_grenadelauncher_no_team_collision"
#define PLUGIN_VERSION 	"1.2.1"

bool g_bEnable;
int g_iOff_m_bCollideWithTeammates = -1;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	EngineVersion test = GetEngineVersion();

	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin " ... PLUGIN_NAME ... "only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "[L4D2] Genade Launcher No Team Collision",
	author = "qy087, blueblur, 洛琪",
	description = "Pass your grenade launcher projectile through teammates.",
	version = PLUGIN_VERSION,
	url = "https://github.com/qy087/l4d2-littleplugins/"
};
	//Thanks: @blueblur0730, @Mineralcr
	//https://github.com/blueblur0730  https://github.com/Mineralcr
	
public void OnPluginStart()
{ 
	GameDataWrapper gd = new GameDataWrapper(PLUGIN_NAME);

	g_iOff_m_bCollideWithTeammates = gd.GetOffset("CGrenadeLauncher_Projectile->m_bCollideWithTeammates");

	CreateConVar( PLUGIN_NAME ... "_version", PLUGIN_VERSION, "L4D2 Genade Launcher No Team Collision Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);

	CreateConVarHook(
		PLUGIN_NAME ... "_enable",
		"1",
		"Enable/Disable The Genade Launcher Team Collision",
		FCVAR_NONE,
		true, 0.0, true, 1.0,
		ConVarChanged_Cvars);
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bEnable = convar.BoolValue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!g_bEnable) 
		return;

	if (strcmp(classname, "grenade_launcher_projectile") == 0) 
		SDKHook(entity, SDKHook_ThinkPost, OnThinkPost);
}

void OnThinkPost(int entity)
{
	if (!IsValidEntity(entity) || !g_bEnable)
		return;

	SetEntData(entity, g_iOff_m_bCollideWithTeammates, false, 1, true);
}

stock ConVar CreateConVarHook(const char[] name,
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
	
	return cv;
}

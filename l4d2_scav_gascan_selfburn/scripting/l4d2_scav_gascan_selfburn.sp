#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <colors>

#define PLUGIN_VERSION "2.5.2"
#define CONFIG_PATH "configs/l4d2_scav_gascan_selfburn.txt"
/* Change log:
* - 2.5.2
*	- Made the ConVar EnableKillPlayer control the TimerK instead of controlling the function KillPlayer() itself.
*	- Added back the detection of mapname c8m5 to decide whether the TimerK should be activated.
*
* - 2.5.1
*	- Changed varibles' name.
*   - Added a new ConVar to control function KillPlayer().
*
* - 2.5
*	- Added 2 ConVars to control the time every detection dose.
*	- Saperated Square ConVar into 2 individual ConVars to detect x and y.
*	- Deleted a function that is never being uesed.
*	- Optimized the logic.
*
* - 2.4
*	- Added a ConVar to debug the parse result.
*   - Optimized the logic.
*
* - 2.3
*	- Added 3 ConVars to control the coordinate detections
*	- Added more coordinate detections to control the boundray the gascan will not get burned (or will get burned in another way to say).
*	- Added coordinate detection to control the function KillPlayer(), which decided wether a player should die under the detection of z axie, instead of only detecting mapname c8m5.
*
* - 2.2
* 	- Added a config file to configurate the height boundray where a gascan will be burned.
*
* - 2.1
*	- Optimized codes.
*	- supprted translations.
*
* - 2.0
* 	- player will die under the c8m5 rooftop.
* 	- supported new syntax.
*
*/

//Timer
Handle
	TimerG = INVALID_HANDLE,
	TimerK = INVALID_HANDLE;

KeyValues
	kv;

ConVar
	EnableSelfBurn,
	EnableSquareDetectx,
	EnableSquareDetecty,
	EnableHeightDetectz,
	EnableDebug,
	EnableKillPlayer,
	IntervalBurnGascan,
	IntervalKillPlayer;

char
	c_mapname[128];

public Plugin myinfo =
{
	name = "L4D2 Scavenge Gascan Self Burn",
	author = "Ratchet, blueblur",
	description = "A plugin that able to configurate the position where the gascan will get burned once they were out of boundray in L4D2 scavenge mode. (And force player to die in impossible places.)",
	version = PLUGIN_VERSION,
	url = "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
	char buffer[128];

	// ConVars
	EnableSelfBurn 		= 	CreateConVar("l4d2_scav_gascan_selfburn_enable", "1", "Enable Plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	EnableSquareDetectx = 	CreateConVar("l4d2_scav_gascan_selfburn_detect_x", "0", "Enable square coordinate detect(detect x)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	EnableSquareDetecty =   CreateConVar("l4d2_scav_gascan_selfburn_detect_y", "0", "Enable square coordinate detect(detect y)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	EnableHeightDetectz =	CreateConVar("l4d2_scav_gascan_selfburn_detect_z", "1", "Enable height coordinate detect(detect z)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	EnableDebug 		= 	CreateConVar("l4d2_scav_gascan_selfburn_debug", "0", "Enable Debug", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	EnableKillPlayer    = 	CreateConVar("l4d2_scav_kill_player", "0", "Enable Kill Player", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	IntervalBurnGascan  = 	CreateConVar("l4d2_scav_gascan_selfburn_interval", "10.0", "Interval every gascan detection dose", FCVAR_NOTIFY, true, 0.0);
	IntervalKillPlayer  = 	CreateConVar("l4d2_scav_kill_player_interval", "3.0", "Interval every kill_player detection dose", FCVAR_NOTIFY, true, 0.0);

	// KeyValue
	kv = CreateKeyValues("Positions", "", "");
	BuildPath(Path_SM, buffer, 128, CONFIG_PATH);
	if (!FileToKeyValues(kv, buffer))
	{
		SetFailState("File %s may be missed!", CONFIG_PATH);
	}

	// Translations
	LoadTranslations("l4d2_scav_gascan_selfburn.phrases");

	// Check scavenge mode and enable status
	CheckStatus();
}

public Action CheckStatus()
{
	if(!GetConVarBool(EnableSelfBurn) || !L4D2_IsScavengeMode())
		return Plugin_Handled;
	else
		return Plugin_Continue;
}

public void OnMapStart()
{
	if( TimerG != INVALID_HANDLE )
		KillTimer(TimerG);

	TimerG = INVALID_HANDLE;

	if( TimerK != INVALID_HANDLE )
	KillTimer(TimerK);

	TimerK = INVALID_HANDLE;

	GetCurrentMap(c_mapname, sizeof(c_mapname));

	TimerG = CreateTimer(GetConVarFloat(IntervalBurnGascan), GascanDetectTimer, _, TIMER_REPEAT);
	if(GetConVarBool(EnableKillPlayer) || strcmp(c_mapname, "c8m5_rooftop") == 0)
	{
		TimerK = CreateTimer(GetConVarFloat(IntervalKillPlayer), KillPlayerTimer, _, TIMER_REPEAT);
	}
}

public Action GascanDetectTimer(Handle Timer, any Client)
{
	FindMisplacedCans();
	return Plugin_Handled;
}

public Action KillPlayerTimer(Handle Timer, any Client)
{
	KillPlayer();
	return Plugin_Handled;
}

public void ParseMapnameAndHeight(char[] height_min, char[] height_max, int maxlength, int maxlength2)
{
	KvRewind(kv);
	if(KvJumpToKey(kv, c_mapname))
	{
		KvGetString(kv, "height_zlimit_min", height_min, maxlength);
		KvGetString(kv, "height_zlimit_max", height_max, maxlength2);
		if(GetConVarBool(EnableDebug))
		{
			PrintToConsoleAll("--------------------------\nparsed mapname and value.\n mapname = %s\n height_min = %s\n height_max = %s", c_mapname, height_min, height_max);
		}
	}
	else
	{
		return;
	}
}

public void ParseMapnameAndWidthMax(char[] width_x_max, char[] width_y_max, int maxlength, int maxlength2)
{
	KvRewind(kv);
	if(KvJumpToKey(kv, c_mapname))
	{
		KvGetString(kv, "width_xlimit_max", width_x_max, maxlength);
		KvGetString(kv, "width_ylimit_max", width_y_max, maxlength2);
		if(GetConVarBool(EnableDebug))
		{
			PrintToConsoleAll("\nparsed mapname and value.\n mapname = %s\n width_x_max = %s\n width_y_max = %s", c_mapname, width_x_max, width_y_max);
		}
	}
	else
	{
		return;
	}
}

public void ParseMapnameAndWidthMin(char[] width_x_min, char[] width_y_min, int maxlength, int maxlength2)
{
	KvRewind(kv);
	if(KvJumpToKey(kv, c_mapname))
	{
		KvGetString(kv, "width_xlimit_min", width_x_min, maxlength);
		KvGetString(kv, "width_ylimit_min", width_y_min, maxlength2);
		if(GetConVarBool(EnableDebug))
		{
			PrintToConsoleAll("\nparsed mapname and value.\n mapname = %s\n width_x_max = %s\n width_y_max = %s\n --------------------------", c_mapname, width_x_min, width_y_min);
		}
	}
	else
	{
		return;
	}
}

stock void FindMisplacedCans()
{
	int ent = -1;
	char g_height_min[128], g_height_max[128];
	char g_width_x_min[128], g_width_y_min[128];
	char g_width_x_max[128], g_width_y_max[128];

	ParseMapnameAndHeight(g_height_min, g_height_max, sizeof(g_height_min), sizeof(g_height_max));
	ParseMapnameAndWidthMax(g_width_x_max, g_width_y_max, sizeof(g_width_x_max), sizeof(g_width_y_max));
	ParseMapnameAndWidthMin(g_width_x_min, g_width_y_min, sizeof(g_width_x_min), sizeof(g_width_y_min));

	while ((ent = FindEntityByClassname(ent, "weapon_gascan")) != -1)
	{
		if (!IsValidEntity(ent))
			continue;

		float position[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", position);

		/*
		* if gascan reached a place that is lower than the coordinate the g_height_min given on z axie, ignite gascan.
		* if gascan reached a place that is higher than the coordinate the g_height_max given on z axie, ignite gascan.
		* if gascan reached a place that its coordinate is smaller than the coordinate g_width_x_min given on x axie, ignite gascan.
		* if gascan reached a place that its coordinate is smaller than the coordinate g_width_y_min given on y axie, ignite gascan.
		* if gascan reached a place that its coordinate is bigger than the coordinate g_width_x_max given on x axie, ignite gascan.
		* if gascan reached a place that its coordinate is bigger than the coordinate g_width_y_max given on y axie, ignite gascan.
		*
		* In summary, gascan will get burned if it has ran out of the cube boundray you defined on every specific map.
		*/

		if(GetConVarBool(EnableHeightDetectz))
		{
			if(strlen(g_height_min) == 0 || strlen(g_height_max) == 0)
			{
				return;
			}
			else
			{
				if(position[2] <= StringToFloat(g_height_min))
				{
					if(position[2])			// Has gascan not hold by survivor? or has gascan become static?
						Ignite(ent);
				}

				if(StringToFloat(g_height_max) <= position[2])
				{
					if(position[2])
						Ignite(ent);
				}
			}
		}

		if(GetConVarBool(EnableSquareDetectx))
		{
			if(strlen(g_width_x_max) == 0 || strlen(g_width_x_min) == 0)
			{
				return;
			}
			else
			{
				if(StringToFloat(g_width_x_max) <= position[0])
				{
					if(position[0])
						Ignite(ent);
				}

				if(position[0] <= StringToFloat(g_width_x_min))
				{
					if(position[0])
					Ignite(ent);
				}
			}
		}

		if(GetConVarBool(EnableSquareDetecty))
		{
			if(strlen(g_width_y_max) == 0 || strlen(g_width_y_min) == 0)
			{
				return;
			}
			else
			{
				if(StringToFloat(g_width_y_max) <= position[1])
				{
					if(position[1])
						Ignite(ent);
				}

				if(position[1] <= StringToFloat(g_width_y_min))
				{	
					if(position[1])
						Ignite(ent);
				}
			}
		}
	}
}

public void KillPlayer()
{
	char g_height_min[128], g_height_max[128];

	ParseMapnameAndHeight(g_height_min, g_height_max, sizeof(g_height_min), sizeof(g_height_max));

	for (int i = 1; i <= MAXPLAYERS; i++)
	{
		if (IsValidPlayer(i) && IsClientInGame(i))
		{
			float position[3];
			GetClientAbsOrigin(i, position);
			if(position[2] <= StringToInt(g_height_min))
			{
				ForcePlayerSuicide(i);
			}
		}
	}
}

static bool IsValidPlayer(int client)
{
	if (0 < client <= MaxClients)
		return true;
	return false;
}

stock Action Ignite(int entity)
{
	AcceptEntityInput(entity, "ignite");
	CPrintToChatAll("%t", "Ignite");		//"Gascan out of bounds! Ignited!"
	return Plugin_Handled;
}
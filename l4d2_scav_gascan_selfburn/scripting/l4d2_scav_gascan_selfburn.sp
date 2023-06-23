#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <colors>

#define PLUGIN_VERSION "2.5"
#define CONFIG_PATH "configs/l4d2_scav_gascan_selfburn.txt"
/* Change log:
* - 2.5
*	- Added 2 ConVars to control the time every detection dose.
*	- Saperate Square ConVar into 2 individual ConVars to detect x and y.
*	- Deleted a function that never being uesed.
*	- Optimized the logic.
*
* - 2.4
*	- Added a ConVar to debug the parse result.
*   - Optimized the logic.
*
* - 2.3
*	- Added 3 ConVars to control the coordinate detections
*	- Added more coordinate detections to control the boundray the gascan will not get burned (or will get burned in another way to say).
*	- Added coordinate detection to control the height boundray the player will get killed compulsorily.
*
* - 2.2
* 	- Added config file to configurate the height bounds that a gascan needs to burn.
*
* - 2.1
*	- Optimized codes.
*	- supprt translations.
*
* - 2.0
* 	- player will die under the c8m5 rooftop.
* 	- support new syntax.
* ----------------------------------------------------------------
* - To Do
*	- Add a method to detect minor coordinate.
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
	EnableSquareDetect1,
	EnableSquareDetect2,
	EnableHeightDetect,
	EnableDebug,
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
	EnableSquareDetect1 = 	CreateConVar("l4d2_scav_gascan_selfburn_detect_x", "0", "Enable square coordinate detect(detect x)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	EnableSquareDetect2 =   CreateConVar("l4d2_scav_gascan_selfburn_detect_y", "0", "Enable square coordinate detect(detect y)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	EnableHeightDetect 	=	CreateConVar("l4d2_scav_gascan_selfburn_detect_z", "1", "Enable height coordinate detect(detect z)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	EnableDebug 		= 	CreateConVar("l4d2_scav_gascan_selfburn_debug", "0", "Enable Debug", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	IntervalBurnGascan  = 	CreateConVar("l4d2_scav_gascan_selfburn_interval", "10.0", "Interval every gascan detection dose", FCVAR_NOTIFY, true, 0.0);
	IntervalKillPlayer  = 	CreateConVar("l4d2_scav_kill_player_interval", "5.0", "Interval every kill_player detection dose", FCVAR_NOTIFY, true, 0.0);

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
	TimerK = CreateTimer(GetConVarFloat(IntervalKillPlayer), KillPlayerTimer, _, TIMER_REPEAT);
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

public void ParseMapnameAndHeight(char[] height_down, char[] height_up, int maxlength, int maxlength2)
{
	KvRewind(kv);
	if(KvJumpToKey(kv, c_mapname))
	{
		KvGetString(kv, "height_zlimit_down", height_down, maxlength);
		KvGetString(kv, "height_zlimit_up", height_up, maxlength2);
		if(GetConVarBool(EnableDebug))
		{
			PrintToConsoleAll("--------------------------\nparsed mapname and value.\n mapname = %s\n height_down = %s\n height_up = %s", c_mapname, height_down, height_up);
		}
	}
	else
	{
		return;
	}
}

public void ParseMapnameAndWidthFirst(char[] width_x_one, char[] width_y_one, int maxlength, int maxlength2)
{
	KvRewind(kv);
	if(KvJumpToKey(kv, c_mapname))
	{
		KvGetString(kv, "width_xlimit_one", width_x_one, maxlength);
		KvGetString(kv, "width_ylimit_one", width_y_one, maxlength2);
		if(GetConVarBool(EnableDebug))
		{
			PrintToConsoleAll("\nparsed mapname and value.\n mapname = %s\n width_x_one = %s\n width_y_one = %s", c_mapname, width_x_one, width_y_one);
		}
	}
	else
	{
		return;
	}
}

public void ParseMapnameAndWidthSecond(char[] width_x_two, char[] width_y_two, int maxlength, int maxlength2)
{
	KvRewind(kv);
	if(KvJumpToKey(kv, c_mapname))
	{
		KvGetString(kv, "width_xlimit_two", width_x_two, maxlength);
		KvGetString(kv, "width_ylimit_two", width_y_two, maxlength2);
		if(GetConVarBool(EnableDebug))
		{
			PrintToConsoleAll("\nparsed mapname and value.\n mapname = %s\n width_x_two = %s\n width_y_two = %s\n --------------------------", c_mapname, width_x_two, width_y_two);
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
	char g_height_down[128], g_height_up[128];
	char g_width_x_one[128], g_width_y_one[128];
	char g_width_x_two[128], g_width_y_two[128];

	ParseMapnameAndHeight(g_height_down, g_height_up, sizeof(g_height_down), sizeof(g_height_up));
	ParseMapnameAndWidthFirst(g_width_x_one, g_width_y_one, sizeof(g_width_x_one), sizeof(g_width_y_one));
	ParseMapnameAndWidthSecond(g_width_x_two, g_width_y_two, sizeof(g_width_x_two), sizeof(g_width_y_two));

	while ((ent = FindEntityByClassname(ent, "weapon_gascan")) != -1)
	{
		if (!IsValidEntity(ent))
			continue;

		float position[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", position);

		/*
		* if gascan reached a place that is lower than the coordinate the g_height_down given on z axie, ignite gascan.
		* if gascan reached a place that is higher than the coordinate the g_height_up given on z axie, ignite gascan.
		* if gascan reached a place that its coordinate is bigger than the coordinate g_width_x_one given on x axie, ignite gascan.
		* if gascan reached a place that its coordinate is bigger than the coordinate g_width_y_one given on y axie, ignite gascan.
		* if gascan reached a place that its coordinate is smaller than the coordinate g_width_x_two given on x axie, ignite gascan.
		* if gascan reached a place that its coordinate is smaller than the coordinate g_width_y_two given on y axie, ignite gascan.
		*
		* In summary, gascan will get burned if it has ran out of a cube you defined on every specific map.
		*/

		if(GetConVarBool(EnableHeightDetect))
		{
			if(strlen(g_height_down) == 0 || strlen(g_height_up) == 0)
			{
				return;
			}
			else
			{
				if(position[2] <= StringToFloat(g_height_down))
				{
					if(position[2])			// Has gascan not hold by survivor? or has gascan become static?
						Ignite(ent);
				}

				if(StringToFloat(g_height_up) <= position[2])
				{
					if(position[2])
						Ignite(ent);
				}
			}
		}

		if(GetConVarBool(EnableSquareDetect1))
		{
			if(strlen(g_width_x_one) == 0 || strlen(g_width_x_two) == 0)
			{
				return;
			}
			else
			{
				if(StringToFloat(g_width_x_one) <= position[0])
				{
					if(position[0])
						Ignite(ent);
				}

				if(position[0] <= StringToFloat(g_width_x_two))
				{
					if(position[0])
					Ignite(ent);
				}
			}
		}

		if(GetConVarBool(EnableSquareDetect2))
		{
			if(strlen(g_width_y_one) == 0 || strlen(g_width_y_two) == 0)
			{
				return;
			}
			else
			{
				if(StringToFloat(g_width_y_one) <= position[1])
				{
					if(position[1])
						Ignite(ent);
				}

				if(position[1] <= StringToFloat(g_width_y_two))
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
	char g_height_down[128], g_height_up[128];

	ParseMapnameAndHeight(g_height_down, g_height_up, sizeof(g_height_down), sizeof(g_height_up));

	for (int i = 1; i <= MAXPLAYERS; i++)
	{
		if (IsValidPlayer(i) && IsClientInGame(i))
		{
			float position[3];
			GetClientAbsOrigin(i, position);
			if(GetConVarBool(EnableHeightDetect))
			{
				if(position[2] <= StringToInt(g_height_down))
				{
					ForcePlayerSuicide(i);
				}
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
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <colors>

#define PLUGIN_VERSION "2.3"
#define CONFIG_PATH "configs/l4d2_scav_gascan_selfburn.txt"
/* Change log:
* - 2.3
*	- Added 3 ConVars to control the coordinate detections
*	- Added more coordinate detections to control the boundray the gascan will not get burned (or will get burned in another way to say).
*	- Added coordinate detection to control the height boundray the player will get killed compulsoryly.
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
*
*/

//Timer
Handle
	TimerH = INVALID_HANDLE;

KeyValues
	kv;

ConVar
	PluginEnable,
	SquareEnable,
	HeightEnable;

char 
	c_mapname[128];

public Plugin myinfo =
{
	name = "L4D2 Scavenge Gascan Self Burn",
	author = "Ratchet, blueblur",
	description = "A plugin that able to configurate the position where the gascan will get burned once they were out of boundray in L4D2 scavenge mode.",
	version = PLUGIN_VERSION,
	url = "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
	char buffer[128];

	// ConVar
	PluginEnable 	= CreateConVar("l4d2_scav_gascan_selfburn_enable", "1", "Enable Plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	SquareEnable 	= CreateConVar("l4d2_scav_gascan_selfburn_square", "1", "Enable square coordinate detect(detect x and y)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HeightEnable 	= CreateConVar("l4d2_scav_gascan_selfburn_height", "1", "Enable height coordinate detect(detect z)", FCVAR_NOTIFY, true, 0.0, true, 1.0);

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
	if(GetConVarInt(PluginEnable) == 1 && L4D2_IsScavengeMode() == true)
		return Plugin_Continue;
	else
		return Plugin_Handled;
}

public void OnMapStart()
{
	if( TimerH != INVALID_HANDLE )
		KillTimer(TimerH);
		
	TimerH = INVALID_HANDLE;

	GetCurrentMap(c_mapname, sizeof(c_mapname));

	TimerH = CreateTimer(15.0, ScavTimerH, _, TIMER_REPEAT);
}

public Action ScavTimerH(Handle Timer, any Client)
{	
	FindMisplacedCans();
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

	if(GetConVarBool(HeightEnable))
		ParseMapnameAndHeight(g_height_down, g_height_up, sizeof(g_height_down), sizeof(g_height_up));

	if(GetConVarBool(SquareEnable))
		ParseMapnameAndWidthFirst(g_width_x_one, g_width_y_one, sizeof(g_width_x_one), sizeof(g_width_y_one));

	if(GetConVarBool(SquareEnable))
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

		if(StringToFloat(g_height_down) != 0.0)		//empty string converts to float 0.0
		{
			if(position[2] <= StringToFloat(g_height_down))
				Ignite(ent);
		}

		if(StringToFloat(g_height_up) != 0.0)
		{
			if(StringToFloat(g_height_up) <= position[2])
				Ignite(ent);
		}

		if(StringToFloat(g_width_x_one) != 0.0)
		{
			if(StringToFloat(g_width_x_one) <= position[0])
				Ignite(ent);
		}

		if(StringToFloat(g_width_x_two) != 0.0)
		{
			if(position[0] <= StringToFloat(g_width_x_two))
				Ignite(ent);
		}

		if(StringToFloat(g_width_y_one) != 0.0)
		{
			if(StringToFloat(g_width_y_one) <= position[1])
				Ignite(ent);
		}

		if(StringToFloat(g_width_y_two) != 0.0)
		{
			if(position[1] <= StringToFloat(g_width_y_two))
				Ignite(ent);
		}
	}
}

public void KillPlayer()
{
	char g_height_down[128], g_height_up[128];

	if(GetConVarBool(HeightEnable))
		ParseMapnameAndHeight(g_height_down, g_height_up, sizeof(g_height_down), sizeof(g_height_up));

	for (int i = 1; i <= MAXPLAYERS; i++)
	{
		if (IsValidPlayer(i) && IsClientInGame(i))
		{
			float position[3];
			GetClientAbsOrigin(i, position);
			if(StringToInt(g_height_down) != 0.0)
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

stock int FindEntityByClassname2(int startEnt, char classname[64])
{
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}
/* Change log:
 * - 2.7
 *	- Optimized code format.
 *  - Added 3 cvar to control the self burn boundary. now every boundary is controlled by a specific cvar.
 *  - moved the changelog to the top of the file. (before it was right between the defined variables and includes and I mean it really seems uncomfortable :( )
 * 
 * - 2.6.4
 *	- Optimized the logic
 *		- CheckDetectCountThenIgnite() is no longer public.
 * 	- Cancelled the nessarity of left4dhooks. Made IsScavengeMode() function alone.
 *
 * - 2.6.3
 *	- Optimized the logic.
 *		- Fixed when current map name can not parse with coodinate, it caused players' death.
 *		- Coordinate parsing functions are no longer public. KillPlayer() function are no longer public.
 *
 * - 2.6.2
 *	- Optimized the logic.
 *
 * - 2.6.1
 *	- Now if a gascan were crossed two axies(such as x and z), it would be only seen as the same one transborder.
 *	- Added a new translation for noticing player the limit has been reached.
 *
 * - 2.6
 *	- Added two ConVars to control the limit of burned gascan to decide wether we choose to stop the igniting optionally.
 *	- Added optional translations
 *
 * - 2.5.2
 *	- Made the ConVar g_hCvarEnableKillPlayer control the g_hTimerK instead of controlling the function KillPlayer() itself.
 *	- Added back the detection of mapname c8m5 to decide whether the g_hTimerK should be activated.
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

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <colors>

#define PLUGIN_VERSION "2.7"
#define CONFIG_PATH	   "configs/l4d2_scav_gascan_selfburn.txt"

Handle
	g_hTimerG = INVALID_HANDLE,
	g_hTimerK = INVALID_HANDLE;

KeyValues
	kv;

ConVar
	g_hCvarEnableSelfBurn,
	g_hCvarEnableSquareDetectx_max,
	g_hCvarEnableSquareDetectx_min,
	g_hCvarEnableSquareDetecty_max,
	g_hCvarEnableSquareDetecty_min,
	g_hCvarEnableHeightDetectz_max,
	g_hCvarEnableHeightDetectz_min,
	g_hCvarEnableDebug,
	g_hCvarEnableKillPlayer,
	g_hCvarEnableCountLimit,
	g_hCvarIntervalBurnGascan,
	g_hCvarIntervalKillPlayer,
	g_hCvarBurnedGascanMaxLimit,
	g_hCvarGameMode;

char
	g_sMapName[128];

int
	g_iBurnedGascanCount,
	g_iDetectCount;

public Plugin myinfo =
{
	name		= "[L4D2] Scavenge Gascan Self Burn",
	author		= "Ratchet, blueblur",
	description = "A plugin that able to configurate the position where the gascan will get burned once they were out of boundray in L4D2 scavenge mode. (And force player to die in impossible places.)",
	version		= PLUGIN_VERSION,
	url			= "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
	char buffer[128];

	// ConVars
	g_hCvarEnableSelfBurn		   = CreateConVar("l4d2_scav_gascan_selfburn_enable", "1", "Enable Plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarEnableSquareDetectx_max = CreateConVar("l4d2_scav_gascan_selfburn_detect_x_max", "1", "Enable square coordinate detection(detect x max)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarEnableSquareDetectx_min = CreateConVar("l4d2_scav_gascan_selfburn_detect_x_min", "1", "Enable square coordinate detection(detect x min)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarEnableSquareDetecty_max = CreateConVar("l4d2_scav_gascan_selfburn_detect_y_max", "1", "Enable square coordinate detection(detect y max)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarEnableSquareDetecty_min = CreateConVar("l4d2_scav_gascan_selfburn_detect_y_min", "1", "Enable square coordinate detection(detect y min)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarEnableHeightDetectz_max = CreateConVar("l4d2_scav_gascan_selfburn_detect_z_max", "1", "Enable height coordinate detection(detect z max)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarEnableHeightDetectz_min = CreateConVar("l4d2_scav_gascan_selfburn_detect_z_min", "1", "Enable height coordinate detection(detect z min)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarEnableDebug			   = CreateConVar("l4d2_scav_gascan_selfburn_debug", "0", "Enable Debug", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarEnableKillPlayer		   = CreateConVar("l4d2_scav_kill_player", "0", "Enable Kill Player", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarEnableCountLimit		   = CreateConVar("l4d2_scav_gascan_burned_limit_enable", "1", "Enable Limited Gascan burn", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	g_hCvarIntervalBurnGascan	   = CreateConVar("l4d2_scav_gascan_selfburn_interval", "10.0", "Interval every gascan detection dose", FCVAR_NOTIFY, true, 0.0);
	g_hCvarIntervalKillPlayer	   = CreateConVar("l4d2_scav_kill_player_interval", "3.0", "Interval every kill_player detection dose", FCVAR_NOTIFY, true, 0.0);

	g_hCvarBurnedGascanMaxLimit	   = CreateConVar("l4d2_scav_gascan_burned_limit", "4", "Limits the max gascan can get burned if they are out of bounds.", FCVAR_NOTIFY, true, 0.0);

	g_hCvarGameMode				   = FindConVar("mp_gamemode");

	// KeyValue
	kv							   = CreateKeyValues("Positions", "", "");
	BuildPath(Path_SM, buffer, 128, CONFIG_PATH);
	if (!FileToKeyValues(kv, buffer))
	{
		SetFailState("File %s may be missed!", CONFIG_PATH);
	}

	// Hooks
	HookEvent("scavenge_round_start", Event_ScavRoundStart, EventHookMode_PostNoCopy);
	HookEvent("scavenge_round_finished", Event_ScavRoundFinished, EventHookMode_PostNoCopy);

	// Translations
	LoadTranslations("l4d2_scav_gascan_selfburn.phrases");

	// Check scavenge mode and enable status
	CheckStatus();
}

public Action CheckStatus()
{
	if (!g_hCvarEnableSelfBurn.BoolValue || !IsScavengeMode())
		return Plugin_Handled;
	else
		return Plugin_Continue;
}

public void OnMapStart()
{
	if (g_hTimerG != INVALID_HANDLE)
		KillTimer(g_hTimerG);

	g_hTimerG = INVALID_HANDLE;

	if (g_hTimerK != INVALID_HANDLE)
		KillTimer(g_hTimerK);

	g_hTimerK = INVALID_HANDLE;

	GetCurrentMap(g_sMapName, sizeof(g_sMapName));

	g_hTimerG = CreateTimer(g_hCvarIntervalBurnGascan.FloatValue, Timer_GascanDetect, _, TIMER_REPEAT);
	if (g_hCvarEnableKillPlayer.BoolValue || strcmp(g_sMapName, "c8m5_rooftop") == 0)		// set suicide timer defaultly on c8m5. this is because in some cases death-charge may not casue player's death.
	{
		g_hTimerK = CreateTimer(g_hCvarIntervalKillPlayer.FloatValue, Timer_KillPlayer, _, TIMER_REPEAT);
	}

	g_iBurnedGascanCount = 0;
}

public void OnMapEnd()
{
	g_iBurnedGascanCount = 0;
}

public Action Event_ScavRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iBurnedGascanCount = 0;
	return Plugin_Continue;
	// if the reason of round ending is that the last survivor was holding the gascan and died out-bound,
	// the gascan will ignite and the count will pass to the next round. we should reset the count on round start.
}

public Action Event_ScavRoundFinished(Event event, const char[] name, bool dontBroadcast)
{
	g_iBurnedGascanCount = 0;
	return Plugin_Continue;
}

Action Timer_GascanDetect(Handle Timer)
{
	FindMisplacedCans();
	return Plugin_Handled;
}

Action Timer_KillPlayer(Handle Timer)
{
	KillPlayer();
	return Plugin_Handled;
}

stock void FindMisplacedCans()
{
	int	  ent = -1;
	float height_min, height_max;
	float width_x_min, width_y_min;
	float width_x_max, width_y_max;

	ParseMapnameAndHeight(height_min, height_max);
	ParseMapnameAndWidthMax(width_x_max, width_y_max);
	ParseMapnameAndWidthMin(width_x_min, width_y_min);

	while ((ent = FindEntityByClassname(ent, "weapon_gascan")) != -1)
	{
		if (!IsValidEntity(ent))
			continue;	 // the entity is not a gascan, continue next loop

		if (g_hCvarEnableCountLimit.BoolValue && IsReachedLimit() == true)
			break;	  // burned gascan has reached its max limit we set, stop the loop (stop igniting the gascan).

		float position[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", position);

		g_iDetectCount = 0;		// initialize the detect count in every loop.

		/*
		 * if gascan reached a place that is lower than the coordinate the height_min given on z axie, ignite gascan.
		 * if gascan reached a place that is higher than the coordinate the height_max given on z axie, ignite gascan.
		 * if gascan reached a place that its coordinate is smaller than the coordinate width_x_min given on x axie, ignite gascan.
		 * if gascan reached a place that its coordinate is smaller than the coordinate width_y_min given on y axie, ignite gascan.
		 * if gascan reached a place that its coordinate is bigger than the coordinate width_x_max given on x axie, ignite gascan.
		 * if gascan reached a place that its coordinate is bigger than the coordinate width_y_max given on y axie, ignite gascan.
		 *
		 * In summary, gascan will get burned if it has ran out of the cube boundray you defined on every specific map.
		 */

		if (g_hCvarEnableHeightDetectz_max.BoolValue)
		{
			if (height_max == 0.0)
			{
				return;
			}
			else
			{
				if (height_max <= position[2])
				{
					if (position[2])	// Has gascan not hold by survivor? or has gascan become static?
					{
						g_iDetectCount++;		// +1 detect count
						CheckDetectCountThenIgnite(ent);
					}
				}
			}
		}

		if (g_hCvarEnableHeightDetectz_min.BoolValue)
		{
			if (height_min == 0.0)
			{
				return;
			}
			else
			{
				if (position[2] <= height_min)
				{
					if (position[2])
					{
						g_iDetectCount++;
						CheckDetectCountThenIgnite(ent);
					}
				}
			}
		}

		if (g_hCvarEnableSquareDetectx_max.BoolValue)
		{
			if (width_x_max == 0.0)
			{
				return;
			}
			else
			{
				if (width_x_max <= position[0])
				{
					if (position[0])
					{
						g_iDetectCount++;
						CheckDetectCountThenIgnite(ent);
					}
				}
			}
		}

		if (g_hCvarEnableSquareDetectx_min.BoolValue)
		{
			if (width_x_min == 0.0)
			{
				return;
			}
			else
			{
				if (position[0] <= width_x_min)
				{
					if (position[0])
					{
						g_iDetectCount++;
						CheckDetectCountThenIgnite(ent);
					}
				}
			}
		}

		if (g_hCvarEnableSquareDetecty_max.BoolValue)
		{
			if (width_y_max == 0.0)
			{
				return;
			}
			else
			{
				if (width_y_max <= position[1])
				{
					if (position[1])
					{
						g_iDetectCount++;
						CheckDetectCountThenIgnite(ent);
					}
				}
			}
		}

		if (g_hCvarEnableSquareDetecty_min.BoolValue)
		{
			if (width_y_min == 0.0)
			{
				return;
			}
			else
			{
				if (position[1] <= width_y_min)
				{
					if (position[1])
					{
						g_iDetectCount++;
						CheckDetectCountThenIgnite(ent);
					}
				}
			}
		}
	}
}

void CheckDetectCountThenIgnite(int entity)
{
	if (g_hCvarEnableCountLimit.BoolValue)
	{
		if (IsDetectCountOverflow() == false)	 // if detect count overflow, return.
		{
			AddBurnedGascanCount();	   // +1 burned gascan count.
			Ignite(entity);			   // do ignition.
			return;					   // retrun to check if there is a detect count overflow.
		}
	}
	else
	{
		if (IsDetectCountOverflow() == false)
		{
			Ignite(entity);
			return;
		}
	}
}

stock void KillPlayer()
{
	float height_min, height_max;

	ParseMapnameAndHeight(height_min, height_max);

	for (int i = 1; i <= MAXPLAYERS; i++)
	{
		if (IsValidPlayer(i) && IsClientInGame(i))
		{
			float position[3];
			GetClientAbsOrigin(i, position);
			if (position[2] <= height_min)
			{
				ForcePlayerSuicide(i);
			}
		}
	}
}

void ParseMapnameAndHeight(float height_min, float height_max)
{
	KvRewind(kv);
	if (KvJumpToKey(kv, g_sMapName))
	{
		KvGetFloat(kv, "height_zlimit_min", height_min);
		KvGetFloat(kv, "height_zlimit_max", height_max);
		if (g_hCvarEnableDebug.BoolValue)
		{
			PrintToConsoleAll("--------------------------\nparsed mapname and value.\n mapname = %s\n height_min = %s\n height_max = %s", g_sMapName, height_min, height_max);
		}
	}
	else
	{
		return;
	}
}

void ParseMapnameAndWidthMax(float width_x_max, float width_y_max)
{
	KvRewind(kv);
	if (KvJumpToKey(kv, g_sMapName))
	{
		KvGetFloat(kv, "width_xlimit_max", width_x_max);
		KvGetFloat(kv, "width_ylimit_max", width_y_max);
		if (g_hCvarEnableDebug.BoolValue)
		{
			PrintToConsoleAll("\nparsed mapname and value.\n mapname = %s\n width_x_max = %s\n width_y_max = %s", g_sMapName, width_x_max, width_y_max);
		}
	}
	else
	{
		return;
	}
}

void ParseMapnameAndWidthMin(float width_x_min, float width_y_min)
{
	KvRewind(kv);
	if (KvJumpToKey(kv, g_sMapName))
	{
		KvGetFloat(kv, "width_xlimit_min", width_x_min);
		KvGetFloat(kv, "width_ylimit_min", width_y_min);
		if (g_hCvarEnableDebug.BoolValue)
		{
			PrintToConsoleAll("\nparsed mapname and value.\n mapname = %s\n width_x_max = %s\n width_y_max = %s\n --------------------------", g_sMapName, width_x_min, width_y_min);
		}
	}
	else
	{
		return;
	}
}

Action Ignite(int entity)
{
	AcceptEntityInput(entity, "ignite");
	if (g_hCvarEnableCountLimit.BoolValue)
	{
		CPrintToChatAll("%t", "IgniteInLimit", g_iBurnedGascanCount, g_hCvarBurnedGascanMaxLimit.IntValue);
		if (g_iBurnedGascanCount == g_hCvarBurnedGascanMaxLimit.IntValue)
		{
			CPrintToChatAll("%t", "ReachedLimit");
		}
	}
	else
	{
		CPrintToChatAll("%t", "Ignite");
	}

	return Plugin_Handled;
}

stock int AddBurnedGascanCount()
{
	return g_iBurnedGascanCount++;
}

stock bool IsReachedLimit()
{
	if (g_iBurnedGascanCount < g_hCvarBurnedGascanMaxLimit.IntValue)
		return false;
	else
		return true;
}

stock bool IsDetectCountOverflow()
{
	if (g_iDetectCount >= 2)
		return true;
	else
		return false;
}

static bool IsValidPlayer(int client)
{
	if (0 < client <= MaxClients)
		return true;
	else
		return false;
}

stock bool IsScavengeMode()
{
	char sGameMode[32];
	GetConVarString(g_hCvarGameMode, sGameMode, sizeof(sGameMode));
	if (StrContains(sGameMode, "scavenge") > -1)
		return true;
	else
		return false;
}
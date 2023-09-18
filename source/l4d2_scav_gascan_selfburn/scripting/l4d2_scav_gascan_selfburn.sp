/* Change log:
 * - 2.7: 9/18/23
 *	- Reconstructed codes.
 *   - Remove player auto suicide.
 *   - Change event "scavenge_round_start" to "round_start"
 *   - Fixed a bug the gascan don't get burned.
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
 *	- Made the ConVar EnableKillPlayer control the g_hTimerK instead of controlling the function KillPlayer() itself.
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

#define DEBUG		   0

KeyValues
	kv = null;

ConVar
	g_hcvarEnablePlugin,

	g_hcvarEnableSquareDetectx,
	g_hcvarEnableSquareDetecty,
	g_hcvarEnableHeightDetectz,

	g_hcvarEnableCountLimit,
	g_hcvarIntervalBurnGascan,
	g_hcvarBurnedGascanMaxLimit;

int
	g_iBurnedGascanCount = 0,
	g_iDetectCount		 = 0;

enum struct CoordinateInfo
{
	float z_min;
	float z_max;

	float x_min;
	float x_max;

	float y_min;
	float y_max;
}

CoordinateInfo g_esInfo;

public Plugin myinfo =
{
	name		= "[L4D2] Scavenge Gascan Self Burn",
	author		= "Ratchet, blueblur",
	description = "Burn unreachable gascans with custom settings in scavenge mode.",
	version		= PLUGIN_VERSION,
	url			= "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
	char sBuffer[128];

	// ConVars
	g_hcvarEnablePlugin			= CreateConVar("l4d2_scav_gascan_selfburn_enable", "1", "Enable Plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	g_hcvarEnableSquareDetectx	= CreateConVar("l4d2_scav_gascan_selfburn_detect_x", "1", "Enable square coordinate detection(detect x)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hcvarEnableSquareDetecty	= CreateConVar("l4d2_scav_gascan_selfburn_detect_y", "1", "Enable square coordinate detection(detect y)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hcvarEnableHeightDetectz	= CreateConVar("l4d2_scav_gascan_selfburn_detect_z", "1", "Enable height coordinate detection(detect z)", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	g_hcvarEnableCountLimit		= CreateConVar("l4d2_scav_gascan_burned_limit_enable", "1", "Enable Limited Gascan burn", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hcvarIntervalBurnGascan	= CreateConVar("l4d2_scav_gascan_selfburn_interval", "10.0", "Interval every gascan detection dose", FCVAR_NOTIFY, true, 0.0);
	g_hcvarBurnedGascanMaxLimit = CreateConVar("l4d2_scav_gascan_burned_limit", "4", "Limits the max gascan can get burned if they are out of bounds.", FCVAR_NOTIFY, true, 0.0);

	// KeyValue
	kv							= new KeyValues("Positions");
	BuildPath(Path_SM, sBuffer, 128, CONFIG_PATH);
	if (!kv.ImportFromFile(sBuffer))
	{
		SetFailState("File %s may be missed!", CONFIG_PATH);
	}

	// Hooks
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("scavenge_round_finished", Event_ScavRoundFinished, EventHookMode_PostNoCopy);

	// Translations
	LoadTranslations("l4d2_scav_gascan_selfburn.phrases");

	// Check scavenge mode and enable status
	CheckStatus();
}

public Action CheckStatus()
{
	return (!g_hcvarEnablePlugin.BoolValue || !IsScavengeMode()) ? Plugin_Handled : Plugin_Continue;
}

public void OnMapStart()
{
	char sMapName[128];
	GetCurrentMap(sMapName, sizeof(sMapName));

	CreateTimer(g_hcvarIntervalBurnGascan.FloatValue, Timer_DetectGascan, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	kv.Rewind();
	ParseMapCoordinateInfo(g_esInfo, sMapName);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iBurnedGascanCount = 0;
	g_iDetectCount		 = 0;
}

public void Event_ScavRoundFinished(Event event, const char[] name, bool dontBroadcast)
{
	g_iBurnedGascanCount = 0;
}

Action Timer_DetectGascan(Handle Timer)
{
#if DEBUG
	PrintToConsoleAll("Timer started.");
#endif
	FindMisplacedCans();
	return Plugin_Handled;
}

void FindMisplacedCans()
{
	int ent = -1;

	while ((ent = FindEntityByClassname(ent, "weapon_gascan")) != -1)
	{
		if (!IsValidEntity(ent))
			continue;
#if DEBUG
		PrintToConsoleAll("Found entity weapon_gascan: %d", ent);
#endif
		if (g_hcvarEnableCountLimit.BoolValue && IsReachedLimit())
			break;	  // burned gascan has reached its max limit we set, stop the loop (stop igniting the gascan).

		float fPosition[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", fPosition);

		g_iDetectCount = 0;

		if (g_hcvarEnableHeightDetectz.BoolValue)
		{
			if (g_esInfo.z_min == 0.0 || g_esInfo.z_max == 0.0) return;
			else if (fPosition[2] <= g_esInfo.z_min)
			{
				if (fPosition[2])	 // if you dont have this gascan will ignite if you grab it.
				{
					g_iDetectCount++;
					CheckDetectCountThenIgnite(ent);
				}
			}

			if (g_esInfo.z_max <= fPosition[2])
			{
				if (fPosition[2])
				{
					g_iDetectCount++;
					CheckDetectCountThenIgnite(ent);
				}
			}
		}

		if (g_hcvarEnableSquareDetectx.BoolValue)
		{
			if (g_esInfo.x_max == 0.0 || g_esInfo.x_min == 0.0) return;
			else if (g_esInfo.x_max <= fPosition[0])
			{
				if (fPosition[0])
				{
					g_iDetectCount++;
					CheckDetectCountThenIgnite(ent);
				}
			}

			if (fPosition[0] <= g_esInfo.x_min)
			{
				if (fPosition[0])
				{
					g_iDetectCount++;
					CheckDetectCountThenIgnite(ent);
				}
			}
		}

		if (g_hcvarEnableSquareDetecty.BoolValue)
		{
			if (g_esInfo.y_max == 0.0 || g_esInfo.y_min == 0.0) return;
			else if (g_esInfo.y_max <= fPosition[1])
			{
				if (fPosition[1])
				{
					g_iDetectCount++;
					CheckDetectCountThenIgnite(ent);
				}
			}

			if (fPosition[1] <= g_esInfo.y_min && fPosition[1])
			{
				if (fPosition[1])
				{
					g_iDetectCount++;
					CheckDetectCountThenIgnite(ent);
				}
			}
		}
	}
}

void CheckDetectCountThenIgnite(int entity)
{
#if DEBUG
	PrintToConsoleAll("Out bound gascan found: %d", entity);
#endif
	if (g_hcvarEnableCountLimit.BoolValue)
	{
		if (!IsDetectCountOverflow())
		{
			g_iBurnedGascanCount++;
			Ignite(entity);
		}
	}
	else
	{
		if (!IsDetectCountOverflow())
		{
			Ignite(entity);
		}
	}
}

Action Ignite(int entity)
{
	AcceptEntityInput(entity, "ignite");
	if (g_hcvarEnableCountLimit.BoolValue)
	{
		CPrintToChatAll("%t", "IgniteInLimit", g_iBurnedGascanCount, g_hcvarBurnedGascanMaxLimit.IntValue);
		if (g_iBurnedGascanCount == g_hcvarBurnedGascanMaxLimit.IntValue)
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

void ParseMapCoordinateInfo(CoordinateInfo esInfo, char[] sMapName)
{
	if (kv.JumpToKey(sMapName))
	{
		esInfo.z_min = kv.GetFloat("height_zlimit_min", 0.0);
		esInfo.z_max = kv.GetFloat("height_zlimit_max", 0.0);

		esInfo.x_max = kv.GetFloat("width_xlimit_max", 0.0);
		esInfo.x_min = kv.GetFloat("width_xlimit_min", 0.0);

		esInfo.y_max = kv.GetFloat("width_ylimit_max", 0.0);
		esInfo.y_min = kv.GetFloat("width_ylimit_min", 0.0);
	}
	else
		LogError("Invalid map name! Current map name dose not match the map name stored in the config!");

#if DEBUG
	PrintToServer("Successfully parsed info.");
	PrintToServer("--------------- Parsed mapname %s and coordinates. ---------------", sMapName);
	PrintToServer("z_max = %f\nz_min = %f", esInfo.z_max, esInfo.z_min);
	PrintToServer("x_max = %f\nx_min = %f", esInfo.x_max, esInfo.x_min);
	PrintToServer("y_max = %f\ny_min = %f", esInfo.y_max, esInfo.y_min);
	PrintToServer("------------------------------------------------------------------");
#endif
}

stock bool IsReachedLimit()
{
	return (g_iBurnedGascanCount >= g_hcvarBurnedGascanMaxLimit.IntValue) ? true : false;
}

stock bool IsDetectCountOverflow()
{
	return (g_iDetectCount >= 2) ? true : false;
}

stock bool IsScavengeMode()
{
	char   sGameMode[32];
	ConVar hcvarGameMode = FindConVar("mp_gamemode");
	hcvarGameMode.GetString(sGameMode, sizeof(sGameMode));

	return (strcmp(sGameMode, "scavenge") == 0 ? true : false);
}
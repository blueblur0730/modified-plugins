/* Change log:
 * 
 * - 2.8: 12/23/23
 *  - optimized the logic of detect count and Kv.
 *  - optimized varibles' name and code format.
 *  - added cvar change hook.
 *  - removed plugin enable cvar
 *  - removed event hook "scavenge_round_end"
 *  - added cvar "plugin version"
 * 
 * - 2.7.1: 9/26/23
 *  - Fixed a bug on comparing two float coordinates.
 *  - Sperated cvars.
 *  - Enable status adjusted.
 *
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

#define PLUGIN_VERSION "2.8"
#define CONFIG_PATH	"configs/l4d2_scav_gascan_selfburn.txt"

#define DEBUG 0
#define MAX_EDICTS 2048

ConVar
	g_hcvarEnablexMin,
	g_hcvarEnablexMax,
	g_hcvarEnableyMin,
	g_hcvarEnableyMax,
	g_hcvarEnablezMin,
	g_hcvarEnablezMax,
	g_hcvarEnableLimit,
	g_hcvarBurnInterval,
	g_hcvarBurnLimit;

bool
	g_bEnablexMin,
	g_bEnablexMax,
	g_bEnableyMin,
	g_bEnableyMax,
	g_bEnablezMin,
	g_bEnablezMax,
	g_bEnableLimit;

float
	g_fBurnInterval;

int
	g_iBurnLimit;

int
	g_iBurnedCount = 0,
	g_iEntDetectCount[MAX_EDICTS] = { -1, ... };

char
	g_sPath[128];

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
	name = "[L4D2] Scavenge Gascan Self Burn",
	author = "Ratchet, blueblur",
	description = "Burn unreachable gascans with custom settings in scavenge mode.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
	CreateConVar("l4d2_scav_gascan_selfburn_version", PLUGIN_VERSION, "Plgin version", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	g_hcvarEnablexMin = CreateConVar("l4d2_scav_gascan_selfburn_detect_x_min", "1", "Enable square coordinate detection(detect x min)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hcvarEnablexMax = CreateConVar("l4d2_scav_gascan_selfburn_detect_x_max", "1", "Enable square coordinate detection(detect x max)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hcvarEnableyMin = CreateConVar("l4d2_scav_gascan_selfburn_detect_y_min", "1", "Enable square coordinate detection(detect y min)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hcvarEnableyMax = CreateConVar("l4d2_scav_gascan_selfburn_detect_y_max", "1", "Enable square coordinate detection(detect y max)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hcvarEnablezMin = CreateConVar("l4d2_scav_gascan_selfburn_detect_z_min", "1", "Enable height coordinate detection(detect z min)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hcvarEnablezMax = CreateConVar("l4d2_scav_gascan_selfburn_detect_z_max", "1", "Enable height coordinate detection(detect z max)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hcvarEnableLimit = CreateConVar("l4d2_scav_gascan_burned_limit_enable", "1", "Enable Limited Gascan burn", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hcvarBurnInterval = CreateConVar("l4d2_scav_gascan_selfburn_interval", "10.0", "Interval every gascan detection dose", FCVAR_NOTIFY, true, 0.0);
	g_hcvarBurnLimit = CreateConVar("l4d2_scav_gascan_burned_limit", "4", "Limits the max gascan can get burned if they are out of bounds.", FCVAR_NOTIFY, true, 0.0);

	g_hcvarEnablexMin.AddChangeHook(OnCvarChanged);
	g_hcvarEnablexMax.AddChangeHook(OnCvarChanged);
	g_hcvarEnableyMin.AddChangeHook(OnCvarChanged);
	g_hcvarEnableyMax.AddChangeHook(OnCvarChanged);
	g_hcvarEnablezMin.AddChangeHook(OnCvarChanged);
	g_hcvarEnablezMax.AddChangeHook(OnCvarChanged);
	g_hcvarEnableLimit.AddChangeHook(OnCvarChanged);
	g_hcvarBurnInterval.AddChangeHook(OnCvarChanged);
	g_hcvarBurnLimit.AddChangeHook(OnCvarChanged);

	BuildPath(Path_SM, g_sPath, sizeof(g_sPath), CONFIG_PATH);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	LoadTranslations("l4d2_scav_gascan_selfburn.phrases");
}

public void OnCvarChanged(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_bEnablexMin = g_hcvarEnablexMin.BoolValue;
	g_bEnablexMax = g_hcvarEnablexMax.BoolValue;
	g_bEnableyMin = g_hcvarEnableyMin.BoolValue;
	g_bEnableyMax = g_hcvarEnableyMax.BoolValue;
	g_bEnablezMin = g_hcvarEnablezMin.BoolValue;
	g_bEnablezMax = g_hcvarEnablezMax.BoolValue;
	g_bEnableLimit = g_hcvarEnableLimit.BoolValue;
	g_fBurnInterval = g_hcvarBurnInterval.FloatValue;
	g_iBurnLimit = g_hcvarBurnLimit.IntValue;
}

public void OnMapStart()
{
	if (!IsScavengeMode())
		return;

	char sMapName[128];
	GetCurrentMap(sMapName, sizeof(sMapName));
	ParseMapCoordinateInfo(sMapName);
	CreateTimer(g_fBurnInterval, Timer_DetectGascan, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_RoundStart(Event hEvent, const char[] sName, bool dontBroadcast)
{
	g_iBurnedCount = 0;
}

Action Timer_DetectGascan(Handle hTimer)
{
#if DEBUG
	PrintToServer("Timer started.");
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
		PrintToServer("Found entity weapon_gascan: %d", ent);
#endif
		if (IsReachedLimit())
			break;	  // burned gascan has reached its max limit we set, stop the loop (stop igniting the gascan).

		float fPosition[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", fPosition);

		if (g_bEnablezMin)
		{
			if (FloatCompare(g_esInfo.z_min, 0.0) == 0)
				continue;

			if (fPosition[2] <= g_esInfo.z_min)
			{
				if (fPosition[2])	 // if you dont have this gascan will ignite if you grab it.
				{
					g_iEntDetectCount[ent]++;
					CheckDetectCountThenIgnite(ent);
				}
			}
		}

		if (g_bEnablezMax)
		{
			if (FloatCompare(g_esInfo.z_max, 0.0) == 0)
				continue;

			if (g_esInfo.z_max <= fPosition[2])
			{
				if (fPosition[2])
				{
					g_iEntDetectCount[ent]++;
					CheckDetectCountThenIgnite(ent);
				}
			}
		}

		if (g_bEnablexMin)
		{
			if (FloatCompare(g_esInfo.x_min, 0.0) == 0)
				continue;

			if (g_esInfo.x_max <= fPosition[0])
			{
				if (fPosition[0])
				{
					g_iEntDetectCount[ent]++;
					CheckDetectCountThenIgnite(ent);
				}
			}
		}

		if (g_bEnablexMax)
		{
			if (FloatCompare(g_esInfo.x_max, 0.0) == 0)
				continue;

			if (fPosition[0] <= g_esInfo.x_max)
			{
				if (fPosition[0])
				{
					g_iEntDetectCount[ent]++;
					CheckDetectCountThenIgnite(ent);
				}
			}
		}

		if (g_bEnableyMin)
		{
			if (FloatCompare(g_esInfo.y_min, 0.0) == 0)
				continue;

			if (g_esInfo.y_min <= fPosition[1])
			{
				if (fPosition[1])
				{
					g_iEntDetectCount[ent]++;
					CheckDetectCountThenIgnite(ent);
				}
			}
		}

		if (g_bEnableyMax)
		{
			if (FloatCompare(g_esInfo.y_max, 0.0) == 0)
				continue;

			if (fPosition[1] <= g_esInfo.y_max)
			{
				if (fPosition[1])
				{
					g_iEntDetectCount[ent]++;
					CheckDetectCountThenIgnite(ent);
				}
			}
		}
	}
}

void CheckDetectCountThenIgnite(int entity)
{
#if DEBUG
	PrintToServer("Out bound gascan found: %d", entity);
#endif

	if (!IsDetectCountOverflow(entity))
		Ignite(entity);
}

Action Ignite(int entity)
{
	if (g_bEnableLimit)
	{
		if (g_iBurnedCount == g_iBurnLimit)
		{
			CPrintToChatAll("%t", "ReachedLimit");
			return Plugin_Handled;
		}

		CPrintToChatAll("%t", "IgniteInLimit", g_iBurnedCount, g_iBurnLimit);
	}
	else
		CPrintToChatAll("%t", "Ignite");

	AcceptEntityInput(entity, "ignite");

	if (g_bEnableLimit)
		g_iBurnedCount++;

	return Plugin_Handled;
}

void ParseMapCoordinateInfo(char[] sMapName)
{
	KeyValues Kv = new KeyValues("Positions");
	Kv.SetEscapeSequences(true);

	if (!Kv.ImportFromFile(g_sPath))
		SetFailState("File %s may be missed!", CONFIG_PATH);

	if (Kv.JumpToKey(sMapName) && Kv.GotoFirstSubKey(false))
	{
		g_esInfo.z_min = Kv.GetFloat("height_zlimit_min", 0.0);
		g_esInfo.z_max = Kv.GetFloat("height_zlimit_max", 0.0);

		g_esInfo.x_max = Kv.GetFloat("width_xlimit_max", 0.0);
		g_esInfo.x_min = Kv.GetFloat("width_xlimit_min", 0.0);

		g_esInfo.y_max = Kv.GetFloat("width_ylimit_max", 0.0);
		g_esInfo.y_min = Kv.GetFloat("width_ylimit_min", 0.0);
	}
	else
		LogError("Invalid map name! Current map name dose not match the map name stored in the config!");

#if DEBUG
	PrintToServer("Successfully parsed info.");
	PrintToServer("--------------- Parsed mapname %s and coordinates. ---------------", sMapName);
	PrintToServer("z_max = %f\nz_min = %f", g_esInfo.z_max, g_esInfo.z_min);
	PrintToServer("x_max = %f\nx_min = %f", g_esInfo.x_max, g_esInfo.x_min);
	PrintToServer("y_max = %f\ny_min = %f", g_esInfo.y_max, g_esInfo.y_min);
	PrintToServer("------------------------------------------------------------------");
#endif

	delete Kv;
}

stock bool IsReachedLimit()
{
	if (g_bEnableLimit)
		return (g_iBurnedCount >= g_iBurnLimit) ? true : false;

	return false;
}

stock bool IsDetectCountOverflow(int entity)
{
	return (g_iEntDetectCount[entity] >= 2) ? true : false;
}

stock bool IsScavengeMode()
{
	char sGameMode[32];
	ConVar hcvarGameMode = FindConVar("mp_gamemode");
	hcvarGameMode.GetString(sGameMode, sizeof(sGameMode));

	return (strcmp(sGameMode, "scavenge") == 0 ? true : false);
}
<<<<<<< HEAD
/* Change log:
 * - 2.8.1
 *  - optimized logic and codes.
 * 
 * - 2.8
 *  - Fixed some issues in 2.7.1 the gascans dont get burned.
 *  - Optimized logic and codes, added or changed or deleted some varibles and function.
 *    - g_iDetectCount is now more compatible to every gascans.
 * 
 * - 2.7.1
 *  - Fixed an issue the float value didnt retrive correctly and gascan didnt get burned, changed coordinate varibles to global.
 * 
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

=======
>>>>>>> parent of 29cefac (update l4d2_scav_gascan_selfburn 2.7)
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
//#include <left4dhooks>
#include <colors>

<<<<<<< HEAD
#define PLUGIN_VERSION "2.8.1"
#define CONFIG_PATH	   "configs/l4d2_scav_gascan_selfburn.txt"
#define MAXENTITY 		2048
=======
#define PLUGIN_VERSION "2.6.4"
#define CONFIG_PATH "configs/l4d2_scav_gascan_selfburn.txt"
/* Change log:
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
>>>>>>> parent of 29cefac (update l4d2_scav_gascan_selfburn 2.7)

//Timer
Handle
	TimerG = INVALID_HANDLE,
	TimerK = INVALID_HANDLE;

KeyValues
	kv;

ConVar
<<<<<<< HEAD
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
	g_hCvarBurnedGascanMaxLimit;
=======
	EnableSelfBurn,
	EnableSquareDetectx,
	EnableSquareDetecty,
	EnableHeightDetectz,
	EnableDebug,
	EnableKillPlayer,
	EnableCountLimit,
	IntervalBurnGascan,
	IntervalKillPlayer,
	BurnedGascanMaxLimit,
	cvarGameMode;
>>>>>>> parent of 29cefac (update l4d2_scav_gascan_selfburn 2.7)

char
	c_mapname[128];

int
<<<<<<< HEAD
	g_iBurnedGascanCount,
	g_iDetectCount[MAXENTITY];

float
	g_fheight_min, g_fheight_max,
	g_fwidth_x_min, g_fwidth_y_min,
	g_fwidth_x_max, g_fwidth_y_max;

public Plugin myinfo =
{
	name 		= "[L4D2] Scavenge Gascan Self Burn",
	author 		= "Ratchet, blueblur",
=======
	BurnedGascanCount,
	DetectCount,
	ent;

public Plugin myinfo =
{
	name = "L4D2 Scavenge Gascan Self Burn",
	author = "Ratchet, blueblur",
>>>>>>> parent of 29cefac (update l4d2_scav_gascan_selfburn 2.7)
	description = "A plugin that able to configurate the position where the gascan will get burned once they were out of boundray in L4D2 scavenge mode. (And force player to die in impossible places.)",
	version = PLUGIN_VERSION,
	url = "https://github.com/blueblur0730/modified-plugins"
};

public void OnPluginStart()
{
	char buffer[128];

	// ConVars
<<<<<<< HEAD
	g_hCvarEnableSelfBurn		   = CreateConVar("l4d2_scav_gascan_selfburn_enable", "1", "Enable Plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	/******************************/
	g_hCvarEnableSquareDetectx_max = CreateConVar("l4d2_scav_gascan_selfburn_detect_x_max", "1", "Enable square coordinate detection(detect x max)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarEnableSquareDetectx_min = CreateConVar("l4d2_scav_gascan_selfburn_detect_x_min", "1", "Enable square coordinate detection(detect x min)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarEnableSquareDetecty_max = CreateConVar("l4d2_scav_gascan_selfburn_detect_y_max", "1", "Enable square coordinate detection(detect y max)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarEnableSquareDetecty_min = CreateConVar("l4d2_scav_gascan_selfburn_detect_y_min", "1", "Enable square coordinate detection(detect y min)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarEnableHeightDetectz_max = CreateConVar("l4d2_scav_gascan_selfburn_detect_z_max", "1", "Enable height coordinate detection(detect z max)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarEnableHeightDetectz_min = CreateConVar("l4d2_scav_gascan_selfburn_detect_z_min", "1", "Enable height coordinate detection(detect z min)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	/******************************/
	g_hCvarEnableDebug			   = CreateConVar("l4d2_scav_gascan_selfburn_debug", "0", "Enable Debug", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarEnableKillPlayer		   = CreateConVar("l4d2_scav_kill_player", "0", "Enable Kill Player", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarEnableCountLimit		   = CreateConVar("l4d2_scav_gascan_burned_limit_enable", "1", "Enable Limited Gascan burn", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	/******************************/
	g_hCvarIntervalBurnGascan	   = CreateConVar("l4d2_scav_gascan_selfburn_interval", "10.0", "Interval every gascan detection dose", FCVAR_NOTIFY, true, 0.0);
	g_hCvarIntervalKillPlayer	   = CreateConVar("l4d2_scav_kill_player_interval", "3.0", "Interval every kill_player detection dose", FCVAR_NOTIFY, true, 0.0);
	g_hCvarBurnedGascanMaxLimit	   = CreateConVar("l4d2_scav_gascan_burned_limit", "4", "Limits the max gascan can get burned if they are out of bounds.", FCVAR_NOTIFY, true, 0.0);
	/******************************/
=======
	EnableSelfBurn 			= 	CreateConVar("l4d2_scav_gascan_selfburn_enable", "1", "Enable Plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	EnableSquareDetectx 	= 	CreateConVar("l4d2_scav_gascan_selfburn_detect_x", "1", "Enable square coordinate detection(detect x)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	EnableSquareDetecty 	=   CreateConVar("l4d2_scav_gascan_selfburn_detect_y", "1", "Enable square coordinate detection(detect y)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	EnableHeightDetectz 	=	CreateConVar("l4d2_scav_gascan_selfburn_detect_z", "1", "Enable height coordinate detection(detect z)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	EnableDebug 			= 	CreateConVar("l4d2_scav_gascan_selfburn_debug", "0", "Enable Debug", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	EnableKillPlayer    	= 	CreateConVar("l4d2_scav_kill_player", "0", "Enable Kill Player", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	EnableCountLimit		=	CreateConVar("l4d2_scav_gascan_burned_limit_enable", "1", "Enable Limited Gascan burn",FCVAR_NOTIFY, true, 0.0, true, 1.0);

	IntervalBurnGascan  	= 	CreateConVar("l4d2_scav_gascan_selfburn_interval", "10.0", "Interval every gascan detection dose", FCVAR_NOTIFY, true, 0.0);
	IntervalKillPlayer  	= 	CreateConVar("l4d2_scav_kill_player_interval", "3.0", "Interval every kill_player detection dose", FCVAR_NOTIFY, true, 0.0);

	BurnedGascanMaxLimit	=	CreateConVar("l4d2_scav_gascan_burned_limit", "4", "Limits the max gascan can get burned if they are out of bounds.", FCVAR_NOTIFY, true, 0.0);

	cvarGameMode 			= 	FindConVar("mp_gamemode");
>>>>>>> parent of 29cefac (update l4d2_scav_gascan_selfburn 2.7)

	// KeyValue
	kv = CreateKeyValues("Positions", "", "");
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
	if(!GetConVarBool(EnableSelfBurn) || !IsScavengeMode())
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

<<<<<<< HEAD
	g_iBurnedGascanCount = 0;

	ParseMapnameAndHeight(g_fheight_min, g_fheight_max);
	ParseMapnameAndWidthMax(g_fwidth_x_max, g_fwidth_y_max);
	ParseMapnameAndWidthMin(g_fwidth_x_min, g_fwidth_y_min);
=======
	BurnedGascanCount = 0;
}

public void OnMapEnd()
{
	BurnedGascanCount = 0;
>>>>>>> parent of 29cefac (update l4d2_scav_gascan_selfburn 2.7)
}

public Action Event_ScavRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	BurnedGascanCount = 0;
	return Plugin_Continue;
	// if the reason of round ending is that the last survivor was holding the gascan and died out-bound,
	// the gascan will ignite and the count will pass to the next round. we should reset the count on round start.
}

public Action Event_ScavRoundFinished(Event event, const char[] name, bool dontBroadcast)
{
	BurnedGascanCount = 0;
	return Plugin_Continue;
}

Action GascanDetectTimer(Handle Timer, any Client)
{
	FindMisplacedCans();
	return Plugin_Handled;
}

Action KillPlayerTimer(Handle Timer, any Client)
{
	KillPlayer();
	return Plugin_Handled;
}

stock void FindMisplacedCans()
{
<<<<<<< HEAD
	int iEntityGascan = -1;

	while ((iEntityGascan = FindEntityByClassname(iEntityGascan, "weapon_gascan")) != -1)
	{
		if (!IsValidEntity(iEntityGascan))
			continue;

		if (g_hCvarEnableCountLimit.BoolValue && IsReachedLimit() == true)
			break;	  // burned gascan has reached its max limit we set, stop the loop.

		float fPosition[3];
		g_iDetectCount[iEntityGascan] = 0;		// initialize the detect count in every loop.
		GetEntPropVector(iEntityGascan, Prop_Send, "m_vecOrigin", fPosition);

		/*
		 * if gascan reached a place that is lower than the coordinate the g_fheight_min given on z axie, ignite gascan.
		 * if gascan reached a place that is higher than the coordinate the g_fheight_max given on z axie, ignite gascan.
		 * if gascan reached a place that its coordinate is smaller than the coordinate g_fwidth_x_min given on x axie, ignite gascan.
		 * if gascan reached a place that its coordinate is smaller than the coordinate g_fwidth_y_min given on y axie, ignite gascan.
		 * if gascan reached a place that its coordinate is bigger than the coordinate g_fwidth_x_max given on x axie, ignite gascan.
		 * if gascan reached a place that its coordinate is bigger than the coordinate g_fwidth_y_max given on y axie, ignite gascan.
		 *
		 * In summary, gascan will get burned if it has ran out of the cube boundray you defined on every specific map.
		 */
=======
	ent = -1;
	char g_height_min[128], g_height_max[128];
	char g_width_x_min[128], g_width_y_min[128];
	char g_width_x_max[128], g_width_y_max[128];

	ParseMapnameAndHeight(g_height_min, g_height_max, sizeof(g_height_min), sizeof(g_height_max));
	ParseMapnameAndWidthMax(g_width_x_max, g_width_y_max, sizeof(g_width_x_max), sizeof(g_width_y_max));
	ParseMapnameAndWidthMin(g_width_x_min, g_width_y_min, sizeof(g_width_x_min), sizeof(g_width_y_min));

	while ((ent = FindEntityByClassname(ent, "weapon_gascan")) != -1)
	{
		if (!IsValidEntity(ent))
			continue;		// the entity is not a gascan, continue next loop

		if(GetConVarBool(EnableCountLimit) && IsReachedLimit() == true)
			break;		// burned gascan has reached its max limit we set, stop the loop (stop igniting the gascan).

		float position[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", position);

		DetectCount = 0;

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
>>>>>>> parent of 29cefac (update l4d2_scav_gascan_selfburn 2.7)

		if(GetConVarBool(EnableHeightDetectz))
		{
<<<<<<< HEAD
			if (g_fheight_max != 0.0 && g_fheight_max <= fPosition[2])
			{
				if (fPosition[2])	// Has gascan not hold by survivor? or has gascan become static?
				{
					if (IsDetectCountOverflow(iEntityGascan))
					{
						g_iDetectCount[iEntityGascan]++;		// +1 detect count
						CheckDetectCountThenIgnite(iEntityGascan);
					}
					else
					{
						continue;
=======
			if(strlen(g_height_min) == 0 || strlen(g_height_max) == 0)
			{
				return;
			}
			else
			{
				if(position[2] <= StringToFloat(g_height_min))
				{
					if(position[2])			// Has gascan not hold by survivor? or has gascan become static?
					{
						DetectCount++;		// +1 detect count
						CheckDetectCountThenIgnite();
					}
				}

				if(StringToFloat(g_height_max) <= position[2])
				{
					if(position[2])
					{
						DetectCount++;
						CheckDetectCountThenIgnite();
					}
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
					{
						DetectCount++;
						CheckDetectCountThenIgnite();
					}
				}

				if(position[0] <= StringToFloat(g_width_x_min))
				{
					if(position[0])
					{
						DetectCount++;
						CheckDetectCountThenIgnite();
>>>>>>> parent of 29cefac (update l4d2_scav_gascan_selfburn 2.7)
					}
				}
			}
		}

		if(GetConVarBool(EnableSquareDetecty))
		{
<<<<<<< HEAD
			if (g_fheight_min != 0.0 && fPosition[2] <= g_fheight_min)
			{
				if (fPosition[2])
				{
					if (IsDetectCountOverflow(iEntityGascan))
					{
						g_iDetectCount[iEntityGascan]++;
						CheckDetectCountThenIgnite(iEntityGascan);
					}
					else
					{
						continue;
=======
			if(strlen(g_width_y_max) == 0 || strlen(g_width_y_min) == 0)
			{
				return;
			}
			else
			{
				if(StringToFloat(g_width_y_max) <= position[1])
				{
					if(position[1])
					{
						DetectCount++;
						CheckDetectCountThenIgnite();
>>>>>>> parent of 29cefac (update l4d2_scav_gascan_selfburn 2.7)
					}
				}

<<<<<<< HEAD
		if (g_hCvarEnableSquareDetectx_max.BoolValue)
		{
			if (g_fwidth_x_max != 0.0 && g_fwidth_x_max <= fPosition[0])
			{
				if (fPosition[0])
				{
					if (IsDetectCountOverflow(iEntityGascan))
					{
						g_iDetectCount[iEntityGascan]++;
						CheckDetectCountThenIgnite(iEntityGascan);
					}
					else
					{
						continue;
					}
				}
			}
		}

		if (g_hCvarEnableSquareDetectx_min.BoolValue)
		{
			if (g_fwidth_x_min != 0.0 && fPosition[0] <= g_fwidth_x_min)
			{
				if (fPosition[0])
				{
					if (IsDetectCountOverflow(iEntityGascan))
					{
						g_iDetectCount[iEntityGascan]++;
						CheckDetectCountThenIgnite(iEntityGascan);
					}
					else
					{
						continue;
					}
				}
			}
		}

		if (g_hCvarEnableSquareDetecty_max.BoolValue)
		{
			if (g_fwidth_y_max != 0.0 && g_fwidth_y_max <= fPosition[1])
			{
				if (fPosition[1])
				{
					if (IsDetectCountOverflow(iEntityGascan))
					{
						g_iDetectCount[iEntityGascan]++;
						CheckDetectCountThenIgnite(iEntityGascan);
					}
					else
					{
						continue;
					}
				}
			}
		}

		if (g_hCvarEnableSquareDetecty_min.BoolValue)
		{
			if (g_fwidth_y_min != 0.0 && fPosition[1] <= g_fwidth_y_min)
			{
				if (fPosition[1])
				{
					if (IsDetectCountOverflow(iEntityGascan))
					{
						g_iDetectCount[iEntityGascan]++;
						CheckDetectCountThenIgnite(iEntityGascan);
					}
					else
					{
						continue;
=======
				if(position[1] <= StringToFloat(g_width_y_min))
				{	
					if(position[1])
					{
						DetectCount++;
						CheckDetectCountThenIgnite();
>>>>>>> parent of 29cefac (update l4d2_scav_gascan_selfburn 2.7)
					}
				}
			}
		}
	}
}

<<<<<<< HEAD
void CheckDetectCountThenIgnite(int ent)
{
	Ignite(ent);

	if (g_hCvarEnableCountLimit.BoolValue)
	{
		g_iBurnedGascanCount++;	   // +1 burned gascan count.
=======
void CheckDetectCountThenIgnite()
{
	if(GetConVarBool(EnableCountLimit))
	{
		if(IsDetectCountOverflow() == false)		// if detect count overflow, return.
		{
			AddBurnedGascanCount();					// +1 burned gascan count.
			Ignite(ent);							// do ignition.
			return;									// retrun to check if there is a detect count overflow.
		}
	}
	else
	{
		if(IsDetectCountOverflow() == false)
		{
			Ignite(ent);
			return;
		}
>>>>>>> parent of 29cefac (update l4d2_scav_gascan_selfburn 2.7)
	}

}

stock void KillPlayer()
{
<<<<<<< HEAD
	ParseMapnameAndHeight(g_fheight_min, g_fheight_max);
=======
	char g_height_min[128], g_height_max[128];

	ParseMapnameAndHeight(g_height_min, g_height_max, sizeof(g_height_min), sizeof(g_height_max));
>>>>>>> parent of 29cefac (update l4d2_scav_gascan_selfburn 2.7)

	for (int i = 1; i <= MAXPLAYERS; i++)
	{
		if (IsValidPlayer(i) && IsClientInGame(i))
		{
<<<<<<< HEAD
			float fPosition[3];
			GetClientAbsOrigin(i, fPosition);
			if (fPosition[2] <= g_fheight_min)
=======
			float position[3];
			GetClientAbsOrigin(i, position);
			if(position[2] <= StringToInt(g_height_min))
>>>>>>> parent of 29cefac (update l4d2_scav_gascan_selfburn 2.7)
			{
				ForcePlayerSuicide(i);
			}
		}
	}
}

void ParseMapnameAndHeight(char[] height_min, char[] height_max, int maxlength, int maxlength2)
{
	KvRewind(kv);
	if(KvJumpToKey(kv, c_mapname))
	{
<<<<<<< HEAD
		height_min = KvGetFloat(kv, "height_zlimit_min");
		height_max = KvGetFloat(kv, "height_zlimit_max");
		if (g_hCvarEnableDebug.BoolValue)
		{
			PrintToServer("--------------------------\nparsed mapname and value.\n mapname = %s\n g_fheight_min = %f\n g_fheight_max = %f", g_sMapName, height_min, height_max);
=======
		KvGetString(kv, "height_zlimit_min", height_min, maxlength);
		KvGetString(kv, "height_zlimit_max", height_max, maxlength2);
		if(GetConVarBool(EnableDebug))
		{
			PrintToConsoleAll("--------------------------\nparsed mapname and value.\n mapname = %s\n height_min = %s\n height_max = %s", c_mapname, height_min, height_max);
>>>>>>> parent of 29cefac (update l4d2_scav_gascan_selfburn 2.7)
		}
	}
	else
	{
		return;
	}
}

void ParseMapnameAndWidthMax(char[] width_x_max, char[] width_y_max, int maxlength, int maxlength2)
{
	KvRewind(kv);
	if(KvJumpToKey(kv, c_mapname))
	{
<<<<<<< HEAD
		width_x_max = KvGetFloat(kv, "width_xlimit_max");
		width_y_max = KvGetFloat(kv, "width_ylimit_max");
		if (g_hCvarEnableDebug.BoolValue)
		{
			PrintToServer("\nparsed mapname and value.\n mapname = %s\n g_fwidth_x_max = %f\n g_fwidth_y_max = %f", g_sMapName, width_x_max, width_y_max);
=======
		KvGetString(kv, "width_xlimit_max", width_x_max, maxlength);
		KvGetString(kv, "width_ylimit_max", width_y_max, maxlength2);
		if(GetConVarBool(EnableDebug))
		{
			PrintToConsoleAll("\nparsed mapname and value.\n mapname = %s\n width_x_max = %s\n width_y_max = %s", c_mapname, width_x_max, width_y_max);
>>>>>>> parent of 29cefac (update l4d2_scav_gascan_selfburn 2.7)
		}
	}
	else
	{
		return;
	}
}

void ParseMapnameAndWidthMin(char[] width_x_min, char[] width_y_min, int maxlength, int maxlength2)
{
	KvRewind(kv);
	if(KvJumpToKey(kv, c_mapname))
	{
<<<<<<< HEAD
		width_x_min = KvGetFloat(kv, "width_xlimit_min");
		width_y_min = KvGetFloat(kv, "width_ylimit_min");
		if (g_hCvarEnableDebug.BoolValue)
		{
			PrintToServer("\nparsed mapname and value.\n mapname = %s\n g_fwidth_x_max = %f\n g_fwidth_y_max = %f\n --------------------------", g_sMapName, width_x_min, width_y_min);
=======
		KvGetString(kv, "width_xlimit_min", width_x_min, maxlength);
		KvGetString(kv, "width_ylimit_min", width_y_min, maxlength2);
		if(GetConVarBool(EnableDebug))
		{
			PrintToConsoleAll("\nparsed mapname and value.\n mapname = %s\n width_x_max = %s\n width_y_max = %s\n --------------------------", c_mapname, width_x_min, width_y_min);
>>>>>>> parent of 29cefac (update l4d2_scav_gascan_selfburn 2.7)
		}
	}
	else
	{
		return;
	}
}

<<<<<<< HEAD
void Ignite(int ent)
{
	AcceptEntityInput(ent, "ignite");
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
=======
stock int AddBurnedGascanCount()
{
	return BurnedGascanCount++;
>>>>>>> parent of 29cefac (update l4d2_scav_gascan_selfburn 2.7)
}

stock bool IsReachedLimit()
{
	if(BurnedGascanCount < GetConVarInt(BurnedGascanMaxLimit))
		return false;
	else
		return true;
}


stock bool IsDetectCountOverflow(int ent)
{
<<<<<<< HEAD
	if (g_iDetectCount[ent] >= 1)
=======
	if(DetectCount >= 2)
>>>>>>> parent of 29cefac (update l4d2_scav_gascan_selfburn 2.7)
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

stock Action Ignite(int entity)
{
	AcceptEntityInput(entity, "ignite");
	if(GetConVarBool(EnableCountLimit))
	{
		CPrintToChatAll("%t", "IgniteInLimit", BurnedGascanCount, GetConVarInt(BurnedGascanMaxLimit));
		if(BurnedGascanCount == GetConVarInt(BurnedGascanMaxLimit))
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

stock bool IsScavengeMode()
{
<<<<<<< HEAD
	char   sCurGameMode[64];
	ConVar hCurGameMode = FindConVar("mp_gamemode");
	hCurGameMode.GetString(sCurGameMode, sizeof(sCurGameMode));
	if (strcmp(sCurGameMode, "scavenge") == 0)
=======
	char sGameMode[32];
	GetConVarString(cvarGameMode, sGameMode, sizeof(sGameMode));
	if (StrContains(sGameMode, "scavenge") > -1)
	{
>>>>>>> parent of 29cefac (update l4d2_scav_gascan_selfburn 2.7)
		return true;
	}
	else
	{
		return false;
	}
}
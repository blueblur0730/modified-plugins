/* *
 * =============================================================================
 * Confogl.inc
 * Confogl (C)2011 Confogl Team
 * =============================================================================
 *
 * This file is part of the Confogl competitive L4D2 plugin suite.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, Confogl Team gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, Confogl Team grants
 * this exception to all derivative works. Confogl defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 */

#if defined _confogl_system_included
	#endinput
#endif
#define _confogl_system_included

enum struct CVSEntry
{
	ConVar CVSE_cvar;
	char CVSE_oldval[64];
	char CVSE_newval[64];
}

/* Forwards */

/**
 * @brief Called when matchmode is fully loaded, before map restart.
 * @remarks Called just before confogl_plugins.cfg executes
 *
 * @param config	Name of the config being loaded.
 * @param maps		Map name that will be loaded to.
 * 
 * @noreturn
 */
forward void LGO_OnMatchModeLoaded(const char[] config, const char[] maps);

/**
 * @brief Called when matchmode is un-loaded, before map restart.
 * @remarks Plugins are unloaded immediately after this call finishes
 *
 * @param config	Name of the config being unloaded.
 * 
 * @noreturn
 */
forward void LGO_OnMatchModeUnloaded(const char[] config);

/**
 * @brief Called when confogl removes lobby reservation.
 * 
 * @noreturn
*/
forward void LGO_OnRemoveLobby();

/* NATIVES */

/**
 * @brief Tells if a confogl match is currently running
 * @remarks Formerly IsPluginEnabled() internally
 *
 * @return 	True if matchmode is loaded, false otherwise
 */
native bool LGO_IsMatchModeLoaded();

/**
 * @brief Get current match name
 * @remarks Same name as the folder name in cfgogl/
 */
native void LGO_GetConfigName(char[] sConfigName, int iSize);

/**
 * @brief Build a filepath relative to the current running config.
 * @remarks Should produce a path in cfg/cfgogl/CONFIG/ or addons/sourcemod/configs/confogl
 *
 * @param buffer	Buffer to write the path to
 * @param maxlength	Buffer size
 * @param sFileName	Name of the file to look for in the config
 * @noreturn
 */
native void LGO_BuildConfigPath(char[] buffer, int maxlength, const char[] sFileName);

/**
 * @brief Execute a cfg file for the current config
 * @remarks Should execute the named .cfg in cfg/ or cfg/cfgogl/CURRENT_CONFIG/
 *
 * @param sFileName	Name of the cfg file to execute
 * @noreturn
 */
native void LGO_ExecuteConfigCfg(const char[] sFileName);

/**
 * @brief Get the list of tracked cvars for the current config.
 * @remarks This arraylist contains a set of enum struct array. See above.
 * 
 * @param hCvarArray	An array to store the cvars in
 * 
 * @return Size of the array. -1 if tracking has not started yet.
*/
native int LGO_GetTrackedCvars(ArrayList &hCvarArray);

public SharedPlugin __pl_confogl_system =
{
	name = "confogl",
	file = "confogl_system.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_confogl_system_SetNTVOptional()
{
	MarkNativeAsOptional("LGO_BuildConfigPath");
	MarkNativeAsOptional("LGO_ExecuteConfigCfg");
	MarkNativeAsOptional("LGO_IsMatchModeLoaded");
	MarkNativeAsOptional("LGO_GetConfigName");
}
#endif

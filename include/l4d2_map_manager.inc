#if defined _l4d2_map_manager_included
    #endinput
#endif
#define _l4d2_map_manager_included

forward void OnNextMapPreserved(const char[] map);

public SharedPlugin __pl_l4d2_map_manager =
{
	name = "l4d2_map_manager",
	file = "l4d2_map_manager.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
#if defined _l4d2_hide_included
	#endinput
#endif
#define _l4d2_hide_included

native int Hide_GetHideRange(int client);
native void Hide_SetHideRange(int client, int range);

public SharedPlugin __pl_l4d2_hide =
{
	name = "l4d2_hide",
	file = "l4d2_hide.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_hide_SetNTVOptional()
{
	MarkNativeAsOptional("Hide_GetHideRange");
	MarkNativeAsOptional("Hide_SetHideRange");
}
#endif
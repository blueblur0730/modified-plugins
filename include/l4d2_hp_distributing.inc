#if defined _l4d2_hp_distributing_included
 #endinput
#endif
#define _l4d2_hp_distributing_included

enum SIType {
	SIType_Smoker = 1,
	SIType_Boomer,
	SIType_Hunter,
	SIType_Spitter,
	SIType_Jockey,
	SIType_Charger,

	SIType_Size	   // 6 size
}

native int GetSIReward(SIType type);

public SharedPlugin __pl_l4d2_hp_distributing =
{
	name = "l4d2_hp_distributing",
	file = "l4d2_hp_distributing.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_hp_distributing_SetNTVOptional()
{
	MarkNativeAsOptional("GetSIReward");
}
#endif
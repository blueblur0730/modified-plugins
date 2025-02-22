#if defined _l4d2_mixmap_included
    #endinput
#endif
#define _l4d2_mixmap_included

enum MapSetType {
	MapSet_None = 0,
	MapSet_Official = 1,
	MapSet_Custom = 2,
	MapSet_Mixtape = 3,
	MapSet_Manual = 4,
	MapSet_Preset = 5
}

/**
 * Called when is about to change to the first map.
 * 
 * @param lenth         The length of the map pool.
 * @param type          The type of the map set. if MapSet_Preset, then the third parameter is the name of the preset.
 * @param sPresetName   The name of the preset.
 * 
 * @noreturn
*/
forward void Mixmap_OnStart(int lenth, MapSetType type, const char[] sPresetName);

/**
 * Called when current map has started, broadcast the next map name.
 * 
 * @param sNexMap       The name of the next map.
 * 
 * @noreturn
*/
forward void Mixmap_OnKnownNext(const char[] sNexMap);

/**
 * Called when mixmap was interrupted and forced to stop.
 * 
 * @noreturn
*/
forward void Mixmap_OnInterrupted();

/**
 * Called when the last map has ended.
 * 
 * @noreturn
*/
forward void Mixmap_OnEnd();

/**
 * Get map pool handle.
 * 
 * @return              The handle of the map pool arraylist.
 * 
 * @error               Mixmap has not started, or caller's plugin handle is invalid.
*/
native ArrayList Mixmap_GetMapPool();

/**
 * Get map pool length.
 * 
 * @return              The length of the map pool.
 * 
 * @error               Mixmap has not started.
*/
native int Mixmap_GetMapCount();

/**
 * Get played map count.
 * 
 * @note                actually play count + 1 on map start, so this usually indicates the next map's index
 * 
 * @return              The index of the current map.
*/
native int Mixmap_GetPlayedMapCount();

/**
 * Has mixmap started?
 * 
 * @return              true if mixmap has started, false otherwise.
*/
native bool Mixmap_HasStarted();

/**
 * Get the current type of the map set.
 * 
 * @return              The type of the map set.
*/
native MapSetType Mixmap_GetMapSetType();

/**
 * Get the name of the preset if using MapSet_Preset.
 * 
 * @param sPresetName   The buffer to store the preset name.
 * @param length        The length of the buffer.
 * 
 * @noreturn
*/
native void Mixmap_GetPresetName(char[] sPresetName, int length);

public SharedPlugin __pl_l4d2_mixmap =
{
	name = "l4d2_mixmap",
	file = "l4d2_mixmap.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_mixmap_SetNTVOptional()
{
	MarkNativeAsOptional("Mixmap_GetMapPool");
	MarkNativeAsOptional("Mixmap_GetMapCount");
	MarkNativeAsOptional("Mixmap_GetPlayedMapCount");
	MarkNativeAsOptional("Mixmap_HasStarted");
    MarkNativeAsOptional("Mixmap_GetMapSetType");
    MarkNativeAsOptional("Mixmap_GetPresetName");
}
#endif
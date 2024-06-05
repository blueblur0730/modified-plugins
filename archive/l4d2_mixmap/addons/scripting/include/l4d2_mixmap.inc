#if defined  _l4d2_mixmap_included_
 #endinput
#endif
#define _l4d2_mixmap_included_

/* 
 * Called right before mixmap loading first map.
 *
 * @param iMapCount      	total selected map count
 * @param sMapName          name of first map
 * 
 **/
forward void OnMixmapStart(int iMapCount, char[] sFirstMapName);

/*
 * Called after mixmap loading a map.
 *
 * @param sNextMapName      next map name
 * 
 **/
forward void OnMixmapNextKnown(char[] sNextMapName);

/*
 * Called when mixmap was interupted
 *
 */
forward void OnMixmapInterrupted()

/*
 * Called after the last map is played.
 *
 */
forward void OnMixmapEnd();

/*
 * Retrieves the map string sequence to an arraylist
 * 
 * @param hArray 			arraylist to store the string sequence
 */
native void GetMixmapMapSequence(ArrayList hArray)

/*
 * Get total map count a mixmap game has played
 * 
 * @return					total played map count
 */
native int GetMixmapPlayedMapCount()

/*
 * If currently we are in mixmap
 *
 * @return					true if we are in mixmap, false otherwise
 */
native bool IsInMixmap()

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
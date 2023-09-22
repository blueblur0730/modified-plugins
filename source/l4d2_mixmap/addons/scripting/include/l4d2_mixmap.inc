#if defined  _l4d2_mixmap_included_
 #endinput
#endif
#define _l4d2_mixmap_included_

/* 
 * Called right before mixmap loading first map.
 *
 * @param iMapListSize      maplist array size
 * @param sMapName          name of first map
 * 
 **/
forward void OnCMTStart(int iMapListSize, char[] sFirstMapName);

/*
 * Called after mixmap loading a map.
 *
 * @param sNextMapName      next map name
 * 
 **/
forward void OnCMTNextKnown(char[] sNextMapName);

/*
 * Called when mixmap was interupted
 *
 */
forward void OnCMTInterrupted()

/*
 * Called after the last map is played.
 *
 */
forward void OnCMTEnd();

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
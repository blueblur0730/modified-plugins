#if defined __confogl_constants_included
	#endinput
#endif
#define __confogl_constants_included

#define TRANSLATION_FILE "confogl_system.phrases"
#define MATCHMODES_PATH	 "configs/matchmodes.txt"
#define TEAM_SPECTATE	 1

enum
{
	L4D2Team_None = 0,
	L4D2Team_Spectator,
	L4D2Team_Survivor,
	L4D2Team_Infected,
	L4D2Team_L4D1_Survivor,	   // Probably for maps that contain survivors from the first part and from part 2

	L4D2Team_Size	 // 5 size
};

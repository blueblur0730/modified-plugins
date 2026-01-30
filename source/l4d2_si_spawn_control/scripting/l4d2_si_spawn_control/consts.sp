#define DEBUG 1

#define	SMOKER	1
#define	BOOMER	2
#define	HUNTER	3
#define	SPITTER	4
#define	JOCKEY	5
#define	CHARGER 6
#define	SI_CLASS_SIZE	7

#define BOT			0
#define PLAYER		1

#define SPAWN_NO_HANDLE 0
#define SPAWN_MAX_PRE	1
#define SPAWN_MAX		2
#define SPAWN_REVIVE	10

#define NEAREST_RANGE_ADD 400.0

stock const char g_sSpecialName[][] = {
	"", 
    "Smoker", 
    "Boomer", 
    "Hunter", 
    "Spitter", 
    "Jockey", 
    "Charger"
};

enum
{
	SpawnMode_Normal			= 0, // L4D_GetRandomPZSpawnPosition + l4d2_si_spawn_control_spawn_range_normal
	SpawnMode_NavAreaNearest	= 1, // GetSpawnPosByNavArea + nearest invisible place
	SpawnMode_NavArea			= 2, // GetSpawnPosByNavArea + l4d2_si_spawn_control_spawn_range_navarea
	SpawnMode_NormalEnhanced	= 3, // SpawnMode_Normal + SpawnMode_NavArea auto switch.
}

enum struct SurPosData
{
	float fFlow;
	float fPos[3];
}

enum struct SpawnData
{
	float fDist;
	float fPos[3];
}

// https://developer.valvesoftware.com/wiki/List_of_L4D_Series_Nav_Mesh_Attributes:zh-cn
#define	TERROR_NAV_NO_NAME1				(1 << 0)
#define	TERROR_NAV_EMPTY				(1 << 1)
#define	TERROR_NAV_STOP_SCAN			(1 << 2)
#define	TERROR_NAV_NO_NAME2				(1 << 3)
#define	TERROR_NAV_NO_NAME3				(1 << 4)
#define	TERROR_NAV_BATTLESTATION		(1 << 5)
#define	TERROR_NAV_FINALE				(1 << 6)
#define	TERROR_NAV_PLAYER_START			(1 << 7)
#define	TERROR_NAV_BATTLEFIELD			(1 << 8)
#define	TERROR_NAV_IGNORE_VISIBILITY	(1 << 9)
#define	TERROR_NAV_NOT_CLEARABLE		(1 << 10)
#define	TERROR_NAV_CHECKPOINT			(1 << 11)
#define	TERROR_NAV_OBSCURED				(1 << 12)
#define	TERROR_NAV_NO_MOBS				(1 << 13)
#define	TERROR_NAV_THREAT				(1 << 14)
#define	TERROR_NAV_RESCUE_VEHICLE		(1 << 15)
#define	TERROR_NAV_RESCUE_CLOSET		(1 << 16)
#define	TERROR_NAV_ESCAPE_ROUTE			(1 << 17)
#define	TERROR_NAV_DOOR					(1 << 18)
#define	TERROR_NAV_NOTHREAT				(1 << 19)
#define	TERROR_NAV_LYINGDOWN			(1 << 20)
#define	TERROR_NAV_COMPASS_NORTH		(1 << 24)
#define	TERROR_NAV_COMPASS_NORTHEAST	(1 << 25)
#define	TERROR_NAV_COMPASS_EAST			(1 << 26)
#define	TERROR_NAV_COMPASS_EASTSOUTH	(1 << 27)
#define	TERROR_NAV_COMPASS_SOUTH		(1 << 28)
#define	TERROR_NAV_COMPASS_SOUTHWEST	(1 << 29)
#define	TERROR_NAV_COMPASS_WEST			(1 << 30)
#define	TERROR_NAV_COMPASS_WESTNORTH	(1 << 31)
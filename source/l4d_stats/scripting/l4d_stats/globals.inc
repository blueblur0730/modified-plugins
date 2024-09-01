#if defined _l4d_stats_globals_included
 #endinput
#endif
#define _l4d_stats_globals_included

#define PLUGIN_VERSION "2.6.0"

// Set to false when stats seem to work properly
#define DEBUG 0

#define MAX_LINE_WIDTH 64
#define MAX_MESSAGE_WIDTH 256
#define MAX_QUERY_COUNTER 256
#define MAX_ENTITIES 2048
#define DB_CONF_NAME "l4dstats"
#define TRANSLATION_FILE "l4d_stats.phrases"
#define MOTD_TITLE "Message Of The Day"

#define INF_ID_SMOKER 1
#define INF_ID_BOOMER 2
#define INF_ID_HUNTER 3
#define INF_ID_SPITTER_L4D2 4
#define INF_ID_JOCKEY_L4D2 5
#define INF_ID_CHARGER_L4D2 6
#define INF_ID_WITCH_L4D1 4
#define INF_ID_WITCH_L4D2 7
#define INF_ID_TANK_L4D1 5
#define INF_ID_TANK_L4D2 8

#define TEAM_UNDEFINED 0
#define TEAM_SPECTATORS 1
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3

#define INF_WEAROFF_TIME 0.5

#define CLEAR_DATABASE_CONFIRMTIME 10.0

#define CM_UNKNOWN -1
#define CM_RANK 0
#define CM_TOP10 1
#define CM_NEXTRANK 2
#define CM_NEXTRANKFULL 3

#define SOUND_RANKVOTE "items/suitchargeok1.wav"
#define SOUND_MAPTIME_START_L4D1 "UI/Beep23.wav"
#define SOUND_MAPTIME_START_L4D2 "level/countdown.wav"
#define SOUND_MAPTIME_IMPROVE_L4D1 "UI/Pickup_Secret01.wav"
#define SOUND_MAPTIME_IMPROVE_L4D2 "level/bell_normal.wav"
#define SOUND_RANKMENU_SHOW_L4D1 "UI/Menu_Horror01.wav"
#define SOUND_RANKMENU_SHOW_L4D2 "ui/menu_horror01.wav"
#define SOUND_BOOMER_VOMIT_L4D1 "player/Boomer/fall/boomer_dive_01.wav"
#define SOUND_BOOMER_VOMIT_L4D2 "player/Boomer/fall/boomer_dive_01.wav"
#define SOUND_HUNTER_PERFECT_L4D1 "player/hunter/voice/pain/lunge_attack_3.wav"
#define SOUND_HUNTER_PERFECT_L4D2 "player/hunter/voice/pain/lunge_attack_3.wav"
#define SOUND_TANK_BULLDOZER_L4D1 "player/tank/voice/yell/hulk_yell_8.wav"
#define SOUND_TANK_BULLDOZER_L4D2 "player/tank/voice/yell/tank_throw_11.wav"
#define SOUND_CHARGER_RAM "player/charger/voice/alert/charger_alert_02.wav"

#define RANKVOTE_NOVOTE -1
#define RANKVOTE_NO 0
#define RANKVOTE_YES 1

char TM_MENU_CURRENT[16] = " <<";
char DB_PLAYERS_TOTALPOINTS[512] = "points + points_survivors + points_infected + points_realism + points_survival + points_scavenge_survivors + points_scavenge_infected + points_realism_survivors + points_realism_infected + points_mutations";
char DB_PLAYERS_TOTALPLAYTIME[256] = "playtime + playtime_versus + playtime_realism + playtime_survival + playtime_scavenge + playtime_realismversus + playtime_mutations";
char g_sMessageOfTheDay[1024];

bool g_bCommandsRegistered = false;

// Server Engine
bool
    g_bLeft4Dead2 = false;
    g_bLeft4Dead = false;

// Sounds
bool 
    g_bEnableSounds_Rankvote = true,
    g_bEnableSounds_Maptime_Start = true,
    g_bEnableSounds_Maptime_Improve = true,
    g_bEnableSounds_Rankmenu_Show = true,
    g_bEnableSounds_Boomer_Vomit = true,
    g_bEnableSounds_Hunter_Perfect = true,
    g_bEnableSounds_Tank_Bulldozer = true,
    g_bEnableSounds_Charger_Ram = true;

char 
    g_sStatsSound_MapTime_Start[32],
    g_SStatsSound_MapTime_Improve[32],
    g_sStatsSound_Rankmenu_Show[32],
    g_sStatsSound_Boomer_Vomit[32],
    g_sStatsSound_Hunter_Perfect[32],
    g_sStatsSound_Tank_Bulldozer[32];

// Database handle
Database db = null;
char g_sDbPrefix[MAX_LINE_WIDTH] = "";

// Update Timer handle
Handle g_hUpdateTimer = null;

// Gamemode
char g_sCurrentGamemode[MAX_LINE_WIDTH];
char g_sCurrentGamemodeLabel[MAX_LINE_WIDTH];
int g_iCurrentGamemodeID = -1;
char g_sCurrentMutation[MAX_LINE_WIDTH];

// Disable check Cvar handles
ConVar 
    g_hCvar_Difficulty,
    g_hCvar_Cheats,
    g_hCvar_SurvivorLimit,
    g_hCvar_InfectedLimit;

// Game event booleans
bool 
    g_bPlayerVomited = false;
    g_bPlayerVomitedIncap = false;
    g_bPanicEvent = false;
    g_bPanicEventIncap = false;
    g_bCampaignOver = false;
    g_bWitchExists = false;
    g_bWitchDisturb = false;

// Anti-Stat Whoring vars
int g_iCurrentPoints[MAXPLAYERS + 1];
int g_iTankCount = 0;

bool g_bClientRankMute[MAXPLAYERS + 1];

ConVar 
    g_hCvar_EnableRankVote,
    g_hCvar_HumansNeeded,
    g_hCvar_UpdateRate,
//  g_hCvar_AnnounceRankMinChange,
    g_hCvar_AnnounceRankChange,
    g_hCvar_AnnouncePlayerJoined,
    g_hCvar_AnnounceMotd,
    g_hCvar_AnnounceMode,
    g_hCvar_AnnounceRankChangeIVal,
//  g_hCvar_AnnounceSpecial,
    g_hCvar_MedkitMode,
    g_hCvar_SiteURL,
    g_hCvar_RankOnJoin,
    g_hCvar_SilenceChat,
    g_hCvar_DisabledMessages,
//  g_hCvar_MaxPoints,
    g_hCvar_DbTagPrefix,
//  g_hCvar_LeaderboardTime,
    g_hCvar_EnableNegativeScore,
    g_hCvar_FriendlyFireMode,
    g_hCvar_FriendlyFireMultiplier,
    g_hCvar_FriendlyFireCooldown,
    g_hCvar_FriendlyFireCooldownMode;

Handle g_hFriendlyFireTimer[MAXPLAYERS + 1][MAXPLAYERS + 1]; //= { null, ... }; but why?
bool g_bFriendlyFireCooldown[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_iFriendlyFirePrm[MAXPLAYERS][2];
StringMap g_hFriendlyFireDamageTrie = null;
int g_iFriendlyFirePrmCounter = 0;

// record stats?
ConVar g_hCvar_Enable;

enum
{
    GAMEMODE_COOP = 0,
    GAMEMODE_VERSUS = 1,
    GAMEMODE_TEAMVERSUS = 2,
    GAMEMODE_REALISM = 3,
    GAMEMODE_SURVIVAL = 4,
    GAMEMODE_SCAVENGE = 5,
    GAMEMODE_TEAMSCAVENGE = 6,
    GAMEMODE_REALISMVERSUS = 7,
    GAMEMODE_TEAMREALISMVERSUS = 8,
    GAMEMODE_OTHERMUTATIONS = 9,

    GAMEMODES_SIZE = 10
};
ConVar g_hCvar_GameMode[GAMEMODES_SIZE];

ConVar 
    g_hCvar_RealismMultiplier,
    g_hCvar_RealismVersusSurMultiplier,
    g_hCvar_RealismVersusInfMultiplier,
    g_hCvar_EnableSurvivalMedicPoints;

enum
{
    CLASS_COMMON = 0,
    CLASS_HUNTER = 1,
    CLASS_SMOKER = 2,
    CLASS_BOOMER = 3,
    CLASS_SPITTER = 4,
    CLASS_JOCKEY = 5,
    CLASS_CHARGER = 6,

    CLASS_SIZE = 7
};
ConVar g_hCvar_KillInfectedClassScore[CLASS_SIZE];

enum
{
    ITEM_PILLS = 0,
    ITEM_ADRENALINE = 1,
    ITEM_MEDKIT = 2,
    ITEM_DEFIB = 3,

    ITEM_SIZE = 4
};
ConVar g_hCvar_GiveItemClassScore[ITEM_SIZE];

enum
{
    INF_ABILITY_TONGUEDRAG = 0,
    INF_ABILITY_CHOKE = 1,
    INF_ABILITY_RIDE = 2,
    INF_ABILITY_PUMMEL = 3,
    INF_ABILITY_CARRY = 4,
    // for hunter and boomer ability score rules see below

    INF_ABILITY_SIZE = 5
};
ConVar g_hCvar_SaveFromInfectedAbilityScore[INF_ABILITY_SIZE];

enum
{
    HELP_REVIVE = 0,
    HELP_RESCUE = 1,
    HELP_PROTECT = 2,

    HELP_SIZE = 3
};
ConVar g_hCvar_HelpScore[HELP_SIZE];

ConVar 
    g_hCvar_KillTankScore,
    g_hCvar_SurvivedPanicHordeScore,
    g_hCvar_SurvivedBoomerHordeScore,
    g_hCvar_ReachedSafeHouseScore,
    g_hCvar_NotDisturbingWitchScore,
    g_hCvar_WitchCrownedScore,
    g_hCvar_VictorySurvivorsScore,
    g_hCvar_VictoryInfectedScore;

enum
{
    ACT_FF = 0,
    ACT_FFINCAP = 1,
    ACT_FFKILL = 2,
    ACT_LET_INF_IN_SAFE_ROOM = 3,
    ACT_RESTART = 4,
    ACT_TRIGGERCARALERM = 5,
    
    ACT_SIZE = 6
};
ConVar g_hCvar_ActionScore[ACT_SIZE];
ConVar g_hCvar_BotScoreMultiplier;

// For every medkit used the points earned by the Survivor team is calculated with this formula:
// NormalPointsEarned * (1 - g_iMedkitsUsedCounter * g_hCvar_MedkitUsedPointPenalty)
// Minimum formula result = 0 (Cannot be negative)
int g_iMedkitsUsedCounter = 0;

ConVar 
    g_hCvar_MedkitUsedPointPenalty,
    g_hCvar_MedkitUsedPointPenaltyMax,
    g_hCvar_MedkitUsedFree,
    g_hCvar_MedkitUsedRealismFree,
    g_hCvar_MedkitBotMode;

// score penalty for survivor death and incap
ConVar
    g_hCvar_SurvivorDeathScore,
    g_hCvar_SurvivorIncapScore;

// L4D2 misc
ConVar 
    g_hCvar_AmmoUpgradeAddedScore,
    g_hCvar_GascanPouredScore;

// Hunter related score cvars
int g_iMaxPounceDistance;
int g_iMinPounceDistance;
int g_iMaxPounceDamage;
float g_fHunterPosition[MAXPLAYERS + 1][3];

ConVar 
    g_hCvar_HunterDamageCap,
    g_hCvar_HunterPerfectPounceDamage,
    g_hCvar_HunterPerfectPounceSuccess,
    g_hCvar_HunterNicePounceDamage,
    g_hCvar_HunterNicePounceSuccess;

// Boomer related score cvars
int g_iBoomerHitCounter[MAXPLAYERS + 1];
bool g_iBoomerVomitUpdated[MAXPLAYERS + 1];
Handle g_hTimerBoomerPerfectCheck[MAXPLAYERS + 1] = { null, ... };

ConVar 
    g_hCvar_BoomerSuccessScore,
    g_hCvar_BoomerPerfectHits,
    g_hCvar_BoomerPerfectSuccessScore;

// Infected related inflictor score cvars
int g_iInfectedDamageCounter[MAXPLAYERS + 1];
Handle g_hTimerInfectedDamageCheck[MAXPLAYERS + 1] = { null, ... };
ConVar g_hCvar_InfectedDamagePerPoint;

// Tank related score cvars
ConVar 
    g_hCvar_TankScoreDamageCap,
    g_hCvar_TankScoreDamageTotal,
    g_hCvar_TankScoreDamageTotalSuccessScore,
    g_hCvar_TankScoreThrowRockSuccessScore;

int 
    g_iTankDamageCounter[MAXPLAYERS + 1],
    g_iTankDamageTotalCounter[MAXPLAYERS + 1],
    g_iTankPointsCounter[MAXPLAYERS + 1],
    g_iTankSurvivorKillCounter[MAXPLAYERS + 1];

// SI Event related data
int 
    g_iChargerCarryVictim[MAXPLAYERS + 1],
    g_iChargerPlummelVictim[MAXPLAYERS + 1],
    g_iJockeyVictim[MAXPLAYERS + 1],
    g_iJockeyRideStartTime[MAXPLAYERS + 1];

int 
    g_iSmokerDamageCounter[MAXPLAYERS + 1],
    g_iSpitterDamageCounter[MAXPLAYERS + 1],
    g_iJockeyDamageCounter[MAXPLAYERS + 1],
    g_iChargerDamageCounter[MAXPLAYERS + 1],
    g_iChargerImpactCounter[MAXPLAYERS + 1];

Handle g_hChargerImpactCounterTimer[MAXPLAYERS + 1] = { null, ... };

// charger related score cvars
ConVar 
    g_hCvar_ChargerRamHitsPerPoints,
    g_hCvar_ChargerRamSuccessScore;

// Other related score cvars
ConVar g_hCvar_PlayerLedgeSuccessScore
ConVar g_hCvar_MatadorScore

int g_iClientInfectedType[MAXPLAYERS + 1];

// client states
int 
    g_iPlayerBlinded[MAXPLAYERS + 1][2],
    g_iPlayerParalyzed[MAXPLAYERS + 1][2],
    g_iPlayerLunged[MAXPLAYERS + 1][2],
    g_iPlayerPummeled[MAXPLAYERS + 1][2],
    g_iPlayerCarried[MAXPLAYERS + 1][2],
    g_iPlayerJockied[MAXPLAYERS + 1][2];

// Rank panel vars
int 
    g_iRankTotal = 0;
    g_iClientRank[MAXPLAYERS + 1],
    g_iClientNextRank[MAXPLAYERS + 1],
    g_iClientPoints[MAXPLAYERS + 1],
    g_iGameModeRankTotal = 0,
    g_iClientGameModeRank[MAXPLAYERS + 1],
    g_iClientGameModePoints[MAXPLAYERS + 1][GAMEMODES_SIZE];

// Misc arrays
int 
    g_iTimerPoints[MAXPLAYERS + 1],
    g_iTimerKills[MAXPLAYERS + 1],
    g_iTimerHeadshots[MAXPLAYERS + 1],
    g_iPillsIndex[MAX_ENTITIES],
    g_iAdrenalineIndex[MAX_ENTITIES];

#if DEBUG
char g_sQueryBuffer[MAX_QUERY_COUNTER][MAX_QUERY_COUNTER];
int g_iQueryCounter = 0;
#endif

int g_iAnnounceCounter[MAXPLAYERS + 1];
int g_iPostAdminCheckRetryCounter[MAXPLAYERS + 1];

int g_iProtectedFriendlyCounter[MAXPLAYERS + 1];
Handle g_hTimerProtectedFriendly[MAXPLAYERS + 1] = { null, ... };

// Announce rank
Handle g_hTimerRankChangeCheck[MAXPLAYERS + 1] = { null, ... };
int g_iRankChangeLastRank[MAXPLAYERS + 1];
bool g_bRankChangeFirstCheck[MAXPLAYERS + 1];

// MapTiming
float g_fMapTimingStartTime = -1.0;
bool g_bMapTimingBlocked = false;
StringMap g_hMapTimingSurvivors = null; // Survivors at the beginning of the map
StringMap g_hMapTimingInfected = null; // Survivors at the beginning of the map
char g_sMapTimingMenuInfo[MAXPLAYERS + 1][MAX_LINE_WIDTH];

// When an admin calls for clear database, the client id is stored here for a period of time.
// The admin must then call the clear command again to confirm the call. After the second call
// the database is cleared. The confirm must be done in the time set by CLEAR_DATABASE_CONFIRMTIME.
int g_iClearDatabaseCaller = -1;
Handle g_hClearDatabaseTimer = null;
//Handle ClearPlayerMenu = INVALID_HANDLE;

// Create handle for the admin menu
TopMenu g_hTM_RankAdminMenu = null;
TopMenuObject g_TMO_MenuClear = INVALID_TOPMENUOBJECT;
TopMenuObject g_TMO_MenuClearPlayers = INVALID_TOPMENUOBJECT;
TopMenuObject g_TMO_MenuClearMaps = INVALID_TOPMENUOBJECT;
TopMenuObject g_TMO_MenuClearAll = INVALID_TOPMENUOBJECT;
TopMenuObject g_TMO_MenuRemoveCustomMaps = INVALID_TOPMENUOBJECT;
TopMenuObject g_TMO_MenuCleanPlayers = INVALID_TOPMENUOBJECT;
TopMenuObject g_TMO_MenuClearTimedMaps = INVALID_TOPMENUOBJECT;

// Administrative Cvars
ConVar
    g_hCvar_AdminPlayerCleanLastOnTime,
    g_hCvar_AdminPlayerCleanPlatime;

// Players can request a vote for team shuffle based on the player ranks ONCE PER MAP
int g_iPlayerRankVote[MAXPLAYERS + 1];
Handle g_hRankVoteTimer = null;
StringMap g_hPlayerRankVoteTrie = null; // Survivors at the beginning of the map
ConVar g_hCvar_RankVoteTime;
ConVar g_hCvar_Top10PPMMin;

bool g_bSurvivalStarted = false;

Handle g_hSDKCall_SetHumanSpec;
Handle g_hSDCall_TakeOverBot;

float g_fClientMapTime[MAXPLAYERS + 1];

ConVar g_hCvar_Lan;
ConVar g_hCvar_SoundsEnabled;

Handle g_hMeleeKillTimer[MAXPLAYERS + 1] = { null, ... };
int g_iMeleeKillCounter[MAXPLAYERS + 1];
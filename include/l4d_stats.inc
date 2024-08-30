#if defined _l4d_stats_included
	#endinput
#endif
#define _l4d_stats_included

enum L4DStats_PlayerDataType
{
    ByRank = 1,             // query the 'players' table by rank number, the sort order is descending. use it except when using native GetRank()
    BySteamID = 2,          // query the 'players' table by steamid, use it except when using native GetSteamID()
    ByClientIndex = 3       // query the 'players' table by client index, use it except when using native GetSteamIndex() and GetName(). It can only be used when a client is in game.
};

enum CaculatorType
{
    Add = 1,
    Subtract = 2,
    Multiply = 3,
    Divide = 4
};

/**
 * Check if the plugin is connected to the database.
 * 
 * @return true if connected, false otherwise.
*/
native bool L4DStats_IsConnected();

/**
 * Check if the database tables is valid.
 * 
 * @return true if all is valid, false if one of them is invalid.
*/
native bool L4DStats_CheckValidity();

/**
 * Check if the player have muted the plugin.
 * 
 * @param steamid The steamid of the player to check.
 * @param maxlen The maximum length of the steamid buffer.
 * 
 * @return true if the player have muted the plugin, false otherwise.
*/
native bool L4DStats_IsMuted(const char[] steamid, int maxlen);


methodmap L4DStats_Player
{
    /**
     * The constructor of the L4DStats_Player class.
     * Creates a DataPack handle to store the given parameters for the functions below to access the 'players' table.
     * 
     * @param rank The rank number of the player to get the name.
     * @param client The client index of the player to get the name.
     * @param steamid The steamid of the player to get the name.
     * @param maxlen The maximum length of the steamid buffer.
     * 
     * @note After used the constructor, the DataPack handle should be deleted using the deleteThis() function.
     * 
     * @error Throw error if constructor is already created and not deleted.
    */
    public native L4DStats_Player(int rank = -1, int client = -1, const char[] steamid = "", int maxlen = 0);

    /**
     * Deletes the DataPack handle created by the constructor.
     * 
     * @noreturn
     * 
     * @error Throw error if Constructor Datapack handle is already null.
    */
    public native void deleteThis();

    /**
     * Rewrites the DataPack handle with the given parameters.
     * 
     * @param rank The rank number of the player to get the name. -1 will throws an error.
     * @param client The client index of the player to get the name. -1 will throws an error.
     * @param steamid The steamid of the player to get the name, epmty string will throws an error.
     * @param maxlen The maximum length of the steamid buffer.
     * 
     * @noreturn
     * 
     * @error Throw error if constructor is not called before.
    */
    public native void Rewrite(int rank = -1, int client = -1, const char[] steamid = "", int maxlen = 0);

    /**
     * Get total number of players in the 'players' table.
     * 
     * @note It is safe to get this property without the constructor being set up.
     * 
     * @error Throw error when database handle is null (plugin did not connnected to the database).
    */
    property int TotalPlayer {
        public native get();
    }

    /**
     * Check if a player is existed in the 'players' table.
     * 
     * @param data The type of data to target by.
     * 
     * @return true if the player exists, false otherwise.
     * 
     * @error Throw error when database handle is null (plugin did not connnected to the database) or client index is invalid, or query failed.
    */
    public native bool CheckPlayer(L4DStats_PlayerDataType data);

    /**
     * Choosing a method, Get the steamid of a player in the 'players' table.
     * 
     * @param data The type of data to target by.
     * @param SteamID The buffer to store the steamid of the player.
     * @param maxlen The maximum length of the steamid buffer.
     * 
     * @noreturn
     * 
     * @error Throw error when database handle is null (plugin did not connnected to the database) or query failed.
    */
    public native void GetSteamID(L4DStats_PlayerDataType data, const char[] SteamID, int maxlen);

    /**
     * Choosing a method, retrives the name of a player in the 'players' table.
     * 
     * @param data The type of data to target by.
     * @param Name The buffer to store the name of the player.
     * @param maxlen The maximum length of the name buffer.
     * 
     * @noreturn
     * 
     * @error Throw error when database handle is null (plugin did not connnected to the database) or query failed.
    */
    public native void GetName(L4DStats_PlayerDataType data, const char[] Name, int maxlen);

    /**
     * Choosing a method, retrives the total points of a player in the 'players' table.
     * 
     * @param data The type of data to target by.
     * 
     * @return The total points of the player.
     * 
     * @error Throw error when database handle is null (plugin did not connnected to the database) or query failed.
    */
    public native int GetPoints(L4DStats_PlayerDataType data);

    /**
     * Choosing a method, retrives the total playtime of a player in the 'players' table.
     * 
     * @param data The type of data to target by.
     * 
     * @return The total playtime of the player. (in minutes)
     * 
     * @error Throw error when database handle is null (plugin did not connnected to the database) or query failed.
    */
    public native int GetTime(L4DStats_PlayerDataType data);

    /**
     * Choosing a method, retrives the PPM (points per minute) of a player in the 'players' table.
     * 
     * @param data The type of data to target by.
     * 
     * @return The PPM (points per minute) of the player.
     * 
     * @error Throw error when database handle is null (plugin did not connnected to the database) or query failed.
    */
    public native float GetPPM(L4DStats_PlayerDataType data);

    /**
     * Choosing a method, retrives the rank number (descending order) of a player in the 'players' table.
     * 
     * @param data The type of data to target by.
     * 
     * @return The rank number (dscending order) of the player.
     * 
     * @error Throw error when database handle is null (plugin did not connnected to the database) or query failed.
    */
    public native int GetRank(L4DStats_PlayerDataType data);

    /**
     * Update the total points of a player by choosing a method to caculate the original points with the given points.
     * 
     * @param data The type of data to target by.
     * @param type The type of caculation to perform.
     * @param points The points to caculate with.
     * 
     * @noreturn
     * 
     * @error Throw error when database handle is null (plugin did not connnected to the database) or query failed.
    */
    public native void UpdatePoints(L4DStats_PlayerDataType data, CaculatorType type, int points);
}

enum GameModeID
{
    COOP = 0,
    VERSUS = 1,
    TEAMVERSUS = 2,
    REALISM = 3,
    SURVIVAL = 4,
    SCAVENGE = 5,
    TEAMSCAVENGE = 6,
    REALISMVERSUS = 7,
    TEAMREALISMVERSUS = 8,
    OTHERMUTATIONS = 9,
};

enum DifficultyID
{
    EASY = 0,
    NORMAL = 1,
    HARD = 2,
    IMPOSSIBLE = 3,
}

methodmap L4DStats_Map
{
    /**
     * The constructor of the L4DStats_Map class.
     * Creates a DataPack handle to store the given parameters for the functions below to access the 'timedmaps' table.
     * 
     * @param steamid The steamid of the player to query for.
     * @param maxlen1 The maximum length of the steamid buffer.
     * @param mapname The name of the map to query for.
     * @param maxlen2 The maximum length of the mapname buffer.
     * @param gamemode The gamemode you want to query for.
     * @param difficulty The difficulty you want to query for.
     * 
     * @note After used the constructor, the DataPack handle should be deleted using the deleteThis() function.
     * 
     * @error Throw error if constructor is already created and not deleted.
    */
    public native L4DStats_Map(const char[] steamid, int maxlen1, const char[] mapname, int maxlen2, GameModeID gamemode, DifficultyID difficulty);

    /**
     * Deletes the DataPack handle created by the constructor.
     * 
     * @noreturn
     * 
     * @error Throw error if Constructor Datapack handle is already null.
    */
    public native void deleteThis();

    /**
     * Rewrites the DataPack handle with the given parameters.
     * 
     * @param steamid The steamid of the player to query for.
     * @param maxlen1 The maximum length of the steamid buffer.
     * @param mapname The name of the map to query for.
     * @param maxlen2 The maximum length of the mapname buffer.
     * @param gamemode The gamemode you want to query for.
     * @param difficulty The difficulty you want to query for.
     * 
     * @noreturn
     * 
     * @error Throw error if constructor is not called before.
    */
    public native void Rewrite(const char[] steamid, int maxlen1, const char[] mapname, int maxlen2, GameModeID gamemode, DifficultyID difficulty);

    /**
     * Check if a player has played the map.
     * 
     * @return true if the player has played the map, false otherwise.
     * 
     * @error Throw error when database handle is null (plugin did not connnected to the database) or query failed.
    */
    public native bool HasPlayedMap();

    /**
     * Get the best accomplishment time of the map of a player. (under the conditions of the gamemode and difficulty)
     * 
     * @return The best accomplishment time of the map. (in seconds)
     * 
     * @error Throw error when database handle is null (plugin did not connnected to the database) or query failed.
    */
    public native float GetBestTime();

    /**
     * Get the play count of the map of a player. (under the conditions of the gamemode and difficulty)
     * 
     * @return The play count of the map.
     * 
     * @error Throw error when database handle is null (plugin did not connnected to the database) or query failed.
    */
    public native int GetPlayCount();

    /**
     * Get the total players count at the moment when a player's best time shows up. (under the conditions of the gamemode and difficulty)
     * 
     * @return The total players count.
     * 
     * @error Throw error when database handle is null (plugin did not connnected to the database) or query failed.
    */
    public native int GetPlayersCount();

    /**
     * Get the date string when a player's best time shows up. (under the conditions of the gamemode and difficulty)
     * 
     * @param date The buffer to store the date string.
     * @param maxlen The maximum length of the date buffer.
     * 
     * @noreturn
     * 
     * @error Throw error when database handle is null (plugin did not connnected to the database) or query failed.
    */
    public native void GetBestTimeDate(const char[] date, int maxlen);
}

public SharedPlugin __pl_l4d_stats = 
{
	name = "l4d_stats",
	file = "l4d_stats.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d_stats_SetNTVOptional()
{
	MarkNativeAsOptional("L4DStats_IsConnected");
	MarkNativeAsOptional("L4DStats_CheckValidity");

	MarkNativeAsOptional("L4DStats_Player.L4DStasts_Player");
	MarkNativeAsOptional("L4DStats_Player.deleteThis");
	MarkNativeAsOptional("L4DStats_Player.Rewrite");
	MarkNativeAsOptional("L4DStats_Player.TotalPlayer.get");
	MarkNativeAsOptional("L4DStats_Player.CheckPlayer");
	MarkNativeAsOptional("L4DStats_Player.GetSteamID");
	MarkNativeAsOptional("L4DStats_Player.GetName");
	MarkNativeAsOptional("L4DStats_Player.GetPoints");
	MarkNativeAsOptional("L4DStats_Player.GetTime");
	MarkNativeAsOptional("L4DStats_Player.GetPPM");
	MarkNativeAsOptional("L4DStats_Player.GetRank");
    MarkNativeAsOptional("L4DStats_Player.UpdatePoints");

    MarkNativeAsOptional("L4DStats_Map.L4DStats_Map");
    MarkNativeAsOptional("L4DStats_Map.deleteThis");
    MarkNativeAsOptional("L4DStats_Map.Rewrite");
    MarkNativeAsOptional("L4DStats_Map.HasPlayedMap");
    MarkNativeAsOptional("L4DStats_Map.GetBestTime");
    MarkNativeAsOptional("L4DStats_Map.GetPlayCount");
    MarkNativeAsOptional("L4DStats_Map.GetPlayersCount");
    MarkNativeAsOptional("L4DStats_Map.GetBestTimeDate");
}
#endif
#if defined _l4d_stats_included
	#endinput
#endif
#define _l4d_stats_included

enum L4DStats_SelectMethod
{
    ByRank = 1,             // query the 'players' table by rank number, the sort order is descending. use it except when using native GetRank()
    BySteamID = 2,          // query the 'players' table by steamid, use it except when using native GetSteamID()
    ByClientIndex = 3       // query the 'players' table by client index, use it except when using native GetSteamIndex() and GetName(). It can only be used when a client is in game.
};

methodmap L4DStats 
{
    /**
     * Get total number of players in the 'players' table.
     * 
     * @error Throw error when database handle is null (plugin did not connnected to the database).
    */
    property int TotalPlayer {
        public native get();
    }

    /**
     * Check if the plugin is connected to the database.
     * 
     * @return true if connected, false otherwise.
    */
    public native bool IsConnected();

    /**
     * Check if the database tables is valid.
     * 
     * @return true if all is valid, false if one of them is invalid.
    */
    public native bool CheckDBValidity();

    /**
     * Check if a map in specific gamemode exists in the 'maps' table.
     * 
     * @param mapname The name of the map to check.
     * @param maxlen1 The maximum length of the map name.
     * @param gamemode The name of the gamemode to check.
     * @param maxleng2 The maximum length of the gamemode name.
     * 
     * @return true if the map exists, false otherwise.
     * 
     * @error Throw error when database handle is null (plugin did not connnected to the database) or query failed.
    */
    public native bool CheckMap(char[] mapname, int maxlen1, char[] gamemode, int maxleng2);

    /**
     * Check if a player exists in the 'players' table.
     * 
     * @param method The method to use to select the player.
     * @param steamid The steamid of the player to get the name, epmty string will throws an error.
     * @param maxlen1 The maximum length of the steamid buffer, 0 will throws an error.
     * @param rank The rank number of the player to get the name. -1 will throws an error.
     * @param client The client index of the player to get the name. -1 will throws an error.
     * 
     * @return true if the player exists, false otherwise.
     * 
     * @error Throw error when database handle is null (plugin did not connnected to the database) or client index is invalid, or query failed.
    */
    public native bool CheckPlayer(L4DStats_SelectMethod method, char[] steamid = "", int maxlen1 = 0, int rank = -1, int client = -1);

    /**
     * Get the steamid of a player in the 'players' table by rank number.
     * 
     * @param rank The rank number of the player to get the steamid. -1 will throws an error.
     * @param steamid The buffer to store the steamid.
     * @param maxlen The maximum length of the steamid buffer.
     * 
     * @error Throw error when database handle is null (plugin did not connnected to the database) or query failed.
    */
    public native void GetSteamID(int rank = -1, char[] steamid, int maxlen);

    /**
     * Choosing a method, given the proper parameters, retrives the name of a player in the 'players' table.
     * 
     * @param method The method to use to select the player.
     * @param name The buffer to store the name.
     * @param maxlen The maximum length of the name buffer.
     * @param steamid The steamid of the player to get the name, epmty string will throws an error.
     * @param maxlen1 The maximum length of the steamid buffer, 0 will throws an error.
     * @param rank The rank number of the player to get the name. -1 will throws an error.
     * 
     * @noreturn
     * 
     * @error Throw error when database handle is null (plugin did not connnected to the database) or query failed.
    */
    public native void GetName(L4DStats_SelectMethod method, char[] name, int maxlen, char[] steamid = "", int maxlen1 = 0, int rank = -1);

    /**
     * Choosing a method, given the proper parameters, retrives the total points of a player in the 'players' table.
     * 
     * @param method The method to use to select the player.
     * @param steamid The steamid of the player to get the name, epmty string will throws an error.
     * @param maxlen1 The maximum length of the steamid buffer, 0 will throws an error.
     * @param rank The rank number of the player to get the name. -1 will throws an error.
     * @param client The client index of the player to get the name. -1 will throws an error.
     * 
     * @return The total points of the player.
     * 
     * @error Throw error when database handle is null (plugin did not connnected to the database) or query failed.
    */
    public native int GetPoints(L4DStats_SelectMethod method, char[] steamid = "", int maxlen = 0, int rank = -1, int client = -1);

    /**
     * Choosing a method, given the proper parameters, retrives the total playtime of a player in the 'players' table.
     * 
     * @param method The method to use to select the player.
     * @param steamid The steamid of the player to get the name, epmty string will throws an error.
     * @param maxlen1 The maximum length of the steamid buffer, 0 will throws an error.
     * @param rank The rank number of the player to get the name. -1 will throws an error.
     * @param client The client index of the player to get the name. -1 will throws an error.
     * 
     * @return The total playtime of the player.
     * 
     * @error Throw error when database handle is null (plugin did not connnected to the database) or query failed.
    */
    public native int GetTime(L4DStats_SelectMethod method, char[] steamid = "", int maxlen = 0, int rank = -1, int client = -1);

    /**
     * Choosing a method, given the proper parameters, retrives the PPM (points per minute) of a player in the 'players' table.
     * 
     * @param method The method to use to select the player.
     * @param steamid The steamid of the player to get the name, epmty string will throws an error.
     * @param maxlen1 The maximum length of the steamid buffer, 0 will throws an error.
     * @param rank The rank number of the player to get the name. -1 will throws an error.
     * @param client The client index of the player to get the name. -1 will throws an error.
     * 
     * @return The PPM (points per minute) of the player.
     * 
     * @error Throw error when database handle is null (plugin did not connnected to the database) or query failed.
    */
    public native int GetPPM(L4DStats_SelectMethod method, char[] steamid = "", int maxlen = 0, int rank = -1, int client = -1);

    /**
     * Choosing a method, given the proper parameters, retrives the rank number (descending order) of a player in the 'players' table.
     * 
     * @param method The method to use to select the player.
     * @param steamid The steamid of the player to get the name, epmty string will throws an error.
     * @param maxlen1 The maximum length of the steamid buffer, 0 will throws an error.
     * @param client The client index of the player to get the name. -1 will throws an error.
     * 
     * @return The rank number (dscending order) of the player.
     * 
     * @error Throw error when database handle is null (plugin did not connnected to the database) or query failed.
    */
    public native int GetRank(L4DStats_SelectMethod method, char[] steamid = "", int maxlen = 0, int client = -1);

    /**
     * Get top x players by points with descending order.
     * 
     * @return An arraylist of the points of top x players.
    */
    public ArrayList GetTopX(int x) {
        ArrayList topTen = new ArrayList();

        int iPoints = 0;
        for (int i = 0; i < x; i++) 
        {
            iPoints = this.GetPoints(ByRank, _, _, i);
            topTen.Push(iPoints);
        }

        return topTen;
    }

    /**
     * Get top x players by PPM with descending order.
     * 
     * @return An arraylist of the PPM of top x players.
    */
    public ArrayList GetTopXPPM(int x) {
        ArrayList topTen = new ArrayList();

        int iPPM = 0;
        for (int i = 0; i < x; i++) 
        {
            iPPM = this.GetPPM(ByRank, _, _, i);
            topTen.Push(iPPM);
        }

        return topTen;
    }

    /**
     * Get top x players by playtime with descending order.
     * 
     * @return An arraylist of the playtime of top x players.
    */
    public ArrayList GetTopXTime(int x) {
        ArrayList topTen = new ArrayList();

        int iTime = 0;
        for (int i = 0; i < x; i++) 
        {
            iTime = this.GetTime(ByRank, _, _, i);
            topTen.Push(iTime);
        }

        return topTen;
    }
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
	MarkNativeAsOptional("L4DStats.TotalPlayer.get");
	MarkNativeAsOptional("L4DStats.Connected");
	MarkNativeAsOptional("L4DStats.CheckDBValidity")
	MarkNativeAsOptional("L4DStats.CheckMap");
	MarkNativeAsOptional("L4DStats.CheckPlayer");
	MarkNativeAsOptional("L4DStats.GetSteamID");
	MarkNativeAsOptional("L4DStats.GetName");
	MarkNativeAsOptional("L4DStats.GetPoints");
	MarkNativeAsOptional("L4DStats.GetTime");
	MarkNativeAsOptional("L4DStats.GetPPM");
	MarkNativeAsOptional("L4DStats.GetRank");
}
#endif
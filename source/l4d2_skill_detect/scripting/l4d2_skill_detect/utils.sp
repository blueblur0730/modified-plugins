#if defined _skill_detect_utils_included
    #endinput
#endif
#define _skill_detect_utils_included

#include <address_base>

#define L4D2_MAXPLAYERS        32

#define POUNCE_CHECK_TIME      0.1
#define HOP_CHECK_TIME         0.1
#define HOPEND_CHECK_TIME      0.1     // after streak end (potentially) detected, to check for realz?
#define SHOVE_TIME             0.05
#define VOMIT_DURATION_TIME    2.25      // how long the boomer vomit stream lasts -- when to check for boom count
#define ROCK_CHECK_TIME        0.34      // how long to wait after rock entity is destroyed before checking for skeet/eat (high to avoid lag issues)
#define CARALARM_MIN_TIME      0.11      // maximum time after touch/shot => alarm to connect the two events (test this for LAG)

#define WITCH_CHECK_TIME       0.1      // time to wait before checking for witch crown after shoots fired
#define WITCH_DELETE_TIME      0.15      // time to wait before deleting entry from witch Map after entity is destroyed

#define HOP_ACCEL_THRESH       0.01      // bhop speed increase must be higher than this for it to count as part of a hop streak

#define ZC_SMOKER              1
#define ZC_BOOMER              2
#define ZC_HUNTER              3
#define ZC_SPITTER             4
#define ZC_JOCKEY              5
#define ZC_CHARGER             6
#define ZC_WITCH               7
#define ZC_TANK                8

#define L4D1_ZOMBIECLASS_TANK 5
#define L4D2_ZOMBIECLASS_TANK 8

enum struct IntervalTimer_t
{
    // gpGlobals->curtime
    float Now()
    {
        return GetGameTime();
    }    

    void Reset()
    {
        this.m_timestamp = this.Now();
    }        

    void Start()
    {
        this.m_timestamp = this.Now();
    }

    void Invalidate()
    {
        this.m_timestamp = -1.0;
    }        

    bool HasStarted()
    {
        return (this.m_timestamp > 0.0);
    }

    /// if not started, elapsed time is very large
    float GetElapsedTime()
    {
        return (this.HasStarted()) ? (this.Now() - this.m_timestamp) : 99999.9;
    }

    bool IsLessThan( float duration )
    {
        return (this.Now() - this.m_timestamp < duration) ? true : false;
    }

    bool IsGreaterThan( float duration )
    {
        return (this.Now() - this.m_timestamp > duration) ? true : false;
    }

    float m_timestamp;
}

enum struct CountdownTimer_t
{
	void Init()
	{
		this.m_timestamp = -1.0;
		this.m_duration = 0.0;
	}

	float Now()
	{
		return GetGameTime(); // gpGlobals->curtime
	}

	void Reset()
	{
		this.m_timestamp = this.Now() + this.m_duration;
	}		

	void Start( float duration )
	{
		this.m_timestamp = this.Now() + duration;
		this.m_duration = duration;
	}

	void Invalidate()
	{
		this.m_timestamp = -1.0;
	}		

	bool HasStarted()
	{
		return (this.m_timestamp > 0.0);
	}

	bool IsElapsed()
	{
		return (this.Now() > this.m_timestamp);
	}

	float GetElapsedTime()
	{
		return this.Now() - this.m_timestamp + this.m_duration;
	}

	float GetRemainingTime()
	{
		return (this.m_timestamp - this.Now());
	}

	/// return original countdown time
	float GetCountdownDuration()
	{
		return (this.m_timestamp > 0.0) ? this.m_duration : 0.0;
	}

	float m_duration;
	float m_timestamp;
}

/*
// size 92
struct CTakeDamageInfo
{
	float m_vecDamageForce[3]; // 0 Vector
	float m_vecDamagePosition[3]; // 12 Vector
	float m_vecReportedPosition[3];	// 24 Vector
	float m_vecUnknown36[3]; // 36 someone thinks it's a vector I guess
	int m_hInflictor; // 48 EHANDLE
	int m_hAttacker; // 52 EHANDLE
	int m_hWeapon; // 56 EHANDLE
	float m_flDamage; // 60
	float m_flMaxDamage; // 64
	float m_flBaseDamage;	// 68
	int m_bitsDamageType; // 72
	int m_iDamageCustom; // 76
	int m_iDamageStats;// 80
	int m_iAmmoType; // 84
	float m_flRadius; // 88
};
*/

methodmap CTakeDamageInfo < AddressBase
{
    property int m_hAttacker {
        public get() {
            return GetEntityFromHandle(LoadFromAddress(this.addr + 52, NumberType_Int32));
        }
    }

    property int m_hWeapon {
        public get() {
            return GetEntityFromHandle(LoadFromAddress(this.addr + 56, NumberType_Int32));
        }
    }

    property float m_flDamage {
        public get() {
            return LoadFromAddress(this.addr + 60, NumberType_Int32);
        }
    }
/*
    property float m_flMaxDamage {
        public get() {
            return LoadFromAddress(this.addr + 64, NumberType_Int32);
        }
    }
*/
    property int m_bitsDamageType {
        public get() {
            return LoadFromAddress(this.addr + 72, NumberType_Int32);
        }
    }
/*
    property int m_iDamageCustom {
        public get() {
            return LoadFromAddress(this.addr + 76, NumberType_Int32);
        }
    }
*/
}

enum struct Vector
{
    float x; 
    float y;
    float z;

    bool IsZero() {
        return (this.x == 0 && this.y == 0 && this.z == 0);
    }

    bool IsEqual(Vector vec) {
        return (this.x == vec.x && this.y == vec.y && this.z == vec.z);
    }

    void Set(float x, float y, float z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    void Equal(Vector vec) {
        this.x = vec.x;
        this.y = vec.y;
        this.z = vec.z;
    }

    void Add(Vector vec) {
        this.x += vec.x;
        this.y += vec.y;
        this.z += vec.z;
    }

    void Subtract(Vector vec) {
        this.x -= vec.x;
        this.y -= vec.y;
        this.z -= vec.z;
    }

    float Length(bool squared=false)
    {
        float arr[3];
        arr[0] = this.x;
        arr[1] = this.y;
        arr[2] = this.z;
        return GetVectorLength(arr, squared);
    }

    float Distance(Vector vec, bool squared=false) {
        return GetVectorDistance(this.ToArray(), vec.ToArray(), squared);
    }

    void GetClientAbsOrigin(int client) {
        float arr[3];
        GetClientAbsOrigin(client, arr);

        this.x = arr[0];
        this.y = arr[1];
        this.z = arr[2];
    }

    void GetClientAbsVelocity(int client) {
        float arr[3];
        GetClientAbsVelocity(client, arr);

        this.x = arr[0];
        this.y = arr[1];
        this.z = arr[2];
    }

    void GetClientVelocity(int client) {
        float arr[3];
        GetEntPropVector(client, Prop_Data, "m_vecVelocity", arr);

        this.x = arr[0];
        this.y = arr[1];
        this.z = arr[2];
    }

    void GetPlayerMins(int client) {
        float arr[3];
        GetClientMins(client, arr);

        this.x = arr[0];
        this.y = arr[1];
        this.z = arr[2];
    }

    void GetPlayerMaxs(int client) {
        float arr[3];
        GetClientMaxs(client, arr);

        this.x = arr[0];
        this.y = arr[1];
        this.z = arr[2];
    }

    float[] ToArray() {
        float arr[3];
        arr[0] = this.x;
        arr[1] = this.y;
        arr[2] = this.z;
        return arr;
    }
}

stock void LoadTranslation(const char[] translation)
{
    char sPath[PLATFORM_MAX_PATH], sName[PLATFORM_MAX_PATH];
    Format(sName, sizeof(sName), "translations/%s.txt", translation);
    BuildPath(Path_SM, sPath, sizeof(sPath), sName);
    if (!FileExists(sPath))
        SetFailState("Missing translation file %s.txt", translation);

    LoadTranslations(translation);
}

stock bool IsValidClientInGame(int client)
{
    return (IsValidClientIndex(client) && IsClientInGame(client));
}

stock bool IsClientAndInGame(int index)
{
    return (index > 0 && index <= MaxClients && IsClientInGame(index));
}

stock bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock int GetEntityFromHandle(any handle)
{
	int ent = handle & 0xFFF;
	if (ent == 0xFFF)
		ent = -1;
	return ent;
}

stock bool IsWitch(int iEntity)
{
    if (iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
    {
        char strClassName[64];
        GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
        return StrEqual(strClassName, "witch");
    }

    return false;
}

stock bool IsRock(int iEntity)
{
    if (iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
    {
        char strClassName[64];
        GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
        return StrEqual(strClassName, "tank_rock");
    }

    return false;
}

stock float GetSurvivorDistance(int client)
{
    return L4D2Direct_GetFlowDistance(client);
}

stock bool GetClientAbsVelocity(int client, float velocity[3])
{
    static int offset = -1;

    if (offset == -1 && (offset = FindDataMapInfo(client, "m_vecAbsVelocity")) == -1) // FindDataMapOffs(client, "m_vecAbsVelocity")) == -1)
        return false;
    
    GetEntDataVector(client, offset, velocity);
    return true;
}

stock float fmaxf(float a, float b)
{
    return (a > b) ? a : b;
}

// game internal damage calculation.
stock float FallingDamageForSpeed( float speed )
{
    if ( speed < 0.0 )
    {
        return 0.0;
    }
    else
    {
        return ( (speed / (720 - 560)) * (speed / (720 - 560)) * 100.0 );
    }
}
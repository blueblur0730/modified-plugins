#if defined _skill_detect_utils_included
    #endinput
#endif
#define _skill_detect_utils_included

#include <address_base>

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

    void GetClientAbsOrigin(int client) {
        float arr[3];
        GetClientAbsOrigin(client, arr);

        this.x = arr[0];
        this.y = arr[1];
        this.z = arr[2];
    }

    float Distance(Vector vec, bool squared=false) {
        return GetVectorDistance(this.ToArray(), vec.ToArray(), squared);
    }

    float[] ToArray() {
        float arr[3];
        arr[0] = this.x;
        arr[1] = this.y;
        arr[2] = this.z;
        return arr;
    }
}

stock void PrintDebug(const char[] Message, any...)
{
    if (!g_hCvar_Debug.BoolValue)
        return;

    char sFormat[256];
    VFormat(sFormat, sizeof(sFormat), Message, 2);

    char Path[PLATFORM_MAX_PATH];
    if (Path[0] == '\0')
        BuildPath(Path_SM, Path, PLATFORM_MAX_PATH, "/logs/skill_detect.log");

    LogToFileEx(Path, sFormat);
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

stock float GetSurvivorDistance(int client)
{
    return L4D2Direct_GetFlowDistance(client);
}
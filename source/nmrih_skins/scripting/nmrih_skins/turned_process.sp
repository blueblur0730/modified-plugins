
/**
 * The problem comes to that there's no direct connection between the infected player and the turned zombie.
 * The watcher has 9 entries, each represents the client index of each player.
 * By overriding and rebuilding the think function of the watcher, we can set the model to the desired one.
 * 
 * Note: Your custom model must be placed in the game's file system search path (nmrih/download e.g.), since the turned model is not used for players.
*/

#if 0 
// total size 292 = 4 + 12 + 12 + 4 + 260
struct TurnedZombieEntry_t {
    CBaseHandle *m_hRagDollHandle;   // 924
    Vector m_vecTurnedPosition;   // 928
    QAngle m_angTurnedAngle;  // 940
    float m_flTurnedTime; // 952
    char m_szModel[260];  // 956
}

class CNMRiH_TurnedZombie_Watcher {
    ... // inherited.
    TurnedZombieEntry_t m_TurnedZombieEntry[9]; // entity size 3552
}
#endif

#include <stringt>

#define INVALID_EHANDLE_INDEX 0xFFFFFFFF

static int g_iOff_TurnedZombieEntry_t_size = -1;
static int g_iOff_m_TurnedZombieEntry = -1;
static int g_iOff_m_hRagDollHandle = -1;
static int g_iOff_m_vecTurnedPosition = -1;
static int g_iOff_m_angTurnedAngle = -1;
static int g_iOff_m_flTurnedTime = -1;
static int g_iOff_m_szModel = -1;

DynamicDetour g_hDetour = null;
static Address g_pEntityList = Address_Null;

static Handle g_hSDKCall_UTIL_RemoveImmediate;
static Handle g_hSDKCall_InitRelationshipTable;
static Handle g_hSDKCall_SetCondition;
static Handle g_hSDKCall_SetSequenceByName;
static Handle g_hSDKCall_SetullSizeNormal;
static Handle g_hSDKCall_SetNextThink;

static const char g_sDefaultTurnedModel[][] = {
	"models/nmr_zombie/badass_infected.mdl",
	"models/nmr_zombie/bateman_infected.mdl",
	"models/nmr_zombie/butcher_infected.mdl",
	"models/nmr_zombie/hunter_infected.mdl",
	"models/nmr_zombie/jive_infected.mdl",
	"models/nmr_zombie/molotov_infected.mdl",
	"models/nmr_zombie/roje_infected.mdl",
	"models/nmr_zombie/wally_infected.mdl"
};

methodmap TurnedZombieEntry_t {
    property Address m_hRagDollHandle {
        public get() {
            return LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iOff_m_hRagDollHandle), NumberType_Int32);
        }

        public set(Address value) {
            StoreToAddress(view_as<Address>(this) + view_as<Address>(g_iOff_m_hRagDollHandle), value, NumberType_Int32);
        }
    }

    public void GetTurnedPosition(float vec[3]) {
        vec[0] = LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iOff_m_vecTurnedPosition), NumberType_Int32);
        vec[1] = LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iOff_m_vecTurnedPosition) + view_as<Address>(4), NumberType_Int32);
        vec[2] = LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iOff_m_vecTurnedPosition) + view_as<Address>(8), NumberType_Int32);
    }

    public void GetTurnedAngle(float ang[3]) {
        ang[0] = LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iOff_m_angTurnedAngle), NumberType_Int32);
        ang[1] = LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iOff_m_angTurnedAngle) + view_as<Address>(4), NumberType_Int32);
        ang[2] = LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iOff_m_angTurnedAngle) + view_as<Address>(8), NumberType_Int32);
    }

    public void SetTurnedPosition(float vec[3]) {
        StoreToAddress(view_as<Address>(this) + view_as<Address>(g_iOff_m_vecTurnedPosition), vec[0], NumberType_Int32);
        StoreToAddress(view_as<Address>(this) + view_as<Address>(g_iOff_m_vecTurnedPosition) + view_as<Address>(4), vec[1], NumberType_Int32);
        StoreToAddress(view_as<Address>(this) + view_as<Address>(g_iOff_m_vecTurnedPosition) + view_as<Address>(8), vec[2], NumberType_Int32);
    }

    public void SetTurnedAngle(float ang[3]) {
        StoreToAddress(view_as<Address>(this) + view_as<Address>(g_iOff_m_angTurnedAngle), ang[0], NumberType_Int32);
        StoreToAddress(view_as<Address>(this) + view_as<Address>(g_iOff_m_angTurnedAngle) + view_as<Address>(4), ang[1], NumberType_Int32);
        StoreToAddress(view_as<Address>(this) + view_as<Address>(g_iOff_m_angTurnedAngle) + view_as<Address>(8), ang[2], NumberType_Int32);
    }

    property float m_flTurnedTime {
        public get() {
            return LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iOff_m_flTurnedTime), NumberType_Int32);
        }

        public set(float value) {
            StoreToAddress(view_as<Address>(this) + view_as<Address>(g_iOff_m_flTurnedTime), value, NumberType_Int32);
        }
    }

    // as the give, the size should be 260.
    public void GetModelName(char[] buffer, int size) {
        Stringt(view_as<Address>(this) + view_as<Address>(g_iOff_m_szModel)).ToCharArray(buffer, size);
    }
/*
    public void EmptyModelString() {

    }
*/
}

methodmap CNMRiH_TurnedZombie_Watcher {
/*
    public CNMRiH_TurnedZombie_Watcher(int entity) {
        return view_as<CNMRiH_TurnedZombie_Watcher>(entity);
    }
*/
    public CNMRiH_TurnedZombie_Watcher(Address pThis) {
        return view_as<CNMRiH_TurnedZombie_Watcher>(pThis);
    }

    public TurnedZombieEntry_t GetEntry(int index) {
        return view_as<TurnedZombieEntry_t>(view_as<Address>(this) + 
                                            view_as<Address>(g_iOff_m_TurnedZombieEntry) + 
                                            view_as<Address>((index) * g_iOff_TurnedZombieEntry_t_size));
    }
}

methodmap CAI_BaseNPC {
    public CAI_BaseNPC(int entity) {
        return view_as<CAI_BaseNPC>(entity);
    }

    public void InitRelationshipTable() {
        SDKCall(g_hSDKCall_InitRelationshipTable, this);
    }

    public void SetCondition(int condition) {
        SDKCall(g_hSDKCall_SetCondition, this, condition);
    }

    public void SetSequenceByName(const char[] name) {
        SDKCall(g_hSDKCall_SetSequenceByName, this, name);
    }

    public void SetHullSizeNormal(int size) {
        SDKCall(g_hSDKCall_SetullSizeNormal, this, size);
    }
}

methodmap CBaseEntity {
    public static void SetNextThink(Address pThis, float flNextThinkTime, const char[] szContext) {
        SDKCall(g_hSDKCall_SetNextThink, pThis, flNextThinkTime, szContext);
    }
}

void LoadGameData()
{
    GameDataWrapper gd = new GameDataWrapper("nmrih_skins");

    g_hDetour = gd.CreateDetourOrFail("CNMRiH_TurnedZombie_Watcher::TurnThink", true, DTR_CNMRiH_TurnedZombie_Watcher_TurnThink_Pre);
    g_pEntityList = gd.GetAddress("g_pEntityList");

    g_iOff_TurnedZombieEntry_t_size = gd.GetOffset("sizeof(TurnedZombieEntry_t)");
    g_iOff_m_TurnedZombieEntry = gd.GetOffset("CNMRiH_TurnedZombie_Watcher->m_TurnedZombieEntry");
    g_iOff_m_hRagDollHandle = gd.GetOffset("TurnedZombieEntry_t->m_hRagDollHandle");
    g_iOff_m_vecTurnedPosition = gd.GetOffset("TurnedZombieEntry_t->m_vecTurnedPosition");
    g_iOff_m_angTurnedAngle = gd.GetOffset("TurnedZombieEntry_t->m_angTurnedAngle");
    g_iOff_m_flTurnedTime = gd.GetOffset("TurnedZombieEntry_t->m_flTurnedTime");
    g_iOff_m_szModel = gd.GetOffset("TurnedZombieEntry_t->m_szModel");

    SDKCallParamsWrapper param1[] = {{SDKType_CBaseEntity, SDKPass_Pointer}};
    g_hSDKCall_UTIL_RemoveImmediate = gd.CreateSDKCallOrFail(SDKCall_Static, SDKConf_Signature, "UTIL_RemoveImmediate", param1, sizeof(param1));

    g_hSDKCall_InitRelationshipTable = gd.CreateSDKCallOrFail(SDKCall_Entity, SDKConf_Signature, "CAI_BaseNPC::InitRelationshipTable");

    SDKCallParamsWrapper param2[] = {{SDKType_PlainOldData, SDKPass_Plain}};
    g_hSDKCall_SetCondition = gd.CreateSDKCallOrFail(SDKCall_Entity, SDKConf_Signature, "CAI_BaseNPC::SetCondition", param2, sizeof(param2));

    SDKCallParamsWrapper param3[] = {{SDKType_String, SDKPass_Pointer}};
    g_hSDKCall_SetSequenceByName = gd.CreateSDKCallOrFail(SDKCall_Entity, SDKConf_Signature, "CAI_BaseNPC::SetSequenceByName", param3, sizeof(param3));

    SDKCallParamsWrapper param4[] = {{SDKType_Float, SDKPass_Plain}, {SDKType_String, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL}}
    g_hSDKCall_SetNextThink = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Signature, "CBaseEntity::SetNextThink", param4, sizeof(param4));

    SDKCallParamsWrapper param5[] = {{SDKType_PlainOldData, SDKPass_Plain}};
    g_hSDKCall_SetullSizeNormal = gd.CreateSDKCallOrFail(SDKCall_Entity, SDKConf_Signature, "CAI_BaseNPC::SetCondition", param5, sizeof(param5));

    delete gd;
}

// for some reason, entity nmrih_turnedzombie_watcher can not return a valid index or ref.
// so we call these by raw address.
// I still have no better idea than rebuilding the whole think function
// to find the specific turned zombie & player relationship, and set the model. perhaps this is the only reasonable way.
MRESReturn DTR_CNMRiH_TurnedZombie_Watcher_TurnThink_Pre(Address pThis)
{
    // fun fact: this is: for (int i = 0; i < MaxClients; i++)
    // On CNMRiH_TurnedZombie_Watcher::RegisterPlayerTurnInfo,
    // infected player's edict index is used to fill the corresponding entry in the watcher's m_TurnedZombieEntry array.
    // this is why we can locate exactly the infected player's entry by looping through the array.
    for (int i = 0; i < NMR_MAXPLAYERS; i++)
    {
        TurnedZombieEntry_t entry = CNMRiH_TurnedZombie_Watcher(pThis).GetEntry(i);
        if (entry.m_flTurnedTime != -1.0 && GetGameTime() > entry.m_flTurnedTime)
        {
            any hndl = entry.m_hRagDollHandle;
            if (hndl != INVALID_EHANDLE_INDEX)
            {
                Address pEntInfo = Address_Null;
                if (HasSerialNumber(hndl, pEntInfo))
                {
                    Address pEntity = LoadFromAddress(pEntInfo + view_as<Address>(4), NumberType_Int32);
                    UTIL_RemoveImmediate(pEntity);
                }
            }

            int npc_nmrih_turnedzombie = CreateEntityByName("npc_nmrih_turnedzombie");
            if (npc_nmrih_turnedzombie != INVALID_ENT_REFERENCE && IsValidEntity(npc_nmrih_turnedzombie))
            {
                float vec[3];
                entry.GetTurnedPosition(vec);
                vec[2] += 20.0; // move the turned zombie up a bit to avoid clipping into the ground.
                DispatchKeyValueVector(npc_nmrih_turnedzombie, "origin", vec);

                float ang[3];
                entry.GetTurnedAngle(ang);
                DispatchKeyValueVector(npc_nmrih_turnedzombie, "angle", ang);

                //PrintToServer("origin: %.02f, %.02f, %.02f / angle: %.02f, %.02f, %.02f", vec[0], vec[1], vec[2], ang[0], ang[1], ang[2]);
                
                //char sModel[260];
                //entry.GetModelName(sModel, sizeof(sModel));
                //PrintToServer("Original Model: %s", sModel);
                //PrintToServer("Setting Turned Model: %s, %d", g_sTurnedModel[i + 1], i + 1);

                CAI_BaseNPC npc = CAI_BaseNPC(npc_nmrih_turnedzombie);
                npc.InitRelationshipTable();
                DispatchSpawn(npc_nmrih_turnedzombie);

                if (strcmp(g_sTurnedModel[i + 1], "") != 0 && g_bCVar[CV_UseTurned])
                {
                    SetEntityModel(npc_nmrih_turnedzombie, g_sTurnedModel[i + 1]);
                }
                else
                {
                    int random = GetRandomInt(0, sizeof(g_sDefaultTurnedModel) - 1);
                    SetEntityModel(npc_nmrih_turnedzombie, g_sDefaultTurnedModel[random]);                            
                }

                npc.SetHullSizeNormal(1);
                npc.SetCondition(88);
                npc.SetSequenceByName("infectionrise");

                entry.m_hRagDollHandle = view_as<Address>(INVALID_EHANDLE_INDEX);
                entry.SetTurnedAngle({0.0, 0.0, 0.0});
                entry.SetTurnedPosition({0.0, 0.0, 0.0});
                entry.m_flTurnedTime = -1.0;

                // should we need to empty the string?
                // though it may not be safe with sourcepawn.
            }
        }
    }

    CBaseEntity.SetNextThink(pThis, GetGameTime() + 0.30000001, NULL_STRING);
    return MRES_Supercede;
}

void UTIL_RemoveImmediate(Address pEntity)
{
    if (pEntity == Address_Null)
        return;

    SDKCall(g_hSDKCall_UTIL_RemoveImmediate, pEntity);
}

#if 0
inline IHandleEntity* CBaseHandle::Get() const
{
	extern CBaseEntityList *g_pEntityList;
	return g_pEntityList->LookupEntity( *this );
}

inline IHandleEntity* CBaseEntityList::LookupEntity( const CBaseHandle &handle ) const
{
	if ( handle.m_Index == INVALID_EHANDLE )
		return NULL;

	const CEntInfo *pInfo = &m_EntPtrArray[ handle.GetEntryIndex() ];
	if ( pInfo && pInfo->m_SerialNumber == handle.GetSerialNumber() )
		return pInfo->m_pEntity;
	else
		return NULL;
}
#endif
stock bool HasSerialNumber(any handle, Address &pEntInfo = Address_Null)
{
	int ent = handle & 0xFFF;
	if (ent == 0xFFF)
		return false;

    pEntInfo = view_as<Address>(ent * 16) + g_pEntityList;
    return (LoadFromAddress(pEntInfo + view_as<Address>(8), NumberType_Int32) == (handle >> 12) + 1);
}
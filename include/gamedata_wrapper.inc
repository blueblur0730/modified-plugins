#if defined _gamedata_wrapper_included
    #endinput
#endif
#define _gamedata_wrapper_included

#include <sourcemod>

enum OperatingSystem
{
    OS_Unknown_Copy = -1,
    OS_Windows = 0,
    OS_Linux = 1
}

#if defined _sdktools_included
enum struct SDKCallParamsWrapper {
    SDKType          type;
    SDKPassMethod    pass;
    int              decflags;
    int              encflags;
}

static const char k_sSDKFuncConfSource[3][] = { "Offsets", "Signatures", "Addresses" };
#endif

// credits to Forgetest.
methodmap GameDataWrapper < GameData {
    public GameDataWrapper(const char[] file) {
        GameData gd = new GameData(file);
        if (!gd) SetFailState("[GameData] Missing gamedata of file \"%s\".", file);
        return view_as<GameDataWrapper>(gd);
    }

    property GameData Super {
        public get() { return view_as<GameData>(this); }
    }

    property OperatingSystem OS {
        public get() { return view_as<OperatingSystem>(this.Super.GetOffset("OS")); }
    }

    public int GetOffset(const char[] key) {
        int offset = this.Super.GetOffset(key);
        if (offset == -1) SetFailState("[GameData] Missing offset of section \"%s\".", key);
        return offset;
    }

    public void GetKeyValue(const char[] key, char[] buffer, int maxlen) {
        bool b = this.Super.GetKeyValue(key, buffer, maxlen);
        if (!b) SetFailState("[GameData] Missing key \"%s\" in gamedata file.", key);
    }

    public Address GetAddress(const char[] key) {
        Address ptr = this.Super.GetAddress(key);
        if (ptr == Address_Null) SetFailState("[GameData] Missing address of section \"%s\".", key);
        return ptr;
    }

    public Address GetMemSig(const char[] key) {
        Address ptr = this.Super.GetMemSig(key);
        if (ptr == Address_Null) SetFailState("[GameData] Missing signature memory of section \"%s\".", key);
        return ptr;
    }

#if defined _sdktools_included
    /**
     * Creates a call from conf file.
     * 
     * @param type              The type of the call.
     * @param src               The source section to retrieve from the gamedata config.
     * @param name              The name of the call.
     * @param params            The parameters of the call.
     * @param numParams         The number of parameters.
     * @param hasReturnValue    Whether the call has a return value.
     * 
     * @return Handle of the call.
     **/ 
    public Handle CreateSDKCallOrFail(
        SDKCallType type,
        SDKFuncConfSource src,
        const char[] name,
        const SDKCallParamsWrapper[] params = {},
        int numParams = 0,
        bool hasReturnValue = false,
        const SDKCallParamsWrapper ret = {})
    {
        Handle result;
        StartPrepSDKCall(type);
        if (!PrepSDKCall_SetFromConf(this, src, name))
            SetFailState("[SDKCall] Missing key \"%s\" from section \"%s\".", name, k_sSDKFuncConfSource[src]);

        for (int i = 0; i < numParams; ++i)
            PrepSDKCall_AddParameter(params[i].type, params[i].pass, params[i].decflags, params[i].encflags);

        if (hasReturnValue)
            PrepSDKCall_SetReturnInfo(ret.type, ret.pass, ret.decflags, ret.encflags);

        if (!(result = EndPrepSDKCall()))
            SetFailState("[SDKCall] Failed to Prepare SDKCall for section \"%s\".", name);

        return result;
    }

    /**
     * Use relative call address to setup call instead of setting from conf.
     * 
     * @param type              The type of the call.
     * @param pFuncStart        The start address of the relative call function.
     * @param offset            The offset to jump back from the relative call.
     * @param params            The parameters of the call.
     * @param numParams         The number of parameters.
     * @param hasReturnValue    Whether the call has a return value.
     * @param ret               The return value of the call.
     * 
     * @returns Handle          The handle of the call.
    */
    public static Handle CreateSDKCallOrFailEx(
        SDKCallType type,
        Address pFuncStart,
        int offset,
        const SDKCallParamsWrapper[] params = {},
        int numParams = 0,
        bool hasReturnValue = false,
        const SDKCallParamsWrapper ret = {})
    {
        int pOri = LoadFromAddress(pFuncStart, NumberType_Int32);
        pFuncStart += view_as<Address>(pOri + offset);

        Handle result;
        StartPrepSDKCall(type);
        PrepSDKCall_SetAddress(pFuncStart);

        for (int i = 0; i < numParams; ++i)
            PrepSDKCall_AddParameter(params[i].type, params[i].pass, params[i].decflags, params[i].encflags);

        if (hasReturnValue)
            PrepSDKCall_SetReturnInfo(ret.type, ret.pass, ret.decflags, ret.encflags);

        if (!(result = EndPrepSDKCall()))
            SetFailState("[SDKCall] Failed to Prepare SDKCall for a raw address call.");

        return result;
    }
#endif

#if defined _dhooks_included
    public DynamicDetour CreateDetourOrFail(
            const char[] name,
            bool bNow = true,
            DHookCallback preHook = INVALID_FUNCTION,
            DHookCallback postHook = INVALID_FUNCTION) 
    {
        DynamicDetour hSetup = DynamicDetour.FromConf(this, name);

        if (!hSetup)
            SetFailState("[Detour] Missing detour setup section \"%s\".", name);

        if (bNow)
        {
            if (preHook != INVALID_FUNCTION && !hSetup.Enable(Hook_Pre, preHook))
                SetFailState("[Detour] Failed to pre-detour of section \"%s\".", name);

            if (postHook != INVALID_FUNCTION && !hSetup.Enable(Hook_Post, postHook))
                SetFailState("[Detour] Failed to post-detour of section \"%s\".", name);
        }

        return hSetup;
    }

    /**
     * Creates a detour, and free its handle. (meaning the detour will never be disabled.)
     * 
     * @param name              The name of the detour setup section.
     * @param bNow              Whether to enable the detour immediately.
     * @param preHook           The pre-hook function.
     * @param postHook          The post-hook function.
     * 
     * @noreturn
    */
    public void CreateDetourOrFailEx(
            const char[] name,
            DHookCallback preHook = INVALID_FUNCTION,
            DHookCallback postHook = INVALID_FUNCTION) {
        delete (this.CreateDetourOrFail(name, true, preHook, postHook));
    }

    // create a dynamic hook from conf, specify the hook type and hooks the target.
    public DynamicHook CreateDynamicHookOrFail(
            const char[] name,
            HookType type,
            int entity = -1,
            Address pAdr = Address_Null,
            bool bNow = true,
            DHookCallback preHook = INVALID_FUNCTION,
            DHookCallback postHook = INVALID_FUNCTION,
            DHookRemovalCB removalHook = INVALID_FUNCTION)
    {
        DynamicHook hSetup = DynamicHook.FromConf(this, name);

        if (!hSetup)
            SetFailState("[DHooks] Missing dynamic hook setup section \"%s\".", name);

        if (!bNow)
            return hSetup;

        switch (type)
        {
            case HookType_Entity:
            {
                if (entity == -1) SetFailState("[DHooks] Invalid entity index for section \"%s\".", name);

                if (preHook != INVALID_FUNCTION && !hSetup.HookEntity(Hook_Pre, entity, preHook, removalHook))
                    SetFailState("[DHooks] Failed to pre-dhook section \"%s\".", name);

                if (postHook != INVALID_FUNCTION && !hSetup.HookEntity(Hook_Post, entity, postHook, removalHook))
                    SetFailState("[DHooks] Failed to post-dhook section \"%s\".", name);
            }
            
            case HookType_GameRules:
            {
                if (preHook != INVALID_FUNCTION && !hSetup.HookGamerules(Hook_Pre, preHook, removalHook))
                    SetFailState("[DHooks] Failed to pre-dhook section \"%s\".", name);

                if (postHook != INVALID_FUNCTION && !hSetup.HookGamerules(Hook_Post, postHook, removalHook))
                    SetFailState("[DHooks] Failed to post-dhook section \"%s\".", name);
            }

            case HookType_Raw:
            {
                if (pAdr == Address_Null) SetFailState("[DHooks] Invalid address for section \"%s\".", name);
                
                if (preHook != INVALID_FUNCTION && !hSetup.HookRaw(Hook_Pre, pAdr, preHook))
                    SetFailState("[DHooks] Failed to pre-dhook section \"%s\".", name);

                if (postHook != INVALID_FUNCTION && !hSetup.HookRaw(Hook_Post, pAdr, postHook))
                    SetFailState("[DHooks] Failed to post-dhook section \"%s\".", name);
            }
        }

        return hSetup;
    }

    public DynamicHook CreateDynamicHookOrFailEx(
            const char[] name,
            HookType type,
            int entity = -1,
            Address pAdr = Address_Null,
            DHookCallback preHook = INVALID_FUNCTION,
            DHookCallback postHook = INVALID_FUNCTION,
            DHookRemovalCB removalHook = INVALID_FUNCTION)
    {
        delete (this.CreateDynamicHookOrFail(name, type, entity, pAdr, true, preHook, postHook, removalHook));
    }
#endif

#if defined __sourcescramble_ext_included
    public MemoryPatch CreateMemoryPatchOrFail(const char[] name, bool enable = false) {
        MemoryPatch hPatch = MemoryPatch.CreateFromConf(this, name);
        if (!(enable ? hPatch.Enable() : hPatch.Validate()))
            SetFailState("[MemoryPatch] Failed to patch section \"%s\" through source scramble.", name);

        return hPatch;
    }

    public void CreateMemoryPatchOrFailEx(const char[] name) {
        delete (this.CreateMemoryPatchOrFail(name));
    }

    public MemoryBlock CreateMemoryBlockOrFail(const char[] name) {
        int iOff = this.Super.GetOffset(name);
        MemoryBlock hBlock = new MemoryBlock(iOff);
        if (!hBlock) SetFailState("[MemoryBlock] Failed to create memory block for section \"%s\".", name);
    }
#endif

#if defined _midhook_included
    public MidHook CreateMidHookOrFail(const char[] name, MidHookCB callback, bool enable = true) {
        Address pAdr = this.GetAddress(name);
        MidHook hHook = new MidHook(pAdr, callback, enable);
        if (!hHook) SetFailState("[MidHooks] Failed to create Midhook for section \"%s\".", name);

        return hHook;
    }

    public void CreateMidHookOrFailEx(const char[] name, MidHookCB callback) {
        delete (this.CreateMidHookOrFail(name, callback, true));
    }
#endif
}
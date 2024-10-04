#if defined _gamedata_wrapper_
    #endinput
#endif
#define _gamedata_wrapper_

#include <sourcemod>
#include <sdktools>
#include <dhooks>
#tryinclude <sourcescramble>
#tryinclude <midhook>

enum OperatingSystem
{
    OS_Windows = 0,
    OS_Linux = 1
}

enum struct SDKCallParamsWrapper
{
    SDKType          type;
    SDKPassMethod    pass;
    int              decflags;
    int              encflags;
}

// credits to Forgetest.
methodmap GameDataWrapper < GameData
{
    public GameDataWrapper(const char[] file) {
        GameData gd = new GameData(file);
        if (!gd) SetFailState("Missing gamedata \"%s\"", file);
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
        if (offset == -1) SetFailState("Missing offset \"%s\"", key);
        return offset;
    }

    public Address GetAddress(const char[] key) {
        Address ptr = this.Super.GetAddress(key);
        if (ptr == Address_Null) SetFailState("Missing address \"%s\"", key);
        return ptr;
    }

    public Handle CreateSDKCallOrFail(
        SDKCallType type,
        SDKFuncConfSource src,
        const char[] name,
        const SDKCallParamsWrapper[] params = {},
        int numParams = 0,
        bool hasReturnValue = false,
        const SDKCallParamsWrapper ret = {})
    {
        static const char k_sSDKFuncConfSource[SDKFuncConfSource][] = { "offset", "signature", "address" };
        Handle result;
        StartPrepSDKCall(type);
        if (!PrepSDKCall_SetFromConf(this, src, name))
            SetFailState("Missing %s \"%s\"", k_sSDKFuncConfSource[src], name);

        for (int i = 0; i < numParams; ++i)
            PrepSDKCall_AddParameter(params[i].type, params[i].pass, params[i].decflags, params[i].encflags);

        if (hasReturnValue)
            PrepSDKCall_SetReturnInfo(ret.type, ret.pass, ret.decflags, ret.encflags);

        if (!(result = EndPrepSDKCall()))
            SetFailState("Failed to Prepare SDKCall \"%s\"", name);

        return result;
    }

    // use relative call address to setup call instead of setting from conf.
    public Handle CreateSDKCallOrFailEx(
        SDKCallType type,
        const char[] name,
        const SDKCallParamsWrapper[] params = {},
        int numParams = 0,
        bool hasReturnValue = false,
        const SDKCallParamsWrapper ret = {})
    {
        // first we check the address, if failed, do not start to prepare.
        Address pFunc = this.GetAddress(name);
        int offset = LoadFromAddress(pFunc, NumberType_Int32);
        pFunc += view_as<Address>(offset + 4);

        Handle result;
        StartPrepSDKCall(type);
        PrepSDKCall_SetAddress(pFunc);

        for (int i = 0; i < numParams; ++i)
            PrepSDKCall_AddParameter(params[i].type, params[i].pass, params[i].decflags, params[i].encflags);

        if (hasReturnValue)
            PrepSDKCall_SetReturnInfo(ret.type, ret.pass, ret.decflags, ret.encflags);

        if (!(result = EndPrepSDKCall()))
            SetFailState("Failed to Prepare SDKCall \"%s\"", name);

        return result;
    }

    public DynamicDetour CreateDetourOrFail(
            const char[] name,
            DHookCallback preHook = INVALID_FUNCTION,
            DHookCallback postHook = INVALID_FUNCTION) 
    {
        DynamicDetour hSetup = DynamicDetour.FromConf(this, name);

        if (!hSetup)
            SetFailState("Missing detour setup \"%s\"", name);

        if (preHook != INVALID_FUNCTION && !hSetup.Enable(Hook_Pre, preHook))
            SetFailState("Failed to pre-detour \"%s\"", name);

        if (postHook != INVALID_FUNCTION && !hSetup.Enable(Hook_Post, postHook))
            SetFailState("Failed to post-detour \"%s\"", name);

        return hSetup;
    }

#if defined __sourcescramble_ext_included
    public MemoryPatch CreatePatchOrFail(const char[] name, bool enable = false) {
        MemoryPatch hPatch = MemoryPatch.CreateFromConf(this, name);
        if (!(enable ? hPatch.Enable() : hPatch.Validate()))
            SetFailState("Failed to patch \"%s\" through source scramble", name);

        return hPatch;
    }
#endif

#if defined _midhook_included
    public MidHook CreateMidHookOrFail(const char[] name, MidHookCB callback, bool enable=true) {
        Address pAdr = this.GetAddress(name);
        MidHook hHook = new MidHook(pAdr, callback, enable);
        if (!hHook) SetFailState("Failed to create Midhook for key \"%s\"", name);

        return hHook;
    }
#endif
}
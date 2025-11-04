
static int g_iOff__m_pStudioHdr = -1;

static int g_iOff__cstudiohdr_t = -1;
static int g_iOff__cstudiohdr_t__numbodyparts = -1;
static int g_iOff__cstudiohdr_t__bodypartindex = -1;

static int g_iOff__mstudiobodyparts_t__nummodls = -1;
static int g_iOff__mstudiobodyparts_t__base = -1;
static int g_iOff__mstudiobodyparts_t__sznameindex = -1;
static int g_iOff__mstudiobodyparts_t__modelindex = -1;

static int g_iOff__mstudiomodel_t__name = -1; 

methodmap CBaseAnimating {
	public CBaseAnimating(int entity) {
		return view_as<CBaseAnimating>(entity);
	}

	property int index {
		public get() {
			return view_as<int>(this);
		}
	}

	public int GetBodyGroup(int iGroup) {
		return __GetBodyGroup(this.index, iGroup);
	}

	public void SetBodyGroup(int iGroup, int iValue) {
		__SetBodyGroup(this.index, iGroup, iValue);
	}

	public int FindBodygroupByName(const char[] szName) {
		return __FindBodygroupByName(this.index, szName);
	}

	public int GetNumBodyGroups() {
		return __GetNumBodyGroups(this.index);
	}

	public int GetBodyGroupCount(int iGroup) {
		return __GetBodygroupCount(this.index, iGroup);
	}

	public void GetBodyGroupName(int iGroup, char[] szName, int maxlen) {
		__GetBodygroupName(this.index, iGroup, szName, maxlen);
	}

	// not implemented in nmrih.
	public void GetBodyGroupPartName(int iGroup, int iPart, char[] szName, int maxlen) {
		__GetBodygroupPartName(this.index, iGroup, iPart, szName, maxlen);
	}
}

// error 109: methodmap name must start with an uppercase letter, LOL.
methodmap STRUCT__cstudiohdr_t < AddressBase {
	public static STRUCT__cstudiohdr_t GetRenderHdr(int client) {
		return view_as<STRUCT__cstudiohdr_t>(__GetStudioHdr(client));
	}

	property int numbodyparts {
		public get() {
			return LoadFromAddress(this.addr + g_iOff__cstudiohdr_t__numbodyparts, NumberType_Int32);
		}
	}

	property int bodypartindex {
		public get() {
			return LoadFromAddress(this.addr + g_iOff__cstudiohdr_t__bodypartindex, NumberType_Int32);
		}
	}

	public STRUCT__mstudiobodyparts_t pBodyPart(int i) {
		return view_as<STRUCT__mstudiobodyparts_t>(this.addr + this.bodypartindex + (16 * i));
	}
}

methodmap STRUCT__mstudiobodyparts_t < AddressBase {
	property int nummodels {
		public get() {
			return LoadFromAddress(this.addr + g_iOff__mstudiobodyparts_t__nummodls, NumberType_Int32);
		}
	}

	property int base {
		public get() {
			return LoadFromAddress(this.addr + g_iOff__mstudiobodyparts_t__base, NumberType_Int32);
		}
	}

	public void pszName(char[] name, int maxlen) {
		Stringt(this.addr + LoadFromAddress(this.addr + g_iOff__mstudiobodyparts_t__sznameindex, NumberType_Int32)).ToCharArray(name, maxlen);
	}

	property int modelindex {
		public get() {
			return LoadFromAddress(this.addr + g_iOff__mstudiobodyparts_t__modelindex, NumberType_Int32);
		}
	}

	// this was token from l4d2 decompiled binaries.
	public STRUCT__mstudiomodel_t pModel(int i) {
		return view_as<STRUCT__mstudiomodel_t>(this.addr + this.modelindex + (148 * i));
	}
}

methodmap STRUCT__mstudiomodel_t < AddressBase {
	public void name(char[] name, int maxlen) {
		Stringt(this.addr + g_iOff__mstudiomodel_t__name).ToCharArray(name, maxlen);
	}
}

void LoadBodyGroupGameData()
{
    GameDataWrapper gd = new GameDataWrapper("nmrih_skins");

	g_iOff__m_pStudioHdr = gd.GetOffset("CBaseAnimating->m_pStudioHdr");

	g_iOff__cstudiohdr_t = gd.GetOffset("CStudioHdr->cstudiohdr_t");
	g_iOff__cstudiohdr_t__numbodyparts = gd.GetOffset("cstudiohdr_t->numbodyparts");
	g_iOff__cstudiohdr_t__bodypartindex = gd.GetOffset("cstudiohdr_t->bodypartindex");

	g_iOff__mstudiobodyparts_t__nummodls = gd.GetOffset("mstudiobodyparts_t->nummodels");
	g_iOff__mstudiobodyparts_t__base = gd.GetOffset("mstudiobodyparts_t->base");
	g_iOff__mstudiobodyparts_t__sznameindex = gd.GetOffset("mstudiobodyparts_t->sznameindex");
	g_iOff__mstudiobodyparts_t__modelindex = gd.GetOffset("mstudiobodyparts_t->modelindex");

	g_iOff__mstudiomodel_t__name = gd.GetOffset("mstudiomodel_t->name");

    delete gd;
}

static int __GetNumBodyGroups(int client)
{
	STRUCT__cstudiohdr_t studiohdr_t = STRUCT__cstudiohdr_t.GetRenderHdr(client);
	if (studiohdr_t.IsNull())
		return -1;

	return studiohdr_t.numbodyparts;
}

static void __SetBodyGroup(int client, int iGroup, int iValue)
{
	STRUCT__cstudiohdr_t studiohdr_t = STRUCT__cstudiohdr_t.GetRenderHdr(client);
	if (studiohdr_t.IsNull())
		return;

	if (iGroup < 0 || iGroup >= studiohdr_t.numbodyparts)
		return;

	STRUCT__mstudiobodyparts_t studiobodyparts_t = studiohdr_t.pBodyPart(iGroup);
	if (studiobodyparts_t.IsNull())
		return;

	int nummodels = studiobodyparts_t.nummodels;
	if (iValue >= nummodels)
		return;

	int m_nBody = GetEntProp(client, Prop_Send, "m_nBody");
	int base = studiobodyparts_t.base;
	int iCurrent = (m_nBody / base) % nummodels;

	m_nBody = (m_nBody - (iCurrent * base) + (iValue * base));
	SetEntProp(client, Prop_Send, "m_nBody", m_nBody);
}

static int __GetBodyGroup(int client, int iGroup)
{
	STRUCT__cstudiohdr_t studiohdr_t = STRUCT__cstudiohdr_t.GetRenderHdr(client);
	if (studiohdr_t.IsNull())
		return -1;

	if (iGroup < 0 || iGroup >= studiohdr_t.numbodyparts)
		return -1;

	STRUCT__mstudiobodyparts_t studiobodyparts_t = studiohdr_t.pBodyPart(iGroup);
	if (studiobodyparts_t.IsNull())
		return -1;

	int nummodels = studiobodyparts_t.nummodels;
	if (nummodels <= 1)
		return -1;

	int m_nBody = GetEntProp(client, Prop_Send, "m_nBody");
	int base = studiobodyparts_t.base;
	int iCurrent = (m_nBody / base) % nummodels;

	return iCurrent;
}

static void __GetBodygroupName(int client, int iGroup, char[] name, int maxlen)
{
	STRUCT__cstudiohdr_t studiohdr_t = STRUCT__cstudiohdr_t.GetRenderHdr(client);
	if (studiohdr_t.IsNull())
		return;

	if (iGroup < 0 || iGroup >= studiohdr_t.numbodyparts)
		return;

	STRUCT__mstudiobodyparts_t studiobodyparts_t = studiohdr_t.pBodyPart(iGroup);
	if (studiobodyparts_t.IsNull())
		return;

	studiobodyparts_t.pszName(name, maxlen);
}

static void __GetBodygroupPartName(int client, int iGroup, int iPart, char[] name, int maxlen)
{
	STRUCT__cstudiohdr_t studiohdr_t = STRUCT__cstudiohdr_t.GetRenderHdr(client);
	if (studiohdr_t.IsNull())
		return;

	if (iGroup < 0 || iGroup >= studiohdr_t.numbodyparts)
		return;

	STRUCT__mstudiobodyparts_t studiobodyparts_t = studiohdr_t.pBodyPart(iGroup);
	if (studiobodyparts_t.IsNull())
		return;

	if (iPart < 0 && iPart >= studiobodyparts_t.nummodels)
		return;

	STRUCT__mstudiomodel_t studiomodel_t = studiobodyparts_t.pModel(iPart);
	if (studiomodel_t.IsNull())
		return;

	studiomodel_t.name(name, maxlen);
}

static int __GetBodygroupCount(int client, int iGroup)
{
	STRUCT__cstudiohdr_t studiohdr_t = STRUCT__cstudiohdr_t.GetRenderHdr(client);
	if (studiohdr_t.IsNull())
		return -1;

	if (iGroup < 0 || iGroup >= studiohdr_t.numbodyparts)
		return -1;

	STRUCT__mstudiobodyparts_t studiobodyparts_t = studiohdr_t.pBodyPart(iGroup);
	if (studiobodyparts_t.IsNull())
		return -1;

	return studiobodyparts_t.nummodels;
}

static int __FindBodygroupByName(int client, const char[] szName)
{
	STRUCT__cstudiohdr_t studiohdr_t = STRUCT__cstudiohdr_t.GetRenderHdr(client);
	if (studiohdr_t.IsNull())
		return -1;

	int iGroup = 0;
	for (iGroup = 0; iGroup < studiohdr_t.numbodyparts; iGroup++)
	{
		STRUCT__mstudiobodyparts_t studiobodyparts_t = studiohdr_t.pBodyPart(iGroup);
		if (studiobodyparts_t.IsNull())
			continue;

		char szBodygroupName[256];
		studiobodyparts_t.pszName(szBodygroupName, sizeof(szBodygroupName));

		if (strcmp(szBodygroupName, szName) == 0)
			return iGroup;
	}

	return -1;
}

static Address __GetModelPtr(int client)
{
	return view_as<Address>(GetEntData(client, g_iOff__m_pStudioHdr));
}

static STRUCT__cstudiohdr_t __GetStudioHdr(int client)
{
	if (__GetModelPtr(client) == Address_Null)
		return view_as<STRUCT__cstudiohdr_t>(Address_Null);

	return LoadFromAddress(__GetModelPtr(client) + view_as<Address>(g_iOff__cstudiohdr_t), NumberType_Int32);
}
/** Double-include prevention */
#if defined _utl_map_included
    #endinput
#endif
#define _utl_map_included

#include <sdktools>
#include <address_base>
#include "tier1/utl_rbtree.inc"

#pragma newdecls required
#pragma semicolon 1

#define UTL_MAP_TAG "[UtlMap]"
#define UTL_MAP_VERSION "1.0.2"

/**
 * Author: blueblur
 * Date: 2025-11-13
 * url: https://github.com/blueblur0730/modified-plugins
 * Version: 1.0.2
*/

/*
    template <typename K, typename T, typename I = unsigned short, typename LessFunc_t = bool (*)( const K &, const K & )> 

    typedef K KeyType_t;
	typedef T ElemType_t;
	typedef I IndexType_t;

    // size is sizeof(key) + sizeof(elem);
	struct Node_t
	{
		Node_t()
		{
		}

		Node_t( const Node_t &from )
		  : key( from.key ),
			elem( from.elem )
		{
		}

		KeyType_t	key;
		ElemType_t	elem;
	};
	
	class CKeyLess
	{
	public:
		CKeyLess( const LessFunc_t& lessFunc ) : m_LessFunc(lessFunc) {}

		bool operator!() const
		{
			return !m_LessFunc;
		}

		bool operator()( const Node_t &left, const Node_t &right ) const
		{
			return m_LessFunc( left.key, right.key );
		}

		LessFunc_t m_LessFunc;
	};

	typedef CUtlRBTree<Node_t, I, CKeyLess> CTree;

protected:
	CTree 	   m_Tree;
*/

/**
 * User defined destructor function for UtlRBTree elements.
 * 
 * @param vec           The Pointer to the UtlMap.
 * @param elem          The element to be destroyed.
 * @param addr          The address of the element.
 * @param obj           The object that the element owns.
 * @param size          The size of the object.
*/
typedef UtlMapDestructorFunc = function void (UtlMap vec, int i, any addr, any obj, int size);

methodmap Node_t < AddressBase {
    public Node_t(Address addr) {
        Node_t p = view_as<Node_t>(addr);

        if (p.IsNull()) {
            ThrowError("Invalid Node_t address");
        }

        return p;
    }

    public any GetKey(NumberType elementSize = NumberType_Int32) {
        return LoadFromAddress(this.addr, elementSize);
    }

    public any GetKeyEx() {
        return this.addr;
    }

    public void SetKey(any value, NumberType elementSize = NumberType_Int32) {
        StoreToAddress(this.addr, value, elementSize);
    }

    public any GetElem(int keySize, NumberType elementSize = NumberType_Int32) {
        return LoadFromAddress(this.addr + keySize, elementSize);
    }

    public any GetElemEx(int keySize) {
        return this.addr + keySize;
    }

    public void SetElem(any value, int keySize, NumberType elementSize = NumberType_Int32) {
        StoreToAddress(this.addr + keySize, value, elementSize);
    }
}

methodmap UtlMap < AddressBase {
    public UtlMap(Address addr) {
        UtlMap p = view_as<UtlMap>(addr);

        if (p.IsNull()) {
            ThrowError("Invalid UtlMap address");
        }

        return p;
    }

    property UtlRBTree m_Tree {
        public get() {
            return view_as<UtlRBTree>(this.addr);
        }
#if defined _smmem_included_
/*
        public set(UtlRBTree value) {
            StoreToAddress(this.addr, value, NumberType_Int32);
        }
*/
#endif
    }

    public any GetElement(int i, int size, int keySize, NumberType elementSize = NumberType_Int32) {
        return view_as<Node_t>(this.m_Tree.GetEx(i, size) + 8).GetElem(keySize, elementSize);
    }

    public any GetElementEx(int i, int size, int keySize) {
        return view_as<Node_t>(this.m_Tree.GetEx(i, size) + 8).GetElemEx(keySize);
    }

    public void SetElement(int i, any value, int size, int keySize, NumberType elementSize = NumberType_Int32) {
        view_as<Node_t>(this.m_Tree.GetEx(i, size) + 8).SetElem(value, keySize, elementSize);
    }

    public any GetKey(int i, int size, NumberType elementSize = NumberType_Int32) {
        return view_as<Node_t>(this.m_Tree.GetEx(i, size) + 8).GetKey(elementSize);
    }

    public any GetKeyEx(int i, int size) {
        return view_as<Node_t>(this.m_Tree.GetEx(i, size) + 8).GetKeyEx();
    }

    public void SetKey(int i, any value, int size, NumberType elementSize = NumberType_Int32) {
        view_as<Node_t>(this.m_Tree.GetEx(i, size) + 8).SetKey(value, elementSize);
    }

    public any Element(int i, int size, int keySize, NumberType elementSize = NumberType_Int32) {
        return this.GetElement(i, size, keySize, elementSize);
    }

    public any Key(int i, int size, NumberType elementSize = NumberType_Int32) {
        return this.GetKey(i, size, elementSize);
    }

    public int Count() {
        return this.m_Tree.Count();
    }

    public int MaxElement() {
        return this.m_Tree.MaxElement();
    }

    public bool IsValidIndex(int i) {
        return this.m_Tree.IsValidIndex(i);
    }

    public bool IsValid() {
        return this.m_Tree.IsValid();
    }

    public static int InvalidIndex() {
        return UtlRBTree.InvalidIndex();
    }

    public void SetLessFunc(any lessFunc) {
        this.m_Tree.SetLessFunc(lessFunc);
    }


// we can't allocte memory in the stack!!!
// the following functions creates a local variable of type Node_t, but we can't do this on sourcepawn.

// assume the folowing code works. but it's not tested and is dangerous!!! we are doing it on the heap instead of stack
// note: key and insert is an object, not a pointer. we will not load it from the pointer here.
#if defined __sourcescramble_ext_included
    public int Insert(any key, int keySize, any insert, int insertSize, NumberType numberType = NumberType_Int32, UtlRBTreeConstructorFunc constructor) {
        // calloc a block of memory for the Node_t, the size is determined by the template type!
        // here, the param 'size' is sizeof(key) + sizeof(elem).
        MemoryBlock memory = new MemoryBlock(keySize + insertSize);

        // get its pointer address.
        any addr = memory.Address;

        // Check the pointer, make sure it is not null.
        if (!addr) {
            delete memory;
            Assert_Zero(UTL_MAP_TAG, "Memory allocation failed. Allocated size: %d bytes.", keySize + insertSize);
        }

        // store the key and elem to the memory block.
        memory.StoreToOffset(0, key, numberType);
        memory.StoreToOffset(keySize, insert, numberType);

        // let go of the memory block, be sure that this CUtlMap will eventually purge it!
        memory.Disown();

        // release the handle.
        delete memory;

        any obj = LoadFromAddress(addr, numberType);
        return this.m_Tree.Insert(obj, keySize + insertSize, constructor);
    }

    public bool HasElement(any key, int keySize, int insertSize, NumberType numberType = NumberType_Int32) {
        MemoryBlock memory = new MemoryBlock(keySize + insertSize);
        any addr = memory.Address;

        if (!addr) {
            delete memory;
            Assert_Zero(UTL_MAP_TAG, "Memory allocation failed. Allocated size: %d bytes.", keySize + insertSize);
        }

        memory.StoreToOffset(0, key, numberType);
    
        any obj = LoadFromAddress(addr, numberType);
        bool b = this.m_Tree.HasElement(obj, keySize + insertSize, numberType);

        // here, we finally free the memory.
        delete memory;

        return b;
    }

    public int Find(any key, int keySize, int insertSize, NumberType numberType = NumberType_Int32) {
        MemoryBlock memory = new MemoryBlock(keySize + insertSize);
        any addr = memory.Address;

        if (!addr) {
            delete memory;
            Assert_Zero(UTL_MAP_TAG, "Memory allocation failed. Allocated size: %d bytes.", keySize + insertSize);
        }

        memory.StoreToOffset(0, key, numberType);

        any obj = LoadFromAddress(addr, numberType);
        int i = this.m_Tree.Find(obj, keySize + insertSize, numberType);

        // here, we finally free the memory.
        delete memory;

        return b;
    }

    public int FindFirst(any key, int keySize, int insertSize, NumberType numberType = NumberType_Int32) {
        MemoryBlock memory = new MemoryBlock(keySize + insertSize);
        any addr = memory.Address;

        if (!addr) {
            delete memory;
            Assert_Zero(UTL_MAP_TAG, "Memory allocation failed. Allocated size: %d bytes.", keySize + insertSize);
        }

        memory.StoreToOffset(0, key, numberType);

        any obj = LoadFromAddress(addr, numberType);
        int i = this.m_Tree.FindFirst(obj, keySize + insertSize, numberType);

        delete memory;

        return b;
    }

    public any FindElement(any key, int keySize, int insertSize, NumberType numberType = NumberType_Int32, any defaultValue = 0) {
        int i = this.Find(key, keySize, insertSize, numberType);
        if (i == UtlRBTree.InvalidIndex()) {
            return defaultValue;
        }

        return this.GetElement(i, insertSize, keySize, numberType);
    }

    public int FindClosest(any key, int keySize, int insertSize, NumberType numberType = NumberType_Int32, CompareOperands_t eFindCriteria) {
        MemoryBlock memory = new MemoryBlock(keySize + insertSize);
        any addr = memory.Address;

        if (!addr) {
            delete memory;
            Assert_Zero(UTL_MAP_TAG, "Memory allocation failed. Allocated size: %d bytes.", keySize + insertSize);
        }

        memory.StoreToOffset(0, key, numberType);

        any obj = LoadFromAddress(addr, numberType);
        int i = this.m_Tree.FindClosest(obj, keySize + insertSize, numberType, eFindCriteria);

        delete memory;

        return b;
    }

    public bool Remove(any key, int keySize, int insertSize, NumberType elementSize = NumberType_Int32, UtlRBTreeDestructorFunc destructor) {
        MemoryBlock memory = new MemoryBlock(keySize + insertSize);
        any addr = memory.Address;

        if (!addr) {
            delete memory;
            Assert_Zero(UTL_MAP_TAG, "Memory allocation failed. Allocated size: %d bytes.", keySize + insertSize);
        }

        memory.StoreToOffset(0, key, numberType);

        any obj = LoadFromAddress(addr, numberType);
        bool b = this.m_Tree.Remove(obj, keySize + insertSize, numberType, destructor);

        delete memory;

        return b;
    }

    public int InsertOrReplace(any key, int keySize, any insert, int insertSize, NumberType numberType = NumberType_Int32, UtlRBTreeConstructorFunc constructor) {
		int i = this.Find(key, keySize, insertSize, numberType);
		if (i != UtlRBTree.InvalidIndex())
		{
            this.SetElement(i, insert, insertSize, numberType);
			return i;
		}
		
		return this.Insert(key, keySize, insert, insertSize, numberType, constructor);
    }
#else 
    #if defined _smmem_included_
    public int Insert(any key, int keySize, any insert, int insertSize, NumberType numberType = NumberType_Int32, UtlRBTreeConstructorFunc constructor) {
        // creates a block of memory for the Node_t, the size is determined by the template type!
        any addr = calloc(1, keySize + insertSize);

        // Check the pointer, make sure it is not null.
        if (!addr) {
            Assert_Zero(UTL_MAP_TAG, "Memory allocation failed. Allocated size: %d bytes.", keySize + insertSize);
        }

        // store the key and elem to the memory.
        StoreToAddress(addr, key, numberType);
        StoreToAddress(addr + keySize, insert, numberType);

        // load the Node_t object from the memory.
        any obj = LoadFromAddress(addr, NumberType_Int32);
        return this.m_Tree.Insert(obj, keySize + insertSize, constructor);
    }

    public bool HasElement(any key, int keySize, int insertSize, NumberType numberType = NumberType_Int32) {
        any addr = calloc(1, keySize + insertSize);

        if (!addr) {
            Assert_Zero(UTL_MAP_TAG, "Memory allocation failed. Allocated size: %d bytes.", keySize + insertSize);
        }

        StoreToAddress(addr, key, numberType);

        any obj = LoadFromAddress(addr, NumberType_Int32);
        bool b = this.m_Tree.HasElement(obj, keySize + insertSize, numberType);

        // here, we finally free the memory.
        free(addr);

        return b;
    }

    public int Find(any key, int keySize, int insertSize, NumberType numberType = NumberType_Int32) {
        any addr = calloc(1, keySize + insertSize);

        if (!addr) {
            Assert_Zero(UTL_MAP_TAG, "Memory allocation failed. Allocated size: %d bytes.", keySize + insertSize);
        }

        StoreToAddress(addr, key, numberType);

        any obj = LoadFromAddress(addr, NumberType_Int32);
        int i = this.m_Tree.Find(obj, keySize + insertSize, numberType);

        free(addr);

        return i;
    }

    public int FindFirst(any key, int keySize, int insertSize, NumberType numberType = NumberType_Int32) {
        any addr = calloc(1, keySize + insertSize);

        if (!addr) {
            Assert_Zero(UTL_MAP_TAG, "Memory allocation failed. Allocated size: %d bytes.", keySize + insertSize);
        }

        StoreToAddress(addr, key, numberType);

        any obj = LoadFromAddress(addr, NumberType_Int32);
        int i = this.m_Tree.FindFirst(obj, keySize + insertSize, numberType);

        free(addr);

        return i;
    }

    public any FindElement(any key, int keySize, int insertSize, NumberType numberType = NumberType_Int32, any defaultValue = 0) {
        int i = this.Find(key, keySize, insertSize, numberType);
        if (i == UtlRBTree.InvalidIndex()) {
            return defaultValue;
        }

        return this.GetElement(i, insertSize, keySize, numberType);
    }

    public int FindClosest(any key, int keySize, int insertSize, NumberType numberType = NumberType_Int32, CompareOperands_t eFindCriteria) {
        any addr = calloc(1, keySize + insertSize);

        if (!addr) {
            Assert_Zero(UTL_MAP_TAG, "Memory allocation failed. Allocated size: %d bytes.", keySize + insertSize);
        }

        StoreToAddress(addr, key, numberType);

        any obj = LoadFromAddress(addr, NumberType_Int32);
        int i = this.m_Tree.FindClosest(obj, keySize + insertSize, numberType, eFindCriteria);

        free(addr);

        return i;
    }

    public bool Remove(any key, int keySize, int insertSize, NumberType numberType = NumberType_Int32, UtlRBTreeDestructorFunc destructor) {
        any addr = calloc(1, keySize + insertSize);

        if (!addr) {
            Assert_Zero(UTL_MAP_TAG, "Memory allocation failed. Allocated size: %d bytes.", keySize + insertSize);
        }

        StoreToAddress(addr, key, numberType);

        any obj = LoadFromAddress(addr, NumberType_Int32);
        bool b = this.m_Tree.Remove(obj, keySize + insertSize, numberType, destructor);

        free(addr);

        return b;
    }

    public int InsertOrReplace(any key, int keySize, any insert, int insertSize, NumberType numberType = NumberType_Int32, UtlRBTreeConstructorFunc constructor) {
		int i = this.Find(key, keySize, insertSize, numberType);
		if (i != UtlRBTree.InvalidIndex())
		{
            this.SetElement(i, insert, insertSize, numberType);
			return i;
		}
		
		return this.Insert(key, keySize, insert, insertSize, numberType, constructor);
    }
    #endif
#endif

    // this is defined by us.
    // pass an already constructed Node_t object to the tree. if you can.

#if defined _smmem_included_
    public int InsertSafe(any obj, int size, UtlRBTreeConstructorFunc constructor) {
        return this.m_Tree.Insert(obj, size, constructor);
    }
#endif

    public bool HasElementSafe(any obj, int size, NumberType numberType = NumberType_Int32) {
        return this.m_Tree.HasElement(obj, size, numberType);
    }

    public int FindSafe(any obj, int size, NumberType numberType = NumberType_Int32) {
        return this.m_Tree.Find(obj, size, numberType);
    }

    public int FindFirstSafe(any obj, int size, NumberType numberType = NumberType_Int32) {
        return this.m_Tree.FindFirst(obj, size, numberType);
    }

    public any FindElementSafe(any obj, int size, int keySize, NumberType numberType = NumberType_Int32, any defaultValue = 0) {
        int i = this.FindSafe(obj, size, numberType);
        if (i == UtlRBTree.InvalidIndex()) {
            return defaultValue;
        }

        return this.GetElement(i, size, keySize, numberType);
    }

    public int FindClosestSafe(any obj, int size, NumberType numberType = NumberType_Int32, CompareOperands_t eFindCriteria) {
        return this.m_Tree.FindClosest(obj, size, numberType, eFindCriteria);
    }

#if defined _smmem_included_
    public void RemoveAt(int i, int size, NumberType elementSize = NumberType_Int32, UtlRBTreeDestructorFunc destructor) {
        this.m_Tree.RemoveAt(i, size, elementSize, destructor);
    }

    public bool RemoveSafe(any obj, int size, NumberType elementSize = NumberType_Int32, UtlRBTreeDestructorFunc destructor) {
        return this.m_Tree.Remove(obj, size, elementSize, destructor);
    }

    public void RemoveAll(int size, NumberType elementSize = NumberType_Int32, UtlRBTreeDestructorFunc destructor) {
        this.m_Tree.RemoveAll(size, elementSize, destructor);
    }

    public void Purge() {
        this.m_Tree.Purge();
    }

    // Purges the list and calls delete on each element in it.
    // here, this equals to calling destructor fisrt, then call purge() to free the elements.
    // here, we are freeing the each element objects.
    // but, if the element is not a pointer or object, just regular types like int, float, etc.
    // then no destructor is needed.
    public void PurgeAndDeleteElements(bool bAlwaysFreeElems = true, int keySize, int elemSize, NumberType elementSize = NumberType_Int32, UtlMapDestructorFunc destructor = null) {
        for (int i = 0; i < this.MaxElement(); ++i) 
        {
            if (!this.IsValidIndex( i )) 
                continue; 

            if (bAlwaysFreeElems && destructor) {
                any elem = this.GetElement(i, keySize + elemSize, keySize, elementSize);
                any elemAddr = this.GetElementEx(i, keySize + elemSize, keySize);

                this.Destruct(i, elemSize, elemAddr, elem, destructor);
            }

            //delete this.Element( i );
        }

        this.Purge();
    }

    public void Destruct(int i, int size, any addr = 0, any obj = 0, UtlMapDestructorFunc destructor) {
        Call_StartFunction(INVALID_HANDLE, destructor);
        Call_PushCell(this);
        Call_PushCell(i);
        Call_PushCell(addr);
        Call_PushCell(obj);
        Call_PushCell(size);
        Call_Finish();
    }
#endif

    public int FirstInorder(int size) {
        return this.m_Tree.FirstInorder(size);
    }

    public int NextInorder(int i, int size) {
        return this.m_Tree.NextInorder(i, size);
    }

    public int PrevInorder(int i, int size) {
        return this.m_Tree.PrevInorder(i, size);
    }

    public int LastInorder(int size) {
        return this.m_Tree.LastInorder(size);
    }

    public int NextInorderSameKey(int i, int size, NumberType elementSize = NumberType_Int32) {
        int iNext = this.NextInorder(i, size);
        if (!this.IsValidIndex(iNext)) {
            return UtlRBTree.InvalidIndex();
        }

        if (this.GetKey(i, size, elementSize) != this.GetKey(iNext, size, elementSize)) {
            return UtlRBTree.InvalidIndex();
        }

        return iNext;
    }

    public any AccessTree() {
        return this.m_Tree;
    }

	// If you change the search key, this can be used to reinsert the 
	// element into the map.
    public void Reinsert(int i, any key, int size, NumberType elementSize = NumberType_Int32) {
        this.SetKey(i, key, size, elementSize);
        this.m_Tree.Reinsert(i, size);
    }
}

// should have use macros here.

static void Assert_Zero(const char[] tag, const char[] message, any ...)
{
    char sBuffer[512];
    VFormat(sBuffer, sizeof(sBuffer), message, 3);
    Format(sBuffer, sizeof(sBuffer), "%s: %s.", tag, sBuffer);
    _Assert(sBuffer);
}

static void _Assert(const char[] message)
{
#if defined _log_for_sourcepawn_included
    char sPath[256];
    BuildPath(Path_SM, sPath, sizeof(sPath), "/logs/utlmap/%d-%m-%y.log");
    Logger logger = ServerConsoleSink.CreateLogger("utlmap");
    logger.SetLevel(LogLevel_Fatal);
    
    if (logger)
    {
        logger.LogSrc(LogLevel_Fatal, message);
        logger.LogStackTrace(LogLevel_Fatal, message);
        logger.Flush();
        delete logger;
    }
#else
    LogStackTrace(message);
    PrintToServer(message);
#endif

    SetCommandFlags("crash", GetCommandFlags("crash") & ~FCVAR_CHEAT);
    ServerCommand("crash");
}
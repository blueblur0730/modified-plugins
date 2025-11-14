/** Double-include prevention */
#if defined _utl_dict_included
    #endinput
#endif
#define _utl_dict_included

#include <address_base>
#include <stringt>
#include "tier1/utl_map.inc"

#pragma newdecls required
#pragma semicolon 1

#define UTL_DICT_TAG "[UtlDict]"
#define UTL_DICT_VERSION "1.0.0"

/**
 * Author: blueblur
 * Date: 2025-11-14
 * url: https://github.com/blueblur0730/modified-plugins
 * Version: 1.0.0
*/

enum EDictCompareType
{
	k_eDictCompareTypeCaseSensitive=0,
	k_eDictCompareTypeCaseInsensitive=1,
	k_eDictCompareTypeFilenames				// Slashes and backslashes count as the same character..
};

/*
    //-----------------------------------------------------------------------------
    // A dictionary mapping from symbol to structure
    //-----------------------------------------------------------------------------
    template <class T, class I = int > 

	// Nested typedefs, for code that might need 
	// to fish out the index type from a given dict
	typedef I IndexType_t;

	typedef CUtlMap<const char *, T, I> DictElementMap_t;
	DictElementMap_t m_Elements;
*/

methodmap UtlDict < AddressBase {
    public UtlDict(Address addr) {
        UtlDict p = view_as<UtlDict>(addr);

        if (p.IsNull()) {
            ThrowError("Invalid UtlDict address");
        }

        return p;
    }

    property UtlMap m_Elements {
        public get() {
            return view_as<UtlMap>(this.addr);
        }
/*
        public set(UtlMap value) {
            StoreToAddress(this.addr, value, NumberType_Int32);
        }
    */
    }

    public any Element(int i, int size = 4, NumberType type = NumberType_Int32) {
        return this.m_Elements.Element(i, size, type);
    }

    public Stringt GetElementName(int i, int size = 4, NumberType type = NumberType_Int32) {
        return this.m_Elements.Key(i, size, type);
    }

    // SetElementName seems to be incomplete, and has not yet been used anywhere in the code.
/*
    template <class T, class I>
    inline void CUtlDict<T, I>::SetElementName( I i, char const *pName )
    {
        MEM_ALLOC_CREDIT_CLASS();
        // TODO:  This makes a copy of the old element
        // TODO:  This relies on the rb tree putting the most recently
        //  removed element at the head of the insert list
        free( (void *)m_Elements.Key( i ) );
        m_Elements.Reinsert( strdup( pName ), i );
    }
*/

    public int Count() {
        return this.m_Elements.Count();
    }

    public int MaxElement() {
        return this.m_Elements.MaxElement();
    }

    public bool IsValidIndex(int i) {
        return this.m_Elements.IsValidIndex(i);
    }

    public static int InvalidIndex() {
        return UtlRBTree.InvalidIndex();
    }

    public int FindSafe(any obj, int size = 4, NumberType numberType = NumberType_Int32) {
        if (obj) {
            return this.m_Elements.FindSafe(obj, size, numberType);
        } else {
            return UtlRBTree.InvalidIndex();
        }
    }

    public bool HasElementSafe(any obj, int size = 4, NumberType numberType = NumberType_Int32) {
        if (obj) {
            return this.IsValidIndex(this.m_Elements.FindSafe(obj, size, numberType));
        } else {
            return false;
        }
    }

    public int First(int size = 4) {
        return this.m_Elements.FirstInorder(size);
    }

    public int Next(int i, int size = 4) {
        return this.m_Elements.NextInorder(i, size);
    }

#if defined _smmem_included_
    // 何意味
    public void EnsureCapacity(int num, int size = 4) {
        this.m_Elements.m_Tree.EnsureCapacity(num, size);
    }

    public void RemoveAt(int elem, int size = 4, NumberType elementSize = NumberType_Int32, UtlRBTreeDestructorFunc destructor) {
        any p = this.m_Elements.GetKeyEx(elem, size);   // const char *
        free(p);

        this.m_Elements.RemoveAt(elem, size, elementSize, destructor);
    }

    public void Remove(Stringt search, int size = 4, int insertSize, NumberType elementSize = NumberType_Int32, UtlRBTreeDestructorFunc destructor) {
        int node = this.Find(search, insertSize, elementSize);
        if (node!= UtlRBTree.InvalidIndex()) {
            this.m_Elements.RemoveAt(node, size, elementSize, destructor);
        }
    }

    public void RemoveAll(int size = 4, NumberType elementSize = NumberType_Int32, UtlRBTreeDestructorFunc destructor) {
        int index = this.m_Elements.FirstInorder(size);
        while (index != UtlRBTree.InvalidIndex()) {
            any p = this.m_Elements.GetKeyEx(index, size);
            free(p);

            index = this.m_Elements.NextInorder(index, size);
        }

        this.m_Elements.RemoveAll(size, elementSize, destructor);
    }

    public void Purge(int size, NumberType elementSize = NumberType_Int32, UtlRBTreeDestructorFunc destructor) {
        this.RemoveAll(size, elementSize, destructor);
    }

    public void PurgeAndDeleteElements(bool bAlwaysFreeElems = true, int keySize, int elemSize, NumberType elementSize = NumberType_Int32, UtlMapDestructorFunc destructor = null, UtlRBTreeDestructorFunc destructor2) {
        int index = this.m_Elements.FirstInorder(keySize + elemSize);
        while (index != UtlRBTree.InvalidIndex()) {
            any p = this.m_Elements.GetKeyEx(index, keySize + elemSize);   // char *
            free(p);

            // delete m_Elements[index];
            if (bAlwaysFreeElems && destructor) {
                any elem = this.m_Elements.GetElement(index, elemSize, elementSize);
                any elemAddr = this.m_Elements.GetElementEx(index, elemSize);

                this.m_Elements.Destruct(index, elemSize, elemAddr, elem, destructor);
            }
            
            index = this.m_Elements.NextInorder(index, keySize + elemSize);
        }

        this.RemoveAll(keySize + elemSize, elementSize, destructor2);
    }

    public int Insert(Stringt keyName, int keySize = 4, any insert, int Insertsize = 4, NumberType elementSize = NumberType_Int32, UtlRBTreeConstructorFunc constructor) {
        Stringt pDup = keyName.strdup();
        this.m_Elements.Insert(pDup, keySize, insert, Insertsize, elementSize, constructor);
    }

    public int InsertSafe(any obj, int size, UtlRBTreeConstructorFunc constructor) {
        this.m_Elements.InsertSafe(obj, size, constructor);
    }

    public int Find(Stringt search, int size = 4, int insertSize, NumberType numberType = NumberType_Int32) {
        if (!search.IsNull()) {
            return this.m_Elements.Find(search, size, insertSize, numberType);
        } else {
            return UtlRBTree.InvalidIndex();
        }
    }

    public bool HasElement(Stringt search, int size = 4, NumberType numberType = NumberType_Int32) {
        if (!search.IsNull()) {
            return this.IsValidIndex(this.m_Elements.Find(search, size, 0, numberType));
        } else {
            return false;
        }
    }
#endif
}
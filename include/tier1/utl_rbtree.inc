/** Double-include prevention */
#if defined _utl_rbtree_included
    #endinput
#endif
#define _utl_rbtree_included

#include <sdktools>
#include <address_base>
#include "tier1/utl_memory.inc"

#pragma newdecls required
#pragma semicolon 1

#define UTL_RBTREE_TAG "[UtlRBTree]"
#define UTL_RBTREE_VERSION "1.3.3"

/**
 * Author: blueblur
 * Date: 2025-11-11
 * url: https://github.com/blueblur0730/modified-plugins
 * Version: 1.3.3
*/

/*
    template < class T, class I = unsigned short, typename L = bool (*)( const T &, const T & ), class M = CUtlMemory< UtlRBTreeNode_t< T, I >, I > >

    typedef L LessFunc_t;

    LessFunc_t m_LessFunc;  // this + 0x0 / 0
    M m_Elements;           // this + 0x4 / 4, size is 0xC
    I m_Root;               // this + 0x10 / 16
    I m_NumElements;        // this + 0x12 / 18
    I m_FirstFree;          // this + 0x14 / 20
    typename M::Iterator_t m_LastAlloc; // this + 0x18 / 22, the last index allocated.

    Node_t* m_pElements;    // this + 0x1A / 24.

    // whole size is 28.
*/

/*
    // size is 8.
    template < class I >
    struct UtlRBTreeLinks_t
    {
        I  m_Left;      // this + 0x0 / 0
        I  m_Right;     // this + 0x2 / 2
        I  m_Parent;    // this + 0x4 / 4
        I  m_Tag;       // this + 0x6 / 6
    };

    // size is 8 + sizeof(T).
    template < class T, class I >
    struct UtlRBTreeNode_t : public UtlRBTreeLinks_t< I >
    {
        T  m_Data;
    };
*/

/*
	typedef UtlRBTreeNode_t< T, I > Node_t;
	typedef UtlRBTreeLinks_t< I > Links_t;
*/

/*
    // size is 2.
	class Iterator_t
	{
	public:
		Iterator_t( I i ) : index( i ) {}
		I index;

		bool operator==( const Iterator_t it ) const	{ return index == it.index; }
		bool operator!=( const Iterator_t it ) const	{ return index != it.index; }
	};
*/

enum { IsUtlRBTree = true }; // Used to match this at compiletime 

// This is a useful macro to iterate from start to end in order in a map
#define FOR_EACH_UTLRBTREE( %0, %1 ) for ( %1 = %0.FirstInorder(); %1 != %0.InvalidIndex(); %1 = %0.NextInorder( %1 ) )
#define FOR_EACH_RBTREE_FAST( %0, %1 ) for ( %1 = 0; %1 < ( %0 ).MaxElement(); ++%1 ) if ( !( %0 ).IsValidIndex( %1 ) ) continue; else

enum NodeColor_t
{
    RED = 0,
    BLACK
};

// For use with FindClosest
// Move these to a common area if anyone else ever uses them
enum CompareOperands_t
{
	k_EEqual = 0x1,
	k_EGreaterThan = 0x2,
	k_ELessThan = 0x4,
	k_EGreaterThanOrEqualTo = k_EGreaterThan | k_EEqual,
	k_ELessThanOrEqualTo = k_ELessThan | k_EEqual,
};

typeset UtlRBTreeConstructorFunc
{
    /**
     * User defined constructor function for UtlRBTree elements.
     * This equilavent to 'inline T* Construct( T* pMemory )'
     * 
     * which is, you need to call the constructor function using this address.
     * Like this: SDKCall(hndl, addr, ...);
     * Or fill the memory yourself: StoreToAddress(addr + offset, value, NumberType_Int32);
     * 
     * @param vec           This pointer to the UtlRBTree.
     * @param elem          The element to be constructed.
     * @param addr          The address of the element.
     * @param size          The size of the element.
    */
    function void (UtlRBTree vec, int elem, any addr, int size);

    /**
     * User defined constructor function for UtlRBTree elements.
     * This equilavent to 'inline T* CopyConstruct( T* pMemory, const T& src )'
     * 
     * which is, you need to store the object (assuming you have already constructed and loaded it from somewhere else) in the memory before calling this function.
     * Like this: StoreToAddress(addr, obj, NumberType_Int32);
     * 
     * @param vec           This pointer to the UtlRBTree.
     * @param elem          The element to be constructed.
     * @param addr          The address of the element.
     * @param obj           The object that copys to. could be null!!!
     * @param size          The size of the object.
    */
    function void (UtlRBTree vec, int elem, any addr, any obj, int size);
}

/**
 * User defined destructor function for UtlRBTree elements.
 * 
 * @param vec           This pointer to the UtlRBTree.
 * @param elem          The element to be destroyed.
 * @param addr          The address of the element.
 * @param obj           The object that the element owns.
 * @param size          The size of the object.
*/
typedef UtlRBTreeDestructorFunc = function void (UtlRBTree vec, int elem, any addr, any obj, int size);

#define UTL_RBTREE_ITERATOR_OFFSET_INDEX 0x0
methodmap Iterator_t < AddressBase {
    property int index {
        public get() {
            return LoadFromAddress(this.addr + UTL_RBTREE_ITERATOR_OFFSET_INDEX, NumberType_Int32);
        }
    }
}

#define UTL_RBTREE_LINKS_OFFSET_LEFT 0x0
#define UTL_RBTREE_LINKS_OFFSET_RIGHT 0x2
#define UTL_RBTREE_LINKS_OFFSET_PARENT 0x4
#define UTL_RBTREE_LINKS_OFFSET_TAG 0x6
methodmap UtlRBTreeLinks_t < AddressBase {
    property int m_Left {
        public get() {
            return LoadFromAddress(this.addr + UTL_RBTREE_LINKS_OFFSET_LEFT, NumberType_Int16);
        }

        public set(int val) {
            StoreToAddress(this.addr + UTL_RBTREE_LINKS_OFFSET_LEFT, val, NumberType_Int16);
        }
    }

    property int m_Right {
        public get() {
            return LoadFromAddress(this.addr + UTL_RBTREE_LINKS_OFFSET_RIGHT, NumberType_Int16);
        }

        public set(int val) {
            StoreToAddress(this.addr + UTL_RBTREE_LINKS_OFFSET_RIGHT, val, NumberType_Int16);
        }
    }

    property int m_Parent {
        public get() {
            return LoadFromAddress(this.addr + UTL_RBTREE_LINKS_OFFSET_PARENT, NumberType_Int16);
        }

        public set(int val) {
            StoreToAddress(this.addr + UTL_RBTREE_LINKS_OFFSET_PARENT, val, NumberType_Int16);
        }
    }

    property int m_Tag {
        public get() {
            return LoadFromAddress(this.addr + UTL_RBTREE_LINKS_OFFSET_TAG, NumberType_Int16);
        }

        public set(int val) {
            StoreToAddress(this.addr + UTL_RBTREE_LINKS_OFFSET_TAG, val, NumberType_Int16);
        }
    }
}

#define UTL_RBTREE_NODE_OFFSET_DATA 0x8
methodmap UtlRBTreeNode_t < UtlRBTreeLinks_t {
    property any m_Data {
        public get() {
            return LoadFromAddress(this.addr + UTL_RBTREE_NODE_OFFSET_DATA, NumberType_Int32);
        }

        public set(const any val) {
            StoreToAddress(this.addr + UTL_RBTREE_NODE_OFFSET_DATA, val, NumberType_Int32);
        }
    }

    public any GetData(NumberType elementSize = NumberType_Int32) {
        return LoadFromAddress(this.addr + UTL_RBTREE_NODE_OFFSET_DATA, elementSize);
    }

    public void SetData(any val, NumberType elementSize = NumberType_Int32) {
        StoreToAddress(this.addr + UTL_RBTREE_NODE_OFFSET_DATA, val, elementSize);
    }

    public any GetDataAddress() {
        return this.addr + UTL_RBTREE_NODE_OFFSET_DATA;
    }
}


//#define UTL_RBTREE_OFFSET_LESSFUNC          0x0
#define UTL_RBTREE_OFFSET_MEMORY            0x4
#define UTL_RBTREE_OFFSET_ALLOCATION_COUNT  0x8
#define UTL_RBTREE_OFFSET_GROWSIZE          0xC
#define UTL_RBTREE_OFFSET_ROOT              0x10
#define UTL_RBTREE_OFFSET_NUM_ELEMENTS      0x12
#define UTL_RBTREE_OFFSET_FIRST_FREE        0x14
#define UTL_RBTREE_OFFSET_LAST_ALLOC        0x16
#define UTL_RBTREE_OFFSET_ELEMENTS          0x18

/**
 * all allocation or deallocation access requires SM-Memory extension to work.
 * be sure you know what you are doing before using this.
*/

// all of this assumes using template:
// template < class T, class I = unsigned short, typename L = bool (*)( const T &, const T & ), class M = CUtlMemory< UtlRBTreeNode_t< T, I >, I > >
// otherwise you will need your own implementation.

methodmap UtlRBTree < AddressBase {
    public UtlRBTree(Address addr) {
        UtlRBTree p = view_as<UtlRBTree>(addr);

        if (p.IsNull())
            ThrowError("UtlRBTree address is null.");

        return p;
    }

    property any m_LessFunc {
        public get() {
            return LoadFromAddress(this.addr, NumberType_Int32);
        }

        public set(any val) {
            StoreToAddress(this.addr, val, NumberType_Int32);
        }
    }

    property UtlRBTreeNode_t m_pMemory {
        public get() {
            return LoadFromAddress(this.addr + UTL_RBTREE_OFFSET_MEMORY, NumberType_Int32);
        }

#if defined _smmem_included_
        public set(UtlRBTreeNode_t val) {
            StoreToAddress(this.addr + UTL_RBTREE_OFFSET_MEMORY, val, NumberType_Int32);
        }
#endif

    }

    property int m_nAllocationCount
    {
        public get() {
            return LoadFromAddress(this.addr + UTL_RBTREE_OFFSET_ALLOCATION_COUNT, NumberType_Int32);
        }

#if defined _smmem_included_
        public set(int val) {
            StoreToAddress(this.addr + UTL_RBTREE_OFFSET_ALLOCATION_COUNT, val, NumberType_Int32);
        }
#endif

    }

    property int m_nGrowSize {
        public get() {
            return LoadFromAddress(this.addr + UTL_RBTREE_OFFSET_GROWSIZE, NumberType_Int32);
        }

#if defined _smmem_included_
        public set(int val) {
            StoreToAddress(this.addr + UTL_RBTREE_OFFSET_GROWSIZE, val, NumberType_Int32);
        }
#endif

    }

    property int m_Root {
        public get() {
            return LoadFromAddress(this.addr + UTL_RBTREE_OFFSET_ROOT, NumberType_Int16);
        }

        public set(int val) {
            StoreToAddress(this.addr + UTL_RBTREE_OFFSET_ROOT, val, NumberType_Int16);
        }
    }

    property int m_NumElements {
        public get() {
            return LoadFromAddress(this.addr + UTL_RBTREE_OFFSET_NUM_ELEMENTS, NumberType_Int16);
        }    

#if defined _smmem_included_
        public set(int val) {
            StoreToAddress(this.addr + UTL_RBTREE_OFFSET_NUM_ELEMENTS, val, NumberType_Int16);
        }
#endif

    }

    property int m_FirstFree {
        public get() {
            return LoadFromAddress(this.addr + UTL_RBTREE_OFFSET_FIRST_FREE, NumberType_Int16);
        }

        public set(int val) {
            StoreToAddress(this.addr + UTL_RBTREE_OFFSET_FIRST_FREE, val, NumberType_Int16);    
        }
    }

    // Iterator_t m_LastAlloc;
    property int m_LastAlloc {
        public get() {
            return LoadFromAddress(this.addr + UTL_RBTREE_OFFSET_LAST_ALLOC, NumberType_Int16);
        }

        public set(int val) {
            StoreToAddress(this.addr + UTL_RBTREE_OFFSET_LAST_ALLOC, val, NumberType_Int16);
        }
    }

    property any m_pElements {
        public get() {
            return LoadFromAddress(this.addr + UTL_RBTREE_OFFSET_ELEMENTS, NumberType_Int32);
        }

#if defined _smmem_included_
        public set(any val) {
            StoreToAddress(this.addr + UTL_RBTREE_OFFSET_ELEMENTS, val, NumberType_Int32);
        }
#endif

    }

    public any Get(int i, int size = 4, NumberType elementSize = NumberType_Int32) {
        Assert(this.IsValidIndex(i, size), UTL_RBTREE_TAG, "Param index (%d) out of bounds. m_nAllocationCount: [0 - %d], m_LastAlloc: [0 - %d].", i, this.m_nAllocationCount, this.m_LastAlloc);
        return view_as<UtlRBTreeNode_t>(view_as<any>(this.m_pMemory) + i * (8 + size)).GetData(elementSize);
    }

    public void Set(int i, int size = 4, any val, NumberType elementSize = NumberType_Int32) {
        Assert(this.IsValidIndex(i, size), UTL_RBTREE_TAG, "Param index (%d) out of bounds. m_nAllocationCount: [0 - %d], m_LastAlloc: [0 - %d].", i, this.m_nAllocationCount, this.m_LastAlloc);
        view_as<UtlRBTreeNode_t>(view_as<any>(this.m_pMemory) + i * (8 + size)).SetData(val, elementSize);
    }

    public any GetEx(int i, int size = 4) {
        Assert(this.IsValidIndex(i, size), UTL_RBTREE_TAG, "Param index (%d) out of bounds. m_nAllocationCount: [0 - %d], m_LastAlloc: [0 - %d].", i, this.m_nAllocationCount, this.m_LastAlloc);
        return view_as<any>(this.m_pMemory) + i * (8 + size);
    }

    public any Element(int i, int size = 4, NumberType elementSize = NumberType_Int32) {
        return this.Get(i, size, elementSize);
    }

    public int Root() {
        return this.m_Root;
    }

    public int Count() {
        return this.m_NumElements;
    }

    public int MaxElement() {
        return this.m_nAllocationCount;
    }

    public int LeftChild(int i, int size = 4) {
        return i != UtlRBTree.InvalidIndex() ? view_as<UtlRBTreeNode_t>(view_as<any>(this.m_pMemory) + i * size).m_Left : UtlRBTree.InvalidIndex();
    }

    public int RightChild(int i, int size = 4) {
        return i != UtlRBTree.InvalidIndex() ? view_as<UtlRBTreeNode_t>(view_as<any>(this.m_pMemory) + i * size).m_Right : UtlRBTree.InvalidIndex();
    }

    public int Parent(int i, int size = 4) {
        return i != UtlRBTree.InvalidIndex() ? view_as<UtlRBTreeNode_t>(view_as<any>(this.m_pMemory) + i * size).m_Parent : UtlRBTree.InvalidIndex();
    }

    public bool IsLeftChild(int i, int size = 4) {
        return this.LeftChild(this.Parent(i, size), size) == i;
    }

    public bool IsRightChild(int i, int size = 4) {
        return this.RightChild(this.Parent(i, size), size) == i;
    }

    public bool IsRoot(int i) {
        return i == this.m_Root;
    }

    public bool IsLeaf(int i, int size = 4) {
        return ((this.LeftChild(i, size) == UtlRBTree.InvalidIndex()) && (this.RightChild(i, size) == UtlRBTree.InvalidIndex()));
    }

    public bool IsValidIndex(int i, int size = 4) {
        if (!this.IsIdxValid(i))
            return false;

        if (this.m_LastAlloc == UtlRBTree.InvalidIndex() || i > this.m_LastAlloc)
            return false;

        return this.LeftChild(i, size) != i;
    }

    public bool IsIdxValid(int i) {
        return i < this.m_nAllocationCount;
    }

    public static int InvalidIndex() {
        return -1;
    }

    public void SetParent(int i, int parent, int size = 4) {
        this.Links(i, size).m_Parent = parent;
    }

    public void SetLeftChild(int i, int left, int size = 4) {
        this.Links(i, size).m_Left = left;
    }

    public void SetRightChild(int i, int right, int size = 4) {
        this.Links(i, size).m_Right = right;
    }

    public UtlRBTreeLinks_t Links(int i, int size = 4) {
        Assert(i != UtlRBTree.InvalidIndex(), UTL_RBTREE_TAG, "Param index (%d) out of bounds", i);
        return view_as<UtlRBTreeLinks_t>(view_as<any>(this.m_pMemory) + i * size);
    }

    public bool IsRed(int i, int size = 4) {
        return this.Color(i, size) == RED;
    }

    public bool IsBlack(int i, int size = 4) {
        return this.Color(i, size) == BLACK;
    }

    public NodeColor_t Color(int i, int size = 4) {
        return view_as<NodeColor_t>(i != UtlRBTree.InvalidIndex() ? this.Links(i, size).m_Tag : BLACK);
    }

    public void SetColor(int i, NodeColor_t c, int size = 4) {
        this.Links(i, size).m_Tag = view_as<int>(c);
    }

    public any Base() {
        return this.m_pMemory;
    }

    public void RotateLeft(int elem, int size = 4) {
        int rightchild = this.RightChild(elem, size);
        this.SetRightChild(elem, this.LeftChild(rightchild, size), size);

        if (this.LeftChild(rightchild, size) != UtlRBTree.InvalidIndex())
            this.SetParent(this.LeftChild(rightchild, size), elem, size);

        if (rightchild != UtlRBTree.InvalidIndex())
            this.SetParent(rightchild, this.Parent(elem, size), size);

        if (!this.IsRoot(elem)) {
            if (this.IsLeftChild(elem, size)) {
                this.SetLeftChild(this.Parent(elem, size), rightchild, size);
            } else {
                this.SetRightChild(this.Parent(elem, size), rightchild, size);
            }
        } else {
            this.m_Root = rightchild;
        }

        this.SetLeftChild(rightchild, elem, size);
        if (elem != UtlRBTree.InvalidIndex()) {
            this.SetParent(elem, rightchild, size);
        }
    }

    public void RotateRight(int elem, int size = 4) {
        int leftchild = this.LeftChild(elem, size);
        this.SetLeftChild(elem, this.RightChild(leftchild, size), size);

        if (this.RightChild(leftchild, size) != UtlRBTree.InvalidIndex()) {
            this.SetParent(this.RightChild(leftchild, size), elem, size);
        }

        if (!this.IsRoot(elem)) {
            if (this.IsRightChild(elem, size)) {
                this.SetRightChild(this.Parent(elem, size), leftchild, size);
            } else {
                this.SetLeftChild(this.Parent(elem, size), leftchild, size);
            }
        } else {
            this.m_Root = leftchild;
        }

        this.SetRightChild(leftchild, elem, size);
        if (elem != UtlRBTree.InvalidIndex()) {
            this.SetParent(elem, leftchild, size);
        }
    }

    public void InsertRebalance(int elem, int size = 4) {
        while (!this.IsRoot(elem) && this.Color(this.Parent(elem, size), size) == RED) {
            int parent = this.Parent(elem, size);
            int grandparent = this.Parent(parent, size);

            /* we have a violation */
            if (this.IsLeftChild(parent, size)) {
                int uncle = this.RightChild(grandparent, size);
                if (this.IsRed(uncle, size)) {
                    /* uncle is RED */
                    this.SetColor(parent, BLACK, size);
                    this.SetColor(uncle, BLACK, size);
                    this.SetColor(grandparent, RED, size);
                    elem = grandparent;
                } else {
                    /* uncle is BLACK */
                    if (this.IsRightChild(elem, size)) {
                        /* make x a left child, will change parent and grandparent */
                        elem = parent;
                        this.RotateLeft(elem, size);
                        parent = this.Parent(elem, size);
                        grandparent = this.Parent(parent, size);
                    }

                    /* recolor and rotate */
                    this.SetColor(parent, BLACK, size);
                    this.SetColor(grandparent, RED, size);
                    this.RotateRight(grandparent, size);
                }
            } else {
                /* mirror image of above code */
                int uncle = this.LeftChild(grandparent, size);
                if (this.IsRed(uncle, size)) { 
                    /* uncle is RED */
                    this.SetColor(parent, BLACK, size);
                    this.SetColor(uncle, BLACK, size);
                    this.SetColor(grandparent, RED, size);
                    elem = grandparent;
                } else {
                    /* uncle is BLACK */
                    if (this.IsLeftChild(elem, size)) {
                        /* make x a right child, will change parent and grandparent */
                        elem = parent;
                        this.RotateRight(parent, size);
                        parent = this.Parent(elem, size);
                        grandparent = this.Parent(parent, size);
                    }

                    /* recolor and rotate */
                    this.SetColor(parent, BLACK, size);
                    this.SetColor(grandparent, RED, size);
                    this.RotateLeft(grandparent, size);
                }
            }
        }

        this.SetColor(this.Root(), BLACK, size);
    }

    public void LinkToParent(int i, int parent, bool isleft, int size = 4) {
        UtlRBTreeLinks_t elem = this.Links(i, size);
        elem.m_Parent = parent;
        elem.m_Left = elem.m_Right = UtlRBTree.InvalidIndex();
        elem.m_Tag = RED;

        /* insert node in tree */
        if (parent != UtlRBTree.InvalidIndex()) {
            if (isleft) {
                this.Links(parent, size).m_Left = i;
            } else {
                this.Links(parent, size).m_Right = i;
            
            }
        } else {
            this.m_Root = i;
        }

        this.InsertRebalance(i, size);
    }

    public void RemoveBalance(int elem, int size = 4) {
        while (elem != this.m_Root && this.IsBlack(elem, size)) {
            int parent = this.Parent(elem, size);

            // If elem is the left child of the parent
            if (elem == this.LeftChild(parent, size)) {
                // Get our sibling
                int sibling = this.RightChild(parent, size);

                if (this.IsRed(sibling, size)) {
                    this.SetColor(sibling, BLACK, size);
                    this.SetColor(parent, RED, size);
                    this.RotateLeft(parent, size);

                    // We may have a new parent now
                    parent = this.Parent(elem, size);
                    sibling = this.RightChild(parent, size);
                }

                if (this.IsBlack(this.LeftChild(sibling, size), size) && (this.IsBlack(this.RightChild(sibling, size), size))) {
                    if (sibling != UtlRBTree.InvalidIndex()) {
                        this.SetColor(sibling, RED, size);
                    }

                    elem = parent;
                } else {
                    if (this.IsBlack(this.RightChild(sibling, size), size)) {
                        this.SetColor(this.LeftChild(sibling, size), BLACK, size);
                        this.SetColor(sibling, RED, size);
                        this.RotateRight(sibling, size);

                        // rotation may have changed this
                        parent = this.Parent(elem, size);
                        sibling = this.RightChild(parent, size);
                    }

                    this.SetColor(sibling, this.Color(parent, size), size);
                    this.SetColor(parent, BLACK, size);
                    this.SetColor(this.RightChild(sibling, size), BLACK, size);
                    this.RotateLeft(parent, size);
                    elem = this.m_Root;
                }
            } else {
                // Elem is the right child of the parent
                int sibling = this.LeftChild(parent, size);
                if (this.IsRed(sibling, size)) {
                    this.SetColor(sibling, BLACK, size);
                    this.SetColor(parent, RED, size);
                    this.RotateRight(parent, size);

                    // We may have a new parent now
                    parent = this.Parent(elem, size);
                    sibling = this.LeftChild(parent, size);
                }

                if (this.IsBlack(this.RightChild(sibling, size), size) && (this.IsBlack(this.LeftChild(sibling, size), size))) {
                    if (sibling != UtlRBTree.InvalidIndex()) {
                        this.SetColor(sibling, RED, size);
                    }

                    elem = parent;
                } else {
                    if (this.IsBlack(this.LeftChild(sibling, size), size)) {
                        this.SetColor(this.RightChild(sibling, size), BLACK, size);
                        this.SetColor(sibling, RED, size);
                        this.RotateLeft(sibling, size);

                        // rotation may have changed this
                        parent = this.Parent(elem, size);
                        sibling = this.LeftChild(parent, size);
                    }

                    this.SetColor(sibling, this.Color(parent, size), size);
                    this.SetColor(parent, BLACK, size);
                    this.SetColor(this.LeftChild(sibling, size), BLACK, size);
                    this.RotateRight(parent, size);
                    elem = this.m_Root;
                }
            }
        }

        this.SetColor(elem, BLACK, size);
    }

    public void Unlink(int elem, int size = 4) {
        if (elem != UtlRBTree.InvalidIndex()) {
            int x, y;

            if ((this.LeftChild(elem, size) == UtlRBTree.InvalidIndex()) || (this.RightChild(elem, size) == UtlRBTree.InvalidIndex())) {
                /* y has a NIL node as a child */
                y = elem;
            } else {
                /* find tree successor with a NIL node as a child */
                y = this.RightChild(elem, size);
                while (this.LeftChild(y, size) != UtlRBTree.InvalidIndex()) {
                    y = this.LeftChild(y, size);
                }
            }

            /* x is y's only child */
            if (this.LeftChild(y, size) != UtlRBTree.InvalidIndex()) {
                x = this.LeftChild(y, size);
            } else {
                x = this.RightChild(y, size);
            }

            /* remove y from the parent chain */
            if (x != UtlRBTree.InvalidIndex()) {
                this.SetParent(x, this.Parent(y, size), size);
            }

            if (!this.IsRoot(y)) {
                if (this.IsLeftChild(y, size)) {
                    this.SetLeftChild(this.Parent(y, size), x, size);
                } else {
                    this.SetRightChild(this.Parent(y, size), x, size);
                }
            } else {
                this.m_Root = x;
            }

            // need to store this off now, we'll be resetting y's color
            NodeColor_t ycolor = this.Color(y, size);
            if (y != elem) {
                // Standard implementations copy the data around, we cannot here.
                // Hook in y to link to the same stuff elem used to.

                this.SetParent(y, this.Parent(elem, size), size);
                this.SetRightChild(y, this.RightChild(elem, size), size);
                this.SetLeftChild(y, this.LeftChild(elem, size), size);
                
                if (!this.IsRoot(elem)) {
                    if (this.IsLeftChild(elem, size)) {
                        this.SetLeftChild(this.Parent(elem, size), y, size);
                    } else {
                        this.SetRightChild(this.Parent(elem, size), y, size);
                    }
                } else {
                    this.m_Root = y;
                }

                if (this.LeftChild(y, size) != UtlRBTree.InvalidIndex()) {
                    this.SetParent(this.LeftChild(y, size), y, size);
                }

                if (this.RightChild(y, size) != UtlRBTree.InvalidIndex()) {
                    this.SetParent(this.RightChild(y, size), y, size);
                }

                this.SetColor(y, this.Color(elem, size), size);
            }

            if ((x != UtlRBTree.InvalidIndex()) && (ycolor == BLACK)) {
                this.RemoveBalance(x, size);
            }
        }
    }

    public void Link(int elem, int size = 4, NumberType elementSize = NumberType_Int32) {
        if (elem != UtlRBTree.InvalidIndex()) {
            int parent = UtlRBTree.InvalidIndex();
            bool leftchild = false;

            this.FindInsertionPosition(this.Element(elem, size, elementSize), parent, leftchild, size);
            this.LinkToParent(elem, parent, leftchild, size);

            Assert(this.IsValid(), UTL_RBTREE_TAG, "Invalid RBTree after Link");
        }
    }

    public int FirstInorder(int size = 4) {
        int i = this.m_Root;
        int left;

        while ((left = this.LeftChild(i, size)) != UtlRBTree.InvalidIndex()) {
            i = left;
        }

        return i;
    }

    public int NextInorder(int i, int size = 4) {
        // Don't go into an infinite loop if it's a bad index
        Assert(this.IsValidIndex(i, size), UTL_RBTREE_TAG, "Param index (%d) invalid.", i);
        if (!this.IsValidIndex(i, size)) {
            return UtlRBTree.InvalidIndex();
        }

        int right;
        if ((right = this.RightChild(i, size)) != UtlRBTree.InvalidIndex()) {
            i = right;
            int left;
            while ((left = this.LeftChild(i, size)) != UtlRBTree.InvalidIndex()) {
                i = left;
            }

            return i;
        }

        int parent = this.Parent(i, size);
        while (this.IsRightChild(i, size)) {
            i = parent;
            if (i == UtlRBTree.InvalidIndex()) {
                break;
            }

            parent = this.Parent(i, size);
        }

        return parent;
    }

    public int PrevInorder(int i, int size = 4) {
        // Don't go into an infinite loop if it's a bad index
        Assert(this.IsValidIndex(i, size), UTL_RBTREE_TAG, "Param index (%d) invalid.", i);
        if (!this.IsValidIndex(i, size)) {
            return UtlRBTree.InvalidIndex();
        }

        int left, right;
        if ((left = this.LeftChild(i, size)) != UtlRBTree.InvalidIndex()) {
            i = left;
            while ((right = this.RightChild(i, size)) != UtlRBTree.InvalidIndex()) {
                i = right;
            }

            return i;
        }

        int parent = this.Parent(i, size);
        while (this.IsLeftChild(i, size)) {
            i = parent;
            if (i == UtlRBTree.InvalidIndex()) {
                break;
            }

            parent = this.Parent(i, size);
        }

        return parent;
    }

    public int LastInorder(int size = 4) {
        int i = this.m_Root;
        int right;
        while ((right = this.RightChild(i, size)) != UtlRBTree.InvalidIndex()) {
            i = right;
        }

        return i;
    }

    public int FirstPreorder() {
        return this.m_Root;
    }

    public int NextPreorder(int i, int size = 4)
    {
        int left, right;
        if ((left = this.LeftChild(i, size)) != UtlRBTree.InvalidIndex()) {
            return left;
        }

        if ((right = this.RightChild(i, size)) != UtlRBTree.InvalidIndex()) {
            return right;
        }

        int parent = this.Parent(i, size);
        while (parent != UtlRBTree.InvalidIndex()) {
            if (this.IsLeftChild(i, size) && (this.RightChild(parent, size) != UtlRBTree.InvalidIndex())) {
                return this.RightChild(parent, size);
            }

            i = parent;
            parent = this.Parent(parent, size);
        }

        return UtlRBTree.InvalidIndex();
    }

    public int PrevPreorder(int i) {
        Assert_Zero(UTL_RBTREE_TAG, "UtlRBtree.PrevPreorder() Not implemented yet.");
        i = UtlRBTree.InvalidIndex();
        return i;
    }

    public int LastPreorder(int size = 4) {
        int i = this.m_Root;
        while (1) {     // you might need a -w 206 to your compiler.
            int left, right;
            while ((right = this.RightChild(i, size)) != UtlRBTree.InvalidIndex()) {
                i = right;
            }

            if ((left = this.LeftChild(i, size)) != UtlRBTree.InvalidIndex()) {
                i = left;
            } else {
                break;
            }
        }

        return i;
    }

    public int FirstPostorder(int size = 4) {
        int i = this.m_Root;
        while (!this.IsLeaf(i, size)) {
            int left;
            if ((left = this.LeftChild(i, size)) != UtlRBTree.InvalidIndex()) {
                i = left;
            } else {
                i = this.RightChild(i, size);
            }
        }

        return i;
    }

    public int NextPostorder(int i, int size = 4) {
        int parent = this.Parent(i, size);
        if (parent == UtlRBTree.InvalidIndex()) {
            return UtlRBTree.InvalidIndex();
        }

        if (this.IsRightChild(i, size)) {
            return parent;
        }

        if (this.RightChild(parent, size) == UtlRBTree.InvalidIndex()) {
            return parent;
        }

        i = this.RightChild(parent);
        while (!this.IsLeaf(i, size)) {
            int left;
            if ((left = this.LeftChild(i, size)) != UtlRBTree.InvalidIndex()) {
                i = left;
            } else {
                i = this.RightChild(i, size);
            }
        }

        return i;
    }

    public int Reinsert(int elem, int size = 4) {
        this.Unlink(elem, size);
        this.Link(elem, size);
    }

    // we need overload :(
    public int Depth__(int size = 4) {
        return this.Depth(this.m_Root, size);
    }

    // returns the tree depth (not a very fast operation)
    public int Depth(int node, int size = 4) {
        if (node == UtlRBTree.InvalidIndex())
            return 0;

        int rightDepth = this.Depth(this.RightChild(node, size), size);
        int leftDepth = this.Depth(this.LeftChild(node, size), size);
        
        return 1 + (rightDepth > leftDepth ? rightDepth : leftDepth);
    }

    public bool IsValid() {
        if (!this.Count()) {
            return true;
        }

        if (this.m_LastAlloc == UtlRBTree.InvalidIndex()) {
            return false;
        }

        if (!this.IsIdxValid(this.Root())) {
            return false;
        }

        if (this.Parent(this.Root()) != UtlRBTree.InvalidIndex()) {
            return false;
        }

        return true;
    }

    public void SetLessFunc(any lessFunc) {
        if (!this.m_LessFunc) {
            this.m_LessFunc = lessFunc;
        } else if (this.Count() > 0){
            // need to re-sort the tree here....
            Assert_Zero(UTL_RBTREE_TAG, "Can't change the lessFunc after inserting elements.");
        }
    }

    // Inserts a node into the tree, doesn't copy the data in.
    public void FindInsertionPosition(any insert, int &parent, bool &leftchild, int size = 4, NumberType elementSize = NumberType_Int32) {
        Assert(!!this.m_LessFunc, UTL_RBTREE_TAG, "LessFunc is not set.");

        /* find where node belongs */
        int current = this.m_Root;
        parent = UtlRBTree.InvalidIndex();
        leftchild = false;

        while (current != UtlRBTree.InvalidIndex()) {
            parent = current;
            if (CallLessFunc(this.m_LessFunc, insert, this.Element(current, size, elementSize))) {
                leftchild = true;
                current = this.LeftChild(current, size);
            } else {
                leftchild = false;
                current = this.RightChild(current, size);
            }
        }
    }

    public bool HasElement(any search, int size = 4, NumberType elementSize = NumberType_Int32) {
        return (this.Find(search, size, elementSize) != UtlRBTree.InvalidIndex());
    }

    public int Find(any search, int size = 4, NumberType elementSize = NumberType_Int32) {
        Assert(!!this.m_LessFunc, UTL_RBTREE_TAG, "LessFunc is not set.");

        int current = this.m_Root;
        while (current != UtlRBTree.InvalidIndex())  {
            if (CallLessFunc(this.m_LessFunc, search, this.Element(current, size, elementSize))) {
                current = this.LeftChild(current, size);
            } else if (CallLessFunc(this.m_LessFunc, this.Element(current, size, elementSize), search)) {
                current = this.RightChild(current, size);
            } else {
                break;
            } 
        }

        return current;
    }

    public int FindFirst(any search, int size = 4, NumberType elementSize = NumberType_Int32) {
        Assert(!!this.m_LessFunc, UTL_RBTREE_TAG, "LessFunc is not set.");

        int current = this.m_Root;
        int best = UtlRBTree.InvalidIndex();
        while (current != UtlRBTree.InvalidIndex()) {
            if (CallLessFunc(this.m_LessFunc, search, this.Element(current, size, elementSize))) {
                current = this.LeftChild(current, size);
            } else if (CallLessFunc(this.m_LessFunc, this.Element(current, size, elementSize), search)) {
                current = this.RightChild(current, size);
            } else {
                best = current;
                current = this.LeftChild(current, size);
            }
        }

        return best;
    }

    public int FindClosest(any search, int size = 4, NumberType elementSize = NumberType_Int32, CompareOperands_t eFindCriteria) {
        Assert(!!this.m_LessFunc, UTL_RBTREE_TAG, "LessFunc is not set.");

        // error 450: no viable conversion from "CompareOperands_t" to "bool"
        Assert( view_as<bool>(( eFindCriteria & ( k_EGreaterThan | k_ELessThan ) ) ^ ( k_EGreaterThan | k_ELessThan )), UTL_RBTREE_TAG, "Invalid FindCriteria (%d).", eFindCriteria);

        int current = this.m_Root;
        int best = UtlRBTree.InvalidIndex();

        while (current != UtlRBTree.InvalidIndex()) {
            if (CallLessFunc(this.m_LessFunc, search, this.Element(current, size, elementSize))) {
                // current node is > key
                if (eFindCriteria & k_EGreaterThan) {
                    best = current;
                }

                current = this.LeftChild(current, size);
            } else if (CallLessFunc(this.m_LessFunc, this.Element(current, size, elementSize), search)) {
                // current node is < key
                if (eFindCriteria & k_ELessThan) {
                    best = current;
                }

                current = this.RightChild(current, size);
            } else {
                // exact match
                if (eFindCriteria & k_EEqual) {
                    best = current;
                    break;
                } else if (eFindCriteria & k_EGreaterThan) {
                    current = this.RightChild(current, size);
                } else if ( eFindCriteria & k_ELessThan ) {
                    current = this.LeftChild(current, size);
                }
            }
        }

        return best;
    }

#if defined _smmem_included_
//-----------------------------------------------------------------------------
// Allocates / deallocates nodes
//-----------------------------------------------------------------------------
    public void Grow(int alloccount = 1, int size = 4) {
        Assert((alloccount > 0), UTL_RBTREE_TAG, "Param alloccount (%d) invalid.", alloccount);

        if (this.IsExternallyAllocated()) {
            Assert_Zero(UTL_RBTREE_TAG, "Can't grow a buffer whose memory was externally allocated.");
            return;
        }

        // Make sure we have at least numallocated + num allocations.
        // Use the grow rules specified for this memory (in m_nGrowSize)
        int nAllocationRequested = this.m_nAllocationCount + alloccount;
        int nNewAllocationCount = UtlMemory_CalcNewAllocationCount( this.m_nAllocationCount, this.m_nGrowSize, nAllocationRequested, size );

        // if m_nAllocationRequested wraps index type I, recalculate
        if ( nNewAllocationCount < nAllocationRequested )
        {
            if ( nNewAllocationCount == 0 && ( nNewAllocationCount - 1 ) >= nAllocationRequested )
            {
                --nNewAllocationCount; // deal w/ the common case of m_nAllocationCount == MAX_USHORT + 1
            }
            else
            {
                if ( nAllocationRequested != nAllocationRequested )
                {
                    // we've been asked to grow memory to a size s.t. the index type can't address the requested amount of memory
                    Assert_Zero(UTL_RBTREE_TAG, "The index type can't address the requested amount of memory.");
                    return;
                }
                while ( nNewAllocationCount < nAllocationRequested )
                {
                    nNewAllocationCount = ( nNewAllocationCount + nAllocationRequested ) / 2;
                }
            }
        }

        this.m_nAllocationCount += nNewAllocationCount;

        if (this.m_pMemory) {
            // do not load or set first! check the allocated memory.
            any p = realloc(this.m_pMemory, this.m_nAllocationCount * size);
            Assert(!p ? 0 : 1, UTL_RBTREE_TAG, "realloc failed");
            this.m_pMemory = p;
        } else {
            any p = malloc(this.m_nAllocationCount * size);
            Assert(!p ? 0 : 1, UTL_RBTREE_TAG, "malloc failed");
            this.m_pMemory = p;
        }
    }

    public void EnsureCapacity(int num, int size = 4) {
        if (this.m_nAllocationCount >= num)
            return;

        if (this.IsExternallyAllocated()) {
            Assert_Zero(UTL_RBTREE_TAG, "Can't grow a buffer whose memory was externally allocated.");
            return;
        }
            
        this.m_nAllocationCount = num;

        if (this.m_pMemory) {
            // do not load or set first! check the allocated memory.
            any p = realloc(this.m_pMemory, this.m_nAllocationCount * size);
            Assert(!p ? 0 : 1, UTL_RBTREE_TAG, "realloc failed");
            this.m_pMemory = p;
        } else {
            any p = malloc(this.m_nAllocationCount * size);
            Assert(!p ? 0 : 1, UTL_RBTREE_TAG, "malloc failed");
            this.m_pMemory = p;
        }

        this.ResetDbgInfo();
    }

    // see 'inline T* Construct( T* pMemory )' (src/public/tier0/platform.h)
    // when adding elements to the vector, we need to construct the object stored first.
    // but how do we construct these data that is all on your own.
    public void Construct(int elem, int size = 4, UtlRBTreeConstructorFunc constructor) {
        Call_StartFunction(INVALID_HANDLE, constructor);
        Call_PushCell(this);
        Call_PushCell(elem);
        Call_PushCell(this.GetEx(elem, size));
        Call_PushCell(size);
        Call_Finish();
    }

    // see 'inline T* CopyConstruct( T* pMemory, T const& src )' (src/public/tier0/platform.h)
    public void CopyConstruct(int elem, int size = 4, any obj = 0, UtlRBTreeConstructorFunc constructor) {
        Assert( obj != 0, UTL_RBTREE_TAG, "Param obj is null to copy construct.");
        Call_StartFunction(INVALID_HANDLE, constructor);
        Call_PushCell(this);
        Call_PushCell(elem);
        Call_PushCell(this.GetEx(elem, size));
        Call_PushCell(obj);
        Call_PushCell(size);
        Call_Finish();
    }

    // see 'void Destruct<T>(T * pMemory)' (src/public/tier0/platform.h)
    // when removing elements from the vector, we need to destruct the object stored first.
    // but how do we destruct these data that is all on your own.
    public void Destruct(int elem, int size = 4, NumberType elementSize = NumberType_Int32, UtlRBTreeDestructorFunc destructor) {
        Call_StartFunction(INVALID_HANDLE, destructor);
        Call_PushCell(this);
        Call_PushCell(elem);
        Call_PushCell(this.GetEx(elem, size));
        Call_PushCell(this.Get(elem, size, elementSize));
        Call_PushCell(size);
        Call_Finish();
    }

    // uses default constructor.
    public int NewNode(int size = 4, UtlRBTreeConstructorFunc constructor) {
        int elem = 0;

        // Nothing in the free list; add.
        if (this.m_FirstFree != UtlRBTree.InvalidIndex()) {
            Assert((this.IsIdxValid(this.m_LastAlloc) || this.m_NumElements == 0), UTL_RBTREE_TAG, "Invalid LastAlloc (%d) or NumElements (%d).", this.m_LastAlloc, this.m_NumElements);
            int it = this.IsIdxValid(this.m_LastAlloc) ? (this.IsIdxValid(this.m_LastAlloc + 1) ? this.m_LastAlloc + 1 : UtlRBTree.InvalidIndex()) : (this.IsIdxValid(0) ? 0 : UtlRBTree.InvalidIndex());

            if (!this.IsIdxValid(it)) {
                this.Grow(_, size);

                it = this.IsIdxValid(this.m_LastAlloc) ? (this.IsIdxValid(this.m_LastAlloc + 1) ? this.m_LastAlloc + 1 : UtlRBTree.InvalidIndex()) : (this.IsIdxValid(0) ? 0 : UtlRBTree.InvalidIndex());
                Assert(this.IsIdxValid(it), UTL_RBTREE_TAG, "CUtlRBTree overflow!");
            }

            this.m_LastAlloc = it;
            elem = this.m_LastAlloc;
            Assert(this.IsIdxValid(this.m_LastAlloc), UTL_RBTREE_TAG, "CUtlRBTree overflow!");
        } else {
            elem = this.m_FirstFree;
            this.m_FirstFree = this.RightChild(this.m_FirstFree, size);
        }

        // Bypass Element() here, we're not fully linked yet so it's valid-element asserts won't yet pass.
        this.Construct(elem, size, constructor);
        this.ResetDbgInfo();

        return elem;
    }

    public void FreeNode(int i, int size = 4, NumberType elementSize = NumberType_Int32, UtlRBTreeDestructorFunc destructor) {
        Assert((this.IsValidIndex(i, size) && (i != UtlRBTree.InvalidIndex())), UTL_RBTREE_TAG, "Param index (%d) invalid.", i);

        this.Destruct(i, size, elementSize, destructor);
        this.SetLeftChild(i, i, size);
        this.SetRightChild(i, this.m_FirstFree, size);
        this.m_FirstFree = i;
    }

    // uses default constructor.
    public int InsertAt(int parent, bool leftchild, int size = 4, UtlRBTreeConstructorFunc constructor) {
        int i = this.NewNode(size, constructor);
        this.LinkToParent(i, parent, leftchild, size);
        ++this.m_NumElements;
        Assert(this.IsValid(), UTL_RBTREE_TAG, "Invalid tree after insert.");
        return i;
    }

    // uses copy constructor.
    public int Insert(any insert, int size = 4, UtlRBTreeConstructorFunc constructor) {
        int parent = UtlRBTree.InvalidIndex();
        bool leftchild = false;
        this.FindInsertionPosition(insert, parent, leftchild, size);
        int newNode = this.InsertAt(parent, leftchild, size, constructor);
        
        this.CopyConstruct(newNode, size, insert, constructor);
        return newNode;
    }

    // uses copy constructor.
    public int InsertIfNotFound(any insert, int size = 4, NumberType elementSize = NumberType_Int32, UtlRBTreeConstructorFunc constructor) {
        // use copy constructor to copy it in
        int parent;
        bool leftchild;

        int current = this.m_Root;
        parent = UtlRBTree.InvalidIndex();
        leftchild = false;
        while (current != UtlRBTree.InvalidIndex())  {
            parent = current;
            if (CallLessFunc(this.m_LessFunc, insert, this.Element(current, size, elementSize))) {
                leftchild = true; current = this.LeftChild(current);
            } else if (CallLessFunc(this.m_LessFunc, this.Element(current, size, elementSize), insert)) {
                leftchild = false; current = this.RightChild(current, size);
            } else {
                // Match found, no insertion
                return UtlRBTree.InvalidIndex();
            }
        }

        int newNode = this.InsertAt(parent, leftchild, size, constructor);
        this.CopyConstruct(newNode, size, insert, constructor);
        return newNode;
    }



    public void RemoveAt(int elem, int size = 4, NumberType elementSize = NumberType_Int32, UtlRBTreeDestructorFunc destructor) {
        if (elem != UtlRBTree.InvalidIndex()) {
            this.Unlink(elem, size);

            this.FreeNode(elem, size, elementSize, destructor);
            --this.m_NumElements;

            Assert(this.IsValid(), UTL_RBTREE_TAG, "Invalid tree after remove.");
        }
    }

    public bool Remove(any search, int size = 4, NumberType elementSize = NumberType_Int32, UtlRBTreeDestructorFunc destructor) {
        int node = this.Find(search, size);
        if (node != UtlRBTree.InvalidIndex()) {
            this.RemoveAt(node, size, elementSize, destructor);
            return true;
        }

        return false;
    }

    public void RemoveAll(int size = 4, NumberType elementSize = NumberType_Int32, UtlRBTreeDestructorFunc destructor) {
        // Have to do some convoluted stuff to invoke the destructor on all
        // valid elements for the multilist case (since we don't have all elements
        // connected to each other in a list).

        
        if (this.m_LastAlloc == UtlRBTree.InvalidIndex()) {
            Assert(this.m_Root == UtlRBTree.InvalidIndex(), UTL_RBTREE_TAG, "No elements to remove. m_Root = %d", this.m_Root);
            Assert(this.m_FirstFree == UtlRBTree.InvalidIndex(), UTL_RBTREE_TAG, "No free elements to remove. m_FirstFree = %d", this.m_FirstFree);
            Assert(this.m_NumElements == 0, UTL_RBTREE_TAG, "No elements to remove. m_NumElements = %d", this.m_NumElements);

            return;
        }

        for (int it = this.IsIdxValid( 0 ) ? 0 : UtlRBTree.InvalidIndex(); it != UtlRBTree.InvalidIndex(); it = this.IsIdxValid( it + 1 ) ? it + 1 : UtlRBTree.InvalidIndex() ) {
            int i = it;
            if (this.IsValidIndex(i, size)) { // skip elements in the free list
                this.Destruct(i, size, elementSize, destructor);
                this.SetRightChild(i, this.m_FirstFree, size);
                this.SetLeftChild(i, i, size);
                this.m_FirstFree = i;
            }

            if (it == this.m_LastAlloc) {
                break; // don't destruct elements that haven't ever been constucted
            }
        }

        // Clear everything else out
        this.m_Root = UtlRBTree.InvalidIndex();
        // Technically, this iterator could become invalid. It will not, because it's 
        // always the same iterator. If we don't clear this here, the state of this
        // container will be invalid after we start inserting elements again.
        this.m_LastAlloc = UtlRBTree.InvalidIndex();
        this.m_FirstFree = UtlRBTree.InvalidIndex();
        this.m_NumElements = 0;

        Assert(this.IsValid(), UTL_RBTREE_TAG, "Invalid tree after remove all.");
    }

    // first destruct all elements, then free the memory.
    public void Purge__(int size = 4, NumberType elementSize = NumberType_Int32, UtlRBTreeDestructorFunc destructor) {
        this.RemoveAll(size, elementSize, destructor);
        this.Purge();
    }

    public void Purge() {
        if (!this.IsExternallyAllocated())
        {
            if (this.m_pMemory) {
                // g_pMemAlloc->Free((void*)m_pMemory);
                // note: not sure if this is correct. better not use it.
                free(view_as<any>(this.m_pMemory));
                this.m_pMemory = view_as<UtlRBTreeNode_t>(0);
            }

            this.m_nAllocationCount = 0;
        }
    }

    public bool IsExternallyAllocated() {
        return (this.m_nGrowSize < 0);
    }

    public void ResetDbgInfo() {
        this.m_pElements = this.Base();
    }
#endif
}

// bool (*)( const T &, const T & )
static bool CallLessFunc(any lessFunc, any insert, any element) {
    StartPrepSDKCall(SDKCall_Static);
#if defined _smmem_included_
    PrepSDKCall_SetAddress(Address(lessFunc));
#else
    PrepSDKCall_SetAddress(view_as<Address>(lessFunc));
#endif
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByRef);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByRef);
    PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
    Handle call = EndPrepSDKCall();

    if (!call)
        ThrowError("Failed to prepare lessFunc call.");

    return SDKCall(call, insert, element);
}

// should have use macros here.

static void Assert(bool condition, const char[] tag, const char[] message, any ...)
{
    if (!condition)
    {
        char sBuffer[512];
        VFormat(sBuffer, sizeof(sBuffer), message, 4);
        Format(sBuffer, sizeof(sBuffer), "%s: %s.", tag, sBuffer);
        _Assert(sBuffer);
    }
}

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
    BuildPath(Path_SM, sPath, sizeof(sPath), "/logs/utlrbtree/%d-%m-%y.log");
    Logger logger = ServerConsoleSink.CreateLogger("utlrbtree");
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
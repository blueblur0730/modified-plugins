/** Double-include prevention */
#if defined _utl_vector_included
    #endinput
#endif
#define _utl_vector_included

#include <address_base>
#include "tier1/utl_memory"

#pragma newdecls required
#pragma semicolon 1

/**
 * Author   dysphie
 * url      https://github.com/dysphie/nmo-guard/blob/main/gamedata/nmo-guard.games.txt
 *          https://github.com/dysphie/nmo-guard/blob/main/scripting/nmo-guard/objective-manager.sp
 *
 * Improved by F1F88
 * url      https://github.com/F1F88
 * Version  1.0.0
 * 
 * Improved by blueblur
 * Date     2025-11-10
 * url      https://github.com/blueblur0730/modified-plugins
 * Version  2.2.1
 * 
 * Ported from: SM-Memory CUtlVector
 * url      https://github.com/Scags/SM-Memory/blob/main/pawn/sourcemod/scripting/include/smmem/vec.inc
 */


// #define UTL_VECTOR_OFFSET_ELEMENTS  0x0
#define UTL_VECTOR_OFFSET_ALLOCATION_COUNT  0x4
#define UTL_VECTOR_OFFSET_GROWSIZE  0x8
#define UTL_VECTOR_OFFSET_SIZE      0xC
#define UTL_VECTOR_OFFSET_ELEMENTS  0x10


#define FOR_EACH_VEC( %0, %1 ) \
    for ( int %1 = 0; %1 < %0.Count(); %1++ )

#define FOR_EACH_VEC_BACK( %0, %1 ) \
    for ( int %1 = %0.Count()-1; %1 >= 0; %1-- )

enum
{
    EXTERNAL_BUFFER_MARKER = -1,
    EXTERNAL_CONST_BUFFER_MARKER = -2,
}

/** 
 * @param elem1         The first obj of this element to compare.
 * @param elem2         The second obj of this element to compare.
 * 
 * @return              < 0 if first < second
 *                      = 0 if first = second
 *                      > 0 if first > second
*/
typedef UtlVectorSortFunc = function int (any elem1, any elem2);

/**
 * User defined constructor function for UtlVector elements.
 * 
 * @param elem          The element to be constructed.
 * @param addr          The address of the element.
*/
typedef UtlVectorConstructorFunc = function void (int elem, any addr);

/**
 * User defined destructor function for UtlVector elements.
 * 
 * @param elem          The element to be destroyed.
 * @param addr          The address of the element.
 * @param obj           The object that the element owns.
*/
typedef UtlVectorDestructorFunc = function void (int elem, any addr, any obj);

/**
 * all allocation or deallocation access requires SM-Memory extension to work except for basic element writing.
 * be sure you know what you are doing before using this.
*/

// all of this assumes using template:
// template< class T, class A = CUtlMemory<T> >
// otherwise you will need your own implementation.

methodmap UtlVector < AddressBase {
    public UtlVector(Address addr) {
        UtlVector p = view_as<UtlVector>(addr);

        if (p.IsNull())
            ThrowError("UtlVector address is null.");

        return p;
    }

    property any m_pMemory {
        public get() {
            return LoadFromAddress(this.addr, NumberType_Int32);
        }

#if defined _smmem_included_
        public set(const any val) {
            StoreToAddress(this.addr, val, NumberType_Int32);
        }
#endif

    }

    property int m_nAllocationCount
    {
        public get() {
            return LoadFromAddress(this.addr + UTL_VECTOR_OFFSET_ALLOCATION_COUNT, NumberType_Int32);
        }

#if defined _smmem_included_
        public set(const int val) {
            StoreToAddress(this.addr + UTL_VECTOR_OFFSET_ALLOCATION_COUNT, val, NumberType_Int32);
        }
#endif

    }

    property int m_nGrowSize {
        public get() {
            return LoadFromAddress(this.addr + UTL_VECTOR_OFFSET_GROWSIZE, NumberType_Int32);
        }

#if defined _smmem_included_
        public set(const int val) {
            StoreToAddress(this.addr + UTL_VECTOR_OFFSET_GROWSIZE, val, NumberType_Int32);
        }
#endif

    }

    property int m_Size {
        public get() {
            return LoadFromAddress(this.addr + UTL_VECTOR_OFFSET_SIZE, NumberType_Int32);
        }

#if defined _smmem_included_
        public set(const int val) {
            StoreToAddress(this.addr + UTL_VECTOR_OFFSET_SIZE, val, NumberType_Int32);
        }
#endif

    }

    property any m_pElements {
        public get() {
            return LoadFromAddress(this.addr + UTL_VECTOR_OFFSET_ELEMENTS, NumberType_Int32);
        }

#if defined _smmem_included_
        public set(const any val) {
            StoreToAddress(this.addr + UTL_VECTOR_OFFSET_ELEMENTS, val, NumberType_Int32);
        }
#endif

    }

    public any Get(int index, int size = 4, NumberType elementSize = NumberType_Int32) {
        if (!this.IsValidIndex(index))
            ThrowError("Param index (%d) out of bounds. [0 - %d].", index, this.size);

        return LoadFromAddress(this.m_pMemory + index * size, elementSize);
    }

    public void Set(int index, int size = 4, any value, NumberType elementSize = NumberType_Int32) {
        if (!this.IsValidIndex(index))
            ThrowError("Param index (%d) out of bounds. [0 - %d].", index, this.size);

        StoreToAddress(this.m_pMemory + index * size, value, elementSize);
    }

    // this gets raw address of the element.
    public any GetEx(int index, int size = 4) {
        if (!this.IsValidIndex(index))
            ThrowError("Param index (%d) out of bounds. [0 - %d].", index, this.size);

        return (this.m_pMemory + index * size);
    }

    public any Element(int index, int size = 4, NumberType elementSize = NumberType_Int32) {

        return this.Get(index, size, elementSize);
    }

    public any Head(int size = 4, NumberType elementSize = NumberType_Int32) {
        return this.Get(0, size, elementSize);
    }

    public any Tail(int size = 4, NumberType elementSize = NumberType_Int32) {
        return this.Get(this.m_Size - 1, size, elementSize);
    }

    public int Count() {
        return this.m_Size;
    }

    public any Random(int size = 4, NumberType elementSize = NumberType_Int32) {
        return this.Get(GetRandomInt(0, this.m_Size - 1), size, elementSize);
    }

    public bool IsEmpty() {
        return (this.m_Size == 0);
    }

    public void Shuffle(int size = 4, NumberType elementSize = NumberType_Int32) {
        for (int i = 0; i < this.m_Size; i++) {
            int j = GetRandomInt(i, this.m_Size - 1);
            if (i != j) {
                any temp = this.Get(i, size, elementSize);
                this.Set(i, size, this.Get(j, size, elementSize), elementSize);
                this.Set(j, size, temp, elementSize);
            }
        }
    }

    public void Reverse(int size = 4, NumberType elementSize = NumberType_Int32) {
        for (int i = 0; i < this.m_Size / 2; i++) {
            int j = this.m_Size - 1 - i;
            any temp = this.Get(i, size, elementSize);
            this.Set(i, size, this.Get(j, size, elementSize), elementSize);
            this.Set(j, size, temp, elementSize);
        }
    }

    public bool IsValidIndex(int index) {
        return (index >= 0 && index < this.m_Size);
    }

    public static int InvalidIndex() {
        return -1;
    }

    // should have something like std::sort or qsort.
    public void Sort(int size = 4, UtlVectorSortFunc sortFunc, NumberType elementSize = NumberType_Int32) {
        for (int i = this.m_Size - 1; i >= 0; i--) {
            for (int j = 1; j <= i; j++) {
                int result = 0;
                Call_StartFunction(INVALID_HANDLE, sortFunc);
                Call_PushCell(this.Get(j - 1, size, elementSize));
                Call_PushCell(this.Get(j, size, elementSize));
                Call_Finish(result);

                if (result < 0) {
                    any temp = this.Get(j - 1, size, elementSize);
                    this.Set(j - 1, size, this.Get(j, size, elementSize), elementSize);
                    this.Set(j, size, temp, elementSize);
                }
            }
        }
    }

    public int Find(any src, int size = 4, NumberType elementSize = NumberType_Int32) {
        for (int i = 0; i < this.m_Size; i++) {
            if (this.Element(i, size, elementSize) == src) {
                return i;
            }
        }

        return UtlVector.InvalidIndex();
    }

    // this compares element address instead of value.
    public int FindEx(any src, int size = 4)
    {
        int count = this.m_Size;
        for (int i = 0; i < count; ++i) {
            if (this.GetEx(i, size) == src)
                return i;
        }

        return -1;
    }

    public void FillWithValue(any src, int size = 4, NumberType elementSize = NumberType_Int32) {
        for (int i = 0; i < this.m_Size; i++) {
            this.Set(i, size, src, elementSize);
        }
    }

    public void ToArray(int size = 4, any[] array, NumberType elementSize = NumberType_Int32) {
        int len = this.m_Size;
        for (int i = 0; i < len; ++i)
            array[i] = this.Element(i, size, elementSize);
    }

    public ArrayList ToArrayList(int size = 4, NumberType elementSize = NumberType_Int32) {
        ArrayList list = new ArrayList(ByteCountToCells(size));
        int len = this.m_Size;
        for (int i = 0; i < len; ++i)
            list.Push(this.Element(i, size, elementSize));

        return list;
    }

    public bool HasElement(any src, int size = 4, NumberType elementSize = NumberType_Int32) {
        return (this.Find(src, size, elementSize) >= 0);
    }

    public bool IsReadOnly() {
        return (this.m_nGrowSize == EXTERNAL_CONST_BUFFER_MARKER);
    }

    public any Base() {
        return this.m_pMemory;
    }

// allocation or deallocation access.
// this is an extension to the original smmem/vec.inc
#if defined _smmem_included_
    public void Grow(int alloccount, int size = 4) {
        if (alloccount <= 0)
            ThrowError("Param alloccount (%d) invalid.", alloccount);

        if (this.IsExternallyAllocated()) {
            ThrowError("Can't grow a buffer whose memory was externally allocated .");
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
            this.m_pMemory = realloc(this.m_pMemory, this.m_nAllocationCount * size);
        } else {
            this.m_pMemory = malloc(this.m_nAllocationCount * size);
        }
    }

    public void GrowVector(int num = 1, int size = 4) {
        if (this.m_Size + num > this.m_nAllocationCount) {
            this.Grow(this.m_Size + num - this.m_nAllocationCount, size);
        }
    
        this.m_Size += num;
        this.ResetDbgInfo();
    }

    // see 'inline T* Construct( T* pMemory )' (src/public/tier0/platform.h)
    // when adding elements to the vector, we need to construct the object stored first.
    // but how do we construct these data that is all on your own.
    public void Construct(int elem, int size = 4, NumberType elementSize = NumberType_Int32, UtlVectorConstructorFunc constructor) {
        Call_StartFunction(INVALID_HANDLE, constructor);
        Call_PushCell(elem);
        Call_PushCell(this.GetEx(elem, size));
        Call_Finish();
    }

    // see 'void Destruct<T>(T * pMemory)' (src/public/tier0/platform.h)
    // when removing elements from the vector, we need to destruct the object stored first.
    // but how do we destruct these data that is all on your own.
    public void Destruct(int elem, int size = 4, NumberType elementSize = NumberType_Int32, UtlVectorDestructorFunc destructor) {
        Call_StartFunction(INVALID_HANDLE, destructor);
        Call_PushCell(elem);
        Call_PushCell(this.GetEx(elem, size));
        Call_Finish();
    }

    public void ShiftElementsRight(int elem, int num = 1, int size = 4) {
        if (! (this.IsValidIndex(elem) || this.m_Size == 0 || num == 0) ) {
            ThrowError("Param elem (%d) out of bounds, [0 - %d], or num (%d) is zero.", elem, this.m_Size, num);
            return;
        }

        int numtomove = this.m_Size - elem - num;
        if (numtomove > 0 && num > 0)
            memmove(this.m_pMemory + (elem + num) * size, this.m_pMemory + elem * size, numtomove * size);
    }

    public void ShiftElementsLeft(int elem, int num = 1, int size = 4) {
        if (! (this.IsValidIndex(elem) || this.m_Size == 0 || num == 0) ) {
            ThrowError("Param elem (%d) out of bounds, [0 - %d], or num (%d) is zero.", elem, this.m_Size, num);
            return;
        }

        int numtomove = this.m_Size - elem - num;
        if (numtomove > 0 && num > 0)
            memmove(this.m_pMemory + elem * size, this.m_pMemory + (elem + num) * size, numtomove * size);
    }

    public void EnsureCapacity(int num, int size = 4) {
        if (this.m_nAllocationCount >= num)
            return;

        if (this.IsExternallyAllocated())
        {
            ThrowError("Can't grow a buffer whose memory was externally allocated.");
            return;
        }
            
        this.m_nAllocationCount = num;

        if (this.m_pMemory) {
            this.m_pMemory = realloc(this.m_pMemory, this.m_nAllocationCount * size);
        } else {
            this.m_pMemory = malloc(this.m_nAllocationCount * size);
        }

        this.ResetDbgInfo();
    }

    public void EnsureCount(int num, int size = 4, NumberType elementSize = NumberType_Int32) {
        if (this.size < num) {
            this.AddMultipleToTail( num - this.m_Size, size, elementSize );
        }
    }

    public int InsertBefore(int elem, int size = 4, NumberType elementSize = NumberType_Int32, UtlVectorConstructorFunc constructor) {
        if (!( (elem == this.Count()) || this.IsValidIndex(elem) ))
            ThrowError("Param elem (%d) out of bounds. [0 - %d].", elem, this.m_Size);

        this.GrowVector(_, size);
        this.ShiftElementsRight(elem, _,size);

        this.Construct(this.m_pMemory + elem * size, this.Element(elem, size, elementSize), elementSize, constructor);
        return elem;
    }

    public int InsertAfter(int elem, int size = 4, NumberType elementSize = NumberType_Int32) {
        return this.InsertBefore(elem + 1, size, elementSize);
    }

    public int AddToHead(int size = 4, NumberType elementSize = NumberType_Int32) {
        return this.InsertBefore(0, size, elementSize);
    }

    public int AddToTail(int size = 4, NumberType elementSize = NumberType_Int32) {
        return this.InsertBefore(this.m_Size, size, elementSize);
    }

    public any AddToTailGetPtr(int size = 4, NumberType elementSize = NumberType_Int32) {
        int index = this.InsertBefore(this.m_Size, size, elementSize);
        return this.Get(index, size, elementSize);
    }

    public int InsertMultipleBefore(int elem, int num, int size = 4, NumberType elementSize = NumberType_Int32, UtlVectorConstructorFunc constructor) {
        if (num == 0)
            return elem;

        if (!( (elem == this.m_Size) || this.IsValidIndex(elem) ))
            ThrowError("Param elem (%d) out of bounds. [0 - %d].", elem, this.m_Size);

        this.GrowVector(num, size);
        this.ShiftElementsRight(elem, num, size);

        for (int i = 0; i < num; i++) {
            this.Construct(elem + i, this.Element(elem + 1, size, elementSize), elementSize, constructor);
        }

        return elem;
    }

    public int AddMultipleToHead(int num, int size = 4, NumberType elementSize = NumberType_Int32) {
        return this.InsertMultipleBefore(0, num, size, elementSize);
    }

    public int AddMultipleToTail(int num, int size = 4, NumberType elementSize = NumberType_Int32) {
        return this.InsertMultipleBefore(this.m_Size, num, size, elementSize);
    }

    public int InsertMultipleAfter(int elem, int num, int size = 4, NumberType elementSize = NumberType_Int32) {
        return this.InsertMultipleBefore(elem + 1, num, size, elementSize);
    }

    public void FastRemove(int elem, int size = 4, NumberType elementSize = NumberType_Int32, UtlVectorDestructorFunc destructor) {
        this.Destruct(elem, size, elementSize, destructor);
        if (this.m_Size > 0) {
            if (elem != this.m_Size - 1)
                memcpy(this.m_pMemory + elem * size, this.m_pMemory + (this.m_Size - 1) * size, size);

            --this.m_Size;
        }
    }

    public void Remove(int elem, int size = 4, NumberType elementSize = NumberType_Int32, UtlVectorDestructorFunc destructor) {
        this.Destruct(elem, size, elementSize, destructor);
        this.ShiftElementsLeft(elem, _, size);
        --this.m_Size;
    }

    public bool FindAndRemove(any src, int size = 4, NumberType elementSize = NumberType_Int32, UtlVectorDestructorFunc destructor) {
        int elem = this.Find(src, size, elementSize);

        if (elem != -1) {
            this.Remove(elem, size, elementSize, destructor);
            return true;
        }

        return false;
    }

    public bool FindAndFastRemove(any src, int size = 4, NumberType elementSize = NumberType_Int32, UtlVectorDestructorFunc destructor) {
        int elem = this.Find(src, size, elementSize);

        if (elem != -1) {
            this.FastRemove(elem, size, elementSize, destructor);
            return true;
        }

        return false;
    }

    public void RemoveAll(int size = 4, NumberType elementSize = NumberType_Int32, UtlVectorDestructorFunc destructor) {
        for (int i = this.m_Size; --i >= 0;) {
            this.Destruct(i, size, elementSize, destructor);
        }
            
        this.m_Size = 0;
    }

    public void RemoveMultiple(int elem, int num, int size = 4, NumberType elementSize = NumberType_Int32, UtlVectorDestructorFunc destructor) {
        for (int i = elem + num; --i >= elem; ) {
            this.Destruct(i, size, elementSize, destructor);
        }

        this.ShiftElementsLeft(elem, num, size);
        this.m_Size -= num;
    }

    public void RemoveMultipleFromHead(int num, int size = 4, NumberType elementSize = NumberType_Int32, UtlVectorDestructorFunc destructor) {
        for (int i = num; --i >= 0; ) {
            this.Destruct(i, size, elementSize, destructor);
        }

        this.ShiftElementsLeft(0, num, size);
        this.m_Size -= num;
    }

    public void RemoveMultipleFromTail(int num, int size = 4, NumberType elementSize = NumberType_Int32, UtlVectorDestructorFunc destructor) {
        for (int i = this.m_Size - num; i < this.m_Size; i++) {
            this.Destruct(i, size, elementSize, destructor);
        }

        this.m_Size -= num;
    }

    public void SetCount(int count, int size = 4, NumberType elementSize = NumberType_Int32, UtlVectorDestructorFunc destructor) {
        this.RemoveAll(size, elementSize, destructor);
        this.AddMultipleToTail(count, size, elementSize);
    }

    public void SetCountNonDestructively(int count, int size = 4, NumberType elementSize = NumberType_Int32, UtlVectorDestructorFunc destructor) {
        int delta = count - this.m_Size;
        if (delta > 0) {
            this.AddMultipleToTail(delta, size, elementSize);
        } else if (delta < 0) {
            this.RemoveMultipleFromTail(-delta, size, elementSize, destructor);
        }
    }

    public bool IsExternallyAllocated() {
        return (this.m_nGrowSize < 0);
    }

    public void Purge(int size = 4, NumberType elementSize = NumberType_Int32, UtlVectorDestructorFunc destructor) {
        this.RemoveAll(size, elementSize, destructor);
        
        // void CUtlMemory<T,I>::Purge()
        if (!this.IsExternallyAllocated())
        {
            if (this.m_pMemory) {
                // g_pMemAlloc->Free((void*)m_pMemory);
                // note: not sure if this is correct. better not use it.
                free(this.m_pMemory);
                this.m_pMemory = 0;
            }

            this.m_nAllocationCount = 0;
        }

        this.ResetDbgInfo();
    }

    public void ResetDbgInfo() {
        this.m_pElements = this.Base();
    }

#endif
// -------------------------------------------------------------------------------
// backwards compatibility

    property Address elements {
        public get() {
            return this.m_pMemory;
        }
    }

    property int size {
        public get() {
            return this.m_Size;
        }

        // @F1F88: 我认为这很危险
        // public set(int value)
        // {
        //     StoreToAddress(this.addr + UTL_VECTOR_OFFSET_SIZE, value, NumberType_Int32);
        // }

        // @blueblur0730: should never change the size without actually changing the memory allocation, which is not what sourcepawn should do.
    }
}


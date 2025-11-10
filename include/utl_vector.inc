/** Double-include prevention */
#if defined _utl_vector_included
    #endinput
#endif
#define _utl_vector_included

#include <address_base>

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
 * url      https://github.com/blueblur0730/modified-plugins
 * Version  2.0.0
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

/*
 * @return              -1 if first should go before second
 *                      0 if first is equal to second
 *                      1 if first should go after second
*/
typedef UtlVectorSortFunc = function int (any elem1, any elem2);

/**
 * User defined destructor function for UtlVector elements.
 * 
 * @param elem          The element to be destroyed.
 * @param elementSize   The size of the element in bytes.
 * @param obj           The object that the element owns.
*/
typedef DestructorFunc = function void (int elem, NumberType elementSize, any obj);

/**
 * all write access requires SM-Memory extension to work except for basic element writing.
 * be sure you know what you are doing before using this.
*/

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

    public any Get(int index, NumberType elementSize = NumberType_Int32) {
        if (!this.IsValidIndex(index))
            ThrowError("Param index (%d) out of bounds. [0 - %d].", index, this.size);

        int offset;
        CheckSizeWithIndex(elementSize, offset, index);

        return LoadFromAddress(this.m_pMemory + offset, elementSize);
    }

    public void Set(int index, any value, NumberType elementSize = NumberType_Int32) {
        if (!this.IsValidIndex(index))
            ThrowError("Param index (%d) out of bounds. [0 - %d].", index, this.size);

        int offset;
        CheckSizeWithIndex(elementSize, offset, index);

        StoreToAddress(this.m_pMemory + offset, value, elementSize);
    }

    // this gets raw address of the element.
    public any GetEx(int index, NumberType elementSize = NumberType_Int32) {
        if (!this.IsValidIndex(index))
            ThrowError("Param index (%d) out of bounds. [0 - %d].", index, this.size);

        int offset;
        CheckSizeWithIndex(elementSize, offset, index);

        return (this.m_pMemory + offset);
    }

    public any Element(int index, NumberType elementSize = NumberType_Int32) {

        return this.Get(index, elementSize);
    }

    public any Head(NumberType elementSize = NumberType_Int32) {
        return this.Get(0, elementSize);
    }

    public any Tail(NumberType elementSize = NumberType_Int32) {
        return this.Get(this.m_Size - 1, elementSize);
    }

    public int Count() {
        return this.m_Size;
    }

    public any Random(NumberType elementSize = NumberType_Int32) {
        return this.Get(GetRandomInt(0, this.m_Size - 1), elementSize);
    }

    public bool IsEmpty() {
        return (this.m_Size == 0);
    }

    public void Shuffle(NumberType elementSize = NumberType_Int32) {
        for (int i = 0; i < this.m_Size; i++) {
            int j = GetRandomInt(i, this.m_Size - 1);
            if (i != j) {
                any temp = this.Get(i, elementSize);
                this.Set(i, this.Get(j, elementSize), elementSize);
                this.Set(j, temp, elementSize);
            }
        }
    }

    public void Reverse(NumberType elementSize = NumberType_Int32) {
        for (int i = 0; i < this.m_Size / 2; i++) {
            int j = this.m_Size - 1 - i;
            any temp = this.Get(i, elementSize);
            this.Set(i, this.Get(j, elementSize), elementSize);
            this.Set(j, temp, elementSize);
        }
    }

    public bool IsValidIndex(int index) {
        return (index >= 0 && index < this.m_Size);
    }

    public static int InvalidIndex() {
        return -1;
    }

    // should have something like std::sort or qsort.
    public void Sort(UtlVectorSortFunc sortFunc, NumberType elementSize = NumberType_Int32) {
        for (int i = this.m_Size - 1; i >= 0; i--) {
            for (int j = 1; j <= i; j++) {
                int result = 1;
                Call_StartFunction(INVALID_HANDLE, sortFunc);
                Call_PushCell(this.Get(j - 1, elementSize));
                Call_PushCell(this.Get(j, elementSize));
                Call_Finish(result);

                if (result < 0) {
                    any temp = this.Get(j - 1, elementSize);
                    this.Set(j - 1, this.Get(j, elementSize), elementSize);
                    this.Set(j, temp, elementSize);
                }
            }
        }
    }

    public int Find(any src, NumberType elementSize = NumberType_Int32) {
        for (int i = 0; i < this.m_Size; i++) {
            if (this.Element(i, elementSize) == src) {
                return i;
            }
        }

        return UtlVector.InvalidIndex();
    }

    // this compares element address instead of value.
    public int FindEx(any src, NumberType elementSize = NumberType_Int32)
    {
        int count = this.m_Size;
        for (int i = 0; i < count; ++i) {
            if (this.GetEx(i, elementSize) == src)
                return i;
        }

        return -1;
    }

    public void FillWithValue(any src, NumberType elementSize = NumberType_Int32) {
        for (int i = 0; i < this.m_Size; i++) {
            this.Set(i, src, elementSize);
        }
    }

    public void ToArray(any[] array) {
        int len = this.m_Size;
        for (int i = 0; i < len; ++i)
            array[i] = this.Element(i);
    }

    public ArrayList ToArrayList(NumberType elementSize = NumberType_Int32) {
        int size;
        CheckSize(elementSize, size);

        ArrayList list = new ArrayList(ByteCountToCells(size));
        int len = this.m_Size;
        for (int i = 0; i < len; ++i)
            list.Push(this.Element(i));

        return list;
    }

    public bool HasElement(any src, NumberType elementSize = NumberType_Int32) {
        return (this.Find(src, elementSize) >= 0);
    }

    public bool IsReadOnly() {
        return (this.m_nGrowSize == EXTERNAL_CONST_BUFFER_MARKER);
    }

    public any Base() {
        return this.m_pMemory;
    }

// write access.
// this is an extension to the original smmem/vec.inc
#if defined _smmem_included_
    public void Grow(int alloccount, NumberType elementSize = NumberType_Int32) {
        this.m_nAllocationCount += alloccount;

        int size;
        CheckSize(elementSize, size);

        if (this.m_pMemory) {
            this.m_pMemory = realloc(this.m_pMemory, this.m_nAllocationCount * size);
        } else {
            this.m_pMemory = malloc(this.m_nAllocationCount * size);
        }
    }

    public void GrowVector(int num = 1, NumberType elementSize = NumberType_Int32) {
        if (this.m_Size + num > this.m_nAllocationCount) {
            this.Grow(this.m_Size + num - this.m_nAllocationCount, elementSize);
        }
    
        this.m_Size += num;
        this.ResetDbgInfo();
    }

    public void Construct(int elem, any src = 0, NumberType elementSize = NumberType_Int32) {
        int size;
        CheckSize(elementSize, size);
        StoreToAddress(this.m_pMemory + elem * size, src, elementSize);
    }

    public void ShiftElementsRight(int elem, int num = 1, NumberType elementSize = NumberType_Int32) {
        if (! (this.IsValidIndex(elem) || this.m_Size == 0 || num == 0) ) {
            ThrowError("Param elem (%d) out of bounds, [0 - %d], or num (%d) is zero.", elem, this.m_Size, num);
            return;
        }

        int size;
        CheckSize(elementSize, size);

        int numtomove = this.m_Size - elem - num;
        if (numtomove > 0 && num > 0)
            memmove(this.m_pMemory + (elem + num) * size, this.m_pMemory + elem * size, numtomove * size);
    }

    public void ShiftElementsLeft(int elem, int num = 1, NumberType elementSize = NumberType_Int32) {
        if (! (this.IsValidIndex(elem) || this.m_Size == 0 || num == 0) ) {
            ThrowError("Param elem (%d) out of bounds, [0 - %d], or num (%d) is zero.", elem, this.m_Size, num);
            return;
        }

        int size;
        CheckSize(elementSize, size);

        int numtomove = this.m_Size - elem - num;
        if (numtomove > 0 && num > 0)
            memmove(this.m_pMemory + elem * size, this.m_pMemory + (elem + num) * size, numtomove * size);
    }

    public void EnsureCapacity(int num, NumberType elementSize = NumberType_Int32) {
        if (this.m_nAllocationCount >= num)
            return;

        if (this.IsExternallyAllocated())
        {
            ThrowError("Can't grow a buffer whose memory was externally allocated.");
            return;
        }
            
        this.m_nAllocationCount = num;

        int size;
        CheckSize(elementSize, size);

        if (this.m_pMemory) {
            this.m_pMemory = realloc(this.m_pMemory, this.m_nAllocationCount * size);
        } else {
            this.m_pMemory = malloc(this.m_nAllocationCount * size);
        }

        this.ResetDbgInfo();
    }

    public void EnsureCount(int num, NumberType elementSize = NumberType_Int32) {
        if (this.size < num) {
            this.AddMultipleToTail( num - this.m_Size, elementSize );
        }
    }

    public int InsertBefore(int elem, NumberType elementSize = NumberType_Int32) {
        if (!( (elem == this.Count()) || this.IsValidIndex(elem) ))
            ThrowError("Param elem (%d) out of bounds. [0 - %d].", elem, this.m_Size);

        this.GrowVector();
        this.ShiftElementsRight(elem, elementSize);

        int size;
        CheckSize(elementSize, size);
        this.Construct(this.m_pMemory + elem * size, this.Element(elem, elementSize), elementSize);
        return elem;
    }

    public int InsertAfter(int elem, NumberType elementSize = NumberType_Int32) {
        return this.InsertBefore(elem + 1, elementSize);
    }

    public int AddToHead(NumberType elementSize = NumberType_Int32) {
        return this.InsertBefore(0, elementSize);
    }

    public int AddToTail(NumberType elementSize = NumberType_Int32) {
        return this.InsertBefore(this.m_Size, elementSize);
    }

    public any AddToTailGetPtr(NumberType elementSize = NumberType_Int32) {
        int index = this.InsertBefore(this.m_Size, elementSize);
        return this.Get(index, elementSize);
    }

    public int InsertMultipleBefore(int elem, int num, NumberType elementSize = NumberType_Int32) {
        if (num == 0)
            return elem;

        if (!( (elem == this.m_Size) || this.IsValidIndex(elem) ))
            ThrowError("Param elem (%d) out of bounds. [0 - %d].", elem, this.m_Size);

        this.GrowVector(num, elementSize);
        this.ShiftElementsRight(elem, num, elementSize);

        int size;
        CheckSize(elementSize, size);
        for (int i = 0; i < num; i++) {
            this.Construct(elem + i, this.Element(elem + 1, elementSize), elementSize);
        }

        return elem;
    }

    public int AddMultipleToHead(int num, NumberType elementSize = NumberType_Int32) {
        return this.InsertMultipleBefore(0, num, elementSize);
    }

    public int AddMultipleToTail(int num, NumberType elementSize = NumberType_Int32) {
        return this.InsertMultipleBefore(this.m_Size, num, elementSize);
    }

    public int InsertMultipleAfter(int elem, int num, NumberType elementSize = NumberType_Int32) {
        return this.InsertMultipleBefore(elem + 1, num, elementSize);
    }

    // see 'void Destruct<T>(T * pMemory)' (src/public/tier0/platform.h)
    // when removing elements from the vector, we need to destruct the object stored first.
    // but how do we destruct these data that is all on your own.
    public void Destruct(int elem, NumberType elementSize = NumberType_Int32, DestructorFunc destructor) {
        Call_StartFunction(INVALID_HANDLE, destructor);
        Call_PushCell(elem);
        Call_PushCell(elementSize);
        Call_PushCell(this.Get(elem, elementSize));
        Call_Finish();
    }

    public void FastRemove(int elem, NumberType elementSize = NumberType_Int32, DestructorFunc destructor) {
        int size;
        CheckSize(elementSize, size);

        this.Destruct(elem, elementSize, destructor);
        if (this.m_Size > 0) {
            if (elem != this.m_Size - 1)
                memcpy(this.m_pMemory + elem * size, this.m_pMemory + (this.m_Size - 1) * size, size);

            --this.m_Size;
        }
    }

    public void Remove(int elem, NumberType elementSize = NumberType_Int32, DestructorFunc destructor) {
        this.Destruct(elem, elementSize, destructor);
        this.ShiftElementsLeft(elem, _, elementSize);
        --this.m_Size;
    }

    public bool FindAndRemove(any src, NumberType elementSize = NumberType_Int32, DestructorFunc destructor) {
        int elem = this.Find(src, elementSize);

        if (elem != -1) {
            this.Remove(elem, elementSize, destructor);
            return true;
        }

        return false;
    }

    public bool FindAndFastRemove(any src, NumberType elementSize = NumberType_Int32, DestructorFunc destructor) {
        int elem = this.Find(src, elementSize);

        if (elem != -1) {
            this.FastRemove(elem, elementSize, destructor);
            return true;
        }

        return false;
    }

    public void RemoveAll(NumberType elementSize = NumberType_Int32, DestructorFunc destructor) {
        for (int i = this.m_Size; --i >= 0;) {
            this.Destruct(i, elementSize, destructor);
        }
            
        this.m_Size = 0;
    }

    public void RemoveMultiple(int elem, int num, NumberType elementSize = NumberType_Int32, DestructorFunc destructor) {
        for (int i = elem + num; --i >= elem; ) {
            this.Destruct(i, elementSize, destructor);
        }

        this.ShiftElementsLeft(elem, num, elementSize);
        this.m_Size -= num;
    }

    public void RemoveMultipleFromHead(int num, NumberType elementSize = NumberType_Int32, DestructorFunc destructor) {
        for (int i = num; --i >= 0; ) {
            this.Destruct(i, elementSize, destructor);
        }

        this.ShiftElementsLeft(0, num, elementSize);
        this.m_Size -= num;
    }

    public void RemoveMultipleFromTail(int num, NumberType elementSize = NumberType_Int32, DestructorFunc destructor) {
        for (int i = this.m_Size - num; i < this.m_Size; i++) {
            this.Destruct(i, elementSize, destructor);
        }

        this.m_Size -= num;
    }

    public void SetCount(int count, NumberType elementSize = NumberType_Int32, DestructorFunc destructor) {
        this.RemoveAll(elementSize, destructor);
        this.AddMultipleToTail(count, elementSize);
    }

    public void SetCountNonDestructively(int count, NumberType elementSize = NumberType_Int32, DestructorFunc destructor) {
        int delta = count - this.m_Size;
        if (delta > 0) {
            this.AddMultipleToTail(delta, elementSize);
        } else if (delta < 0) {
            this.RemoveMultipleFromTail(-delta, elementSize, destructor);
        }
    }

    public bool IsExternallyAllocated() {
        return (this.m_nGrowSize < 0);
    }

    public void Purge(NumberType elementSize = NumberType_Int32, DestructorFunc destructor) {
        this.RemoveAll(elementSize, destructor);
        
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
            return this.m_pElements;
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

static void CheckSizeWithIndex(NumberType elementSize, int& offset, int index)
{
    switch (elementSize) { 
        case NumberType_Int8: { 
            offset = index; 
        } 

        case NumberType_Int16: { 
            offset = index * 2; 
        } 

        case NumberType_Int32: { 
            offset = index * 4; 
        } 

        default: { 
            ThrowError("Invalid elementSize (%d). [%d, %d, %d]", NumberType_Int8, NumberType_Int16, NumberType_Int32);
        } 
    } 
}

static void CheckSize(NumberType elementSize, int& offset)
{
    switch (elementSize) { 
        case NumberType_Int8: { 
            offset = 1; 
        } 

        case NumberType_Int16: { 
            offset = 2; 
        } 

        case NumberType_Int32: { 
            offset = 4; 
        } 

        default: { 
            ThrowError("Invalid elementSize (%d). [%d, %d, %d]", NumberType_Int8, NumberType_Int16, NumberType_Int32);
        } 
    } 
}
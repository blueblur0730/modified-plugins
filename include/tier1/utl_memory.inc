/** Double-include prevention */
#if defined _utl_memory_included
    #endinput
#endif
#define _utl_memory_included

#if defined _smmem_included_
//-----------------------------------------------------------------------------
// Grows the memory
//-----------------------------------------------------------------------------
stock int UtlMemory_CalcNewAllocationCount( int nAllocationCount, int nGrowSize, int nNewSize, int nBytesItem )
{
	if ( nGrowSize )
	{ 
		nAllocationCount = ((1 + ((nNewSize - 1) / nGrowSize)) * nGrowSize);
	}
	else 
	{
		if ( !nAllocationCount )
		{
			// Compute an allocation which is at least as big as a cache line...
			nAllocationCount = (31 + nBytesItem) / nBytesItem;
		}

		while (nAllocationCount < nNewSize)
		{
			nAllocationCount *= 2;
		}
	}

	return nAllocationCount;
}
#endif
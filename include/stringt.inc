/** Double-include prevention */
#if defined _stringt_included
    #endinput
#endif
#define _stringt_included

#include <address_base>

#pragma newdecls required
#pragma semicolon 1

/**
 * Author   dysphie
 * url      https://github.com/dysphie/nmo-guard/blob/main/scripting/nmo-guard/entity-outputs.sp
 *
 * Improve  by F1F88
 * url      https://github.com/F1F88
 * Version  1.0.0
 * 
 * Extended by blueblur
 * url      https://github.com/blueblur0730/modified-plugins
 * Version  1.1.0
 * Date: 2025-11-14
 */


methodmap Stringt < AddressBase
{
    public Stringt(Address addr) {
        return view_as<Stringt>(addr);
    }

    /**
     * ><(((°>
     *
     * @param buffer    Buffer to store stringt in.
     * @param maxlen    Maximum length of buffer.
     *
     * @return          store the number of bytes written.
     * @error           stringt address is null or maxlen <= 0.
     */
    public int ToCharArray(char[] buffer, int maxlen) {
        if (this.IsNull()) {
            ThrowError("Stringt address is null.");
        }

        return UTIL_StringtToCharArray(this, buffer, maxlen);
    }

    // included null terminator.
    public int strlen() {
        if (this.IsNull()) {
            ThrowError("Stringt address is null.");
        }

        return UTIL_StrLen(this);
    }

    public Stringt strcpy(Stringt pDest) {
        if (this.IsNull()) {
            ThrowError("Stringt address is null.");
        }

        return UTIL_StrCpy(pDest, this);
    }

    public Stringt strncpy(Stringt pDest, int nMaxLen) {
        if (this.IsNull()) {
            ThrowError("Stringt address is null.");
        }

        return UTIL_StrnCpy(pDest, this, nMaxLen);
    }

    public Stringt strstr(Stringt pStr2) {
        if (this.IsNull()) {
            ThrowError("Stringt address is null.");
        }

        return UTIL_StrStr(this, pStr2);
    }

#if defined _smmem_included_
    public Stringt strdup() {
        if (this.IsNull()) {
            ThrowError("Stringt address is null.");
        }

        return UTIL_StrDup(this);
    }
#endif
}


/**
 * ><(((°>
 *
 * @param stringt   stringt address.
 * @param buffer    Buffer to store stringt in.
 * @param maxlen    Maximum length of buffer.
 *
 * @return          store the number of bytes written.
 * @error           stringt address is null or maxlen <= 0.
 */
stock int UTIL_StringtToCharArray(Stringt stringt, char[] buffer, int maxlen)
{
    if (stringt.addr == Address_Null)
        ThrowError("Stringt address is null.");

    if (maxlen <= 0)
        ThrowError("The parameter maxlen must be greater than 0.");

    int  index  = 0;
    int  end    = maxlen - 1;       // 保留 1 位给结束符
    char character;

    while (index < end)             // 读取到 buffer 没有剩余空间或者字符串结束
    {
        character = LoadFromAddress(stringt.addr + index, NumberType_Int8);

        if (character =='\0')       // 字符串结束
            break;

        buffer[index] = character;  // 将字符串内容写入 buffer
        ++index;                    // 将指针移向下一个字符应该存储在 buffer 中的相应下标
    }

    buffer[index] = '\0';           // 结束符
    return index;
}

// not safe, did not check the length.
stock Stringt UTIL_StrCpy(Stringt pDest, const Stringt pSrc) 
{
    if (pDest.addr == Address_Null || pSrc.addr == Address_Null) {
        ThrowError("Stringt address is null.");
    }

    int nLen = 0;
    char c = '\0';

    while ((c = LoadFromAddress(pSrc.addr + nLen, NumberType_Int8)) != '\0') {
        StoreToAddress(pDest.addr + nLen, c, NumberType_Int8);
        nLen++;
    }

    StoreToAddress(pDest.addr + nLen, '\0', NumberType_Int8);
    return pDest;
}

stock Stringt UTIL_StrnCpy(Stringt pDest, const Stringt pSrc, int nMaxLen) {
    if (pDest.addr == Address_Null || pSrc.addr == Address_Null) {
        ThrowError("Stringt address is null.");
    }

    int nLen = nMaxLen;
    int nLoop = 0;
    char c = '\0';
    while ((c = LoadFromAddress(pSrc.addr + nLoop, NumberType_Int8)) != '\0' && nLen > 0) {
        StoreToAddress(pDest.addr + nLoop, c, NumberType_Int8);
        nLen--;
        nLoop++;
    }

    while (nLen > 0) {
        StoreToAddress(pDest.addr + nLoop, '\0', NumberType_Int8);
        nLen--;
        nLoop++;
    }

    StoreToAddress(pDest.addr + nLoop, '\0', NumberType_Int8);
    return pDest;
}

stock Stringt UTIL_StrStr(Stringt pStr1, Stringt pStr2) {
    if (pStr1.addr == Address_Null || pStr2.addr == Address_Null) {
        ThrowError("Stringt address is null.");
    }

    int nLen1 = 0;
    int nLen2 = 0;

    if (LoadFromAddress(pStr2.addr + nLen2, NumberType_Int8) == '\0') {
       return pStr1;
    }

    Address pStr1End = Address_Null;
    Address pStr2Start = Address_Null;
    while (LoadFromAddress(pStr1.addr + nLen1, NumberType_Int8) != '\0') {
        pStr1End = pStr1.addr + nLen1;
        pStr2Start = pStr2.addr;

        while ((LoadFromAddress(pStr1End, NumberType_Int8) != '\0') && (LoadFromAddress(pStr2Start, NumberType_Int8) != '\0' ) && 
                (LoadFromAddress(pStr1End, NumberType_Int8) == LoadFromAddress(pStr2Start, NumberType_Int8))) {
            pStr1End += 1;
            pStr2Start += 1;
        }

        if ((LoadFromAddress(pStr2Start, NumberType_Int8) == '\0')) {
            return view_as<Stringt>(pStr1End);
        }

        if ((LoadFromAddress(pStr1End, NumberType_Int8) == '\0')) {
            return view_as<Stringt>(Address_Null);
        }

        nLen1++;
    }

    return view_as<Stringt>(Address_Null);
}

// included null terminator.
stock int UTIL_StrLen(Stringt pString) {
    if (pString.addr == Address_Null) {
        ThrowError("Stringt address is null.");
    }

    int nLen = 0;
    while (LoadFromAddress(pString.addr + nLen, NumberType_Int8) != '\0') {
        nLen++;
    }

    return nLen;
}

#if defined _smmem_included_
stock Stringt UTIL_StrDup(Stringt pString) 
{
    if (pString.addr == Address_Null)
        ThrowError("Stringt address is null.");

    //char szString[PLATFORM_MAX_PATH];
    //int nLen = pString.ToCharArray(szString, sizeof(szString)); // 字符串长度, 包括结束符, 相当于 strlen(pString) + 1

    // included null terminator.
    int nLen = UTIL_StrLen(pString);

    if (nLen <= 0) {
        return view_as<Stringt>(Address_Null);
    }

    any pDest = malloc(nLen);
    if (!pDest) {
        return view_as<Stringt>(Address_Null);
    }

    UTIL_StrCpy(view_as<Stringt>(pDest), pString);
    return view_as<Stringt>(pDest);
}
#endif
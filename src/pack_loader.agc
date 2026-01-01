/**
 * File: pack_loader.agc
 * Author: nonom
 * Description: Asset loader for XOR-obfuscated .pak files
 * Created: 2025-12-26
 *
 * Generate assets.pak using: python.exe build_assets.py media media/assets.pak
 * 
 * USAGE:
 *   1. #include "src/pack_loader.agc"
 *   2. Call Pack_Init("assets.pak") at startup
 *   3. Use:
 *        - Pack_LoadImage()
 *        - Pack_LoadSound()
 *        - Pack_LoadMusic()
 *        - Pack_LoadText()
 *        - Pack_LoadBytes()
 *   4. Call Pack_Close() before exit
 */

// Key must be exactly 32 characters and match build_assets.py
// Avoid obvious/plain strings.
#constant PACK_KEY_STRING "my-secret-game-key-32-bytes!!!!!"

/**
 * AssetInfo
 * Metadata for a packed asset.
 */
type AssetInfo
    path as string
    offset as integer
    length as integer
endtype

// Global state
global g_AssetManifest as AssetInfo[]
global g_PackFileID as integer = 0
global g_PackDataStart as integer = 0
global g_KeyMemblock as integer = 0

/**
 * Pack_Init
 * Opens the pack file and parses the file table.
 */
function Pack_Init(filePath as string)
    local i as integer
    local fileCount as integer

    // Validate key length
    if len(PACK_KEY_STRING) <> 32
        // Key must be exactly 32 bytes.
        exitfunction
    endif

    // Create key memblock for fast XOR
    g_KeyMemblock = CreateMemblock(32)
    for i = 1 to 32
        SetMemblockByte(g_KeyMemblock, i-1, Asc(Mid(PACK_KEY_STRING, i, 1)))
    next i

    // Open .pak file
    if GetFileExists(filePath) = 0
        // File not found.
        exitfunction
    endif

    g_PackFileID = OpenToRead(filePath)
    
    // Read file count
    fileCount = ReadInteger(g_PackFileID)
    
    if fileCount < 0 or fileCount > 100000
        // Invalid manifest.
        exitfunction
    endif

    // Read manifest
    if fileCount > 0
        g_AssetManifest.length = fileCount - 1
        
        for i = 0 to fileCount - 1
            g_AssetManifest[i].path = Pack_ReadString(g_PackFileID)
            g_AssetManifest[i].offset = ReadInteger(g_PackFileID)
            g_AssetManifest[i].length = ReadInteger(g_PackFileID)
        next i
    endif
    
    // Store data start position
    g_PackDataStart = GetFilePos(g_PackFileID)
endfunction

/**
 * Pack_DecryptMemblock
 * Decrypts a memblock in-place using XOR.
 */
function Pack_DecryptMemblock(memID as integer, size as integer)
    local i as integer
    local byteVal as integer
    local keyByte as integer

    for i = 0 to size - 4 step 4
        byteVal = GetMemblockInt(memID, i)
        keyByte = GetMemblockInt(g_KeyMemblock, Mod(i, 32))
        SetMemblockInt(memID, i, byteVal ~~ keyByte)
    next i
endfunction

/**
 * Pack_ReadToMemblock
 * Reads bytes from file to memblock.
 */
function Pack_ReadToMemblock(fileID as integer, memID as integer, size as integer)
    local i as integer
    for i = 0 to size - 4 step 4
        SetMemblockInt(memID, i, ReadInteger(fileID))
    next i
endfunction

/**
 * Pack_LoadImage
 * Loads an image from the pack. Returns Image ID.
 */
function Pack_LoadImage(virtualPath as string)
    local index as integer
    local i as integer
    local mem as integer
    local imgID as integer
    local offset as integer
    local length as integer

    // Find in manifest
    index = -1
    for i = 0 to g_AssetManifest.length
        if g_AssetManifest[i].path = virtualPath
            index = i
            exit
        endif
    next i
    
    if index = -1
        // Image not found.
        exitfunction 0
    endif
    
    // Read and decrypt
    offset = g_AssetManifest[index].offset
    length = g_AssetManifest[index].length
    local paddedSize as integer
    paddedSize = (length + 3) / 4 * 4
    
    SetFilePos(g_PackFileID, g_PackDataStart + offset)
    
    mem = CreateMemblock(paddedSize)
    Pack_ReadToMemblock(g_PackFileID, mem, paddedSize)
    Pack_DecryptMemblock(mem, paddedSize)
    
    // Detect format and load
    if GetMemblockByte(mem, 0) = 137 and GetMemblockByte(mem, 1) = 80 and GetMemblockByte(mem, 2) = 78 and GetMemblockByte(mem, 3) = 71
        // PNG Signature matches (89 50 4E 47 ...)
        imgID = CreateImageFromPNGMemblock(mem)
    else
        // Try generic loader for others
        imgID = CreateImageFromMemblock(mem)
    endif
    
    DeleteMemblock(mem)
endfunction imgID

/**
 * Pack_LoadText
 * Loads a text file from the pack. Returns the content as a string.
 */
function Pack_LoadText(virtualPath as string)
    local index as integer
    local i as integer
    local mem as integer
    local offset as integer
    local length as integer
    local startOffset as integer
    local result as string

    index = -1
    for i = 0 to g_AssetManifest.length
        if g_AssetManifest[i].path = virtualPath
            index = i
            exit
        endif
    next i
    
    if index = -1
        // Text not found.
        exitfunction ""
    endif
    
    // Read and decrypt
    offset = g_AssetManifest[index].offset
    length = g_AssetManifest[index].length
    local paddedSize as integer
    paddedSize = (length + 3) / 4 * 4
    
    SetFilePos(g_PackFileID, g_PackDataStart + offset)
    
    mem = CreateMemblock(paddedSize)
    Pack_ReadToMemblock(g_PackFileID, mem, paddedSize)
    Pack_DecryptMemblock(mem, paddedSize)
    
    // Skip BOM if present (EF BB BF)
    startOffset = 0
    if length >= 3 and GetMemblockByte(mem, 0) = 239 and GetMemblockByte(mem, 1) = 187 and GetMemblockByte(mem, 2) = 191
        startOffset = 3
    endif
    
    result = GetMemblockString(mem, startOffset, length - startOffset)
    DeleteMemblock(mem)
endfunction result

/**
 * Pack_LoadBytes
 * Loads raw bytes from the pack. Returns a memblock ID (caller deletes).
 */
function Pack_LoadBytes(virtualPath as string)
    local index as integer
    local i as integer
    local mem as integer
    local offset as integer
    local length as integer
    local paddedSize as integer
    local memData as integer

    index = -1
    for i = 0 to g_AssetManifest.length
        if g_AssetManifest[i].path = virtualPath
            index = i
            exit
        endif
    next i
    
    if index = -1
        // Bytes not found.
        exitfunction 0
    endif
    
    offset = g_AssetManifest[index].offset
    length = g_AssetManifest[index].length
    paddedSize = (length + 3) / 4 * 4
    
    SetFilePos(g_PackFileID, g_PackDataStart + offset)
    
    mem = CreateMemblock(paddedSize)
    Pack_ReadToMemblock(g_PackFileID, mem, paddedSize)
    Pack_DecryptMemblock(mem, paddedSize)
    
    memData = CreateMemblock(length)
    for i = 0 to length - 1
        SetMemblockByte(memData, i, GetMemblockByte(mem, i))
    next i
    
    DeleteMemblock(mem)
endfunction memData

/**
 * Pack_LoadSound
 * Loads a sound (WAV/OGG) from the pack. Returns Sound ID.
 */
function Pack_LoadSound(virtualPath as string)
    local index as integer
    local i as integer
    local mem as integer
    local soundID as integer
    local offset as integer
    local length as integer
    local paddedSize as integer
    local memData as integer
    local magic0 as integer
    local magic1 as integer
    local magic2 as integer
    local magic3 as integer
    local isOgg as integer

    index = -1
    for i = 0 to g_AssetManifest.length
        if g_AssetManifest[i].path = virtualPath
            index = i
            exit
        endif
    next i
    
    if index = -1
        // Sound not found.
        exitfunction 0
    endif
    
    offset = g_AssetManifest[index].offset
    length = g_AssetManifest[index].length
    paddedSize = (length + 3) / 4 * 4
    
    SetFilePos(g_PackFileID, g_PackDataStart + offset)
    
    mem = CreateMemblock(paddedSize)
    Pack_ReadToMemblock(g_PackFileID, mem, paddedSize)
    Pack_DecryptMemblock(mem, paddedSize)
    
    memData = CreateMemblock(length)
    for i = 0 to length - 1
        SetMemblockByte(memData, i, GetMemblockByte(mem, i))
    next i
    DeleteMemblock(mem)
    
    // Detect format by magic
    magic0 = GetMemblockByte(memData, 0)
    magic1 = GetMemblockByte(memData, 1)
    magic2 = GetMemblockByte(memData, 2)
    magic3 = GetMemblockByte(memData, 3)
    
    isOgg = 0
    if magic0 = 79 and magic1 = 103 and magic2 = 103 and magic3 = 83
        isOgg = 1 // "OggS"
    endif
    
    if isOgg = 1
        soundID = CreateSoundFromOGGMemblock(memData)
    else
        soundID = CreateSoundFromMemblock(memData)
    endif
    
    DeleteMemblock(memData)
endfunction soundID

/**
 * Pack_LoadMusic
 * Loads music/streaming OGG (or sound fallback) from the pack. Returns Music/Sound ID.
 */
function Pack_LoadMusic(virtualPath as string)
    local index as integer
    local i as integer
    local mem as integer
    local musicID as integer
    local offset as integer
    local length as integer
    local paddedSize as integer
    local memData as integer
    local magic0 as integer
    local magic1 as integer
    local magic2 as integer
    local magic3 as integer
    local isOgg as integer

    index = -1
    for i = 0 to g_AssetManifest.length
        if g_AssetManifest[i].path = virtualPath
            index = i
            exit
        endif
    next i
    
    if index = -1
        // Music not found.
        exitfunction 0
    endif
    
    offset = g_AssetManifest[index].offset
    length = g_AssetManifest[index].length
    paddedSize = (length + 3) / 4 * 4
    
    SetFilePos(g_PackFileID, g_PackDataStart + offset)
    
    mem = CreateMemblock(paddedSize)
    Pack_ReadToMemblock(g_PackFileID, mem, paddedSize)
    Pack_DecryptMemblock(mem, paddedSize)
    
    memData = CreateMemblock(length)
    for i = 0 to length - 1
        SetMemblockByte(memData, i, GetMemblockByte(mem, i))
    next i
    DeleteMemblock(mem)
    
    magic0 = GetMemblockByte(memData, 0)
    magic1 = GetMemblockByte(memData, 1)
    magic2 = GetMemblockByte(memData, 2)
    magic3 = GetMemblockByte(memData, 3)
    
    isOgg = 0
    if magic0 = 79 and magic1 = 103 and magic2 = 103 and magic3 = 83
        isOgg = 1
    endif
    
    if isOgg = 1
        musicID = CreateMusicFromOGGMemblock(memData)
        if musicID = 0
            musicID = CreateSoundFromOGGMemblock(memData)
        endif
    else
        musicID = CreateSoundFromMemblock(memData)
    endif
    
    DeleteMemblock(memData)
endfunction musicID

/**
 * Pack_ReadString
 * Helper: Reads a length-prefixed string from file.
 */
function Pack_ReadString(fileID as integer)
    local strLen as integer
    local mem as integer
    local i as integer
    local resultStr as string
    
    strLen = ReadInteger(fileID)
    resultStr = ""
    if strLen > 0 and strLen < 2048
        mem = CreateMemblock(strLen)
        for i = 0 to strLen - 1
            SetMemblockByte(mem, i, ReadByte(fileID))
        next i
        resultStr = GetMemblockString(mem, 0, strLen)
        DeleteMemblock(mem) 
    endif
endfunction resultStr

/**
 * Pack_Close
 * Closes the pack file and releases the key memblock.
 */
function Pack_Close()
    if g_PackFileID > 0
        CloseFile(g_PackFileID)
        g_PackFileID = 0
    endif
    if g_KeyMemblock > 0
        DeleteMemblock(g_KeyMemblock)
        g_KeyMemblock = 0
    endif
endfunction

/**
 * File: common.agc
 * Description: Common functions and definitions for example purpose.
 * Created: 2025-12-27
 */

type AppSettingsType
    width      as integer
    height     as integer
    fullscreen as integer
    vsync      as integer
endtype

type AppDebugType
    showFps  as integer
    logLevel as string
endtype

type AppConfigType
    title    as string
    version  as string
    author   as string
    settings as AppSettingsType
    debug    as AppDebugType
endtype


function Load_JSON(path as string)
    local s as string
    local mem as integer
    mem = CreateMemblockFromFile(path)
    s = GetMemblockString(mem, 0, GetMemblockSize(mem))
    DeleteMemblock(mem)
endfunction s
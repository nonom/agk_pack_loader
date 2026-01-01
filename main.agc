/**
 * File: main.agc
 * Description: Example project using Pack Loader
 * Created: 2025-12-27
 * 
 * This demonstrates loading images, text, and sounds from an XOR-obfuscated .pak file.
 * 
 * BUILD INSTRUCTIONS:
 *   1. Run: "python build_assets.py media media/assets.pak"
 *   2. Compile and run this project in AppGameKit
 */

#option_explicit

#include "src/common.agc"

// Include the pack loader
#include "src/pack_loader.agc"

// Configuration:
// Set to 1 for packed mode
#constant USE_PACK 1

// Load resources
global logoImg as integer
global appConfig as AppConfigType
global clickSnd as integer
global blobMb as integer
global blobSize as integer

if USE_PACK
	// Initialize pack loader
	Pack_Init("assets.pak")
    
    // Load from assets.pak
    logoImg = Pack_LoadImage("img/logo.png")
    appConfig.fromJSON(Pack_LoadText("data/config.json"))
    clickSnd = Pack_LoadSound("sfx/click.ogg")
    blobMb = Pack_LoadBytes("data/config.json")
    if blobMb > 0
        blobSize = GetMemblockSize(blobMb)
    endif
else
	// Without PAK, as usual
    logoImg = LoadImage("img/logo.png")
    appConfig.fromJSON(Load_JSON("data/config.json"))
    clickSnd = LoadSoundOGG("sfx/click.ogg")
    blobMb = CreateMemblockFromFile("data/config.json")
    if blobMb > 0
        blobSize = GetMemblockSize(blobMb)
    endif
endif


SetWindowTitle(appConfig.title)
SetWindowSize(appConfig.settings.width, appConfig.settings.height, 0)
SetVirtualResolution(appConfig.settings.width, appConfig.settings.height)
SetSyncRate(60, 0)
SetVSync(appConfig.settings.vsync)
UseNewDefaultFonts(1)

// Create sprite from loaded image
global logoSprite as integer
logoSprite = CreateSprite(logoImg)
SetSpritePosition(logoSprite, 400 - GetSpriteWidth(logoSprite) / 2, 200)

// Main loop
do
    // Display info (print JSON fields)
    Print("Pack Loader Example")
    Print("")
    Print("USE_PACK: " + Str(USE_PACK))
    Print("")
    Print("Config fields:")
    Print(" title: " + appConfig.title)
    Print(" version: " + appConfig.version)
    Print(" author: " + appConfig.author)
    Print("")
    Print(" settings.width: " + Str(appConfig.settings.width))
    Print(" settings.height: " + Str(appConfig.settings.height))
    Print(" settings.fullscreen: " + Str(appConfig.settings.fullscreen))
    Print(" settings.vsync: " + Str(appConfig.settings.vsync))
    Print("")
    Print(" debug.showFps: " + Str(appConfig.debug.showFps))
    Print(" debug.logLevel: " + appConfig.debug.logLevel)
    Print("")
    Print(" Text memblock size: " + Str(blobSize))
    Print("")
    Print("Click or Touch to play sound")
    Print("Press ESC to exit")
    
    // Play sound on Click/Touch
    if GetPointerPressed()
        PlaySound(clickSnd)
    endif
    
    // Exit on ESC
    if GetRawKeyPressed(27) = 1 then exit
    
    Sync()
loop

// Cleanup
if blobMb > 0 then DeleteMemblock(blobMb)
if USE_PACK = 1 then Pack_Close()
end

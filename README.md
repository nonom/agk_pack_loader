# AGK Pack Loader

A high-performance, XOR-obfuscated asset loading system for AppGameKit (AGK). This tool allows you to package your game assets into a single obfuscated file and load them directly from memory, improving resistance to casual extraction and load times.

## Key Features

- **XOR Obfuscation**: Basic protection to deter casual extraction.
- **Vectorized Loading**: Optimized 4-byte integer reading and decryption for maximum performance in AGK Tier 1.
- **Direct Memory Loading**: Assets stream from memblocks straight into AGK IDs, minimizing disk I/O.
- **4-Byte Alignment**: Assets are automatically padded to ensure high-speed integer-aligned CPU access.

## 1. Packing Assets

Use the provided Python script to bundle your `media` folder into a single `.pak` file.

**Syntax:**
```bash
python build_assets.py <source_folder> <output_file>
```

**Example:**
```bash
python build_assets.py media media/assets.pak
```
*   This scans the `media` folder.
*   Aligns all files to 4-byte boundaries (adding padding if necessary).
*   XOR-obfuscates the data using the key defined in the script.
*   Generates `media/assets.pak`.

> **Note:** Ensure the `XOR_KEY` in `build_assets.py` matches the one in `src/pack_loader.agc`.

## 2. Integration in AppGameKit

Include the loader in your main project file.

```agc
#include "src/pack_loader.agc"

// Optional: Use a constant to toggle between Packed and Loose modes
#constant USE_PACK 1
```

## 3. Usage Examples

### Initialization
Initialize the loader at the start of your game. This reads the manifest headers into memory.

```agc
if USE_PACK
    Pack_Init("assets.pak")
endif
```

### Loading Images
Loads an image from the pack into an AGK Image ID (PNG/JPG).

```agc
global playerImg as integer

if USE_PACK
    // Load directly from memory (fastest)
    playerImg = Pack_LoadImage("img/player.png")
else
    // Fallback for development (loose files)
    playerImg = LoadImage("img/player.png")
endif
```

### Loading Sounds
Loads a sound from the pack into an AGK Sound ID (WAV/OGG).

```agc
global clickSnd as integer

if USE_PACK
    clickSnd = Pack_LoadSound("sfx/click.ogg")
else
    clickSnd = LoadSoundOGG("sfx/click.ogg")
endif

// Usage
PlaySound(clickSnd)
```

### Loading Music
Loads streaming music from the pack into an AGK Music/Sound ID (OGG preferred).

```agc
global musicID as integer

if USE_PACK
    musicID = Pack_LoadMusic("music/theme.ogg")
else
    musicID = LoadMusicOGG("music/theme.ogg")
endif

PlayMusic(musicID, 1) // loop
```

### Loading Text
Reads a text file from the pack and returns it as a string (config, shaders, levels).

```agc
local jsonContent as string

if USE_PACK
    jsonContent = Pack_LoadText("data/config.json")
else
    // Use helper for loose files (reads entire file to string)
    jsonContent = Load_JSON("data/config.json")
endif

// Parse the JSON
myConfig.fromJSON(jsonContent)
```

### Loading Binary
Gets a memblock with the exact bytes from the pack; caller deletes it.

```agc
local bytesID as integer
bytesID = Pack_LoadBytes("data/blob.bin")

if bytesID > 0
    // Read or pass the memblock to your parser
    // ...
    DeleteMemblock(bytesID)
endif
```

### Cleanup
Close the pack file when the application terminates to free file handles and memory.

```agc
Pack_Close()
```

## Usage

1. Ensure Python 3 is installed and available as `python` or `python3` in your PATH (only needed to build assets).
2. Build the pack:
   ```bash
   python build_assets.py media media/assets.pak
   ```
3. In your AGK project:
   - `#include "src/pack_loader.agc"`
   - Call `Pack_Init("assets.pak")` at startup.
   - Use the loader functions as needed:
     - `Pack_LoadImage()`
     - `Pack_LoadSound()`
     - `Pack_LoadMusic()`
     - `Pack_LoadText()`
     - `Pack_LoadBytes()`
   - Call `Pack_Close()` on shutdown.

## API Reference

| Function | Return | Description |
| :--- | :--- | :--- |
| `Pack_Init(filePath)` | `void` | Opens the pack file and parses the file table. |
| `Pack_LoadImage(virtualPath)` | `integer` | Loads an image from the pack. Returns Image ID. |
| `Pack_LoadSound(virtualPath)` | `integer` | Loads a sound (WAV/OGG) from the pack. Returns Sound ID. |
| `Pack_LoadMusic(virtualPath)` | `integer` | Loads music/streaming OGG (or sound fallback) from the pack. Returns Music/Sound ID. |
| `Pack_LoadText(virtualPath)` | `string` | Loads a text file from the pack. Returns the content as a string. |
| `Pack_LoadBytes(virtualPath)` | `integer` | Loads raw bytes from the pack. Returns a memblock ID (caller deletes). |
| `Pack_Close()` | `void` | Closes the pack file and releases the key memblock. |

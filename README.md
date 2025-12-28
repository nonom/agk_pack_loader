# AGK Pack Loader

A high-performance, encrypted asset loading system for AppGameKit (AGK). This tool allows you to package your game assets into a single obfuscated file and load them directly from memory, improving security and load times.

## Key Features

*   **XOR Encryption**: Basic obfuscation to protect assets from casual extraction.
*   **Vectorized Loading**: Optimized 4-byte integer reading and decryption for maximum performance in AGK Tier 1.
*   **Direct Memory Loading**: Images and sounds are loaded directly from memory (RAM) without writing temporary files to disk, reducing I/O overhead.
*   **4-Byte Alignment**: Assets are automatically padded to ensure high-speed integer-aligned CPU access.

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
*   Encrypts the data using the key defined in the script.
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
Loads an image directly from the pack into an AGK Image ID. Support includes PNG and JPG.

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
Loads a sound effect file (e.g., .wav, .ogg).

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

### Loading JSON / Text
Reads a text file from the pack and returns it as a string. Useful for configuration or level data.

```agc
local jsonContent as string

if USE_PACK
    jsonContent = Pack_LoadJSON("data/config.json")
else
    // Use helper for loose files (reads entire file to string)
    jsonContent = Load_JSON("data/config.json")
endif

// Parse the JSON
myConfig.fromJSON(jsonContent)
```

### Cleanup
Close the pack file when the application terminates to free file handles and memory.

```agc
Pack_Close()
```

## API Reference

| Function | Return | Description |
| :--- | :--- | :--- |
| `Pack_Init(path)` | `void` | Opens the pack file and parses the file table. |
| `Pack_LoadImage(path)` | `integer` | Decrypts and creates an image from memory. Returns Image ID. |
| `Pack_LoadSound(path)` | `integer` | Decrypts and loads a sound. Returns Sound ID. |
| `Pack_LoadJSON(path)` | `string` | Decrypts and returns the file content as a string. |
| `Pack_Close()` | `void` | Closes the pack file and releases the encryption key memblock. |

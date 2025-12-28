#!/usr/bin/env python3
"""
Asset Packer for AppGameKit
Simple XOR encryption with hardcoded key.

Usage: python build_assets.py media media/assets.pak
"""

import os
import argparse

# ============================================================
# CONFIGURATION - Change this key as needed.
# Must be exactly 32 characters and match pack_loader.agc
# ============================================================
XOR_KEY = "my-secret-game-key-32-bytes!!!!!"

def xor_encrypt(data, key):
    """Applies simple XOR encryption to a block of bytes."""
    key_bytes = key.encode('utf-8')
    key_len = len(key_bytes)
    return bytes([b ^ key_bytes[i % key_len] for i, b in enumerate(data)])

def create_asset_pack(source_dir, output_file):
    """
    Scans a directory, encrypts its files, and packages them into a
    single .pak file with a manifest.
    """
    manifest = []
    current_offset = 0
    files_to_process = []
    abs_output_path = os.path.normcase(os.path.abspath(output_file))

    print(f"Scanning: {source_dir}")
    print(f"Using key: {XOR_KEY[:8]}... ({len(XOR_KEY)} bytes)")

    # Step 1: Build manifest
    for root, _, files in os.walk(source_dir):
        for file in files:
            file_path = os.path.join(root, file)
            # Exclude bytecode.byc and the output .pak file itself
            if file == "bytecode.byc" or os.path.normcase(os.path.abspath(file_path)) == abs_output_path:
                continue
            # Don't pack the output file itself (redundant, but kept for safety)
            if os.path.normcase(os.path.abspath(file_path)) == abs_output_path:
                continue

            relative_path = os.path.relpath(file_path, source_dir).replace('\\', '/')
            file_size = os.path.getsize(file_path)
            
            # Align to 4 bytes
            padded_size = (file_size + 3) & ~3
            
            print(f"  + {relative_path} ({file_size} bytes -> {padded_size} padded)")
            
            manifest.append({
                "path": relative_path,
                "offset": current_offset,
                "length": file_size,
                "padded_length": padded_size
            })
            
            files_to_process.append(file_path)
            current_offset += padded_size

    if not manifest:
        print("No files found!")
        return

    # Step 2: Write .pak file
    print(f"\nWriting: {output_file}")
    
    os.makedirs(os.path.dirname(output_file) or '.', exist_ok=True)

    with open(output_file, 'wb') as f:
        # Header: file count (4 bytes, little-endian)
        f.write(len(manifest).to_bytes(4, byteorder='little'))
        
        # Manifest entries
        for item in manifest:
            path_bytes = item['path'].encode('utf-8')
            f.write(len(path_bytes).to_bytes(4, byteorder='little'))
            f.write(path_bytes)
            f.write(item['offset'].to_bytes(4, byteorder='little'))
            f.write(item['length'].to_bytes(4, byteorder='little'))
        
        # Encrypted data blob
        for file_path in files_to_process:
            with open(file_path, 'rb') as source_f:
                file_data = source_f.read()
                
                # Padding
                padding = (4 - (len(file_data) % 4)) % 4
                if padding > 0:
                    file_data += b'\0' * padding
                
                encrypted_data = xor_encrypt(file_data, XOR_KEY)
                f.write(encrypted_data)
    
    total_size = os.path.getsize(output_file)
    print(f"\nSuccess! {len(manifest)} files -> {output_file}")
    print(f"Total size: {total_size / 1024:.2f} KB")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Asset packer for AppGameKit",
        epilog="Example: python build_assets.py media assets.pak"
    )
    parser.add_argument("source", help="Source directory (e.g., media)")
    parser.add_argument("output", help="Output .pak file (e.g., assets.pak)")
    
    args = parser.parse_args()

    # Validate key length
    if len(XOR_KEY) != 32:
        print(f"ERROR: XOR_KEY must be exactly 32 bytes. Current: {len(XOR_KEY)}")
        exit(1)

    if not os.path.isdir(args.source):
        print(f"ERROR: Directory not found: {args.source}")
        exit(1)
    
    create_asset_pack(args.source, args.output)

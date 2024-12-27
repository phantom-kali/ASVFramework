#!/bin/bash
set -e  # Exit on error

# Create output and data directories
mkdir -p build
mkdir -p data

# Compile assembly files with stack note section
for file in SVMCoreMath.asm SVMDataOps.asm SVMModel.asm SVMUtils.asm test_svm.asm; do
    echo "Compiling $file..."
    nasm -f elf64 -g -F dwarf \
         -i $(dirname "$file") \
         -w+gnu-elf-extensions \
         "$file" -o "build/$(basename "$file" .asm).o"
done

# Link with C library
echo "Linking..."
gcc -no-pie \
    build/*.o \
    -o build/svm_test

chmod +x build/svm_test
echo "Build complete: build/svm_test"

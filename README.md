# ASVFramework

## Overview
This project provides a simple SVM (Support Vector Machine) framework written in Assembly. It is split into several modules:
- SVMCoreMath: Basic math operations (dot product, vector ops).
- SVMDataOps: Data loading, normalization, splitting, etc.
- SVMModel: Core SVM model (weights, bias, training).
- SVMUtils: Utility functions (model saving/loading, accuracy).
- test_svm: Example driver that trains and tests the model.

## Requirements
- NASM assembler (for .asm files).
- GCC (for linking).
- Python (for generating test data).

## Building
1. Run the provided build script:
   ```
   ./build.sh
   ```
2. An executable called `svm_test` will be generated in the `build` folder.

## Running
1. Generate test data (optional):
   ```
   pip install -r requirements.txt
   python3 generate_test_data.py
   ```
2. Run the executable:
   ```
   ./build/svm_test
   ```
3. View the output in your terminal.

## Modules Overview
See "FrameworkModulesOverview" for details on each module and its dependencies.

%include "common.inc"

section .data
    feature_file db "data/features.bin", 0
    label_file db "data/labels.bin", 0
    fmt_result db "Accuracy: %f", 10, 0
    error_msg db "Error loading data", 10, 0
    success_msg db "Data loaded successfully", 10, 0
    debug_path db "Loading file: %s", 10, 0
    err_no_file db "Error: Could not open file %s", 10, 0
    err_alloc db "Error: Memory allocation failed", 10, 0
    err_read db "Error: Failed to read file %s", 10, 0
    err_format db "Error: Invalid file format in %s", 10, 0
    err_train db "Error: Training failed with code %d", 10, 0
    debug_samples db "Debug: Loaded %d samples with %d features", 10, 0
    mem_init_msg db "Initializing memory...", 10, 0

section .bss
    features resd 1024*1024  ; Space for features (up to 1024 samples * 1024 features)
    labels resd 1024        ; Space for labels
    n_samples resd 1        ; Number of samples
    n_features resd 1       ; Number of features
    buffer resb 8           ; Temporary buffer for reading file header

section .text
    global main               ; Export main instead of _start
    extern printf          ; Declare printf as external
    extern initialize_model
    extern train_svm
    extern calculate_accuracy
    extern load_csv
    
main:                       ; Change _start to main
    push rbp                ; Setup stack frame for C
    mov rbp, rsp
    sub rsp, 32           ; Reserve stack space for locals
    
    ; Print memory initialization message
    mov rdi, mem_init_msg
    xor rax, rax
    call printf
    
    ; Clear memory regions
    mov rdi, features
    mov rcx, 1024*1024
    xor eax, eax
    rep stosd            ; Clear features array
    
    mov rdi, labels
    mov rcx, 1024
    xor eax, eax
    rep stosd            ; Clear labels array
    
    ; Initialize counters
    mov dword [n_samples], 0
    mov dword [n_features], 0
    
    ; Load feature file header first to get dimensions
    mov rdi, feature_file
    mov rsi, buffer
    mov rdx, 8           ; Read 8 bytes header
    call read_file_header
    
    ; Check header read result
    cmp rax, -1
    je file_error
    
    ; Extract dimensions from header
    mov eax, dword [buffer]
    mov dword [n_samples], eax
    mov eax, dword [buffer+4]
    mov dword [n_features], eax
    
    ; Verify dimensions
    mov eax, dword [n_samples]
    cmp eax, 1024        ; Max samples
    ja alloc_error
    mov eax, dword [n_features]
    cmp eax, 1024        ; Max features
    ja alloc_error
    
    ; Print debug info for feature file
    mov rdi, debug_path   ; Format string
    mov rsi, feature_file ; Filename argument
    xor rax, rax         ; No floating point arguments
    call printf
    
    ; Load feature data
    mov rdi, feature_file
    mov rsi, features
    mov rdx, n_samples
    call load_csv
    
    ; Check load_csv return value
    cmp rax, -1
    je file_error
    cmp rax, -2
    je read_error
    cmp rax, -3
    je format_error
    
    ; Print debug info
    mov rdi, debug_samples
    mov rsi, [n_samples]
    mov rdx, [n_features]
    xor rax, rax
    call printf
    
    ; Print success message
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, success_msg
    mov rdx, 22         ; length
    syscall
    
    ; Load label data
    mov rdi, label_file
    mov rsi, labels
    mov rdx, n_samples
    call load_csv
    
    ; Initialize SVM model
    mov rdi, [n_features]
    call initialize_model
    
    ; Train model
    mov rdi, features
    mov rsi, labels
    mov rdx, [n_samples]
    mov rcx, [n_features]
    call train_svm
    
    ; Calculate and print accuracy
    mov rdi, features
    mov rsi, labels
    mov rdx, [n_samples]
    call calculate_accuracy
    
    ; Exit with return value
    xor eax, eax           ; Return 0
    leave                  ; Restore stack frame
    ret                    ; Return to C runtime

alloc_error:
    mov rdi, err_alloc
    xor rax, rax
    call printf
    mov eax, 1
    jmp exit

file_error:
    mov rdi, err_no_file
    mov rsi, feature_file
    xor rax, rax
    call printf
    mov eax, 2
    jmp exit

read_error:
    mov rdi, err_read
    mov rsi, feature_file
    xor rax, rax
    call printf
    mov eax, 3
    jmp exit

format_error:
    mov rdi, err_format
    mov rsi, feature_file
    xor rax, rax
    call printf
    mov eax, 4
    jmp exit

error_exit:
    ; Print error
    mov rdi, error_msg
    call printf
    
    mov eax, 1            ; Return 1 (error)
    leave
    ret

exit:
    leave
    ret

; New function to read file header
read_file_header:
    push rbp
    mov rbp, rsp
    
    ; Open file
    mov rax, 2          ; sys_open
    xor rsi, rsi        ; O_RDONLY
    xor rdx, rdx        ; Mode (not used for reading)
    syscall
    
    ; Check for error
    cmp rax, 0
    jl .error
    
    mov r8, rax         ; Save file descriptor
    
    ; Read header
    mov rax, 0          ; sys_read
    mov rdi, r8
    ; rsi already has buffer address
    ; rdx already has size
    syscall
    
    ; Close file
    push rax            ; Save read result
    mov rax, 3          ; sys_close
    mov rdi, r8
    syscall
    pop rax
    
    pop rbp
    ret
    
.error:
    mov rax, -1
    pop rbp
    ret

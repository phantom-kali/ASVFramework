%include "common.inc"

section .data
    delimiter db ',', 0  ; Comma delimiter for CSV parsing
    newline db 10        ; Newline character (line feed)
    buffer_size equ 4096 ; Size of the data buffer
    open_error_msg db "Error opening file", 10, 0
    read_error_msg db "Error reading file", 10, 0
    debug_msg db "Debug: FD=%d, Read=%d bytes", 10, 0
    err_invalid_header db "Error: Invalid file header", 10, 0
    err_buffer_overflow db "Error: Buffer overflow", 10, 0

section .bss
    data_buffer resb buffer_size  ; Buffer for loading data
    parsed_data resd 256          ; Buffer for parsed data (up to 256 elements)

section .text
    global load_csv
    global normalize_data
    global shuffle_data
    global split_data

; Function: load_csv
; Loads data from a CSV file and parses it into an integer array.
; Arguments:
;   rdi - Pointer to the file path (string)
;   rsi - Pointer to the buffer where parsed data is stored
;   rdx - Pointer to the buffer size (output)
; Returns:
;   rax - Number of elements parsed into the buffer

load_csv:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    
    ; Validate input parameters
    test rdi, rdi
    jz invalid_param
    test rsi, rsi
    jz invalid_param
    test rdx, rdx
    jz invalid_param
    
    ; Save parameters
    mov r12, rsi   ; Buffer pointer
    mov r13, rdx   ; Pointer to n_samples
    
    ; Open file
    mov rax, 2     ; sys_open
    xor rsi, rsi   ; O_RDONLY
    mov rdx, 0644o
    syscall
    cmp rax, 0
    jl open_error
    
    mov rbx, rax   ; File descriptor
    
    ; Correct lseek call (skip 8-byte header)
    mov rax, 8     ; sys_lseek on 64-bit
    mov rdi, rbx
    mov rsi, 8     ; 8-byte offset
    xor rdx, rdx   ; SEEK_SET
    syscall
    
    ; Read data
    mov rax, 0     ; sys_read
    mov rdi, rbx
    mov rsi, r12   ; Destination buffer
    mov edx, [r13] ; n_samples (32-bit)
    imul rdx, 4    ; Each sample is 4 bytes
    syscall
    
    ; Close file
    push rax       ; Bytes read
    mov rax, 3     ; sys_close
    mov rdi, rbx
    syscall
    pop rcx        ; Restore bytes read
    
    ; Check read size
    mov eax, [r13] ; n_samples again
    imul rax, 4
    cmp rcx, rax
    jne read_error
    
    ; Return success = number of samples
    mov rax, [r13]
    
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

invalid_param:
    mov rax, -1
    jmp load_exit

invalid_header:
    mov rax, -3
    jmp load_exit

buffer_overflow:
    mov rax, -4
    jmp load_exit

header_error:
    mov rax, -5
    jmp load_exit

load_exit:
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

open_error:
    mov rax, 1                      ; sys_write
    mov rdi, 1                      ; stdout
    mov rsi, open_error_msg
    mov rdx, 18                     ; length
    syscall
    mov rax, -1
    pop rbp
    ret

read_error:
    mov rax, 1                      ; sys_write
    mov rdi, 1                      ; stdout
    mov rsi, read_error_msg
    mov rdx, 18                     ; length
    syscall
    mov rax, -1
    pop rbp
    ret

; Function: normalize_data
; Normalizes the data array based on the given min and max values.
; Arguments:
;   rdi - Pointer to the data array
;   rsi - Number of elements in the array
;   rdx - Minimum value
;   rcx - Maximum value

normalize_data:
    push rbp
    mov rbp, rsp
    push rbx              ; Save rbx as we'll use it

normalize_loop:
    cmp r8, rsi              ; Check if we've reached the end
    jge normalize_end        ; If yes, end the loop

    ; Fix: Proper operand handling for normalization
    mov eax, dword [rdi + r8 * 4]  ; Load 32-bit integer
    sub eax, edx                    ; Subtract min value
    imul eax, 100                   ; Scale by 100
    cdq                             ; Sign extend eax into edx:eax
    mov ebx, ecx                    ; Move max-min to ebx
    idiv ebx                        ; Divide by max-min
    mov dword [rdi + r8 * 4], eax   ; Store result

    inc r8                     ; Move to the next element
    jmp normalize_loop        ; Continue the loop

normalize_end:
    pop rbx               ; Restore rbx
    pop rbp
    ret                       ; Return from the function

; Function: shuffle_data
; Shuffles a data array using Fisher-Yates algorithm.
; Arguments:
;   rdi - Pointer to the data array
;   rsi - Number of elements in the array

shuffle_data:
    push rbp
    mov rbp, rsp
    push rbx                    ; Preserve rbx for data swapping
    push r12                    ; Preserve r12 for temporary storage
    
    xor r8, r8                 ; Initialize counter
shuffle_loop:
    cmp r8, rsi               ; Compare counter with array size
    jge shuffle_end
    
    ; Save current element
    mov ebx, dword [rdi + r8 * 4]  ; Get current element
    
    ; Get random index
    push rdi
    push rsi
    push r8
    call random_index          ; Get random index in rax
    pop r8
    pop rsi
    pop rdi
    
    ; Perform swap
    mov r12d, dword [rdi + rax * 4]     ; Get element at random index
    mov dword [rdi + rax * 4], ebx      ; Put current element at random index
    mov dword [rdi + r8 * 4], r12d      ; Put random element at current position
    
    inc r8
    jmp shuffle_loop

shuffle_end:
    pop r12
    pop rbx
    pop rbp
    ret

; Random Index Generation (Placeholder)
; This function generates a random index in the range [r8, rsi-1]
; Should be replaced with an actual random generator
random_index:
    mov rax, rsi           ; Get the upper bound
    sub rax, r8            ; Get the range
    idiv eax               ; Integer division (will give a crude random index)
    add rax, r8            ; Ensure index starts from r8
    ret                    ; Return the random index

; Function: split_data
; Splits a data array into training and testing sets based on test size.
; Arguments:
;   rdi - Pointer to the data array
;   rsi - Number of elements in the array
;   rdx - Pointer to the training set
;   rcx - Pointer to the testing set
;   rbx - Test size as a float multiplied by 100 (e.g., 20 for 20%)

split_data:
    push rbp
    mov rbp, rsp
    push rbx                  ; Preserve rbx
    push r12                  ; Preserve r12 for count
    push r13                  ; Preserve r13 for offset

    xor r8, r8               ; Loop counter
    
    ; Calculate split index
    mov r12, rsi             ; Store total elements
    imul rbx, r12            ; Multiply by test percentage
    mov rax, rbx
    xor rdx, rdx
    mov rcx, 100
    div rcx                  ; Divide by 100 to get test set size
    mov r13, rax             ; Store test set size
    sub r12, r13             ; r12 now has training set size

split_loop:
    cmp r8, r12             ; Compare with training set size
    jge split_test_start    ; If done with training, start test set
    
    mov eax, [rdi + r8*4]   ; Load data element
    mov [rdx + r8*4], eax   ; Store in training set
    inc r8
    jmp split_loop

split_test_start:
    xor r9, r9              ; Initialize test set counter

split_test_loop:
    cmp r9, r13             ; Compare with test set size
    jge split_end           ; If done, exit
    
    mov r10, r12            ; Get training set size
    add r10, r9             ; Add test counter for source index
    mov eax, [rdi + r10*4]  ; Load data element
    mov [rcx + r9*4], eax   ; Store in test set
    inc r9
    jmp split_test_loop

split_end:
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Fix the effective address calculation
    mov rax, r13          ; Get sample index
    mul rcx               ; Multiply by number of features
    lea rdi, [rdi + rax * 4] ; Calculate address correctly

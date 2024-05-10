section .data
    delimiter db ',', 0  ; Comma delimiter for CSV parsing
    newline db 10        ; Newline character (line feed)
    buffer_size equ 4096 ; Size of the data buffer

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
    ; Open the file
    mov rax, 2              ; System call number for "open"
    mov rdi, 0              ; Flags for read-only access
    syscall                 ; Call the system function to open the file

    ; Read the file into the buffer
    mov rax, 0              ; System call number for "read"
    mov rdi, 3              ; File descriptor for the opened file
    mov rsi, data_buffer    ; Buffer to read into
    mov rdx, buffer_size    ; Maximum bytes to read
    syscall                 ; Read the data

    ; Parse the CSV data into integers
    xor rbx, rbx            ; Loop counter
    xor rcx, rcx            ; Temporary storage for parsed integer

parse_csv:
    cmp byte [data_buffer + rbx], newline ; Check for newline
    je end_of_line          ; If newline, end the parsing

    cmp byte [data_buffer + rbx], delimiter ; Check for delimiter
    je next_integer         ; If delimiter, parse the integer

    ; Convert ASCII digit to integer
    sub byte [data_buffer + rbx], '0'  ; Convert ASCII to digit
    imul rcx, 10            ; Multiply current number by 10 (for digit placement)
    add rcx, byte [data_buffer + rbx] ; Add the new digit

    inc rbx                ; Move to the next byte
    jmp parse_csv          ; Continue parsing

next_integer:
    ; Store the current integer and reset
    mov [parsed_data + (rdx * 4)], ecx  ; Store parsed integer
    inc rdx                              ; Increment parsed data index
    xor rcx, rcx                         ; Reset temporary storage
    inc rbx                               ; Continue to the next byte
    jmp parse_csv                        ; Continue parsing

end_of_line:
    ; Store the last integer after newline
    mov [parsed_data + (rdx * 4)], ecx  ; Store the last parsed integer
    inc rdx                              ; Increment parsed data index
    ret                                  ; Return with the count in rax

; Function: normalize_data
; Normalizes the data array based on the given min and max values.
; Arguments:
;   rdi - Pointer to the data array
;   rsi - Number of elements in the array
;   rdx - Minimum value
;   rcx - Maximum value

normalize_data:
    xor r8, r8               ; Loop counter

normalize_loop:
    cmp r8, rsi              ; Check if we've reached the end
    jge normalize_end        ; If yes, end the loop

    mov eax, dword [rdi + r8 * 4] ; Get the current element
    sub eax, rdx              ; Subtract minimum value
    imul eax, 100             ; Multiply for scaling
    cdq                       ; Prepare for division
    idiv ecx                  ; Divide by (max - min)
    mov dword [rdi + r8 * 4], eax ; Store normalized value

    inc r8                     ; Move to the next element
    jmp normalize_loop        ; Continue the loop

normalize_end:
    ret                       ; Return from the function

; Function: shuffle_data
; Shuffles a data array using Fisher-Yates algorithm.
; Arguments:
;   rdi - Pointer to the data array
;   rsi - Number of elements in the array

shuffle_data:
    xor r8, r8               ; Loop counter
    ; Fisher-Yates shuffle logic
    shuffle_loop:
        cmp r8, rsi          ; If counter >= number of elements, stop
        jge shuffle_end       ; Exit when shuffle is complete
        
        ; Generate a random index between r8 and rsi-1
        call random_index     ; Generate a random index in rax
        
        ; Swap elements at r8 and rax
        mov eax, [rdi + r8 * 4] ; Get current element
        mov ebx, [rdi + rax * 4] ; Get element at random index
        mov [rdi + rax * 4], eax ; Swap them
        mov [rdi + r8 * 4], ebx
        
        inc r8               ; Move to the next element
        jmp shuffle_loop     ; Continue shuffling
        
    shuffle_end:
        ret                  ; Return from the function

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
; Splits a data array into training and testing sets based on test_size.
; Arguments:
;   rdi - Pointer to the data array
;   rsi - Number of elements in the array
;   rdx - Pointer to the training set
;   rcx - Pointer to the testing set
;   rbx - Test size as a float multiplied by 100 (e.g., 20 for 20%)

split_data:
    xor r8, r8               ; Loop counter

    ; Calculate the index to split based on test size
    mov eax, rsi            ; Total number of elements
    imul eax, rbx           ; Multiply by test size
    cdq                      ; Convert to double word
    idiv 100                 ; Get the index
    sub rsi, eax            ; Get the count of training elements
    
    split_loop:
        cmp r8, rsi          ; If loop counter >= number of training elements
        jge split_testing    ; Go to testing set split
        
        ; Copy to training set
        mov edx, [rdi + r8 * 4] ; Get data element
        mov [rdx + r8 * 4], edx ; Store in training set
        
        inc r8              ; Move to the next element
        jmp split_loop      ; Continue
        
    split_testing:
        ; Now copying to testing set
        sub r8, rsi          ; Adjust index to start from 0 in testing set
        
        cmp r8, eax           ; If loop counter >= test size
        jge split_end         ; End
        
        mov edx, [rdi + (rsi + r8) * 4] ; Get data element
        mov [rcx + r8 * 4], edx         ; Store in testing set
        
        inc r8               ; Move to the next element
        jmp split_testing   ; Continue splitting into testing
        
    split_end:
        ret                  ; Return from the function

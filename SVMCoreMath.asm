section .text
    global dot_product
    global vector_addition
    global scalar_multiplication
    global euclidean_norm

; Function: dot_product
; Calculates the dot product of two vectors.
; Arguments:
;   rdi - Pointer to the first vector
;   rsi - Pointer to the second vector
;   rdx - Number of elements in each vector
; Returns:
;   rax - The computed dot product

dot_product:
    xor rax, rax            ; Initialize result to zero
    xor rcx, rcx            ; Loop counter

dot_product_loop:
    cmp rcx, rdx            ; Check if we've reached the end of the loop
    jge dot_product_end     ; If yes, jump to the end

    movzx rbx, byte [rdi + rcx] ; Get element from first vector
    imul rbx, dword [rsi + rcx * 4] ; Multiply by corresponding element in second vector
    add rax, rbx            ; Add to the result

    inc rcx                 ; Move to the next element
    jmp dot_product_loop    ; Repeat the loop

dot_product_end:
    ret                     ; Return the result in rax


; Function: vector_addition
; Adds two vectors together and stores the result in a destination vector.
; Arguments:
;   rdi - Pointer to the first vector
;   rsi - Pointer to the second vector
;   rdx - Pointer to the destination vector
;   rcx - Number of elements in each vector

vector_addition:
    xor r8, r8              ; Loop counter

vector_addition_loop:
    cmp r8, rcx             ; Check if we've reached the end of the loop
    jge vector_addition_end ; If yes, jump to the end

    movzx rax, byte [rdi + r8 * 4] ; Get element from the first vector
    add eax, dword [rsi + r8 * 4]  ; Add the corresponding element from the second vector
    mov dword [rdx + r8 * 4], eax  ; Store in the destination vector

    inc r8                  ; Move to the next element
    jmp vector_addition_loop; Repeat the loop

vector_addition_end:
    ret                     ; Return from the function


; Function: scalar_multiplication
; Multiplies a vector by a scalar.
; Arguments:
;   rdi - Pointer to the vector
;   rsi - Scalar value
;   rdx - Pointer to the destination vector
;   rcx - Number of elements in the vector

scalar_multiplication:
    xor r8, r8              ; Loop counter

scalar_multiplication_loop:
    cmp r8, rcx             ; Check if we've reached the end of the loop
    jge scalar_multiplication_end ; If yes, jump to the end

    movzx rax, byte [rdi + r8 * 4] ; Get element from the vector
    imul eax, rsi           ; Multiply by the scalar
    mov dword [rdx + r8 * 4], eax  ; Store in the destination vector

    inc r8                  ; Move to the next element
    jmp scalar_multiplication_loop ; Repeat the loop

scalar_multiplication_end:
    ret                     ; Return from the function


; Function: euclidean_norm
; Calculates the Euclidean norm (length) of a vector.
; Arguments:
;   rdi - Pointer to the vector
;   rcx - Number of elements in the vector
; Returns:
;   rax - The computed Euclidean norm (approximation using integers)

euclidean_norm:
    xor rax, rax            ; Initialize result to zero
    xor r8, r8              ; Loop counter

euclidean_norm_loop:
    cmp r8, rcx             ; Check if we've reached the end of the loop
    jge euclidean_norm_end  ; If yes, jump to the end

    movzx rbx, byte [rdi + r8 * 4] ; Get element from the vector
    imul rbx, rbx           ; Square the element
    add rax, rbx            ; Add to the result (sum of squares)

    inc r8                  ; Move to the next element
    jmp euclidean_norm_loop ; Repeat the loop

euclidean_norm_end:
    call sqrt_approx        ; Call sqrt approximation (not included here)
    ret                     ; Return from the function

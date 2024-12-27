section .data
    learning_rate dq 0.01   ; Default learning rate
    max_iterations dd 1000  ; Maximum training iterations
    convergence_threshold dq 0.0001 ; Convergence threshold
    initial_bias dd 1       ; Moved from .bss

section .bss
    weights resd 1024       ; Weight vector (supports up to 1024 features)
    bias resd 1             ; Changed to resd
    gradient resd 1024      ; Gradient vector for updates

section .text
    global initialize_model
    global train_svm
    global predict
    global compute_gradient
    global weights         ; Export weights symbol
    global bias           ; Export bias symbol
    extern dot_product    ; Declare external function

; Function: initialize_model
; Initializes the SVM model parameters
; Arguments:
;   rdi - Number of features
initialize_model:
    xor rcx, rcx           ; Counter
init_loop:
    cmp rcx, rdi
    jge init_done
    mov dword [weights + rcx * 4], 0  ; Initialize weights to 0
    inc rcx
    jmp init_loop
init_done:
    mov dword [bias], 0    ; Initialize bias to 0
    ret

; Function: train_svm
; Trains the SVM model using gradient descent
; Arguments:
;   rdi - Pointer to training data
;   rsi - Pointer to labels
;   rdx - Number of samples
;   rcx - Number of features
train_svm:
    push rbp
    mov rbp, rsp
    push rbx                    ; Preserve rbx
    push r12                    ; Preserve r12 for iteration count
    push r13                    ; Preserve r13 for sample index
    
    xor r12, r12               ; Initialize iteration counter
training_loop:
    cmp r12d, [max_iterations] ; Check if max iterations reached
    jge training_done
    
    xor r13, r13               ; Initialize sample index
sample_loop:
    cmp r13, rdx               ; Compare with number of samples
    jge iteration_done
    
    ; Calculate prediction for current sample
    mov rax, r13          ; Get sample index
    mul rcx               ; Multiply by number of features
    lea rdi, [rdi + rax * 4] ; Calculate address correctly
    push rcx
    call predict
    pop rcx
    
    ; Compare with actual label
    mov ebx, [rsi + r13 * 4]   ; Get actual label
    cmp rax, rbx               ; Compare prediction with actual
    je next_sample             ; If correct, skip update
    
    ; Update weights and bias if prediction was wrong
    push rdi
    push rsi
    push rdx
    push rcx
    call compute_gradient      ; Compute gradient for update
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    
    ; Apply gradient update
    call apply_updates
    
next_sample:
    inc r13
    jmp sample_loop
    
iteration_done:
    inc r12
    jmp training_loop
    
training_done:
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Function: predict
; Makes predictions using the trained model
; Arguments:
;   rdi - Pointer to input features
;   rsi - Number of features
; Returns:
;   rax - Predicted class (-1 or 1)
predict:
    push rbp
    mov rbp, rsp
    ; Calculate decision boundary: w·x + b
    call dot_product       ; Call dot product from CoreMath
    add rax, [bias]       ; Add bias term
    
    ; Return sign of result
    cmp rax, 0
    jge predict_positive
    mov rax, -1
    jmp predict_end
predict_positive:
    mov rax, 1
predict_end:
    pop rbp
    ret

; New function: compute_gradient
; Computes the gradient for weight updates
; Arguments same as train_svm
compute_gradient:
    push rbp
    mov rbp, rsp
    
    ; Clear gradient buffer
    xor rcx, rcx
clear_gradient:
    cmp rcx, rsi              ; Compare with number of features
    jge compute_grad_start
    mov dword [gradient + rcx * 4], 0
    inc rcx
    jmp clear_gradient
    
compute_grad_start:
    ; Compute gradient components
    ; gradient = -y_i * x_i if y_i * (w·x_i + b) < 1
    ; Using dot_product from CoreMath
    
    movsd xmm0, [learning_rate] ; Load learning rate
    ; ... compute actual gradient values ...
    
    pop rbp
    ret

; New function: apply_updates
; Applies the computed gradients to weights and bias
apply_updates:
    push rbp
    mov rbp, rsp
    
    xor rcx, rcx
update_loop:
    cmp rcx, rsi              ; Compare with number of features
    jge update_done
    
    ; Update weights: w = w - learning_rate * gradient
    mov eax, [gradient + rcx * 4]
    imul eax, [learning_rate]
    sub [weights + rcx * 4], eax
    
    inc rcx
    jmp update_loop
    
update_done:
    ; Update bias similarly
    mov eax, [gradient]       ; Use first gradient component for bias
    imul eax, [learning_rate]
    sub [bias], eax
    
    pop rbp
    ret

.data
    # Menu
    str_header:     .asciiz "\n=== Space Shuttle Ticket Kiosk ===\n"
    str_luna:      .asciiz "1) Luna City ......... 75\n"
    str_mars:      .asciiz "2) Mars Dunes ........ 120\n"
    str_europa:      .asciiz "3) Europa Geysers .... 90\n"
    str_titan:      .asciiz "4) Titan Lakes ....... 55\n"
    str_entr_dest:.asciiz "Enter destination number:\n"
    # Error
    str_invalid_c:.asciiz "Invalid choice. Please try again:\n"
    str_invalid_bill:.asciiz "Invalid bill. Attempts left: "
    str_newline:    .asciiz "\n"
    str_cancel:     .asciiz "Transaction canceled due to repeated invalid input.\n"
    #Payment
    str_insert_bill:.asciiz "Insert bill (1, 5, 10, 20):\n"
    str_total_ins:  .asciiz "Total inserted: "
    str_credits:    .asciiz " credits\n"
    #dispensed
    str_ticket_luna:   .asciiz "Ticket to Luna City dispensed!\n"
    str_ticket_mars:   .asciiz "Ticket to Mars Dunes dispensed!\n"
    str_ticket_europa:   .asciiz "Ticket to Europa Geysers dispensed!\n"
    str_ticket_titan:   .asciiz "Ticket to Titan Lakes dispensed!\n"
    str_change:     .asciiz "Change: "
    # Prices Array (Luna=75, Mars=120, Europa=90, Titan=55)
    prices:         .word 75, 120, 90, 55
.text
.globl main
main:
    jal DisplayMenu #Display the Menu
    
    #(Returns: $v0 = Index (1-4), $v1 = Price)
    jal HandleSelection
    
    move $s0, $v0       # $s0 = Destination Index
    move $s1, $v1       # $s1 = Price Needed
    
    #Insert_Credits (save price in $a0)
    move $a0, $s1
    jal InsertCredits
    
    #Check_result: if $v0 is -1= failed
    li $t0, -1
    beq $v0, $t0, exit_program
    
    # If success: $v0 = total inserted amount
    move $s2, $v0       # $s2 = Total Inserted
    
    #Calculate Change
    # Arguments: $a0 = Index, $a1 = Price, $a2 = Total Inserted
    move $a0, $s0
    move $a1, $s1
    move $a2, $s2
    jal DispenseTicket
    
exit_program:
    li $v0, 10
    syscall

DisplayMenu:
    addiu $sp, $sp, -4
    sw $ra, 0($sp) #saving the returning addres
    
    li $v0, 4 # Print Header
    la $a0, str_header
    syscall
    
    # Print Items
    la $a0, str_luna
    syscall
    la $a0, str_mars
    syscall
    la $a0, str_europa
    syscall
    la $a0, str_titan
    syscall

    lw $ra, 0($sp) #loas return address
    addiu $sp, $sp, 4 #bring pointer back
    jr $ra


HandleSelection:

    addiu $sp, $sp, -4
    sw $ra, 0($sp)

    li $v0, 4 #print to screen
    la $a0, str_entr_dest
    syscall

loop_select:
    # Read int
    li $v0, 5
    syscall
    move $t0, $v0       # Store input in $t0
    
    #(Must be >= 1 AND <= 4)
    blt $t0, 1, invalid_input
    bgt $t0, 4, invalid_input
    
    # Valid Input found
    # prices + (choice-1)*4
    la $t1, prices      # Base address
    subi $t2, $t0, 1    # Index 0
    mul $t2, $t2, 4     # Offset in bytes
    add $t1, $t1, $t2   # Address of price
    lw $v1, 0($t1)      # Load price into $v1
    
    move $v0, $t0       # Return index in $v0
    j end_select

invalid_input:
    # Print Invalid choice...
    li $v0, 4
    la $a0, str_invalid_c
    syscall
    j loop_select       # Try again

end_select:
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra

InsertCredits:
    addiu $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)      # Target_price
    sw $s1, 8($sp)      # Cur_total
    sw $s2, 12($sp)     # Bad_try_count
    
    move $s0, $a0       # $s0 = Price
    li $s1, 0           # $s1 = Total Inserted = 0
    li $s2, 0           # $s2 = Bad_try_count = 0
    
loop_payment:
    #if Total >= Price
    bge $s1, $s0, payment_success
    
    #if Bad Attempts >= 3
    bge $s2, 3, payment_failed
    
    #"Insert bill..."
    li $v0, 4
    la $a0, str_insert_bill
    syscall
    
    # Read Bill
    li $v0, 5
    syscall
    move $t0, $v0       # $t0 = bill value
    
    # Validate Bill (must be 1, 5, 10, 20)
    beq $t0, 1, valid_bill
    beq $t0, 5, valid_bill
    beq $t0, 10, valid_bill
    beq $t0, 20, valid_bill
    
    #here becuse Invalid Bill
    addi $s2, $s2, 1    # +=1 Bad_try_count
    
    # Calculate attempts left
    li $t1, 3
    sub $t1, $t1, $s2
    
    # Print "Invalid bill..."
    li $v0, 4
    la $a0, str_invalid_bill
    syscall
    
    li $v0, 1
    move $a0, $t1
    syscall
    
    li $v0, 4
    la $a0, str_newline
    syscall
    
    j loop_payment

valid_bill:
    # Update Total
    add $s1, $s1, $t0
    
    # Print "Total inserted: X credits"
    li $v0, 4
    la $a0, str_total_ins
    syscall
    
    li $v0, 1
    move $a0, $s1
    syscall
    
    li $v0, 4
    la $a0, str_credits
    syscall
    
    j loop_payment      #back to check if we have enough

payment_failed:
    # Print Cancel Message
    li $v0, 4
    la $a0, str_cancel
    syscall
    li $v0, -1          #error code
    j end_insert

payment_success:
    move $v0, $s1       # Return total inserted

end_insert:

    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addiu $sp, $sp, 16
    jr $ra

DispenseTicket:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)
    
    #Print Ticket Message based on Index ($a0)
    beq $a0, 1, print_luna
    beq $a0, 2, print_mars
    beq $a0, 3, print_europa
    beq $a0, 4, print_titan

    j calc_change

print_luna:
    la $a0, str_ticket_luna
    j print_msg
print_mars:
    la $a0, str_ticket_mars
    j print_msg
print_europa:
    la $a0, str_ticket_europa
    j print_msg
print_titan:
    la $a0, str_ticket_titan
    j print_msg

print_msg:
    li $v0, 4
    syscall         # Print the ticket msg after loaded in $a0

calc_change:

    sub $t0, $a2, $a1   # Change = Total ($a2) - Price ($a1)
    
    # Print "Change: "
    li $v0, 4
    la $a0, str_change
    syscall
    
    # Print Change Amount
    li $v0, 1
    move $a0, $t0
    syscall
    
    # Newline
    li $v0, 4
    la $a0, str_newline
    syscall

    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra
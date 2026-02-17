.data
    # Menu
    str_header:     .asciiz "\n=== Space Shuttle Ticket Kiosk ===\n"
    str_luna:       .asciiz "1) Luna City ......... 75"
    str_mars:       .asciiz "2) Mars Dunes ........ 120"
    str_europa:     .asciiz "3) Europa Geysers .... 90"
    str_titan:      .asciiz "4) Titan Lakes ....... 55"
    
    # Commander & Exit 
    str_opt_comm:   .asciiz "0) Commander Mode\n"
    str_opt_exit:   .asciiz "9) Exit Kiosk\n"
    str_entr_dest:  .asciiz "Enter choice:\n"

    # Inventory Strings
    str_seats_pre:  .asciiz " (Seats: "
    str_seats_suf:  .asciiz ")\n"
    str_sold_out:   .asciiz " (Sold Out)\n"
    str_msg_soldout:.asciiz "Destination is sold out. Please choose another.\n"
    str_exiting:    .asciiz "Exiting Kiosk. Safe travels!\n"

    # Error
    str_invalid_c:  .asciiz "Invalid choice. Please try again:\n"
    str_invalid_bill:.asciiz "Invalid bill. Attempts left: "
    str_newline:    .asciiz "\n"
    str_cancel:     .asciiz "Transaction canceled due to repeated invalid input.\n"

    # Payment
    str_insert_bill:.asciiz "Insert bill (1, 5, 10, 20):\n"
    str_total_ins:  .asciiz "Total inserted: "
    str_credits:    .asciiz " credits\n"

    # Dispensed
    str_ticket_luna:   .asciiz "Ticket to Luna City dispensed!\n"
    str_ticket_mars:   .asciiz "Ticket to Mars Dunes dispensed!\n"
    str_ticket_europa: .asciiz "Ticket to Europa Geysers dispensed!\n"
    str_ticket_titan:  .asciiz "Ticket to Titan Lakes dispensed!\n"
    str_change:        .asciiz "Change: "

    # Commander Mode Strings
    str_enter_pin:  .asciiz "Enter Commander PIN:\n"
    str_access_den: .asciiz "Access denied.\n"
    str_access_grn: .asciiz "Access granted.\n"
    str_upd_luna:   .asciiz "Set seats for Luna City (current: "
    str_upd_mars:   .asciiz "Set seats for Mars Dunes (current: "
    str_upd_euro:   .asciiz "Set seats for Europa Geysers (current: "
    str_upd_titan:  .asciiz "Set seats for Titan Lakes (current: "
    str_paren_close:.asciiz "): "
    str_updated:    .asciiz "Updated to "
    str_inv_qty:    .asciiz "Invalid quantity. Please enter a non-negative number.\n"
    str_ret_menu:   .asciiz "All updates complete. Returning to main menu...\n"

    # Data Arrays
    prices:         .word 75, 120, 90, 55
    seats:          .word 5, 3, 4, 6 

.text
.globl main

main:
main_loop:
    jal DisplayMenu 
    
    # $v0 = Index (1-4) OR 0 (Commander) OR 9 (Exit)
    # $v1 = Price (only valid if 1-4)
    jal HandleSelection
    
    move $s0, $v0       # $s0 = Destination Index / Command
    move $s1, $v1       # $s1 = Price Needed

    # Check for Special Options
    beq $s0, 9, exit_kiosk       # User chose Exit
    beq $s0, 0, call_commander   # User chose Commander Mode

    # Normal Transaction (1-4)
    # Insert_Credits (save price in $a0)
    move $a0, $s1
    jal InsertCredits
    
    # Check_result: if $v0 is -1 = failed
    li $t0, -1
    beq $v0, $t0, main_loop
    
    # If success: $v0 = total inserted amount
    move $s2, $v0       # $s2 = Total Inserted
    
    # Calculate Change & Dispense & Update Inventory
    # Arguments: $a0 = Index, $a1 = Price, $a2 = Total Inserted
    move $a0, $s0
    move $a1, $s1
    move $a2, $s2
    jal DispenseTicket
    
    j main_loop         # Loop back to start

call_commander:
    jal CommanderMode
    j main_loop

exit_kiosk:
    li $v0, 4
    la $a0, str_exiting
    syscall
    li $v0, 10
    syscall


DisplayMenu:
    addiu $sp, $sp, -4
    sw $ra, 0($sp) 
    
    li $v0, 4 # Print Header
    la $a0, str_header
    syscall
    
    # Print luna + Seats
    la $a0, str_luna
    syscall
    li $a0, 0           # Index for Luna
    jal PrintSeatHelper

    # Print mars + Seats
    li $v0, 4
    la $a0, str_mars
    syscall
    li $a0, 1           # Index for Mars
    jal PrintSeatHelper

    # Print europa + Seats
    li $v0, 4
    la $a0, str_europa
    syscall
    li $a0, 2           # Index for Europa
    jal PrintSeatHelper

    # Print titan + Seats
    li $v0, 4
    la $a0, str_titan
    syscall
    li $a0, 3           # Index for Titan
    jal PrintSeatHelper

    # Print Options 0 and 9
    li $v0, 4
    la $a0, str_opt_comm
    syscall
    la $a0, str_opt_exit
    syscall
    la $a0, str_entr_dest
    syscall

    lw $ra, 0($sp) 
    addiu $sp, $sp, 4 
    jr $ra

# Helper to print seat info
PrintSeatHelper:
    move $t0, $a0       # Get index
    mul $t0, $t0, 4
    la $t1, seats
    add $t1, $t1, $t0
    lw $t2, 0($t1)      # Load seat count
    
    beq $t2, 0, p_soldout
    
    # Print Seats: X
    li $v0, 4
    la $a0, str_seats_pre
    syscall
    li $v0, 1
    move $a0, $t2
    syscall
    li $v0, 4
    la $a0, str_seats_suf
    syscall
    jr $ra

p_soldout:
    li $v0, 4
    la $a0, str_sold_out
    syscall
    jr $ra

HandleSelection:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)

loop_select:
    # Read int
    li $v0, 5
    syscall
    move $t0, $v0       # Store input in $t0
    
    # Check specieal Inputs
    beq $t0, 0, ret_special
    beq $t0, 9, ret_special
    
    # (Must be >= 1 AND <= 4)
    blt $t0, 1, invalid_input
    bgt $t0, 4, invalid_input
    
    # Valid Input 
    subi $t1, $t0, 1    # Index 0-based
    mul $t1, $t1, 4     # Offset
    la $t2, seats
    add $t2, $t2, $t1   # Address of seat count
    lw $t3, 0($t2)      # Load count
    
    blez $t3, sold_out_err # If seats <= 0
    
    # Get Price
    la $t2, prices      
    # $t1 holds offset before
    add $t2, $t2, $t1   
    lw $v1, 0($t2)      # Load price into $v1
    
    move $v0, $t0       # Return index in $v0
    j end_select

sold_out_err:
    li $v0, 4
    la $a0, str_msg_soldout
    syscall
    la $a0, str_entr_dest
    syscall
    j loop_select

invalid_input:
    # Print Invalid choice...
    li $v0, 4
    la $a0, str_invalid_c
    syscall
    j loop_select       # Try again

ret_special:
    move $v0, $t0
    li $v1, 0           # No price needed
    j end_select

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
    
    li $v0, 4           # Insert bill...
    la $a0, str_insert_bill
    syscall

loop_payment:
    # if Total >= Price
    bge $s1, $s0, payment_success
    
    # if Bad Attempts >= 3
    bge $s2, 3, payment_failed
    
    # Read Bill
    li $v0, 5
    syscall
    move $t0, $v0       # $t0 = bill value
    
    # Validate Bill (must be 1, 5, 10, 20)
    beq $t0, 1, valid_bill
    beq $t0, 5, valid_bill
    beq $t0, 10, valid_bill
    beq $t0, 20, valid_bill
    
    # Invalid Bill
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
    
    la $a0, str_insert_bill
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
    
    # If need more money, prompt again
    blt $s1, $s0, prompt_again
    j loop_payment      

prompt_again:
    la $a0, str_insert_bill
    syscall
    j loop_payment

payment_failed:
    # Print Cancel Message
    li $v0, 4
    la $a0, str_cancel
    syscall
    li $v0, -1          # error code
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

    # $a0 has Index (1-4) change to 0-3.
    subi $t0, $a0, 1
    mul $t0, $t0, 4
    la $t1, seats
    add $t1, $t1, $t0
    lw $t2, 0($t1)      # Load curr
    subi $t2, $t2, 1    # change
    sw $t2, 0($t1)      # Save back

    # Print Ticket Message based on Index ($a0)
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

CommanderMode:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Prompt pin
    li $v0, 4
    la $a0, str_enter_pin
    syscall
    
    li $v0, 5
    syscall
    bne $v0, 2025, access_denied #correct pin
    
    # Access ok
    li $v0, 4
    la $a0, str_access_grn
    syscall
    
    # Update Luna (Index 0)
    la $a0, str_upd_luna
    li $a1, 0
    jal UpdateSeatSingle
    
    # Update Mars (Index 1)
    la $a0, str_upd_mars
    li $a1, 1
    jal UpdateSeatSingle
    
    # Update Europa (Index 2)
    la $a0, str_upd_euro
    li $a1, 2
    jal UpdateSeatSingle
    
    # Update Titan (Index 3)
    la $a0, str_upd_titan
    li $a1, 3
    jal UpdateSeatSingle
    
    # Finish
    li $v0, 4
    la $a0, str_ret_menu
    syscall
    j end_commander

access_denied:
    li $v0, 4
    la $a0, str_access_den
    syscall

end_commander:
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra

# Helper for Commander Mode

UpdateSeatSingle:
    addiu $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)      # Save index
    sw $s1, 8($sp)      
    
    move $s0, $a1       
    move $s1, $a0       

retry_update:          #if there is a mistake

    li $v0, 4
    move $a0, $s1      
    syscall
    
    # Print current value
    mul $t0, $s0, 4
    la $t1, seats
    add $t1, $t1, $t0
    lw $a0, 0($t1)
    li $v0, 1
    syscall
    
    li $v0, 4
    la $a0, str_paren_close
    syscall
    

    li $v0, 5
    syscall
    move $t2, $v0
    
    # check >= 0
    bltz $t2, bad_qty
    
    # Update memory
    mul $t0, $s0, 4
    la $t1, seats
    add $t1, $t1, $t0
    sw $t2, 0($t1)
    
    # Print "Updated to X"
    li $v0, 4
    la $a0, str_updated
    syscall
    li $v0, 1
    move $a0, $t2
    syscall
    li $v0, 4
    la $a0, str_newline
    syscall
    
    j end_upd_single

bad_qty:
    li $v0, 4
    la $a0, str_inv_qty
    syscall
    j retry_update #reprint all

end_upd_single:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)      
    addiu $sp, $sp, 16
    jr $ra   
    
read_new_qty:
    li $v0, 5
    syscall
    move $t2, $v0
    
    # check >= 0
    bltz $t2, bad_qty
    
    # Update memory
    mul $t0, $s0, 4
    la $t1, seats
    add $t1, $t1, $t0
    sw $t2, 0($t1)
    
    # Print "Updated to X"
    li $v0, 4
    la $a0, str_updated
    syscall
    li $v0, 1
    move $a0, $t2
    syscall
    li $v0, 4
    la $a0, str_newline
    syscall
    
    j end_upd_single


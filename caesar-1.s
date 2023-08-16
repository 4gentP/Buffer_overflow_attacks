.data
    PromptForPlaintext:
        .asciz  "Please enter the plaintext: "
        lenPromptForPlaintext = .-PromptForPlaintext

    PromptForShiftValue:
        .asciz  "Please enter the shift value: "
        lenPromptForShiftValue = .-PromptForShiftValue

    Newline:
        .asciz  "\n"

    ShiftValue:
        .int    0
.bss
    .comm   buffer, 102     # Buffer to read in plaintext/output ciphertext
    .comm   intBuffer, 4    # Buffer to read in shift value
                            # (assumes value is 3 digits or less)

.text

    .globl _start

    .type PrintFunction, @function
    .type ReadFromStdin, @function
    .type GetStringLength, @function
    .type AtoI, @function
    .type CaesarCipher, @function


    PrintFunction:
        pushl %ebp              # store the current value of EBP on the stack
        movl %esp, %ebp         # Make EBP point to top of stack

        # Write syscall
        movl $4, %eax           # syscall number for write()
        movl $1, %ebx           # file descriptor for stdout
        movl 8(%ebp), %ecx      # Address of string to write
        movl 12(%ebp), %edx     # number of bytes to write
        int $0x80

        movl %ebp, %esp         # Restore the old value of ESP
        popl %ebp               # Restore the old value of EBP
        ret                     # return

    ReadFromStdin:
        pushl %ebp              # store the current value of EBP on the stack
        movl %esp, %ebp         # Make EBP point to top of stack

        # Read syscall
        movl $3, %eax
        movl $0, %ebx
        movl 8(%ebp), %ecx      # address of buffer to write input to
        movl 12(%ebp), %edx     # number of bytes to write
        int  $0x80

        movl %ebp, %esp         # Restore the old value of ESP
        popl %ebp               # Restore the old value of EBP
        ret                     # return


    GetStringLength:

        # Strings which are read through stdin will end with a newline character. (0xa)
        # So look through the string until we find the newline and keep a count
        pushl %ebp              # store the current value of EBP on the stack
        movl %esp, %ebp         # Make EBP point to top of stack

        movl 8(%ebp), %esi      # Store the address of the source string in esi
        xor %edx, %edx          # edx = 0

        Count:
			inc %edx            # increment edx
            lodsb               # load the first character into eax
            cmp $0xa, %eax  	# compare the newline character vs eax
            jnz Count           # If eax != newline, loop back

        dec %edx                # the loop adds an extra one onto edx
        movl %edx, %eax          # return value

        movl %ebp, %esp         # Restore the old value of ESP
        popl %ebp               # Restore the old value of EBP
        ret                     # return


    
    AtoI:
    #
    # Input is always read in as a string. 
    # This function should convert a string to an integer.
    #
        pushl %ebp		# pushing the current value of base pointer ebp into the stack
        movl %esp, %ebp		# copying the value of esp into ebp
        
        xor %eax, %eax          
        xor %ebx, %ebx          # clears register eax and ebx

        leal intBuffer, %esi    # sets esi to point at first byte of intBuffer

        loop:
            xor %eax, %eax      # clears eax
            lodsb               # loads value pointed by esi into eax
            cmp $0x0a, %al      # compares if the loaded value is a new line in ascii 
            jz done             # if the value is a space it exits the loop, ZF is set and the jz is executed
            sub $0x30, %al      # if ZF is not set we reduce the ascii value of ascii 0 to get integer value 
            imul $10, %ebx      # mult the value of ebx by the value 10 and store it in ebx
            addl %eax, %ebx     # insert the next digit into ebx
            jmp loop            # start loop again

        done:
            movl %ebx, ShiftValue   # copy the final result into ShiftValue
            movl %ebp, %esp
            popl %ebp
            ret

    CaesarCipher:
    #
    # Fill in code for CaesarCipher Function here
    #
        pushl %ebp 		# pushing the current value of base pointer ebp into the stack
        movl %esp, %ebp		# copying the value in esp to ebp 

        movl $0, %edx           # clear edx for div
        movl ShiftValue, %eax   # copy ShiftValue to eax
        movl $26, %ebx          # copy 26 into ebx
        idivl %ebx              # divide ShiftValue by 26 to get remainder, essentially ShiftValue mod 26, the quotient is stored in eax and remainder is stored in edx
        
        xor %eax, %eax          # clears register eax

        leal buffer, %esi       # sets esi to point at first byte of buffer
        leal buffer, %edi       # sets esi to point at first byte of buffer
        
        loop2:
            xor %eax, %eax      # clear eax
            lodsb               # load byte pointed by esi into eax
            cmp $0x0a, %eax     # compares to see in eax is a line feed character
            jz done2            # if it is the caesar cipher can exit

            cmp $122, %eax      # check if eax greater than largest ascii value for a alphabet
            jg continue         # if it is continue
            
            cmp $122, %eax      # compares to see if the byte is less than 122 which is lower case 'z',
            jl lower            # which is the highest alphabet in ascii, if it is then we jmp to lower(lower case alphabet)
                  
            lower:
                cmp $97, %eax   # makes sure the byte is a lower case alphabet,
                jl upper        # if its less than 97 it would not be a lower case alphabet, jumps to upper case alphabet
                addl %edx, %eax # adds the ShiftValue to eax
                cmp $122, %eax  # checks to see if the shifted char overflows
                jg over         # if overflow occures jumps to over
                jmp continue    # if all's good, jumps to continue 

            upper:
                cmp $90, %eax   # checks to see if the byte is within the range of upper case alphabet in ascii
                jg continue     # if not jump to continue
                cmp $65, %eax   # checks to see if the byte is within the range of upper case alphabet in ascii
                jl continue     # if not jump to continue
                addl %edx, %eax # adds the ShiftValue to eax
                cmp $90, %eax   # checks to see if the shifted char overflows
                jg over         # if overflow occures jumps to over
                jmp continue    # if all's good, jumps to continue

            over:
                subl $26, %eax  # if char overflows, we can just subtract by 26
                jmp continue    # continue with char within range

            continue:
                stosb           # stores eax to address pointed by edi
                jmp loop2       # loop again

        done2:
            movl %ebp, %esp	# move the value of ebp into esp
            popl %ebp		# remove the value from top of the stack and put in ebp
            ret			# return 

    _start:

        # Print prompt for plaintext
        pushl   $lenPromptForPlaintext
        pushl   $PromptForPlaintext
        call    PrintFunction
        addl    $8, %esp

        # Read the plaintext from stdin
        pushl   $102
        pushl   $buffer
        call    ReadFromStdin
        addl    $8, %esp

        # Print newline
        pushl   $1
        pushl   $Newline
        call    PrintFunction
        addl    $8, %esp

        # Get input string and adjust the stack pointer back after
        pushl   $lenPromptForShiftValue
        pushl   $PromptForShiftValue
        call    PrintFunction
        addl    $8, %esp

        # Read the shift value from stdin
        pushl   $4
        pushl   $intBuffer
        call    ReadFromStdin
        addl    $8, %esp

        # Print newline
        pushl   $1
        pushl   $Newline
        call    PrintFunction
        addl    $8, %esp

        # Convert the shift value from a string to an integer.
        pushl   $intBuffer	# pushing the address of memory location intBuffer into the stack
        call    AtoI		# calling the AtoI fucntion
        add     $8, %esp

        # Perform the caesar cipheR
        # FILL IN HERE
        pushl   $buffer		# pushing the address of memory location buffer into the stack
        call    CaesarCipher	# calling the CaesarCipher function
        add     $8, %esp

        # Get the size of the ciphertext
        # The ciphertext must be referenced by the 'buffer' label
        pushl   $buffer
        call    GetStringLength
        addl    $4, %esp

        # Print the ciphertext
        pushl   %eax
        pushl   $buffer
        call    PrintFunction
        addl    $8, %esp

        # Print newline
        pushl   $1
        pushl   $Newline
        call    PrintFunction
        addl    $8, %esp

        # Exit the program
        Exit:
            movl    $1, %eax
            movl    $0, %ebx
            int     $0x80

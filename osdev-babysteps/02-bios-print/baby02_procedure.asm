; https://wiki.osdev.org/Babystep2
; Writing a string message using the BIOS calls.
; Print is refactored to a procedure with is called with call/ret.

; initialize the address of the message
  mov ax, 0x7C0
  mov ds, ax ; segment of the string
  mov si, msg ; offset of the string

  call bios_print ; call the procedure
  ; after call the execution continues below to hang label

hang:
  jmp hang ; infinite loop

bios_print:
  ; https://en.wikipedia.org/wiki/INT_10H
  ; http://vitaly_filatov.tripod.com/ng/asm/asm_023.15.html
  ; BIOS interrupt 0x10 with method 0x0E - teletype output:
  ; print character of a string while interpreting some characters

  lodsb ; load a byte of string from DS:SI address to AL
  cmp al, 0 ; set zero flag when AL = 0 (end of string)
  je done ; jump to label "done" when zero flag is set

  mov ah, 0x0E ; teletype output
  mov bh, 0 ; display page number (active page, there might be other pages...)
  int 0x10 ; call the BIOS interrupt
  jmp bios_print
done:
  ret ; return from the procedure

; data: message + \r\n\0 - zero-terminated string
msg:
  db 'baby 02 - procedure', 13, 10, 'Hello, world!', 13, 10, 0
  ; padding with boot signature
  times 512 - 2 - ($-$$) db 0
  db 0x55
  db 0xAA

; https://wiki.osdev.org/Babystep2
; Writing a string message using the BIOS calls
;
; Quick review:
;
; - Boot sector loaded by BIOS is 512 bytes
; - The code in the boot sector of the disk is loaded by the BIOS at 0000:7c00
; - Machine starts in Real Mode
; - Be aware that the CPU is being interrupted unless you issue the CLI assembly
;   command
; - Many (but not all) BIOS interrupts expect DS to be filled with a Real Mode
;   segment value. This is why many BIOS interrupts won't work in protected
;   mode. So if you want to use int 10h/ah=0eh to print to the screen, then you
; need to make sure that your seg:offset for the characters to print is correct.
;
; In real mode, addresses are calculated as segment * 16 + offset. Since offset
; can be much larger than 16, there are many pairs of segment and offset that
; point to the same address. For instance, some say that the bootloader is is
; loaded at 0000:7C00, while others say 07C0:0000. This is in fact the same
; address: 16 * 0x0000 + 0x7C00 = 16 * 0x07C0 + 0x0000 = 0x7C00.
;
; It doesn't matter if you use 0000:7c00 or 07c0:0000, but if you use ORG you
; need to be aware of what's happening. By default, the start of a raw binary is
; at offset 0, but if you need it you can change the offset to something
; different and make it work. For instance the following snippet accesses the
; variable msg with segment 0x7C0.

; initialize the address of the message
  mov ax, 0x7C0
  mov ds, ax ; segment of the string
  mov si, msg ; offset of the string

char_loop:
  ; https://en.wikipedia.org/wiki/INT_10H
  ; http://vitaly_filatov.tripod.com/ng/asm/asm_023.15.html
  ; BIOS interrupt 0x10 with method 0x0E - teletype output:
  ; print character of a string while interpreting some characters

  lodsb ; load a byte of string from DS:SI address to AL
  or al, al ; set zero flag when AL = 0 (end of string), keeps AL untouched
  jz hang ; exit and go into infinite loop

  ; Also possible:
  ; cmp al, 0
  ; je hang

  mov ah, 0x0E ; teletype output
  mov bh, 0 ; display page number (active page, there might be other pages...)
  int 0x10 ; call the BIOS interrupt
  jmp char_loop

hang:
  jmp hang ; infinite loop

; data: message + \r\n\0 - zero-terminated string
msg:
  db 'Hello, world!', 13, 10, 0
  ; padding with boot signature
  times 512 - 2 - ($-$$) db 0
  db 0x55
  db 0xAA

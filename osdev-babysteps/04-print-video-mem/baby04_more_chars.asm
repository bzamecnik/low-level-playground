; https://wiki.osdev.org/Babystep4
; Printing to the screen without the BIOS
;
; This example prints a string and the contents of a memory location (which is
; the first letter of the string in video memory). It is meant to demonstrate
; printing to screen in text mode without using BIOS, as well as converting hex
; so it can be displayed -- so we can check register and memory values.
; A stack is included, but only used by call and ret.

; There are two functions: "print_string" to print a string to video memory and
; "printreg16" to format and two bytes from the video memory in hexadecimal.

; The cursor is represented by two variables: xpos, ypos.

; --- main ---

[org 0x7c00] ; origin address
  xor ax, ax ; maybe just "mov ax 0"? https://stackoverflow.com/questions/1135679/does-using-xor-reg-reg-give-advantage-over-mov-reg-0
  mov ds, ax ; data segment = 0 (for input string)
  mov ss, ax ; stack segment = 0
  mov sp, stack; stack pointer

  cld ; clear direction flag (-> string goes up for lodsb)

  mov ax, video_mem ; text video memory address -> extra segment E
  mov es, ax ; (can't set it directly)

  mov si, msg ; argument to print_string - string pointer in index register SI
  call print_string

  ; examine content of video memory (each char+attr of the string)

  mov ax, video_mem ; text video memory address -> extra segment G
  mov gs, ax
  mov cx, msg_len ; loop: for (cx = msg_len; cx > 0; cx--)
print_video_mem_word:
  ; bx - offset in video memory: offset = 2 * (msg_len - counter)
  mov bx, msg_len
  sub bx, cx
  shl bx, 1 ; bx *= 2
  mov ax, [gs:bx] ; load a word from video memory at given offset
  mov word [reg16], ax ; store argument for printreg16
  push cx ; keep the counter on stack
  call printreg16
  pop cx
  dec cx
  jnz print_video_mem_word

hang:
  jmp hang ; end

; --- string printing ---

print_string: ; print string
  lodsb ; load a byte from address ds:si to al
  cmp al, 0
  je print_crlf ; loop until we find a zero byte in the string
  call print_char ; print one character and then continue to the rest of the string
  jmp print_string
print_crlf:
  ; finish with CR LF:
  add byte [ypos], 1 ; line feed - one row down
  mov byte [xpos], 0 ; carriage return - back to the first column
  ret

print_char:
  ; al is set to the character byte

  ; https://wiki.osdev.org/Printing_To_Screen
  mov ah, 0x0F; text color attribute: white on black
  mov cx, ax ; keep character + attribute in cx

  movzx ax, byte [ypos] ; load 8-bit cursor row position to 16-bit ax
                        ; (pad upper byte with 0)
  mov dx, row_offset ; 2*80 (2 bytes per 80 columns)
  mul dx ; ax = ax * dx (offset = ypos * 2 * width)

  movzx bx, byte [xpos] ; cursor column position
  shl bx, 1 ; bx = 2 * xpos (2 bytes / char)

  mov di, 0 ; video memory offset = y offset + x offset
  add di, ax ; y offset
  add di, bx ; x offset

  mov ax, cx ; restore character + attribute to ax

  ; write the character to video memory
  stosw ; store AX at address ES:DI, ES is still

  add byte [xpos], 1 ; move one column right

  ret

; --- print value in a register ---

; It will print in little endian. For video memory word it prints:
; text attribute, then character.

printreg16:
  ; format a 16-bit value from reg16 into outstr16
  mov di, outstr16 ; DI points to currently written char in the output string
  mov ax, [reg16] ; input value - will get modified in AX
  mov si, hexstr ; character map
  mov cx, 4 ; loop with 4 iterations (each 4-bits formatted to one hex char)
hexloop:
  ; format one half-byte (nibble)
  rol ax, 4 ; rotate to left by 4 bits
  mov bx, ax ; keep AX when we apply a mask
  and bx, 0x0F ; mask out one nibble, bx is now in range [0; 16)
  mov bl, [si + bx] ; get hex char corresponding to the current nibble
  mov [di], bl ; write the char to the output string
  inc di ; move by one char in the output string
  dec cx ; decrement loop counter
  jnz hexloop ; continue if cx > 0

  ; print the formatted string
  mov si, outstr16 ; argument to print_string
  call print_string

  ret

; --- data ---

video_mem equ 0xb800
stack equ 0x9c00 ; stack pointer: 0x7c00 + 0x2000
screen_width equ 80
row_offset equ 2 * screen_width
msg_len equ 20

xpos db 0
ypos db 0
hexstr db '0123456789ABCDEF'
outstr16 db '0000', 0 ; register value in hex as a string
reg16 dw 0 ; input argument to printreg16, a word from a register
msg db 'Hello, video memory!', 0
; padding + boot sector signature
times 510 - ($-$$) db 0
db 0x55
db 0xaa

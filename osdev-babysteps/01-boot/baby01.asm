; https://wiki.osdev.org/Babystep1
;
; It just boots and shows a blinking cursor.
;
; nasm baby01.asm -f bin -o baby01.bin
; qemu-system-i386 -fda baby01.bin
;
; or just `make baby01`
;
; We have to compile to flat binary (ELF doesn't work). We provide the image to
; QEMU as floppy disk image or hard-disk image (`-hda`). `-kernel` doesn't work
; since it needs multiboot header.
;
hang:
  ; infinite loop
  jmp hang

  ; zero padding up to 1 block of 512 minut two bytes for the boot signature
  ; this is a repeated zero byte
  ; $ = address of this line (https://www.nasm.us/doc/nasmdoc3.html#section-3.5)
  ; $$ = address of this section
  times 510-($-$$) db 0
  ; boot signature
  db 0x55
  db 0xAA

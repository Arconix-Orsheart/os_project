CC = i686-elf-gcc
AS = i686-elf-as

# Default CFLAGS:
CFLAGS?=-O2 -g

# Add mandatory options to CFLAGS:
CFLAGS:=$(CFLAGS) -Wall -Wextra

QEMU = qemu-system-i386

all: myos

prepare:
	@export PATH="$HOME/opt/cross/bin:$PATH"

boot: boot.s
	$(AS) boot.s -o boot.o

kernel: kernel.c
	$(CC) $(CFLAGS) -c kernel.c -o kernel.o

myos: boot.o kernel.o
	$(CC) -T linker.ld -o myos -ffreestanding -O2 -nostdlib boot.o kernel.o -lgcc

verify: myos
	@if grub2-file --is-x86-multiboot myos; then\
		echo "multiboot confirmed";\
	else\
		echo "the file is not multiboot";\
	fi

iso: myos
	mkdir -p isodir/boot/grub
	cp myos isodir/boot/myos
	cp grub.cfg isodir/boot/grub/grub.cfg
	grub2-mkrescue -o myos.iso isodir

qemu: myos.iso
	$(QEMU) -cdrom myos.iso

clean:
	rm -f *.o myos*
	rm -r isodir
TARGET=x86_64-elf
SHELL=bash
BUILDS=$$HOME/src
OPT=$$HOME/opt
BUILD_BINUTILS=$(BUILDS)/build-binutils
BUILD_GCC=$(BUILDS)/build-gcc
BUILD_LIBICONV=$(BUILDS)/build-libiconv
PREFIX=$(OPT)/cross

# BINARIES
BIN=$(PREFIX)/bin
GCC=$(BIN)/x86_64-elf-gcc
LD=$(BIN)/x86_64-elf-ld


###############################################################################
#	BINUTILS
###############################################################################

.PHONY: directories libiconv binutils cross_compiler

directories:
	@#make PREFIX directory where cross-compiler binary will be stored
	@if ! [ -d $(OPT) ]; then \
		mkdir $(OPT); \
	fi
	@if ! [ -d $(PREFIX) ]; then \
		mkdir $(PREFIX); \
	fi
	@#make directory where to download tar files
	@if ! [ -d $(BUILDS) ]; then \
		mkdir $(BUILDS); \
	fi
	@if ! [ -d $(BUILD_BINUTILS) ]; then \
		mkdir $(BUILD_BINUTILS); \
	fi
	@if ! [ -d $(BUILD_GCC) ]; then \
		mkdir $(BUILD_GCC); \
	fi
	@if ! [ -d $(BUILD_LIBICONV) ]; then \
		mkdir $(BUILD_LIBICONV); \
	fi
	

libiconv: directories
	@# download libiconv file at BUILD_LIBICONV and build at /usr/local
	@cd $(BUILDS) && \
	if ! [ -f libiconv-1.16.tar.gz ]; then \
		echo Downloading libiconv-1.16.tar.gz && \
		wget https://ftp.gnu.org/gnu/libiconv/libiconv-1.16.tar.gz; \
	fi && \
	echo libiconv-1.16.tar.gz downloaded at $(BUILDS) && \
	if ! [ -d libiconv-1.16 ]; then \
		echo extracting libiconv-1.16.tar.gz && \
		tar -xf libiconv-1.16.tar.gz; \
	fi && \
	echo libiconv-1.16 extracted at $(BUILDS) && \
	if ! [ -d /usr/local/Cellar/libiconv ]; then \
		echo building libiconv at /usr/local/Cellar && \
		cd $(BUILD_LIBICONV) && \
		../libiconv-1.16/configure --prefix=/usr/local/Cellar/libiconv/1.16 && \
		make && \
		make install; \
	fi && \
	if [ -d /usr/local/Cellar/libiconv ]; then \
		echo libiconv built at /usr/local/Cellar; \
	fi


binutils: libiconv
	@# download binutils file at BUILD_BINUTILS and build at PREFIX
	@cd $(BUILDS) && \
	if ! [ -f binutils-2.35.tar.xz ]; then \
		echo Downloading binutils-2.35.tar.xz && \
		wget https://ftp.gnu.org/gnu/binutils/binutils-2.35.tar.xz; \
	fi && \
	echo binutils-2.35.tar.xz downloaded at $(BUILDS) && \
	if ! [ -d "binutils-2.35" ]; then \
		echo Extracting binutils-2.35.tar.xz && \
		tar -xf binutils-2.35.tar.xz; \
	fi && \
	echo binutils-2.35 extracted at $(BUILDS) && \
	if ! [ -d $(PREFIX)/bin ] || ! [ -d $(PREFIX)/$(TARGET) ] || ! [ -d $(PREFIX)/share ]; then \
		echo building binutils-2.35 at $(PREFIX) && \
		cd $(BUILD_BINUTILS) && \
		../binutils-2.35/configure \
			--target=$(TARGET) --prefix=$(PREFIX) \
			--with-sysroot --disable-nls --disable-werror && \
		make && make install; \
	fi
	@if [ -d $(PREFIX)/$(TARGET) ] && [ -d $(PREFIX)/$(TARGET) ] && [ -d $(PREFIX)/share ]; then \
		echo Binutils built at $(PREFIX); \
	fi

cross_compiler_download: binutils
	@cd $(BUILDS) && \
	if ! [ -f "gcc-10.2.0.tar.xz" ]; then \
		echo Downloading gcc-10.2.tar.xz && \
		wget https://ftp.gnu.org/gnu/gcc/gcc-10.2.0/gcc-10.2.0.tar.xz; \
	fi && \
	echo gcc-10.2.tar.xz downloaded at $(BUILDS) && \
	if ! [ -d gcc-10.2.0 ]; then \
		echo Extracting gcc-10.2.0.tar.xz && \
		tar -xf gcc-10.2.0.tar.xz; \
	fi 
	@echo gcc-10.2.0 extracted at $(BUILDS)

cross_compiler:
	cd $(BUILD_GCC) && \
	echo Building gcc-10.2.0 at $(PREFIX) && \
	export PATH=$(PREFIX)/bin:$$PATH && \
	../gcc-10.2.0/configure \
		--target=$(TARGET) --prefix=$(PREFIX) \
		--disable-nls --enable-languages=c,c++ \
		--without-headers \
		--with-libiconv-prefix=/usr/local/Cellar  && \
	make all-gcc && \
	make all-target-libgcc && \
	make install-gcc && \
	make install-target-libgcc;

###############################################################################
# RUN KERNEL
###############################################################################

C_SOURCES = $(wildcard kernel/*.c drivers/*.c)
HEADERS = $(wildcard kernel/*.h drivers/*.h)
OBJ = ${C_SOURCES:.c=.o}

.PHONY: os-image clean run-qemu run
all: os-image run-qemu

kernel/kernel_prefix.o: kernel/kernel_prefix.asm
	nasm -f elf64 $< -o $@

%.o: %.c
	$(GCC) -ffreestanding -c $< -o $@

kernel/kernel.bin: kernel/kernel_prefix.o ${OBJ} 
	$(LD) -o $@ -Ttext 0x1000 $^ --oformat binary

boot/boot_loader.bin: boot/boot_loader.asm
	nasm -f bin $^ -o $@

os-image: boot/boot_loader.bin kernel/kernel.bin
	cat $^ > $@

clean: ${wildcard *.o *.bin}
	rm kernel/*.o drivers/*.o kernel/*.bin drivers/*.bin boot/*.bin os-image

run-qemu: os-image
	qemu-system-x86_64 -machine pc os-image

.PHONY: 
run: boot/boot_loader.bin 
	qemu-system-x86_64 boot/boot_loader.bin
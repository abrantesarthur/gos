TARGET=x86_64-elf
SHELL=bash

GCC_VERSION=14.2.0
LIBICONV_VERSION=1.17
BINUTILS_VERSION=2.43

BUILDS=$$HOME/src
BUILD_BINUTILS=$(BUILDS)/build-binutils
GCC_SOURCE=$(BUILDS)/gcc-$(GCC_VERSION)
BUILD_GCC=$(BUILDS)/build-gcc
BUILD_LIBICONV=$(BUILDS)/build-libiconv

LIBICONV_PREFIX=/usr/local/Cellar/libiconv/$(LIBICONV_VERSION)


OPT=$$HOME/opt
PREFIX=$(OPT)/cross

# BINARIES
BIN=$(PREFIX)/bin
GCC=$(BIN)/x86_64-elf-gcc-$(GCC_VERSION)
LD=$(BIN)/x86_64-elf-ld


###############################################################################
# CROSS COMPILER DEPENDENCIES
###############################################################################

.PHONY: directories utils libiconv binutils cross_compiler brew install_wget install_gmp install_mpfr install_mpc install_mac_ports disable_pch

install_brew:
	@if ! [ -e /opt/homebrew/bin/brew ]; then \
		echo Installing homebrew at /opt/Homebrew... && \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
		echo adding homebrew to the PATH && \
		echo; echo 'eval "$$(/opt/homebrew/bin/brew shellenv)"' >> $$HOME/.zprofile && \
		eval "$$(/opt/homebrew/bin/brew shellenv)"; \
	fi

install_wget: install_brew
	@if ! [ -e /opt/homebrew/bin/wget ]; then \
		echo "Installing wget at /opt/homebrew/bin" && \
		brew install wget; \
	fi

install_texinfo: install_brew
	@brew install texinfo

install_gnu_sed: install_brew
	@if ! [ -d /opt/homebrew/Cellar/gnu-sed ]; then \
		echo "Installing gnu-sed at /opt/homebrew/bin" && \
		brew install gnu-sed; \
	fi

directories:
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

install_libiconv: install_wget directories
	@# download libiconv file at BUILD_LIBICONV and build at /usr/local
	@cd $(BUILDS) && \
	if ! [ -f libiconv-$(LIBICONV_VERSION).tar.gz ]; then \
		wget -q --show-progress https://ftp.gnu.org/gnu/libiconv/libiconv-$(LIBICONV_VERSION).tar.gz; \
	fi && \
	echo libiconv-$(LIBICONV_VERSION).tar.gz downloaded at $(BUILDS) && \
	if ! [ -d libiconv-$(LIBICONV_VERSION) ]; then \
		echo extracting libiconv-$(LIBICONV_VERSION).tar.gz && \
		tar -xf libiconv-$(LIBICONV_VERSION).tar.gz; \
	fi && \
	echo libiconv-$(LIBICONV_VERSION) extracted at $(BUILDS) && \
	if ! [ -d /usr/local/Cellar/libiconv/$(LIBICONV_VERSION) ]; then \
		echo building libiconv at /usr/local/Cellar && \
		cd $(BUILD_LIBICONV) && \
		sudo ../libiconv-$(LIBICONV_VERSION)/configure --prefix=$(LIBICONV_PREFIX) && \
		sudo make && \
		sudo make install; \
	fi && \
	if [ -d /usr/local/Cellar/libiconv/$(LIBICONV_VERSION) ]; then \
		echo libiconv-$(LIBICONV_VERSION) built at $(LIBICONV_PREFIX); \
	fi


install_binutils: install_libiconv install_texinfo
	@# download binutils file at $(BUILD_BINUTILS) and build at $(PREFIX)
	@cd $(BUILDS) && \
	if ! [ -f binutils-$(BINUTILS_VERSION).tar.xz ]; then \
		wget -q --show-progress https://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VERSION).tar.xz; \
	fi && \
	echo binutils-$(BINUTILS_VERSION).tar.xz downloaded at $(BUILDS) && \
	if ! [ -d "binutils-$(BINUTILS_VERSION)" ]; then \
		echo Extracting binutils-$(BINUTILS_VERSION).tar.xz && \
		tar -xf binutils-$(BINUTILS_VERSION).tar.xz; \
	fi && \
	echo binutils-$(BINUTILS_VERSION) extracted at $(BUILDS) && \
	if ! [ -d $(PREFIX)/bin ] || ! [ -d $(PREFIX)/$(TARGET) ] || ! [ -d $(PREFIX)/share ]; then \
		echo building binutils-$(BINUTILS_VERSION) at $(PREFIX) && \
		cd $(BUILD_BINUTILS) && \
		sudo ../binutils-$(BINUTILS_VERSION)/configure \
			--target=$(TARGET) --prefix=$(PREFIX) \
			--with-sysroot --disable-nls --disable-werror && \
		sudo make && \
		sudo make install; \
	fi
	@if [ -d $(PREFIX)/$(TARGET) ] && [ -d $(PREFIX)/$(TARGET) ] && [ -d $(PREFIX)/share ]; then \
		echo Binutils built at $(PREFIX); \
	fi

# download the cross-compiler sources.
download_cc_sources: install_binutils
	@cd $(BUILDS) && \
	if ! [ -f "gcc-$(GCC_VERSION).tar.xz" ]; then \
		echo Downloading gcc-$(GCC_VERSION).tar.xz... && \
		wget -q --show-progress https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VERSION)/gcc-$(GCC_VERSION).tar.xz; \
	fi && \
	echo gcc-$(GCC_VERSION).tar.xz downloaded at $(BUILDS) && \
	if ! [ -d gcc-$(GCC_VERSION) ]; then \
		echo Extracting gcc-$(GCC_VERSION).tar.xz && \
		tar -xf gcc-$(GCC_VERSION).tar.xz; \
	fi 
	@echo gcc-$(GCC_VERSION) extracted at $(BUILDS)
	@echo Successfully installed libiconv-$(LIBICONV_VERSION), binutils-$(BINUTILS_VERSION), and downloaded gcc-$(GCC_VERSION)!

# Install MacPorts, an open source system for installing open-source libraries on Mac.
install_mac_ports:
	@cd $(BUILDS) && \
	if ! [ -f "MacPorts-2.10.1.tar.gz" ]; then \
		echo Downloading Macports... && \
		wget -q --show-progress https://github.com/macports/macports-base/releases/download/v2.10.1/MacPorts-2.10.1.tar.gz; \
	fi && \
	echo MacPorts downloaded at $(BUILDS) && \
	if ! [ -d MacPorts-2.10.1 ]; then \
		echo extracting MacPorts... && \
		tar -xf MacPorts-2.10.1.tar.gz; \
	fi && \
	if ! [ -f /opt/local/bin/port ]; then \
		echo installling MacPorts... && \
		cd MacPorts-2.10.1 && \
		./configure && make && sudo make install && \
		cd .. && rm -rf MacPorts-2.10.1; \
	fi

# Use MacPorts to install thegmp, mpfr and libmpc, open-source
# packages that the cross compiler depends on.
install_cc_deps: install_mac_ports
	@if port installed gmp | grep -q "None"; then \
		sudo port -q install gmp; \
	fi && \
	if port installed mpfr | grep -q "None"; then \
		sudo port -q install mpfr; \
	fi && \
	if port installed libmpc | grep -q "None"; then \
		sudo port -q install libmpc; \
	fi

# Build a libgcc multilib variant without red-zone requirement
GCC_CONFIG=$(GCC_SOURCE)/gcc/config.gcc
HOST_CONFIG=$(GCC_SOURCE)/gcc/config.host
T_X86_64_ELF=$(GCC_SOURCE)/gcc/config/i386/t-x86_64-elf
disable_red_zone: install_gnu_sed
	@if ! [ -f $(T_X86_64_ELF) ]; then \
		sudo chown -R $(USER):admin $(BUILDS)/gcc-$(GCC_VERSION) && \
		touch $(T_X86_64_ELF); \
	fi
	truncate -s 0 $(T_X86_64_ELF) && \
	echo MULTILIB_OPTIONS += mno-red-zone >> $(T_X86_64_ELF); \
	echo MULTILIB_DIRNAMES += no-red-zone >> $(T_X86_64_ELF); \
	gsed -i '/x86_64-\*-elf/a\	tmake_file="$${tmake_file} i386/t-x86_64-elf"' $(GCC_CONFIG)

# Disable PCH so the MacBook M architecture can be supported
disable_pch: install_gnu_sed
	gsed -i '/out_host_hook_obj=host-darwin.o/c\		#out_host_hook_obj=host-darwin.o' $(HOST_CONFIG); \
	gsed -i '/host_xmake_file="$${host_xmake_file} x-darwin"/c\		#host_xmake_file="$${host_xmake_file} x-darwin"' $(HOST_CONFIG)
	

###############################################################################
# CROSS COMPILER
###############################################################################

# Build cross-compiler. If it fails, consider running make clean_cc before.
cross_compiler: download_cc_sources install_cc_deps disable_red_zone disable_pch
	cd $(BUILD_GCC) && \
	echo Building gcc-$(GCC_VERSION) at $(PREFIX) && \
	export PATH=$(PREFIX)/bin:$$PATH && \
	sudo ../gcc-$(GCC_VERSION)/configure \
		--target=$(TARGET) --prefix=$(PREFIX) \
		--disable-nls --enable-languages=c,c++ \
		--without-headers \
		--with-gmp=/usr --with-mpc=/opt/local --with-mpfr=/opt/local \
		--with-libiconv-prefix=/usr/local/Cellar  && \
	sudo make -j 8 all-gcc && \
	sudo make all-target-libgcc && \
	sudo make install-gcc && \
	sudo make install-target-libgcc;

###############################################################################
# CLEAN
###############################################################################

clean_cc:
	sudo rm -rf $(BUILDS) && sudo rm -rf $(OPT) && sudo rm -rf $(LIBICONV_PREFIX) 

###############################################################################
# RUN KERNEL
###############################################################################

C_SOURCES = $(wildcard kernel/*.c drivers/*.c)
HEADERS = $(wildcard kernel/*.h drivers/*.h)
OBJ = ${C_SOURCES:.c=.o}

.PHONY: os-image clean run-qemu run run-file install_nasm
all: os-image run-qemu

install_nasm: install_brew
	@if ! [ -e /opt/homebrew/bin/nasm ]; then \
		echo "Installing nasm at /opt/homebrew/bin" && \
		brew install nasm; \
	fi

kernel/kernel_prefix.o: kernel/kernel_prefix.asm install_nasm
	nasm -f elf64 $< -o $@

%.o: %.c
	$(GCC) -ffreestanding -c $< -o $@

kernel/kernel.bin: kernel/kernel_prefix.o ${OBJ} 
	$(LD) -o $@ -Ttext 0x1000 $^ --oformat binary

boot/boot_loader.bin: boot/boot_loader.asm install_nasm
	nasm -f bin $< -o $@

os-image: boot/boot_loader.bin kernel/kernel.bin
	cat $^ > $@

clean: ${wildcard *.o *.bin}
	rm kernel/*.o drivers/*.o kernel/*.bin drivers/*.bin boot/*.bin os-image

run-qemu: os-image
	qemu-system-x86_64 -machine pc os-image

.PHONY: 
run: boot/boot_loader.bin 
	qemu-system-x86_64 boot/boot_loader.bin

.PHONY:
run-file: nasm
	nasm -f bin $(f).asm -o $(f).bin && \
	qemu-system-x86_64 $(f).bin
#!/bin/bash

set -e

TARGET=x86_64-elf
GCC_VERSION=14.2.0
LIBICONV_VERSION=1.17
BINUTILS_VERSION=2.43

BUILDS=$HOME/src
BUILD_BINUTILS=$BUILDS/build-binutils
GCC_SOURCE=$BUILDS/gcc-$GCC_VERSION
BUILD_GCC=$BUILDS/build-gcc
BUILD_LIBICONV=$BUILDS/build-libiconv

LIBICONV_PREFIX=/usr/local/Cellar/libiconv/$LIBICONV_VERSION

OPT=$HOME/opt
PREFIX=$OPT/cross

install_brew() {
    if [ ! -e /opt/homebrew/bin/brew ]; then
        echo "Installing homebrew at /opt/Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo "Adding homebrew to the PATH"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
}

install_wget() {
    if ! brew list | grep -q wget; then
        echo "Installing wget at /opt/homebrew/bin"
        brew install wget
    fi
}

install_texinfo() {
    if ! brew list | grep -q texinfo; then
        echo "Installing texinfo at /opt/homebrew/bin"
        brew install texinfo
    fi
}

install_gnu_sed() {
    if ! brew list | grep -q gnu-sed; then
        echo "Installing gnu-sed at /opt/homebrew/bin"
        brew install gnu-sed
    fi
}

# Function to create necessary directories
create_directories() {
    mkdir -p $OPT $PREFIX $BUILDS $BUILD_BINUTILS $BUILD_GCC $BUILD_LIBICONV
}

install_libiconv() {
    install_wget
    create_directories
    cd $BUILDS
    if [ ! -f libiconv-$LIBICONV_VERSION.tar.gz ]; then
        wget -q --show-progress https://ftp.gnu.org/gnu/libiconv/libiconv-$LIBICONV_VERSION.tar.gz
    fi
    echo "libiconv-$LIBICONV_VERSION.tar.gz downloaded at $BUILDS"
    if [ ! -d libiconv-$LIBICONV_VERSION ]; then
        echo "Extracting libiconv-$LIBICONV_VERSION.tar.gz"
        tar -xf libiconv-$LIBICONV_VERSION.tar.gz
    fi
    echo "libiconv-$LIBICONV_VERSION extracted at $BUILDS"
    if [ ! -d /usr/local/Cellar/libiconv/$LIBICONV_VERSION ]; then
        echo "Building libiconv at /usr/local/Cellar"
        cd $BUILD_LIBICONV
        sudo ../libiconv-$LIBICONV_VERSION/configure --prefix=$LIBICONV_PREFIX
        sudo make
        sudo make install
    fi
    if [ -d /usr/local/Cellar/libiconv/$LIBICONV_VERSION ]; then
        echo "libiconv-$LIBICONV_VERSION built at $LIBICONV_PREFIX"
    fi
}

install_binutils() {
    install_libiconv
    install_texinfo
    cd $BUILDS
    if [ ! -f binutils-$BINUTILS_VERSION.tar.xz ]; then
        wget -q --show-progress https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.xz
    fi
    echo "binutils-$BINUTILS_VERSION.tar.xz downloaded at $BUILDS"
    if [ ! -d "binutils-$BINUTILS_VERSION" ]; then
        echo "Extracting binutils-$BINUTILS_VERSION.tar.xz"
        tar -xf binutils-$BINUTILS_VERSION.tar.xz
    fi
    echo "binutils-$BINUTILS_VERSION extracted at $BUILDS"
    if [ ! -d $PREFIX/bin ] || [ ! -d $PREFIX/$TARGET ] || [ ! -d $PREFIX/share ]; then
        echo "Building binutils-$BINUTILS_VERSION at $PREFIX"
        cd $BUILD_BINUTILS
        sudo ../binutils-$BINUTILS_VERSION/configure \
            --target=$TARGET --prefix=$PREFIX \
            --with-sysroot --disable-nls --disable-werror
        sudo make
        sudo make install
    fi
    if [ -d $PREFIX/$TARGET ] && [ -d $PREFIX/$TARGET ] && [ -d $PREFIX/share ]; then
        echo "Binutils built at $PREFIX"
    fi
}

# Function to download GCC sources
download_cc_sources() {
    install_binutils
    cd $BUILDS
    if [ ! -f "gcc-$GCC_VERSION.tar.xz" ]; then
        echo "Downloading gcc-$GCC_VERSION.tar.xz..."
        wget -q --show-progress https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz
    fi
    echo "gcc-$GCC_VERSION.tar.xz downloaded at $BUILDS"
    if [ ! -d gcc-$GCC_VERSION ]; then
        echo "Extracting gcc-$GCC_VERSION.tar.xz"
        tar -xf gcc-$GCC_VERSION.tar.xz
    fi 
    echo "gcc-$GCC_VERSION extracted at $BUILDS"
    echo "Successfully installed libiconv-$LIBICONV_VERSION, binutils-$BINUTILS_VERSION, and downloaded gcc-$GCC_VERSION!"
}

install_mac_ports() {
    cd $BUILDS
    if [ ! -f "MacPorts-2.10.1.tar.gz" ]; then
        echo "Downloading Macports..."
        wget -q --show-progress https://github.com/macports/macports-base/releases/download/v2.10.1/MacPorts-2.10.1.tar.gz
    fi
    echo "MacPorts downloaded at $BUILDS"
    if [ ! -d MacPorts-2.10.1 ]; then
        echo "Extracting MacPorts..."
        tar -xf MacPorts-2.10.1.tar.gz
    fi
    if [ ! -f /opt/local/bin/port ]; then
        echo "Installing MacPorts..."
        cd MacPorts-2.10.1
        ./configure && make && sudo make install
        cd .. && rm -rf MacPorts-2.10.1
    fi
}

install_cc_deps() {
    install_mac_ports
    if port installed gmp | grep -q "None"; then
        sudo port -q install gmp
    fi
    if port installed mpfr | grep -q "None"; then
        sudo port -q install mpfr
    fi
    if port installed libmpc | grep -q "None"; then
        sudo port -q install libmpc
    fi
}

# Function to disable red zone
disable_red_zone() {
    install_gnu_sed
    if [ ! -f $GCC_SOURCE/gcc/config/i386/t-x86_64-elf ]; then
        sudo chown -R $USER:admin $GCC_SOURCE
        touch $GCC_SOURCE/gcc/config/i386/t-x86_64-elf
    fi
    truncate -s 0 $GCC_SOURCE/gcc/config/i386/t-x86_64-elf
    echo "MULTILIB_OPTIONS += mno-red-zone" >> $GCC_SOURCE/gcc/config/i386/t-x86_64-elf
    echo "MULTILIB_DIRNAMES += no-red-zone" >> $GCC_SOURCE/gcc/config/i386/t-x86_64-elf
    gsed -i '/x86_64-\*-elf/a\	tmake_file="${tmake_file} i386/t-x86_64-elf"' $GCC_SOURCE/gcc/config.gcc
}

# Function to disable PCH
disable_pch() {
    install_gnu_sed
    gsed -i '/out_host_hook_obj=host-darwin.o/c\		#out_host_hook_obj=host-darwin.o' $GCC_SOURCE/gcc/config.host
    gsed -i '/host_xmake_file="${host_xmake_file} x-darwin"/c\		#host_xmake_file="${host_xmake_file} x-darwin"' $GCC_SOURCE/gcc/config.host
}

# Function to build cross-compiler
build_cross_compiler() {
    download_cc_sources
    install_cc_deps
    disable_red_zone
    disable_pch
    cd $BUILD_GCC
    echo "Building gcc-$GCC_VERSION at $PREFIX"
    export PATH=$PREFIX/bin:$PATH
    sudo ../gcc-$GCC_VERSION/configure \
        --target=$TARGET --prefix=$PREFIX \
        --disable-nls --enable-languages=c,c++ \
        --without-headers \
        --with-gmp=/usr --with-mpc=/opt/local --with-mpfr=/opt/local \
        --with-libiconv-prefix=/usr/local/Cellar
    sudo make -j 8 all-gcc
    sudo make all-target-libgcc
    sudo make install-gcc
    sudo make install-target-libgcc
}

install_nasm() {
    if ! brew list | grep -q nasm; then
        echo "Installing nasm at /opt/homebrew/bin"
        brew install nasm
    fi
}

install_qemu() {
    if ! brew list | grep -q qemu; then
        echo "Installing qemu at /opt/homebrew/bin"
        brew install qemu
    fi
}

# Install dependencies
install_brew
install_nasm
install_qemu

# Install cross-compiler
build_cross_compiler
echo "Cross-compiler installation complete!"
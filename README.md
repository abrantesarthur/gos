# GOS
An x86 bootloader written from scratch.

## Development

Gos requires Make >= 3. Unfortunately, the bootloader doesn't support the MacBook M1 architecture yet.

### Setting Up

You need a cross-compiler to compile your kernel, since your system compiler 
assumes you are writing code that will run on your hosted operating system.

Thus, the first step is to download the cross compiler and its dependecies:

```shell
make cross_compiler_download
```

This will download a more recent version of [libiconv](https://www.gnu.org/software/libiconv/),
build [GNU binutils](https://wiki.osdev.org/Binutils) targeting our
generic x86-64 architecture, and download `GCC-10.2.0`.

Since we are building a compiler for the x86-64 architecture, it is important
that we build [libgcc](https://wiki.osdev.org/Libgcc) without the "[red zone](https://wiki.osdev.org/Libgcc_without_red_zone)".
Thus, before issuing the next command, folow the
[instructions](https://wiki.osdev.org/Libgcc_without_red_zone) for doing so.

The instructions tell you to modify your [GCC](https://wiki.osdev.org/GCC)
sources. Know that they will be available at `~/opt/cross`.

```shell
make cross_compiler
```

This will actually build our cross compiler. It may take a few minutes to 
complete. Its binary will be available at `~/opt/cross/bin` as 
`x86_64-elf-gcc` together with the binaries of the `binutils` we built in the
previous step.

### Running

```shell
make run
```

This will compile the bootloader and run it on `qemu`. If you don't have `qemu` installed on your system, `brew install qemu` should do it :)

# GOS
I wanted to understand how an OS gets loaded into memory at boot time so I wrote an X86 bootloader from scratch.

## Development

Gos requires Make >= 3. Unfortunately, the bootloader doesn't support the MacBook M1 architecture yet.

### Setting Up

You need a cross-compiler to compile your kernel, since your system compiler 
assumes you are writing code that will run on your hosted operating system.

Thus, the first step is to download the cross compiler and its dependecies. We use `sudo` so the script can create the necessary directories.

```shell
sudo make cross_compiler_download
```

This will take a few minutes to complete. It will download a more recent version of [libiconv](https://www.gnu.org/software/libiconv/),
build [GNU binutils](https://wiki.osdev.org/Binutils) targeting our
generic x86-64 architecture, and download `GCC-10.2.0`.

To actually build our cross compiler, do:

```shell
make cross_compiler
```

It may take a few minutes to complete.

The cross compiler's binary will be available at `~/opt/cross/bin` as 
`x86_64-elf-gcc` together with the binaries of the `binutils` we built in the `cross_compiler_download` step.

### Running

```shell
make run
```

This will compile the bootloader and run it on `qemu`. If you don't have `qemu` installed on your system, `brew install qemu` should do it :)

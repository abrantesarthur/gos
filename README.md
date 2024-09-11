# GOS
I wanted to understand how an OS gets loaded into memory at boot time so I wrote an X86 bootloader from scratch.

## Development

Gos requires Make >= 3.

### Setting Up

You need a crosscompiler to compile the kernel on MacOS, since your default system compiler 
assumes you are writing code that will run on your hosted operating system. Get one by running:

```shell
make cross_compiler
```

This builds a crosscompiler targeting an x86-64 architecture and will take a few minutes to complete.

The crosscompiler's binary will be available at `~/opt/cross/bin` as `x86_64-elf-gcc`.

You'll also need QEMU to run the OS:

```shell
brew install qemu
```

### Running

To compile the bootloader and run it on `qemu`:

```shell
make run
```
# GOS
An operating system written entirely in GO, from scratch.

## Development

Gos requires

Make >= 3

### Workflow

You need a cross-compiler to compile your kernel, since your system compiler 
assumer you are writing code that will run on your hosted operating system.

Thus, the first step is to download the cross compiler and its dependecies:

```shell
make cross_compiler_download
```

This will download a more recent version of [libiconv](https://www.gnu.org/software/libiconv/),
build [GNU binutils](https://wiki.osdev.org/Binutils) targeting our
generic architecture, and download 'GCC-10.2.0'.

Since we are building a compiler for the 'x86-64' architecture, it is important
that we build 'Libgcc' without the "red zone". Thus, before issuing the next
command, folow the [instructions](https://wiki.osdev.org/Libgcc_without_red_zone)
for doing so.

```shell
make cross_compiler
```

This will actually build our cross compiler. It may take a few minutes to 
complete. Its binary will be available at `~/opt/cross/bin` together with 
the binaries of the `binutils` we built in the previous step.

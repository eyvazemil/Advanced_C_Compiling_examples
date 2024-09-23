# Dynamic libraries linking and loading in C/C++

This project consists of examples of building/linking/loading of dynamic libraries in C/C++ on Linux, along with smaller topics 
like static libraries, and analysis of ELF file format through object dumping and various tools. Thus, it can be used, as a guide
to writing/using dynamic libraries.

The code consists of C/C++ files along with the Makefile, which is the main piece of code of this project, as it illustrates
examples of the topics, covered in this project.

## Makefile

The main part of this project is a Makefile, which comprises of multiple parts that define multiple topics:

* _Preprocessor expansion_: intoduction to different stages of code compilation, including preprocessor expansion, generation of an 
assembly code, along with analysis of the object file (with `.o` expansion) and its various sections, e.g. `.data` section, which 
serves as a section for initialized global variables or `.bss` section, which is a section for uninitialized global variables.

* _ELF format_: introduction to `readelf` tool, which is used for analysis of ELF file, which is a standard format on Linux for 
storing executable and linkable binary files.

* _Static library_: building static library, which is instead of being linked to the target executable (the binary program that we will 
run), is included as a whole to the target binary, making it extermely bloated and large in size. Also, if multiple binaries use the 
same library and that library happens to be a static library, compiler would include that large library code into each of our binaries,
thus creating large files in our secondary memory.

* _Dynamic library building_: building of the dynamic library along with explanation of `-fPIC` linker flag, symbols analysis via 
`nm` tool, symbols mangling on C++ and how to demangle them via `extern C {}` code block. 

* _Dynamic library linking against target executable_: linking of the dynamic library to the target binary via `-L`, `-l`, and `-R` 
linker flags, via which we could supply the location (`-L` flag), name (`-l`), and runtime location (`-R`) of the library. Information
about the library's location and name is written to the ELF file of the target binary, so that, once we run our target binary, it could
load the appropriate library based on its location and name.

Also discusses library versioning and so-called __soname__, which is used as the name of the library that we provide via `-l` linker 
flag, rather than providing the library name with full version information.

* _Dynamic library versioning_: discusses dynamic library versioning, specifically, symbols versioning, which allows different target
binaries, which were build with different versions of the library to use the exact version of the symbols it needs.

Symbols versioning is achieved via __Linux Version Script__ and `.symver` assembly directive in the library's code.

This way, we can change the API of our library and provide the new library to the target binaries that used the old version of this library,
without having those target binaries recompile agains the new version of the library, as library would have had its old symbols for 
previous versions inside of it.
 

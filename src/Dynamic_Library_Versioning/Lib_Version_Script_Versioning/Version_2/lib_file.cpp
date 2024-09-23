#include "lib_file.h"
#include <iostream>


// Declare functions that will be actually executed, when referencing symbols
// that are given in `.symver` directive below.
#ifdef __cplusplus
extern "C" {
#endif

int lib_file_func_1_0(int num);
int lib_file_func_1_1(int num_1, int num_2);
int lib_file_func_2_0(int num);

#ifdef __cplusplus
}
#endif

// Now, as there are 2 major versions of the library, the target binaries that were
// linked against the first version `LIBSHAREDLIB_1.0.0` will be calling function 
// `lib_file_func_1_0()`, when referencing symbol `lib_file_func_1`.
// Defined with only one `@`, as it is not used in the latest version of the library 
// and is used only in the target binaries that use the old version of this library.
__asm__(".symver lib_file_func_1_0, lib_file_func_1@LIBSHAREDLIB_1.0.0");
int lib_file_func_1_0(int num) {
    std::cout << "LIBSHAREDLIB_MAJOR_VERSION_2" << std::endl;
    return num;
}

// Defined with two `@@`, as it is a definition of the function in the new version of the
// library, thus it is considered as a default function to be called, when symbol 
// `lib_file_func_1` is referenced.
__asm__(".symver lib_file_func_1_1, lib_file_func_1@@LIBSHAREDLIB_2.0.0");
int lib_file_func_1_1(int num_1, int num_2) {
    std::cout << "LIBSHAREDLIB_MAJOR_VERSION_2" << std::endl;
    return num_1 * num_2;
}

__asm__(".symver lib_file_func_2_0, lib_file_func_2@@LIBSHAREDLIB_1.0.0");
int lib_file_func_2_0(int num) {
    std::cout << "LIBSHAREDLIB_MAJOR_VERSION_2" << std::endl;
    return num * 2;
}

// We don't define the `.symver` directive for this function, as it is not even exported.
int DynamicLibraryVersioning::lib_file_func_3(int num) {
    return num * 3;
}

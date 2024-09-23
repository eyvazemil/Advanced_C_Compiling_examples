#include "lib_file.h"
#include <iostream>


// Declare functions that will be actually executed, when referencing symbols
// that are given in `.symver` directive below.
#ifdef __cplusplus
extern "C" {
#endif

int lib_file_func_1_0(int num);
int lib_file_func_2_0(int num);

#ifdef __cplusplus
}
#endif

// In all three functions, the function they defer to, when the target binary
// will be using default symbol versions, which is written with two `@@`, as this 
// is the first version of the library and there is no other version of the library, 
// that requires a different function to be called based on the same symbol.
// And as it is the first version of the library, we declare `.symver` directive 
// with two `@@` indicating that the function these symbols defer to are the default
// functions for those symbols.
__asm__(".symver lib_file_func_1_0, lib_file_func_1@@LIBSHAREDLIB_1.0.0");
int lib_file_func_1_0(int num) {
    std::cout << "LIBSHAREDLIB_MAJOR_VERSION_1" << std::endl;
    return num;
}

__asm__(".symver lib_file_func_2_0, lib_file_func_2@@LIBSHAREDLIB_1.0.0");
int lib_file_func_2_0(int num) {
    std::cout << "LIBSHAREDLIB_MAJOR_VERSION_1" << std::endl;
    return num * 2;
}

// We don't define the `.symver` directive for this function, as it is not even exported.
int DynamicLibraryVersioning::lib_file_func_3(int num) {
    return num * 3;
}

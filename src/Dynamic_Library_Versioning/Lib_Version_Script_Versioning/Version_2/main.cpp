#include "lib_file.h"
#include <iostream>

// Ensure that macro for using the right signature of `lib_file_func_1()` 
// library function is defined.
#if !defined(LIBSHAREDLIB_MAJOR_VERSION_2)
#   error "Macro `LIBSHAREDLIB_MAJOR_VERSION_2` hasn't been defined in build time of this binary!"
#endif


int main() {
    std::cout << "-- Second target binary -- DynamicLibraryVersioning::lib_file_func_1(6): " << 
        DynamicLibraryVersioning::lib_file_func_1(6, 5) << std::endl;

    std::cout << "-- Second target binary -- DynamicLibraryVersioning::lib_file_func_2(6): " << 
        DynamicLibraryVersioning::lib_file_func_2(6) << std::endl;

    return 0;
}

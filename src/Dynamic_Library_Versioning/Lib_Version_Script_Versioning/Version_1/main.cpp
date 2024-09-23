#include "lib_file.h"
#include <iostream>


int main() {
    std::cout << "-- First target binary -- DynamicLibraryVersioning::lib_file_func_1(6): " << 
        DynamicLibraryVersioning::lib_file_func_1(6) << std::endl;

    std::cout << "-- First target binary -- DynamicLibraryVersioning::lib_file_func_2(6): " << 
        DynamicLibraryVersioning::lib_file_func_2(6) << std::endl;

    return 0;
}

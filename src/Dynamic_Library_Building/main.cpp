#include "dynamic_library_loader.h"
#include <iostream>
#include <cassert>
#include <vector>

// Header file for handling loading of dynamic libraries.
#include <dlfcn.h>

// Pointer to the functions from the library that we will load.
// We have to define it here, as it is considered a new type,
// defined by us with the name `LIB_FUNC_PTR`.
typedef int (*LIB_FUNC_PTR)(int);

int main(int argc, char ** argv) {
    // Read the absolute path to the library.
    const std::string library_path = argv[1];

    // todo:_ remove this
    std::cout << "Library path: " << library_path << std::endl;

    // Load the dynamic library.
    void * lib_handle = nullptr;
    const std::vector<DynamicLibraryLoader::LibOpenFlag> lib_open_flags = 
        {DynamicLibraryLoader::LibOpenFlag::LAZY_BINGING};

    DynamicLibraryLoader::LibStatus lib_open_status = DynamicLibraryLoader::lib_open(
        library_path, &lib_handle, lib_open_flags
    );

    assert(lib_open_status == DynamicLibraryLoader::LibStatus::LIB_OPEN_SUCCESS);
    assert(lib_handle);

    // Check if the library is already loaded.
    DynamicLibraryLoader::LibStatus lib_is_loaded_status = 
        DynamicLibraryLoader::lib_is_loaded(library_path, lib_open_flags);

    assert(lib_is_loaded_status == DynamicLibraryLoader::LibStatus::LIB_IS_LOADED);

    // Load first symbol as function pointers to the library functions.
    void * lib_first_symbol_handle = nullptr;
    DynamicLibraryLoader::LibStatus lib_resolve_first_symbol_status =  DynamicLibraryLoader::lib_resolve_symbol(
        "first_file_func", &lib_first_symbol_handle, lib_handle
    );

    assert(lib_resolve_first_symbol_status == DynamicLibraryLoader::LibStatus::LIB_SYM_LOAD_SUCCESS);
    assert(lib_first_symbol_handle);

    // Load second symbol.
    // We can't load the `second_file_func()` function, as its symbol is linker and platform dependent
    // due to name mangling, but we can easily load another symbol, which is `second_file_C_style_func`,
    // as it is defined inside `extern "C" {}` block, which prevents linker imposed C++ name mangling.
    void * lib_second_symbol_handle = nullptr;
    DynamicLibraryLoader::LibStatus lib_resolve_second_symbol_status =  DynamicLibraryLoader::lib_resolve_symbol(
        "second_file_C_style_func", &lib_second_symbol_handle, lib_handle
    );

    assert(lib_resolve_second_symbol_status == DynamicLibraryLoader::LibStatus::LIB_SYM_LOAD_SUCCESS);
    assert(lib_second_symbol_handle);

    // Reference the symbols, i.e. call the library functions.
    std::cout << "DynamicLibraryBuilding::first_file_func(5): " << ((LIB_FUNC_PTR) lib_first_symbol_handle)(5) << std::endl;
    std::cout << "DynamicLibraryBuilding::second_file_C_style_func(6): " << ((LIB_FUNC_PTR) lib_second_symbol_handle)(6) << std::endl;

    // Close the library.
    DynamicLibraryLoader::lib_close(&lib_handle);
    assert(!lib_handle);

    return 0;
}

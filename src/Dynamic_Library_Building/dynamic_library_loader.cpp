#include "dynamic_library_loader.h"
#include <cassert>

// Header file for handling loading of dynamic libraries.
#include <dlfcn.h>

namespace DynamicLibraryLoader {

/**
 * Converts the vector of flags to the corresponding integer
 * that represent the flags that are passed to `lib_open()` function.
 * 
 * TODO: only lazy binding `RTLD_LAZY` and `RTLD_NOW` flags are supported 
 *       for now, add more in the future.
 */
static int resolve_flags(std::vector<LibOpenFlag> vec_flags) {
    int flags = 0;

    for(const auto & flag : vec_flags) {
        if(flag == LibOpenFlag::LAZY_BINGING) {
            flags |= RTLD_LAZY;
        }
    }

    return flags;
}

LibStatus lib_open(std::string lib_path, void ** lib_handle, std::vector<LibOpenFlag> flags) {
    assert(lib_handle);
    assert(!(*lib_handle));

    // Get a handle to the shared library.
    // In case if it was already opened, an already existing handle
    // is returned and a reference count to this library is increased by 1.
    // Thus, after opening and calling its symbols, we must make sure to 
    // close it, so that the reference count of this library is decreased 
    // to 0, thus this library gets deallocated.
    const int resolved_flags = resolve_flags(flags);
    *lib_handle = dlopen(lib_path.c_str(), resolved_flags);

    if(!lib_handle) {
        *lib_handle = nullptr;
        return LibStatus::LIB_OPEN_FAIL;
    }

    return LibStatus::LIB_OPEN_SUCCESS;
}

LibStatus lib_is_loaded(std::string lib_path, std::vector<LibOpenFlag> flags) {
    // As the `RTLD_NOLOAD` flag makes `dlopen()` to not load the library
    // if it hasn't been loaded and return the handle of the already loaded librar,
    // if it has been opened, the `flags` vector that we specify as a parameter,
    // can be used to propagate a different set of flags to the already loaded library.
    const int resolved_flags = resolve_flags(flags);
    void * lib_handle = dlopen(lib_path.c_str(), RTLD_NOLOAD | resolved_flags);

    if(!lib_handle) {
        return LibStatus::LIB_IS_NOT_LOADED;
    }

    // In case if this library has already been loaded before, i.e. current 
    // call to `dlopen()` has returned a valid handle, thus is has incremented
    // the reference count of this library, we have to close it, in order to
    // decrease that reference count to restore it back to its previous value.
    dlclose(lib_handle);

    return LibStatus::LIB_IS_LOADED;
}

LibStatus lib_resolve_symbol(std::string symbol_name, void ** lib_symbol_handle, void * lib_handle) {
    assert(lib_handle);
    assert(lib_symbol_handle);
    assert(!(*lib_symbol_handle));

    *lib_symbol_handle = dlsym(lib_handle, symbol_name.c_str());

    // Check for the errors from the symbol loading.
    if(!lib_symbol_handle) {
        *lib_symbol_handle = nullptr;
        return LibStatus::LIB_SYM_LOAD_FAIL;
    }

    return LibStatus::LIB_SYM_LOAD_SUCCESS;
}

void lib_close(void ** lib_handle) {
    assert(lib_handle);
    assert(*lib_handle);

    dlclose(*lib_handle);
    *lib_handle = nullptr;
}

} // DynamicLibraryLoader

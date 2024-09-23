#ifndef DYNAMIC_LIBRARY_LOADER_H
#define DYNAMIC_LIBRARY_LOADER_H

/**
 * @brief Contains utility functions that we use for loading a given dynamic library,
 * its symbols, gettings the last error, and closing that dynamic library.
 */

#include <string>
#include <vector>

namespace DynamicLibraryLoader {

/**
 * @brief Used as in the return value of our functions to indicate
 * successful loading/closing of the library/symbol.
 */
enum class LibStatus {
    LIB_OPEN_SUCCESS,
    LIB_OPEN_FAIL,
    LIB_IS_LOADED,
    LIB_IS_NOT_LOADED,
    LIB_SYM_LOAD_SUCCESS,
    LIB_SYM_LOAD_FAIL
};

/**
 * @brief Flags that encapsulate the flags that 
 * are passed to `lib_open()` function.
 */
enum class LibOpenFlag {
    LAZY_BINGING, // corresponds to `RTLD_LAZY`
    IMMEDIATE_BINDING // corresponds to `RTLD_NOW`
};

/**
 * @brief Loads the library with a given library path.
 * The path to the library is either an absolute path or 
 * only the file name of the library.
 * We don't have to provide an absolute path to the library
 * and simply provide the library file name if:
 * - We set the environment variable `LD_LIBRARY_PATH`
 *   to include the path to this library.
 * - This object file contains a `DT_RUNPATH` tag that has the 
 *   location of this library listed.
 * - There is an entry in `etc/ld.so.cache` for that library name.
 * - Library is located in `/lib` or `/usr/lib` directories.
 * 
 * @param lib_path Path to the library (either absolute or just file name).
 * @param lib_handle Pointer to the handle that we supply to this function
 *                   to be modified to point to the exact handle.
 * 
 * @param flags Vector of flags that we want to pass to `dlopen()` function.
 *              It is important to note that one set of flags called from one 
 *              process doesn't affect the set of flags of another process that
 *              loaded this library, i.e. every process has its own way of loading 
 *              this exact library and if one process loads this library with 
 *              `RTLD_LAZY` and another one with `RTLD_NOW`, the first library
 *              will have the lazy binding and another process will have the
 *              immediate binding of symbols of this shared library.
 * 
 *              TODO: right now, only lazy and immediate binding, i.e. `RTLD_LAZY` 
 *                    and `RTLD_NOW` flags are supported.
 */
LibStatus lib_open(std::string lib_path, void ** lib_handle, std::vector<LibOpenFlag> flags);

/**
 * @brief Returns `LIB_IS_LOADED` if library with the given path
 * has already been loaded and `LIB_IS_NOT_LOADED` if that library
 * hasn't been loaded yet.
 * 
 * This function doesn't load the library in case if it wasn't loaded,
 * thus we don't get any handle from it, instead it only checks if the 
 * given library has already been loaded.
 * 
 * This function doesn't increment the reference count of this library.
 */
LibStatus lib_is_loaded(std::string lib_path, std::vector<LibOpenFlag> flags);

/**
 * @brief Resolves the symbol via a given name and returns its address.
 * In case if symbol loading was unsuccessful, the error is printed and
 * library is closed.
 * 
 * @param symbol_name Name of the symbol.
 * @param lib_symbol Pointer to the symbol handle that this function will modify.
 * @param lib_handle Handle of the library, the symbol of which we want to load.
 */
LibStatus lib_resolve_symbol(std::string symbol_name, void ** lib_symbol_handle, void * lib_handle);

/**
 * @brief Closes the library given exact library handle.
 * Also sets the given \param lib_handle to nullptr, that 
 * is why we pass a pointer to the handle.
 */
void lib_close(void ** lib_handle);

} // DynamicLibraryLoader

#endif // DYNAMIC_LIBRARY_LOADER_H
#ifndef LIB_FILE_H
#define LIB_FILE_H

// Namespace of this library.
namespace DynamicLibraryVersioning {

// We use it to prevent the linker enforced 
// C++ name mangling of symbols.
#ifdef __cplusplus
extern "C" {
#endif

// We don't declare the symbol visibility here, as it will be 
// managed by the version script and `.symver` directive below.

// Due to the fact that for the second major version of the library,
// the signature of this function differs from the first version of the library,
// we have to provide 2 different signatures depending on the version of the library.
// This macro is custom and it should be defined, when building the target binary 
// that uses the second version of this library.

#ifdef LIBSHAREDLIB_MAJOR_VERSION_2
int lib_file_func_1(int num_1, int num_2);
#else
int lib_file_func_1(int num);
#endif

int lib_file_func_2(int num);
int lib_file_func_3(int num);

#ifdef __cplusplus
}
#endif

} // DynamicLibraryVersioning

#endif // LIB_FILE_H

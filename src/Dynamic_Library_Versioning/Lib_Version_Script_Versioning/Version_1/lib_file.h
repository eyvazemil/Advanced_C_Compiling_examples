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
int lib_file_func_1(int num);
int lib_file_func_2(int num);
int lib_file_func_3(int num);

#ifdef __cplusplus
}
#endif

} // DynamicLibraryVersioning

#endif // LIB_FILE_H

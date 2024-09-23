#ifndef LIB_FILE_H
#define LIB_FILE_H

// Namespace of this library.
namespace DynamicLibraryVersioning {

// We use it to prevent the linker enforced 
// C++ name mangling of symbols.
#ifdef __cplusplus
extern "C" {
#endif

// Declare the symbol of this function as visible, i.e. 
// can be imported by target executable/another library.
__attribute__ ((visibility("default")))
int lib_file_func(int num);

#ifdef __cplusplus
}
#endif

} // DynamicLibraryVersioning

#endif // LIB_FILE_H

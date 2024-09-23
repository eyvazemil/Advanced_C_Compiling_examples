#ifndef FIRST_FILE_H
#define FIRST_FILE_H

// We should define our library functions in its own namespace, 
// so that the symbols of this library don't collide with the symbols 
// of another library with the similar symbol names.
namespace DynamicLibraryBuilding {

// This will prevent the name mangling, so that the linker doesn't 
// create the function symbol with additional information about its parameters.
#ifdef __cplusplus
extern "C" {
#endif

__attribute__ ((visibility("default")))
int first_file_func(int num);

__attribute__ ((visibility("hidden")))
int first_file_hidden_func(int num);

#ifdef __cplusplus
}
#endif

} // DynamicLibraryBuilding

#endif // FIRST_FILE_H

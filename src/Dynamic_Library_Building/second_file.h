#ifndef SECOND_FILE_H
#define SECOND_FILE_H

// We have to define our library functions in its own namespace, 
// so that the symbols of this library don't collide with the symbols 
// of another library with the similar symbol names.
namespace DynamicLibraryBuilding {

__attribute__ ((visibility("default")))
int second_file_func(int num);

#ifdef __cplusplus
extern "C" {
#endif

__attribute__ ((visibility("default")))
int second_file_C_style_func(int num);

#ifdef __cplusplus
}
#endif

} // DynamicLibraryBuilding

#endif // SECOND_FILE_H

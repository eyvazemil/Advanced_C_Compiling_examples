#include "second_file.h"

int DynamicLibraryBuilding::second_file_func(int num) {
    return num * num;
}

int DynamicLibraryBuilding::second_file_C_style_func(int num) {
    return second_file_func(num);
}

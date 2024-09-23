#include "preprocessor_expansion.h"

int global_variable_zero = 0;
int global_variable_negative = -1;

int add(int num) {
    return num + MACRO_TEST;
}

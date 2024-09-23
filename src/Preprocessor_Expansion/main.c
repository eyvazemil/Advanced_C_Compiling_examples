#include "preprocessor_expansion.h"
#include <stdio.h>

int main() {
    printf("Sum of 5 with %d is %d\n", MACRO_TEST, add(5));

    return 0;
}

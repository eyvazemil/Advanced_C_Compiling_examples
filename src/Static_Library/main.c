#include "first_file.h"
#include "second_file.h"
#include <stdio.h>

int main() {
    printf("first_file_func(5): %d, second_file_func(5): %d\n",
        first_file_func(5), second_file_func(5)
    );

    return 0;
}

#include <stdio.h>


class ThirdFile {
public:
    ThirdFile() {
        puts("\n__Called from the third file__\n");
    }
};

// Here, the constructor of this object will be called, thus if this file
// is linked to the target binary, then the constructor will write to STDOUT.
ThirdFile third_file;

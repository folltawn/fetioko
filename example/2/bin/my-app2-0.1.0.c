#include <stdio.h>

const char GLOBAL = 'G';

int main(void) {
    const int x = 14;
    char* y = "hi";
    static const char f = 'f';
    printf("%s\n", x);
    printf("%s\n", y);
    printf("%s\n", f);
    printf("%s\n", GLOBAL);
    y = "hello";
    printf("%s\n", y);
    return 0;
}

static int fl(void) {
    static const int x = 14;
    printf("%s\n", x);
    return 0;
}


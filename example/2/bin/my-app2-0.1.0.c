#include <stdio.h>

const char GLOBAL = 'G';

int main(void) {
    const int itz = 14;
    char* y = "hi";
    static const char f = 'f';
    printf("%d\n", itz);
    printf("%s\n", y);
    printf("%c\n", f);
    printf("%c\n", GLOBAL);
    y = "hello";
    printf("%s\n", y);
    return 0;
}

static int fl(void) {
    static const int x = 14;
    printf("%d\n", x);
    return 0;
}


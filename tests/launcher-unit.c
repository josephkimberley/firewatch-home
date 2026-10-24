#define FIREWATCH_LAUNCHER_UNIT_TEST
#include "../src/launcher.c"
#include <assert.h>
int main(void) {
    char result[256];
    assert(json_string("/apps/firewatch/main.qml", result, sizeof(result)) == 0);
    assert(strcmp(result, "\"/apps/firewatch/main.qml\"") == 0);
    assert(json_string("/odd/\"quote\\slash\n", result, sizeof(result)) == 0);
    assert(strcmp(result, "\"/odd/\\u0022quote\\u005cslash\\u000a\"") == 0);
    assert(json_string("x", result, 3) == -1);
    assert(json_string("", result, 3) == 0);
    assert(strcmp(result, "\"\"") == 0);
    assert(json_string("\n", result, 8) == -1);
    assert(json_string("\n", result, 9) == 0);
    return 0;
}

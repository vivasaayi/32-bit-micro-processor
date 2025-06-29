#include <stdio.h>

  #define MACRO_WITH_SPACES 42
	#define MACRO_WITH_TABS 100

#define LONG_MACRO_NAME_THAT_CONTINUES \
    on_multiple_lines_with_backslash

#if 0
    This should be skipped
#endif

int main() {
    int x = 10;
    return x;
}

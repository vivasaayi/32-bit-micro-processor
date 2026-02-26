#include <stdint.h>

// Example utility entrypoint style for future ABI integration.
// For now these files document intended utility shape.
int32_t util_echo(int argc, const char **argv) {
    (void)argc;
    (void)argv;
    return 0;
}

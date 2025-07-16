// Check if a string looks like a label name (not a number)
static bool is_label_name(const char *str) {
    if (!str || *str == '\0') return false;
    
    // Skip leading whitespace
    while (isspace(*str)) str++;
    
    // If it starts with '#' or is a number, it's not a label
    if (*str == '#') return false;
    if (*str == '-' || *str == '+') str++; // Skip sign
    if (isdigit(*str)) {
        // Check if entire string is numeric
        while (isdigit(*str) || *str == 'x' || *str == 'X' || 
               (*str >= 'a' && *str <= 'f') || (*str >= 'A' && *str <= 'F')) {
            str++;
        }
        return (*str != '\0'); // If we didn't reach end, it's not purely numeric
    }
    
    // Must start with letter or underscore for a valid label
    return (isalpha(*str) || *str == '_');
}

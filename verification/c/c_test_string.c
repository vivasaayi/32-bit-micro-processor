// String Operations Test
// Verifies: Pointers, Arrays, Loops, Char access

int my_strlen(char *s) {
  int len = 0;
  while (*s != 0) {
    len++;
    s++;
  }
  return len;
}

void my_strcpy(char *dest, char *src) {
  while (*src != 0) {
    *dest = *src;
    dest++;
    src++;
  }
  *dest = 0;
}

int main() {
  char str1[10];
  char str2[10];

  // Fill str1 "Hello"
  str1[0] = 'H';
  str1[1] = 'e';
  str1[2] = 'l';
  str1[3] = 'l';
  str1[4] = 'o';
  str1[5] = 0;

  int len = my_strlen(str1);
  if (len != 5)
    return 0;

  // Copy
  my_strcpy(str2, str1);

  if (str2[0] != 'H')
    return 0;
  if (str2[4] != 'o')
    return 0;
  if (str2[5] != 0)
    return 0;

  return 1; // PASS
}

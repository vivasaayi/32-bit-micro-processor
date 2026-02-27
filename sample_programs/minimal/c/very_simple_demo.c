int main() {
    int* mode_reg = (int*)0xFF000000;
    *mode_reg = 0;
    
    short* text = (short*)0xFF001000;
    text[0] = 0x0F48;
    text[1] = 0x0F45;
    text[2] = 0x0F4C;
    text[3] = 0x0F4C;
    text[4] = 0x0F4F;
    
    return 0;
}

typedef unsigned short word;
typedef unsigned int* pword;
typedef unsigned char byte;
typedef unsigned char* pbyte;
typedef unsigned short u16;
typedef signed short s16;
typedef unsigned char u8;
typedef signed char s8;
typedef unsigned long u32;
typedef unsigned long dword;
typedef unsigned char bool;
typedef bool (__pascal* progress)(byte current, byte max);
typedef void (__pascal* leds)(byte leds);
enum {false, true};


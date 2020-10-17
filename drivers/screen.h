#define VIDEO_ADDR		0xB8000
#define MAX_ROWS		25
#define MAX_COLS		80
#define WHITE_ON_BLACK	0x0F

// screen device I/O ports
#define REG_SCREEN_CTRL	0x3D4
#define REG_SCREEN_DATA	0x3D5



void print_char(char character, int row, int col, char attribute);
int get_screen_offset(unsigned int col, unsigned int row);
int get_cursor_position();
void set_cursor_position(int cursor);

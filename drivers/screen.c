void print_char(char character, int row, int col, char attribute) {
	unsigned char *video_addr = (unsigned char *) VIDEO_ADDR;

	// if no attribute was passed, use default
	if(!attribute) {
		attribute = WHITE_ON_BLACK;
	}

	int offset;
	//use col and row for offset, or default for cursor position
	if (col >= 0 && row >= 0) {
		offset = get_screen_offset(col, row);
	} else {
		offset = get_cursor_position();
	}

	// if new line character, set offset to last column of current row, so it
	// will later be updated to first column of next row
	if (character == '\n') {
		// we use 2 * MAX_COLS because each column has 2 bytes: 1 for
		// character ASCII code and the other for the attribute
		int rows = offset / (2 * MAX_COLS);
		offset = get_screen_offset(MAX_COLS - 1, rows);
	} else {
		video_addr[offset] = character;
		video_addr[offset+1] = attribute;
	}
		
	offset += 2;
	// adjust scrolling, for when we reach bottom of screen
	offset = handle_scrolling(offset);
	// update cursor position
	set_cursor_position(offset);
}


int get_scren_offset(unsigned int col, unsigned int row) {
	if (col > MAX_COLS) {
		col = MAX_COLS;
	}
	if (row > MAX_ROWS) {
		row = MAX_ROWS;
	}
	return (row * MAX_COLS + col) * 2;
}

int get_cursor_position() {
	// VGA device's register 14 holds high cursor byte
	// VGA device's register 15 holds low cursor byte

	// tell device we want to read register 14
	port_byte_out(REG_SCREEN_CTRL, 14);
	// actually read register 14
	int offset = port_byte_in(REG_SCREEN_DATA) << 8;
	// tell device we want to read register 15
	port_byte_out(REG_SCREEN_CRTL, 15);
	// actually read register 15
	offset += port_byte_int(REG_SCREEN_DATA);
	
	// VGA's offset is simply the number of characters, so we multiply by 2
	// to account for attributes
	return offset * 2;	
}

void set_cursor_position(int offset) {
	// convert from cell offset to char offset
	offset /= 2;
	
	port_byte_out(REG_SCREEN_CTRL, 14);
	port_byte_out(REG_SCREEN_DATA, (unsigned char)(offset >> 8));		
	port_byte_out(REG_SCREEN_CTRL, 15);
	port_byte_out(REG_SCREEN_DATA, (unsigned char) offset);	
}

void print_at(char *message, int col, int row) {
	// update the cursor if necessary
	if (col >= 0 && row >= 0) {
		set_cursor_position(get_screen_offset(col, row));
	}

	int i = 0;
	while(message[i] != 0) {
		print_char(message[i], col, row, WHITE_ON_BLACK);
	}
}

void print(char *message) {
	print_at(message, -1, -1);
}

void clear_screen() {
	for(int row = 0; row < MAX_ROWS; row++) {
		for (int col = 0; col < MAX_COLS; col++) {
			print_char(' ', col, row, WHITE_ON_BLACK);
		}
	}

	set_cursor_position(get_screen_offset(0, 0));
}

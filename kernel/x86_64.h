// write data to port
void port_byte_out(unsigned short port, unsigned char data) {
	// "a" (data): load EAX with data
	// "d" (port): load EDX with port
	__asm__("out %%al, %%dx": : "a" (data), "d" (port));
}

// return data from port
unsigned char port_byte_in(unsigned short port) {
	int result;
	// "=a" (result): store AL in result when finished
	// "d" (port): load EDX with port
	__asm__("in %%dx, %%al", : "=a" (result) : "d" (port)); 
	return result
}

// write data to port
void port_word_out(unsigned short port, unsigned short data) {
	__asm__("out %%ax, %%dx": : "a" (data), "d" (port));
}

// return short data from port
unsigned short port_word_in(unsigned short port) {
	unsigned short result;
	__asm__("in %%dx, %%ax": "=a" (result) : "d" (port));
	return result;
}

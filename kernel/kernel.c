void some_function(char* c) {

}

void main() {
	char* video_memory = (char *) 0xb8000;
	*video_memory = 'X';
	some_function(video_memory);
}
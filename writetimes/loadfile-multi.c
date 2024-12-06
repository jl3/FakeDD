/*
 * Reads multiple file to a buffer and then continues to run until terminated
 *
 * Syntax: loadfile-multi <offset> <file1> ... <fileN>
 */

#define _POSIX_C_SOURCE 200112L

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <string.h>

int main(int argc, char **argv) {
	char **filemem;
	char **filename;
	int numFiles;
	long *bufsize;
	int offset;
	if(argc >= 3) {
		offset = atoi(argv[1]);
		numFiles = argc-2;
		filename = malloc(numFiles*sizeof(char*));
		bufsize = malloc(numFiles*sizeof(long*));
		for(int i = 0; i < numFiles; i++) {
			filename[i] = argv[i+2];
		}
		filemem = malloc(numFiles*sizeof(char*));
	} else {
		return(1);
	}

	for(int i = 0; i < numFiles; i++) {
		// uses code for loading files into memory from http://stackoverflow.com/questions/140029524/c-programming-how-to-read-the-whole-file-contents-into-a-buffer
		FILE *fp = fopen(filename[i], "r");
		if(fp != NULL) {
			/* Go to the end of the file. */
			if (fseek(fp, 0L, SEEK_END) == 0) {
				/* Get the size of the file. */
				bufsize[i] = ftell(fp);
				printf("%s: %i-%i\n", filename[i], bufsize[i], offset);
				if(bufsize[i] == -1) { /* Error */ }
				bufsize[i] -= offset; // offset bytes will not be loaded
				/* Allocate page-aligned buffer. */
				int maret = posix_memalign((void **)&filemem[i], sysconf(_SC_PAGESIZE), bufsize[i]);

				if(maret!=0) {
					return 2;
				}

				/* Go back to the start of the file, taking the offset into account. */
				if(fseek(fp, offset, SEEK_SET) != 0) { /* Error */ }

				/* Read the entire file into memory. */
				size_t newLen = fread(filemem[i], sizeof(char), bufsize[i], fp);
				if(newLen == 0) {
					fputs("Error reading file", stderr);
				}
			}
			fclose(fp);
		} else {
			return 3;
		}
	}

	getchar(); // Wait for input before continuing...

	// Nullify memory
	for(int i = 0; i < numFiles; i++) {
		memset(filemem[i], 0, bufsize[i]); // Nullify source
		free(filemem[i]);
	}

	return 0;
}

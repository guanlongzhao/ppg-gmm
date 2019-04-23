/* htk2ark

Usage: htk2ark <input_HTK_feature_file_list> <output_ark_feature_file_name>

Takes HTK feature files specified in the input_HTK_feature_file_list, converts them into Kaldi format, and stores in output_ark_feature_file_name. Produces a complementary scp file for Kaldi that contains list of utterance files and fast access addresses.

%
%
% Copyright 2013 Hynek Boril, Center for Robust Speech Systems (CRSS), The University of Texas at Dallas
%
%   Licensed under the Apache License, Version 2.0 (the "License");
%   you may not use this file except in compliance with the License.
%   You may obtain a copy of the License at
%
%       http://www.apache.org/licenses/LICENSE-2.0
%
%   Unless required by applicable law or agreed to in writing, software
%   distributed under the License is distributed on an "AS IS" BASIS,
%   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%   See the License for the specific language governing permissions and
%   limitations under the License.
%
% Contact: borilh@gmail.com


Compilation:  gcc -std=c99 -Wall htk2ark.c -o htk2ark
*/

#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <string.h>

// ========================= FUNCTIONS: ENDIAN CONVERSION (Little <-> Big and Vice Versa) ==========================

union byte2 {
	char byte[2];
	short int numint;
};

union byte4 {
	char byte[4];
	int numint;
	float numfloat;
};

//-------- New -------------

void endianSwap4(union byte4 *un) {
    // swap
    char c1 = (*un).byte[0];
    (*un).byte[0] = (*un).byte[3];
    (*un).byte[3] = c1;
    c1 = (*un).byte[1];
    (*un).byte[1] = (*un).byte[2];
    (*un).byte[2] = c1;
}
//----------------------------

short int endianSwap2int(short int a) {
	union byte2 un;
	un.numint = a;

	// swap
	char c1 = un.byte[0];
	un.byte[0] = un.byte[1];
	un.byte[1] = c1;

	return un.numint;
}

int endianSwap4int(int a) {
	union byte4 un;
	un.numint = a;

	// swap
	char c1 = un.byte[0];
	un.byte[0] = un.byte[3];
	un.byte[3] = c1;
	c1 = un.byte[1];
	un.byte[1] = un.byte[2];
	un.byte[2] = c1;

	return un.numint;
}

float endianSwap4float(float a) {
	union byte4 un;
	un.numfloat = a;

	// swap
	char c1 = un.byte[0];
	un.byte[0] = un.byte[3];
	un.byte[3] = c1;
	c1 = un.byte[1];
	un.byte[1] = un.byte[2];
	un.byte[2] = c1;

	return un.numfloat;
}


long int findTokenInString(char *string, char *search_token) {
	
	long int search_token_length;
	char token_buffer[256] = {'\0'};
	char search_buffer[256] = {'\0'};
	long int byte_counter;
	long int i;
	char input_char;
	
	search_token_length = strlen(search_token);

	if (search_token_length > 256)	{
		printf("findTokenInString(): search token length %ld bigger than size of token_buffer, terminating!\n", search_token_length);
		return 1;
	}

	(void) strcpy(token_buffer, search_token);    // copy the search token into a buffer of a fixed length (the search token can in general have a variable length); we want a fixed length

	byte_counter = 0;
	while (1) {
	// shift the search buffer by 1
		for (i = 0; i < search_token_length - 1; i++)	{
			search_buffer[i] = search_buffer[i + 1];
		}
		input_char = string[byte_counter];
		if (input_char == '\0') {
			break;
		}
		search_buffer[search_token_length - 1] = input_char;

		if (!strcmp(search_buffer, token_buffer)) {
			return byte_counter - search_token_length + 1;
		}
		byte_counter++;
	}
	return -1;              // -1 -> didn't find the token
}

void help()
{
	printf("\nhelp: htk2ark <input_HTK_feature_file_list> <output_ark_feature_file_name>\n\n");
}

// ============================ MAIN ==============================

int main(int argc, char *argv[]) {
    if (argc != 3) {                            // Check number of input parameters
         help();
	     return 2;
    }
    
    FILE *fin_list, *fin_htk, *fout_ark, *fout_scp;
	struct stat st; 

	char delim1[3] = "\n";
	char delim2[2] = "/";
	char delim3[5] = ".ark";
	char delim4[5] = ".fea";

	char htk_list_line[1000];
	char fname_scp_out[1000];
	char fname_htk_fea_in_raw_no_ext [1000];
	char *fname_htk_fea_in, *fname_htk_fea_in_raw, *fname_ark_out, *token;
	union byte4 sample;
	unsigned long int sample_counter;
	long int token_index;
	long int ark_access_index;

	//------- HTK Header Parameters ---------
	long int number_of_frames;
	unsigned long int fea_vector_length;
	long int sample_period;              // x 100 ns
	short int number_of_bytes_per_frame;
	short int parameter_kind;

	//----------- Open Input HTK list and Output ark and scp File ------------
	if (stat(argv[1], &st) == 0) {
		if (st.st_size == 0) {
		    printf("Empty list of input HTK feature files %s, quitting!\n", argv[1]);
			return 1; 
		}
	}
	else {
	    printf("Cannot open source file %s!\n", argv[1]);
		return 1; 
	}
	if ((fin_list = fopen(argv[1], "rt")) == NULL) {
	    printf("Cannot open list of input HTK feature files %s!\n", argv[1]);
	    return 1;
	}
	if ((fout_ark = fopen(argv[2], "wb")) == NULL) {
	    printf("Cannot open output ark file %s for writing!\n", argv[2]);     
	    return 1;          
	}

	memset(fname_scp_out, 0, 1000);
	fname_ark_out = argv[2];
	token_index = findTokenInString(fname_ark_out, delim3);

	if (token_index == -1)	{                 // filename doesn't contain .ark extension -> just add .scp to the ark file name to create scp file name
		strcpy(fname_scp_out, fname_ark_out);
		strcat(fname_scp_out, ".scp");
	}
	else {
		strncpy(fname_scp_out, fname_ark_out, token_index);
		strcat(fname_scp_out, ".scp");
	}

	if ((fout_scp = fopen(fname_scp_out, "wt")) == NULL) {
	    printf("Cannot open output scp file %s for writing!\n", fname_scp_out);     
	    return 1;          
	}

	//-------- Read HTK file list and read/write features in ark file -----

	while(!feof(fin_list)) {
		memset(htk_list_line, 0, 1000);
		if(fgets(htk_list_line, sizeof(htk_list_line), fin_list)) {
			fname_htk_fea_in = strtok(htk_list_line, delim1);

			// Open and read HTK feature file

			if (stat(fname_htk_fea_in, &st) == 0) {
				if (st.st_size == 0) {
				    printf("Empty input HTK feature file %s, skipping!\n", fname_htk_fea_in);
					continue; 
				}
			}
			else {
			    printf("Cannot open input HTK feature file %s, skipping!\n", fname_htk_fea_in);
				continue; 
			}
			if ((fin_htk = fopen(fname_htk_fea_in, "rt")) == NULL) {
			    printf("Cannot open input HTK feature file %s, skipping!\n", fname_htk_fea_in);
			    return 1;
			}

			// get raw HTK file name
			token = strtok(fname_htk_fea_in, delim2);
			while(token != NULL) {
				fname_htk_fea_in_raw = token;
				token = strtok(NULL, delim2);
			}
			memset(fname_htk_fea_in_raw_no_ext, 0, 1000);
			token_index = findTokenInString(fname_htk_fea_in_raw, delim4);
			if (token_index == -1)	{                 // filename doesn't contain .ark extension -> just add .scp to the ark file name to create scp file name
				strcpy(fname_htk_fea_in_raw_no_ext, fname_htk_fea_in_raw);
			}
			else {
				strncpy(fname_htk_fea_in_raw_no_ext, fname_htk_fea_in_raw, token_index);
			}

			// read HTK header (12 Bytes) - big endians
			fread(&number_of_frames, 4, 1, fin_htk);
			fread(&sample_period, 4, 1, fin_htk);
			fread(&number_of_bytes_per_frame, 2, 1, fin_htk);
			fread(&parameter_kind, 2, 1, fin_htk);
					
			number_of_frames = (unsigned long int) endianSwap4int(number_of_frames);
			sample_period = endianSwap4int(sample_period);
			number_of_bytes_per_frame = endianSwap2int(number_of_bytes_per_frame);
			fea_vector_length = number_of_bytes_per_frame/4;                  // each sample is float32
			
			if (fprintf(fout_ark, "%s %cBFM %c", fname_htk_fea_in_raw_no_ext, 0, 4) < 0) {
				printf("Couldn't write header to %s, quitting!\n", argv[2]);
				return 1;
			}
			fwrite(&number_of_frames, 4, 1, fout_ark);
			fprintf(fout_ark, "%c", 4);
			fwrite(&fea_vector_length, 4, 1, fout_ark);

			for (sample_counter = 0; sample_counter < number_of_frames*fea_vector_length; sample_counter++)	{
				if (sample_counter == 0) {
					ark_access_index = ftell(fout_ark)  - 15;   // fast access index
				}
				if (fread(sample.byte, 4, 1, fin_htk) != 1) {
				    printf("Error reading %s features, quitting!\n", fname_htk_fea_in);
				    return 1;
				}
				endianSwap4(&sample);
				if (fwrite(sample.byte, 4, 1, fout_ark) != 1) {
				    printf("Error writing %s features into arkfile %s, quitting!\n", fname_htk_fea_in, argv[2]);
				    return 1;
				}
			}
			fclose(fin_htk);

			fprintf(fout_scp, "%s %s:%ld\n", fname_htk_fea_in_raw_no_ext, fname_ark_out, ark_access_index);
		}
	}
	fclose(fin_list);      
	fclose(fout_ark);   
	fclose(fout_scp);   
	return 0;
}

/*
 * Copyright (C) 2003, by Keith J. Jones.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the project nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE PROJECT AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE PROJECT OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */


#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <time.h>
#include <math.h>

#ifdef CYGWIN
ssize_t pread( int d, void *buf, size_t nbytes, off_t offset) {
  lseek( d, offset, SEEK_SET );
  read( d, buf, nbytes );
}
#endif

//
/* Backwards ASCII Hex to Integer */
//
unsigned int bah_to_i( char *val, int size ) {
  int total;
  int i;

  total = 0;

  for ( i=0; i < size; i++ ) {
    total += ((unsigned char)val[i] << 8*i);
  }

  return total;
}

//
/* Backwards 8 byte ASCII Hex to time_t */
//
time_t win_time_to_unix( char *val ) {
  unsigned long low, high;
  double dbl;
  time_t total;

  char fourbytes[4]; 

  fourbytes[0] = val[0];
  fourbytes[1] = val[1];
  fourbytes[2] = val[2];
  fourbytes[3] = val[3];

  low = bah_to_i( fourbytes, 4 );

  fourbytes[0] = val[4];
  fourbytes[1] = val[5];
  fourbytes[2] = val[6];
  fourbytes[3] = val[7];

  high = bah_to_i( fourbytes, 4 );

  dbl = ((double)high)*(pow(2,32));
  dbl += (double)(low);

  if ( dbl==0 ) {
    return 0;
  }

  dbl *= 1.0e-7;
  dbl -= 11644473600;

  total = (double)dbl;

  return total;
}

//
/* This function prepares a string for nice output */
//
int printablestring( char *str ) {
  int i;

  i = 0;
  while ( str[i] != '\0' ) {
    if ( (unsigned char)str[i] < 32 || (unsigned char)str[i] > 127 ) {
      str[i] = ' ';
    }
    i++; 
  }
  return 0;
}

//
/* This function prints the usage message */
//
void usage( void ) {
  printf("\nUsage:  rifiuti [options] <filename>\n" );
  printf("\t-d Field Delimiter (TAB by default)\n" );
  printf("\n\n");
}

//
/* MAIN function */
//
int main( int argc, char **argv ) {
  int info2_file;
  char fourbytes[4];
  char chr;
  char delim[10];
  char ascdeltime[26];
  int currrecoff;
  int recordsize;
  int i;
  int opt;
  int res;
  time_t deltime;
  char *record;
  int eof = 0;
  char *filename;
  int index, drive;
  int filesize;
  int year, mon;
  struct tm *deltm;

  if (argc < 2) {
    usage();
    exit( -2 );
  }

  strcpy( delim, "\t" );

  printf("INFO2 File: %s\n\n", argv[argc-1]);
  info2_file = open( argv[argc-1], O_RDONLY, 0 );

  if ( info2_file <= 0 ) { 
    printf("ERROR - The INFO2 file cannot be opened!\n\n");
    usage();
    exit( -3 ); 
  }

  pread( info2_file, fourbytes, 4, 0x0C );
  recordsize = bah_to_i( fourbytes, 4 );

  record = malloc( recordsize );

  while ((opt = getopt( argc, argv, "dt:f:")) != -1) {
    switch(opt) {
      case 't':
        strncpy( delim, optarg, 10 );
        break;

      default:
        usage();
        exit(-1);
    }
  }

  currrecoff = 0x10;

  printf( "INDEX%sDELETED TIME%sDRIVE NUMBER%sPATH%sSIZE\n", delim, delim, delim, delim );

  while (eof == 0) {
    res = pread( info2_file, record, recordsize, currrecoff );
    if (res < recordsize) {
      eof = 1;
    } else {
      filename = record + 0x04;
      index = bah_to_i( record+0x108, 4 );
      drive = bah_to_i( record+0x10C, 4 );

      deltime = win_time_to_unix( record+0x110 );
      deltm = localtime( &deltime );
      year = deltm->tm_year + 1900;
      mon = deltm->tm_mon + 1;
      sprintf( ascdeltime, "%02d/%02d/%02d %02d:%02d:%02d", mon, deltm->tm_mday, year, deltm->tm_hour, deltm->tm_min, deltm->tm_sec );

      filesize = bah_to_i( record+0x118, 4 );

      printf( "%d%s%s%s%d%s%s%s%d\n", index, delim, ascdeltime, delim, drive, delim, filename, delim, filesize );
    }
    currrecoff = currrecoff + recordsize;
  }


  free( record );
  close (info2_file);
}

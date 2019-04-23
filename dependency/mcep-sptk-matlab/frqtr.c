/* ----------------------------------------------------------------- */
/*             The Speech Signal Processing Toolkit (SPTK)           */
/*             developed by SPTK Working Group                       */
/*             http://sp-tk.sourceforge.net/                         */
/* ----------------------------------------------------------------- */
/*                                                                   */
/*  Copyright (c) 1984-2007  Tokyo Institute of Technology           */
/*                           Interdisciplinary Graduate School of    */
/*                           Science and Engineering                 */
/*                                                                   */
/*                1996-2016  Nagoya Institute of Technology          */
/*                           Department of Computer Science          */
/*                                                                   */
/* All rights reserved.                                              */
/*                                                                   */
/* Redistribution and use in source and binary forms, with or        */
/* without modification, are permitted provided that the following   */
/* conditions are met:                                               */
/*                                                                   */
/* - Redistributions of source code must retain the above copyright  */
/*   notice, this list of conditions and the following disclaimer.   */
/* - Redistributions in binary form must reproduce the above         */
/*   copyright notice, this list of conditions and the following     */
/*   disclaimer in the documentation and/or other materials provided */
/*   with the distribution.                                          */
/* - Neither the name of the SPTK working group nor the names of its */
/*   contributors may be used to endorse or promote products derived */
/*   from this software without specific prior written permission.   */
/*                                                                   */
/* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND            */
/* CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,       */
/* INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF          */
/* MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE          */
/* DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS */
/* BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,          */
/* EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED   */
/* TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,     */
/* DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON */
/* ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,   */
/* OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY    */
/* OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE           */
/* POSSIBILITY OF SUCH DAMAGE.                                       */
/* ----------------------------------------------------------------- */

/***************************************************************

    Frequency Transformation for Calculating Coefficients

        void frqtr(c1, m1, c2, m2, a)

        double *c1   : minimum phase sequence
        int m1       : order of minimum phase sequence
        double *c2   : warped sequence
        int m2       : order of warped sequence
        double a     : all-pass constant

***************************************************************/

/******************************************************************
 * Modified to call it from matlab, use mex to compile this function and
 * then call it from matlab using the syntax below,
 * c2 = frqtr(c1, m2, a);
 * the variables follow the definitions above, vectors are column vectors.
 * the return value is also a column vector.
 * It should be noted that this function does not do any input validation, 
 * so use it at your own risk.
 * Guanlong Zhao (gzhao@tamu.edu)
 * Created: 06/09/2017
 * Last Modified: 06/09/2017
 * Revision log:
 *  06/09/2017: function creation, GZ
****************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "mex.h"

char *getmem(const size_t leng, const size_t size)
{
   char *p = NULL;

   if ((p = (char *) calloc(leng, size)) == NULL) {
      fprintf(stderr, "Cannot allocate memory!\n");
      exit(3);
   }
   return (p);
}

double *dgetmem(const int leng)
{
   return ((double *) getmem((size_t) leng, sizeof(double)));
}

void fillz(void *ptr, const size_t size, const int nitem)
{
   long n;
   char *p = ptr;

   n = size * nitem;
   while (n--)
      *p++ = '\0';
}

void movem(void *a, void *b, const size_t size, const int nitem)
{
   long i;
   char *c = a;
   char *d = b;

   i = size * nitem;
   if (c > d)
      while (i--)
         *d++ = *c++;
   else {
      c += i;
      d += i;
      while (i--)
         *--d = *--c;
   }
}


void frqtr(double *c1, int m1, double *c2, int m2, const double a)
{
   int i, j;
   static double *d = NULL, *g;
   static int size;

   if (d == NULL) {
      size = m2;
      d = dgetmem(size + size + 2);
      g = d + size + 1;
   }

   if (m2 > size) {
      free(d);
      size = m2;
      d = dgetmem(size + size + 2);
      g = d + size + 1;
   }

   fillz(g, sizeof(*g), m2 + 1);

   for (i = -m1; i <= 0; i++) {
      if (0 <= m2) {
         d[0] = g[0];
         g[0] = c1[-i];
      }
      for (j = 1; j <= m2; j++)
         g[j] = d[j - 1] + a * ((d[j] = g[j]) - g[j - 1]);
   }

   movem(g, c2, sizeof(*g), m2 + 1);

   return;
}


/* The gateway function */
void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
	/* Check input, 3 */
	if(nrhs != 3) {
		mexErrMsgIdAndTxt("MyToolbox:theq:nrhs",
						  "3 inputs required.");
	}
	
	/* Check output, 1 */
	if(nlhs != 1) {
		mexErrMsgIdAndTxt("MyToolbox:theq:nlhs",
                      "One output required.");
	}

	/* variable declarations here */
	/* inputs */
	double *c1;
	int m2;
	double a;
	
	/* outputs */
	double *c2;
	
	/* code here */
	/* get inputs */
	c1 = mxGetPr(prhs[0]);
	m2 = mxGetScalar(prhs[1]);
	a = mxGetScalar(prhs[2]);
	
	int nrow = mxGetM(prhs[0]);
	
	/* get outputs */
	plhs[0] = mxCreateDoubleMatrix((m2+1), 1, mxREAL);
	c2 = mxGetPr(plhs[0]);
    
    frqtr(c1, nrow, c2, m2, a);
}

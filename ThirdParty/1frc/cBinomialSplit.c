/*Compile the mex file:
 *
 * mex -O cBinomialSplit.c
 *
 *      [out1, out2]=cBinomialSplit(image_in)
 */

#include <stdlib.h>
#include <string.h>
#include "mex.h"
#include <math.h>

#define max(a,b) ( (a) >= (b) ? (a) : (b) )
#define min(a,b) ( (a) < (b) ? (a) : (b) )
#define FLOAT double
#define INT int
#define MLTYPENAME mxDOUBLE_CLASS
#define MLTYPENAME_INT mxINT32_CLASS

#define IA 16807
#define IM 2147483647
#define AM (1.0/IM)
#define IQ 127773
#define IR 2836
#define NTAB 32
#define NDIV (1+(IM-1)/NTAB)
#define EPS 1.2e-7
#define RNMX (1.0-EPS)
#define PI 3.141592654

/* Numerical Recipies code v2*/
float ran1(long *idum)
{
    int j;
    long k;
    static long iy=0;
    static long iv[NTAB];
    float temp;
    
    if (*idum <= 0 || !iy) {
        if (-(*idum) < 1) *idum=1;
        else *idum = -(*idum);
        for (j=NTAB+7;j>=0;j--) {
            k=(*idum)/IQ;
            *idum=IA*(*idum-k*IQ)-IR*k;
            if (*idum < 0) *idum += IM;
            if (j < NTAB) iv[j] = *idum;
        }
        iy=iv[0];
    }
    k=(*idum)/IQ;
    *idum=IA*(*idum-k*IQ)-IR*k;
    if (*idum < 0) *idum += IM;
    j=iy/NDIV;
    iy=iv[j];
    iv[j] = *idum;
    if ((temp=AM*iy) > RNMX) return RNMX;
    else return temp;
}
float gammln(float xx)
{
    double x,y,tmp,ser;
    static double cof[6]={76.18009172947146,-86.50532032941677,
        24.01409824083091,-1.231739572450155,
        0.1208650973866179e-2,-0.5395239384953e-5};
    int j;
    
    y=x=xx;
    tmp=x+5.5;
    tmp -= (x+0.5)*log(tmp);
    ser=1.000000000190015;
    for (j=0;j<=5;j++) ser += cof[j]/++y;
    return -tmp+log(2.5066282746310005*ser/x);
}

int bnldev(float pp, int n, long *idum)
{
    int j;
    static int nold=(-1);
    float am,em,g,angle,p,bnl,sq,t,y;
    static float pold=(-1.0),pc,plog,pclog,en,oldg;
    
    p=(pp <= 0.5 ? pp : 1.0-pp);
    am=n*p;
    if (n < 25) {
        bnl=0.0;
        for (j=1;j<=n;j++)
            if (ran1(idum) < p) ++bnl;
    } else if (am < 1.0) {
        g=exp(-am);
        t=1.0;
        for (j=0;j<=n;j++) {
            t *= ran1(idum);
            if (t < g) break;
        }
        bnl=(j <= n ? j : n);
    } else {
        if (n != nold) {
            en=n;
            oldg=gammln(en+1.0);
            nold=n;
        } if (p != pold) {
            pc=1.0-p;
            plog=log(p);
            pclog=log(pc);
            pold=p;
        }
        sq=sqrt(2.0*am*pc);
        do {
            do {
                angle=PI*ran1(idum);
                y=tan(angle);
                em=sq*y+am;
            } while (em < 0.0 || em >= (en+1.0));
            em=floor(em);
            t=1.2*sq*(1.0+y*y)*exp(oldg-gammln(em+1.0)
                                   -gammln(en-em+1.0)+em*plog+(en-em)*pclog);
        } while (ran1(idum) > t);
        bnl=em;
    }
    if (p != pp) bnl=n-bnl;
    return (int) bnl;
}

void mexFunction(int nlhs, mxArray *plhs[],	int	nrhs, const	mxArray*prhs[])
{
    int dims;
    INT *image;
    INT *out1, *out2;
    INT  value, x, xbis;
    int ii,numel;
    static long idum=1;
    const mwSize *size;
    
    /*input checks*/
    if (nrhs!=1)
        mexErrMsgTxt("Input only one image\n");
    dims = mxGetNumberOfDimensions(prhs[0]);
    if (dims !=2 && dims !=3) {
      mexErrMsgTxt("2D or 3D image expected for now.");
   }
    if (mxGetClassID(prhs[0])!=mxINT32_CLASS)
        mexErrMsgTxt("data must be integer\n");
     if (nlhs != 2) {
        mexErrMsgTxt("Need 2 output arguments");
    }
    
    image =(FLOAT *) mxGetData(prhs[0]);
    /* output generation */
    size = mxGetDimensions(prhs[0]);
    plhs[0] = mxCreateNumericArray(dims, size, MLTYPENAME_INT, mxREAL);
    plhs[1] = mxCreateNumericArray(dims, size, MLTYPENAME_INT, mxREAL);
    out1 = (INT *) mxGetData(plhs[0]);
    out2 = (INT *) mxGetData(plhs[1]);
    
    numel = size[0]*size[1]; 
    if (dims ==3){
        numel = numel*size[2];
    }
            /*try linear indexing */
    for (ii=0; ii< numel-1; ii++){
        value = *(image++);
        x = bnldev(0.5, value, &idum);
        *(out1++) = x;
        *(out2++) = value-x;
        }
    
    return;
};


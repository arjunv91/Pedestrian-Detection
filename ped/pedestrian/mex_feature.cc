#include <string.h>
#include <math.h>
#include <mex.h>
#include <mclmcr.h>
#include <stdio.h>

// tamara's office phone number 631 632 8426

int g_verbosity = 0;

void vprint(const char *s) // wraps printing to control verbosity
{
  if (g_verbosity>0){
    mexPrintf(s);
  }
}

void compute_features(int nr,int nc,int nch, float *ll,
			  int nsamples,mxInt32 *samples,
			  int nlocs, mxInt32 *locs,
			  float *feats)
{

  int nrp = nr+1;
  int ncp = nc+1;
  float *sat = (float *)malloc(sizeof(float)*nrp*ncp);
  if (!sat){ mexErrMsgTxt("Memories... I have none(3).\n"); return; }
  memset(sat,0,sizeof(float)*nrp*ncp);

  for (int ch=0; ch<nch; ch++){
    int base = ch*nr*nc;
    for (int i=1; i<nrp; i++){
      for (int j=1; j<ncp; j++){
	sat[i+j*nrp] = sat[i-1+j*nrp]+sat[i+(j-1)*nrp]-sat[(i-1)+(j-1)*nrp]+ll[(i-1)+(j-1)*nr+base]; 
      }
    }

    // testing code, dangerous...memcpy(feats,sat,sizeof(float)*nrp*ncp)...;

    for (int j=0; j<nsamples; j++){ // loop through sample offsets
      for (int i=0; i<nlocs; i++){  // loop through locations
	//	locs[i,0..1] samples[j,0..3]
          //       x0 = asx(j,1)+px(k)-1-1; y0 = asy(j,1)+py(k)-1;
	  int x0 = locs[i+nlocs]+samples[j+2*nsamples]-1;
	  int x1 = locs[i+nlocs]+samples[j+3*nsamples]-1;
	  int y0 = locs[i]+samples[j]-1;
	  int y1 = locs[i]+samples[j+nsamples]-1;
	  //  	  printf("x0=%d x1=%d y0=%d y1=%d\n",x0,x1,y0,y1);
			  //       x1 = asx(j,3)+px(k)-1-1; y1 = asy(j,2)+py(k)-1;
	  int i00 = y0+x0*nrp;
	  int i01 = y0+x1*nrp;
	  int i10 = y1+x0*nrp;
	  int i11 = y1+x1*nrp;
	  //	  printf("i00=%d i01=%d i10=%d i11=%d\n",i00,i01,i10,i11);
	  //	  printf("sat(i00)=%4.2f sat(i01)=%4.2f sat(i10)=%4.2f sat(i11)=%4.2f\n",
	  //      sat[i00],sat[i01],sat[i10],sat[i11]);
	  feats[i+j*nlocs+ch*nsamples*nlocs ]=(sat[i11]-sat[i10]-sat[i01]+sat[i00])*samples[j+4*nsamples];
      }
    }
  }
  free(sat);
}

void mexFunction (int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{

  int  mlen = 4097;
  char* message = (char *)malloc(sizeof(char)*mlen);
  if (!message){ mexErrMsgTxt("Memories... I have none.\n"); return; }


  //////////////////////
  // Check arguments
  //////////////////////

  int err=0;

    // ll_feats
  if ((!mxIsSingle(prhs[0]))|(mxIsComplex(prhs[0]))){
    err = 1;
    vprint("ll_feat_Stack should be of type (real) single\n");
  }
  const int *sz = NULL;
  int nr  = 0;
  int nc  = 0;
  int nch = 0;

  if (3!=mxGetNumberOfDimensions(prhs[0])){
    if (2!=mxGetNumberOfDimensions(prhs[0])){
      err = 1;
      vprint("ll_feat_stack should be 3 dimensional (or 2...)\n");
    }else{
      sz = mxGetDimensions(prhs[0]);
      nr  = sz[0];
      nc  = sz[1];
      nch = 1;
    }
    
  }else{
    sz = mxGetDimensions(prhs[0]);
    nr  = (int)sz[0];
    nc  = (int)sz[1];
    nch = (int)sz[2];
  }
  float* ll = (float *)mxGetData(prhs[0]);
    snprintf(message,mlen,"ll_feats \t %d x %d x %d\n",
	     nr, nc, nch);
    vprint(message);    
    
    // locations
  if (!mxIsInt32(prhs[1])){
    err = 1;
    vprint("locations should be of type int32\n");
  }
  if (2!=mxGetNumberOfDimensions(prhs[1])){
    err = 1;
    vprint("locations should be 2 dimensional\n");
  }
    int nlocs = mxGetM(prhs[1]);
    int check2 = mxGetN(prhs[1]);

  if (2!=check2){
    err = 1;
    vprint("locations should be n_locations x 2\n");
  }
    mxInt32* locs = (mxInt32 *)mxGetData(prhs[1]);
    snprintf(message,mlen,"locations \t %d x %d\n",
	     nlocs, check2);
    vprint(message);    

//   printf("locs:\n");
//   for (int i=0; i<10; i++){
//     printf("%d ",locs[i]);
//   }
//   printf("\n\n");

    // samples
  if (!mxIsInt32(prhs[2])){
    err = 1;
    vprint("feature_samples should be of type int32\n");
  }
  if (2!=mxGetNumberOfDimensions(prhs[2])){
    err = 1;
    vprint("feature_samples should be 2 dimensional\n");
  }
  int nsamples = mxGetM(prhs[2]);
  int check5 = mxGetN(prhs[2]);
  if (5!=check5){
    err = 1;
    vprint("feature_samples should be num_samples x 5\n");
  }
  mxInt32* samples = (mxInt32 *)mxGetData(prhs[2]);
  snprintf(message,mlen,"feat_samples \t %d x %d\n",
	   nsamples, check5);
  vprint(message);    

//   printf("samples:\n");
//   for (int i=0; i<10; i++){
//     printf("%d ",samples[i]);
//   }
//   printf("\n\n");

  if (err){
    vprint("Usage:\n");
    vprint(" area_features = mex_feature( ll_feat_stack, locations, feature_samples )\n");
    vprint(" \t ll_feat_stack is r x c x #ll_feat_dimensions (single)\n");
    vprint(" \t locations is n x 2  upper left corners (row, col) / row (int32)\n");
    vprint(" \t featues samples is m x 5 offsets from feature to sample (top bottom left right sf) / row (int32)\n");
    vprint(" \t \n");
    vprint(" area_features is n x ( m * #ll_feat_dimensions ) (double)\n");
    vprint("\n");
    return;
  }

  //////////////////////
  // Make Features
  //////////////////////

  // allocate return variable
  plhs[0] = mxCreateNumericMatrix( nlocs, nsamples*nch,mxSINGLE_CLASS, mxREAL );
  if (!plhs[0]){ mexErrMsgTxt("Memories... I have none(2).\n"); return; }
  float *feats = (float *)mxGetData(plhs[0]);

  compute_features( nr, nc, nch, ll, 
		    nsamples, samples, nlocs, 
		    locs, feats);
  free(message);
}



/*

Some useful functions from matrix.h
-----------------------------------

*** for 2d arrays ***

mxArray *mxCreateNumericMatrix(mwSize m, mwSize n, 
  mxClassID classid, mxComplexity ComplexFlag);

to get pointer to beginning of array (double *)
double *mxGetPr(const mxArray *pm);  

Get pointer to character array data
mxChar *mxGetChars(const mxArray *array_ptr);

Get pointer to array data
void *mxGetData(const mxArray *pm);

mxGetProperty returns the value at pa[index].propname
mxArray *mxGetProperty(const mxArray *pa, mwIndex index,
         const char *propname);

mxClassID mxGetClassID(const mxArray *pm);
const char *mxGetClassName(const mxArray *pm);

size_t mxGetM(const mxArray *pm);
size_t mxGetN(const mxArray *pm);


*** for nd array ***

mxArray *mxCreateNumericArray(mwSize ndim, const mwSize *dims, 
         mxClassID classid, mxComplexity ComplexFlag);

mwSize mxGetNumberOfDimensions(const mxArray *pm);

Use mxGetNumberOfDimensions to determine how many dimensions are in
the specified array. To determine how many elements are in each
dimension, call mxGetDimensions.


const mwSize *mxGetDimensions(const mxArray *pm);

The address of the first element in the dimensions array. Each integer
in the dimensions array represents the number of elements in a
particular dimension. The array is not NULL terminated.


*** for strings (in array single byte per char ) ***

int mxGetString(const mxArray *pm, char *str, mwSize strlen);


*** enums ***

typedef enum {
    mxREAL,
    mxCOMPLEX
} mxComplexity;


typedef enum {
	mxUNKNOWN_CLASS = 0,
	mxCELL_CLASS,
	mxSTRUCT_CLASS,
	mxLOGICAL_CLASS,
	mxCHAR_CLASS,
	mxVOID_CLASS,
	mxDOUBLE_CLASS,
	mxSINGLE_CLASS,
	mxINT8_CLASS,
	mxUINT8_CLASS,
	mxINT16_CLASS,
	mxUINT16_CLASS,
	mxINT32_CLASS,
	mxUINT32_CLASS,
	mxINT64_CLASS,
	mxUINT64_CLASS,
	mxFUNCTION_CLASS,
        mxOPAQUE_CLASS,
	mxOBJECT_CLASS
} mxClassID;


*/


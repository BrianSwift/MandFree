//
//  mbc_calc.c
//
//  Copyright © 2016 Brian Swift. All rights reserved.
//

#include <string.h>
#include <TargetConditionals.h>

#include "mbc_calc.h"
#include "mbc_inner_loop.h"
// #include "mbc_inner_loop_s.h"


// extern int mbc_inner_loop_s(double,double,int);
// extern int mbc_inner_loop(double,double,int);

// #define Enable_Marks 1
#ifdef Enable_Marks
extern int cornerMarks;
#endif

int mbc_calc(
             double	realCorner,
             double	imaginaryCorner,
             double	delta,
             int	pixelsWide,
             int	pixelsHigh,
             int	maxIterations,
             
             GLubyte *pixels
             
             ){
   
    /* register */ double c1r,c1i /*,c2r, c2i, tfr,tfi */;
    int bp /* ,ob[513]*/ ;
    
    double a1,a2 /*,size ,delta*/;
    int /* ias,*/ ix,iy;
    // int iSum=0;		// Total iteration count
    
    /* register */ int i,idpt;
    uint64_t v_i;
    
    /*       WRITE(6,520) */
    /*       READ(5,*) A1 */
    // fprintf(f6,"ENTER REAL CORNER\n");
    // fscanf(f5,"%f\n",&a1);
    a1=realCorner;
    
    /*       WRITE(6,522) */
    /*       READ(5,*) A2 */
    // fprintf(f6,"ENTER IMAGINARY CORNER\n");
    // fscanf(f5,"%f\n",&a2);
    a2=imaginaryCorner;
    
    /*       WRITE(6,524)  */
    /*       READ(5,*) SIZE */
    // fprintf(f6,"ENTER WIDTH\n");
    // fscanf(f5,"%f\n",&size);
    //	size=regionWidth;
    
    /*       WRITE(6,530)  */
    /*       READ(5,*) IAS */
    // fprintf(f6,"ENTER NUMBER OF POINTS ON A SIDE\n");
    // fscanf(f5,"%d\n",&ias);
    //    ias=pixelsWide;
    
    /*       WRITE(6,532)  */
    /*       READ(5,* ) IDPT */
    // fprintf(f6,"ENTER MAXIMUM COLOR HEIGHT\n");
    // fscanf(f5,"%d\n",&idpt);
    idpt=maxIterations;
    
    /*       WRITE(6,120) A1,A2,SIZE,IAS,IDPT  */
    // fprintf(f6,"RC=%f IC=%f SIZE=%f PTS/CH=%d %d\n",a1,a2,size,ias,idpt);
    //	fprintf(stderr,"RC=%f IC=%f SIZE=%f PTS/CH=%d %d\n",a1,a2,size,ias,idpt);
    
    /*C      WRITE(7,*) A1,A2,SIZE,IAS,IDPT */
    
    /*       DELTA=SIZE/IAS */
    // delta=size/ias;
    /*       C1=CMPLX(A1,A2) */
    c1r=a1;c1i=a2;
    /*      BP=0 */
    bp=0;

#if 0
    // used for debugging mbc_inner_loop neon incorrect ordering of VFMA operands
    {
        int j;
        static int once=0;
        if(!once){
//            j = mbc_inner_loop_s(-1.95,0.25,idpt);
//            j = mbc_inner_loop(-1.0,0.25,idpt);
            j=mbc_inner_loop_x4(-1.95,0.25,delta,idpt)>>(64-16);
            printf("j = %d expected 4\n",j);
            once=1;
        }
    }
#endif

// Number of 16-bit iteration count values returned by mbc_inner_loop_x4 (currently 2, possibly 4 in future)
#define MBC_INNER_WIDTH 2
    /*       DO 250 IY = 1,IAS */
    for(iy=1;iy<=pixelsHigh;iy++){
        /*       DO 260 IX = 1,IAS */
        //for(ix=1;ix<=pixelsWide;ix++){
        for(ix=1;ix<=pixelsWide;ix+=MBC_INNER_WIDTH){
#if TARGET_OS_IPHONE  && !TARGET_IPHONE_SIMULATOR
            // i = mbs_inner_loop(c1r,c1i,idpt);
            // no assembly code for now
            v_i = mbc_inner_loop_x4(c1r,c1i,delta,idpt);
#else
//            i = mbc_inner_loop(c1r,c1i,idpt);
            v_i = mbc_inner_loop_x4(c1r,c1i,delta,idpt);

#endif

            /**      WRITE I TO MYIO DATA FILE */
            /* 210  BP=BP+1 */
        l210:
            // extract each iteration count
            for (unsigned int count_select=0;count_select<MBC_INNER_WIDTH;count_select++){
                i=0xffff & ( v_i>>(64-(16*(1+count_select))) );
#define bytesPerPixel 4
            {
                GLubyte R,G,B,A;
                if (! ( i > idpt
#ifdef Enable_Marks
                       // Make second and fourth lines black to check resolution
                       ||(cornerMarks&&(iy==2||iy==4))
#endif
                       )) {
                    // Iteration count to color table function
                    R = (i*7)%(idpt-7);	// R
                    G = (i*15)%(idpt-7);	// G
                    B = i*(idpt-5)/(idpt);	// B
                    A = 255 ;
                } else {
                    R = G = B = 3;
                    A = 255 ;
                }
                pixels[bp*bytesPerPixel]  = R ;
                pixels[bp*bytesPerPixel+1]= G ;
                pixels[bp*bytesPerPixel+2]= B ;
                pixels[bp*bytesPerPixel+3]= A ;
            }

            
                bp++;
            }
            
            /*        C1=CMPLX(REAL(C1)+DELTA,AIMAG(C1)) */
            c1r+=delta*MBC_INNER_WIDTH;
            /* 260   CONTINUE */
        }		

        /*       C1=CMPLX(A1,AIMAG(C1)+DELTA) */
        c1r=a1;c1i+=delta;
        /* 250   CONTINUE */
    }
    // fprintf(stderr, "iSum=%d -95016565=%d   ",iSum,iSum-95016565);
    return bp;
    
}


#if 0
void setPixel(int x,int y, GLubyte *pixels, int rowBytes, int components,
              int r, int g, int b){
    pixels[y*rowBytes+x*components]=r;  // R
    pixels[y*rowBytes+x*components+1]=g;  // G
    pixels[y*rowBytes+x*components+2]=b;  // B
}
#endif

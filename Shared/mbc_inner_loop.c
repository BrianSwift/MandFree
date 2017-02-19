//
//  mbc_inner_loop.c
//
//  Copyright © 2016 Brian Swift. All rights reserved.
//

#include "mbc_inner_loop.h"

#if defined(__arm64__)
#include <arm_neon.h>
#endif

// Calculate two adjacent mandelbrot iteration count values
// Values are returned as two 16-bit fields in the upper upper bits of the return value
// On arm64, two values are calculated simultaneously using Neon SIMD operations
uint64_t mbc_inner_loop_x4(double c1r,double c1i,double delta, int idpt) {

    uint64_t a_i,b_i;

    double a_c1r=c1r,a_c1i=c1i;
    double b_c1r=c1r+delta,b_c1i=c1i;

// #if 0
#if defined(__arm64__)
    int i;

    float64x2_t v_t4,v_c1r,v_c1i,v_c2r,v_c2i,v_tfr,v_tfi;
    float64x2_t v_t0,v_t1;
    uint64x2_t v_flag;
    uint64x2_t v_ones;
    uint64x2_t v_i;
    

    v_ones=vdupq_n_u64(1);
    v_i=v_ones+v_ones;  // v_i={2,2}

    v_t4=vdupq_n_f64(4.0);
    
//    v_c1r=vcombine_f64(vdup_n_f64(a_c1r),vdup_n_f64(b_c1r));
    v_c1r=vcombine_f64(vdup_n_f64(b_c1r),vdup_n_f64(a_c1r));  // b_ in lane 0, a_ in lane 1
    v_c1i=vcombine_f64(vdup_n_f64(b_c1i),vdup_n_f64(a_c1i));
    v_c2r=v_c1r;
    v_c2i=v_c1i;
    
// Unroll count
#define UNR 2
    for(i=2;
        i<=idpt ; // idpt ;  // setting this this to 255 constant doesn't improve performance
        i+=UNR){
// #pragma clang loop interleave_count(2)
#pragma clang loop unroll(full)
        for(int j=0;j<UNR;j++){
            v_tfr=v_c2r*v_c2r;
            v_tfi=v_c2i*v_c2i;
            v_t0=v_c2i+v_c2i;       // t0=2.0*c2i
            v_c2i=v_c1i;            // [c2i]=c1i
            v_t1=v_tfr+v_c1r;
            v_tfr=v_tfr+v_tfi;
                    //            v_c2i=vfmaq_f64(v_c2i,v_t0,v_c2r);		// c2i=2.0*c2r*c2i+c1i;
            v_c2i=v_c2i+v_t0*v_c2r;		// c2i=2.0*c2r*c2i+c1i;
#if 0
            v_flag=vcleq_f64(v_tfr,v_t4 );  // expands into 2 set of fcmp/csel and move instructions,
#else
                    //        asm("cmge   %0.2D,%1.2D,%2.2D" :"=w"(v_flag) :"w"(v_t4),"w"(v_tfr));  // also works
            asm("cmge.2D   %0,%1,%2" :"=w"(v_flag) :"w"(v_t4),"w"(v_tfr));
#endif
            v_ones=v_flag&v_ones;
            v_i=v_i+v_ones;
            v_c2r=v_t1-v_tfi;
        }
        if(!( vgetq_lane_u64(v_ones, 1) | vgetq_lane_u64(v_ones, 0))) break;
                    // if (tfr > t4) break;	// if (t2 > 4.0) break;	// tfr ___  __ c2i  __ c2r
    }
    a_i=vgetq_lane_u64(v_i,1);
    b_i=vgetq_lane_u64(v_i,0);
#else
    // For Simulator (non Arm64) two valuse are calculated using scalar code
    a_i=mbc_inner_loop(a_c1r,a_c1i,idpt);
    b_i=mbc_inner_loop(b_c1r,b_c1i,idpt);
#endif
    return
          ( (a_i&0xffff) << (64-1*16) )
        | ( (b_i&0xffff) << (64-2*16) );
}


#if !defined(__arm64__)

// scalar code used in first app store release and by simulator

unsigned int mbc_inner_loop(double c1r,double c1i,int idpt) {
    /*       DO 200 I=1,IDPT */

    register double t4=4.0;
    /*       C2=CMPLX(0,0) */
    //	register double c2r=0,c2i=0;
    register double c2r=c1r,c2i=c1i;
    register double tfi;
    register double tfr;

    int i;

    for(i=2;
        i<=idpt /* idpt */ ;  // setting this this to 255 constant doesn't improve performance
        i++){
        register double t0,t1;
        /*      IF (REAL(C2)**2+AIMAG(C2)**2 .GT. 4.0) GOTO 210 */
        
        // c1r c1i t4
        //  d0  d1 d4	//  d3  d2  d7  d6 d12  d5
        tfr=c2r*c2r;									// tfr
        tfi=c2i*c2i;									// tfr tfi
        t0=c2i+c2i;		// t0=2.0*c2i					// tfr tfi  t0
        c2i=c1i;		// [c2i]=c1i					// tfr tfi  t0 c2i
        t1=tfr+c1r;										// tfr tfi  t0 c2i  t1
        tfr=tfr+tfi;									// tfr tfi  t0 c2i  t1
        // if(tfr+tfi > 4.0) goto l210;
        /*       C2=C2**2+C1 */
        c2i=t0*c2r+c2i;		// c2i=2.0*c2r*c2i+c1i;		// tfr tfi  t0 c2i  t1
        c2r=t1-tfi;			// c2r=tfr-tfi+c1r;			// tfr tfi  __ c2i  t1 c2r
        if (tfr > t4) break;	// if (t2 > 4.0) break;	// tfr ___  __ c2i  __ c2r
        /* 200   CONTINUE */							// ___ ___  __ c2i  __ c2r
    }
    return i;
}
#endif

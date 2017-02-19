//
//  mbc_inner_loop.h
//
//  Copyright © 2016 Brian Swift. All rights reserved.
//

#include <stdint.h>

#ifndef mbc_inner_loop_h
#define mbc_inner_loop_h

unsigned int mbc_inner_loop(double c1r,double c1i,int idpt);
uint64_t mbc_inner_loop_x4(double c1r,double c1i,double delta,int idpt);

#endif /* mbc_inner_loop_h */

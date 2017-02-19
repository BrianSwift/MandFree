//
//  mbc_calc.h
//
//  Copyright © 2016 Brian Swift. All rights reserved.
//

#ifndef mbc_calc_h
#define mbc_calc_h

#ifndef GLubyte
#define GLubyte unsigned char
#endif

#define MBC_MAX_ITER 383

int mbc_calc(
             double	realCorner,
             double	imaginaryCorner,
             double	delta,  /* NOTE: no longer region width */
             int	pixelsWide,
             int	pixelsHigh,
             int	maxIterations,
             
             GLubyte *pixels
             
             );

#endif /* mbc_calc_h */

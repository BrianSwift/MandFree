//
//  TiledMBView.m
//
//  Copyright © 2016 Brian Swift. All rights reserved.
//

#import "TiledMBView.h"
#import <QuartzCore/QuartzCore.h>


@implementation TiledMBView

#define USE_CATiledLayer 1
// When using CATiledLayer, looks like tiles get tossed and re-done when app leaves and enters forgeround
// When not using, then zoom just scales up initial image


// - (id)initWithFrame:(CGRect)frame {
- (id)initWithFrame:(CGRect)frame andScale:(CGFloat)scale{
//    frame.size.width*=2.;
//    frame.size.height*=2;
//    printf("Tiled MB view initWithFrame %f %f %f %f\n",frame.origin.x,frame.origin.y,frame.size.width,frame.size.height);
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
#if USE_CATiledLayer
		CATiledLayer *tiledLayer = (CATiledLayer *)[self layer];
        tiledLayer.levelsOfDetail = 3;  // seems better than 1, should also compare to 2
//		tiledLayer.levelsOfDetailBias = 4;
		// large values getty jittery in 3.1.3
//		tiledLayer.levelsOfDetail = 24;
		tiledLayer.levelsOfDetailBias = 20 ; // No need for this to be larger than log2(maximumZoomScale)
//		tiledLayer.levelsOfDetail = 20;  // 14 smooth until lock on iOS 3.1.3
//		tiledLayer.levelsOfDetailBias = 20;
//		tiledLayer.tileSize = CGSizeMake(512.0, 512.0);
		tiledLayer.tileSize = CGSizeMake(256.0, 256.0);
//        tiledLayer.fadeDuration = 0.0;
        		
#if 0
        // Seems better when this is disabled. Don't see shifts when scaling
		tiledLayer.minificationFilter= kCAFilterTrilinear; // kCAFilterLinear default
		tiledLayer.minificationFilterBias=-1./2.;  // default 0, used when minificationFiler is kCAFilterTrilinear
		tiledLayer.magnificationFilter= kCAFilterTrilinear;  // kCAFilterLinear default
		// kCAFilterTrilinear with minificationFilterBias =1 looks fuzzy and low-rez
		//    with markers on can see tile is scaled up to size of entire screen screen before next LOD start to fade in
		//  =2.0 looks lower rez
		//  =0.5 not so low
		//     but still almost screen size before next fades in
		//  =0.0  about half screen size before fade in
		//  ==-0.5 less than half screen befoe fade in, markers always sharp, I wonder if -Bias means alwasy minimizing
		//       also get a two stage refinement when hitting a new area.  Big tiles rendered, then small
		//  ==-1.0 new tiles start to fade in when tile is about size orig base tile (128x128) <1/3 screen hight
		//    also image gets shimmery when when zooming
		// kCAFilterLinear image changes when zooming in are more noticible
		// turning on markers, it looks like kCAFilterTrilinear cross-fades between different LOD so slow changes are not as noticable
#endif		

#endif
		myScale = scale;

    }
    return self;
}



#if USE_CATiledLayer

// Set the layer's class to be CATiledLayer.
+ (Class)layerClass {
	return [CATiledLayer class];
}
#endif



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
-(void)drawRect:(CGRect)r
{
    // UIView uses the existence of -drawRect: to determine if it should allow its CALayer
    // to be invalidated, which would then lead to the layer creating a backing store and
    // -drawLayer:inContext: being called.
    // By implementing an empty -drawRect: method, we allow UIKit to continue to implement
    // this logic, while doing our real drawing work inside of -drawLayer:inContext:
}




#ifdef Enable_Marks
int cornerMarks=1;
int textMarks=0;
#endif


#include "mbc_calc.h"

-(void)drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
    // The context is appropriately scaled and translated such that you can draw to this context
    // as if you were drawing to the entire layer and the correct content will be rendered.
    // We assume the current CTM will be a non-rotated uniformly scaled
	
	// affine transform, which implies that
    // a == d and b == c == 0
    CGFloat scale = CGContextGetCTM(context).a;
    // While not used here, it may be useful in other situations.
	
    // The clip bounding box indicates the area of the context that
    // is being requested for rendering. While not used here
    // your app may require it to do scaling in other
    // situations.
     CGRect rect = CGContextGetClipBoundingBox(context);
	
    // Set and draw the background color of the entire layer
    // The other option is to set the layer as opaque=NO;
    // eliminate the following two lines of code
    // and set the scroll view background color
//    CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
//    CGContextFillRect(context,self.bounds);

	CGRect b=self.bounds;
	

#if 0
	// to get tileSize, not sure if passed in layer is same as [self layer]
	CATiledLayer *tiledLayer = (CATiledLayer *)[self layer];
	CGFloat tileWidth=tiledLayer.tileSize.width;
	CGFloat tileHeight=tiledLayer.tileSize.height;
#endif
    

	
#if 1
	{
        // draw mandelbrot image to a tile

        // corruption with static buffer now, must not have been multi-threading in past
#if USE_CATiledLayer
        unsigned char *pixels=malloc(4*256*(256+2));
#else
        unsigned char *pixels=malloc(4*1920*(1080+2));
#endif


// 128 always looks blocky when paused, but is fast to re-calc
// 256 always looks smooth when paused, but is slow to re-calc
#define	rowPixels 192
// .75 = 192/256 rowPixels/tileSize = tileToImageSizeFactor
//#define	tileToImageSizeFactor (0.75)
#define	tileToImageSizeFactor (1.0)

//		CGFloat imageWidth = tileWidth * tileToImageSizeFactor;
//		CGFloat imageHeight =tileHeight * tileToImageSizeFactor;
		CGFloat imageWidth = rect.size.width*scale*tileToImageSizeFactor;
		CGFloat imageHeight = rect.size.height*scale*tileToImageSizeFactor;
		
#if 0
        // full set with explicit mbTop
        CGFloat mbLeft = -3.000000;
        CGFloat mbTop = -1.406250;
        CGFloat mbWidth = 5.000000;
#elif 0
        // Zoomed in One level, centered
        CGFloat mbLeft = -1.750000;
        CGFloat mbTop = -0.703125;
        CGFloat mbWidth = 2.500000;
#elif 0
        // new benchmark area
        CGFloat mbLeft = -0.992018;
        CGFloat mbTop = -0.252614;
        CGFloat mbWidth = 0.001221;
#else
		// the full set with mbTop calculated to center on screen
		CGFloat mbLeft = -2.0;
		CGFloat mbWidth = 3.0;
        mbWidth = 5.0;
        mbLeft = -3.0;

		// CGFloat mbTop = -2.5;
		CGFloat mbTop = -0.5*(/* mbHeight = */ mbWidth*b.size.height/b.size.width) ;
#endif


        // Calculate a tile (or screen) worth of image

        // since rect is in screen coordinates, math is converting from screen to mb coordinates

        mbc_calc(
                 // expiremental shift trying to impove multi-levels transision allignment
                 (mbWidth / scale /b.size.width / (tileToImageSizeFactor))+
                 mbLeft+rect.origin.x/b.size.width*mbWidth, // left realCorner

                 (mbWidth / scale /b.size.width / (tileToImageSizeFactor))+
				 mbTop+rect.origin.y/b.size.width*mbWidth, // top imaginaryCorner
//bad			 .002313*(tileWidth  / scale) /b.size.width, // regionWidth
//works			 .002313*(tileWidth  / scale) /b.size.width / (tileWidth*tileToImageSizeFactor), // delta =regionWidth/pixelsWide
				 mbWidth / scale /b.size.width / (tileToImageSizeFactor), // delta =regionWidth/pixelsWide
				 imageWidth, // pixelsWide
				 imageHeight,	// pixelsHigh
				 MBC_MAX_ITER, // maxIterations
				 pixels // pixels bitmap
				 );


		// Didn't see a way of drawing bitmaps other than from an image.
		// So, create a CGBitmap context from pixels,
		//   create CG image from CGBitmap context,
		//   flip CTM so image is displayed top-side-up,
		//	 draw image into tile

		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		CGContextRef bmContext = 
		CGBitmapContextCreate(
							  pixels,		// bitmap
							  imageWidth,	// width
							  imageHeight,	// height
							  8,			// bitsPerComponent
							  4*imageWidth, // bytesPerRow
							  colorSpace,
							  kCGImageAlphaNoneSkipLast
							  );
		
		CGImageRef theCGImage;						   
		
		theCGImage = CGBitmapContextCreateImage(bmContext);
		
#if 0		
		CGRect edgeSubimageArea= CGRectMake(0., 0.,
											rect.size.width*scale*tileToImageSizeFactor,
											rect.size.height*scale*tileToImageSizeFactor);
		CGImageRef edgeSubimage = CGImageCreateWithImageInRect(theCGImage, edgeSubimageArea);
#endif		
		

		// flip and shift CTM so image draws top-side-up
		CGContextSaveGState(context);
		CGContextTranslateCTM(context, 0.0, (rect.size.height+2*rect.origin.y));
		CGContextScaleCTM(context, 1.0, -1.0);

		CGContextDrawImage(context, rect, theCGImage);
//		CGContextDrawImage(context, rect, edgeSubimage);
		
		CGContextRestoreGState(context);

//		CGImageRelease(edgeSubimage);
		
		CGImageRelease(theCGImage);
		CGContextRelease(bmContext);
		CGColorSpaceRelease(colorSpace);
        free(pixels);
		
		
	}
#endif	


	// draw simple box on tile clip bounding box
#if 0
	CGContextSetRGBStrokeColor(context, 1.0, 1.0, 0.0, 1.0);  // yellow
	CGContextSetLineWidth(context, 3.0 / scale);
	CGContextStrokeRect(context, rect);
#endif


#ifdef Enable_Marks
	if (cornerMarks) {
		// draw marks at corners of tiles, inset from the tile boundry 
		float	rectRed=1.0;
		float	rectGreen=1.0;
		float	rectBlue=0.0;
		float	rectAlpha=0.75;
		float	rectLineWidth=1.0;
		float	cornerFractionOfEdge=0.10;
		float	insetFractionOfEdge=4./128.;
		CGRect	r=rect;
		{
			CGContextSetRGBStrokeColor(context, rectRed, rectGreen, rectBlue, rectAlpha);  // yellow
			CGContextSetLineWidth(context, rectLineWidth / scale);
			
			CGContextBeginPath(context);
			
			float cornerVerticalStrokeLength=r.size.height*cornerFractionOfEdge;
			float verticalInset=r.size.height*insetFractionOfEdge;
			float cornerHorizontalStrokeLength=r.size.width*cornerFractionOfEdge;
			float horizontalInset=r.size.width*insetFractionOfEdge;
			
			// upper left corner
			CGContextMoveToPoint(context, r.origin.x+horizontalInset,
								 r.origin.y+cornerVerticalStrokeLength+verticalInset);
			CGContextAddLineToPoint(context, r.origin.x+horizontalInset,
									r.origin.y+verticalInset	);
			CGContextAddLineToPoint(context, r.origin.x+cornerHorizontalStrokeLength+horizontalInset,
									r.origin.y+verticalInset	);
			
			// lower right corner
			CGContextMoveToPoint(context, r.origin.x+r.size.width-horizontalInset,
								 r.origin.y+r.size.height-(cornerVerticalStrokeLength+verticalInset));
			CGContextAddLineToPoint(context, r.origin.x+r.size.width-horizontalInset,
									r.origin.y+r.size.height-verticalInset	);
			CGContextAddLineToPoint(context, r.origin.x+r.size.width-(cornerHorizontalStrokeLength+horizontalInset),
									r.origin.y+r.size.height-verticalInset	);
			
			CGContextStrokePath(context);
			
		}
	}	
	


	// display information about tile coordinates 
	if(textMarks)
	{

		CGContextSetRGBFillColor(context, 0.5, 0.5, 0.5, 0.50); // black

		CGContextSelectFont(context, "Helvetica", 24.0, kCGEncodingMacRoman);
		CGContextSetTextMatrix(context, CGAffineTransformMakeScale(1.0 / scale , -1.0 / scale));

		CGContextSetTextDrawingMode(context, kCGTextFill);

		char st[256];

#if 1
		// clip rect
		snprintf(st,sizeof(st)-1,"%.2f %.2f",rect.origin.x,rect.origin.y);
		CGContextShowTextAtPoint(context, rect.origin.x+10/scale, rect.origin.y+(24+10)/scale, st, strlen(st));
		snprintf(st,sizeof(st)-1,"%.2f %.2f",rect.size.width, rect.size.height);
		CGContextShowTextAtPoint(context, rect.origin.x+10/scale, rect.origin.y+(2*24+10)/scale, st, strlen(st));
#endif
		// CTM Scale
		snprintf(st,sizeof(st)-1,"%.2f %.2f",scale, myScale);
		CGContextShowTextAtPoint(context, rect.origin.x+10/scale, rect.origin.y+(3*24+10)/scale, st, strlen(st));

#if 1
		// bounds
		snprintf(st,sizeof(st)-1,"%.2f %.2f",b.origin.x,b.origin.y);
		CGContextShowTextAtPoint(context, rect.origin.x+10/scale, rect.origin.y+(5*24+10)/scale, st, strlen(st));
		snprintf(st,sizeof(st)-1,"%.2f %.2f",b.size.width, b.size.height);
		CGContextShowTextAtPoint(context, rect.origin.x+10/scale, rect.origin.y+(6*24+10)/scale, st, strlen(st));
#endif		
		
	}
#endif
}



@end

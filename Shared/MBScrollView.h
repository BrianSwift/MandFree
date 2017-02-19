//
//  MBScrollView.h
//
//  Copyright © 2016 Brian Swift. All rights reserved.
//

#import <UIKit/UIKit.h>

@class	TiledMBView;

@interface MBScrollView : UIScrollView <UIScrollViewDelegate> {
	TiledMBView *mbView;
}

@property BOOL zoomIsAnimating;

@end


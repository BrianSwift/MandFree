//
//  MBScrollView.m
//  ViewTesting
//
//  Copyright © 2016 Brian Swift. All rights reserved.
//

#import "MBScrollView.h"
#import "TiledMBView.h"


@implementation MBScrollView


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
		
        self.delegate = self;
//		[self setBackgroundColor:[UIColor grayColor]];
        
        // zooming parameters

//		self.maximumZoomScale = 5.0;
//		self.maximumZoomScale = 65536.*65536;  // movement gets jittery at high scales 
//		self.maximumZoomScale = 1<<14 ;	// smooth iOS 3.1.3
//	this sets limit on users ability to zoom in
//	in iOS 3.1.3 value >= 1<<16 behaves as unlimited
//	in iOS 4.0.2 larger values seem to work
// 4.0.2	1<<17 scroll bars start to become jittery
//			1<<19 corner marks mis-alligned
//			1<<22 locked up iTouch requiring reboot
// tvOS 9.0
//          1<<20 screen goes blank but otherwise smooth
//		self.minimumZoomScale = .25 ;
// tvOS 9.0
//      1<<19 started having problems, after adding help overlay view
        // seems to be related to changing zoom speed
		self.maximumZoomScale = 1<<19 ;  // normally 19 is max
        
		self.minimumZoomScale = 1.0 ;
//        self.minimumZoomScale = 1./(1<<10) ;
        self.zoomScale=self.minimumZoomScale ;
        self.bouncesZoom = YES ; // bouncesZoom does not seem to work

        // Scrolling parameters
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        // self.decelerationRate = UIScrollViewDecelerationRateNormal;
        self.bounces = YES ; // bounces scroll seems to work
        self.alwaysBounceVertical = YES;
        self.alwaysBounceHorizontal = YES;
        self.showsVerticalScrollIndicator = YES;  // these are small and difficult to see because dark, and fade
        self.showsHorizontalScrollIndicator = YES;
        self.indicatorStyle=UIScrollViewIndicatorStyleWhite;
        self.indicatorStyle=UIScrollViewIndicatorStyleDefault;
        
//        self.contentInset=UIEdgeInsetsMake(-512., -512., 512., 512.);
        
        // calls into my code which currently doesn't use andScale:
        mbView = [[TiledMBView alloc] initWithFrame:frame andScale:1.0];
		[self addSubview:mbView];

    }
    return self;
}



// A UIScrollView delegate callback, called when the user starts zooming. 
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return mbView;
}



- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView
                       withView:(UIView *)view
                        atScale:(CGFloat)scale
{
#ifdef NOISY
    printf("scrollViewDidEndZooming atScale %f\n",scale);
#endif
    self.zoomIsAnimating = NO;
}



#if 0
// called when zooming and throught dragging
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    static int counter;
    printf("scrollViewDidScroll=%d\n",counter);
    counter++;
}
#endif



- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    static int counter;
#ifdef NOISY
    printf("scrollViewDidEndDragging=%d\n",counter);
#endif
    static int swipeHelpFinished;
    // swipeHelpFinished needs to be some gloabl with state preservation
    
    if (! swipeHelpFinished ){
//        UIView *zoomHelp=[scrollView.superview viewWithTag:30];
        UIView *swipeHelp=[scrollView.superview viewWithTag:31];
        UIView *pressHelp=[scrollView.superview viewWithTag:32];

        if (! swipeHelp.hidden){
            counter++;
            if (counter>=2){
                // transition from swipeHelp to PressHelp
                [UIView animateWithDuration: 0.5
                              delay: 0.25
                            options: UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             swipeHelp.alpha = 0.0;
                         }
                         completion:^(BOOL finished){
                             swipeHelp.hidden=YES;
                             // Show the Press Help
                             pressHelp.alpha=0.;
                             pressHelp.hidden=NO;
                             // Wait one second and then fade in the view
                             [UIView animateWithDuration:0.5
                                                   delay: 0.0
                                                 options:UIViewAnimationOptionCurveEaseOut
                                              animations:^{
                                                  pressHelp.alpha = 1.0;
                                              }
                                              completion:nil];
                         }];
                swipeHelpFinished=YES;
            }
        }
    }
}



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


@end

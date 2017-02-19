//
//  ViewController.m
//  MandelBits
//
//  Copyright © 2016 Brian Swift. All rights reserved.
//

#import "ViewController.h"
#import	"MBScrollView.h"

#include "mbc_calc.h"

// Enable_Long_Press to perform performance benchmark code
#define Enable_Long_Press

#ifdef Enable_Long_Press
#include <sys/time.h>
static double dtimeofday(){
    struct timeval tv;
    gettimeofday(&tv,NULL);
    return (double)tv.tv_sec+tv.tv_usec/1000000.;
}
#endif

@implementation ViewController



- (void)loadView {
    [super loadView]; // maybe not needed?
    
    // Create our MBScrollView and add it to the view controller.
    CGRect newBounds = self.view.bounds;
    sv = [[MBScrollView alloc] initWithFrame:newBounds];
    
#ifdef NOISY
    printf("bounds %f %f %f %f\n"
           ,self.view.bounds.origin.x
           ,self.view.bounds.origin.y
           ,self.view.bounds.size.width
           ,self.view.bounds.size.height);
#endif
    
#if TARGET_OS_TV
    // This made swipe based scrolling work, got it form forums https://forums.developer.apple.com/message/51021#51021
    UIPanGestureRecognizer *panGesture = [sv panGestureRecognizer];
    [panGesture setAllowedTouchTypes:@[@(UITouchTypeIndirect)]];
#endif

#if 0
    [panGesture setAllowedTouchTypes:@[@(UITouchTypeDirect)]]; // this will cause swipe events to be produced in gestureRecognizer
#endif
#if 0
    [panGesture setAllowedTouchTypes:@[@(UITouchTypeDirect), @(UITouchTypeIndirect)]];
#endif
    sv.clearsContextBeforeDrawing = NO; // not sure if helping performance or not
    sv.backgroundColor = [UIColor blackColor];

    [self.view addSubview: sv];
    [self.view sendSubviewToBack:sv];
}




- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    UIView *myView = (UIView *)self.view;
    
    
    // add a singletap gesture recognizer
    // handleTap: to Zoom In
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGesture.numberOfTapsRequired=1;
    [tapGesture setAllowedTouchTypes:@[@(UITouchTypeDirect), @(UITouchTypeIndirect)]];
    tapGesture.allowedPressTypes = [NSArray array];
    // description of how to get taps came from https://forums.developer.apple.com/message/76948#76948
    //    says UITouchTypeIndirect and allowedPressTypes empty array
    
    
#if TARGET_OS_IOS
    // a 2 finger singletap gesture recognizer to zoom out o iPhone
    UITapGestureRecognizer *tap2Gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePress:)];
    tap2Gesture.numberOfTouchesRequired=2;
    [tap2Gesture setAllowedTouchTypes:@[@(UITouchTypeDirect), @(UITouchTypeIndirect)]];
    tap2Gesture.allowedPressTypes = [NSArray array];
#endif
    

    
#if 0
    // add a doubletap gesture recognizer for zooming out
    // unfortunately, it causes zooming-in to be less responsive since singletap recognizer needs to wait for doubletap timeout failure
    //
    UITapGestureRecognizer *doubletapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubletap:)];
    doubletapGesture.numberOfTapsRequired=2;
    [doubletapGesture setAllowedTouchTypes:@[@(UITouchTypeDirect), @(UITouchTypeIndirect)]];
    doubletapGesture.allowedPressTypes = [NSArray array];
    
    // note: below line is effecting tapGesture
    [tapGesture requireGestureRecognizerToFail:doubletapGesture];
    // above line mentioned at https://forums.developer.apple.com/message/83302#83302
#endif
    
    // add a singlepress gesture recognizer
    // handlePress: to Zoom Out
    UITapGestureRecognizer *pressGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePress:)];
    pressGesture.numberOfTapsRequired=1;
    [pressGesture setAllowedTouchTypes:@[@(UITouchTypeDirect)]];
    pressGesture.allowedPressTypes = @[@(UIPressTypeSelect)];
    
    // not sure how to get Begin event for single press, but can for long press, but it doesn't show up until after longPress timeout
    // probably can't get it because panGesture allows panning while pad is pushed in
    
#ifdef Enable_Long_Press
    // handleLongPress: for performance benchmark
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];  // produces two calls, at start and end, does not recognize first longPress
#endif
#if 0
    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];  // doesn't work, possibly because scene kit has one
#endif
#if 0
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];  // doesn't work, possibly because scene kit has one
#endif
    
#if 0
    UIPanGestureRecognizer *panGesture = [scrollView panGestureRecognizer];
    [panGesture setAllowedTouchTypes:@[@(UITouchTypeDirect), @(UITouchTypeIndirect)]];
#endif
    
    NSMutableArray *gestureRecognizers = [NSMutableArray array];
    [gestureRecognizers addObject:tapGesture];
#if TARGET_OS_IOS
    [gestureRecognizers addObject:tap2Gesture];
#endif

    //    [gestureRecognizers addObject:doubletapGesture];
    [gestureRecognizers addObject:pressGesture];
#ifdef Enable_Long_Press
    [gestureRecognizers addObject:longPressGesture];
#endif
#if 0
    [gestureRecognizers addObject:swipeGesture];
#endif
    //    [gestureRecognizers addObject:panGesture];
    [gestureRecognizers addObjectsFromArray:myView.gestureRecognizers];
    myView.gestureRecognizers = gestureRecognizers;
}



#ifdef Enable_Long_Press
// Performance benchmark and artwork generation
- (void) handleLongPress:(UIGestureRecognizer*)gestureRecognize
{
    
#ifdef NOISY
    printf("handleLongPress %d at %f,%f , state=%ld, zoomScale=%f\n",counter++,p.x,p.y
           ,(long)gestureRecognize.state
           ,sv.zoomScale);
#endif
    
    if( gestureRecognize.state == UIGestureRecognizerStateBegan){
        
        // generat large image for artwork
        printf("producing artwork6\n");
        // since rect is in screen coordinates, math is converting from screen to mb coordinates
#if 1
        // new benchmark area
        CGFloat mbLeft = -0.992018;
        CGFloat mbTop = -0.252614;
        CGFloat mbWidth = 0.001221;
#elif 0
        // the full set
        CGFloat mbLeft = -2.0;
        CGFloat mbWidth = 3.0;
        mbWidth = 5.0;
        mbLeft = -3.0;
        
        // CGFloat mbTop = -2.5;
        CGFloat mbTop = -0.5*(/* mbHeight = */ mbWidth) ;
#endif
#if 0
        int mbc_calc(
                     double	realCorner,
                     double	imaginaryCorner,
                     double	delta,
                     int	pixelsWide,
                     int	pixelsHigh,
                     int	maxIterations,
                     
                     GLubyte *pixels
                     
                     );
#endif
//  ARTSIZE used in generating Mandelbits header artwork, with claissic benchmark area
// #define ARTSIZE 4196
#define ARTSIZE 4096
        unsigned char *pixels=malloc(4*ARTSIZE*(ARTSIZE+2));
        
        double dseconds1,dseconds2;
        dseconds1=dtimeofday();
        
        mbc_calc((double)mbLeft,(double) mbTop, (double)mbWidth/(double)ARTSIZE, ARTSIZE, ARTSIZE, MBC_MAX_ITER, pixels);
        
        dseconds2=dtimeofday();
        // 2.5Ghz i7
        //  debug 14.096788 sec maxIterations as parameter
        //  release 13.470607 sec
        // 6.289105 -Ofast -funroll-loops no #pragma
        // tv
        //  debug 42.054432 sec maxIterations as parameter
        // debug 41.850551
        // release 16.679323
        // release 16.578979 variable max iter
        // 16.678444 fixed #pragma unroll did no unrolling
        // 16.675902 fixed #pragma unroll(4) did no unrolling, maybe because of branch out
        // 20.718618 new code forced 255 trips no unroll
        // 20.733670 " #pragma unroll(4)  [clang 3.8]
        // 20.724918 " #pragma clang loop unroll(full)  , still no unrolling  [clang 3.7]
        // 20.733681 " #pragma clang loop interleave_count(2)  [clang 3.7]
        // 15.680847 #pragma clang loop unroll(full) and build option -funroll-loops
        // 12.231175 " -Ofast -funroll-loops
        // 12.479629 no pragma, non-forced-255 code, but with -Ofast -funroll-loops
        // 12.548696 no pragma, maxiter 255 not var, but with -Ofast -funroll-loops

        // 15.239804 " -Ofast not-release" using partial neon intrinsics
        // 15.283652 -Ofast release using partial neon intrinsics
        
        
        // 8.296529 mbc_inner_loop_x4 UNR 1 count_R/G/B 1949065045 1475184611 2011120753
        // 7.955191 mbc_inner_loop_x4 UNR 2 count_R/G/B 1949065045 1475184611 2011120753
        // 7.824327 mbc_inner_loop_x4 UNR 4 count_R/G/B 1949065045 1475184611 2011120753
        // 7.806374 mbc_inner_loop_x4 UNR 4 count_R/G/B 1949065045 1475184611 2011120753
        // 7.784488 mbc_inner_loop_x4 UNR 4 count_R/G/B 1949065045 1475184611 2011120753  idpt var not constant 255
        // 7.850053 mbc_inner_loop_x4 UNR 4 count_R/G/B 1942806946 1495411757 2080398634 idpt 511, shows issue of benchmark area not having enough high iteration count values
        // 8.026492 mbc_inner_loop_x4 UNR 4 count_R/G/B 1959135118 1499184114 -2137497340  idpt 2048
 

        int count_R=0,count_G=0,count_B=0;
        {   int i;
            for(i=0;i<ARTSIZE*ARTSIZE;i++){
                count_R+=pixels[i*4];
                count_G+=pixels[i*4+1];
                count_B+=pixels[i*4+2];
            }
            // i7 debug   count_R/G/B 1949122075 1475219557 2011168055
            // i7 release count_R/G/B 1949122075 1475219557 2011168055
            // tv debug   count_R/G/B 1949121085 1475221613 2011170789

            // tv release count_R/G/B 1949118530 1475217049 2011168302 no -Ofast    15.839082 sec
            // tv release count_R/G/B 1949121085 1475221613 2011170789  -Ofast fmadd  12.035521 sec
            // tv release count_R/G/B 1949121085 1475221613 2011170789 simple assembly 11.964016 sec
            //            from clang -S -Ofast -arch arm64 -Rpass='.*' -Rpass-missed='.*' -Rpass-analysis='.*'  mbc_inner_loop_s.c
            //      note had to replace line with ".tvos_version_min 9, 0"
            // tv release count_R/G/B 1949121085 1475221613 2011170789 11.969258 sec "b.gt LBB0_5" moved 1 instruction down
            //            count_R/G/B 1949121085 1475221613 2011170789 11.946290 sec "b.gt LBB0_5" moved 3 instructions down

            // New benchmark area
            //    mbLeft mbTop mbWidth -0.992018 -0.252614 0.001221
            //    pixelsWide high maxIterations 4096 4096 383
            // i7 scalar release  15.989404 sec count_R/G/B 1075266575 1205481504 978189441
            // tv neon   release  21.514227 sec count_R/G/B 1075267102 1205482094 978190428  UNR 4
            // tv neon   release  21.365389 sec count_R/G/B 1075267102 1205482094 978190428  UNR 4 after PDO
            // tv neon            21.223685 sec count_R/G/B 1075267102 1205482094 978190428  UNR 8
            // tv neon            21.917089 sec count_R/G/B 1075267102 1205482094 978190428  UNR 1
            // tv neon            21.648357                                                  UNR 32
            // tv scalar          44.925518 sec count_R/G/B 1075267102 1205482094 978190428  clang unrolled 2
            // tv neon            21.495653 sec count_R/G/B 1075267102 1205482094 978190428  UNR 2
            // tv neon            21.610043 sec count_R/G/B 1075267102 1205482094 978190428  UNR 2 vcleq_f64 instead of cmge.2D

            

        }
        
#define ART_FILE "/var/tmp/mbimage.data"
        printf("mbc_calc time =%f sec\n mbLeft mbTop mbWidth %f %f %f\n pixelsWide high maxIterations %d %d %d\n"
               "count_R/G/B %d %d %d\n"
               "ART_FILE = %s\n"
               ,dseconds2-dseconds1
               ,mbLeft, mbTop, mbWidth // (double)mbWidth/(double)ARTSIZE
               ,ARTSIZE,ARTSIZE,MBC_MAX_ITER
               ,count_R,count_G,count_B
               ,ART_FILE
               );
        
        {
            int FD;
            if(-1==(FD=open(ART_FILE,O_CREAT|O_TRUNC|O_WRONLY,0666))){
                perror("open " ART_FILE);
            }
            printf("FD=%d\n",FD);
            if(-1==write(FD,pixels,ARTSIZE*ARTSIZE*4)){
                perror("write" ART_FILE);
            };
            close(FD);
        }
        free(pixels);
        printf("artwork done\n");
    }
    
}
#endif



#if 0
// pan handled by scroll view controller
- (void) handlePan:(UIGestureRecognizer*)gestureRecognize
{
    CGPoint p = [gestureRecognize locationInView:sv];
    static int counter;
    printf("handlePan %d at %f,%f\n",counter++,p.x,p.y);
    
}
#endif


#if 0
// Don't get Swipe if Pan enabled

- (void) handleSwipe:(UIGestureRecognizer*)gestureRecognize
{
    CGPoint p = [gestureRecognize locationInView:sv];
    static int counter;
    printf("handleSwipe %d at %f,%f\n",counter++,p.x,p.y);
    
}
#endif



#if 0

- (void) handleDoubletap:(UIGestureRecognizer*)gestureRecognize
{
    CGPoint p = [gestureRecognize locationInView:sv];
    // MBScrollView *sv = (MBScrollView *)sv;
    static int counter;
    printf("handleDoubletap %d at %f,%f , state=%ld, zoomScale=%f\n",counter++,p.x,p.y
           ,(long)gestureRecognize.state
           ,sv.zoomScale);
    [sv setZoomScale: sv.zoomScale*0.5 animated:YES];
}
#endif




// Press to Zoom Out

- (void) handlePress:(UIGestureRecognizer*)gestureRecognize
{
    // MBScrollView *sv = (MBScrollView *)self.view;
    static int counter;
#ifdef NOISY
    CGPoint p = [gestureRecognize locationInView:sv];
    printf("handlePress %d at %f,%f , state=%ld, zoomScale=%f\n",counter,p.x,p.y
           ,(long)gestureRecognize.state
           ,sv.zoomScale);
#endif
    if (! sv.zoomIsAnimating ) {
        if (sv.zoomScale == sv.minimumZoomScale) {
            // Maybe Give user feedback that they are at Minimum Zoom
            ; //             [sv setZoomScale: sv.zoomScale*0.5 animated:YES]; // probably kill this line since it doesn't produce bounce
            
        } else {
            // This initiates zoom out by factor of 2
            [sv setZoomScale: sv.zoomScale*0.5 animated:YES];
            //    [self updateZoomSpeed];
            sv.zoomIsAnimating = YES; // crappy coding
        }
    } else {
#ifdef NOISY
        printf("ZOOM SKIPED OUT\n");
#endif
    }
    
    static int pressHelpFinished;
    // swipeHelpFinished needs to be some gloabl with state preservation
    
    if (! pressHelpFinished ){
        //   UIView *zoomHelp=[scrollView.superview viewWithTag:30];
        //   UIView *swipeHelp=[sv.superview viewWithTag:31];
        UIView *pressHelp=[sv.superview viewWithTag:32];
        
        if (! pressHelp.hidden){
            counter++;
            if (counter>=1){
                // transition from swipeHelp to PressHelp
                [UIView animateWithDuration: 0.5
                                      delay: 0.25
                                    options: UIViewAnimationOptionCurveEaseIn
                                 animations:^{
                                     pressHelp.alpha = 0.0;
                                 }
                                 completion:^(BOOL finished){
                                     pressHelp.hidden=YES;
#if 0
                                     // Show the Next Help
                                     nextHelp.alpha=0.;
                                     nextHelp.hidden=NO;
                                     // Wait one second and then fade in the view
                                     [UIView animateWithDuration:0.5
                                                           delay: 0.0
                                                         options:UIViewAnimationOptionCurveEaseOut
                                                      animations:^{
                                                          nextHelp.alpha = 1.0;
                                                      }
                                                      completion:nil];
#endif
                                 }];
                pressHelpFinished=YES;
            }
        }
    }
}

double zoomSpeed(double maximumZoomScale, double zoomScale)
{
    return 0;
}

#define USE_CATiledLayer 1


// updateZoomSpeed not used
//   expirement in slowing zoom speed to give user feedback they are approaching zoom maximumZoomScale
#if 0
- (void) updateZoomSpeed
{
    // MBScrollView *sv = (MBScrollView *)self.view;
#if USE_CATiledLayer
    CATiledLayer *tiledLayer = (CATiledLayer *)[sv layer];
#endif
    
    int zoomLevel = log2(sv.maximumZoomScale / sv.zoomScale) ;
    // when zoomScale == maximumZoomScale => zoomLevel == 0 , already at max there won't be any zooming here, since bounce doesn't work, so 0'th element of speeds not relevant
    double zoomSpeeds[]={0.1, 0.1, 0.25, 0.5};
#ifdef NOISY
#if USE_CATiledLayer
    printf("entry zoomLevel=%d new layer speed=%f\n",zoomLevel,tiledLayer.speed);
#else
    printf("entry zoomLevel=%d new layer speed=%f\n",zoomLevel,sv.layer.speed);
#endif
#endif
    if(zoomLevel < sizeof(zoomSpeeds)/sizeof(zoomSpeeds[0])){
#if USE_CATiledLayer
        tiledLayer.speed=zoomSpeeds[zoomLevel];
#else
        sv.layer.speed=zoomSpeeds[zoomLevel];
#endif
    } else {
#if USE_CATiledLayer
        tiledLayer.speed=1.0;
#else
        sv.layer.speed=1.0;
#endif
    }
}
#endif

// Tap to Zoom In
- (void) handleTap:(UIGestureRecognizer*)gestureRecognize
{
    static int counter;
    counter++;
    if(counter==2){
        // Remove tap help
        [UIView animateWithDuration: 0.5
                              delay: 0.25
                            options: UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.ZoomInHelp.alpha = 0.0;
                         }
                         completion:^(BOOL finished){
                             self.ZoomInHelp.hidden=YES;
                             // Show the Swipe Help
                             self.SwipeHelp.alpha=0.;
                             self.SwipeHelp.hidden=NO;
                             // Wait one second and then fade in the view
                             [UIView animateWithDuration:0.5
                                                   delay: 0.0
                                                 options:UIViewAnimationOptionCurveEaseOut
                                              animations:^{
                                                  self.SwipeHelp.alpha = 1.0;
                                              }
                                              completion:nil];
                         }];
        
        
    }
    //    CATiledLayer *tiledLayer = (CATiledLayer *)[sv layer];
    
    //    [self updateZoomSpeed];
    if (! sv.zoomIsAnimating) {
        
        if (sv.zoomScale == sv.maximumZoomScale){
            // Give user feedback that maximum zoom reached
#ifdef NOISY
            printf("at maximumZoomScale\n");
#endif
            [sv setZoomScale: sv.zoomScale*2.0 animated:YES]; /* zoom bounce not working */
            /* setting to smaller increments over max (eg *1.04 and *1.01) doesn't help */
            if (self.MaxZoomLabel.hidden){
                self.MaxZoomLabel.alpha=0.;
                self.MaxZoomLabel.hidden=NO;
                [UIView animateWithDuration: 0.5
                                      delay: 0.0
                                    options: UIViewAnimationOptionCurveEaseInOut
                                 animations:^{
                                     self.MaxZoomLabel.alpha = 1.0;
                                 }
                                 completion:^(BOOL finished){
                                     // Fade out after showing for a bit
                                     // Wait one second and then fade in the view
                                     [UIView animateWithDuration:0.5
                                                           delay: 1.0
                                                         options:UIViewAnimationOptionCurveEaseInOut
                                                      animations:^{
                                                          self.MaxZoomLabel.alpha = 0.0;
                                                      }
                                                      completion:^(BOOL finished){
                                                          self.MaxZoomLabel.hidden=YES;
                                                      }];
                                 }];
            }
        } else {
            // This initiates zoom in by factor of 2
            [sv setZoomScale: sv.zoomScale*2.0 animated:YES];
            sv.zoomIsAnimating = YES; // crappy coding
        }
        //    [self updateZoomSpeed];
    } else {
#ifdef NOISY
        printf("ZOOM SKIPED IN\n");
#endif
    }
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end



//
//  ViewController.h
//  MandelBits
//

//  Copyright © 2016 Brian Swift. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBScrollView.h"

@interface ViewController : UIViewController {
    MBScrollView *sv;
}

@property (weak, nonatomic) IBOutlet UILabel *ZoomInHelp;

@property (weak, nonatomic) IBOutlet UILabel *SwipeHelp;

@property (weak, nonatomic) IBOutlet UILabel *ZoomOutHelp;

@property (weak, nonatomic) IBOutlet UILabel *MaxZoomLabel;

@end

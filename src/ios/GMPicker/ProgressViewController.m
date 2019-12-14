//
//  ProgressViewController.m
//  BZTestPicker
//
//  Created by DevMaster on 12/10/19.
//  Copyright © 2019 DevMaster. All rights reserved.
//

#import "ProgressViewController.h"
#import "GMImagePickerController.h"
//#import <UIKit/UIKit.h>


@interface ProgressViewController ()
 
@end

@implementation ProgressViewController

- (id)init
{
    if (self = [super init]) {
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInt:UIDeviceOrientationPortrait] forKey:@"orientation"];
        self.preferredContentSize = kPopoverContentSize;
        
        CGRect frame;
        float realWidth;
        float realHeight;
//        NSLog(@"Screen Size %f", [[UIScreen mainScreen] bounds].size.width);
        if ([[UIApplication sharedApplication] statusBarOrientation] == UIDeviceOrientationLandscapeLeft || [[UIApplication sharedApplication] statusBarOrientation] == UIDeviceOrientationLandscapeRight) {
            realWidth = [[UIScreen mainScreen] bounds].size.width < kPopoverContentSize.height ? [[UIScreen mainScreen] bounds].size.width : kPopoverContentSize.height;
            realHeight = [[UIScreen mainScreen] bounds].size.height < kPopoverContentSize.width ? [[UIScreen mainScreen] bounds].size.height : kPopoverContentSize.width;
            frame = CGRectMake((realWidth/2 - 100), (realHeight/2 - 100), 200, 200);
        }
        else {
            realWidth = [[UIScreen mainScreen] bounds].size.width < kPopoverContentSize.width ? [[UIScreen mainScreen] bounds].size.width : kPopoverContentSize.width;
            realHeight = [[UIScreen mainScreen] bounds].size.height < kPopoverContentSize.height ? [[UIScreen mainScreen] bounds].size.height : kPopoverContentSize.height;
            frame = CGRectMake((realWidth/2 - 100), (realHeight/2 - 100), 200, 200);
            
        }
            
//        UIProgressView *progressView;
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.progressTintColor = [UIColor colorWithRed:187.0/255 green:160.0/255 blue:209.0/255 alpha:1.0];
        
        [[_progressView layer]setFrame:frame];
        [[_progressView layer]setBorderColor:[UIColor redColor].CGColor];
        _progressView.trackTintColor = [UIColor clearColor];
        [_progressView setProgress:(float)(50/100) animated:YES];  ///15

        [[_progressView layer]setCornerRadius:_progressView.frame.size.width / 2];
        [[_progressView layer]setBorderWidth:10];
        [[_progressView layer]setMasksToBounds:TRUE];
        _progressView.clipsToBounds = YES;
        
        _progressLabel = [[UILabel alloc] initWithFrame:CGRectMake((realWidth-200)/2, realHeight/2-150, 200, 40.0)];
        _progressLabel.font = [UIFont boldSystemFontOfSize:24.0];
        _progressLabel.text = @"0%";
        _progressLabel.backgroundColor = [UIColor clearColor];
        _progressLabel.textColor = [UIColor blueColor];
        _progressLabel.textAlignment = NSTextAlignmentCenter ;
        _progressLabel.alpha = 0.8;
        
        _current_value = 0.0;
        _new_to_value = 0.0;
        _IsAnimationInProgress = NO;
        
        
//        [self.view addSubview:_progressView];
        [self.view addSubview:_progressLabel];
    }
    
    return self;
}

//- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
//    return UIInterfaceOrientationMaskPortrait;
//}

-(BOOL) shouldAutorotate{ return YES; }

-(UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    NSNumber *value = [[NSNumber alloc] initWithFloat:0.9];
//    [self setProgress:value];
}

-(void)UpdateLabelsWithValue:(NSString*)value
{
    _progressLabel.text = value;
}

-(void)setProgressValue:(float)to_value withAnimationTime:(float)animation_time
{
    float timer = 0;
    
    float step = 0.1;
    
    float value_step = (to_value-self.current_value)*step/animation_time;
    int final_value = self.current_value*100;
    
    while (timer<animation_time-step) {
        final_value += floor(value_step*100);
        [self performSelector:@selector(UpdateLabelsWithValue:) withObject:[NSString stringWithFormat:@"%i%%", final_value] afterDelay:timer];
        timer += step;
    }
    
    [self performSelector:@selector(UpdateLabelsWithValue:) withObject:[NSString stringWithFormat:@"%.0f%%", to_value*100] afterDelay:animation_time];
}

- (void)setProgress:(NSNumber*)value{
    
    float to_value = [value floatValue];
    
    if (to_value<=self.current_value)
        return;
    else if (to_value>1.0)
        to_value = 1.0;
    
    if (_IsAnimationInProgress)
    {
        _new_to_value = to_value;
        return;
    }
    
    _IsAnimationInProgress = YES;
    
    float animation_time = to_value-self.current_value;
    
    [self performSelector:@selector(SetAnimationDone) withObject:Nil afterDelay:animation_time];
    
    if (to_value == 1.0 && self.delegate && [self.delegate respondsToSelector:@selector(didFinishAnimation:)])
        [self.delegate performSelector:@selector(didFinishAnimation:) withObject:self afterDelay:animation_time];
    
    [self setProgressValue:to_value withAnimationTime:animation_time];
    
    float start_angle = 2*M_PI*self.current_value-M_PI_2;
    float end_angle = 2*M_PI*to_value-M_PI_2;
    
    float radius = 75.0;
    
    CAShapeLayer *circle = [CAShapeLayer layer];

    // Make a circular shape
    
    CGRect frame;
    float realWidth;
    float realHeight;
//        NSLog(@"Screen Size %f", [[UIScreen mainScreen] bounds].size.width);
    if ([[UIApplication sharedApplication] statusBarOrientation] == UIDeviceOrientationLandscapeLeft || [[UIApplication sharedApplication] statusBarOrientation] == UIDeviceOrientationLandscapeRight) {
        realWidth = [[UIScreen mainScreen] bounds].size.width < kPopoverContentSize.height ? [[UIScreen mainScreen] bounds].size.width : kPopoverContentSize.height;
        realHeight = [[UIScreen mainScreen] bounds].size.height < kPopoverContentSize.width ? [[UIScreen mainScreen] bounds].size.height : kPopoverContentSize.width;
        frame = CGRectMake((realWidth/2 - 100), (realHeight/2 - 100), 200, 200);
    }
    else {
        realWidth = [[UIScreen mainScreen] bounds].size.width < kPopoverContentSize.width ? [[UIScreen mainScreen] bounds].size.width : kPopoverContentSize.width;
        realHeight = [[UIScreen mainScreen] bounds].size.height < kPopoverContentSize.height ? [[UIScreen mainScreen] bounds].size.height : kPopoverContentSize.height;
        frame = CGRectMake((realWidth/2 - 100), (realHeight/2 - 100), 200, 200);
        
    }
    
    circle.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(realWidth/2,realHeight/2)
                                                 radius:radius startAngle:start_angle endAngle:end_angle clockwise:YES].CGPath;
    
    // Configure the apperence of the circle
    circle.fillColor = [UIColor clearColor].CGColor;
    circle.strokeColor = [UIColor blueColor].CGColor;
    circle.lineWidth = 8;
    
    // Add to parent layer
    [self.view.layer addSublayer:circle];
    
    // Configure animation
    CABasicAnimation *drawAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    
    drawAnimation.duration            = animation_time;
    drawAnimation.repeatCount         = 0.0;  // Animate only once..
    drawAnimation.removedOnCompletion = NO;   // Remain stroked after the animation..
    
    // Animate from no part of the stroke being drawn to the entire stroke being drawn
    drawAnimation.fromValue = [NSNumber numberWithFloat:0.0];
    drawAnimation.toValue   = [NSNumber numberWithFloat:1.0];
    
    // Experiment with timing to get the appearence to look the way you want
    drawAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    
    // Add the animation to the circle
    [circle addAnimation:drawAnimation forKey:@"drawCircleAnimation"];
    self.current_value = to_value;
}

-(void)SetAnimationDone
{
    _IsAnimationInProgress = NO;
    if (_new_to_value>_current_value)
        [self setProgress:[NSNumber numberWithFloat:_new_to_value]];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

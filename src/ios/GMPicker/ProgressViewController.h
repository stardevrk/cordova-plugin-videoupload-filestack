//
//  ProgressViewController.h
//  BZTestPicker
//
//  Created by DevMaster on 12/10/19.
//  Copyright © 2019 DevMaster. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ProgressViewControllerDelegate;

@interface ProgressViewController : UIViewController

@property (nonatomic, strong) UIProgressView *progressView;

@property id delegate;
@property float current_value;
@property float new_to_value;

@property BOOL IsAnimationInProgress;

@property (nonatomic, strong) UILabel *progressLabel;
- (void)setProgress:(NSNumber*)value;
@end

@protocol ProgressViewControllerDelegate <NSObject>
- (void)didFinishAnimation:(ProgressViewController*)progressViewController;
@end

NS_ASSUME_NONNULL_END

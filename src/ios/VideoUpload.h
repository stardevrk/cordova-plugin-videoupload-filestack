#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

#import "GMImagePickerController.h"

@interface VideoUpload : CDVPlugin <GMImagePickerControllerDelegate>

@property(nonatomic, copy) NSString* actionCallbackId;

@property(nonatomic, copy) GMImagePickerController* picker;

- (void)init:(CDVInvokedUrlCommand*)command;

- (void)startUpload:(CDVInvokedUrlCommand*)command;

@end

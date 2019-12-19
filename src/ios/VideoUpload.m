#import "VideoUpload.h"
#import <UIKit/UIKit.h>

@implementation VideoUpload
@synthesize actionCallbackId;


- (void)init:(CDVInvokedUrlCommand*)command {
     if (!_picker){
         _picker = [[GMImagePickerController alloc] init];
     }
    NSString *key = [command.arguments objectAtIndex:0];
    NSString *secret = [command.arguments objectAtIndex:1];
    NSString *region = [command.arguments objectAtIndex:2];
    NSString *container = [command.arguments objectAtIndex:3];
    NSString *path = [command.arguments objectAtIndex:4];
    [_picker setupFilestack:key secret:secret region:region bucket:container folder:path];
    _picker.delegate = self;
    _picker.title = @"Albums";
    _picker.customDoneButtonTitle = @"Finished";
    _picker.customCancelButtonTitle = @"Cancel";
    _picker.customNavigationBarPrompt = @"";
    
    _picker.colsInPortrait = 3;
    _picker.colsInLandscape = 5;
    _picker.minimumInteritemSpacing = 2.0;
    _picker.modalPresentationStyle = UIModalPresentationPopover;
     self.actionCallbackId = command.callbackId;
     [self.commandDelegate runInBackground:^{
         CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
         [self.commandDelegate sendPluginResult:result callbackId:self.actionCallbackId];
     }];
}

- (void)startUpload:(CDVInvokedUrlCommand*)command {
    self.actionCallbackId = command.callbackId;
           
    [self.commandDelegate runInBackground:^{
        dispatch_async(dispatch_get_main_queue(), ^{
          [self.viewController presentViewController:self.picker animated:YES completion:nil];
        });
        return;
    }];
  
}

 #pragma mark - GMImagePickerControllerDelegate

 - (void)assetsPickerController:(GMImagePickerController *)picker didFinishUpload:(NSMutableDictionary *)result
 {
     [self.viewController dismissViewControllerAnimated:YES completion:nil];
     NSString *Status = [result objectForKey:@"Status"] ? [result objectForKey:@"Status"] : [[NSString alloc] init];
     
     
     if (![Status isEqualToString:@"Stored"]) {
         NSLog(@"Upload was failed.");
         [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"cancelled"] callbackId:self.actionCallbackId];
         return;
     }
     
     
     NSLog(@"Upload completed.");
     [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result] callbackId:self.actionCallbackId];
     
 }

 //Optional implementation:
 -(void)assetsPickerControllerDidCancel:(GMImagePickerController *)picker
 {
     NSLog(@"User pressed cancel button");
     [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"cancelled"] callbackId:self.actionCallbackId];
 }

 @end

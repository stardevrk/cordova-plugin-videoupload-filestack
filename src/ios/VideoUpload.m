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

 - (void)assetsPickerController:(GMImagePickerController *)picker didFinishUpload:(NSString *)downloadURL
 {
     [self.viewController dismissViewControllerAnimated:YES completion:nil];
     NSLog(@"Result Download URL == %@", downloadURL);
     if (downloadURL.length == 0) {
         NSLog(@"Upload was failed.");
         [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"cancelled"] callbackId:self.actionCallbackId];
         return;
     }
     
     NSLog(@"Upload completed.");
     [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:downloadURL] callbackId:self.actionCallbackId];
     
 }

 //Optional implementation:
 -(void)assetsPickerControllerDidCancel:(GMImagePickerController *)picker
 {
     NSLog(@"User pressed cancel button");
     [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"cancelled"] callbackId:self.actionCallbackId];
 }

 @end

// #pragma mark - FSPickerDelegate Methods
//
//- (void)fsPicker:(FSPickerController *)picker didFinishPickingMediaWithBlobs:(NSArray<FSBlob *> *)blobs {
//    NSLog(@"FILES CHOSEN: %@", blobs);
//    [self.viewController dismissViewControllerAnimated:YES completion:nil];
//
//    if (blobs.count == 0) {
//        NSLog(@"Nothing was picked.");
//        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"cancelled"] callbackId:self.actionCallbackId];
//        return;
//    }
//
//    NSMutableArray* files = [[NSMutableArray alloc] init];
//    for (FSBlob *info in blobs) {
//        NSMutableDictionary* file = [NSMutableDictionary dictionaryWithCapacity:7];
//        [file setObject: (!info.container || [info.container isEqual:[NSNull null]] ? [NSNull null]: info.container) forKey:@"container"];
//        [file setObject: (!info.url || [info.url isEqual:[NSNull null]] ? [NSNull null]: info.url) forKey:@"url"];
//        [file setObject: (!info.fileName || [info.fileName isEqual:[NSNull null]] ? [NSNull null]: info.fileName) forKey:@"filename"];
//        [file setObject: (!info.key || [info.key isEqual:[NSNull null]] ? [NSNull null]: info.key) forKey:@"key"];
//        [file setObject: (!info.mimeType || [info.mimeType isEqual:[NSNull null]] ? [NSNull null]: info.mimeType) forKey:@"mimetype"];
//        [file setObject: [NSNull null] forKey:@"localPath"];
//        [file setObject: [NSNumber numberWithInteger:info.size] forKey:@"size"];
//
//        [files addObject:file];
//    }
//    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:files] callbackId:self.actionCallbackId];
//}
//
// - (void)fsPickerDidCancel:(FSPickerController *)picker {
//     NSLog(@"FilePicker Cancelled");
//     [self.viewController dismissViewControllerAnimated:YES completion:nil];
//     [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"cancelled"] callbackId:self.actionCallbackId];
// }
//@end

//
//  GMImagePickerController.m
//  GMPhotoPicker
//
//  Created by Guillermo Muntaner Perelló on 19/09/14.
//  Copyright (c) 2014 Guillermo Muntaner Perelló. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import "GMImagePickerController.h"
#import "GMAlbumsViewController.h"
#import "ProgressViewController.h"

@import Photos;

@interface GMImagePickerController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (strong) ProgressViewController *progressController;
@property (strong) GMAlbumsViewController *albumsController;
@property (strong) FSClient *client;
@property (strong) NSURL *toBeUploaded;
@property (strong) NSString *resultURL;
@property (strong) NSString *apiKey;
@property (strong) NSString *appSecret;
@property (strong) FSUploadOptions *uploadOptions;


@end

@implementation GMImagePickerController

- (id)init
{
    if (self = [super init]) {
        
        _selectedAssets = [[NSMutableArray alloc] init];
        
        //Remove Temp file
        NSArray *paths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *documentsURL = [paths lastObject];
        
        NSURL *finalUploading = [[NSURL alloc] initWithString: [[NSString alloc] initWithFormat:@"%@/temp", documentsURL.absoluteString]];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:[finalUploading path]]){
            [fileManager removeItemAtPath:[finalUploading path] error:nil];
        }
        
        // Default values:
        _displaySelectionInfoToolbar = YES;
        _displayAlbumsNumberOfAssets = YES;
        _autoDisableDoneButton = YES;
        _allowsMultipleSelection = NO;
        _confirmSingleSelection = YES;
        _showCameraButton = NO;
        
        // Grid configuration:
        _colsInPortrait = 3;
        _colsInLandscape = 5;
        _minimumInteritemSpacing = 2.0;
        
        // Sample of how to select the collections you want to display:
        _customSmartCollections = @[@(PHAssetCollectionSubtypeSmartAlbumFavorites),
                                    @(PHAssetCollectionSubtypeSmartAlbumRecentlyAdded),
                                    @(PHAssetCollectionSubtypeSmartAlbumVideos),
                                    @(PHAssetCollectionSubtypeSmartAlbumSlomoVideos),
                                    @(PHAssetCollectionSubtypeSmartAlbumTimelapses),
                                    @(PHAssetCollectionSubtypeSmartAlbumBursts),
                                    @(PHAssetCollectionSubtypeSmartAlbumPanoramas)];
        // If you don't want to show smart collections, just put _customSmartCollections to nil;
        //_customSmartCollections=nil;
        
        // Which media types will display
//        _mediaTypes = @[@(PHAssetMediaTypeAudio),
//                        @(PHAssetMediaTypeVideo),
//                        @(PHAssetMediaTypeImage)];
        _mediaTypes = @[@(PHAssetMediaTypeVideo)];
        
        self.preferredContentSize = kPopoverContentSize;
        
        // UI Customisation
        _pickerBackgroundColor = [UIColor whiteColor];
        _pickerTextColor = [UIColor darkTextColor];
        _pickerFontName = @"HelveticaNeue";
        _pickerBoldFontName = @"HelveticaNeue-Bold";
        _pickerFontNormalSize = 14.0f;
        _pickerFontHeaderSize = 17.0f;
        
        _navigationBarBackgroundColor = [UIColor whiteColor];
        _navigationBarTextColor = [UIColor darkTextColor];
        _navigationBarTintColor = [UIColor darkTextColor];
        
        _toolbarBarTintColor = [UIColor whiteColor];
        _toolbarTextColor = [UIColor darkTextColor];
        _toolbarTintColor = [UIColor darkTextColor];
        
        _pickerStatusBarStyle = UIStatusBarStyleDefault;
        
        
        _albumsController = [[GMAlbumsViewController alloc] init];
        
        
        
        _toBeUploaded = [[NSURL alloc] init];
        _resultURL = [[NSString alloc] initWithString:@""];
        _uploadPath = [[NSString alloc] initWithString:@""];
        
        
        
        
        [self setupNavigationController];
        
    }
    return self;
}

- (void) setupFilestack:(NSString *)key secret:(NSString *)secret region:(NSString *)region bucket:(NSString *)bucket folder:(NSString *)folder
{
    self.apiKey = [[NSString alloc] initWithString:key];
    self.appSecret = [[NSString alloc] initWithString:secret];
    
    // Filestack
    NSTimeInterval oneDayInSeconds = 60*60*24;
    NSDate *expiryDate = [[NSDate alloc] initWithTimeIntervalSinceNow:oneDayInSeconds];
    FSPolicyCall permissions = FSPolicyCallPick | FSPolicyCallRead | FSPolicyCallStore;
    FSPolicy *policy = [[FSPolicy alloc] initWithExpiry:expiryDate call:permissions];
    NSError *error;
    FSSecurity *security = [[FSSecurity alloc] initWithPolicy:policy appSecret:self.appSecret error:&error];
    if (error != nil) {
        NSLog(@"Error instantiating policy object: %@", error.localizedDescription);
        self.client = nil;
    } else {
        self.client = [[FSClient alloc] initWithApiKey:self.apiKey security:security];
    }
    
    self.uploadOptions = FSUploadOptions.defaults;
    if (folder.length > 0) {
        self.uploadOptions.storeOptions.path = [[NSString alloc] initWithString:folder];
    }
    
    if (bucket.length > 0 && region.length > 0) {
        self.uploadOptions.storeOptions.container = [[NSString alloc] initWithString:bucket];
        self.uploadOptions.storeOptions.region = [[NSString alloc] initWithString:region];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Ensure nav and toolbar customisations are set. Defaults are in place, but the user may have changed them
    self.view.backgroundColor = _pickerBackgroundColor;

    _navigationController.toolbar.translucent = YES;
    _navigationController.toolbar.barTintColor = _toolbarBarTintColor;
    _navigationController.toolbar.tintColor = _toolbarTintColor;
//    [(UIView*)[_navigationController.toolbar.subviews objectAtIndex:0] setAlpha:0.75f];  // URGH - I know!
    
    _navigationController.navigationBar.backgroundColor = _navigationBarBackgroundColor;
    _navigationController.navigationBar.tintColor = _navigationBarTintColor;
    NSDictionary *attributes;
    if (_useCustomFontForNavigationBar) {
        attributes = @{NSForegroundColorAttributeName : _navigationBarTextColor,
                       NSFontAttributeName : [UIFont fontWithName:_pickerBoldFontName size:_pickerFontHeaderSize]};
    } else {
        attributes = @{NSForegroundColorAttributeName : _navigationBarTextColor};
    }
    _navigationController.navigationBar.titleTextAttributes = attributes;
    
    [self updateToolbar];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return _pickerStatusBarStyle;
}

-(BOOL) shouldAutorotate{ return YES; }

-(UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - Setup Navigation Controller

- (void)setupNavigationController
{
    _navigationController = [[UINavigationController alloc] initWithRootViewController:_albumsController];
    _navigationController.delegate = self;
    
    _navigationController.navigationBar.translucent = YES;
    [_navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    _navigationController.navigationBar.shadowImage = [UIImage new];
    
    [_navigationController willMoveToParentViewController:self];
    [_navigationController.view setFrame:self.view.frame];
    [self.view addSubview:_navigationController.view];
    [self addChildViewController:_navigationController];
    [_navigationController didMoveToParentViewController:self];
    
}

-(void)uploadSelectedFile
{
    // If selected Video exist
    if (self.toBeUploaded.absoluteString.length != 0) {
        
                 
            self.progressController = [[ProgressViewController alloc] init];
             self.progressController.view.backgroundColor = [UIColor colorWithWhite:1 alpha:0.8f];
            self.progressController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            [self presentViewController:self.progressController animated:YES completion:nil];
        
//            [self.progressController setProgress:[[NSNumber alloc] initWithDouble:0.0]];
        
        
        [self.client uploadURLUsing:self.toBeUploaded options:self.uploadOptions queue:dispatch_get_main_queue() uploadProgress:^(NSProgress * _Nonnull progress) {
                        NSLog(@"Progress: %@", progress);
                    
                        [self.progressController setProgress:[[NSNumber alloc] initWithDouble:progress.fractionCompleted]];
        
                    
                   } completionHandler:^(FSNetworkJSONResponse * _Nullable response) { NSDictionary *jsonResponse = response.json;
                       NSString *handle = jsonResponse[@"handle"];
                       NSError *error = response.error;
                       NSMutableArray<NSString *> *descriptions = [NSMutableArray arrayWithCapacity:10];
                       [descriptions addObject:response.description];
                       if (handle) { // Use Filestack handle
                           
                           NSString *resultDescription = [descriptions componentsJoinedByString:@", "];
                           NSLog(@"Success: %@", resultDescription);
                           for(NSString *key in [jsonResponse allKeys]) {
                             
                             NSLog(@"%@ ------ %@", key, [jsonResponse objectForKey:key]);
                               if ([key isEqualToString:@"url"]) {
                                   self.resultURL = [[NSString alloc] initWithString:[jsonResponse objectForKey:key]];
                               }
                            
                           }
                           dispatch_async(dispatch_get_main_queue(), ^(void) {
                               [self.progressController dismissViewControllerAnimated:YES completion:nil];
                               [self finishPickingAssets:self];
                           });
                           
                       } else if (error) { // Handle error
                           NSLog(@"Error is: %@", error);
                           dispatch_async(dispatch_get_main_queue(), ^(void) {
                               [self.progressController dismissViewControllerAnimated:YES completion:nil];
                           });
                       }
                   }
                ];
        
        
    }
    
}


#pragma mark - UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        // Only if OK was pressed do we want to completge the selection
//        [self finishPickingAssets:self];
        
//        [self.navigationController setViewControllers:[NSArray arrayWithObject: _progressController]];
//        [_progressController setProgress:[[NSNumber alloc] initWithFloat:0.5]];
           
        
        
        
    }
}


#pragma mark - Select / Deselect Asset

- (void)selectAsset:(PHAsset *)asset
{
    [self.selectedAssets insertObject:asset atIndex:self.selectedAssets.count];
    [self updateDoneButton];
    
    if (!self.allowsMultipleSelection) {
        if (self.confirmSingleSelection) {
            NSString *message = self.confirmSingleSelectionPrompt ? self.confirmSingleSelectionPrompt : [NSString stringWithFormat:@"Do you want to upload video you tapped on? Upload Task will be continued in Background."];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat: @"Upload Ready?"]
                message:message
                preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"No"]
                style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                // Ok action example
            }];
            UIAlertAction *otherAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Yes"]
                style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                // Other action
                PHAsset *firstAsset = [self.selectedAssets objectAtIndex:0];
                if (firstAsset.mediaType == PHAssetMediaTypeVideo) {
                    [[PHImageManager defaultManager] requestAVAssetForVideo:firstAsset options:nil resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info)
                    {
                        if ([asset isKindOfClass:[AVURLAsset class]])
                        {
                            NSURL *url = [(AVURLAsset*)asset URL];
                             // do what you want with it

                            self.toBeUploaded = [(AVURLAsset*)asset URL];
                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                 [self uploadSelectedFile];
                            });
                            
                            NSString *path=[NSString stringWithFormat:@"%@",url];
                            NSLog(@"GMImagePicker: User ended picking assets. Video Path is: %@", path);
                        }
                    }];
                }
            }];
            [alert addAction:okAction];
            [alert addAction:otherAction];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
//            [self finishPickingAssets:self];
            
            /// Hide assetPickerController if singleSelection disabled
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
    } else if (self.displaySelectionInfoToolbar || self.showCameraButton) {
        [self updateToolbar];
    }
}

- (void)deselectAsset:(PHAsset *)asset
{
    [self.selectedAssets removeObjectAtIndex:[self.selectedAssets indexOfObject:asset]];
    if (self.selectedAssets.count == 0) {
        [self updateDoneButton];
    }
    
    if (self.displaySelectionInfoToolbar || self.showCameraButton) {
        [self updateToolbar];
    }
}

- (void)updateDoneButton
{
    if (!self.allowsMultipleSelection) {
        return;
    }
    
    UINavigationController *nav = (UINavigationController *)self.childViewControllers[0];
    for (UIViewController *viewController in nav.viewControllers) {
        viewController.navigationItem.rightBarButtonItem.enabled = (self.autoDisableDoneButton ? self.selectedAssets.count > 0 : TRUE);
    }
}

- (void)updateToolbar
{
    if (!self.allowsMultipleSelection && !self.showCameraButton) {
        return;
    }

    UINavigationController *nav = (UINavigationController *)self.childViewControllers[0];
    for (UIViewController *viewController in nav.viewControllers) {
        NSUInteger index = 1;
        if (_showCameraButton) {
            index++;
        }
        [[viewController.toolbarItems objectAtIndex:index] setTitleTextAttributes:[self toolbarTitleTextAttributes] forState:UIControlStateNormal];
        [[viewController.toolbarItems objectAtIndex:index] setTitleTextAttributes:[self toolbarTitleTextAttributes] forState:UIControlStateDisabled];
        [[viewController.toolbarItems objectAtIndex:index] setTitle:[self toolbarTitle]];
        [viewController.navigationController setToolbarHidden:(self.selectedAssets.count == 0 && !self.showCameraButton) animated:YES];
    }
}


#pragma mark - User finish Actions

- (void)dismiss:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(assetsPickerControllerDidCancel:)]) {
        [self.delegate assetsPickerControllerDidCancel:self];
    }
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


- (void)finishPickingAssets:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(assetsPickerController:didFinishUpload:)]) {
        [self.delegate assetsPickerController:self didFinishUpload:self.resultURL];
    }
}


#pragma mark - Toolbar Title

- (NSPredicate *)predicateOfAssetType:(PHAssetMediaType)type
{
    return [NSPredicate predicateWithBlock:^BOOL(PHAsset *asset, NSDictionary *bindings) {
        return (asset.mediaType == type);
    }];
}

- (NSString *)toolbarTitle
{
    if (self.selectedAssets.count == 0) {
        return nil;
    }
    
    NSPredicate *photoPredicate = [self predicateOfAssetType:PHAssetMediaTypeImage];
    NSPredicate *videoPredicate = [self predicateOfAssetType:PHAssetMediaTypeVideo];
    
    NSInteger nImages = [self.selectedAssets filteredArrayUsingPredicate:photoPredicate].count;
    NSInteger nVideos = [self.selectedAssets filteredArrayUsingPredicate:videoPredicate].count;
    
    if (nImages > 0 && nVideos > 0) {
        return [NSString stringWithFormat:@"%@ Items Selected", @(nImages + nVideos)];
    } else if (nImages > 1) {
        return [NSString stringWithFormat:@"%@ Photos Selected", @(nImages)];
    } else if (nImages == 1) {
        return @"1 Photo Selected";
    } else if (nVideos > 1) {
        return [NSString stringWithFormat:@"%@ Videos Selected", @(nVideos)];
    } else if (nVideos == 1) {
        return @"1 Video Selected";
    } else {
        return nil;
    }
}


#pragma mark - Toolbar Items

- (void)cameraButtonPressed:(UIBarButtonItem *)button
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Camera!"
                                                        message:@"Sorry, this device does not have a camera."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];

        return;
    }
    
    // This allows the selection of the image taken to be better seen if the user is not already in that VC
    if (self.autoSelectCameraImages && [self.navigationController.topViewController isKindOfClass:[GMAlbumsViewController class]]) {
        [((GMAlbumsViewController *)self.navigationController.topViewController) selectAllAlbumsCell];
    }
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.mediaTypes = @[(NSString *)kUTTypeImage];
    picker.allowsEditing = self.allowsEditingCameraImages;
    picker.delegate = self;
    picker.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *popPC = picker.popoverPresentationController;
    popPC.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popPC.barButtonItem = button;
    
    [self showViewController:picker sender:button];
}

- (NSDictionary *)toolbarTitleTextAttributes {
    return @{NSForegroundColorAttributeName : _toolbarTextColor,
             NSFontAttributeName : [UIFont fontWithName:_pickerFontName size:_pickerFontHeaderSize]};
}

- (UIBarButtonItem *)titleButtonItem
{
    UIBarButtonItem *title = [[UIBarButtonItem alloc] initWithTitle:self.toolbarTitle
                                                              style:UIBarButtonItemStylePlain
                                                             target:nil
                                                             action:nil];
    
    NSDictionary *attributes = [self toolbarTitleTextAttributes];
    [title setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [title setTitleTextAttributes:attributes forState:UIControlStateDisabled];
    [title setEnabled:NO];
    
    return title;
}

- (UIBarButtonItem *)spaceButtonItem
{
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
}

- (UIBarButtonItem *)cameraButtonItem
{
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(cameraButtonPressed:)];
}

- (NSArray *)toolbarItems
{
    UIBarButtonItem *camera = [self cameraButtonItem];
    UIBarButtonItem *title  = [self titleButtonItem];
    UIBarButtonItem *space  = [self spaceButtonItem];
    
    NSMutableArray *items = [[NSMutableArray alloc] init];
    if (_showCameraButton) {
        [items addObject:camera];
    }
    [items addObject:space];
    [items addObject:title];
    [items addObject:space];
    
    return [NSArray arrayWithArray:items];
}


#pragma mark - Camera Delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];

    NSString *mediaType = info[UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage *image = info[UIImagePickerControllerEditedImage] ? : info[UIImagePickerControllerOriginalImage];
        UIImageWriteToSavedPhotosAlbum(image,
                                       self,
                                       @selector(image:finishedSavingWithError:contextInfo:),
                                       nil);
    }
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)image:(UIImage *)image finishedSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Image Not Saved"
                                                        message:@"Sorry, unable to save the new image!"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    // Note: The image view will auto refresh as the photo's are being observed in the other VCs
}

@end

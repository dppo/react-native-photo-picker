#import "PhotoPicker.h"
#import "PPWindowManager.h"
#import <HXPhotoPicker/HXPhotoPicker.h>

#define PPWeakObj(o) autoreleasepool{} __weak typeof(o) o##Weak = o;

@implementation PhotoPicker

RCT_EXPORT_MODULE()

RCT_REMAP_METHOD(openGallery,
                 openGalleryWithOptions:(NSDictionary *)options
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)
{
    HXPhotoManager *manager = [self handlerPhotoManagerWithOptions:options];
    
    @PPWeakObj(self);
    [[[PPWindowManager shareManager] jsd_findVisibleViewController] hx_presentSelectPhotoControllerWithManager:manager didDone:^(NSArray<HXPhotoModel *> * _Nullable allList, NSArray<HXPhotoModel *> * _Nullable photoList, NSArray<HXPhotoModel *> * _Nullable videoList, BOOL isOriginal, UIViewController * _Nullable viewController, HXPhotoManager * _Nullable manager) {
        [selfWeak handlerSelectedPhotos:allList withResolver:resolve withRejecter:reject];
    } cancel:^(UIViewController * _Nullable viewController, HXPhotoManager * _Nullable manager) {
        reject(@"cancel", @"user select cancel", nil);
    }];
}

RCT_REMAP_METHOD(openCamera,
                 openCameraWithOptions:(NSDictionary *)options
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)
{
    HXPhotoManager *manager = [self handlerPhotoManagerWithOptions:options];
    
    @PPWeakObj(self);
    [[[PPWindowManager shareManager] jsd_findVisibleViewController] hx_presentCustomCameraViewControllerWithManager:manager done:^(HXPhotoModel *model, HXCustomCameraViewController *viewController) {
        [selfWeak handlerSelectedPhotos:@[model] withResolver:resolve withRejecter:reject];
    } cancel:^(HXCustomCameraViewController *viewController) {
        reject(@"cancel", @"user select cancel", nil);
    }];
}

- (void)handlerSelectedPhotos:(NSArray<HXPhotoModel *> *)photos withResolver:(RCTPromiseResolveBlock)resolve withRejecter:(RCTPromiseRejectBlock)reject
{
    @PPWeakObj(self);
    NSString *tmpPath = NSTemporaryDirectory();
    NSMutableArray *images = [NSMutableArray array];
    dispatch_group_t group = dispatch_group_create();
    for (int i = 0; i<photos.count; i++) {
        NSString *imageName = [NSString stringWithFormat:@"%.0f_%d.jpg", [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970], i];
        NSString *imagePath = [NSString stringWithFormat:@"%@%@",tmpPath, imageName];
        HXPhotoModel *photoModel = photos[i];
        dispatch_group_enter(group);
        if (photoModel.subType == HXPhotoModelMediaSubTypePhoto) {
            if (photoModel.photoEdit) {
                [images addObject:[selfWeak handlerImageAssetData:[UIImage imageWithData:photoModel.photoEdit.editPreviewData] imageName:imageName imagePath:imagePath]];
                dispatch_group_leave(group);
            }else {
                if (photoModel.type == HXPhotoModelMediaTypeCameraPhoto) {
                    if (photoModel.networkPhotoUrl) {
                        // network image
                    }else {
                        // local image
                        [images addObject:[selfWeak handlerImageAssetData:photoModel.previewPhoto imageName:imageName imagePath:imagePath]];
                        dispatch_group_leave(group);
                    }
                }else {
                    if (photoModel.type == HXPhotoModelMediaTypePhoto) {
                        [photoModel requestPreviewImageWithSize:PHImageManagerMaximumSize startRequestICloud:nil progressHandler:nil success:^(UIImage * _Nullable image, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
                            [images addObject:[selfWeak handlerImageAssetData:image imageName:imageName imagePath:imagePath]];
                            dispatch_group_leave(group);
                        } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
                            dispatch_group_leave(group);
                        }];
                    }else if (photoModel.type == HXPhotoModelMediaTypePhotoGif) {
                        [photoModel requestImageDataStartRequestICloud:nil progressHandler:nil success:^(NSData * _Nullable imageData, UIImageOrientation orientation, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
                            [images addObject:[selfWeak handlerImageAssetData:[UIImage imageWithData:imageData] imageName:imageName imagePath:imagePath]];
                            dispatch_group_leave(group);
                        } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
                            dispatch_group_leave(group);
                        }];
                    }else if (photoModel.type == HXPhotoModelMediaTypeLivePhoto) {
                        [photoModel requestLivePhotoAssetsWithSuccess:^(NSURL * _Nullable imageURL, NSURL * _Nullable videoURL, BOOL isNetwork, HXPhotoModel * _Nullable model) {
                            [images addObject:[selfWeak handlerImageAssetData:[UIImage imageWithContentsOfFile:imageURL.absoluteString] imageName:imageName imagePath:imagePath]];
                            dispatch_group_leave(group);
                        } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
                            dispatch_group_leave(group);
                        }];
                    }
                }
            }
        }else if(photoModel.subType == HXPhotoModelMediaSubTypeVideo) {
            // video
        }
    }
    dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        resolve(images);
    });
}

- (NSDictionary *)handlerImageAssetData:(UIImage *)image imageName:(NSString *)imageName imagePath:(NSString *)imagePath
{
    [UIImageJPEGRepresentation(image, 1) writeToFile:imagePath atomically:YES];
    return @{
        @"imagePath":imagePath,
        @"imageName":imageName,
        @"mimeType":@"image/jpeg",
        @"width":[NSNumber numberWithFloat:image.size.width],
        @"height":[NSNumber numberWithFloat:image.size.height]
    };
}

- (HXPhotoManager *)handlerPhotoManagerWithOptions:(NSDictionary *)options
{
    NSString *mediaType = options[@"mediaType"] ? options[@"mediaType"]: @"mixed";
    NSInteger selectionLimit = options[@"selectionLimit"] ? [options[@"selectionLimit"] intValue] : 1;
    BOOL editable = options[@"editable"] ? [options[@"editable"] boolValue] : YES;
    
    HXPhotoManagerSelectedType type = [@[@"photo",@"video",@"mixed"] indexOfObject:mediaType];
    HXPhotoManager *manager = [HXPhotoManager managerWithType:type];
    manager.configuration.type = HXConfigurationTypeWXMoment;
    manager.configuration.singleSelected = selectionLimit <= 1;
    manager.configuration.photoMaxNum = selectionLimit;
    manager.configuration.openCamera = NO;
    manager.configuration.singleJumpEdit = editable;
    manager.configuration.cameraCanLocation = NO;
    manager.configuration.photoCanEdit = editable;
    
    manager.configuration.photoEditConfigur.onlyCliping = YES;
    manager.configuration.photoEditConfigur.clippingMinSize = CGSizeMake(30, 30);
    
    return manager;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

@end

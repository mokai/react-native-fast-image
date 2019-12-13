#import "FFFastImageViewManager.h"
#import "FFFastImageView.h"

#import <SDWebImage/SDWebImagePrefetcher.h>
#import <SDWebImage/SDImageCache.h>

@implementation FFFastImageViewManager

RCT_EXPORT_MODULE(FastImageView)

- (FFFastImageView*)view {
  return [[FFFastImageView alloc] init];
}

RCT_EXPORT_VIEW_PROPERTY(source, FFFastImageSource)
RCT_EXPORT_VIEW_PROPERTY(resizeMode, RCTResizeMode)
RCT_EXPORT_VIEW_PROPERTY(onFastImageLoadStart, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onFastImageProgress, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onFastImageError, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onFastImageLoad, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onFastImageLoadEnd, RCTDirectEventBlock)
RCT_REMAP_VIEW_PROPERTY(tintColor, imageColor, UIColor)

RCT_EXPORT_METHOD(preload:(nonnull NSArray<FFFastImageSource *> *)sources
                  preloadWithResolver:(RCTPromiseResolveBlock) resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    NSMutableArray *urls = [NSMutableArray arrayWithCapacity:sources.count];

    [sources enumerateObjectsUsingBlock:^(FFFastImageSource * _Nonnull source, NSUInteger idx, BOOL * _Nonnull stop) {
        [source.headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString* header, BOOL *stop) {
            [[SDWebImageDownloader sharedDownloader] setValue:header forHTTPHeaderField:key];
        }];
        [urls setObject:source.url atIndexedSubscript:idx];
    }];

    [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:urls progress:^(NSUInteger finishedUrls, NSUInteger totalUrls) {
    } completed:^(NSUInteger finishedUrls, NSUInteger skippedUrls) {
        resolve(@{
            @"finished": [NSString stringWithFormat:@"%lu", finishedUrls],
            @"skipped": [NSString stringWithFormat:@"%lu", skippedUrls],
        });
    }];
}

RCT_EXPORT_METHOD(getCachePath:(NSString *)key
                  withResolver:(RCTPromiseResolveBlock)resolve
                   andRejecter:(RCTPromiseRejectBlock)reject)
{
    BOOL isCached = [[SDImageCache sharedImageCache] diskImageDataExistsWithKey:key];
    if (isCached) {
        NSString *cachePath = [[SDImageCache sharedImageCache] cachePathForKey:key];
        resolve(cachePath);
    } else {
        resolve([NSNull null]);
    }
}

RCT_EXPORT_METHOD(getCachePaths:(NSArray<NSString *> *)keys
                  withResolver:(RCTPromiseResolveBlock)resolve
                   andRejecter:(RCTPromiseRejectBlock)reject)
{
    NSMutableArray *paths = [NSMutableArray arrayWithCapacity:keys.count];
    for (NSString *key in keys) {
        BOOL isCached = [[SDImageCache sharedImageCache] diskImageDataExistsWithKey:key];
        if (isCached) {
            NSString *cachePath = [[SDImageCache sharedImageCache] cachePathForKey:key];
            [paths addObject:cachePath];
        } else {
            [paths addObject:[NSNull null]];
        }
    }
    resolve(paths);
}

@end


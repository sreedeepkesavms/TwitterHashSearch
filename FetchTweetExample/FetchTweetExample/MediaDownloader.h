//
//  MediaDownloader.h
//  FetchTweetExample
//
//  Created by Sreedeepkesav on 31/01/16.
//  Copyright © 2016 test. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@class AppRecord;

@interface MediaDownloader : NSObject

@property (nonatomic, strong) AppRecord *appRecord;
@property (nonatomic, copy) void (^completionHandler)(void);

- (void)startDownload;
- (void)cancelDownload;

@end

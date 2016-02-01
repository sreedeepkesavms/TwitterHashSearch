//
//  MediaDownloader.m
//  FetchTweetExample
//
//  Created by Sreedeepkesav on 31/01/16.
//  Copyright © 2016 test. All rights reserved.
//

#import "MediaDownloader.h"
#import "AppRecord.h"

#define kAppIconSize 40

@interface MediaDownloader ()

@property (nonatomic, strong) NSURLSessionDataTask *sessionTask;

@end

#pragma mark - 

@implementation MediaDownloader

// -------------------------------------------------------------------------------
//	startDownload
// -------------------------------------------------------------------------------
- (void)startDownload
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.appRecord.mediaURLString]];
    
    // create an session data task to obtain and download the app icon
    _sessionTask = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                   completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                       
                                                       // in case we want to know the response status code
                                                       //NSInteger HTTPStatusCode = [(NSHTTPURLResponse *)response statusCode];
                                                       
                                                       if (error != nil)
                                                       {
                                                           if ([error code] == NSURLErrorAppTransportSecurityRequiresSecureConnection)
                                                           {
                                                               // if you get error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
                                                               // then your Info.plist has not been properly configured to match the target server.
                                                               //
                                                               abort();
                                                           }
                                                       }
                                                       
                                                       [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
                                                           
                                                           // Set appIcon and clear temporary data/image
                                                           UIImage *image = [[UIImage alloc] initWithData:data];
                                                           

                                                                NSLog(@"Image - %@", image);
                                                               self.appRecord.mediaImage = image;
//                                         
//                                                           
                                                           // call our completion handler to tell our client that our icon is ready for display
                                                           if (self.completionHandler != nil)
                                                           {
                                                               self.completionHandler();
                                                           }
                                                       }];
                                                   }];
    
    [self.sessionTask resume];
}

// -------------------------------------------------------------------------------
//	cancelDownload
// -------------------------------------------------------------------------------
- (void)cancelDownload
{
    [self.sessionTask cancel];
    _sessionTask = nil;
}


@end

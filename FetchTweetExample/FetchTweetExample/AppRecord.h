 /*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Object encapsulating information about an iOS app in the 'Top Paid Apps' RSS feed.
  Each one corresponds to a row in the app's table.
 */

#include <UIKit/UIKit.h>

@interface AppRecord : NSObject

@property (nonatomic, strong) UIImage *appIcon;
@property (nonatomic, strong) NSString *imageURLString;
@property (nonatomic, strong) NSString *mediaURLString;
@property (nonatomic, strong) UIImage *mediaImage;
@end
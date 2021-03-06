//
//  BCOptions.h
//  BioCaching
//
//  Created by Andy Jeffrey on 23/04/2014.
//  Copyright (c) 2014 MPApps.net. All rights reserved.
//

// Switch to NSUserDefaults

#import <Foundation/Foundation.h>
#import "SearchOptions.h"
#import "DisplayOptions.h"

@interface BCOptions : NSObject

@property (nonatomic, strong, readonly) SearchOptions *searchOptions;
@property (nonatomic, strong, readonly) DisplayOptions *displayOptions;

+ (instancetype)sharedInstance;
- (id)initWithDefaults;

@end

//
//  BCRestKitJsonParser.m
//  BioCaching
//
//  Created by Andy Jeffrey on 10/07/2014.
//  Copyright (c) 2014 MPApps.net. All rights reserved.
//

//  Custom RestKit JSON Parser to amend RestKit responses before mapping
//  http://stackoverflow.com/questions/8692246/how-to-change-json-before-mapping-by-restkit
//
//  Nasty cludge to handle INatObservation POST response being inside an array
//  (causing mapping of response to the single request entity to fail)

#import "BCRestKitJsonParser.h"

@implementation BCRestKitJsonParser

+ (id)objectFromData:(NSData *)data error:(NSError *__autoreleasing *)error
{
    id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    
    // Change JSON before mapping
    if ([result isKindOfClass:[NSArray class]] && ([(NSArray *)result count] > 0)) {
        NSLog(@"BCRestKitJsonParser, Amended JSON:%@", result[0]);
        return result[0];
    }
    
    return result;
}

+ (NSData *)dataFromObject:(id)object error:(NSError *__autoreleasing *)error
{
    return [NSJSONSerialization dataWithJSONObject:object options:0 error:error];
}

@end

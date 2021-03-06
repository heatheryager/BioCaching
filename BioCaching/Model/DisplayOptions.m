//
//  DisplayOptions.m
//  BioCaching
//
//  Created by Andy Jeffrey on 23/04/2014.
//  Copyright (c) 2014 MPApps.net. All rights reserved.
//

#import "DisplayOptions.h"

#define kOptionsKeyMapType          @"OptionsMapType"
#define kOptionsKeyFollowUser       @"OptionsFollowUser"
#define kOptionsKeyTrackLocation    @"OptionsTrackLocation"
#define kOptionsKeyAutoSearch       @"OptionsAutoSearch"
#define kOptionsKeyPreCacheImages   @"OptionsPreCacheImages"
#define kOptionsKeyDisplayPoints    @"OptionsDisplayPoints"
#define kOptionsKeyUniqueSpecies    @"OptionsUniqueSpecies"
#define kOptionsKeyUniqueLocations  @"OptionsUniqueLocations"
#define kOptionsKeySpeciesBinomial  @"OptionsSpeciesBinomial"

static NSUserDefaults *_userDefaults;

@implementation DisplayOptions

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    static DisplayOptions *instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] initPrivate];
    });
    return instance;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[DisplayOptions sharedInstance]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
        
        if (![_userDefaults objectForKey:kOptionsKeyMapType]) {
            self.mapType = kOptionsDefaultMapType;
            self.followUser = kOptionsDefaultFollowUser;
            self.trackLocation = kOptionsDefaultTrackLocation;
            self.autoSearch = kOptionsDefaultAutoSearch;
            self.preCacheImages = kOptionsDefaultPreCacheImages;
            self.displayPoints = kOptionsDefaultDisplayPoints;
            self.uniqueSpecies = kOptionsDefaultUniqueSpecies;
            self.uniqueLocations = kOptionsDefaultUniqueLocations;
            self.fullSpeciesNames = kOptionsDefaultFullSpeciesNames;
        }
    }
    return self;
}

- (MKMapType)mapType {
    return [[_userDefaults objectForKey:kOptionsKeyMapType] intValue];
}
- (void)setMapType:(MKMapType)mapType
{
    [_userDefaults setObject:[NSNumber numberWithInt:mapType] forKey:kOptionsKeyMapType];
    [_userDefaults synchronize];
}

- (BOOL)followUser {
    return [[_userDefaults objectForKey:kOptionsKeyFollowUser] boolValue];
}
- (void)setFollowUser:(BOOL)followUser {
    [_userDefaults setBool:followUser forKey:kOptionsKeyFollowUser];
    [_userDefaults synchronize];
}

- (BOOL)trackLocation {
    return [[_userDefaults objectForKey:kOptionsKeyTrackLocation] boolValue];
}
- (void)setTrackLocation:(BOOL)trackLocation {
    [_userDefaults setBool:trackLocation forKey:kOptionsKeyTrackLocation];
    [_userDefaults synchronize];
}

- (BOOL)autoSearch {
    return [[_userDefaults objectForKey:kOptionsKeyAutoSearch] boolValue];
}
- (void)setAutoSearch:(BOOL)autoSearch {
    [_userDefaults setBool:autoSearch forKey:kOptionsKeyAutoSearch];
    [_userDefaults synchronize];
}

- (BOOL)preCacheImages {
    return [[_userDefaults objectForKey:kOptionsKeyPreCacheImages] boolValue];
}
- (void)setPreCacheImages:(BOOL)preCacheImages {
    [_userDefaults setBool:preCacheImages forKey:kOptionsKeyPreCacheImages];
    [_userDefaults synchronize];
}

- (NSUInteger)displayPoints {
    return [[_userDefaults objectForKey:kOptionsKeyDisplayPoints] unsignedIntegerValue];
}
- (void)setDisplayPoints:(NSUInteger)displayPoints
{
    [_userDefaults setObject:[NSNumber numberWithUnsignedInteger:displayPoints] forKey:kOptionsKeyDisplayPoints];
    [_userDefaults synchronize];
}

- (BOOL)uniqueSpecies {
    return [[_userDefaults objectForKey:kOptionsKeyUniqueSpecies] boolValue];
}
- (void)setUniqueSpecies:(BOOL)uniqueSpecies
{
    [_userDefaults setBool:uniqueSpecies forKey:kOptionsKeyUniqueSpecies];
    [_userDefaults synchronize];
}

- (BOOL)uniqueLocations {
    return [[_userDefaults objectForKey:kOptionsKeyUniqueLocations] boolValue];
}
- (void)setUniqueLocations:(BOOL)uniqueLocations
{
    [_userDefaults setBool:uniqueLocations forKey:kOptionsKeyUniqueLocations];
    [_userDefaults synchronize];
}

- (BOOL)fullSpeciesNames {
    return [[_userDefaults objectForKey:kOptionsKeySpeciesBinomial] boolValue];
}
- (void)setFullSpeciesNames:(BOOL)fullSpeciesNames
{
    [_userDefaults setBool:fullSpeciesNames forKey:kOptionsKeySpeciesBinomial];
    [_userDefaults synchronize];
}

@end

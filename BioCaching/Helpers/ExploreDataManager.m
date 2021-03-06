//
//  ExploreDataManager.m
//  BioCaching
//
//  Created by Andy Jeffrey on 03/06/2014.
//  Copyright (c) 2014 MPApps.net. All rights reserved.
//

#import "ExploreDataManager.h"
#import "GBIFManager.h"
#import "INatManager.h"
#import "TripsDataManager.h"
#import "ImageCache.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

@implementation ExploreDataManager {
    GBIFManager *_gbifManager;
    INatManager *_iNatManager;
    TripsDataManager *_tripsDataManager;
    NSManagedObjectContext *_managedObjectContext;
    BCOptions *_bcOptions;
}

+(instancetype)sharedInstance
{
    static dispatch_once_t once;
    static ExploreDataManager *instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] initPrivate];
    });
    return instance;
}


- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[ExploreDataManager sharedInstance]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        _gbifManager = [[GBIFManager alloc] init];
        _gbifManager.delegate = self;
        
        _iNatManager = [[INatManager alloc] init];
        _iNatManager.delegate = self;
        
        _tripsDataManager = [TripsDataManager sharedInstance];
        _managedObjectContext = [[RKObjectManager sharedManager] managedObjectStore].mainQueueManagedObjectContext;
    }
    return self;
}


#pragma mark - ExploreDataManager Protocol Methods

- (void)fetchOccurrencesWithOptions:(BCOptions *)bcOptions
{
    _bcOptions = bcOptions;
    
    if (![ConnectionHelper checkNetworkConnectivityAndDisplayAlert:NO]) {
        return;
    }

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [BCLoggingHelper recordGoogleEvent:@"GBIF" action:@"OccurrenceSearchRequest"];
    [_gbifManager fetchOccurrencesWithOptions:bcOptions.searchOptions];
}

- (void)removeOccurrence:(GBIFOccurrence *)occurrence
{
    [self.currentSearchResults.removedResults addObject:occurrence];
    [self.delegate occurrenceRemoved:occurrence];
}


#pragma mark - GBIFManagerDelegate Methods

- (void)didReceiveOccurences:(GBIFOccurrenceResults *)occurrenceResults
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [BCLoggingHelper recordGoogleEvent:@"GBIF" action:@"OccurrenceSearchResponse" value:[NSNumber numberWithUnsignedInteger:occurrenceResults.filteredResults.count]];
    
    DDLogVerbose(@"%s Results.count: %lu", __PRETTY_FUNCTION__, (unsigned long)occurrenceResults.Results.count);

    if (occurrenceResults.Results.count > 0) {
        [BCAlerts displayDefaultSuccessNotification:
         [NSString stringWithFormat:@"%d Records Found", (int)occurrenceResults.filteredResults.count] subtitle:@"Fetching Shortlisted Species Details..."];

        occurrenceResults.tripListRequestCount = (int)occurrenceResults.tripListResults.count;
        occurrenceResults.tripListRequests = [[NSMutableArray alloc] initWithCapacity:occurrenceResults.tripListResults.count];
        self.currentSearchResults = occurrenceResults;
        
        if ([_tripsDataManager createNewTrip:occurrenceResults bcOptions:_bcOptions])
        {
            [_tripsDataManager.exploreDelegate newTripCreated:_tripsDataManager.currentTrip];
            for (GBIFOccurrence *occurrence in occurrenceResults.tripListResults)
            {
                occurrence.occurrenceResultsRef = occurrenceResults;
                [occurrenceResults.tripListRequests addObject:occurrence];
                [_iNatManager addINatTaxonToGBIFOccurrence:occurrence];
            }
        }
    } else {
        [BCAlerts displayDefaultFailureNotification:@"No Records Found" subtitle:nil];
        [BCAlerts displayDefaultInfoAlert:@"No Records Found" message:@"Please try a different location/area or change the search options in the Settings menu"];
        [self.delegate occurrenceResultsReceived:nil];
    }
}

- (void)fetchingResultsFailedWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.delegate errorReceived:error];
}


#pragma mark - INatManagerDelegate Methods

- (void)iNatTaxonAddedToGBIFOccurrence:(GBIFOccurrence *)gbifOccurrence
{
    NSError *error = nil;
    
    if (gbifOccurrence.iNatTaxon)
    {
        DDLogVerbose(@"%s \niNatTaxon Received: %@ - %@ \nAdding To Occurrence: %@", __PRETTY_FUNCTION__, gbifOccurrence.speciesBinomial, gbifOccurrence.iNatTaxon.commonName, gbifOccurrence.Key);
        
        if (gbifOccurrence.iNatTaxon.taxonPhotos.count > 0)
        {
            INatTaxonPhoto *mainPhoto = gbifOccurrence.iNatTaxon.taxonPhotos[0];
            if (_bcOptions.displayOptions.preCacheImages) {
                [ImageCache saveImageForURL:mainPhoto.mediumUrl];
            }
        }
        // Create new CoreData OccurrenceRecord entity if required
        if (!gbifOccurrence.occurrenceRecord)
        {
            gbifOccurrence.occurrenceRecord = [OccurrenceRecord createFromGBIFOccurrence:gbifOccurrence];
            
            if (![_managedObjectContext saveToPersistentStore:&error]) {
                RKLogError(@"Error Saving New OccurrenceRecord To Store: %@", error);
            }
        }
        
        [_tripsDataManager addNewTaxaAttributeFromOccurrence:gbifOccurrence.occurrenceRecord];
    }
    else
    {
        DDLogVerbose(@"%s \nNO iNatTaxon Received: %@ \nRemoving Occurrence: %@", __PRETTY_FUNCTION__, gbifOccurrence.speciesBinomial, gbifOccurrence.Key);
        
        [self.currentSearchResults.removedResults addObject:gbifOccurrence];
        [self.delegate occurrenceRemoved:gbifOccurrence];
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"iNatTaxonId != nil"];
    NSArray *tripListResponses = [self.currentSearchResults.tripListRequests filteredArrayUsingPredicate:predicate];
    DDLogVerbose(@"iNatTaxonAddedToGBIFOccurrence, Requests:%d, Responses:%d", self.currentSearchResults.tripListRequestCount, (int)tripListResponses.count);
    
    if (tripListResponses.count == self.currentSearchResults.tripListRequestCount) {
        DDLogInfo(@"iNatTaxonAddedToGBIFOccurrence, SEARCH COMPLETE Requests:%d, Responses:%d", self.currentSearchResults.tripListRequestCount, (int)tripListResponses.count);
        [self.delegate searchCompleted];
    }
}

@end

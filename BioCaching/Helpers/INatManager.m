//
//  INatManager.m
//  BioCaching
//
//  Created by Andy Jeffrey on 07/04/2014.
//  Copyright (c) 2014 MPApps.net. All rights reserved.
//

#import "INatManager.h"
#import "INatTaxon.h"
#import "GBIFOccurrence.h"
#import "ExploreDataManager.h"

static const int ddLogLevel = LOG_LEVEL_DEBUG;

static NSString * const kTaxaSearchQuery = @"taxa/search.json?q=";

@implementation INatManager {
    NSManagedObjectContext *managedObjectContext;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        managedObjectContext = [[RKObjectManager sharedManager] managedObjectStore].mainQueueManagedObjectContext;
    }
    return self;
}

- (void)getTaxonForSpeciesName:(NSString *)speciesName
{
    
}

- (void)addINatTaxonToGBIFOccurrence:(GBIFOccurrence *)occurrence
{
    GBIFOccurrenceResults *results = [ExploreDataManager sharedInstance].currentSearchResults;
    
    DDLogDebug(@"addINatTaxon %d (%d) LOOKUP", [results.tripListResults indexOfObject:occurrence], occurrence.SpeciesKey.intValue);
    
    INatTaxon *primaryTaxon = [self getTaxonFromLocalStore:occurrence.speciesBinomial];
    
    if (primaryTaxon) {
        DDLogDebug(@"addINatTaxon %d (%d) FOUND LOCAL (%d)", [results.tripListResults indexOfObject:occurrence], occurrence.SpeciesKey.intValue, primaryTaxon.recordIdValue);
        [self addTaxonToOccurrenceAndCallDelegate:primaryTaxon occurrence:occurrence];
    } else {
        NSString *taxaSearchPath = [NSString stringWithFormat:@"%@%@",
                                    kTaxaSearchQuery,
                                    [occurrence.speciesBinomial stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        DDLogDebug(@"addINatTaxon %d (%d) INAT REQUEST", [results.tripListResults indexOfObject:occurrence], occurrence.SpeciesKey.intValue);
        [[RKObjectManager sharedManager] getObjectsAtPath:taxaSearchPath parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
            NSError *error = nil;
            
            DDLogVerbose(@"Taxa Search Returned %d results", (int)mappingResult.array.count);
            // INatTaxon MOs automatically created for all search results using RestKit, so remove all but first
            INatTaxon *primaryTaxon = mappingResult.firstObject;
            for (INatTaxon *taxon in mappingResult.array) {
                if (taxon == primaryTaxon) {
                    taxon.searchName = occurrence.speciesBinomial;
                    taxon.localCreatedAt = [NSDate date];
                } else if (taxon) {
                    [managedObjectContext deleteObject:taxon];
                    DDLogVerbose(@"Taxon Object Deleted: \n%d-%@", (int)taxon.recordId, taxon.objectID);
                }
            }
            if (![managedObjectContext saveToPersistentStore:&error]) {
                RKLogError(@"Error Saving Changes To Store: %@", error);
            } else {
                if (primaryTaxon) {
                    DDLogDebug(@"addINatTaxon %d (%d) INAT RESPONSE (%d)", [results.tripListResults indexOfObject:occurrence], occurrence.SpeciesKey.intValue, primaryTaxon.recordIdValue);
                    [BCLoggingHelper recordGoogleEvent:@"INAT" action:[NSString stringWithFormat:@"Taxon Received: %d (%d)", primaryTaxon.recordId.intValue, occurrence.SpeciesKey.intValue] value:[NSNumber numberWithInt:1]];
                } else {
                    DDLogDebug(@"addINatTaxon %d (%d) INAT NOTFOUND", [results.tripListResults indexOfObject:occurrence], occurrence.SpeciesKey.intValue);
                    [BCLoggingHelper recordGoogleEvent:@"INAT" action:[NSString stringWithFormat:@"Taxon Not Found: (%d)", occurrence.SpeciesKey.intValue] value:[NSNumber numberWithInt:0]];
                }
                //Check Search Is Still Valid (i.e. Discard Responses From Previous Searches)
                if (occurrence.occurrenceResultsRef != [ExploreDataManager sharedInstance].currentSearchResults) {
                    DDLogDebug(@"addINatTaxon %d (%d) INAT RESPONSE FOR INACTIVE SEARCH: %@", [results.tripListResults indexOfObject:occurrence], occurrence.SpeciesKey.intValue, occurrence.occurrenceResultsRef);
                } else {
                    [self addTaxonToOccurrenceAndCallDelegate:primaryTaxon occurrence:occurrence];
                }
            }
        } failure:^(RKObjectRequestOperation *operation, NSError *error) {
            DDLogDebug(@"addINatTaxon %d (%d) INAT ERROR", [results.tripListResults indexOfObject:occurrence], occurrence.SpeciesKey.intValue);
            [BCLoggingHelper recordGoogleEvent:@"INAT" action:[NSString stringWithFormat:@"Taxon Lookup Error: (%d)", occurrence.SpeciesKey.intValue] value:[NSNumber numberWithInt:0]];
        }];
    }
}

- (void)addTaxonToOccurrenceAndCallDelegate:(INatTaxon *)taxon occurrence:(GBIFOccurrence *)occurrence
{
    occurrence.iNatTaxon = taxon;
    [self.delegate iNatTaxonAddedToGBIFOccurrence:occurrence];
}

- (INatTaxon *)getTaxonFromLocalStore:(NSString *)speciesName
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"INatTaxon" inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"searchName = %@", speciesName];
    [fetchRequest setPredicate:predicate];
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"updatedAt"
                                                                   ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil || fetchedObjects.count == 0) {
        return nil;
    } else {
        return fetchedObjects[0];
    }
}

@end

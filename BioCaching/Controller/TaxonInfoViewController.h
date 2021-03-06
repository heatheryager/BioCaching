//
//  TaxonInfoViewController.h
//  BioCaching
//
//  Created by Andy Jeffrey on 01/05/2014.
//  Copyright (c) 2014 MPApps.net. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TaxonInfoViewController : UIViewController

@property (nonatomic, strong) OccurrenceRecord *occurrence;
@property (nonatomic, assign) BOOL showDetailsButton;
@property (nonatomic, strong) UINavigationController *navVC;

@end

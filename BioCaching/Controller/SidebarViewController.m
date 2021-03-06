    //
//  SidebarViewController.m
//  BioCaching
//
//  Created by Andy Jeffrey on 29/04/2014.
//  Copyright (c) 2014 MPApps.net. All rights reserved.
//

#import "SidebarViewController.h"
#import "ExploreOptionsViewController.h"
#import "ExploreDataManager.h"
#import "TripsDataManager.h"
#import "LoginManager.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

@interface SidebarViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageIconExplore;
@property (weak, nonatomic) IBOutlet UIImageView *imageIconTrips;
@property (weak, nonatomic) IBOutlet UIImageView *imageIconProfile;
@property (weak, nonatomic) IBOutlet UIImageView *imageIconAbout;
@property (weak, nonatomic) IBOutlet UIImageView *imageIconSettings;

@property (weak, nonatomic) IBOutlet TDBadgedCell *tableCellExplore;
@property (weak, nonatomic) IBOutlet TDBadgedCell *tableCellTrips;
@property (weak, nonatomic) IBOutlet TDBadgedCell *tableCellProfile;


@end

@implementation SidebarViewController {
    UIViewController *_previousVC;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    DDLogVerbose(@"%s", __PRETTY_FUNCTION__);
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    DDLogVerbose(@"%s", __PRETTY_FUNCTION__);
    self.viewControllersCache = [NSMutableDictionary dictionary];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    DDLogVerbose(@"%s", __PRETTY_FUNCTION__);
    
    [self setColors];
    [self setupIcons];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
//    [self.revealViewController.frontViewController.view setUserInteractionEnabled:NO];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    [self updateBadges];
}

- (void)viewDidAppear:(BOOL)animated
{
    // Auto return to previous screen
    if (_previousVC) {
        [self.revealViewController setFrontViewController:_previousVC];
        [self.revealViewController setFrontViewPosition:FrontViewPositionLeft animated:YES];
        _previousVC = nil;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    [self.revealViewController.frontViewController.view setUserInteractionEnabled:YES];
}

- (void)setColors
{
    self.tableView.backgroundColor = [UIColor kColorTableBackgroundColor];
    self.tableView.separatorColor = [UIColor kColorTableCellSeparator];
}

- (void)setupIcons
{
    self.imageIconExplore.image = [IonIcons imageWithIcon:icon_search
                                              iconColor:[UIColor kColorLabelText]
                                               iconSize:30.0f
                                              imageSize:CGSizeMake(40.0f, 40.0f)];
    self.imageIconTrips.image = [IonIcons imageWithIcon:icon_clipboard
                                              iconColor:[UIColor kColorLabelText]
                                               iconSize:30.0f
                                              imageSize:CGSizeMake(40.0f, 40.0f)];
    self.imageIconProfile.image = [IonIcons imageWithIcon:icon_person
                                                iconColor:[UIColor kColorLabelText]
                                                 iconSize:30.0f
                                                imageSize:CGSizeMake(40.0f, 40.0f)];
    self.imageIconAbout.image = [IonIcons imageWithIcon:icon_information
                                              iconColor:[UIColor kColorLabelText]
                                               iconSize:30.0f
                                              imageSize:CGSizeMake(40.0f, 40.0f)];
    self.imageIconSettings.image = [IonIcons imageWithIcon:icon_gear_b
                                                 iconColor:[UIColor kColorLabelText]
                                                  iconSize:30.0f
                                                 imageSize:CGSizeMake(40.0f, 40.0f)];
}

- (void)updateBadges
{
    TripsDataManager *tripsManager = [TripsDataManager sharedInstance];

    self.tableCellExplore.badgeLeftOffset = 120;
    if (tripsManager.currentTrip) {
        self.tableCellExplore.badge.hidden = NO;
        if (tripsManager.currentTrip.statusValue == TripStatusInProgress) {
            self.tableCellExplore.badgeColor = [UIColor kColorDarkGreen];
        } else {
            self.tableCellExplore.badgeColor = [UIColor kColorTableCellText];
        }
        self.tableCellExplore.badgeString = [NSString stringWithFormat:@"%d / %d", (int)tripsManager.currentTrip.observations.count, (int)tripsManager.currentTrip.occurrenceRecords.count];
    } else {
        self.tableCellExplore.badgeString = nil;
        self.tableCellExplore.badge.hidden = YES;
    }
    
    self.tableCellTrips.badgeLeftOffset = 120;
    if (tripsManager.finishedTrips && tripsManager.finishedTrips.count > 0) {
        self.tableCellTrips.badge.hidden = NO;
        self.tableCellTrips.badgeColor = [UIColor kColorDarkRed];
        self.tableCellTrips.badgeTextColor = [UIColor whiteColor];
        self.tableCellTrips.badgeString = [NSString stringWithFormat:@"%d To Upload", (int)tripsManager.finishedTrips.count];
    } else {
        self.tableCellTrips.badgeString = nil;
        self.tableCellTrips.badge.hidden = YES;
    }
    
    self.tableCellProfile.badgeLeftOffset = 120;
    if ([LoginManager sharedInstance].loggedIn) {
        self.tableCellProfile.badge.hidden = NO;
        self.tableCellProfile.badgeColor = [UIColor kColorDarkGreen];
        self.tableCellProfile.badgeString = @"Logged In";
    } else {
        self.tableCellProfile.badgeColor = [UIColor kColorDarkRed];
        self.tableCellProfile.badgeString = nil;
        self.tableCellProfile.badge.hidden = YES;
    }
    
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // Text Color
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.contentView.backgroundColor = [UIColor colorWithWhite:0.2f alpha:0.8f];
    [header.textLabel setTextColor:[UIColor kColorLabelText]];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DDLogVerbose(@"%s segue:%@", __PRETTY_FUNCTION__, segue.identifier);
    
    if ([segue isKindOfClass:[SWRevealViewControllerSegue class]]) {
        SWRevealViewControllerSegue *swSegue = (SWRevealViewControllerSegue *)segue;
        
        //If Going From Explore Screen to Settings Screen Save Reference To ExploreVC To Automatically Return When Sidebar Next Displayed
        if ([swSegue.identifier isEqualToString:@"OptionsVC"]) {
            UIViewController *exploreVC = [self.viewControllersCache objectForKey:@"ExploreVC"];
            if ((exploreVC == self.revealViewController.frontViewController) || ((self.revealViewController.frontViewController.childViewControllers.count > 0) && (exploreVC == self.revealViewController.frontViewController.childViewControllers[0]))) {
                _previousVC = exploreVC;
            }
        }
        
        swSegue.performBlock = ^(SWRevealViewControllerSegue *rvc_segue, UIViewController *svc, UIViewController *dvc) {
            if (rvc_segue.identifier) {
                UIViewController *cachedVC = [self.viewControllersCache objectForKey:rvc_segue.identifier];
                if (cachedVC != nil) {
                    dvc = cachedVC;
                } else {
                    [self.viewControllersCache setObject:dvc forKey:rvc_segue.identifier];
                }
            }
            //            UINavigationController *navVC = (UINavigationController *)self.revealViewController.frontViewController;
            //            [navVC setViewControllers:@[dvc] animated:NO];
            [self.revealViewController setFrontViewController:dvc];
            [self.revealViewController setFrontViewPosition:FrontViewPositionLeft animated:YES];
        };
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}


@end

//
//  MainViewController.m
//  BioCaching
//
//  Created by Andy Jeffrey on 29/04/2014.
//  Copyright (c) 2014 MPApps.net. All rights reserved.
//

#import "MainViewController.h"
#import "SidebarViewController.h"
#import "ExploreContainerViewController.h"

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (self) {
        [BCOptions sharedInstance];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [TSMessage setDefaultViewController:self.revealViewController];
    
    //Setup Sidebar
    [_sidebarButton addTarget:self.revealViewController action:@selector(revealToggle:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"MainViewController:viewWillAppear");
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
//    NSLog(@"%@:%@ segue=%@", self.class, NSStringFromSelector(_cmd), segue.identifier);
    NSLog(@"%s segue:%@", __PRETTY_FUNCTION__, segue.identifier);
    
    SidebarViewController *sidebarVC = (SidebarViewController*)self.revealViewController.rearViewController;
    if ([segue.identifier isEqualToString:@"ExploreVC"]) {
        UINavigationController *exploreNavVC = segue.destinationViewController;
        
        if (![sidebarVC.viewControllersCache objectForKey:segue.identifier]) {
            [sidebarVC.viewControllersCache setObject:exploreNavVC forKey:segue.identifier];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

    //
//  ExploreMapViewController.m
//  BioCaching
//
//  Created by Andy Jeffrey on 19/02/2014.
//  Copyright (c) 2014 MPApps.net. All rights reserved.
//

#import "ExploreMapViewController.h"
#import "ExploreListViewController.h"
#import "ExploreOptionsViewController.h"
#import "LocationsArray.h"
#import "TripOptions.h"
#import "GBIFCommunicator.h"
#import "GBIFCommunicatorMock.h"
#import "GBIFOccurrenceResults.h"
#import "OccurrenceLocation.h"

#define kDefaultSearchAreaStepperValue 1000
#define kInitialViewSpan 5000

@interface ExploreMapViewController () {
    CLLocationCoordinate2D _currentViewLocation;
    int _currentSearchAreaSpan;
    MKPolygon *_currentSearchAreaPolygon;
    CLLocation *_currentUserLocation;
    bool _followUser;
    bool _annotationSelected;
    TripOptions *_tripOptions;
    GBIFOccurrenceResults *_occurrenceResults;
    DropDownView *dropDownViewLocations;
    UITapGestureRecognizer *singleTapRecognizer, *doubleTapRecognizer;
    BOOL uiControlsDimmed;
    UIView *uiControlsView;
    NSArray *uiControls;
}

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *labelLocationDetails;
@property (weak, nonatomic) IBOutlet UILabel *labelLocationList;
@property (weak, nonatomic) IBOutlet UIButton *buttonLocationList;
@property (weak, nonatomic) IBOutlet UILabel *labelSearchArea;
@property (weak, nonatomic) IBOutlet UIStepper *stepperSearchArea;
@property (weak, nonatomic) IBOutlet UIButton *buttonSearch;
@property (weak, nonatomic) IBOutlet UIButton *buttonList;
@property (weak, nonatomic) IBOutlet UIButton *buttonCurrentLocation;
@property (weak, nonatomic) IBOutlet UIButton *buttonZoom;
@property (weak, nonatomic) IBOutlet UIButton *buttonMapType;
@property (weak, nonatomic) IBOutlet UIButton *buttonOptions;

@end

@implementation ExploreMapViewController

- (void)viewDidLoad
{
//    NSLog(@"viewDidAppear");
    [super viewDidLoad];
    
    uiControlsDimmed = NO;
    [self configureViewsToDisable];

    self.tabBarItem.selectedImage = [UIImage imageNamed:@"tabicon-search-solid"];

    _tripOptions = [TripOptions initWithDefaults];

    self.mapView.showsUserLocation = TRUE;
    _followUser = FALSE;

    self.mapView.mapType = MKMapTypeStandard;
    [self.buttonMapType setTitle:@"MapType: Standard" forState:UIControlStateNormal];

    [self configureSearchAreaStepper:kDefaultSearchAreaStepperValue];
    [self configureSearchManager];
    [self configureLocationDropDown];

    _currentViewLocation = LocationsArray.defaultLocation;
    //    CLLocationCoordinate2D defaultLocation = CLLocationCoordinate2DMake(37.769341, -122.481937);
    [self updateLocationLabelAndMapView:_currentViewLocation];
    [self updateSearchAreaOverlay:_currentViewLocation areaSpan:_currentSearchAreaSpan];

    [self configureGestureRecognizers];
    self.mapView.delegate = self;

    [self performSearch:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
//    NSLog(@"viewDidAppear");
}

- (void)configureViewsToDisable
{
    uiControls = [[NSArray alloc] initWithObjects:
                  self.mapView,
                  self.buttonLocationList,
                  self.stepperSearchArea,
                  self.buttonSearch,
                  self.buttonList,
                  self.buttonCurrentLocation,
                  self.buttonZoom,
                  self.buttonMapType,
                  self.buttonOptions,
                  nil];
}

- (void)dimUIControls:(BOOL)dimEnabled
{
    uiControlsView.hidden = !dimEnabled;
    for (UIControl *uiControl in uiControls) {
        uiControl.userInteractionEnabled = !dimEnabled;
    }
    if (dimEnabled) {
        uiControlsDimmed = dimEnabled;
    }
}

- (void)configureSearchManager
{
    self.gbifManager = [[GBIFManager alloc] init];
    self.gbifManager.delegate = self;
#ifdef USE_MOCK_DATA
    self.gbifManager.communicator = [[GBIFCommunicatorMock alloc] init];
#else
    self.gbifManager.communicator = [[GBIFCommunicator alloc] init];
#endif
    self.gbifManager.communicator.delegate = self.gbifManager;
}

- (void)configureLocationDropDown
{
	dropDownViewLocations = [[DropDownView alloc] initWithArrayData:[LocationsArray displayStringsArray] cellHeight:30 heightTableView:200 paddingTop:0 paddingLeft:0 paddingRight:0 refView:self.buttonLocationList animation:GROW openAnimationDuration:0.2 closeAnimationDuration:0.2];
    [dropDownViewLocations closeAnimation];
    [self.view addSubview:dropDownViewLocations.view];
    
    dropDownViewLocations.delegate = self;
    
    uiControlsView = [[UIView alloc] initWithFrame:self.view.frame];
    uiControlsView.backgroundColor = [UIColor blackColor];
    uiControlsView.alpha = 0.3f;
    [self.view insertSubview:uiControlsView belowSubview:dropDownViewLocations.view];
    uiControlsView.hidden = YES;
    UIGestureRecognizer *uiControlViewTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(uiControlViewClick:)];
    //    singleTapRecognizer.delaysTouchesBegan = YES;
    //    singleTapRecognizer.numberOfTapsRequired = 1;
    [uiControlsView addGestureRecognizer:uiControlViewTapRecognizer];
    
    self.labelLocationList.text = nil;
    [self.labelLocationList setBackgroundColor:[UIColor colorWithPatternImage:[IonIcons imageWithIcon:icon_navicon size:self.labelLocationList.frame.size.width color:[UIColor darkGrayColor]]]];
}

- (void)updateLocationLabelAndMapView:(CLLocationCoordinate2D)location mapViewSpan:(NSInteger)viewSpan
{
    [self updateLocationLabel:location horizAccuracy:0];
    [self updateCurrentMapView:location latitudinalMeters:0 longitudinalMeters:viewSpan];
}

- (void)updateLocationLabelAndMapView:(CLLocationCoordinate2D)location
{
    [self updateLocationLabelAndMapView:location mapViewSpan:kInitialViewSpan];
}

- (void)configureSearchAreaStepper:(int)searchAreaSpan
{
    _currentSearchAreaSpan = searchAreaSpan;
    self.stepperSearchArea.value = log2(_currentSearchAreaSpan/kDefaultSearchAreaStepperValue);
    self.stepperSearchArea.maximumValue = 5;
    self.stepperSearchArea.minimumValue = -5;
    [self updateSearchAreaLabel:self.stepperSearchArea.value];
}

- (void)configureGestureRecognizers
{
    singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapSingleClick:)];
//    singleTapRecognizer.delaysTouchesBegan = YES;
//    singleTapRecognizer.numberOfTapsRequired = 1;
    [self.mapView addGestureRecognizer:singleTapRecognizer];

    doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapDoubleClick:)];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    doubleTapRecognizer.delegate = self;
    [self.mapView addGestureRecognizer:doubleTapRecognizer];
    [singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
    
/*
    UITapGestureRecognizer *doubleTapRecognizer =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapDoubleClick:)];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    doubleTapRecognizer.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:doubleTapRecognizer];
    doubleTapRecognizer.delegate = self;

    singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapSingleClick:)];
    singleTapRecognizer.numberOfTapsRequired = 1;
//    singleTapRecognizer.delaysTouchesEnded = YES;
//    [singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
    [self.view addGestureRecognizer:singleTapRecognizer];
*/
}

- (void)updateLocationLabel:(CLLocationCoordinate2D)location horizAccuracy:(double)accuracy {
    self.labelLocationDetails.text = [NSString stringWithFormat:@"Lat: %f Long: %f Acc: %.1fm",
                                      location.latitude,
                                      location.longitude,
                                      accuracy];
}

- (void)updateSearchAreaStepper:(int)searchAreaSpan
{
    self.stepperSearchArea.value = log2(searchAreaSpan/kDefaultSearchAreaStepperValue);
    [self updateSearchAreaLabel:self.stepperSearchArea.value];
}

- (void)updateSearchAreaLabel:(double)stepperValue
{
    self.labelSearchArea.text = [NSString stringWithFormat:@"Span: %dm", _currentSearchAreaSpan];
}

- (void)updateSearchAreaOverlay:(CLLocationCoordinate2D)location areaSpan:(double)areaSpan
{
    [self updateSearchAreaOverlay:location latitudeSpan:areaSpan/2 longitudeSpan:areaSpan/2];
}

- (void)updateSearchAreaOverlay:(CLLocationCoordinate2D)location latitudeSpan:(double)latSpan longitudeSpan:(double)longSpan
{
    if (_currentSearchAreaPolygon) {
        [self.mapView removeOverlay:_currentSearchAreaPolygon];
    }
    
    MKCoordinateRegion searchRegion = MKCoordinateRegionMakeWithDistance(location, latSpan, longSpan);
    MKCoordinateSpan searchSpan = searchRegion.span;
    CLLocationCoordinate2D searchPolygonCoords[5] = {
        CLLocationCoordinate2DMake(location.latitude - searchSpan.latitudeDelta, location.longitude - searchSpan.longitudeDelta),
        CLLocationCoordinate2DMake(location.latitude - searchSpan.latitudeDelta, location.longitude + searchSpan.longitudeDelta),
        CLLocationCoordinate2DMake(location.latitude + searchSpan.latitudeDelta, location.longitude + searchSpan.longitudeDelta),
        CLLocationCoordinate2DMake(location.latitude + searchSpan.latitudeDelta, location.longitude - searchSpan.longitudeDelta),
        CLLocationCoordinate2DMake(location.latitude - searchSpan.latitudeDelta, location.longitude - searchSpan.longitudeDelta)};
    
    // Polygon (square) area overlay
    _currentSearchAreaPolygon = [MKPolygon polygonWithCoordinates:searchPolygonCoords count:5];
    [self.mapView addOverlay:_currentSearchAreaPolygon];
    NSLog(@"SearchArea: %@", _currentSearchAreaPolygon);

    // Circle area overlay
    //MKCircle *circle = [MKCircle circleWithCenterCoordinate:userLocation.coordinate radius:1000];
    //[mapView addOverlay:circle];
}

- (void)updateOccurrenceAnnotations:(NSArray *)occurrenceResults
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    for (int i = 0; i < _tripOptions.displayPoints && i < occurrenceResults.count; i++) {
        [self addOccurrenceAnnotation:occurrenceResults[i]];
    }
}

- (void)addOccurrenceAnnotation:(GBIFOccurrence *)occurrence
{
    OccurrenceLocation *location = [[OccurrenceLocation alloc] initWithGBIFOccurrence:occurrence];
    [self.mapView addAnnotation:location];
}

- (void)updateCurrentMapView:(CLLocationCoordinate2D)location latitudinalMeters:(NSInteger)latRegionSpan longitudinalMeters:(NSInteger)longRegionSpan
{
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location, latRegionSpan, longRegionSpan);
    NSLog(@"MKCoordinationRegion.span: %.4f, %.4f", region.span.latitudeDelta, region.span.longitudeDelta);
    [self.mapView setRegion:region animated:YES];
}


#pragma mark IBActions
- (IBAction)buttonLocationSelect:(id)sender {
/*
    [self activateUIControls:FALSE];
*/
    NSLog(@"buttonLocationSelect");
    uiControlsView.hidden = NO;
    [dropDownViewLocations openAnimation];
    [dropDownViewLocations.uiTableView flashScrollIndicators];
}


- (IBAction)currentLocation:(id)sender {
    [self updateLocationLabel:_currentUserLocation.coordinate horizAccuracy:_currentUserLocation.horizontalAccuracy];
    [self updateSearchAreaOverlay:_currentUserLocation.coordinate areaSpan:_currentSearchAreaSpan];
    [self updateCurrentMapView:_currentUserLocation.coordinate latitudinalMeters:0 longitudinalMeters:kInitialViewSpan];
}

- (IBAction)searchZoomChanged:(UIStepper *)sender
{
    _currentSearchAreaSpan = kDefaultSearchAreaStepperValue * pow(2, self.stepperSearchArea.value);
    [self updateSearchAreaLabel:sender.value];
    [self updateSearchAreaOverlay:_currentSearchAreaPolygon.coordinate areaSpan:_currentSearchAreaSpan];
}

- (IBAction)zoomToLocation:(id)sender {
    [self updateCurrentMapView:_currentSearchAreaPolygon.coordinate latitudinalMeters:_currentSearchAreaSpan longitudinalMeters:_currentSearchAreaSpan];
}

- (IBAction)performSearch:(id)sender
{
    _tripOptions.searchAreaSpan = _currentSearchAreaSpan;
    _tripOptions.searchAreaPolygon = _currentSearchAreaPolygon;
    _tripOptions.searchAreaCentre = _currentSearchAreaPolygon.coordinate;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
//    [self.gbifManager fetchOccurrencesWithinArea:_currentSearchAreaPolygon];
    [self.gbifManager fetchOccurrencesWithOptions:_tripOptions];
}

- (IBAction)changeMapType:(id)sender
{
    NSString *mapType = @"MapType: %@";
    
    switch (self.mapView.mapType) {
        case MKMapTypeStandard:
            [self.mapView setMapType:MKMapTypeSatellite];
            [self.buttonMapType setTitle:[NSString stringWithFormat:mapType, @"Satellite"] forState:UIControlStateNormal];
            break;
            
        case MKMapTypeSatellite:
            [self.mapView setMapType:MKMapTypeHybrid];
            [self.buttonMapType setTitle:[NSString stringWithFormat:mapType, @"Hybrid"] forState:UIControlStateNormal];
            break;

        default:
            [self.mapView setMapType:MKMapTypeStandard];
            [self.buttonMapType setTitle:[NSString stringWithFormat:mapType, @"Standard"] forState:UIControlStateNormal];
            break;
    }
}


#pragma mark MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    _currentUserLocation = userLocation.location;
    
    if (_followUser) {
        [self.mapView setCenterCoordinate:userLocation.coordinate animated:TRUE];
        [self updateSearchAreaOverlay:userLocation.coordinate areaSpan:_currentSearchAreaSpan];
    }

    /*
    MKCoordinateRegion region =
    MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 0, 5000);
    NSLog(@"MKCoordinationRegion.span: %.4f, %.4f", region.span.latitudeDelta, region.span.longitudeDelta);
    [self.mapView setRegion:region animated:YES];
    
    [self updateSearchAreaOverlay:userLocation.coordinate latitudeSpan:_currentSearchAreaSize longitudeSpan:_currentSearchAreaSize];
     */
}

- (MKOverlayView *)mapView:(MKMapView *)map viewForOverlay:(id <MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKCircle class]]) {
        MKCircleView *circleView = [[MKCircleView alloc] initWithOverlay:overlay];
        circleView.strokeColor = [UIColor grayColor];
        circleView.lineWidth = 2.0;
        [circleView setLineDashPattern:@[@10, @10]];
        circleView.fillColor = [[UIColor grayColor] colorWithAlphaComponent:0.2];
        return circleView;
    }
    else if ([overlay isKindOfClass:[MKPolygon class]]) {
        MKPolygonView *polygonView = [[MKPolygonView alloc] initWithOverlay:overlay];
        polygonView.strokeColor = [UIColor redColor];
        polygonView.lineWidth = 2.0;
        [polygonView setLineDashPattern:@[@10, @10]];
        polygonView.fillColor = [[UIColor redColor] colorWithAlphaComponent:0.2];
        return polygonView;
    }
    return nil;
}


- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    NSLog(@"regionDidChangeAnimated");
    [self updateLocationLabel:mapView.centerCoordinate horizAccuracy:0];
//    singleTapRecognizer.cancelsTouchesInView = NO;
    
//    uiControlsDimmed = NO;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    static NSString *identifier = @"OccurrenceLocation";
    if ([annotation isKindOfClass:[OccurrenceLocation class]]) {
/*
        MKPinAnnotationView *annotationView = (MKPinAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (!annotationView) {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            annotationView.pinColor = MKPinAnnotationColorRed;
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            annotationView.animatesDrop = YES;
*/
        MKAnnotationView *annotationView = (MKAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier:@"OccurrenceLocation"];
        if (!annotationView) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            annotationView.image = [UIImage imageNamed:((OccurrenceLocation *)annotation).mapMarkerImageFile];
        } else {
            annotationView.image = [UIImage imageNamed:((OccurrenceLocation *)annotation).mapMarkerImageFile];
            annotationView.annotation = annotation;
        }
        
        return annotationView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    NSLog(@"didSelectAnnotationView");
    _annotationSelected = TRUE;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    NSLog(@"calloutAccessoryControlTapped");
}

#pragma mark UIGestureRecognizer Methods

- (void)mapSingleClick:(UIGestureRecognizer *)gestureRecognizer
{
    NSLog(@"SingleClick, dropDownViewVisible:%@", !dropDownViewLocations.view.hidden ? @"YES" : @"NO");
    
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded)
        return;
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.view];
    UIView *selectedView = [self.view hitTest:touchPoint withEvent:nil];
    
    if ([selectedView isKindOfClass:[MKAnnotationView class]]) {
        NSLog(@"AnnotationView selected");
        return;
    }
    
    CLLocationCoordinate2D mapCoord = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    [self.mapView setCenterCoordinate:mapCoord animated:YES];
    [self updateSearchAreaOverlay:mapCoord areaSpan:_currentSearchAreaSpan];
    
}

- (void)mapDoubleClick:(UIGestureRecognizer *)gestureRecognizer
{
    NSLog(@"DoubleClick");
}

- (void)uiControlViewClick:(UIGestureRecognizer *)gestureRecognizer
{
    NSLog(@"uiControlViewClick");
    [dropDownViewLocations closeAnimation];
    uiControlsView.hidden = YES;
}

#pragma mark UIGestureRecognizerDelegate

/*
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    NSLog(@"shouldReceiveTouch: %@", [touch.view class]);
    return (![touch.view isDescendantOfView:dropDownViewLocations.view]);
}
*/

- (BOOL)shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)gr
{
    return TRUE;
}


#pragma mark ExploreOptionsDelegate
- (void)saveOptions:(TripOptions *)savedTripOptions
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateOccurrenceAnnotations:_occurrenceResults.Results];
    });
    
//    _tripOptions = savedTripOptions;
}

#pragma mark GBIFManagerDelegate

- (void)didReceiveOccurences:(GBIFOccurrenceResults *)occurrenceResults
{
    NSLog(@"ExploreMapViewController didReceiveOccurences: %lu", (unsigned long)occurrenceResults.Results.count);
    _occurrenceResults = occurrenceResults;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateOccurrenceAnnotations:occurrenceResults.Results];
        [self zoomToLocation:nil];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    });
}

- (void)fetchingResultsFailedWithError:(NSError *)error
{
    NSLog(@"Error %@; %@", error, [error localizedDescription]);
}


#pragma mark UIStoryboard Methods
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ExploreListSegue"]) {
        ExploreListViewController *vc = [segue destinationViewController];
        [vc setSearchAreaCenter:_currentSearchAreaPolygon.coordinate];
        [vc setSearchAreaSpan:_currentSearchAreaSpan];
        [vc setOccurenceResults:_occurrenceResults];
    }
    else if ([segue.identifier isEqualToString:@"ExploreOptionsSegue"]) {
        ExploreOptionsViewController *optionsVC = [segue destinationViewController];
        optionsVC.delegate = self;
        optionsVC.tripOptions = _tripOptions;
    }
}

#pragma mark DropDownViewDelegate
-(void)dropDownCellSelected:(NSInteger)returnIndex
{
    _currentViewLocation = [LocationsArray locationCoordinate:returnIndex];
    _currentSearchAreaSpan = [LocationsArray locationSearchAreaSpan:returnIndex];
    [self updateLocationLabelAndMapView:_currentViewLocation mapViewSpan:[LocationsArray locationViewSpan:returnIndex]];
    [self updateSearchAreaStepper:_currentSearchAreaSpan];
    [self updateSearchAreaOverlay:_currentViewLocation areaSpan:_currentSearchAreaSpan];
//    [self dimUIControls:NO];
    uiControlsView.hidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

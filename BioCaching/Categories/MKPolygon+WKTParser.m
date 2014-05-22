//
//  MKPolygon+WKTParser.m
//  BioCaching
//
//  Created by Andy Jeffrey on 07/03/2014.
//  Copyright (c) 2014 MPApps.net. All rights reserved.
//

#import "MKPolygon+WKTParser.h"

@implementation MKPolygon (WKTParser)

- (NSString *)convertToWKT
{
    NSString *wktPolygonFormat = @"POLYGON((%@))";
    NSMutableString *wktPoints = [NSMutableString string];
    
    for (int i = 0; i < self.pointCount; i++) {
        CLLocationCoordinate2D coord = MKCoordinateForMapPoint(self.points[i]);
        if (i > 0) {
            [wktPoints appendString:@","];
        }
        [wktPoints appendFormat:@"%f%%20%f", coord.longitude, coord.latitude];
        //NSLog(@"MKPolygon.convertToWKT: %f %f", coord.longitude, coord.latitude);
    }
    
    NSString *wktPolygon = [NSString stringWithFormat:wktPolygonFormat, wktPoints];
    NSLog(@"MKPolygon.convertToWKT: %@", wktPolygon);
    
    return wktPolygon;
}

- (NSString *)description
{
    NSMutableString *descString = [NSMutableString string];
    
    for (int i = 0; i < self.pointCount; i++) {
        CLLocationCoordinate2D coord = MKCoordinateForMapPoint(self.points[i]);
        [descString appendFormat:@"%f,%f ", coord.latitude, coord.longitude];
    }
    
    return descString;
}

+ (MKPolygon *)approximatedPolygonFromCircle:(MKCircle *)circle count:(NSUInteger)numberOfPoints
{
    
    for (int i = 0; i <= numberOfPoints; i++) {
        
    }

    return nil;
//    return [MKPolygon polygonWithCoordinates:<#(CLLocationCoordinate2D *)#> count:<#(NSUInteger)#>
}

@end
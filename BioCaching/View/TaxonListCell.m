//
//  TaxonListCell.m
//  BioCaching
//
//  Created by Andy Jeffrey on 08/05/2014.
//  Copyright (c) 2014 MPApps.net. All rights reserved.
//

#import "TaxonListCell.h"

@implementation TaxonListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self.buttonAction setTitleColor:[UIColor kColorButtonLabel] forState:UIControlStateNormal];
    }
    
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)performAction:(id)sender {
    [self.delegate actionButtonSelected:self];
}
@end

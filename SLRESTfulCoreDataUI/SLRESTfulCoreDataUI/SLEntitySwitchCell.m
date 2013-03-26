//
//  SLEntitySwitchCell.m
//  iCuisineAPI
//
//  Created by Oliver Letterer on 25.03.13.
//  Copyright 2013 SparrowLabs. All rights reserved.
//

#import "SLEntitySwitchCell.h"



@interface SLEntitySwitchCell () {
    
}

@end



@implementation SLEntitySwitchCell

#pragma mark - Initialization

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier 
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        _switchControl = [[UISwitch alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:_switchControl];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

#pragma mark - UITableViewCell

//- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
//{
//    [super setSelected:selected animated:animated];
//
//}

//- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated 
//{
//    [super setHighlighted:highlighted animated:animated];
//    
//}

- (void)layoutSubviews 
{
    [super layoutSubviews];
    
    CGRect bounds = self.contentView.bounds;
    
    [self.switchControl sizeToFit];
    self.switchControl.frame = CGRectMake(CGRectGetWidth(bounds) - 8.0f - CGRectGetWidth(self.switchControl.frame),
                                   CGRectGetMidY(self.textLabel.frame) - CGRectGetHeight(self.switchControl.frame) / 2.0f,
                                   CGRectGetWidth(self.switchControl.frame),
                                   CGRectGetHeight(self.switchControl.frame));
    
//    self.switchControl.center = CGPointMake(floorf(self.switchControl.center.x), floorf(self.switchControl.center.y));
}

//- (void)prepareForReuse 
//{
//    [super prepareForReuse];
//    
//}

#pragma mark - Memory management

- (void)dealloc
{
    
}

#pragma mark - Private category implementation ()

@end

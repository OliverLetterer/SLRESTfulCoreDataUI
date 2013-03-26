//
//  SLEntityTextFieldCell.m
//  iCuisineAPI
//
//  Created by Oliver Letterer on 25.03.13.
//  Copyright 2013 SparrowLabs. All rights reserved.
//

#import "SLEntityTextFieldCell.h"



@interface SLEntityTextFieldCell () {
    
}

@end



@implementation SLEntityTextFieldCell

#pragma mark - Initialization

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        _textField = [[UITextField alloc] initWithFrame:CGRectZero];
        _textField.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:_textField];
        
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
    
    [self.textLabel sizeToFit];
    CGPoint center = self.textLabel.center;
    center.y = CGRectGetMidY(self.contentView.bounds);
    self.textLabel.center = center;
    
    self.textField.frame = CGRectMake(CGRectGetMaxX(self.textLabel.frame) + 8.0f, 8.0f,
                                      CGRectGetWidth(self.contentView.bounds) - CGRectGetMaxX(self.textLabel.frame) - 16.0f, CGRectGetHeight(self.contentView.bounds) - 16.0f);
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

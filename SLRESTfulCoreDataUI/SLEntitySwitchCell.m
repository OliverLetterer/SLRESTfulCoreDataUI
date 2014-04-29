//
//  SLEntitySwitchCell.m
//
//  The MIT License (MIT)
//  Copyright (c) 2013-2014 Oliver Letterer, Sparrow-Labs
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "SLEntitySwitchCell.h"

@implementation SLEntitySwitchCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        _switchControl = [[UISwitch alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:_switchControl];

        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect bounds = self.contentView.bounds;

    [self.switchControl sizeToFit];
    self.switchControl.frame = CGRectMake(CGRectGetWidth(bounds) - 14.0 - CGRectGetWidth(self.switchControl.frame),
                                          CGRectGetMidY(bounds) - CGRectGetHeight(self.switchControl.frame) / 2.0,
                                          CGRectGetWidth(self.switchControl.frame),
                                          CGRectGetHeight(self.switchControl.frame));

    if (CGRectGetMaxX(self.textLabel.frame) > CGRectGetMinX(self.switchControl.frame) - 7.0) {
        CGFloat overlap = CGRectGetMinX(self.switchControl.frame) - 7.0 - CGRectGetMaxX(self.textLabel.frame);
        self.textLabel.frame = UIEdgeInsetsInsetRect(self.textLabel.frame, UIEdgeInsetsMake(0.0, 0.0, 0.0, - overlap));
    }

    if (CGRectGetMaxX(self.detailTextLabel.frame) > CGRectGetMinX(self.switchControl.frame) - 7.0) {
        CGFloat availableWidth = CGRectGetMinX(self.switchControl.frame) - 7.0 - CGRectGetMinX(self.detailTextLabel.frame);
        CGFloat availableHeight = CGRectGetHeight(bounds) - CGRectGetMinY(self.detailTextLabel.frame) - 7.0;

        CGSize size = [self.detailTextLabel sizeThatFits:CGSizeMake(availableWidth, availableHeight)];

        CGRect frame = self.detailTextLabel.frame;
        frame.size = size;
        self.detailTextLabel.frame = frame;
    }
}

@end

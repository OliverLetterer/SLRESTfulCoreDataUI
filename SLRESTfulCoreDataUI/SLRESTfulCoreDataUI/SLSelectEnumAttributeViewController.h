//
//  SLSelectEnumAttributeViewController.h
//  iCuisineAPI
//
//  Created by Oliver Letterer on 12.04.13.
//  Copyright 2013 SparrowLabs. All rights reserved.
//

@class SLSelectEnumAttributeViewController;



/**
 @abstract  <#abstract comment#>
 */
@protocol SLSelectEnumAttributeViewControllerDelegate <NSObject>

- (void)selectEnumAttributeViewController:(SLSelectEnumAttributeViewController *)viewController didSelectEnumValue:(id)enumValue;

@end



/**
 @abstract  <#abstract comment#>
 */
@interface SLSelectEnumAttributeViewController : UITableViewController <UIViewControllerRestoration, UIDataSourceModelAssociation>

@property (nonatomic, weak) id<SLSelectEnumAttributeViewControllerDelegate> delegate;
@property (nonatomic, readonly) NSArray *options;
@property (nonatomic, readonly) NSArray *values;
@property (nonatomic, readonly) id currentValue;

- (id)initWithOptions:(NSArray *)options values:(NSArray *)values currentValue:(id)currentValue;

@end

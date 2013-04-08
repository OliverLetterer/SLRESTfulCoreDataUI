//
//  SLEntityViewController.h
//  iCuisineAPI
//
//  Created by Oliver Letterer on 18.03.13.
//  Copyright 2013 SparrowLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef NS_ENUM(NSUInteger, SLEntityViewControllerEditingType) {
    SLEntityViewControllerEditingTypeCreate = 0,
    SLEntityViewControllerEditingTypeEdit
};



/**
 @abstract  <#abstract comment#>
 */
@interface SLEntityViewController : UITableViewController <UIViewControllerRestoration, UIDataSourceModelAssociation>

@property (nonatomic, readonly) SLEntityViewControllerEditingType editingType;

@property (nonatomic, readonly) id entity;

@property (nonatomic, copy) void(^completionHandler)(BOOL didSaveEntity);

/**
 key: name of the property
 value: string which will be displayed to the user for this property
 */
@property (nonatomic, strong) NSDictionary *propertyMapping;
@property (nonatomic, strong) NSArray *properties;

/**
 managing keyboard types for attributes
 */
- (void)setKeyboardType:(UIKeyboardType)keyboardType forAttribute:(NSString *)attribute;
- (UIKeyboardType)keyboardTypeForAttribute:(NSString *)attribute;

- (void)applyStringValue:(NSString *)value forAttribute:(NSString *)attribute;
- (NSString *)stringValueForAttribute:(NSString *)attribute;

/**
 Registera custom view controller class which conforms to `SLSelectEntityAttributeViewControllerProtocol`. An instance of this class will be pushed if the corresponding cell has been selected.
 */
- (void)setViewControllerClass:(Class)viewControllerClass forAttribute:(NSString *)attribute;
- (Class)viewControllerClassForAttribute:(NSString *)attribute;

/**
 Configuring selection of relationships. fetchedResultsController will be used to display possible entities for the given relationship. nameKeyPath will be used as the name for each relationship entity.
 */
- (void)setFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController forRelationship:(NSString *)relationship;
- (NSFetchedResultsController *)fetchedResultsControllerForRelationship:(NSString *)relationship;

- (void)setNameKeyPath:(NSString *)nameKeyPath forRelationship:(NSString *)relationship;
- (NSString *)nameKeyPathForRelationship:(NSString *)relationship;

- (id)initWithEntity:(NSManagedObject *)entity editingType:(SLEntityViewControllerEditingType)editingType;

- (UITableViewCell *)tableView:(UITableView *)tableView cellForAttributeDescription:(NSAttributeDescription *)attributeDescription atIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRelationshipDescription:(NSAttributeDescription *)attributeDescription atIndexPath:(NSIndexPath *)indexPath;

@end

//
//  SLEntityViewController.h
//
//  The MIT License (MIT)
//  Copyright (c) 2013 Oliver Letterer, Sparrow-Labs
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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

@class SLEntityTextFieldCell;

typedef NS_ENUM(NSUInteger, SLEntityViewControllerEditingType) {
    SLEntityViewControllerEditingTypeCreate = 0,
    SLEntityViewControllerEditingTypeEdit
};



@interface SLEntityViewControllerSection : NSObject

@property (nonatomic, copy) NSString *titleText;
@property (nonatomic, copy) NSString *footerText;

+ (instancetype)staticSectionWithProperties:(NSArray *)properties;

+ (instancetype)dynamicEntityWithRelationship:(NSString *)relationship
                     fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController
                                  formatBlock:(NSString *(^)(id entity))formatBlock;

@end



/**
 @abstract  <#abstract comment#>
 */
@interface SLEntityViewController : UITableViewController <UIViewControllerRestoration, UIDataSourceModelAssociation, UITextFieldDelegate>

@property (nonatomic, readonly) SLEntityViewControllerEditingType editingType;

@property (nonatomic, strong) id entity;

@property (nonatomic, copy) void(^completionHandler)(BOOL didSaveEntity);

/**
 key: name of the property
 value: string which will be displayed to the user for this property
 */
@property (nonatomic, strong) NSDictionary *propertyMapping;
@property (nonatomic, copy) NSArray *sections;

/**
 managing keyboard types for attributes
 */
- (void)setKeyboardType:(UIKeyboardType)keyboardType forAttribute:(NSString *)attribute;
- (UIKeyboardType)keyboardTypeForAttribute:(NSString *)attribute;

- (void)applyStringValue:(NSString *)value forAttribute:(NSString *)attribute;
- (NSString *)stringValueForAttribute:(NSString *)attribute;

- (void)configureTextFieldCell:(SLEntityTextFieldCell *)textFieldCell forAttribute:(NSString *)attribute;

/**
 Registera custom view controller class which conforms to `SLSelectEntityAttributeViewControllerProtocol`. An instance of this class will be pushed if the corresponding cell has been selected.
 */
- (void)setViewControllerClass:(Class)viewControllerClass forAttribute:(NSString *)attribute;
- (Class)viewControllerClassForAttribute:(NSString *)attribute;

/**
 If the user should only select an attribute from a distinct set of values. User will select `options` with corresponding index value if `enumValues`.
 */
- (void)setEnumValues:(NSArray *)enumValues withOptions:(NSArray *)options forAttribute:(NSString *)attribute;
- (NSArray *)enumValuesForAttribute:(NSString *)attribute;
- (NSArray *)enumOptionsForAttribute:(NSString *)attribute;

/**
 These predicated determine, if a given attribute should be displayed.
 */
- (void)onlyShowAttribute:(NSString *)attribute whenPredicateEvaluates:(NSPredicate *)predicate;
- (NSPredicate *)predicateForAttribute:(NSString *)attribute;

/**
 Configuring selection of relationships. fetchedResultsController will be used to display possible entities for the given relationship. nameKeyPath will be used as the name for each relationship entity.
 */
- (void)setFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController forRelationship:(NSString *)relationship;
- (NSFetchedResultsController *)fetchedResultsControllerForRelationship:(NSString *)relationship;

- (void)setNameKeyPath:(NSString *)nameKeyPath forRelationship:(NSString *)relationship;
- (NSString *)nameKeyPathForRelationship:(NSString *)relationship;

- (id)initWithEntity:(NSManagedObject *)entity editingType:(SLEntityViewControllerEditingType)editingType;

- (UITableViewCell *)tableView:(UITableView *)tableView cellForAttributeDescription:(NSAttributeDescription *)attributeDescription atIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRelationshipDescription:(NSRelationshipDescription *)attributeDescription atIndexPath:(NSIndexPath *)indexPath;

- (NSString *)propertyNameForTextField:(UITextField *)textField;

- (NSString *)propertyForIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForProperty:(NSString *)property;

/**
 Configuring, if a property is editable or readonly.
 */
- (BOOL)canEditProperty:(NSString *)property;

@property (nonatomic, readonly) UIBarButtonItem *activityIndicatorBarButtonItem;
- (void)cancelButtonClicked:(UIBarButtonItem *)sender;
- (void)saveButtonClicked:(UIBarButtonItem *)sender;

@end

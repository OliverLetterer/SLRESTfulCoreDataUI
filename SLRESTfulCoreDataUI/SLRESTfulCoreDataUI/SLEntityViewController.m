//
//  SLEntityViewController.m
//  iCuisineAPI
//
//  Created by Oliver Letterer on 18.03.13.
//  Copyright 2013 SparrowLabs. All rights reserved.
//

#import "SLEntityViewController.h"
#import "SLRESTfulCoreData.h"
#import "SLEntityTextFieldCell.h"
#import "SLEntitySwitchCell.h"
#import "SLSelectEntityAttributeViewControllerProtocol.h"
#import "SLSelectRelationshipEntityViewController.h"
#import <objc/runtime.h>
#import <objc/message.h>

char *const SLEntityViewControllerAttributeDescriptionKey;



@interface SLEntityViewController () {
    NSManagedObject *_entity;
}

@property (nonatomic, readonly) UIBarButtonItem *activityIndicatorBarButtonItem;

@property (nonatomic, strong) NSArray *properties;

@property (nonatomic, strong) NSMutableDictionary *keyboardTypes;
@property (nonatomic, strong) NSMutableDictionary *viewControllerClasses;
@property (nonatomic, strong) NSMutableDictionary *fetchedResultsControllers;
@property (nonatomic, strong) NSMutableDictionary *relationshipNameKeyPaths;

@property (nonatomic, strong) NSEntityDescription *entityDescription;
@property (nonatomic, strong) NSDictionary *propertyDescriptions;

@end



@implementation SLEntityViewController

#pragma mark - setters and getters

- (UIBarButtonItem *)activityIndicatorBarButtonItem
{
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activityIndicatorView startAnimating];
    
    return [[UIBarButtonItem alloc] initWithCustomView:activityIndicatorView];
}

- (NSMutableDictionary *)viewControllerClasses
{
    if (!_viewControllerClasses) {
        _viewControllerClasses = [NSMutableDictionary dictionary];
    }
    
    return _viewControllerClasses;
}

- (NSMutableDictionary *)fetchedResultsControllers
{
    if (!_fetchedResultsControllers) {
        _fetchedResultsControllers = [NSMutableDictionary dictionary];
    }
    
    return _fetchedResultsControllers;
}

- (NSMutableDictionary *)relationshipNameKeyPaths
{
    if (!_relationshipNameKeyPaths) {
        _relationshipNameKeyPaths = [NSMutableDictionary dictionary];
    }
    
    return _relationshipNameKeyPaths;
}

- (NSMutableDictionary *)keyboardTypes
{
    if (!_keyboardTypes) {
        _keyboardTypes = [NSMutableDictionary dictionary];
    }
    
    return _keyboardTypes;
}

- (void)setProperties:(NSArray *)properties
{
    if (properties != _properties) {
        _properties = properties;
        
        NSMutableDictionary *propertyDescriptions = [NSMutableDictionary dictionaryWithCapacity:_properties.count];
        
        for (NSString *propertyName in _properties) {
            NSPropertyDescription *propertyDescription = self.entityDescription.attributesByName[propertyName] ?: self.entityDescription.relationshipsByName[propertyName];
            NSAssert(propertyDescription != nil, @"propertyDescription for key %@ cannot be nil", propertyName);
            
            propertyDescriptions[propertyName] = propertyDescription;
        }
        
        self.propertyDescriptions = propertyDescriptions;
        
        [self.tableView reloadData];
    }
}

- (void)setPropertyMapping:(NSDictionary *)propertyMapping
{
    if (propertyMapping != _propertyMapping) {
        _propertyMapping = propertyMapping;
        
        self.properties = [_propertyMapping.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSString *value1 = _propertyMapping[obj1];
            NSString *value2 = _propertyMapping[obj2];
            
            return [value1 caseInsensitiveCompare:value2];
        }];
    }
}

#pragma mark - Initialization

- (id)initWithEntity:(NSManagedObject *)entity editingType:(SLEntityViewControllerEditingType)editingType
{
    NSParameterAssert(entity);
    
    if (self = [self initWithStyle:UITableViewStylePlain]) {
        _entity = entity;
        _editingType = editingType;
        
        self.entityDescription = [NSEntityDescription entityForName:NSStringFromClass(entity.class)
                                             inManagedObjectContext:entity.managedObjectContext];
        NSParameterAssert(self.entityDescription);
        
        self.properties = @[];
        self.title = _editingType == SLEntityViewControllerEditingTypeCreate ? NSLocalizedString(@"Create", @"") : NSLocalizedString(@"Edit", @"");
        
        self.contentSizeForViewInPopover = CGSizeMake(320.0f, 480.0f);
        self.modalInPopover = YES;
        
        if ([self respondsToSelector:@selector(setRestorationIdentifier:)]) {
            self.restorationIdentifier = NSStringFromClass(self.class);
            self.restorationClass = self.class;
        }
    }
    return self;
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

#pragma mark - View lifecycle

//- (void)loadView
//{
//    [super loadView];
//
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(_cancelButtonClicked:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(_saveButtonClicked:)];
    
    if ([self.tableView respondsToSelector:@selector(setRestorationIdentifier:)]) {
        self.tableView.restorationIdentifier = NSStringFromClass(self.tableView.class);
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    }
}

- (NSUInteger)supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.properties.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id propertyDescription = self.propertyDescriptions[self.properties[indexPath.row]];
    if ([propertyDescription isKindOfClass:[NSAttributeDescription class]]) {
        return [self tableView:tableView cellForAttributeDescription:propertyDescription atIndexPath:indexPath];
    } else if ([propertyDescription isKindOfClass:[NSRelationshipDescription class]]) {
        return [self tableView:tableView cellForRelationshipDescription:propertyDescription atIndexPath:indexPath];
    }
    
    NSAssert(NO, @"propertyDescription %@ is not supported", propertyDescription);
    return nil;
}

// Override to support conditional editing of the table view.
//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    // Return NO if you do not want the specified item to be editable.
//    return YES;
//}

// Override to support editing the table view.
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        // Delete the row from the data source
//        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
//    }
//    else if (editingStyle == UITableViewCellEditingStyleInsert) {
//        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//    }
//}

// Override to support rearranging the table view.
//- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
//{
//
//}

// Override to support conditional rearranging of the table view.
//- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    // Return NO if you do not want the item to be re-orderable.
//    return YES;
//}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id propertyDescription = self.propertyDescriptions[self.properties[indexPath.row]];
    if ([propertyDescription isKindOfClass:[NSAttributeDescription class]]) {
        NSAttributeDescription *attributeDescription = propertyDescription;
        Class viewControllerClass = [self viewControllerClassForAttribute:attributeDescription.name];
        
        if (viewControllerClass) {
            UIViewController<SLSelectEntityAttributeViewControllerProtocol> *viewController = [[viewControllerClass alloc] initWithEntity:self.entity attribute:attributeDescription.name];
            [self.navigationController pushViewController:viewController animated:YES];
            return;
        }
    } else if ([propertyDescription isKindOfClass:[NSRelationshipDescription class]]) {
        NSRelationshipDescription *relationshipDescription = propertyDescription;
        NSFetchedResultsController *fetchedResultsController = [self fetchedResultsControllerForRelationship:relationshipDescription.name];
        NSString *nameKeyPath = [self nameKeyPathForRelationship:relationshipDescription.name];
        
        SLSelectRelationshipEntityViewController *viewController = [[SLSelectRelationshipEntityViewController alloc] initWithFetchedResultsController:fetchedResultsController
                                                                                                                              relationshipDescription:relationshipDescription
                                                                                                                                               entity:self.entity
                                                                                                                                       keyPathForName:nameKeyPath];
        viewController.title = self.propertyMapping[relationshipDescription.name];
        [self.navigationController pushViewController:viewController animated:YES];
        return;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Instance methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForAttributeDescription:(NSAttributeDescription *)attributeDescription atIndexPath:(NSIndexPath *)indexPath
{
    NSString *firstLetter = [attributeDescription.name substringToIndex:1];
    NSString *restString = [attributeDescription.name substringFromIndex:1];
    
    NSString *selectorName = [NSString stringWithFormat:@"tableView:cellFor%@%@AtIndexPath:", firstLetter.uppercaseString, restString];
    SEL selector = NSSelectorFromString(selectorName);
    
    if ([self respondsToSelector:selector]) {
        return objc_msgSend(self, selector, tableView, indexPath);
    }
    
    static NSArray *textFieldAttributes = nil;
    if (!textFieldAttributes) {
        textFieldAttributes = @[
                                @(NSStringAttributeType),
                                @(NSInteger16AttributeType),
                                @(NSInteger32AttributeType),
                                @(NSInteger64AttributeType),
                                @(NSDecimalAttributeType),
                                @(NSDoubleAttributeType),
                                @(NSFloatAttributeType),
                                @(NSDateAttributeType)
                                ];
    }
    
    BOOL useTextFieldCell = [textFieldAttributes containsObject:@(attributeDescription.attributeType)];
    
    if (useTextFieldCell) {
        static NSString *CellIdentifier = @"SLEntityTextFieldCell";
        
        SLEntityTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[SLEntityTextFieldCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
            
            [cell.textField addTarget:self action:@selector(_textFieldEditingChanged:) forControlEvents:UIControlEventEditingChanged];
        }
        
        cell.textLabel.text = self.propertyMapping[attributeDescription.name];
        
        objc_setAssociatedObject(cell.textField, &SLEntityViewControllerAttributeDescriptionKey,
                                 attributeDescription, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        cell.textField.text = [self stringValueForAttribute:attributeDescription.name];
        cell.textField.placeholder = cell.textLabel.text;
        cell.textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        cell.textField.keyboardType = [self keyboardTypeForAttribute:attributeDescription.name];
        cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        
        if (attributeDescription.attributeType == NSDateAttributeType) {
            UIDatePicker *datePicker = [[UIDatePicker alloc] init];
            datePicker.datePickerMode = UIDatePickerModeDateAndTime;
            
            cell.textField.inputAccessoryView = datePicker;
        } else {
            cell.textField.inputAccessoryView = nil;
        }
        
        return cell;
    }
    
    if (attributeDescription.attributeType == NSBooleanAttributeType) {
        static NSString *CellIdentifier = @"SLEntitySwitchCell";
        
        SLEntitySwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[SLEntitySwitchCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
            
            [cell.switchControl addTarget:self action:@selector(_switchValueChanged:) forControlEvents:UIControlEventValueChanged];
        }
        
        cell.textLabel.text = self.propertyMapping[attributeDescription.name];
        cell.switchControl.on = [[self.entity valueForKey:attributeDescription.name] boolValue];
        objc_setAssociatedObject(cell.switchControl, &SLEntityViewControllerAttributeDescriptionKey,
                                 attributeDescription, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        return cell;
    }
    
    NSAssert(NO, @"attribute %@ is not supported by SLEntityViewController", attributeDescription);
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRelationshipDescription:(NSRelationshipDescription *)relationshipDescription atIndexPath:(NSIndexPath *)indexPath
{
    NSString *firstLetter = [relationshipDescription.name substringToIndex:1];
    NSString *restString = [relationshipDescription.name substringFromIndex:1];
    
    NSString *selectorName = [NSString stringWithFormat:@"tableView:cellFor%@%@AtIndexPath:", firstLetter.uppercaseString, restString];
    SEL selector = NSSelectorFromString(selectorName);
    
    if ([self respondsToSelector:selector]) {
        return objc_msgSend(self, selector, tableView, indexPath);
    }
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    NSString *nameKeyPath = [self nameKeyPathForRelationship:relationshipDescription.name];
    
    cell.textLabel.text = self.propertyMapping[relationshipDescription.name];
    cell.detailTextLabel.text = [[self.entity valueForKey:relationshipDescription.name] valueForKey:nameKeyPath];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - Instance methods

- (void)setKeyboardType:(UIKeyboardType)keyboardType forAttribute:(NSString *)attribute
{
    self.keyboardTypes[attribute] = @(keyboardType);
}

- (UIKeyboardType)keyboardTypeForAttribute:(NSString *)attribute
{
    NSNumber *registeredKeyboardType = self.keyboardTypes[attribute];
    
    if (registeredKeyboardType) {
        return registeredKeyboardType.integerValue;
    }
    
    if ([attribute isEqualToString:@"price"]) {
        DLog(@"");
    }
    
    NSAttributeDescription *attributeDescription = self.propertyDescriptions[attribute];

    switch (attributeDescription.attributeType) {
        case NSStringAttributeType:
            return UIKeyboardTypeAlphabet;
            break;
        case NSInteger16AttributeType:
        case NSInteger32AttributeType:
        case NSInteger64AttributeType:
            return UIKeyboardTypeNumberPad;
            break;
        case NSDoubleAttributeType:
        case NSFloatAttributeType:
        case NSDecimalAttributeType:
            return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? UIKeyboardTypeDecimalPad : UIKeyboardTypeNumbersAndPunctuation;
            break;
        default:
            break;
    }
    
    return UIKeyboardTypeAlphabet;
}

- (void)applyStringValue:(NSString *)value forAttribute:(NSString *)attribute
{
    NSAttributeDescription *attributeDescription = self.propertyDescriptions[attribute];
    
    switch (attributeDescription.attributeType) {
        case NSStringAttributeType:
            [self.entity setValue:value forKey:attribute];
            break;
        case NSInteger16AttributeType:
            [self.entity setValue:@(value.integerValue) forKey:attribute];
            break;
        case NSInteger32AttributeType:
            [self.entity setValue:@(value.integerValue) forKey:attribute];
            break;
        case NSInteger64AttributeType:
            [self.entity setValue:@(value.longLongValue) forKey:attribute];
            break;
        case NSDoubleAttributeType:
            value = [value stringByReplacingOccurrencesOfString:@"," withString:@"."];
            [self.entity setValue:@(value.doubleValue) forKey:attribute];
            break;
        case NSFloatAttributeType:
            value = [value stringByReplacingOccurrencesOfString:@"," withString:@"."];
            [self.entity setValue:@(value.floatValue) forKey:attribute];
            break;
        case NSDecimalAttributeType:
            value = [value stringByReplacingOccurrencesOfString:@"," withString:@"."];
            [self.entity setValue:[NSDecimalNumber numberWithDouble:value.doubleValue] forKey:attribute];
            break;
        default:
            break;
    }
}

- (NSString *)stringValueForAttribute:(NSString *)attribute
{
    NSAttributeDescription *attributeDescription = self.propertyDescriptions[attribute];
    
    switch (attributeDescription.attributeType) {
        case NSStringAttributeType:
            return [self.entity valueForKey:attribute];
            break;
        case NSInteger16AttributeType:
        case NSInteger32AttributeType:
        case NSInteger64AttributeType:
        case NSDoubleAttributeType:
        case NSFloatAttributeType:
        case NSDecimalAttributeType: {
            NSNumber *number = [self.entity valueForKey:attribute];
            return [NSString stringWithFormat:@"%@", number];
            break;
        } case NSDateAttributeType:
            return [NSDateFormatter localizedStringFromDate:[self.entity valueForKey:attribute]
                                                  dateStyle:NSDateFormatterMediumStyle
                                                  timeStyle:NSDateFormatterMediumStyle];
            break;
        default:
            break;
    }
    
    return [NSString stringWithFormat:@"%@", [self.entity valueForKey:attribute]];
}

- (void)setViewControllerClass:(Class)viewControllerClass forAttribute:(NSString *)attribute
{
    NSParameterAssert(viewControllerClass);
    NSAssert(class_conformsToProtocol(viewControllerClass, @protocol(SLSelectEntityAttributeViewControllerProtocol)), @"%@ does not conform to SLSelectEntityAttributeViewControllerProtocol", viewControllerClass);
    
    self.viewControllerClasses[attribute] = NSStringFromClass(viewControllerClass);
}

- (Class)viewControllerClassForAttribute:(NSString *)attribute
{
    NSString *className = self.viewControllerClasses[attribute];
    
    if (!className) {
        return Nil;
    }
    
    return NSClassFromString(className);
}

- (void)setFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController forRelationship:(NSString *)relationship
{
    self.fetchedResultsControllers[relationship] = fetchedResultsController;
}

- (NSFetchedResultsController *)fetchedResultsControllerForRelationship:(NSString *)relationship
{
    return self.fetchedResultsControllers[relationship];
}

- (void)setNameKeyPath:(NSString *)nameKeyPath forRelationship:(NSString *)relationship
{
    self.relationshipNameKeyPaths[relationship] = nameKeyPath;
}

- (NSString *)nameKeyPathForRelationship:(NSString *)relationship
{
    return self.relationshipNameKeyPaths[relationship];
}

#pragma mark - UIViewControllerRestoration

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    return [[self alloc] init];
}

#pragma mark - UIStateRestoration

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
}

#pragma mark - UIDataSourceModelAssociation

- (NSString *)modelIdentifierForElementAtIndexPath:(NSIndexPath *)indexPath inView:(UIView *)view
{
    if (indexPath) {
        
    }
    
    return nil;
}

- (NSIndexPath *)indexPathForElementWithModelIdentifier:(NSString *)identifier inView:(UIView *)view
{
    if (identifier) {
        
    }
    
    return nil;
}

#pragma mark - Private category implementation ()

- (void)_textFieldEditingChanged:(UITextField *)sender
{
    NSAttributeDescription *attributeDescription = objc_getAssociatedObject(sender, &SLEntityViewControllerAttributeDescriptionKey);
    
    [self applyStringValue:sender.text forAttribute:attributeDescription.name];
}

- (void)_switchValueChanged:(UISwitch *)sender
{
    NSAttributeDescription *attributeDescription = objc_getAssociatedObject(sender, &SLEntityViewControllerAttributeDescriptionKey);
    
    [self.entity setValue:@(sender.isOn) forKey:attributeDescription.name];
}

- (void)_cancelButtonClicked:(UIBarButtonItem *)sender
{
    if (self.editingType == SLEntityViewControllerEditingTypeCreate) {
        NSManagedObject *entity = self.entity;
        
        [entity.managedObjectContext deleteObject:entity];
        
        NSError *saveError = nil;
        [entity.managedObjectContext save:&saveError];
        NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
    } else {
        NSManagedObject *entity = self.entity;
        
        NSArray *changedKeys = entity.changedValues.allKeys;
        NSDictionary *commitedValues = [entity committedValuesForKeys:changedKeys];
        
        for (NSString *key in commitedValues) {
            id value = commitedValues[key];
            [entity setValue:[value isEqual:[NSNull null]] ? nil : value forKey:key];
        }
    }
    
    if (self.completionHandler) {
        self.completionHandler(NO);
        self.completionHandler = NULL;
    }
}

- (void)_saveButtonClicked:(UIBarButtonItem *)sender
{
    UIBarButtonItem *previousBarButtonItem = self.navigationItem.rightBarButtonItem;
    self.navigationItem.rightBarButtonItem = self.activityIndicatorBarButtonItem;
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.view.userInteractionEnabled = NO;
    
    void(^cleanupUI)(void) = ^{
        self.navigationItem.rightBarButtonItem = previousBarButtonItem;
        self.navigationItem.leftBarButtonItem.enabled = YES;
        self.view.userInteractionEnabled = YES;
    };
    
    void(^completionHandler)(id managedObject, NSError *error) = ^(id managedObject, NSError *error) {
        cleanupUI();
        
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:error.localizedDescription
                                                            message:error.localizedFailureReason
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
        
        if (self.completionHandler) {
            self.completionHandler(YES);
            self.completionHandler = NULL;
        }
    };
    
    if (self.editingType == SLEntityViewControllerEditingTypeCreate) {
        [self.entity createWithCompletionHandler:completionHandler];
    } else {
        [self.entity saveWithCompletionHandler:completionHandler];
    }
}

@end

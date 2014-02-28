//
//  SLEntityViewController.m
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

#import "SLEntityViewController.h"
#import "SLRESTfulCoreData.h"
#import "SLEntityTextFieldCell.h"
#import "SLEntitySwitchCell.h"
#import "SLSelectEntityAttributeViewControllerProtocol.h"
#import "SLSelectRelationshipEntityViewController.h"
#import "SLSelectEnumAttributeViewController.h"
#import "SLEntityTableViewCell.h"
#import <objc/runtime.h>
#import <objc/message.h>

static NSString *capitalizedString(NSString *string)
{
    if (string.length == 0) {
        return @"";
    }

    return [[string substringToIndex:1] stringByAppendingString:[string substringFromIndex:1]];
}

char *const SLEntityViewControllerAttributeDescriptionKey;

@interface SLEntityViewControllerSection ()
@property (nonatomic, readonly) BOOL isVisible;
@end

@interface SLEntityViewControllerStaticSection : SLEntityViewControllerSection
@property (nonatomic, strong) NSArray *properties;
@end

@interface SLEntityViewControllerStaticEnumSection : SLEntityViewControllerSection
@property (nonatomic, strong) NSString *attribute;
@property (nonatomic, strong) NSArray *values;
@property (nonatomic, strong) NSArray *humanReadableOptions;
@end

@interface SLEntityViewControllerDynamicSection : SLEntityViewControllerSection
@property (nonatomic, copy) NSString *relationship;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, copy) NSString *(^formatBlock)(id entity);
@end



@implementation SLEntityViewControllerSection

#pragma mark - setters and getters

- (BOOL)isVisible
{
    return NO;
}

#pragma mark - Initialization

+ (instancetype)staticSectionWithProperties:(NSArray *)properties
{
    SLEntityViewControllerStaticSection *section = [[SLEntityViewControllerStaticSection alloc] init];
    section.properties = properties;

    return section;
}

+ (instancetype)staticSectionWithEnumValue:(NSArray *)values humanReadableOptions:(NSArray *)humanReadableOptions forAttribute:(NSString *)attribute
{
    SLEntityViewControllerStaticEnumSection *section = [[SLEntityViewControllerStaticEnumSection alloc] init];
    section.attribute = attribute;
    section.values = values;
    section.humanReadableOptions = humanReadableOptions;

    return section;
}

+ (instancetype)dynamicEntityWithRelationship:(NSString *)relationship
                     fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController
                                  formatBlock:(NSString *(^)(id entity))formatBlock
{
    SLEntityViewControllerDynamicSection *section = [[SLEntityViewControllerDynamicSection alloc] init];
    section.relationship = relationship;
    section.fetchedResultsController = fetchedResultsController;
    section.formatBlock = formatBlock;

    return section;
}

@end



@implementation SLEntityViewControllerStaticSection

- (BOOL)isVisible
{
    return self.properties.count > 0;
}

@end

@implementation SLEntityViewControllerDynamicSection

- (BOOL)isVisible
{
    return YES;
}

@end

@implementation SLEntityViewControllerStaticEnumSection

- (BOOL)isVisible
{
    return YES;
}

@end



@interface SLEntityViewController () <SLSelectEnumAttributeViewControllerDelegate, NSFetchedResultsControllerDelegate> {
    NSManagedObject *_entity;
}

@property (nonatomic, readonly) NSArray *visibleSectionsInTableView;

@property (nonatomic, strong) NSMutableDictionary *keyboardTypes;
@property (nonatomic, strong) NSMutableDictionary *viewControllerClasses;
@property (nonatomic, strong) NSMutableDictionary *fetchedResultsControllers;
@property (nonatomic, strong) NSMutableDictionary *relationshipNameKeyPaths;

@property (nonatomic, strong) NSMutableDictionary *enumValues;
@property (nonatomic, strong) NSMutableDictionary *enumOptions;
@property (nonatomic, strong) NSMutableDictionary *enumOptionsValueMappings;

@property (nonatomic, strong) NSMutableDictionary *predicates;

@property (nonatomic, strong) NSEntityDescription *entityDescription;

//@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, readonly) NSArray *visibleSections;
- (void)setVisibleSections:(NSArray *)sections animateDiff:(BOOL)animateDiff;

@end



@implementation SLEntityViewController

#pragma mark - setters and getters

- (NSArray *)visibleSectionsInTableView
{
    NSMutableArray *visibleSectionsInTableView = [NSMutableArray array];

    for (SLEntityViewControllerSection *section in self.visibleSections) {
        if (section.isVisible) {
            [visibleSectionsInTableView addObject:section];
        }
    }

    return visibleSectionsInTableView;
}

- (void)setEntity:(id)entity
{
    if (entity != _entity) {
        _entity = entity;

        [self _updateVisibleSectionsAnimated:NO];
    }
}

- (BOOL)canEditProperty:(NSString *)property
{
    return YES;
}

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

- (NSMutableDictionary *)enumValues
{
    if (!_enumValues) {
        _enumValues = [NSMutableDictionary dictionary];
    }

    return _enumValues;
}

- (NSMutableDictionary *)enumOptions
{
    if (!_enumOptions) {
        _enumOptions = [NSMutableDictionary dictionary];
    }

    return _enumOptions;
}

- (NSMutableDictionary *)enumOptionsValueMappings
{
    if (!_enumOptionsValueMappings) {
        _enumOptionsValueMappings = [NSMutableDictionary dictionary];
    }

    return _enumOptionsValueMappings;
}

- (NSMutableDictionary *)predicates
{
    if (!_predicates) {
        _predicates = [NSMutableDictionary dictionary];
    }

    return _predicates;
}

- (void)setSections:(NSArray *)sections
{
    for (id section in _sections) {
        if ([section isKindOfClass:[SLEntityViewControllerDynamicSection class]]) {
            SLEntityViewControllerDynamicSection *dynamicSection = section;
            dynamicSection.fetchedResultsController.delegate = nil;
        }
    }

    _sections = [sections copy];

    for (id section in _sections) {
        if ([section isKindOfClass:[SLEntityViewControllerDynamicSection class]]) {
            SLEntityViewControllerDynamicSection *dynamicSection = section;
            dynamicSection.fetchedResultsController.delegate = self;

            NSError *error = nil;
            [dynamicSection.fetchedResultsController performFetch:&error];
            NSAssert(error == nil, @"controller %@ error: %@", dynamicSection.fetchedResultsController, error);
        }
    }

    [self _updateVisibleSectionsAnimated:NO];
}

- (void)setVisibleSections:(NSArray *)sections animateDiff:(BOOL)animateDiff
{
    if (![sections isEqualToArray:_visibleSections]) {
        NSArray *previousSecions = _visibleSections;
        _visibleSections = sections;

        if (self.isViewLoaded) {
            if (self.view.window && animateDiff) {
                [self _applyDiffUpdateToTableViewWithVisibleSections:_visibleSections previousVisibleSections:previousSecions];
            } else {
                [self.tableView reloadData];
            }
        }
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

        self.sections = @[];
        self.title = _editingType == SLEntityViewControllerEditingTypeCreate ? NSLocalizedString(@"Create", @"") : NSLocalizedString(@"Edit", @"");

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0
        self.preferredContentSize = CGSizeMake(320.0f, 480.0f);
#else
        self.contentSizeForViewInPopover = CGSizeMake(320.0f, 480.0f);
#endif

        if (entity.managedObjectContext) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(_entitiesManagedObjectContextDidChangeCallback:)
                                                         name:NSManagedObjectContextObjectsDidChangeNotification
                                                       object:entity.managedObjectContext];
        }

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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];;
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

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonClicked:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonClicked:)];

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

    if (!self.isMovingToParentViewController) {
        return;
    }

    for (id section in self.sections) {
        if (![section isKindOfClass:[SLEntityViewControllerStaticSection class]]) {
            continue;
        }

        SLEntityViewControllerStaticSection *staticSection = section;
        for (NSString *property in staticSection.properties) {
            NSAttributeDescription *attributeDescription = self.entityDescription.propertiesByName[property];

            if (![attributeDescription isKindOfClass:[NSAttributeDescription class]]) {
                continue;
            }

            if (![self _attributeDescriptionRequiresTextField:attributeDescription] || [self stringValueForAttribute:property].length > 0) {
                continue;
            }

            NSIndexPath *indexPath = [self indexPathForProperty:attributeDescription.name];
            if (!indexPath) {
                continue;
            }

            SLEntityTextFieldCell *cell = (SLEntityTextFieldCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            if ([cell isKindOfClass:[SLEntityTextFieldCell class]]) {
                [cell.textField becomeFirstResponder];
                return;
            }
        }
    }
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
    return self.visibleSectionsInTableView.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id sectionInfo = self.visibleSectionsInTableView[section];

    if ([sectionInfo isKindOfClass:[SLEntityViewControllerStaticSection class]]) {
        SLEntityViewControllerStaticSection *staticSection = sectionInfo;
        return staticSection.properties.count;
    } else if ([sectionInfo isKindOfClass:[SLEntityViewControllerDynamicSection class]]) {
        SLEntityViewControllerDynamicSection *dynamicSection = sectionInfo;

        return dynamicSection.fetchedResultsController.fetchedObjects.count;
    } else if ([sectionInfo isKindOfClass:[SLEntityViewControllerStaticEnumSection class]]) {
        SLEntityViewControllerStaticEnumSection *staticSection = sectionInfo;

        return staticSection.values.count;
    }

    NSParameterAssert(NO);
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id sectionInfo = self.visibleSectionsInTableView[indexPath.section];

    if ([sectionInfo isKindOfClass:[SLEntityViewControllerStaticSection class]]) {
        SLEntityViewControllerStaticSection *staticSection = sectionInfo;

        NSString *property = staticSection.properties[indexPath.row];
        id propertyDescription = self.entityDescription.propertiesByName[property];

        if ([propertyDescription isKindOfClass:[NSAttributeDescription class]]) {
            return [self tableView:tableView cellForAttributeDescription:propertyDescription atIndexPath:indexPath];
        } else if ([propertyDescription isKindOfClass:[NSRelationshipDescription class]]) {
            return [self tableView:tableView cellForRelationshipDescription:propertyDescription atIndexPath:indexPath];
        }
    } else if ([sectionInfo isKindOfClass:[SLEntityViewControllerStaticEnumSection class]]) {
        SLEntityViewControllerStaticEnumSection *staticSection = sectionInfo;

        static NSString *CellIdentifier = @"SLEntityTableViewCellStaticEnum";

        SLEntityTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[SLEntityTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }

        cell.textLabel.text = staticSection.humanReadableOptions[indexPath.row];
        id currentValue = [self.entity valueForKey:staticSection.attribute];

        if ([currentValue isEqual:staticSection.values[indexPath.row]]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }

        return cell;
    } else if ([sectionInfo isKindOfClass:[SLEntityViewControllerDynamicSection class]]) {
        SLEntityViewControllerDynamicSection *dynamicSection = sectionInfo;

        static NSString *CellIdentifier = @"SLEntityTableViewCellDynamicSection";

        SLEntityTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[SLEntityTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }

        NSManagedObject *thisEntity = dynamicSection.fetchedResultsController.fetchedObjects[indexPath.row];
        cell.textLabel.text = dynamicSection.formatBlock(thisEntity);

        NSRelationshipDescription *relationshipDescription = self.entityDescription.relationshipsByName[dynamicSection.relationship];

        if (relationshipDescription.isToMany) {
            NSSet *set = [self.entity valueForKey:relationshipDescription.name];
            cell.accessoryType = [set containsObject:thisEntity] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        } else {
            cell.accessoryType = thisEntity == [self.entity valueForKey:relationshipDescription.name] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }

        return cell;
    }

    NSAssert(NO, @"no cell for %@", indexPath);
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    SLEntityViewControllerSection *sectionInfo = self.visibleSectionsInTableView[section];
    return sectionInfo.titleText;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    SLEntityViewControllerSection *sectionInfo = self.visibleSectionsInTableView[section];
    return sectionInfo.footerText;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id sectionInfo = self.visibleSectionsInTableView[indexPath.section];

    if ([sectionInfo isKindOfClass:[SLEntityViewControllerStaticSection class]]) {
        NSString *property = [self propertyForIndexPath:indexPath];
        id propertyDescription = self.entityDescription.propertiesByName[property];

        if (![self canEditProperty:[propertyDescription name]]) {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
            return;
        }

        if ([propertyDescription isKindOfClass:[NSAttributeDescription class]]) {
            NSAttributeDescription *attributeDescription = propertyDescription;

            if (attributeDescription.attributeType == NSBooleanAttributeType) {
                [self.entity setValue:@(![[self.entity valueForKey:attributeDescription.name] boolValue]) forKey:attributeDescription.name];

                SLEntitySwitchCell *cell = (SLEntitySwitchCell *)[tableView cellForRowAtIndexPath:indexPath];
                if ([cell isKindOfClass:[SLEntitySwitchCell class]]) {
                    [cell.switchControl setOn:[[self.entity valueForKey:attributeDescription.name] boolValue] animated:YES];
                }

                [self _updateVisibleSectionsAnimated:YES];
                return;
            }

            NSArray *enumOptions = [self enumOptionsForAttribute:attributeDescription.name];
            NSArray *enumValues = [self enumValuesForAttribute:attributeDescription.name];

            if (enumOptions && enumValues) {
                if (enumOptions.count > 1) {
                    SLSelectEnumAttributeViewController *viewController = [[SLSelectEnumAttributeViewController alloc] initWithOptions:enumOptions values:enumValues currentValue:[self.entity valueForKey:attributeDescription.name]];
                    viewController.delegate = self;
                    viewController.title = self.propertyMapping[attributeDescription.name];

                    viewController.modalInPopover = self.modalInPopover;

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0
                    viewController.preferredContentSize = self.preferredContentSize;
#else
                    viewController.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
#endif

                    viewController.view.backgroundColor = self.view.backgroundColor;
                    viewController.tableView.separatorColor = self.tableView.separatorColor;
                    viewController.tableView.separatorStyle = self.tableView.separatorStyle;
                    viewController.tableView.rowHeight = self.tableView.rowHeight;

                    if ([self.view respondsToSelector:@selector(tintColor)]) {
                        viewController.view.tintColor = self.view.tintColor;
                    }

                    if ([self.tableView.backgroundView isKindOfClass:[UIImageView class]]) {
                        UIImageView *imageView = (UIImageView *)self.tableView.backgroundView;
                        viewController.tableView.backgroundView = [[UIImageView alloc] initWithImage:imageView.image];
                    }

                    objc_setAssociatedObject(viewController, &SLEntityViewControllerAttributeDescriptionKey,
                                             attributeDescription, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

                    [self.navigationController pushViewController:viewController animated:YES];
                    return;
                }
            }

            Class viewControllerClass = [self viewControllerClassForAttribute:attributeDescription.name];

            if (viewControllerClass) {
                UIViewController<SLSelectEntityAttributeViewControllerProtocol> *viewController = [[viewControllerClass alloc] initWithEntity:self.entity attribute:attributeDescription.name];
                [self.navigationController pushViewController:viewController animated:YES];
                return;
            }
        } else if ([propertyDescription isKindOfClass:[NSRelationshipDescription class]]) {
            NSRelationshipDescription *relationshipDescription = propertyDescription;

            Class viewControllerClass = [self viewControllerClassForAttribute:relationshipDescription.name];

            if (viewControllerClass) {
                UIViewController<SLSelectEntityAttributeViewControllerProtocol> *viewController = [[viewControllerClass alloc] initWithEntity:self.entity attribute:relationshipDescription.name];
                [self.navigationController pushViewController:viewController animated:YES];
                return;
            }

            NSFetchedResultsController *fetchedResultsController = [self fetchedResultsControllerForRelationship:relationshipDescription.name];
            NSString *nameKeyPath = [self nameKeyPathForRelationship:relationshipDescription.name];

            SLSelectRelationshipEntityViewController *viewController = [[SLSelectRelationshipEntityViewController alloc] initWithFetchedResultsController:fetchedResultsController
                                                                                                                                  relationshipDescription:relationshipDescription
                                                                                                                                                   entity:self.entity
                                                                                                                                           keyPathForName:nameKeyPath];
            viewController.title = self.propertyMapping[relationshipDescription.name];
            viewController.modalInPopover = self.modalInPopover;

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0
            viewController.preferredContentSize = self.preferredContentSize;
#else
            viewController.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
#endif

            viewController.view.backgroundColor = self.view.backgroundColor;
            viewController.tableView.separatorColor = self.tableView.separatorColor;
            viewController.tableView.separatorStyle = self.tableView.separatorStyle;
            viewController.tableView.rowHeight = self.tableView.rowHeight;

            if ([self.view respondsToSelector:@selector(tintColor)]) {
                viewController.view.tintColor = self.view.tintColor;
            }

            if ([self.tableView.backgroundView isKindOfClass:[UIImageView class]]) {
                UIImageView *imageView = (UIImageView *)self.tableView.backgroundView;
                viewController.tableView.backgroundView = [[UIImageView alloc] initWithImage:imageView.image];
            }

            [self.navigationController pushViewController:viewController animated:YES];
            return;
        }
    } else if ([sectionInfo isKindOfClass:[SLEntityViewControllerDynamicSection class]]) {
        SLEntityViewControllerDynamicSection *dynamicSection = sectionInfo;

        NSManagedObject *thisEntity = dynamicSection.fetchedResultsController.fetchedObjects[indexPath.row];
        NSRelationshipDescription *relationshipDescription = self.entityDescription.relationshipsByName[dynamicSection.relationship];

        if (relationshipDescription.isToMany) {
            NSSet *set = [self.entity valueForKey:relationshipDescription.name];
            SEL addOrDeleteSelector = NULL;

            if ([set containsObject:thisEntity]) {
                addOrDeleteSelector = NSSelectorFromString([NSString stringWithFormat:@"remove%@Object:", capitalizedString(relationshipDescription.name)]);
            } else {
                addOrDeleteSelector = NSSelectorFromString([NSString stringWithFormat:@"add%@Object:", capitalizedString(relationshipDescription.name)]);
            }

            ((void(*)(id, SEL, ...))objc_msgSend)(self.entity, addOrDeleteSelector, thisEntity);

            [self _updateVisibleSectionsAnimated:YES];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:[self indexPathForProperty:relationshipDescription.name].section]
                          withRowAnimation:UITableViewRowAnimationNone];
        } else {
            [self.entity setValue:thisEntity forKey:relationshipDescription.name];
            [self _updateVisibleSectionsAnimated:YES];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:[self indexPathForProperty:relationshipDescription.name].section]
                          withRowAnimation:UITableViewRowAnimationNone];
        }
    } else if ([sectionInfo isKindOfClass:[SLEntityViewControllerStaticEnumSection class]]) {
        SLEntityViewControllerStaticEnumSection *staticSection = sectionInfo;

        [self.entity setValue:staticSection.values[indexPath.row] forKey:staticSection.attribute];
        [self _updateVisibleSectionsAnimated:YES];

        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:[self indexPathForProperty:staticSection.attribute].section]
                      withRowAnimation:UITableViewRowAnimationNone];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Instance methods

- (NSString *)propertyNameForTextField:(UITextField *)textField
{
    NSAttributeDescription *attribute = objc_getAssociatedObject(textField, &SLEntityViewControllerAttributeDescriptionKey);
    NSParameterAssert(attribute);

    return attribute.name;
}

- (NSString *)propertyForIndexPath:(NSIndexPath *)indexPath
{
    id sectionInfo = self.visibleSectionsInTableView[indexPath.section];

    if ([sectionInfo isKindOfClass:[SLEntityViewControllerStaticSection class]]) {
        SLEntityViewControllerStaticSection *staticSection = sectionInfo;
        return staticSection.properties[indexPath.row];
    } else if ([sectionInfo isKindOfClass:[SLEntityViewControllerDynamicSection class]]) {
        SLEntityViewControllerDynamicSection *dynamicSection = sectionInfo;
        return dynamicSection.relationship;
    } else if ([sectionInfo isKindOfClass:[SLEntityViewControllerStaticEnumSection class]]) {
        SLEntityViewControllerStaticEnumSection *dynamicSection = sectionInfo;
        return dynamicSection.attribute;
    }

    return nil;
}

- (NSIndexPath *)indexPathForProperty:(NSString *)property
{
    __block NSIndexPath *indexPath = nil;

    [self.visibleSectionsInTableView enumerateObjectsUsingBlock:^(id sectionInfo, NSUInteger idx, BOOL *stop) {
        if ([sectionInfo isKindOfClass:[SLEntityViewControllerStaticSection class]]) {
            SLEntityViewControllerStaticSection *staticSection = sectionInfo;

            if ([staticSection.properties containsObject:property]) {
                indexPath = [NSIndexPath indexPathForRow:[staticSection.properties indexOfObject:property] inSection:idx];
                *stop = YES;
            }
        } else if ([sectionInfo isKindOfClass:[SLEntityViewControllerDynamicSection class]]) {
            SLEntityViewControllerDynamicSection *dynamicSection = sectionInfo;

            if ([dynamicSection.relationship isEqualToString:property]) {
                indexPath = [NSIndexPath indexPathForRow:0 inSection:idx];
                *stop = YES;
            }
        } else if ([sectionInfo isKindOfClass:[SLEntityViewControllerStaticEnumSection class]]) {
            SLEntityViewControllerStaticEnumSection *staticSection = sectionInfo;

            if ([staticSection.attribute isEqualToString:property]) {
                indexPath = [NSIndexPath indexPathForRow:0 inSection:idx];
                *stop = YES;
            }
        }
    }];

    return indexPath;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForAttributeDescription:(NSAttributeDescription *)attributeDescription atIndexPath:(NSIndexPath *)indexPath
{
    NSString *firstLetter = [attributeDescription.name substringToIndex:1];
    NSString *restString = [attributeDescription.name substringFromIndex:1];

    NSString *selectorName = [NSString stringWithFormat:@"tableView:cellFor%@%@AtIndexPath:", firstLetter.uppercaseString, restString];
    SEL selector = NSSelectorFromString(selectorName);

    if ([self respondsToSelector:selector]) {
        return objc_msgSend(self, selector, tableView, indexPath);
    }

    BOOL canEditProperty = [self canEditProperty:attributeDescription.name];
    BOOL useEnum = [self _attributeDescriptionRequiresEnum:attributeDescription];

    BOOL useTextFieldCell = [self _attributeDescriptionRequiresTextField:attributeDescription];

    if (useTextFieldCell) {
        static NSString *CellIdentifier = @"SLEntityTextFieldCell";

        SLEntityTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[SLEntityTextFieldCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];

            cell.textField.delegate = self;
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

        [self configureTextFieldCell:cell forAttribute:attributeDescription.name];

        return cell;
    } else if (useEnum) {
        static NSString *CellIdentifier = @"SLEntityTableViewCellUITableViewCellStyleValue1";

        SLEntityTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[SLEntityTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        }

        cell.textLabel.text = self.propertyMapping[attributeDescription.name];
        cell.detailTextLabel.text = [self stringValueForAttribute:attributeDescription.name];

        NSArray *enumOptions = [self enumOptionsForAttribute:attributeDescription.name];
        if (enumOptions.count > 1) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
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

    if (!canEditProperty) {
        static NSString *CellIdentifier = @"SLEntityTableViewCellNotEditable";

        SLEntityTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[SLEntityTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];

            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryType = UITableViewCellAccessoryNone;
        }

        cell.textLabel.text = self.propertyMapping[attributeDescription.name];
        cell.detailTextLabel.text = [self stringValueForAttribute:attributeDescription.name];

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

    BOOL canEditProperty = [self canEditProperty:relationshipDescription.name];

    static NSString *CellIdentifier = @"SLEntityTableViewCell";

    SLEntityTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[SLEntityTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }

    cell.textLabel.text = self.propertyMapping[relationshipDescription.name];

    if (relationshipDescription.isToMany) {
        cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d selected", @""), [[self.entity valueForKey:relationshipDescription.name] count]];
    } else {
        NSString *nameKeyPath = [self nameKeyPathForRelationship:relationshipDescription.name];
        cell.detailTextLabel.text = [[self.entity valueForKey:relationshipDescription.name] valueForKey:nameKeyPath];
    }

    if (canEditProperty) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

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

    NSAttributeDescription *attributeDescription = self.entityDescription.attributesByName[attribute];

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
    NSAttributeDescription *attributeDescription = self.entityDescription.attributesByName[attribute];

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

    [self _updateVisibleSectionsAnimated:YES];
}

- (NSString *)stringValueForAttribute:(NSString *)attribute
{
    NSAttributeDescription *attributeDescription = self.entityDescription.attributesByName[attribute];

    NSArray *enumOptions = [self enumOptionsForAttribute:attribute];
    NSArray *enumValues = [self enumValuesForAttribute:attribute];

    if (enumOptions && enumValues) {
        NSDictionary *mapping = self.enumOptionsValueMappings[attributeDescription.name];
        return mapping[[self.entity valueForKey:attributeDescription.name]];
    }

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
            if (!number) {
                return @"";
            }

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

- (void)configureTextFieldCell:(SLEntityTextFieldCell *)textFieldCell forAttribute:(NSString *)attribute
{

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

- (void)setEnumValues:(NSArray *)enumValues withOptions:(NSArray *)options forAttribute:(NSString *)attribute
{
    NSAssert(enumValues.count == options.count, @"enumValues and options must have ");

    self.enumValues[attribute] = enumValues;
    self.enumOptions[attribute] = options;

    self.enumOptionsValueMappings[attribute] = [NSDictionary dictionaryWithObjects:options forKeys:enumValues];
}

- (NSArray *)enumValuesForAttribute:(NSString *)attribute
{
    return self.enumValues[attribute];
}

- (NSArray *)enumOptionsForAttribute:(NSString *)attribute
{
    return self.enumOptions[attribute];
}

- (void)onlyShowAttribute:(NSString *)attribute whenPredicateEvaluates:(NSPredicate *)predicate
{
    self.predicates[attribute] = predicate;
    [self _updateVisibleSectionsAnimated:NO];
}

- (NSPredicate *)predicateForAttribute:(NSString *)attribute
{
    return self.predicates[attribute] ?: [NSPredicate predicateWithValue:YES];
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

- (void)cancelButtonClicked:(UIBarButtonItem *)sender
{
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];

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

- (void)saveButtonClicked:(UIBarButtonItem *)sender
{
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];

    UIBarButtonItem *previousBarButtonItem = self.navigationItem.rightBarButtonItem;
    self.navigationItem.rightBarButtonItem = self.activityIndicatorBarButtonItem;
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.view.userInteractionEnabled = NO;

    void(^cleanupUI)(void) = ^{
        self.navigationItem.rightBarButtonItem = previousBarButtonItem;
        self.navigationItem.leftBarButtonItem.enabled = YES;
        self.view.userInteractionEnabled = YES;

        [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
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

#pragma mark - SLSelectEnumAttributeViewControllerDelegate

- (void)selectEnumAttributeViewController:(SLSelectEnumAttributeViewController *)viewController didSelectEnumValue:(id)enumValue
{
    NSAttributeDescription *attributeDescription = objc_getAssociatedObject(viewController, &SLEntityViewControllerAttributeDescriptionKey);

    [self.entity setValue:enumValue forKey:attributeDescription.name];
    [self _updateVisibleSectionsAnimated:NO];

    [self.navigationController popToViewController:self animated:YES];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    NSUInteger index = [self.visibleSectionsInTableView indexOfObjectPassingTest:^BOOL(SLEntityViewControllerDynamicSection *section, NSUInteger idx, BOOL *stop) {
        if (![section isKindOfClass:[SLEntityViewControllerDynamicSection class]]) {
            return NO;
        }

        return section.fetchedResultsController == controller;
    }];

    if (index == NSNotFound) {
        return;
    }

    SLEntityViewControllerDynamicSection *section = self.visibleSectionsInTableView[index];
    NSUInteger sectionIndex = [self indexPathForProperty:section.relationship].section;

    NSIndexPath *updatedIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:sectionIndex];
    NSIndexPath *updatedNewIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:sectionIndex];

    switch (type) {
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[ updatedIndexPath ] withRowAnimation:UITableViewRowAnimationTop];
            break;
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[ updatedNewIndexPath ] withRowAnimation:UITableViewRowAnimationTop];
            break;
        case NSFetchedResultsChangeMove:
            [self.tableView moveRowAtIndexPath:updatedIndexPath toIndexPath:updatedNewIndexPath];
            break;
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:@[ updatedIndexPath ] withRowAnimation:UITableViewRowAnimationNone];
            break;
    }
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
    [self _updateVisibleSectionsAnimated:YES];
}

- (void)_updateVisibleSectionsAnimated:(BOOL)animated
{
    NSMutableArray *visibleSections = [NSMutableArray arrayWithCapacity:self.sections.count];

    for (id sectionInfo in self.sections) {
        if ([sectionInfo isKindOfClass:[SLEntityViewControllerStaticSection class]]) {
            SLEntityViewControllerStaticSection *staticSection = sectionInfo;

            NSMutableArray *properties = [NSMutableArray arrayWithCapacity:staticSection.properties.count];

            for (NSString *property in staticSection.properties) {
                if ([[self predicateForAttribute:property] evaluateWithObject:self.entity]) {
                    [properties addObject:property];
                }
            }

            SLEntityViewControllerSection *visibleSectionInfo = [SLEntityViewControllerSection staticSectionWithProperties:properties];
            visibleSectionInfo.titleText = staticSection.titleText;
            visibleSectionInfo.footerText = staticSection.footerText;

            [visibleSections addObject:visibleSectionInfo];
        } else if ([sectionInfo isKindOfClass:[SLEntityViewControllerDynamicSection class]]) {
            [visibleSections addObject:sectionInfo];
        } else if ([sectionInfo isKindOfClass:[SLEntityViewControllerStaticEnumSection class]]) {
            [visibleSections addObject:sectionInfo];
        }
    }

    [self setVisibleSections:visibleSections animateDiff:animated];
}

- (BOOL)_attributeDescriptionRequiresEnum:(NSAttributeDescription *)attributeDescription
{
    NSArray *enumOptions = [self enumOptionsForAttribute:attributeDescription.name];
    NSArray *enumValues = [self enumValuesForAttribute:attributeDescription.name];

    return enumOptions != nil && enumValues != nil && [self canEditProperty:attributeDescription.name];
}

- (BOOL)_attributeDescriptionRequiresTextField:(NSAttributeDescription *)attributeDescription
{
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

    return [textFieldAttributes containsObject:@(attributeDescription.attributeType)] && ![self _attributeDescriptionRequiresEnum:attributeDescription] && [self canEditProperty:attributeDescription.name];
}

- (void)_applyDiffUpdateToTableViewWithVisibleSections:(NSArray *)visibleSections previousVisibleSections:(NSArray *)previousVisibleSections
{
    if (visibleSections.count != previousVisibleSections.count) {
        [self.tableView reloadData];
        return;
    }

    [self.tableView beginUpdates];

    __block NSInteger previousVisibleSectionIndex = 0;

    [visibleSections enumerateObjectsUsingBlock:^(SLEntityViewControllerSection *visibleSection, NSUInteger idx, BOOL *stop) {
        SLEntityViewControllerSection *previousVisibleSection = previousVisibleSections[idx];

        if (visibleSection.isVisible && !previousVisibleSection.isVisible) {
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:previousVisibleSectionIndex] withRowAnimation:UITableViewRowAnimationTop];
        } else if (!visibleSection.isVisible && previousVisibleSection.isVisible) {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:previousVisibleSectionIndex] withRowAnimation:UITableViewRowAnimationTop];
        } else if (visibleSection.isVisible && previousVisibleSection.isVisible) {
            if ([visibleSection isKindOfClass:[SLEntityViewControllerStaticSection class]]) {
                SLEntityViewControllerStaticSection *staticVisibleSection = (SLEntityViewControllerStaticSection *)visibleSection;
                SLEntityViewControllerStaticSection *previousVisibleStaticSection = (SLEntityViewControllerStaticSection *)previousVisibleSection;

                NSArray *previousVisibleProperties = previousVisibleStaticSection.properties;
                NSArray *visibleProperties = staticVisibleSection.properties;

                NSMutableArray *deletedIndexPaths = [NSMutableArray arrayWithCapacity:previousVisibleProperties.count];
                NSMutableArray *insertedIndexPaths = [NSMutableArray arrayWithCapacity:visibleProperties.count];

                for (NSString *property in previousVisibleProperties) {
                    if ([visibleProperties containsObject:property]) {
                        continue;
                    }

                    [deletedIndexPaths addObject:[NSIndexPath indexPathForRow:[previousVisibleProperties indexOfObject:property]
                                                                    inSection:previousVisibleSectionIndex]];
                }

                for (NSString *property in visibleProperties) {
                    if ([previousVisibleProperties containsObject:property]) {
                        continue;
                    }
                    
                    [insertedIndexPaths addObject:[NSIndexPath indexPathForRow:[visibleProperties indexOfObject:property]
                                                                     inSection:previousVisibleSectionIndex]];
                }
                
                [self.tableView deleteRowsAtIndexPaths:deletedIndexPaths withRowAnimation:UITableViewRowAnimationTop];
                [self.tableView insertRowsAtIndexPaths:insertedIndexPaths withRowAnimation:UITableViewRowAnimationTop];
            }
        }
        
        if (previousVisibleSection.isVisible) {
            previousVisibleSectionIndex++;
        }
    }];
    
    [self.tableView endUpdates];
}

- (void)_entitiesManagedObjectContextDidChangeCallback:(NSNotification *)notification
{
    NSArray *deletedObjects = notification.userInfo[NSDeletedObjectsKey];
    if (![deletedObjects containsObject:self.entity]) {
        return;
    }
    
    NSArray *viewControllers = self.navigationController.viewControllers;
    NSInteger index = [viewControllers indexOfObject:self];
    
    if (self.navigationController && index != NSNotFound && index > 0) {
        [self.navigationController popToViewController:viewControllers[index - 1] animated:YES];
    } else {
        if (self.completionHandler) {
            self.completionHandler(NO);
            self.completionHandler = NULL;
        }
    }
}

@end

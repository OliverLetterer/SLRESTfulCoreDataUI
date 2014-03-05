//
//  SLRESTfulCoreDataUITests.m
//  SLRESTfulCoreDataUITests
//
//  Created by Oliver Letterer on 28.02.14.
//  Copyright (c) 2014 Sparrow-Labs. All rights reserved.
//

#import <SLRESTfulCoreDataUI.h>
#import "SLEntity1.h"
#import "SLEntity2.h"
#import "SLTestCoreDataStack.h"

static SLEntity2 *createEntity2WithName(NSString *name)
{
    SLEntity2 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity2 class])
                                                      inManagedObjectContext:[SLTestCoreDataStack sharedInstance].mainThreadManagedObjectContext];

    entity.name = name;

    NSError *saveError = nil;
    [[SLTestCoreDataStack sharedInstance].mainThreadManagedObjectContext save:&saveError];
    NSCAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

    return entity;
}

@interface SLRESTfulCoreDataUITests : SenTestCase

@property (nonatomic, strong) SLEntityViewController *viewController;
@property (nonatomic, strong) SLEntity1 *entity;

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation SLRESTfulCoreDataUITests

- (void)setUp
{
    [super setUp];

    self.context = [SLTestCoreDataStack sharedInstance].mainThreadManagedObjectContext;
    self.entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity1 class])
                                                inManagedObjectContext:self.context];

    self.viewController = [[SLEntityViewController alloc] initWithEntity:self.entity editingType:SLEntityViewControllerEditingTypeCreate];
    self.viewController.propertyMapping = @{
                                            @"booleanValue": @"BOOL",
                                            @"stringValue": @"String",
                                            @"dateValue": @"Date",
                                            @"dummyBool": @"dummy",
                                            };

    [UIApplication sharedApplication].delegate.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:self.viewController];
}

- (void)tearDown
{
    [super tearDown];

    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
    [[SLTestCoreDataStack sharedInstance] wipeDataStore];
}

- (void)testThatSLEntityViewControllerCanDisplayAStaticSection
{
    NSArray *attributes = @[ @"booleanValue", @"dateValue", @"stringValue" ];
    SLEntityViewControllerSection *staticSection = [SLEntityViewControllerSection staticSectionWithProperties:attributes];
    SLEntityViewControllerSection *dummySection = [SLEntityViewControllerSection staticSectionWithProperties:@[ @"dummyBool" ]];

    self.viewController.sections = @[ dummySection, staticSection, dummySection ];

    [tester waitForTimeInterval:1.0];
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];

    [tester enterText:@"long text" intoViewWithAccessibilityLabel:@"String"];
    expect(self.entity.stringValue).to.equal(@"long text");

    [tester setOn:YES forSwitchWithAccessibilityLabel:@"BOOL"];
    expect(self.entity.booleanValue).to.beTruthy();
}

- (void)testThatSLEntityViewControllerCanHideAttributesOfTheSameSection
{
    self.entity.booleanValue = @NO;

    NSArray *attributes = @[ @"booleanValue", @"dateValue", @"stringValue" ];
    SLEntityViewControllerSection *staticSection = [SLEntityViewControllerSection staticSectionWithProperties:attributes];
    SLEntityViewControllerSection *dummySection = [SLEntityViewControllerSection staticSectionWithProperties:@[ @"dummyBool" ]];

    self.viewController.sections = @[ dummySection, staticSection, dummySection ];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"booleanValue == NO"];
    [self.viewController onlyShowAttribute:@"dateValue" whenPredicateEvaluates:predicate];
    [self.viewController onlyShowAttribute:@"stringValue" whenPredicateEvaluates:predicate];

    [tester waitForTimeInterval:1.0];
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];

    [tester setOn:YES forSwitchWithAccessibilityLabel:@"BOOL"];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"String"];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"Date"];

    [tester setOn:NO forSwitchWithAccessibilityLabel:@"BOOL"];
    [tester waitForViewWithAccessibilityLabel:@"String"];
    [tester waitForViewWithAccessibilityLabel:@"Date"];
}

- (void)testThatSLEntityViewControllerCanHideAttributesOfAnotherSection
{
    self.entity.booleanValue = @NO;

    SLEntityViewControllerSection *staticSection1 = [SLEntityViewControllerSection staticSectionWithProperties:@[ @"booleanValue" ]];
    SLEntityViewControllerSection *staticSection2 = [SLEntityViewControllerSection staticSectionWithProperties:@[ @"dateValue", @"stringValue" ]];
    SLEntityViewControllerSection *dummySection = [SLEntityViewControllerSection staticSectionWithProperties:@[ @"dummyBool" ]];

    staticSection1.titleText = @"Section 1";
    staticSection2.titleText = @"Section 1";

    self.viewController.sections = @[ dummySection, staticSection1, staticSection2, dummySection ];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"booleanValue == NO"];
    [self.viewController onlyShowAttribute:@"dateValue" whenPredicateEvaluates:predicate];
    [self.viewController onlyShowAttribute:@"stringValue" whenPredicateEvaluates:predicate];

    [tester waitForTimeInterval:1.0];
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];

    [tester setOn:YES forSwitchWithAccessibilityLabel:@"BOOL"];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"String"];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"Date"];

    [tester setOn:NO forSwitchWithAccessibilityLabel:@"BOOL"];
    [tester waitForViewWithAccessibilityLabel:@"String"];
    [tester waitForViewWithAccessibilityLabel:@"Date"];
}

- (void)testThatSLEntityViewControllerCanDislayAStaticEnumSection
{
    self.entity.stringValue = @"value 0";

    NSArray *values = @[ @"value 0", @"value 1", @"value 2", @"value 3" ];
    NSArray *options = @[ @"Option 0", @"Option 1", @"Option 2", @"Option 3" ];

    SLEntityViewControllerSection *enumSection = [SLEntityViewControllerSection staticSectionWithEnumValue:values humanReadableOptions:options forAttribute:@"stringValue"];
    SLEntityViewControllerSection *dummySection = [SLEntityViewControllerSection staticSectionWithProperties:@[ @"dummyBool" ]];
    self.viewController.sections = @[ dummySection, enumSection, dummySection ];

    [tester tapViewWithAccessibilityLabel:options[0]];
    expect(self.entity.stringValue).to.equal(values[0]);

    [tester tapViewWithAccessibilityLabel:options[3]];
    expect(self.entity.stringValue).to.equal(values[3]);

    [tester tapViewWithAccessibilityLabel:options[1]];
    expect(self.entity.stringValue).to.equal(values[1]);
}

- (void)testThatSLEntityViewControllerCanHideAStaticEnumSection
{
    self.entity.stringValue = @"value 0";
    self.entity.booleanValue = @NO;

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"booleanValue == NO"];
    [self.viewController onlyShowAttribute:@"stringValue" whenPredicateEvaluates:predicate];

    NSArray *values = @[ @"value 0", @"value 1", @"value 2", @"value 3" ];
    NSArray *options = @[ @"Option 0", @"Option 1", @"Option 2", @"Option 3" ];

    SLEntityViewControllerSection *staticSection = [SLEntityViewControllerSection staticSectionWithProperties:@[ @"booleanValue" ]];
    SLEntityViewControllerSection *enumSection = [SLEntityViewControllerSection staticSectionWithEnumValue:values humanReadableOptions:options forAttribute:@"stringValue"];
    SLEntityViewControllerSection *dummySection = [SLEntityViewControllerSection staticSectionWithProperties:@[ @"dummyBool" ]];
    self.viewController.sections = @[ dummySection, staticSection, enumSection, dummySection ];

    [tester waitForViewWithAccessibilityLabel:options.firstObject];

    [tester setOn:YES forSwitchWithAccessibilityLabel:@"BOOL"];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:options.firstObject];
}

- (void)testThatSLEntityViewControllerCanDislayDynamicSectionForToOneRelationships
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([SLEntity2 class])];
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ];

    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                 managedObjectContext:self.context
                                                                                   sectionNameKeyPath:nil cacheName:nil];

    SLEntityViewControllerSection *dummySection = [SLEntityViewControllerSection staticSectionWithProperties:@[ @"dummyBool" ]];
    SLEntityViewControllerSection *dynamicSection = [SLEntityViewControllerSection dynamicSectionWithRelationship:@"toOneRelation" fetchedResultsController:controller formatBlock:^NSString *(SLEntity2 *entity) {
        return entity.name;
    }];

    dynamicSection.titleText = @"toOneRelation";

    self.viewController.sections = @[ dummySection, dynamicSection, dummySection ];

    SLEntity2 *entity1 = createEntity2WithName(@"Name 1");
    [tester waitForViewWithAccessibilityLabel:entity1.name];

    SLEntity2 *entity2 = createEntity2WithName(@"Name 2");
    [tester waitForViewWithAccessibilityLabel:entity2.name];

    SLEntity2 *entity3 = createEntity2WithName(@"Name 3");
    [tester waitForViewWithAccessibilityLabel:entity3.name];

    [tester tapViewWithAccessibilityLabel:entity1.name];
    expect(self.entity.toOneRelation).to.equal(entity1);

    [tester tapViewWithAccessibilityLabel:entity2.name];
    expect(self.entity.toOneRelation).to.equal(entity2);
}

- (void)testThatSLEntityViewControllerCanDislayDynamicSectionForToManyRelationships
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([SLEntity2 class])];
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ];

    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                 managedObjectContext:self.context
                                                                                   sectionNameKeyPath:nil cacheName:nil];

    SLEntityViewControllerSection *dummySection = [SLEntityViewControllerSection staticSectionWithProperties:@[ @"dummyBool" ]];
    SLEntityViewControllerSection *dynamicSection = [SLEntityViewControllerSection dynamicSectionWithRelationship:@"toManyRelation" fetchedResultsController:controller formatBlock:^NSString *(SLEntity2 *entity) {
        return entity.name;
    }];

    dynamicSection.titleText = @"toManyRelation";

    self.viewController.sections = @[ dummySection, dynamicSection, dummySection ];

    SLEntity2 *entity1 = createEntity2WithName(@"Name 1");
    [tester waitForViewWithAccessibilityLabel:entity1.name];

    SLEntity2 *entity2 = createEntity2WithName(@"Name 2");
    [tester waitForViewWithAccessibilityLabel:entity2.name];

    SLEntity2 *entity3 = createEntity2WithName(@"Name 3");
    [tester waitForViewWithAccessibilityLabel:entity3.name];

    [tester tapViewWithAccessibilityLabel:entity1.name];
    expect(self.entity.toManyRelation).to.haveCountOf(1);
    expect(self.entity.toManyRelation).to.contain(entity1);

    [tester tapViewWithAccessibilityLabel:entity2.name];
    expect(self.entity.toManyRelation).to.haveCountOf(2);
    expect(self.entity.toManyRelation).to.contain(entity1);
    expect(self.entity.toManyRelation).to.contain(entity2);

    [tester tapViewWithAccessibilityLabel:entity1.name];
    expect(self.entity.toManyRelation).to.haveCountOf(1);
    expect(self.entity.toManyRelation).to.contain(entity2);
}

- (void)testThatSLEntityViewControllerCanHideADynamicSection
{
    self.entity.booleanValue = @NO;

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([SLEntity2 class])];
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ];

    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                 managedObjectContext:self.context
                                                                                   sectionNameKeyPath:nil cacheName:nil];

    SLEntityViewControllerSection *dummySection = [SLEntityViewControllerSection staticSectionWithProperties:@[ @"dummyBool" ]];
    SLEntityViewControllerSection *staticSection = [SLEntityViewControllerSection staticSectionWithProperties:@[ @"booleanValue" ]];
    SLEntityViewControllerSection *dynamicSection = [SLEntityViewControllerSection dynamicSectionWithRelationship:@"toOneRelation" fetchedResultsController:controller formatBlock:^NSString *(SLEntity2 *entity) {
        return entity.name;
    }];

    dynamicSection.titleText = @"toOneRelation";

    self.viewController.sections = @[ dummySection, staticSection, dynamicSection, dummySection ];

    SLEntity2 *entity1 = createEntity2WithName(@"Name 1");
    [tester waitForViewWithAccessibilityLabel:entity1.name];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"booleanValue == NO"];
    [self.viewController onlyShowAttribute:@"toOneRelation" whenPredicateEvaluates:predicate];

    [tester setOn:YES forSwitchWithAccessibilityLabel:@"BOOL"];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:entity1.name];
}

- (void)testThatSLEntityViewControllerCanDisplayACollapsableEnumSection
{
    NSArray *values = @[ @"value 0", @"value 1", @"value 2", @"value 3" ];
    NSArray *options = @[ @"Option 0", @"Option 1", @"Option 2", @"Option 3" ];

    self.entity.stringValue = values.firstObject;

    [self.viewController onlyShowAttribute:@"booleanValue" whenPredicateEvaluates:[NSPredicate predicateWithBlock:^BOOL(SLEntity1 *evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject.stringValue isEqualToString:values.firstObject];
    }]];

    SLEntityViewControllerSection *enumSection = [SLEntityViewControllerSection staticSectionWithEnumValue:values humanReadableOptions:options forAttribute:@"stringValue"];
    enumSection.isExpandable = YES;

    SLEntityViewControllerSection *staticSection = [SLEntityViewControllerSection staticSectionWithProperties:@[ @"booleanValue" ]];
    self.viewController.sections = @[ enumSection, staticSection ];

    [tester waitForViewWithAccessibilityLabel:@"String"];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:options[1]];

    [tester tapViewWithAccessibilityLabel:@"String"];
    [tester waitForViewWithAccessibilityLabel:options[2]];
    [tester setOn:YES forSwitchWithAccessibilityLabel:@"BOOL"];

    [tester tapViewWithAccessibilityLabel:options[1]];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:options[2]];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"BOOL"];

    expect(self.entity.stringValue).to.equal(values[1]);
    expect(self.entity.booleanValue).to.beTruthy();
}

@end

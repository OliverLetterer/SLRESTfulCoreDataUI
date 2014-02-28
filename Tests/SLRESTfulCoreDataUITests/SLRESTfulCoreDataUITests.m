//
//  SLRESTfulCoreDataUITests.m
//  SLRESTfulCoreDataUITests
//
//  Created by Oliver Letterer on 28.02.14.
//  Copyright (c) 2014 Sparrow-Labs. All rights reserved.
//

#import <SLRESTfulCoreDataUI.h>
#import "SLEntity1.h"
#import "SLTestCoreDataStack.h"

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
                                            };

    [UIApplication sharedApplication].delegate.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:self.viewController];
}

- (void)tearDown
{
    [super tearDown];

    [[SLTestCoreDataStack sharedInstance] wipeDataStore];
}

- (void)testThatSLEntityViewControllerCanDisplayAStaticSection
{
    NSArray *attributes = @[ @"booleanValue", @"dateValue", @"stringValue" ];
    SLEntityViewControllerSection *staticSection = [SLEntityViewControllerSection staticSectionWithProperties:attributes];

    self.viewController.sections = @[ staticSection ];

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

    self.viewController.sections = @[ staticSection ];

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

    staticSection1.titleText = @"Section 1";
    staticSection2.titleText = @"Section 1";

    self.viewController.sections = @[ staticSection1, staticSection2 ];

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

@end

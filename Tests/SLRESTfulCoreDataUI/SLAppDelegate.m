//
//  SLAppDelegate.m
//  SLRESTfulCoreDataUI
//
//  Created by Oliver Letterer on 28.02.14.
//  Copyright (c) 2014 Sparrow-Labs. All rights reserved.
//

#import "SLAppDelegate.h"
#import "SLEntity1.h"
#import "SLEntity2.h"
#import "SLTestCoreDataStack.h"

#import <SLEntityViewController.h>
#import <SLEntitySwitchCell.h>

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

@implementation SLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[SLTestCoreDataStack sharedInstance] wipeDataStore];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    NSManagedObjectContext *context = [SLTestCoreDataStack sharedInstance].mainThreadManagedObjectContext;
    SLEntity1 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity1 class])
                                                      inManagedObjectContext:context];

    SLEntityViewController *viewController = [[SLEntityViewController alloc] initWithEntity:entity editingType:SLEntityViewControllerEditingTypeCreate];
    viewController.hightlightedSectionColor = [UIColor redColor];
    viewController.expandedSectionBackgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];

    viewController.propertyMapping = @{
                                       @"booleanValue": @"BOOL",
                                       @"stringValue": @"String",
                                       @"dateValue": @"Date",
                                       @"dummyBool": @"dummy",
                                       @"toOneRelation": @"toOneRelation",
                                       @"toManyRelation": @"toManyRelation",
                                       };

    {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([SLEntity2 class])];
        fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ];

        NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                     managedObjectContext:entity.managedObjectContext
                                                                                       sectionNameKeyPath:nil cacheName:nil];

        SLEntity2 *entity1 = createEntity2WithName(@"Name 1");
        SLEntity2 *entity2 = createEntity2WithName(@"Name 2");
        SLEntity2 *entity3 = createEntity2WithName(@"Name 3");

        SLEntityViewControllerSection *dynamicSection = [SLEntityViewControllerSection dynamicSectionWithRelationship:@"toManyRelation" fetchedResultsController:controller formatBlock:^NSString *(SLEntity2 *entity) {
            return entity.name;
        }];
        dynamicSection.isExpandable = YES;

        SLEntityViewControllerSection *staticSection = [SLEntityViewControllerSection staticSectionWithProperties:@[ @"booleanValue" ]];
        viewController.sections = @[ dynamicSection, staticSection ];
    }
    
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:viewController];

//    UIViewController *dummyViewController = [[UIViewController alloc] init];
//    self.window.rootViewController = dummyViewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

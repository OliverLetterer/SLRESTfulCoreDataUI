//
//  SLTestCoreDataStack.m
//  SLRESTfulCoreDataUI
//
//  Created by Oliver Letterer on 28.02.14.
//  Copyright 2014 Sparrow-Labs. All rights reserved.
//

#import "SLTestCoreDataStack.h"
#import <SLRESTfulCoreData.h>

__attribute__((constructor))
void SLRESTfulCoreDataTestsInitialize(void)
{
    [NSManagedObject registerDefaultMainThreadManagedObjectContextWithAction:^NSManagedObjectContext *{
        return [SLTestCoreDataStack sharedInstance].mainThreadManagedObjectContext;
    }];

    [NSManagedObject registerDefaultBackgroundThreadManagedObjectContextWithAction:^NSManagedObjectContext *{
        return [SLTestCoreDataStack sharedInstance].backgroundThreadManagedObjectContext;
    }];
}

@implementation SLTestCoreDataStack

- (void)wipeDataStore
{
    NSManagedObjectModel *model = self.managedObjectModel;

    for (NSEntityDescription *entity in model.entities) {
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entity.name];

        NSError *error = nil;
        NSArray *objects = [self.mainThreadManagedObjectContext executeFetchRequest:request error:&error];
        NSAssert(error == nil, @"");

        for (NSManagedObject *object in objects) {
            [self.mainThreadManagedObjectContext deleteObject:object];
        }
    }

    NSError *saveError = nil;
    [self.mainThreadManagedObjectContext save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
}

- (NSString *)managedObjectModelName
{
    return @"SLTestCoreDataStack";
}

@end

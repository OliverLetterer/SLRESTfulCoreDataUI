//
//  SLEntity1.h
//  SLRESTfulCoreDataUI
//
//  Created by Oliver Letterer on 28.02.14.
//  Copyright (c) 2014 Sparrow-Labs. All rights reserved.
//

@class SLEntity2;

@interface SLEntity1 : NSManagedObject

@property (nonatomic, strong) NSNumber *booleanValue;
@property (nonatomic, strong) NSString *stringValue;
@property (nonatomic, strong) NSDate *dateValue;

@property (nonatomic, strong) SLEntity2 *toOneRelation;
@property (nonatomic, strong) NSSet *toManyRelation;

@end

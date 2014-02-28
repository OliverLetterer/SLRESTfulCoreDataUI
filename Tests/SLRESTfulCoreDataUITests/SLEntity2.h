//
//  SLEntity2.h
//  SLRESTfulCoreDataUI
//
//  Created by Oliver Letterer on 28.02.14.
//  Copyright (c) 2014 Sparrow-Labs. All rights reserved.
//

@class SLEntity1;

@interface SLEntity2 : NSManagedObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) SLEntity1 *toOneInverse;
@property (nonatomic, strong) SLEntity1 *toManyInverse;

@end

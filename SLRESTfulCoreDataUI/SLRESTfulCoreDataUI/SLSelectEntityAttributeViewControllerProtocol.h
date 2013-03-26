//
//  SLSelectEntityAttributeViewControllerProtocol.h
//  iCuisineAPI
//
//  Created by Oliver Letterer on 26.03.13.
//  Copyright 2013 SparrowLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>



/**
 @abstract  <#abstract comment#>
 */
@protocol SLSelectEntityAttributeViewControllerProtocol <NSObject>

- (id)initWithEntity:(NSManagedObject *)entity attribute:(NSString *)attribute;

@end

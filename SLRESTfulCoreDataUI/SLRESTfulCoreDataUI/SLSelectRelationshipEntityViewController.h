//
//  SLSelectRelationshipEntityViewController.h
//  iCuisineAPI
//
//  Created by Oliver Letterer on 26.03.13.
//  Copyright 2013 SparrowLabs. All rights reserved.
//



/**
 @abstract  <#abstract comment#>
 */
@interface SLSelectRelationshipEntityViewController : UITableViewController <UIViewControllerRestoration, UIDataSourceModelAssociation>

@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readonly) NSRelationshipDescription *relationshipDescription;
@property (nonatomic, readonly) NSManagedObject *entity;
@property (nonatomic, readonly) NSString *keyPathForName;

- (id)initWithFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController relationshipDescription:(NSRelationshipDescription *)relationshipDescription entity:(NSManagedObject *)entity keyPathForName:(NSString *)keyPathForName;

@end

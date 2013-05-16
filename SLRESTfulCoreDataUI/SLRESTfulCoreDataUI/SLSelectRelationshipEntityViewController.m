//
//  SLSelectRelationshipEntityViewController.m
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

#import "SLSelectRelationshipEntityViewController.h"
#import "SLEntityTableViewCell.h"
#import <objc/message.h>

static NSString *capitalizedString(NSString *string)
{
    if (string.length == 0) {
        return @"";
    }
    
    return [[string substringToIndex:1] stringByAppendingString:[string substringFromIndex:1]];
}



@interface SLSelectRelationshipEntityViewController () <NSFetchedResultsControllerDelegate> {
    
}

@end



@implementation SLSelectRelationshipEntityViewController

#pragma mark - setters and getters

#pragma mark - Initialization

- (id)initWithFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController relationshipDescription:(NSRelationshipDescription *)relationshipDescription entity:(NSManagedObject *)entity keyPathForName:(NSString *)keyPathForName
{
    NSParameterAssert(fetchedResultsController);
    
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        _fetchedResultsController = fetchedResultsController;
        _relationshipDescription = relationshipDescription;
        _entity = entity;
        _keyPathForName = keyPathForName;
        
        self.fetchedResultsController.delegate = self;
        
        NSError *error = nil;
        [self.fetchedResultsController performFetch:&error];
        NSAssert(error == nil, @"controller %@ error: %@", self.fetchedResultsController, error);
        
        NSAssert(self.fetchedResultsController.sectionNameKeyPath == nil, @"sectionNameKeyPath not supported right now");
        
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
    return self.fetchedResultsController.fetchedObjects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SLEntityTableViewCell";
    
    SLEntityTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[SLEntityTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSManagedObject *thisEntity = self.fetchedResultsController.fetchedObjects[indexPath.row];
    cell.textLabel.text = [thisEntity valueForKey:self.keyPathForName];
    
    if (self.relationshipDescription.isToMany) {
        NSSet *set = [self.entity valueForKey:self.relationshipDescription.name];
        cell.accessoryType = [set containsObject:thisEntity] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    } else {
        cell.accessoryType = thisEntity == [self.entity valueForKey:self.relationshipDescription.name] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    
    return cell;
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
    NSManagedObject *thisEntity = self.fetchedResultsController.fetchedObjects[indexPath.row];
    
    if (self.relationshipDescription.isToMany) {
        NSSet *set = [self.entity valueForKey:self.relationshipDescription.name];
        SEL addOrDeleteSelector = NULL;
        
        if ([set containsObject:thisEntity]) {
            addOrDeleteSelector = NSSelectorFromString([NSString stringWithFormat:@"remove%@Object:", capitalizedString(self.relationshipDescription.name)]);
        } else {
            addOrDeleteSelector = NSSelectorFromString([NSString stringWithFormat:@"add%@Object:", capitalizedString(self.relationshipDescription.name)]);
        }
        
        objc_msgSend(self.entity, addOrDeleteSelector, thisEntity);
        
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        [self.tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationNone];
    } else {
        [self.entity setValue:thisEntity forKey:self.relationshipDescription.name];
        [self.navigationController popViewControllerAnimated:YES];
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

#pragma mark - Private category implementation ()

@end

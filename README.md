# SLRESTfulCoreDataUI [![Build Status](https://travis-ci.org/OliverLetterer/SLRESTfulCoreDataUI.png)](https://travis-ci.org/OliverLetterer/SLRESTfulCoreDataUI) ![Version Badge](https://cocoapod-badges.herokuapp.com/v/SLRESTfulCoreDataUI/badge.png) ![License Badge](https://go-shields.herokuapp.com/license-MIT-blue.png)

SLRESTfulCoreDataUI is the UI pendent to [SLRESTfulCoreData](https://github.com/OliverLetterer/SLRESTfulCoreData) and right now has the ability to create and edit entities backed by SLRESTfulCoreData.

## Installation

```ruby
pod 'SLRESTfulCoreDataUI', '~> 1.0'
```

## Usage

SLEntityViewController is a UITableViewController subclass which manages and creates or edit a NSManagedObject entity.

Let's take the following sample entity as a reference:

``` objc
@interface SLEntity1 : NSManagedObject

@property (nonatomic, strong) NSNumber *dummyBool;

@property (nonatomic, strong) NSNumber *booleanValue;
@property (nonatomic, strong) NSString *stringValue;
@property (nonatomic, strong) NSDate *dateValue;

@property (nonatomic, strong) SLEntity2 *toOneRelation;
@property (nonatomic, strong) NSSet *toManyRelation;

@end
```

To setup and configure SLEntityViewController:

``` objc
SLEntityViewController *viewController = [[SLEntityViewController alloc] initWithEntity:self.entity editingType:SLEntityViewControllerEditingTypeCreate];

/*
setup property mapping, keys are the attributes of the entity 
and values their human readable representation which will be displayed to to user
*/
viewController.propertyMapping = @{
  @"booleanValue": NSLocalizedString(@"BOOL", @""),
  @"stringValue": NSLocalizedString(@"String", @""),
  @"dateValue": NSLocalizedString(@"Date", @""),
  @"dummyBool": NSLocalizedString(@"dummy", @""),
};

// setup completion handler
[self.viewController setCompletionHandler:^(BOOL didSaveEntity) {
  // called when done, dismiss view controller here
}];
```

## Contact
Oliver Letterer

- http://github.com/OliverLetterer
- http://twitter.com/oletterer

## License
SPLWindow is available under the MIT license. See the LICENSE file for more information.

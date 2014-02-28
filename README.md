# SLRESTfulCoreDataUI

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

## Contact
Oliver Letterer

- http://github.com/OliverLetterer
- http://twitter.com/oletterer

## License
SPLWindow is available under the MIT license. See the LICENSE file for more information.

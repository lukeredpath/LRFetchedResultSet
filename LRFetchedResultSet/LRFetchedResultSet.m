//
//  LRFetchedResultSet.m
//  LRFetchedResultSet
//
//  Created by Luke Redpath on 10/12/2012.
//  Copyright (c) 2012 LJR Software Ltd. All rights reserved.
//

#import "LRFetchedResultSet.h"

@interface LRFetchedResultSet ()

@property (nonatomic, copy) LRFetchedResultSetChangeBlock changeBlock;

@end

@implementation LRFetchedResultSet {
  NSFetchRequest *_fetchRequest;
  NSManagedObjectContext *_managedObjectContext;
}

- (id)initWithObjects:(NSArray *)objects fetchRequest:(NSFetchRequest *)fetchRequest managedObjectContext:(NSManagedObjectContext *)context;
{
  self = [super init];
  if (self) {
    _objects = objects;
    _fetchRequest = fetchRequest;
    _managedObjectContext = context;
  }
  return self;
}

- (NSInteger)count
{
  return _objects.count;
}

- (void)notifyChangesUsingBlock:(LRFetchedResultSetChangeBlock)changeBlock
{
  self.changeBlock = changeBlock;
  
  if (self.changeBlock != nil) {
    [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextObjectsDidChangeNotification object:_managedObjectContext queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
      [self handleChangesToManagedObjectContext:note.userInfo];
    }];
  }
}

#pragma mark - Private

- (void)handleChangesToManagedObjectContext:(NSDictionary *)changes
{
  NSMutableArray *newObjects = [NSMutableArray arrayWithArray:self.objects];
  
  NSMutableDictionary *relevantChanges = [NSMutableDictionary dictionary];
  
  NSSet *relevantInsertedObjects = [[changes objectForKey:NSInsertedObjectsKey] filteredSetUsingPredicate:self.relevancyPredicate];
  
  if (relevantInsertedObjects) {
    [relevantChanges setObject:relevantInsertedObjects forKey:NSInsertedObjectsKey];
    [newObjects addObjectsFromArray:[relevantInsertedObjects allObjects]];
  }
  
  _objects = [newObjects copy];
  
  self.changeBlock(relevantChanges);
}

- (NSPredicate *)entityPredicate
{
  return [NSPredicate predicateWithFormat:@"entity.name == %@", _fetchRequest.entityName];
}

- (NSPredicate *)relevancyPredicate
{
  if (_fetchRequest.predicate == nil) {
    return self.entityPredicate;
  }
  return [NSCompoundPredicate andPredicateWithSubpredicates:@[self.entityPredicate, _fetchRequest.predicate]];
}

@end

@implementation NSManagedObjectContext (LRFetchedResultSet)

- (LRFetchedResultSet *)LR_executeFetchRequestAndReturnResultSet:(NSFetchRequest *)fetchRequest error:(NSError **)errorPtr;
{
  NSArray *results = [self executeFetchRequest:fetchRequest error:errorPtr];
  return [[LRFetchedResultSet alloc] initWithObjects:results fetchRequest:fetchRequest managedObjectContext:self];
}

@end

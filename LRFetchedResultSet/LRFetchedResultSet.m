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

- (void)notifyChangesUsingBlock:(LRFetchedResultSetChangeBlock)changeBlock
{
  self.changeBlock = changeBlock;
  
  if (self.changeBlock != nil) {
    [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextObjectsDidChangeNotification object:_managedObjectContext queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
      [self handleChangesToManagedObjectContext:note.userInfo];
    }];
  }
}

#pragma mark - Collection access

- (NSInteger)count
{
  return _objects.count;
}

- (id)objectAtIndexedSubscript:(NSUInteger)index
{
  return [_objects objectAtIndex:index];
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
  
  NSMutableSet *relevantUpdatedObjects = [NSMutableSet set];
  for (NSManagedObject *object in [changes objectForKey:NSUpdatedObjectsKey]) {
    if ([_objects containsObject:object]) {
      [relevantUpdatedObjects addObject:object];
    }
  }
  [relevantChanges setObject:relevantUpdatedObjects forKey:NSUpdatedObjectsKey];
  
  NSMutableSet *relevantRefreshedObjects = [NSMutableSet set];
  for (NSManagedObject *object in [changes objectForKey:NSRefreshedObjectsKey]) {
    if ([_objects containsObject:object]) {
      [relevantRefreshedObjects addObject:object];
    }
  }
  [relevantChanges setObject:relevantRefreshedObjects forKey:NSRefreshedObjectsKey];
  
  NSMutableSet *relevantDeletedObjects = [NSMutableSet set];
  for (NSManagedObject *object in [changes objectForKey:NSDeletedObjectsKey]) {
    if ([_objects containsObject:object]) {
      [relevantDeletedObjects addObject:object];
    }
  }
  [relevantChanges setObject:relevantDeletedObjects forKey:NSDeletedObjectsKey];
  [newObjects removeObjectsInArray:[relevantDeletedObjects allObjects]];
  
  _objects = [newObjects sortedArrayUsingDescriptors:_fetchRequest.sortDescriptors];
  
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

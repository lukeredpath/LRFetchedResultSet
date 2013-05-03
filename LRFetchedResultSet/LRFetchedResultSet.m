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

- (void)reexecuteFetchRequest;

@end

@implementation LRFetchedResultSet {
  NSFetchRequest *_fetchRequest;
  NSManagedObjectContext *_managedObjectContext;
  id _contextObserver;
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

- (void)dealloc
{
  if (_contextObserver) {
    [[NSNotificationCenter defaultCenter] removeObserver:_contextObserver];
  }
}

- (void)setAlwaysObservesChanges:(BOOL)alwaysObservesChanges
{
  _alwaysObservesChanges = alwaysObservesChanges;
  
  if (_alwaysObservesChanges) {
    [self startObservingChanges];
  }
  else {
    if (self.changeBlock == nil) {
      [self stopObservingChanges];
    }
  }
}

- (void)notifyChangesUsingBlock:(LRFetchedResultSetChangeBlock)changeBlock
{
  self.changeBlock = changeBlock;
  
  if (self.changeBlock || self.alwaysObservesChanges) {
    [self startObservingChanges];
  }
  else {
    [self stopObservingChanges];
  }
}

- (void)startObservingChanges
{
  if (_contextObserver) return;
  
  __weak id weakSelf = self;
  
  _contextObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextObjectsDidChangeNotification object:_managedObjectContext queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
    [weakSelf handleChangesToManagedObjectContext:note.userInfo];
  }];
}

- (void)stopObservingChanges
{
  if (_contextObserver) {
    [[NSNotificationCenter defaultCenter] removeObserver:_contextObserver];
    _contextObserver = nil;
  }
}

- (void)setObjects:(NSArray *)objects
{
  BOOL countChanged = (objects.count != _objects.count);
  
  if (countChanged) {
    [self willChangeValueForKey:@"count"];
  }
  
  _objects = objects;
  
  if (countChanged) {
    [self didChangeValueForKey:@"count"];
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
  
  if (relevantInsertedObjects.count > 0) {
    [relevantChanges setObject:relevantInsertedObjects forKey:NSInsertedObjectsKey];
    [newObjects addObjectsFromArray:[relevantInsertedObjects allObjects]];
  }
  
  NSMutableSet *relevantUpdatedObjects = [[changes objectForKey:NSUpdatedObjectsKey] mutableCopy];
  
  if (relevantUpdatedObjects.count) {
    [relevantUpdatedObjects intersectSet:[NSSet setWithArray:self.objects]];
    [relevantChanges setObject:relevantUpdatedObjects forKey:NSUpdatedObjectsKey];
  }
  
  NSMutableSet *relevantRefreshedObjects = [[changes objectForKey:NSRefreshedObjectsKey] mutableCopy];
  
  if (relevantRefreshedObjects.count) {
    [relevantRefreshedObjects intersectSet:[NSSet setWithArray:self.objects]];
    [relevantChanges setObject:relevantRefreshedObjects forKey:NSRefreshedObjectsKey];
  }
  
  NSMutableSet *relevantDeletedObjects = [[changes objectForKey:NSDeletedObjectsKey] mutableCopy];
  
  if (relevantDeletedObjects.count) {
    [relevantDeletedObjects intersectSet:[NSSet setWithArray:self.objects]];
    [relevantChanges setObject:relevantDeletedObjects forKey:NSDeletedObjectsKey];
    [newObjects removeObjectsInArray:[relevantDeletedObjects allObjects]];
  }
  
  if (relevantChanges.count > 0) {
    [self setObjects:[newObjects sortedArrayUsingDescriptors:_fetchRequest.sortDescriptors]];
    
    if (self.changeBlock) {
      self.changeBlock(relevantChanges);
    }
  }
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

- (void)reexecuteFetchRequest
{
  NSError *error;
  
  [self setObjects:[_managedObjectContext executeFetchRequest:_fetchRequest error:&error]];
  
  if (error) {
    // TODO: handle error
  }
  if (self.changeBlock) {
    self.changeBlock(@{});
  }
}

@end

@implementation LRFetchedResultSet (ForSubclassersOnly)

- (void)reexecuteFetchRequestWithPredicate:(NSPredicate *)predicate
{
  _fetchRequest.predicate = predicate;
  [self reexecuteFetchRequest];
}

- (void)reexecuteFetchRequestWithAndPredicate:(NSPredicate *)predicate
{
  if (_fetchRequest.predicate == nil) {
    [self reexecuteFetchRequestWithPredicate:predicate];
  }
  else {
    [self reexecuteFetchRequestWithPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:@[_fetchRequest.predicate, predicate]]];
  }
}

- (void)reexecuteFetchRequestWithOrPredicate:(NSPredicate *)predicate
{
  if (_fetchRequest.predicate == nil) {
    [self reexecuteFetchRequestWithPredicate:predicate];
  }
  else {
    [self reexecuteFetchRequestWithPredicate:[NSCompoundPredicate orPredicateWithSubpredicates:@[_fetchRequest.predicate, predicate]]];
  }
}

@end

@implementation NSManagedObjectContext (LRFetchedResultSet)

- (LRFetchedResultSet *)LR_executeFetchRequestAndReturnResultSet:(NSFetchRequest *)fetchRequest error:(NSError **)errorPtr;
{
  NSArray *results = [self executeFetchRequest:fetchRequest error:errorPtr];
  
  if (results == nil) return nil;
  
  return [[LRFetchedResultSet alloc] initWithObjects:results fetchRequest:fetchRequest managedObjectContext:self];
}

@end

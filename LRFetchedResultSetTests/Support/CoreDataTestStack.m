//
//  CoreDataTestStack.m
//  LRFetchedResultSet
//
//  Created by Luke Redpath on 10/12/2012.
//  Copyright (c) 2012 LJR Software Ltd. All rights reserved.
//

#import "CoreDataTestStack.h"
#import "LRManagedObjectModelBuilder.h"

@implementation CoreDataTestStack {
  NSManagedObjectContext *_mainContext;
}

+ (NSManagedObjectModel *)testModel
{
  NSManagedObjectModel *model = [[NSManagedObjectModel alloc] init];
  
  LRManagedObjectModelBuilder *builder = [[LRManagedObjectModelBuilder alloc] initWithManagedObjectModel:model];
  
  [builder defineEntityNamed:@"Person" definition:^(LREntityDefinition *definition) {
    [definition addAttribute:@"name" type:NSStringAttributeType isIndexed:NO];
    [definition addAttribute:@"age" type:NSInteger32AttributeType isIndexed:NO];
  }];
  
  [builder defineEntityNamed:@"Company" definition:^(LREntityDefinition *definition) {
    [definition addAttribute:@"name" type:NSStringAttributeType isIndexed:NO];
  }];
  
  [builder build];
  
  return model;
}

+ (id)inMemoryTestStack
{
  CoreDataTestStack *stack = [[self alloc] initWithManagedObjectModel:[self testModel]];
  [stack useInMemoryStore];
  return stack;
}

- (id)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
  if ((self = [super init])) {
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
  }
  return self;
}

- (void)useInMemoryStore
{
  [self.persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:nil];
}

- (NSManagedObjectContext *)mainContext
{
  if (_mainContext == nil) {
    _mainContext = [self newManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType];
  }
  return _mainContext;
}

- (NSManagedObjectContext *)newManagedObjectContextWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType
{
  NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:concurrencyType];
  context.persistentStoreCoordinator = self.persistentStoreCoordinator;
  return context;
}

@end

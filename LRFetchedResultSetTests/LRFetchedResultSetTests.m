//
//  LRFetchedResultSetTests.m
//  LRFetchedResultSetTests
//
//  Created by Luke Redpath on 10/12/2012.
//  Copyright (c) 2012 LJR Software Ltd. All rights reserved.
//

#import "TestHelper.h"
#import "CoreDataTestStack.h"
#import "LRFetchedResultSet.h"

DEFINE_TEST_CASE(LRFetchedResultSetTests) {
  CoreDataTestStack *coreDataStack;
}

- (void)setUp
{
  [super setUp];
    
  coreDataStack = [CoreDataTestStack inMemoryTestStack];
}

- (void)testEmptyResultSetHasNoObjects
{
  NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Person"];

  LRFetchedResultSet *resultSet = [coreDataStack.mainContext LR_executeFetchRequestAndReturnResultSet:fetchRequest error:nil];
  
  expect(resultSet.count).to.equal(0);
}

- (void)testSuccessfulFetchReturnsResultSetWithSomeObjects
{
  NSManagedObject *person = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:coreDataStack.mainContext];
  
  [coreDataStack.mainContext save:nil];
  
  NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:person.entity.name];
  
  LRFetchedResultSet *resultSet = [coreDataStack.mainContext LR_executeFetchRequestAndReturnResultSet:fetchRequest error:nil];
  
  expect(resultSet.count).to.equal(1);
}

- (void)testResultSetNotifiesWhenMatchingEntitiesAreAddedToTheContext
{
  NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Person"];
  
  LRFetchedResultSet *resultSet = [coreDataStack.mainContext LR_executeFetchRequestAndReturnResultSet:fetchRequest error:nil];
  
  __block NSSet *insertedObjects = [NSSet set];
  
  [resultSet notifyChangesUsingBlock:^(NSDictionary *changes) {
    insertedObjects = [changes objectForKey:NSInsertedObjectsKey];
  }];
  
  NSManagedObject *person = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:coreDataStack.mainContext];
  
  expect(insertedObjects).will.contain(person);
}

- (void)testResultSetDoesntNotifyOfNonMatchingEntitiesWhenTheyAreAdded
{
  NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Person"];
  
  LRFetchedResultSet *resultSet = [coreDataStack.mainContext LR_executeFetchRequestAndReturnResultSet:fetchRequest error:nil];
  
  __block NSSet *insertedObjects = [NSSet set];
  
  [resultSet notifyChangesUsingBlock:^(NSDictionary *changes) {
    insertedObjects = [changes objectForKey:NSInsertedObjectsKey];
  }];
  
  NSManagedObject *company = [NSEntityDescription insertNewObjectForEntityForName:@"Company" inManagedObjectContext:coreDataStack.mainContext];
  NSManagedObject *person = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:coreDataStack.mainContext];

  expect(insertedObjects).will.contain(person);
  expect(insertedObjects).willNot.contain(company);
}

- (void)testResultSetDoesntNotifyOfEntitiesThatDontSatisfyTheFetchRequestPredicate
{
  NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Person"];
  fetchRequest.predicate = [NSPredicate predicateWithFormat:@"age < 50"];
  
  LRFetchedResultSet *resultSet = [coreDataStack.mainContext LR_executeFetchRequestAndReturnResultSet:fetchRequest error:nil];
  
  __block NSSet *insertedObjects = [NSSet set];
  
  [resultSet notifyChangesUsingBlock:^(NSDictionary *changes) {
    insertedObjects = [changes objectForKey:NSInsertedObjectsKey];
  }];
  
  NSManagedObject *oldPerson = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:coreDataStack.mainContext];
  [oldPerson setValue:@80 forKeyPath:@"age"];
  
  NSManagedObject *youngPerson = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:coreDataStack.mainContext];
  [youngPerson setValue:@15 forKeyPath:@"age"];
  
  expect(insertedObjects).will.contain(youngPerson);
  expect(insertedObjects).willNot.contain(oldPerson);
}

- (void)testResultSetAlwaysHasLatestRelevantResults
{
  NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Person"];
  
  LRFetchedResultSet *resultSet = [coreDataStack.mainContext LR_executeFetchRequestAndReturnResultSet:fetchRequest error:nil];
  
  __block BOOL changeFired = NO;
  
  [resultSet notifyChangesUsingBlock:^(NSDictionary *changes) {
    changeFired = YES;
  }];
  
  NSManagedObject *person = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:coreDataStack.mainContext];
  
  when(changeFired, ^{
    expect(resultSet.objects).to.contain(person);
  });
}

END_TEST_CASE

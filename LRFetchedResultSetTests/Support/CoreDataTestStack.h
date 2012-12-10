//
//  CoreDataTestStack.h
//  LRFetchedResultSet
//
//  Created by Luke Redpath on 10/12/2012.
//  Copyright (c) 2012 LJR Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CoreDataTestStack : NSObject

@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly) NSManagedObjectContext *mainContext;

+ (id)inMemoryTestStack;
- (id)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel;
- (void)useInMemoryStore;
- (NSManagedObjectContext *)newManagedObjectContextWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType;

@end

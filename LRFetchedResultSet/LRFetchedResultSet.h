//
//  LRFetchedResultSet.h
//  LRFetchedResultSet
//
//  Created by Luke Redpath on 10/12/2012.
//  Copyright (c) 2012 LJR Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^LRFetchedResultSetChangeBlock)(NSDictionary *changeBlock);

@interface LRFetchedResultSet : NSObject

@property (nonatomic, readonly) NSArray *objects;
@property (nonatomic, readonly) NSInteger count;
@property (nonatomic, readonly) NSFetchRequest *fetchRequest;

/* If set to YES, will continuously observe changes to its
 * results, even if a change block has not been set.
 *
 * This can be useful if you need to monitor the changing
 * count of a result set using KVO.
 *
 * Defaults to NO.
 */
@property (nonatomic, assign) BOOL alwaysObservesChanges;

- (void)notifyChangesUsingBlock:(LRFetchedResultSetChangeBlock)changeBlock;
- (id)objectAtIndexedSubscript:(NSUInteger)index;

@end

@interface LRFetchedResultSet (ForSubclassersOnly)

/* Executes the result set's fetch request with the provided predicate
 * replacing any previous predicate that was set.
 */
- (void)reexecuteFetchRequestWithPredicate:(NSPredicate *)predicate;

/* Executes the result set's fetch request with the provided predicate
 * compounded with any existing predicate using AND logic.
 */
- (void)reexecuteFetchRequestWithAndPredicate:(NSPredicate *)predicate;

/* Executes the result set's fetch request with the provided predicate
 * compounded with any existing predicate using OR logic.
 */
- (void)reexecuteFetchRequestWithOrPredicate:(NSPredicate *)predicate;

@end

@interface NSManagedObjectContext (LRFetchedResultSet)

- (LRFetchedResultSet *)LR_executeFetchRequestAndReturnResultSet:(NSFetchRequest *)fetchRequest error:(NSError **)errorPtr;

@end

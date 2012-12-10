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

- (void)notifyChangesUsingBlock:(LRFetchedResultSetChangeBlock)changeBlock;
- (id)objectAtIndexedSubscript:(NSUInteger)index;

@end

@interface NSManagedObjectContext (LRFetchedResultSet)

- (LRFetchedResultSet *)LR_executeFetchRequestAndReturnResultSet:(NSFetchRequest *)fetchRequest error:(NSError **)errorPtr;

@end

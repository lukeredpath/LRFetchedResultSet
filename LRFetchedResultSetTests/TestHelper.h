//
//  TestHelper.h
//  CANEventStreamer
//
//  Created by Luke Redpath on 16/11/2012.
//  Copyright (c) 2012 LShift. All rights reserved.
//

#import "SenTestMacros.h"
#define EXP_SHORTHAND
#import "Expecta.h"

#define when(predicate, block) \
  expect(predicate).will.beTruthy(); \
  block(); 

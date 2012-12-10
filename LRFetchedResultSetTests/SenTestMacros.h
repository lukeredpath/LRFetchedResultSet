//
//  SenTestMacros.h
//  CANEventStreamer
//
//  Created by Luke Redpath on 15/11/2012.
//  Copyright (c) 2012 LShift. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#ifndef CANEventStreamer_SenTestMacros_h
#define CANEventStreamer_SenTestMacros_h

#define DEFINE_TEST_CASE_WITH_SUBCLASS(name, subclass) \
@interface name : subclass \
@end \
@implementation name \

#define DEFINE_TEST_CASE(name) DEFINE_TEST_CASE_WITH_SUBCLASS(name, SenTestCase)

#define END_TEST_CASE \
@end

#endif

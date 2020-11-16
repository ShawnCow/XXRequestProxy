//
//  XXRequestProxyParameter.h
//  XXRequestProxy
//
//  Created by Shawn on 2019/12/17.
//  Copyright © 2019 Shawn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XXJSONToModelWrap.h>

@interface XXRequestProxyParameter : NSObject<XXJSONToModelWrap>

@property (nonatomic, copy) NSDictionary *parameter;

@property (nonatomic, copy) NSArray *formparts;

@end

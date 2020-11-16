//
//  XXParameter.h
//  aboard
//
//  Created by Shawn on 2020/8/19.
//  Copyright © 2020 Shawn. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 实现这个协议最新的参数读取协议
 */
@protocol XXParameterVerifyAndPickUpSupport <NSObject>

@optional

/**
 属性key和参数key的映射 比如 把属性为 itemId转成 id 字段  @{@"itemId":@"id"}
 */
- (NSDictionary *)xx_HTTPParamterKeyMapperDictionary;

/**
 属性的mime type 比如 image字段为 image/jpg 就是 @{@"image" :@"image/jpg"}
 */
- (NSDictionary *)xx_HTTPParamterKeyMimeTypeDictionary;

/**
 通过key获取form data的信息
        key:属性
        mimeType:类型
        fileName:文件名
 */
- (NSData *)xx_HTTPParameterFormDataForKey:(NSString *)key mimeType:(NSString **)mimeType fileName:(NSString **)fileName;

@end

/// - 属性具有特性就加上去 比如 字段 userId为必须 @property (nonatomic, strong) NSString <XXParameterRequired, XXHTTPParameterBody> *userId 说明这个属性为必选字段(XXParameterRequired) 不允许为null(DEBUG环境会抛出异常,RELEASE环境会再控制台输出), 请求body参数(XXHTTPParameterBody)

#pragma mark - 属性是否为必要性
/**
 属性不能为null
 */
@protocol XXParameterRequired <NSObject>

@end

/**
 属性忽略
 */
@protocol XXParameterIgnore <NSObject>

@end

/**
 可选, 默认属性
 */
@protocol XXParameterOptional <NSObject>

@end

/**
 不允许为空, 比如string, dictionary, array 长度不能为0
 */
@protocol XXParameterNotEmpty <NSObject>

@end

#pragma mark - 属性的类型

/**
 属性为header字段
 */
@protocol XXHTTPParameterHeader <NSObject>

@end

/**
 属性为url 的query参数
 */
@protocol XXHTTPParameterQuery <NSObject>

@end

/**
 属性为body参数,get请求会放进url, post请求会放进body
 */
@protocol XXHTTPParameterBody <NSObject>

@end

#pragma mark - form data
/**
 属性为POST表单的字段
 */
@protocol XXHTTPParameterForm <NSObject>

@end

/**
 属性为表单的文件 实现这个属性的必须是文件路径
 */
@protocol XXHTTPParameterFormFile <NSObject>

@end

@interface NSObject (XXRemoveWarning)
<
XXParameterRequired,
XXParameterIgnore,
XXParameterOptional,
XXParameterNotEmpty,
XXHTTPParameterHeader,
XXHTTPParameterQuery,
XXHTTPParameterBody,
XXHTTPParameterForm,
XXHTTPParameterFormFile
>
@end

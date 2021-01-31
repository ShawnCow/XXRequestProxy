//
//  XXRequestProxy.m
//  XXRequestProxy
//
//  Created by Shawn on 2019/12/17.
//  Copyright © 2019 Shawn. All rights reserved.
//

#import "XXRequestProxy.h"
#import <XXHTTPRequest+RequestConfig.h>
#include <objc/runtime.h>
#import <KMBaseModel.h>
#import "XXRequestProxyParameter.h"
#import <XXHTTPPostFormDataPart.h>
#import <CoreServices/CoreServices.h>
#import "XXParameter.h"

static NSMutableSet * addMethods;
static NSString * xx_request_method_prefix;

void xxDyConvertParameter(id parameter, NSDictionary **headers, NSDictionary **querys, NSDictionary **parameters,  NSArray **formDatas){
     
    if (parameter) {
        unsigned pCount;
        NSDictionary *tempKeyMapperDic = nil;
        if ([parameter respondsToSelector:@selector(xx_HTTPParamterKeyMapperDictionary)]) {
            tempKeyMapperDic = [(id<XXParameterVerifyAndPickUpSupport>)parameter xx_HTTPParamterKeyMapperDictionary];
        }
        NSDictionary *tempMineKeyDic = nil;
        if ([parameter respondsToSelector:@selector(xx_HTTPParamterKeyMimeTypeDictionary)]) {
            tempMineKeyDic = [(id<XXParameterVerifyAndPickUpSupport>)parameter xx_HTTPParamterKeyMimeTypeDictionary];
        }
        NSDictionary *tempFileNameDic = nil;
        if ([parameter respondsToSelector:@selector(xx_HTTPParamterKeyFileNameDictionary)]) {
            tempFileNameDic = [(id<XXParameterVerifyAndPickUpSupport>)parameter xx_HTTPParamterKeyFileNameDictionary];
        }
        NSMutableDictionary *tempParameterDictionary = [NSMutableDictionary dictionary];
        NSMutableDictionary *tempQueryDictionary = [NSMutableDictionary dictionary];
        NSMutableDictionary *tempHeaderDictionary = [NSMutableDictionary dictionary];
        NSMutableArray *tempFormDatas = [NSMutableArray array];

        if (headers) {
            *headers = tempHeaderDictionary;
        }
        if (querys) {
            *querys = tempQueryDictionary;
        }
        if (parameters) {
            *parameters = tempParameterDictionary;
        }
        if (formDatas) {
            *formDatas = tempFormDatas;
        }
        NSArray *blackList = @[@"debugDescription",@"description",@"hash",@"superclass"];
        
        Class tempCls = [parameter class];
        objc_property_t *properties = class_copyPropertyList(tempCls, &pCount);//属性数组
        for(int i = 0; i < pCount; i ++){
            objc_property_t property = properties[i];
            const char *propertyName = property_getName(property);
            NSString *propertyNameText = [NSString stringWithUTF8String:propertyName];
            if ([blackList containsObject:propertyNameText]) {
                continue;
            }
            NSString *tempMapperKey = tempKeyMapperDic[propertyNameText];
            if (!tempMapperKey) {
                tempMapperKey = propertyNameText;
            }
            const char *attributed = property_getAttributes(property);
            NSString *attrbutedText = [NSString stringWithUTF8String:attributed];
            NSRegularExpression *reg = [[NSRegularExpression alloc] initWithPattern:@"<([^<>]*)>" options:kNilOptions error:nil];
            NSArray * result = [reg matchesInString:attrbutedText options:kNilOptions range:NSMakeRange(0, attrbutedText.length)];
            NSMutableArray *tempProtocolNames = [NSMutableArray array];
            for (int i = 0; i < result.count; i ++) {
                NSTextCheckingResult *tempResult = [result objectAtIndex:i];
                NSString *text = [attrbutedText substringWithRange:NSMakeRange(tempResult.range.location + 1, tempResult.range.length - 2)];
                [tempProtocolNames addObject:text];
            }
            if ([tempProtocolNames containsObject:@"XXParameterIgnore"]) {
                continue;
            }
            id value = [parameter valueForKey:tempMapperKey];
                
            BOOL isHandle = NO;
            
            if ([tempProtocolNames containsObject:@"XXParameterRequired"] && value == nil) {
#ifdef DEBUG
                [[NSException exceptionWithName:@"XXRequestProxyDomain" reason:[NSString stringWithFormat:@"%@ %@不允许为null",tempCls, propertyNameText] userInfo:nil] raise];
#else
                NSLog([NSString stringWithFormat:@"ERROR:%@ %@不允许为null",tempCls, propertyNameText]);
#endif
                continue;
            }
            if ([tempProtocolNames containsObject:@"XXParameterNotEmpty"]) {
                if (value == nil) {
#ifdef DEBUG
                    [[NSException exceptionWithName:@"XXRequestProxyDomain" reason:[NSString stringWithFormat:@"%@ %@不允许为null",tempCls, propertyNameText] userInfo:nil] raise];
#else
                    NSLog([NSString stringWithFormat:@"ERROR:%@ %@不允许为null",tempCls, propertyNameText]);
#endif
                }
                if ([value isKindOfClass:[NSString class]]) {
                    if ([(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
#ifdef DEBUG
                        [[NSException exceptionWithName:@"XXRequestProxyDomain" reason:[NSString stringWithFormat:@"%@ %@不允许为空",tempCls, propertyNameText] userInfo:nil] raise];
#else
                        NSLog([NSString stringWithFormat:@"ERROR:%@ %@不允许为空",tempCls, propertyNameText]);
#endif
                    }
                }
                if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]) {
                    if ([value count] == 0) {
#ifdef DEBUG
                        [[NSException exceptionWithName:@"XXRequestProxyDomain" reason:[NSString stringWithFormat:@"%@ %@不允许为空",tempCls, propertyNameText] userInfo:nil] raise];
#else
                        NSLog([NSString stringWithFormat:@"ERROR:%@ %@不允许为空",tempCls, propertyNameText]);
#endif
                    }
                }
            }
            
            if (value) {
                Class valueClass = [value class];
                Protocol *supportProtocol = NSProtocolFromString(@"XXParameterVerifyAndPickUpSupport");
                if (class_conformsToProtocol(valueClass, supportProtocol)) {
                    NSDictionary *tempNodeParameter = nil;
                    xxDyConvertParameter(value, nil, nil, &tempNodeParameter, nil);
                    if (tempNodeParameter) {
                        [tempParameterDictionary setValue:tempNodeParameter forKey:tempMapperKey];
                    }
                    continue;
                }
            }
       
            if ([tempProtocolNames containsObject:@"XXHTTPParameterHeader"]) {
                [tempHeaderDictionary setValue:value forKey:tempMapperKey];
                isHandle = YES;
            }
            if ([tempProtocolNames containsObject:@"XXHTTPParameterQuery"]) {
                [tempQueryDictionary setValue:value forKey:tempMapperKey];
                isHandle = YES;
            }
            if ([tempProtocolNames containsObject:@"XXHTTPParameterBody"]) {
                [tempParameterDictionary setValue:value forKey:tempMapperKey];
                isHandle = YES;
            }
            if ([tempProtocolNames containsObject:@"XXHTTPParameterForm"]) {
                isHandle = YES;
                NSString *mimeType = [tempMineKeyDic objectForKey:propertyNameText];
                NSString *fileName = [tempFileNameDic objectForKey:propertyNameText];
                
                if ([value isKindOfClass:[NSString class]]) {
                    XXHTTPPostFormDataPart *tempItem = [[XXHTTPPostFormDataPart alloc]initWithData:[(NSString *)value dataUsingEncoding:NSUTF8StringEncoding] mimeType:mimeType filename:fileName name:tempMapperKey];
                    [tempFormDatas addObject:tempItem];
                }else if ([value isKindOfClass:[NSData class]])
                {
                    XXHTTPPostFormDataPart *tempItem = [[XXHTTPPostFormDataPart alloc]initWithData:value mimeType:mimeType filename:fileName name:tempMapperKey];
                    [tempFormDatas addObject:tempItem];
                }else if ([(NSObject *)value respondsToSelector:@selector(xx_HTTPParameterFormDataForKey:mimeType:fileName:)])
                {
                    NSString *fileName = nil;
                    NSString *callBackMineType = nil;
                    NSData *data = [(id<XXParameterVerifyAndPickUpSupport>)parameter xx_HTTPParameterFormDataForKey:propertyNameText mimeType:&callBackMineType fileName:&fileName];
                    if (data == nil || data.length == 0) {
                        continue;
                    }
                    if (callBackMineType) {
                        mimeType = callBackMineType;
                    }
                    XXHTTPPostFormDataPart *tempItem = [[XXHTTPPostFormDataPart alloc]initWithData:data mimeType:mimeType filename:nil name:tempMapperKey];
                    [tempFormDatas addObject:tempItem];
                }
            }
            if ([tempProtocolNames containsObject:@"XXHTTPParameterFormFile"] && [value isKindOfClass:[NSString class]]) {
                isHandle = YES;
                BOOL isDir = NO;
                if ([[NSFileManager defaultManager] fileExistsAtPath:value isDirectory:&isDir] == NO) {
#ifdef DEBUG
                    [[NSException exceptionWithName:@"XXRequestProxyDomain" reason:[NSString stringWithFormat:@"%@ %@文件路径不存在",tempCls, propertyNameText] userInfo:nil] raise];
#else
                    NSLog([NSString stringWithFormat:@"ERROR:%@ %@文件路径不存在",tempCls, propertyNameText]);
#endif
                }else{
                    if (isDir) {
#ifdef DEBUG
                        [[NSException exceptionWithName:@"XXRequestProxyDomain" reason:[NSString stringWithFormat:@"%@ %@文件路径为目录",tempCls, propertyNameText] userInfo:nil] raise];
#else
                        NSLog([NSString stringWithFormat:@"ERROR:%@ %@文件路径为目录",tempCls, propertyNameText]);
#endif
                    }else
                    {
                        NSString *filePath = (NSString *)value;
                        NSString *extension = [[filePath lastPathComponent]pathExtension];
                        NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
                        NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
                        if (!mimeType) {
                            mimeType = @"application/octet-stream";
                        }
                        XXHTTPPostFormDataPart *tempItem = [[XXHTTPPostFormDataPart alloc]initWithData:[NSData dataWithContentsOfFile:filePath] mimeType:mimeType filename:[filePath lastPathComponent] name:tempMapperKey];
                        [tempFormDatas addObject:tempItem];
                    }
                }
            }
            
            if (isHandle == NO) {
                [tempParameterDictionary setValue:value forKey:tempMapperKey];
            }
        }
    }
}

NSURLSessionTask * xxDyProxyMethod(id self, SEL _cmd, id parameter,id response, XXHTTPRequestCompletion completion)
{
    NSString *methodName = NSStringFromSelector(_cmd);
    NSString *subText = [methodName substringFromIndex:xx_request_method_prefix.length];
    NSInteger parameterLocation = [subText rangeOfString:@":"].location;
    NSString *methodBody = [subText substringToIndex:parameterLocation];
    methodBody = [methodBody stringByReplacingOccurrencesOfString:@"__" withString:@"&&"];
    NSMutableArray *methodArray = [[methodBody componentsSeparatedByString:@"_"] mutableCopy];
    for (int i = 0; i < methodArray.count; i ++) {
        NSString *tempItemText = methodArray[i];
        if ([tempItemText containsString:@"&&"]) {
            [methodArray replaceObjectAtIndex:i withObject:[tempItemText stringByReplacingOccurrencesOfString:@"&&" withString:@"-"]];
        }
    }
    XXHTTPRequest *request = nil;
    BOOL isGet = NO;
    if ([[methodArray.firstObject lowercaseString] isEqualToString:@"get"]) {
        request = [XXHTTPRequest defaultGETHTTPRequest];
        isGet = YES;
    }else
    {
        request = [XXHTTPRequest defaultPOSTHTTPRequest];
    }
    if (methodArray.count > 1) {
        request.URLString = [[methodArray subarrayWithRange:NSMakeRange(1, methodArray.count - 1)] componentsJoinedByString:@"/"];
    }
    
    if (parameter) {
        Class parameterClass = [parameter class];
        Protocol *supportProtocol = NSProtocolFromString(@"XXParameterVerifyAndPickUpSupport");
        if (class_conformsToProtocol(parameterClass, supportProtocol)) {
            NSDictionary *headersDic = nil;
            NSDictionary *querysDic = nil;
            NSDictionary *paramDic = nil;
            NSArray *formDataArray = nil;
            xxDyConvertParameter(parameter, &headersDic, &querysDic, &paramDic, &formDataArray);
            if (headersDic.count > 0) {
                NSMutableDictionary *tempHeaders = [request.headers mutableCopy];
                if (!tempHeaders) {
                    tempHeaders = [NSMutableDictionary dictionary];
                }
                [tempHeaders addEntriesFromDictionary:headersDic];
                request.headers = tempHeaders;
            }
            if (querysDic.count > 0) {
                NSMutableArray *tempQueryKeyValue = [NSMutableArray array];
                for (NSString *tempKey in querysDic.allKeys) {
                    [tempQueryKeyValue addObject:[NSString stringWithFormat:@"%@=%@",tempKey,querysDic[tempKey]]];
                }
                if (isGet) {
                    for (NSString *tempKey in paramDic.allKeys) {
                        [tempQueryKeyValue addObject:[NSString stringWithFormat:@"%@=%@",tempKey,paramDic[tempKey]]];
                    }
                }
                NSMutableString *tempURLString = [request.URLString mutableCopy];
                [tempURLString appendFormat:@"?%@",[tempQueryKeyValue componentsJoinedByString:@"&"]];
                request.URLString = tempURLString;
            }
            
            if (paramDic.count > 0) {
                if (querysDic.count > 0 && isGet) {
                    
                }else{
                    request.parameter = paramDic;
                }
            }
            if (formDataArray.count > 0) {
                request.formBodyParts = formDataArray;
            }
            
        }else{
            if ([parameter isKindOfClass:[KMBaseModel class]]) {
                id tempParameter = [parameter xx_serializerToJSONObject];
                if ([tempParameter isKindOfClass:[XXRequestProxyParameter class]]) {
                    XXRequestProxyParameter *tempItem = (XXRequestProxyParameter *)tempParameter;
                    request.parameter = tempItem.parameter;
                    request.formBodyParts = tempItem.formparts;
                }else{
                    request.parameter = tempParameter;
                }
            }
        }
    }
    
    if (response) {
        if (object_isClass(response)) {
            request.responseORMTargetModelClass = response;
        }else
        {
            request.responseORMTargetModel = response;
        }
    }
    return (NSURLSessionTask *)[request sendRequestWithCompletion:completion];
}

BOOL canResoleMethodName(NSString *methodName, Class cls)
{
    if ([methodName hasPrefix:xx_request_method_prefix]) {
        @synchronized (addMethods) {
            if ([addMethods containsObject:methodName] == NO) {
                class_addMethod(cls, NSSelectorFromString(methodName), (IMP)xxDyProxyMethod, "@:@:@:");
                [addMethods addObject:methodName];
            }
        }
        return YES;
    }
    return NO;
}

@implementation XXRequestProxy

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        addMethods = [NSMutableSet set];
        xx_request_method_prefix = @"xx_request_";
    });
}

+ (BOOL)resolveInstanceMethod:(SEL)sel
{
    if (canResoleMethodName(NSStringFromSelector(sel), self)) {
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}

@end

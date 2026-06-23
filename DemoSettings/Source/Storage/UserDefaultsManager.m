//
//  UserDefaultsManager.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/20.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "UserDefaultsManager.h"

static NSString * const kUserDefaultsManagerSuiteName = @"PlayerKit-AppSettings_Prefs";

@interface UserDefaultsManager ()

@property (nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation UserDefaultsManager

#pragma mark - Singleton

+ (instancetype)sharedInstance {
    static UserDefaultsManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[UserDefaultsManager alloc] initPrivate];
    });
    return instance;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _userDefaults = [[NSUserDefaults alloc] initWithSuiteName:kUserDefaultsManagerSuiteName];
    }
    return self;
}

#pragma mark - String

- (void)saveString:(nullable NSString *)value forKey:(NSString *)key {
    [self.userDefaults setObject:value forKey:key];
}

- (nullable NSString *)stringForKey:(NSString *)key {
    return [self.userDefaults stringForKey:key];
}

#pragma mark - Integer

- (void)saveInteger:(NSInteger)value forKey:(NSString *)key {
    [self.userDefaults setInteger:value forKey:key];
}

- (NSInteger)integerForKey:(NSString *)key defValue:(NSInteger)defValue {
    id value = [self.userDefaults objectForKey:key];
    return value ? [self.userDefaults integerForKey:key] : defValue;
}

#pragma mark - Boolean

- (void)saveBool:(BOOL)value forKey:(NSString *)key {
    [self.userDefaults setBool:value forKey:key];
}

- (BOOL)boolForKey:(NSString *)key defValue:(BOOL)defValue {
    id value = [self.userDefaults objectForKey:key];
    return value ? [self.userDefaults boolForKey:key] : defValue;
}

#pragma mark - Float

- (void)saveFloat:(float)value forKey:(NSString *)key {
    [self.userDefaults setFloat:value forKey:key];
}

- (float)floatForKey:(NSString *)key defValue:(float)defValue {
    id value = [self.userDefaults objectForKey:key];
    return value ? [self.userDefaults floatForKey:key] : defValue;
}

#pragma mark - Remove

- (void)removeForKey:(NSString *)key {
    [self.userDefaults removeObjectForKey:key];
}

- (void)clearAll {
    NSDictionary *allKeys = [self.userDefaults dictionaryRepresentation];
    for (NSString *key in allKeys) {
        [self.userDefaults removeObjectForKey:key];
    }
}

@end

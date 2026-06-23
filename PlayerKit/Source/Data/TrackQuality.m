//
//  TrackQuality.m
//  AliPlayerKit
//
//  Created by keria on 2024/10/18.
//  Copyright © 2024 Alibaba Cloud. All rights reserved.
//

#import "TrackQuality.h"

@implementation TrackQuality

- (instancetype)initWithIndex:(NSInteger)index
                         type:(TrackType)type
                        width:(NSInteger)width
                       height:(NSInteger)height {
    self = [super init];
    if (self) {
        _index = index;
        _type = type;
        _width = width;
        _height = height;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"TrackQuality{index=%ld, type=%ld, width=%ld, height=%ld}",
            (long)self.index, (long)self.type, (long)self.width, (long)self.height];
}

@end

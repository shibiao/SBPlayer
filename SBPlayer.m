//
//  SBPlayer.m
//  Audio
//
//  Created by ShiBiao on 2018/8/6.
//  Copyright © 2018年 石彪. All rights reserved.
//

#import "SBPlayer.h"

@interface SBPlayer(){
    id playbackTimerObserver;
}
@property (nonatomic , strong) AVPlayerItem *item;

@property (nonatomic,strong) NSView *superView;
@end
@implementation SBPlayer
//MARK: Setter方法
-(void)setControlStyle:(AVPlayerViewControlsStyle)controlStyle {
    _controlStyle = controlStyle;
    if (self.playerView) {
        self.playerView.controlsStyle = controlStyle;
    }
}
-(instancetype)initWithURL:(NSURL *)url withDelegate:(id<SBPlayerDelegate>) delegate
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        dispatch_queue_t sbplayerQueue = dispatch_queue_create("sb.com.sbplayer.queue", DISPATCH_QUEUE_CONCURRENT);
        dispatch_async(sbplayerQueue, ^{
            [self createMediaPlayerWithURL:url];
        });
        
    }
    return self;
}
-(instancetype)initWithURL:(NSURL *)url view:(NSView *)view withDelegate:(id<SBPlayerDelegate>) delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;
        _superView = view;
        [self createMediaPlayerWithURL:url];
    }
    return self;
}
//MARK: 创建媒体资源
-(void)createMediaPlayerWithURL:(NSURL *)url {
    //开始安全域资源
    [url startAccessingSecurityScopedResource];
    _url = url;
    if (self.item) {
        [self removeObservers];
    }
    self.item = [[AVPlayerItem alloc]initWithAsset:[self assetWithURL:url]];
    self.player = [[AVPlayer alloc]initWithPlayerItem:self.item];
    __weak typeof(self) weakSelf = self;
    if (_superView) {
        self.playerView = [[AVPlayerView alloc]initWithFrame:self.superView.bounds];
        self.playerView.player = self.player;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.superView addSubview:weakSelf.playerView];
        });
        
    }
    [self addKVO];
    [self addNotificationCenter];
    
}
//切换音视频
-(void)replaceSBPlayerItemWithURL:(NSURL *)url {
    //停止安全域资源
    if (_url) {
        [_url stopAccessingSecurityScopedResource];
    }
    [self createMediaPlayerWithURL:url];
}
//MARK: NSURLAsset资源，可以获取音频预览图片，音乐名称，作家等等
-(AVURLAsset *)assetWithURL:(NSURL *)url {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSMutableDictionary *assetDic = [[NSMutableDictionary alloc]init];
    for (NSString *format in asset.availableMetadataFormats) {
        for (AVMetadataItem *metaDataItem in [asset metadataForFormat:format]) {
            NSLog(@"%@---%@",metaDataItem.commonKey,metaDataItem.value);
            if (metaDataItem.commonKey == nil || metaDataItem.value == nil) {
                continue;
            }
            [assetDic setObject:metaDataItem.value forKey:metaDataItem.commonKey];
            if ([self.delegate respondsToSelector:@selector(sbPlayerAssetWithAVMetadataItemValue:andCommonKey:)]) {
                [self.delegate sbPlayerAssetWithAVMetadataItemValue:metaDataItem.value andCommonKey:metaDataItem.commonKey];
            }
        }
    }
    _assetDictionary = assetDic;
    return asset;
}
//MARK: Tracking time,跟踪时间的改变
-(void)addPeriodicTimeObserver{
    __weak typeof(self) weakSelf = self;
    if (playbackTimerObserver != nil) {
        return;
    }
    playbackTimerObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.f, 1.f) queue:NULL usingBlock:^(CMTime time) {
        if (!CMTIME_IS_INDEFINITE(self.item.duration)) {
//            weakSelf.volumeSlider.integerValue = [Tool timeIntervalConvertFromCMTime:time];
            if ([weakSelf.delegate respondsToSelector:@selector(sbPlayer:didStartPeriodicTimeObserverWith:)]) {
                [weakSelf.delegate sbPlayer:weakSelf didStartPeriodicTimeObserverWith:time];
            }
        }
    }];
}
//添加KVO
-(void)addKVO {
    [self.item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监听网络加载情况属性
    [self.item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //监听播放的区域缓存是否为空
    [self.item addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    //缓存可以播放的时候调用
    [self.item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    [self.player addObserver:self forKeyPath:@"timeControlStatus" options:NSKeyValueObservingOptionNew context:nil];
    
}
//MARK: 处理监听对象
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus itemStatus = [[change objectForKey:NSKeyValueChangeNewKey]integerValue];
        switch (itemStatus) {
            case AVPlayerItemStatusUnknown:
            {
                _status = SBPlayerPlaybackStatusUnknown;
                NSLog(@"AVPlayerItemStatusUnknown");
            }
                break;
            case AVPlayerItemStatusReadyToPlay:
            {
                _status = SBPlayerPlaybackStatusReadyToPlay;
                [self addPeriodicTimeObserver];
//                self.volumeSlider.maxValue = [Tool timeIntervalConvertFromCMTime:self.player.currentItem.duration];
                if ([self.delegate respondsToSelector:@selector(sbPlayerStatusReadToPlay:)]) {
                    [self.delegate sbPlayerStatusReadToPlay:self.player];
                }
                NSLog(@"AVPlayerItemStatusReadyToPlay");
            }
                break;
            case AVPlayerItemStatusFailed:
            {
                _status = SBPlayerPlaybackStatusFailed;
                NSLog(@"AVPlayerItemStatusFailed");
            }
                break;
            default:
                break;
        }
    }else if ([keyPath isEqualToString:@"timeControlStatus"]) {
        AVPlayerTimeControlStatus timeControlStatus = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        /**
         AVPlayerTimeControlStatusPaused,
         AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate,
         AVPlayerTimeControlStatusPlaying
         */
        switch (timeControlStatus) {
            case AVPlayerTimeControlStatusPaused:
            {
                _status = SBPlayerPlaybackStatusPaused;
            }
                break;
            case AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate:
            {
                _status = SBPlayerPlaybackStatusWaitingToPlayAtSpecifiedRate;
            }
                break;
            case AVPlayerTimeControlStatusPlaying:
            {
                _status = SBPlayerPlaybackStatusPlaying;
            }
                break;
            default:
                break;
        }
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {  //监听播放器的下载进度
        NSArray *loadedTimeRanges = [self.item loadedTimeRanges];
        CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval timeInterval = startSeconds + durationSeconds;// 计算缓冲总进度
        CMTime duration = self.item.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        //缓存值
        _rate=timeInterval / totalDuration;
        NSLog(@"缓存进度-------:%f",_rate);
        if ([self.delegate respondsToSelector:@selector(sbPlayer:downloadingBufferDataWithRate:)]) {
            [self.delegate sbPlayer:self downloadingBufferDataWithRate:_rate];
        }
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) { //监听播放器在缓冲数据的状态
        NSLog(@"开始缓存");
        if ([self.delegate respondsToSelector:@selector(sbPlayerBeginBuffering)]) {
            [self.delegate sbPlayerBeginBuffering];
        }
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        NSLog(@"缓冲达到可播放");
        if ([self.delegate respondsToSelector:@selector(sbPlayerDidBufferDataFinished)]) {
            [self.delegate sbPlayerDidBufferDataFinished];
        }
    }
}
//添加消息中心
-(void)addNotificationCenter {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(SBPlayerItemDidPlayToEndTimeNotificaiton:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.item];
}
-(void)SBPlayerItemDidPlayToEndTimeNotificaiton:(NSNotification *)noti {
    if ([self.delegate respondsToSelector:@selector(sbPlayer:didPlayToEndTimeNotification:)]) {
        [self.delegate sbPlayer:self.player didPlayToEndTimeNotification:noti];
    }
    //停止安全域资源
    [_url stopAccessingSecurityScopedResource];
}
-(void)play {
    if (self.player) {
        [self.player play];
    }
}
-(void)pause {
    if (self.player) {
        [self.player pause];
    }
}
-(void)stop {
    if (self.player) {
        [self.player pause];
        [self.player seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
}
//MARK: 将URL转换成书签数据
+ (NSData*)bookmarkForURL:(NSURL*)url {
    NSError* theError = nil;
    NSData* bookmark = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                     includingResourceValuesForKeys:nil
                                      relativeToURL:nil
                                              error:&theError];
    if (theError || (bookmark == nil)) {
        // Handle any errors.
        return nil;
    }
    return bookmark;
}
//MARK: 将bookmark数据转换成URL
+ (NSURL*)urlForBookmark:(NSData*)bookmark {
    BOOL bookmarkIsStale = NO;
    NSError* theError = nil;
    NSURL* bookmarkURL = [NSURL URLByResolvingBookmarkData:bookmark
                                                   options:NSURLBookmarkResolutionWithoutUI | NSURLBookmarkResolutionWithSecurityScope
                                             relativeToURL:nil
                                       bookmarkDataIsStale:&bookmarkIsStale
                                                     error:&theError];
    
    if (bookmarkIsStale || (theError != nil)) {
        // Handle any errors
        return nil;
    }
    return bookmarkURL;
}
-(void)removeObservers {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self.item removeObserver:self forKeyPath:@"status" context:nil];
    [self.item removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
    [self.item removeObserver:self forKeyPath:@"playbackBufferEmpty" context:nil];
    [self.item removeObserver:self forKeyPath:@"playbackLikelyToKeepUp" context:nil];
    [self.player removeObserver:self forKeyPath:@"timeControlStatus" context:nil];
    [self.player removeTimeObserver:playbackTimerObserver];
    playbackTimerObserver = nil;
    self.item = nil;
    self.player = nil;
}
-(void)dealloc {
    [self removeObservers];
}
@end

//
//  SBPlayer.h
//  Audio
//
//  Created by ShiBiao on 2018/8/6.
//  Copyright © 2018年 石彪. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Cocoa/Cocoa.h>
#import <AVKit/AVKit.h>
@class SBPlayer;
@protocol SBPlayerDelegate<NSObject>
@optional
/**
 此方法可以获取音视频资源信息

 @param value 作者/歌曲名/封面图片等
 @param commonKey 对应的值
 */
-(void)sbPlayerAssetWithAVMetadataItemValue:(id)value andCommonKey:(AVMetadataKey)commonKey;

/**
 此方法用于获取音视频当前播放时间，可以用于赋值给NSSlider等控件，可以改变某些控件当前值，每间隔1s走一次该代理方法

 @param player SBPlayer
 @param time 当前时间CMTime
 */
-(void)sbPlayer:(SBPlayer *)player didStartPeriodicTimeObserverWith:(CMTime)time;

/**
 当播发器正准备播放的时候走此方法，可以初始化一些控件

 @param player SBPlayer
 */
-(void)sbPlayerStatusReadToPlay:(AVPlayer *)player;

/**
 播放结束后走此方法

 @param player AVPlayer播放器
 @param noti NSNotification
 */
-(void)sbPlayer:(AVPlayer *)player didPlayToEndTimeNotification:(NSNotification *)noti;

//开始缓存
-(void)sbPlayerBeginBuffering;
/**
 正在缓冲中

 @param player SBPlayer
 @param rate 缓冲率
 */
-(void)sbPlayer:(SBPlayer *)player downloadingBufferDataWithRate:(CGFloat)rate;
//缓存结束
-(void)sbPlayerDidBufferDataFinished;
@end
typedef NS_ENUM(NSUInteger, SBPlayerPlayBackStatus) {
    SBPlayerPlaybackStatusUnknown,                      //播放状态位置
    SBPlayerPlaybackStatusReadyToPlay,                  //准备播放
    SBPlayerPlaybackStatusFailed,                       //播放失败
    SBPlayerPlaybackStatusPaused,                       //暂停
    SBPlayerPlaybackStatusWaitingToPlayAtSpecifiedRate, //等待以指定的速度播放
    SBPlayerPlaybackStatusPlaying,                      //正在播放
};

@interface SBPlayer : NSObject
/**  播放状态  */
@property (nonatomic , assign) SBPlayerPlayBackStatus  status;
/**  播发器  */
@property (nonatomic , strong) AVPlayer *player;
/**  文件资源内容,如作者，封面等等  */
@property (nonatomic , strong ,readonly) NSDictionary *assetDictionary;
//缓存比率
@property (nonatomic,assign) CGFloat  rate;

/**  代理  */
@property (nonatomic , weak) id<SBPlayerDelegate>  delegate;
//当前播放的URL
@property (nonatomic , strong) NSURL *url;
//播放器控制样式
@property (nonatomic,assign) AVPlayerViewControlsStyle controlStyle;
//承载视频播放的视图
@property (nonatomic,strong) AVPlayerView *playerView;
/**
 实例化SBPlayer

 @param url 视频或者音频url资源
 @return 返回实例化SBPlayer
 */
-(instancetype)initWithURL:(NSURL *)url withDelegate:(id<SBPlayerDelegate>) delegate;

/**
 实例化视频播放器方法

 @param url 视频url资源
 @param view 父视图
 @param delegate 代理方法
 @return 返回实例化SBPlayer
 */
-(instancetype)initWithURL:(NSURL *)url view:(NSView *)view withDelegate:(id<SBPlayerDelegate>) delegate;
//切换音视频
-(void)replaceSBPlayerItemWithURL:(NSURL *)url;
/**  播放  */
-(void)play;
/**  暂停  */
-(void)pause;
/**  开始  */
-(void)stop;

//MARK: 将URL转换成书签数据(开启沙盒的情况下，本地资源用此方法保存url bookmarks data)
+ (NSData*)bookmarkForURL:(NSURL*)url;

//MARK: 将bookmark数据转换成URL (开启沙盒的情况下，本地资源用此方法获取URL资源)
+ (NSURL*)urlForBookmark:(NSData*)bookmark;
@end

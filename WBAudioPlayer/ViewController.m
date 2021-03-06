//
//  ViewController.m
//  WBAudioPlayer
//
//  Created by Bing on 15/3/31.
//  Copyright (c) 2015年 Bing. All rights reserved.
//
#import "WBAudioPlayer.h"
#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UISlider * volume;
@property (weak, nonatomic) IBOutlet UILabel  * time;
@property (weak, nonatomic) IBOutlet UISlider * progress;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@end



@implementation ViewController
{
    WBAudioPlayer * _player;
    NSString      * _duration;
    NSTimer       * _timer;
    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSString * audioFile = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp3"];
    _player = [WBAudioPlayer instance];
    BOOL rt =  [_player createAudioTrack:audioFile];
    if (rt)
    {
        [_player play];
        [_playButton setTitle:@"pause" forState:UIControlStateNormal];
        _duration = [self _timeFormatted:_player.duration];
        [self _configCallback];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (_player.playing)
    {
        [self _initionalTimer];
    }
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self _destroyTimer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)_configCallback
{
    __weak typeof(self) weakSelf = self;
    _player.interrutionBlock = ^(WBAudioPlayerinterruptionType type){
        if (type == WBAudioPlayerinterruptionTypeBegin)
        {
            [weakSelf _pause];
        }else if (type == WBAudioPlayerinterruptionTypeEnd)
        {
            [weakSelf _play];
        }
    };
    _player.remoteEventBlock = ^(WBAudioPlayerRemoteEventType type){
        if (type == WBAudioPlayerRemoteEventTypePlay)
        {
            //响应远程播放事件
            NSLog(@"响应远程播放事件");
            [weakSelf _play];
            
        }else if(type == WBAudioPlayerRemoteEventTypePause){
            //响应远程暂停事件
            NSLog(@"响应远程暂停事件");
            [weakSelf _pause];
        }
    };
    _player.headPhonePlugBlock = ^(WBAudioPlayerHeadPhonePlugType type){
        if (type == WBAudioPlayerHeadPhonePlugTypePlugin)
        {
            //响应耳机插入事件
            NSLog(@"响应耳机插入事件");
        }else{
            //响应耳机拔出事件
            NSLog(@"响应耳机拔出事件");
            [weakSelf _pause];
        }

    };
    _player.playFinishBlock = ^(){
        [weakSelf _pause];
        NSLog(@"播放结束");
    };
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackgroundCallback:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becomeActiveCallback:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
}

- (void)_updateUI
{
    _time.text = [NSString stringWithFormat:@"%@/%@",[self _timeFormatted:_player.currentTime],_duration];
    _progress.value = _player.currentTime/_player.duration;
}

- (NSString *)_timeFormatted:(int)totalSeconds
{
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

- (void)_play
{
    [_playButton setTitle:@"pause" forState:UIControlStateNormal];
    [self _initionalTimer];
}

- (void)_pause
{
    [_playButton setTitle:@"play" forState:UIControlStateNormal];
    [self _destroyTimer];
}

#pragma mark -- NSTimer
- (void)_initionalTimer
{
    [self _destroyTimer];
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_updateUI) userInfo:nil repeats:YES];
    [_timer fire];
}

- (void)_destroyTimer
{
    if (_timer != nil)
    {
        [_timer invalidate];
        _timer = nil;
    }
}

#pragma mark -- UI controller
- (IBAction)volumeChange:(UISlider *)sender
{
   [_player setVolume:sender.value];
}

- (IBAction)finishSeek:(UISlider *)sender
{
    [_player setCurrentTime:sender.value*_player.duration];
    [self _initionalTimer];
    [_player updateNowPlayingInfoWithRate:[_player rate]];
}

- (IBAction)beginSeek:(UISlider *)sender
{
    [self _destroyTimer];
}

- (IBAction)playButtonClick:(UIButton *)sender
{
    if (_player.playing)
    {
        [self _pause];
        [_player pause];
    }else{
        [self _play];
        [_player play];
    }
}
#pragma mark -- UIApplicationDidEnterBackgroundNotification UIApplicationDidBecomeActiveNotification

- (void)enterBackgroundCallback:(NSNotification *)notification
{
    [self _destroyTimer];
}

- (void)becomeActiveCallback:(NSNotification *)notification
{
    [self _initionalTimer];
}
@end

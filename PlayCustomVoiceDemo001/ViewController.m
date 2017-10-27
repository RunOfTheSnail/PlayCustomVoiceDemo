//
//  ViewController.m
//  PlayCustomVoiceDemo001
//
//  Created by Zhang Yan on 2017/10/10.
//  Copyright © 2017年 yan. All rights reserved.
//

#import "ViewController.h"
//包含头文件
#import "iflyMSC/IFlyMSC.h"
#import <AVFoundation/AVFoundation.h>

#define kFileManager [NSFileManager defaultManager]


typedef void(^PlayVoiceBlock)();

@interface ViewController ()<IFlySpeechSynthesizerDelegate,AVAudioPlayerDelegate,AVSpeechSynthesizerDelegate>
{
    
    AVSpeechSynthesizer *synthesizer;
    
}
@property (nonatomic, strong) IFlySpeechSynthesizer *iFlySpeechSynthesizer;
@property (nonatomic, strong)AVAudioPlayer *myPlayer;


// AVSpeechSynthesisVoice 播放完毕之后的回调block
@property (nonatomic, copy)PlayVoiceBlock finshBlock;
@property (nonatomic, strong) NSString *filePath;

@end

static int lianxunPlay = 1;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    
    [self createUI];
    
    
}

- (void)createUI
{
    UIButton *tempBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    tempBtn.frame = CGRectMake(100, 100, 100, 100);
    tempBtn.backgroundColor = [UIColor cyanColor];
    [tempBtn addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:tempBtn];
}

/** 按钮的点击事件 */
- (void)clickBtn:(UIButton *)sender
{
    
    //    [self play1];
    //    [self play2];
    
    //    [self play3];
    
        [self play4];
    
//    [self test5];
    
}





- (void)play1
{
    //创建语音配置,appid必须要传入，仅执行一次则可
    NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@",@"59db7ce2"];
    
    //所有服务启动前，需要确保执行createUtility
    [IFlySpeechUtility createUtility:initString];
    
    //获取语音合成单例
    _iFlySpeechSynthesizer = [IFlySpeechSynthesizer sharedInstance];
    //设置协议委托对象
    _iFlySpeechSynthesizer.delegate = self;
    //设置合成参数
    //设置在线工作方式
    [_iFlySpeechSynthesizer setParameter:[IFlySpeechConstant TYPE_CLOUD]
                                  forKey:[IFlySpeechConstant ENGINE_TYPE]];
    //设置音量，取值范围 0~100
    [_iFlySpeechSynthesizer setParameter:@"50"
                                  forKey: [IFlySpeechConstant VOLUME]];
    //发音人，默认为”xiaoyan”，可以设置的参数列表可参考“合成发音人列表”
    [_iFlySpeechSynthesizer setParameter:@" xiaoyan "
                                  forKey: [IFlySpeechConstant VOICE_NAME]];
    //保存合成文件名，如不再需要，设置为nil或者为空表示取消，默认目录位于library/cache下
    [_iFlySpeechSynthesizer setParameter:@" tts.pcm"
                                  forKey: [IFlySpeechConstant TTS_AUDIO_PATH]];
    //启动合成会话
    [_iFlySpeechSynthesizer startSpeaking: @"12345656778890098765644456789876543456787654567"];
}


//IFlySpeechSynthesizerDelegate协议实现
//合成结束
- (void) onCompleted:(IFlySpeechError *) error {}
//合成开始
- (void) onSpeakBegin {}
//合成缓冲进度
- (void) onBufferProgress:(int) progress message:(NSString *)msg {}
//合成播放进度
- (void) onSpeakProgress:(int) progress beginPos:(int)beginPos endPos:(int)endPos {}


- (void)play2
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    [self lianxuPlay];
}

-(void)lianxuPlay
{
    NSString *pathStr = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%d", lianxunPlay] ofType:@"m4a"];
    NSURL *url = [NSURL fileURLWithPath:pathStr];
    self.myPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    
    self.myPlayer.delegate = self;
    [self.myPlayer play];
    
}


- (void)play3
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    [self hechengVoiceWithFinshBlock:^{
        NSLog(@"播放完毕");
    }];
}


#pragma mark- 合成音频播放，成功
- (void)hechengVoiceWithFinshBlock:(PlayVoiceBlock )block
{
    /************************合成音频并播放*****************************/
    NSMutableArray *audioAssetArray = [[NSMutableArray alloc] init];
    NSMutableArray *durationArray = [[NSMutableArray alloc] init];
    [durationArray addObject:@(0)];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    NSArray *fileNameArray = @[@"daozhang",@"1",@"2",@"3",@"4",@"5",@"6"];
    
    
    CMTime allTime = kCMTimeZero;
    
    for (NSInteger i = 0; i < fileNameArray.count; i++) {
        NSString *auidoPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@",fileNameArray[i]] ofType:@"m4a"];
        AVURLAsset *audioAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:auidoPath]];
        [audioAssetArray addObject:audioAsset];
        
        // 音频轨道
        AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:0];
        // 音频素材轨道
        AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        
        
        // 音频合并 - 插入音轨文件
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration) ofTrack:audioAssetTrack atTime:allTime error:nil];
        
        // 更新当前的位置
        allTime = CMTimeAdd(allTime, audioAsset.duration);
        
    }
    
    // 合并后的文件导出 - `presetName`要和之后的`session.outputFileType`相对应。
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    NSString *outPutFilePath = [[self.filePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"xindong.m4a"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outPutFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:outPutFilePath error:nil];
    }
    
    // 查看当前session支持的fileType类型
    NSLog(@"---%@",[session supportedFileTypes]);
    session.outputURL = [NSURL fileURLWithPath:outPutFilePath];
    session.outputFileType = AVFileTypeAppleM4A; //与上述的`present`相对应
    session.shouldOptimizeForNetworkUse = YES;   //优化网络
    
    [session exportAsynchronouslyWithCompletionHandler:^{
        if (session.status == AVAssetExportSessionStatusCompleted) {
            NSLog(@"合并成功----%@", outPutFilePath);
            
            NSURL *url = [NSURL fileURLWithPath:outPutFilePath];
            
            self.myPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
            
            self.myPlayer.delegate = self;
            [self.myPlayer play];
            
            //            static SystemSoundID soundID = 0;
            //
            //            AudioServicesCreateSystemSoundID((__bridge CFURLRef _Nonnull)(url), &soundID);
            //
            //            AudioServicesPlayAlertSoundWithCompletion(soundID, ^{
            //                NSLog(@"播放完成");
            //                if (block) {
            //                    block();
            //                }
            //            });
            
            
            
        } else {
            // 其他情况, 具体请看这里`AVAssetExportSessionStatus`.
            // 播放失败
            block();
        }
    }];
    
    /************************合成音频并播放*****************************/
}

- (NSString *)filePath {
    if (!_filePath) {
        _filePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
        NSString *folderName = [_filePath stringByAppendingPathComponent:@"MergeAudio"];
        BOOL isCreateSuccess = [kFileManager createDirectoryAtPath:folderName withIntermediateDirectories:YES attributes:nil error:nil];
        if (isCreateSuccess) _filePath = [folderName stringByAppendingPathComponent:@"xindong.m4a"];
    }
    return _filePath;
}





- (void)play4
{
    [self playVoiceWithAVSpeechSynthesisVoiceWithContent:@"playVoiceWithAVSpeechSynthesisVoiceWithContent" fishBlock:^{
        
    }];
}




#pragma mark- AVSpeechSynthesisVoice文字转语音进行播放，成功

- (void)playVoiceWithAVSpeechSynthesisVoiceWithContent:(NSString *)content fishBlock:(PlayVoiceBlock)finshBlock
{
    if (content.length == 0) {
        return;
    }
    if (finshBlock) {
        self.finshBlock = finshBlock;
    }
    
    
//    AVAudioSession *session = [AVAudioSession sharedInstance];
//    [session setActive:YES error:nil];
//    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    
    // 创建嗓音，指定嗓音不存在则返回nil
    AVSpeechSynthesisVoice *voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];
    
    // 创建语音合成器
    synthesizer = [[AVSpeechSynthesizer alloc] init];
    synthesizer.delegate = self;
    
    // 实例化发声的对象
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:content];
    utterance.voice = voice;
    utterance.rate = 0.5; // 语速
    
    // 朗读的内容
    [synthesizer speakUtterance:utterance];
    
    
    
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance
{
    NSLog(@"开始");
}
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    
    NSLog(@"结束");
}
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance
{
    
}
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didContinueSpeechUtterance:(AVSpeechUtterance *)utterance
{
    
}
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance
{
    
}


- (void)test5
{
    NSString *outPutFilePath = [[NSBundle mainBundle] pathForResource:@"daozhang" ofType:@"m4a"];
    NSURL *url = [NSURL fileURLWithPath:outPutFilePath];
    
    //建立的SystemSoundID对象
    static SystemSoundID soundID = 0;
    
    // 赋值
    AudioServicesCreateSystemSoundID((__bridge CFURLRef _Nonnull)(url), &soundID);
    
    // 播放系统声音
    AudioServicesPlaySystemSound(soundID);
    
    //播放提示音 带震动
//    AudioServicesPlayAlertSound(soundID);
    
    // 播放完毕之后的回调
    AudioServicesPlayAlertSoundWithCompletion(soundID, ^{
            NSLog(@"播放完成");
    
        });
    
    
    
    
    // 单纯的振动
//    static SystemSoundID mySoundID = kSystemSoundID_Vibrate;
//    AudioServicesPlaySystemSound(mySoundID);
    
    
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end


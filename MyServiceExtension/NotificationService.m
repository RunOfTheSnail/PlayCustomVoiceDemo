//
//  NotificationService.m
//  MyServiceExtension
//
//  Created by Zhang Yan on 2017/10/10.
//  Copyright © 2017年 yan. All rights reserved.
//

#import "NotificationService.h"
//包含头文件
#import "iflyMSC/IFlyMSC.h"

#import <AVFoundation/AVFoundation.h>

#define kFileManager [NSFileManager defaultManager]


@interface NotificationService ()<IFlySpeechSynthesizerDelegate,AVAudioPlayerDelegate>

@property (nonatomic, strong) IFlySpeechSynthesizer *iFlySpeechSynthesizer;

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@property (nonatomic, strong)AVAudioPlayer *myPlayer;



@property (nonatomic,strong)AVAudioPlayer *movePlayer;





@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) AVAudioPlayer *player;




@end

@implementation NotificationService

static int lianxunPlay = 1;

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    
    // Modify the notification content here...
    self.bestAttemptContent.title = [NSString stringWithFormat:@"%@ [modified]", self.bestAttemptContent.title];
    
    self.contentHandler(self.bestAttemptContent);
    
    
    
    <#                 失败                     #>
    // 方式1，直接使用科大讯飞播放，失败
//    [self playVoiceKeDaXunFei];
    
    <#                 失败                     #>
    // 方式2，使用AVAudioPlayer播放，失败
//    AVAudioSession *session = [AVAudioSession sharedInstance];
//    [session setActive:YES error:nil];
//    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
//    [self lianxuPlay];
    
    
    <#                    成功                 #>
    // 方式3，使用 AudioServicesPlayAlertSoundWithCompletion 递归播放音频，效果没有合成一个音频播放效果好,成功
//    [self playVoiceAction];
    
    
    <#                    成功                 #>
    // 方式4，语音合成，使用AudioServicesPlayAlertSoundWithCompletion播放，但是时间最多5秒,成功
//    [self hechengVoice];
    
    <#                    成功                 #>
//    // 方式5，AVSpeechSynthesisVoice使用系统方法，文字转语音播报,成功
//    [self playVoiceWithAVSpeechSynthesisVoiceWithContent:self.bestAttemptContent.body];
    
}


#pragma mark- 合成音频播放，成功
- (void)hechengVoice
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

            static SystemSoundID soundID = 0;
            
            AudioServicesCreateSystemSoundID((__bridge CFURLRef _Nonnull)(url), &soundID);

            AudioServicesPlayAlertSoundWithCompletion(soundID, ^{
                NSLog(@"播放完成");
            });
            
          
            
        } else {
            // 其他情况, 具体请看这里`AVAssetExportSessionStatus`.
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



#pragma mark- 使用 AudioServicesPlayAlertSoundWithCompletion 递归播放音频，效果没有合成一个音频播放效果好,成功
- (void)playVoiceAction
{

    NSString *urlString = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%d",lianxunPlay] ofType:@"m4a" ];
    
    NSURL *url = [NSURL fileURLWithPath:urlString];
    
    static SystemSoundID soundID = 0;
    
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef _Nonnull)(url), &soundID);
    
    AudioServicesPlayAlertSoundWithCompletion(soundID, ^{
        NSLog(@"播放完成");
        if (lianxunPlay <= 5) {
            lianxunPlay ++;
            [self playVoiceAction];
        }
    });
}





#pragma mark- 使用 AVAudioPlayer 进行播放，失败

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer*)player successfully:(BOOL)flag{
    //播放结束时执行的动作
    if (lianxunPlay < 6) {
        ++lianxunPlay;
        [self lianxuPlay];
    }else {
        lianxunPlay = 1;
    }
    
}
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer*)player error:(NSError *)error{
    //解码错误执行的动作
}
- (void)audioPlayerBeginInteruption:(AVAudioPlayer*)player{
    //处理中断的代码
}
- (void)audioPlayerEndInteruption:(AVAudioPlayer*)player{
    //处理中断结束的代码
}

-(void)lianxuPlay
{
    NSString *pathStr = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%d", lianxunPlay] ofType:@"m4a"];
    NSURL *url = [NSURL fileURLWithPath:pathStr];
    self.myPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    
    self.myPlayer.delegate = self;
    [self.myPlayer play];
    
}

#pragma mark- 使用科大讯飞播放语音 ,失败
- (void)playVoiceKeDaXunFei
{
    //创建语音配置,appid必须要传入，仅执行一次则可
    NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@",@"59db7ce2"];
    
    //所有服务启动前，需要确保执行createUtility
    [IFlySpeechUtility createUtility:initString];
    
    /******************************************************/
    
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
    [_iFlySpeechSynthesizer startSpeaking: @"支付宝到账10000万"];
    
}

//IFlySpeechSynthesizerDelegate协议实现
//合成结束
- (void) onCompleted:(IFlySpeechError *) error {
    
    NSLog(@"合成结束 error ===== %@",error);
}
//合成开始
- (void) onSpeakBegin {}
//合成缓冲进度
- (void) onBufferProgress:(int) progress message:(NSString *)msg {}
//合成播放进度
- (void) onSpeakProgress:(int) progress beginPos:(int)beginPos endPos:(int)endPos {}


#pragma mark- AVSpeechSynthesisVoice文字转语音进行播放，成功

- (void)playVoiceWithAVSpeechSynthesisVoiceWithContent:(NSString *)content
{
    if (content.length == 0) {
        return;
    }
    // 创建嗓音，指定嗓音不存在则返回nil
    AVSpeechSynthesisVoice *voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];
    
    // 创建语音合成器
    AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc] init];
    
    // 实例化发声的对象
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:content];
    utterance.voice = voice;
    utterance.rate = 0.5; // 语速
    
    // 朗读的内容
    [synthesizer speakUtterance:utterance];
}



- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    self.contentHandler(self.bestAttemptContent);
}

@end

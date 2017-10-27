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

typedef void(^PlayVoiceBlock)();


@interface NotificationService ()<IFlySpeechSynthesizerDelegate,AVAudioPlayerDelegate,AVSpeechSynthesizerDelegate>
{
    AVSpeechSynthesizer *synthesizer;
}
@property (nonatomic, strong) IFlySpeechSynthesizer *iFlySpeechSynthesizer;

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@property (nonatomic, strong)AVAudioPlayer *myPlayer;

@property (nonatomic, strong) NSString *filePath;

// AVSpeechSynthesisVoice 播放完毕之后的回调block
@property (nonatomic, copy)PlayVoiceBlock finshBlock;

// 科大讯飞播放完毕之后的block回调
@property (nonatomic, copy)PlayVoiceBlock kedaFinshBlock;

// 语音合成完毕之后，使用 AVAudioPlayer 播放
@property (nonatomic, copy)PlayVoiceBlock aVAudioPlayerFinshBlock;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    
    // Modify the notification content here...
    self.bestAttemptContent.title = [NSString stringWithFormat:@"%@ [modified]", self.bestAttemptContent.title];
    __weak __typeof(self)weakSelf = self;
    
    /**************************************************************************/
    
    
    // 方式1，直接使用科大讯飞播放，成功，但是刚开始的时候可能需要几秒的准备播放时间
//    [self playVoiceKeDaXunFeiWithMessage:self.bestAttemptContent.body withBlock:^{
//        weakSelf.contentHandler(weakSelf.bestAttemptContent);
//    }];
    
    
    /**************************************************************************/
    

    // 方式2，语音合成，使用AudioServicesPlayAlertSoundWithCompletion播放,成功,缺点就是，手机静音模式下，没有声音播放
//     [self hechengVoiceWithFinshBlock:^{
//         weakSelf.contentHandler(weakSelf.bestAttemptContent);
//     }];
    
    
    /*******************************推荐用法*******************************************/
    
    // 方法3,语音合成，使用AVAudioPlayer播放,成功
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];

    [self hechengVoiceAVAudioPlayerWithFinshBlock:^{
        weakSelf.contentHandler(weakSelf.bestAttemptContent);
    }];
    
    
    /**************************************************************************/
    
//  方式4，AVSpeechSynthesisVoice使用系统方法，文字转语音播报,成功
//    [self playVoiceWithAVSpeechSynthesisVoiceWithContent:self.bestAttemptContent.body fishBlock:^{
//        weakSelf.contentHandler(weakSelf.bestAttemptContent);
//    }];
    
}

#pragma mark- 使用科大讯飞播放语音
- (void)playVoiceKeDaXunFeiWithMessage:(NSString *)message withBlock:(PlayVoiceBlock)finshBlock
{
    if (finshBlock) {
        self.kedaFinshBlock = finshBlock;
    }
    
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
    [_iFlySpeechSynthesizer startSpeaking:message];
    
}

//IFlySpeechSynthesizerDelegate协议实现
//合成结束
- (void) onCompleted:(IFlySpeechError *) error {
    
    NSLog(@"合成结束 error ===== %@",error);
    self.kedaFinshBlock();
}
/*!
 *  开始合成回调
 */
- (void) onSpeakBegin
{
    
}

/*!
 *  缓冲进度回调
 *
 *  @param progress 缓冲进度，0-100
 *  @param msg      附件信息，此版本为nil
 */
- (void) onBufferProgress:(int) progress message:(NSString *)msg
{
    
}

/*!
 *  播放进度回调
 *
 *  @param progress 当前播放进度，0-100
 *  @param beginPos 当前播放文本的起始位置，0-100
 *  @param endPos 当前播放文本的结束位置，0-100
 */
- (void) onSpeakProgress:(int) progress beginPos:(int)beginPos endPos:(int)endPos
{
    
}

/*!
 *  暂停播放回调
 */
- (void) onSpeakPaused
{
    
}

/*!
 *  恢复播放回调<br>
 *  注意：此回调方法SDK内部不执行，播放恢复全部在onSpeakBegin中执行
 */
- (void) onSpeakResumed
{
    
}

/*!
 *  正在取消回调<br>
 *  注意：此回调方法SDK内部不执行
 */
- (void) onSpeakCancel
{
    
}

/*!
 *  扩展事件回调<br>
 *  根据事件类型返回额外的数据
 *
 *  @param eventType 事件类型，具体参见IFlySpeechEventType枚举。目前只支持EVENT_TTS_BUFFER也就是实时返回合成音频。
 *  @param arg0      arg0
 *  @param arg1      arg1
 *  @param eventData 事件数据
 */
- (void) onEvent:(int)eventType arg0:(int)arg0 arg1:(int)arg1 data:(NSData *)eventData
{
    
}



#pragma mark- 合成音频使用AudioServicesCreateSystemSoundID播放，成功
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

            static SystemSoundID soundID = 0;

            AudioServicesCreateSystemSoundID((__bridge CFURLRef _Nonnull)(url), &soundID);

            AudioServicesPlayAlertSoundWithCompletion(soundID, ^{
                NSLog(@"播放完成");
                if (block) {
                    block();
                }
            });
            
          
            
        } else {
            // 其他情况, 具体请看这里`AVAssetExportSessionStatus`.
            // 播放失败
            block();
        }
    }];
    
    /************************合成音频并播放*****************************/
}


#pragma mark- 合成音频使用 AVAudioPlayer 播放
- (void)hechengVoiceAVAudioPlayerWithFinshBlock:(PlayVoiceBlock )block
{
    if (block) {
        self.aVAudioPlayerFinshBlock = block;
    }
    
    /************************合成音频并播放*****************************/

    AVMutableComposition *composition = [AVMutableComposition composition];
    
    NSArray *fileNameArray = @[@"daozhang",@"1",@"2",@"3",@"4",@"5",@"6"];
    
    CMTime allTime = kCMTimeZero;
    
    for (NSInteger i = 0; i < fileNameArray.count; i++) {
        NSString *auidoPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@",fileNameArray[i]] ofType:@"m4a"];
        
        AVURLAsset *audioAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:auidoPath]];
        
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
            
            
        } else {
            // 其他情况, 具体请看这里`AVAssetExportSessionStatus`.
            // 播放失败
            self.aVAudioPlayerFinshBlock();
        }
    }];
    
    /************************合成音频并播放*****************************/
}
#pragma mark- AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (self.aVAudioPlayerFinshBlock) {
        self.aVAudioPlayerFinshBlock();
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


- (NSString *)filePath {
    if (!_filePath) {
        _filePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
        NSString *folderName = [_filePath stringByAppendingPathComponent:@"MergeAudio"];
        BOOL isCreateSuccess = [kFileManager createDirectoryAtPath:folderName withIntermediateDirectories:YES attributes:nil error:nil];
        if (isCreateSuccess) _filePath = [folderName stringByAppendingPathComponent:@"xindong.m4a"];
    }
    return _filePath;
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
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
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
    self.finshBlock();
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



- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    self.contentHandler(self.bestAttemptContent);
}

@end

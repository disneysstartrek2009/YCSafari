//
//  ViewController.m
//  yungCloudWeb
//
//  Created by Ethan Thomas on 1/12/16.
//  Copyright © 2016 Ethan Thomas. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
@import MediaPlayer;

@interface ViewController () <UIWebViewDelegate, UITextFieldDelegate, UINavigationBarDelegate, UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UITextField *urlTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *webActivityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *forwardButton;
@property (weak, nonatomic) IBOutlet UINavigationItem *navTitle;
@property (weak, nonatomic) IBOutlet UIView *urlBarView;
@property NSString *songArtist;
@property NSString *songName;
@property NSString *songURL;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self loadURL];
    self.urlTextField.text = @"http://www.google.com";
    self.navigationItem.title = @"Ethan";
    self.backButton.hidden = YES;
    self.navTitle.title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    self.webView.delegate = self;
    self.webView.scrollView.delegate = self;
    self.urlTextField.delegate = self;
}

- (BOOL)canBecomeFirstResponder {
    
    return YES;
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    [self becomeFirstResponder];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    
    [self resignFirstResponder];
    
    [super viewWillDisappear:animated];
    
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {
                
            case UIEventSubtypeRemoteControlPlay:
                
                [self.audioPlayer play];
                
                break;
                
            case UIEventSubtypeRemoteControlPause:
                
                [self.audioPlayer pause];
                
                break;
                
            case UIEventSubtypeRemoteControlTogglePlayPause:
                
                if (self.audioPlayer.playbackState == MPMoviePlaybackStatePlaying) {
                    
                    [self.audioPlayer pause];
                    
                }
                
                else {
                    
                    [self.audioPlayer play];
                    
                }
                
                break;
                
            default:
                
                break;
                
        }
        
    }
    
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString* scheme = [[request URL] scheme];
    if ([@"yungcloud" isEqual:scheme]) {
        [self getTrackInfo];
    } else {
        return YES;
    }
    MPMediaItem *info;
    [info mediaType];
    [self configureNowPlayingInfo:info];
    [[AVAudioSession sharedInstance] setDelegate: self];
    
    NSError *myErr;
    
    // Initialize the AVAudioSession here.
    if (![[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&myErr]) {
        // Handle the error here.
        NSLog(@"Audio Session error %@, %@", myErr, [myErr userInfo]);
    }
    else{
        // Since there were no errors initializing the session, we'll allow begin receiving remote control events
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    }
    
    //initialize our audio player
    self.audioPlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:self.songURL]];
    
    [self.audioPlayer setShouldAutoplay:NO];
    [self.audioPlayer setControlStyle: MPMovieControlStyleEmbedded];
    self.audioPlayer.view.hidden = YES;
    
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
    
    Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
    
    if (playingInfoCenter) {
        
        
        NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
        
        
        MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage: [UIImage imageNamed:@"AlbumArt"]];
        
        NSNumber *rate = @1.0;
        
        [songInfo setObject:self.songName forKey:MPMediaItemPropertyTitle];
        [songInfo setObject:self.songArtist forKey:MPMediaItemPropertyArtist];
        [songInfo setObject:@"Audio Album" forKey:MPMediaItemPropertyAlbumTitle];
        [songInfo setObject:rate forKey:MPNowPlayingInfoPropertyPlaybackRate];
        [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
        
        
    }
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *setCategoryError = nil;
    BOOL ok = [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    if (!ok) {
        NSLog(@"Error setting AVAudioSessionCategoryPlayback: %@", setCategoryError);
    };
    return ok;
}

-(void)getTrackInfo
{
    NSLog(@"Inside track info");
    NSString *songTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('songTitle').text"];
    NSString *songArtist = [self.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('song-artist').innerHTML"];
    NSString *songURL = [self.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('songURL').innerHTML"];
    self.songName = songTitle;
    self.songArtist = songArtist;
    self.songURL = songURL;
    NSLog(@"Song Title: %@, Song Artist: %@, Song URL: %@", songTitle, songArtist, songURL);
    
}

-(void)configureNowPlayingInfo:(MPMediaItem *)item
{
    MPNowPlayingInfoCenter *info = [MPNowPlayingInfoCenter defaultCenter];
    NSMutableDictionary *newInfo = [NSMutableDictionary dictionary];
    NSSet *itemProperties = [NSSet setWithObjects:MPMediaItemPropertyTitle, MPMediaItemPropertyArtist,
                             MPMediaItemPropertyPlaybackDuration, MPNowPlayingInfoPropertyElapsedPlaybackTime, MPNowPlayingInfoPropertyPlaybackRate, nil];
    [item enumerateValuesForProperties:itemProperties usingBlock:^(NSString * _Nonnull property, id  _Nonnull value, BOOL * _Nonnull stop) {
        {
            [newInfo setObject:value forKey:property];
        }
    }];
    
    info.nowPlayingInfo = newInfo;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
//    [self loadURL:self.urlTextField.text];
    [self.urlTextField resignFirstResponder];
    self.urlTextField.text = self.webView.request.URL.absoluteString;
    return YES;
}



-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(scrollView.contentOffset.y <= 0.0){
//        self.urlTextField.hidden = NO;
//        self.urlBarView.hidden = NO;
    } else {
        self.urlBarView.hidden = YES;
        self.urlTextField.hidden = YES;
    }
}

-(void)webViewDidStartLoad:(UIWebView *)webView
{
    self.urlTextField.text = self.webView.request.URL.absoluteString;
    if ([self.webView canGoBack]) {
        self.backButton.hidden = NO;
    } else {
        self.backButton.hidden = YES;
    }
    if ([self.webView canGoForward]) {
        self.forwardButton.hidden = NO;
    } else {
        self.forwardButton.hidden = YES;
    }
    [self.webActivityIndicator startAnimating];
}

- (IBAction)comingSoon:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"New Feature!" message:@"Coming Soon!" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *doneButton = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //done
    }];
    
    [alertController addAction:doneButton];
    
    [self presentViewController:alertController animated:YES completion:nil];
}


-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.navTitle.title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    self.urlTextField.text = self.webView.request.URL.absoluteString;
    [self.webActivityIndicator stopAnimating];
}

- (IBAction)goBackPage:(id)sender {
    [self.webView goBack];
    self.urlTextField.text = self.webView.request.URL.absoluteString;
}

- (IBAction)goForwardPage:(id)sender {
    [self.webView goForward];
    self.urlTextField.text = self.webView.request.URL.absoluteString;
}

- (IBAction)stopLoading:(id)sender {
    [self.webView stopLoading];
    [self.webActivityIndicator stopAnimating];
}

- (IBAction)reloadPage:(id)sender {
    [self.webView reload];
}

-(void)loadURL
{
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"]];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

@end

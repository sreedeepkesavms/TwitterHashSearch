//
//  ViewController.m
//  FetchTweetExample
//
//  Created by Sreedeepkesav on 30/01/16.
//  Copyright © 2016 test. All rights reserved.
//

#import "ViewController.h"
#import "TweetsTableViewCell.h"
#import "AppRecord.h"
#import "IconDownloader.h"
#import "MediaDownloader.h"

#define CONSUMER_KEY @"2woaa9V18oasPUcHwUyLFdoEk"
#define CONSUMER_SECRET @"WDR0wHwZ1p59xNH9yE6vqXtzb7BXsK13vTz9ir3ra7zjJzU9fi"
#define MAX_TWEETS 50
#define TWEETS_IN_SINGLE_FETCH 10
#define REFRESH_INTERVAL_IN_SECONDS 10.0

@interface ViewController (){
    
    NSMutableArray *tweetsArray;
    NSTimer *refreshTimer;
    NSString *searchString;
}

@property (weak, nonatomic) IBOutlet UISearchBar *hashTagSearchBar;
@property (weak, nonatomic) IBOutlet UITableView *tweetsTableView;
@property (nonatomic, strong) NSMutableDictionary *imageDownloadsInProgress;
@property (nonatomic, strong) NSMutableDictionary *mediaDownloadsInProgress;
@property (weak, nonatomic) IBOutlet UILabel *placeholderLabel;

@property (nonatomic, weak)NSString *bearerToken;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setUpView];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.tweetsTableView setHidden:YES];
}

- (void)setUpView {
    
    self.tweetsTableView.dataSource = self;
    self.tweetsTableView.delegate = self;
    self.hashTagSearchBar.delegate = self;
    tweetsArray = [NSMutableArray array];
    self.placeholderLabel.hidden = NO;
    self.tweetsTableView.rowHeight = UITableViewAutomaticDimension;
    self.tweetsTableView.estimatedRowHeight = 300.0;
}

- (void)getTweetsFromTwitterUsingSearchString {
    
    if(self.bearerToken == nil) return;
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat: @"https://api.twitter.com/1.1/search/tweets.json?q=%@&language=en&result_type=recent&since_id=693645135838445568&count=%d", searchString, TWEETS_IN_SINGLE_FETCH]];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];
    [urlRequest setValue:[NSString stringWithFormat:@"Bearer %@", self.bearerToken] forHTTPHeaderField:@"Authorization"];
    NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:nil error:nil];
    
    if (data != nil) {
        
        NSError* error;
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data
                                                             options:kNilOptions
                                                               error:&error];
        
        [self processTweetsResponse:json];
    }
    else {
        NSLog(@"Error Fetching Tweets");
    }
}

- (void)processTweetsResponse:(NSDictionary *)responseDictionary {
    
    NSMutableArray *oldArray = [NSMutableArray array];
    
    if (tweetsArray.count > 0) {
        
        oldArray = [NSMutableArray arrayWithArray:tweetsArray];
    }
    
    NSMutableArray *newArray = [NSMutableArray array];
    if (responseDictionary)
    {
        id data = [responseDictionary valueForKey:@"statuses"];
        if ([data isKindOfClass:NSArray.class])
        {
            NSArray *dataArray = (NSArray*)data;
            for (NSDictionary *post in dataArray)
            {
                [newArray addObject:post];
            }
        }
    }
    if (oldArray.count <= (MAX_TWEETS - TWEETS_IN_SINGLE_FETCH)) {
        
        tweetsArray = [[newArray arrayByAddingObjectsFromArray:oldArray] mutableCopy];
    }
    else {
        NSMutableArray *tempArray = [[oldArray subarrayWithRange:NSMakeRange(0, (MAX_TWEETS - TWEETS_IN_SINGLE_FETCH))] mutableCopy];
        tweetsArray = [[newArray arrayByAddingObjectsFromArray:tempArray] mutableCopy];
    }
    
    [self.tweetsTableView setHidden:NO];
    [self.view endEditing:YES];
    [self.tweetsTableView reloadData];
    [self addPageRefresh];
}

- (void)addPageRefresh {
    
    refreshTimer = [NSTimer scheduledTimerWithTimeInterval:REFRESH_INTERVAL_IN_SECONDS target:self selector:@selector(getTweetsFromTwitterUsingSearchString) userInfo:nil repeats:NO];
}

- (NSString *)bearerToken
{
    if(_bearerToken == nil)
    {
        NSString * consumerKey = [CONSUMER_KEY stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        
        NSString * consumerSecret = [CONSUMER_SECRET stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        
        NSString * combinedKey = [[self class] _base64Encode:[[NSString stringWithFormat:@"%@:%@", consumerKey, consumerSecret] dataUsingEncoding:NSUTF8StringEncoding]];
        
        //Making post request for bearer token.
        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.twitter.com/oauth2/token"]];
        [urlRequest setHTTPMethod:@"POST"];
        [urlRequest setValue:[NSString stringWithFormat:@"Basic %@", combinedKey] forHTTPHeaderField:@"Authorization"];
        [urlRequest setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded;charset=UTF-8"] forHTTPHeaderField:@"Content-Type"];
        [urlRequest setHTTPBody:[@"grant_type=client_credentials" dataUsingEncoding:NSUTF8StringEncoding]];
        NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:nil error:nil];
        NSDictionary *responseJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        _bearerToken = [responseJSON valueForKey:@"access_token"];
    }
    return _bearerToken;
}

+(NSString *)_base64Encode:(NSData *)data{
    
    //Point to start of the data and set buffer sizes
    int inLength = (int)[data length];
    int outLength = ((((inLength * 4)/3)/4)*4) + (((inLength * 4)/3)%4 ? 4 : 0);
    const char *inputBuffer = [data bytes];
    char *outputBuffer = malloc(outLength);
    outputBuffer[outLength] = 0;
    
    //64 digit code
    static char Encode[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
    //start the count
    int cycle = 0;
    int inpos = 0;
    int outpos = 0;
    char temp = '\0';
    
    //Pad the last to bytes, the outbuffer must always be a multiple of 4
    outputBuffer[outLength-1] = '=';
    outputBuffer[outLength-2] = '=';
    
    /* http://en.wikipedia.org/wiki/Base64
     Text content   M           a           n
     ASCII          77          97          110
     8 Bit pattern  01001101    01100001    01101110
     
     6 Bit pattern  010011  010110  000101  101110
     Index          19      22      5       46
     Base64-encoded T       W       F       u
     */
    
    
    while (inpos < inLength){
        switch (cycle) {
            case 0:
                outputBuffer[outpos++] = Encode[(inputBuffer[inpos]&0xFC)>>2];
                cycle = 1;
                break;
            case 1:
                temp = (inputBuffer[inpos++]&0x03)<<4;
                outputBuffer[outpos] = Encode[temp];
                cycle = 2;
                break;
            case 2:
                outputBuffer[outpos++] = Encode[temp|(inputBuffer[inpos]&0xF0)>> 4];
                temp = (inputBuffer[inpos++]&0x0F)<<2;
                outputBuffer[outpos] = Encode[temp];
                cycle = 3;
                break;
            case 3:
                outputBuffer[outpos++] = Encode[temp|(inputBuffer[inpos]&0xC0)>>6];
                cycle = 4;
                break;
            case 4:
                outputBuffer[outpos++] = Encode[inputBuffer[inpos++]&0x3f];
                cycle = 0;
                break;
            default:
                cycle = 0;
                break;
        }
    }
    NSString *pictemp = [NSString stringWithUTF8String:outputBuffer];
    free(outputBuffer);
    return pictemp;
}

- (BOOL)checkIfMediaPresent:(int)index {
    
    if (tweetsArray[index][@"entities"][@"media"] != nil) {
        return YES;
    }
    return NO;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return (tweetsArray.count != 0) ? tweetsArray.count : 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return [self checkIfMediaPresent:(int)indexPath.row] ? 300 : UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return [self checkIfMediaPresent:(int)indexPath.row] ? 300 : 88;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Set up the cell representing the tweet
    TweetsTableViewCell *cell = (TweetsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"tweetsCell"];
    
    NSUInteger nodeCount = tweetsArray.count;
    
    // Leave cells empty if there's no data yet
    if (nodeCount > 0)
    {
        AppRecord *appRecord = [[AppRecord alloc]init];
        
        [self downloadProfileImages:appRecord forIndexPath:indexPath andPopulateCell:cell];
        [self downloadMedia:appRecord forIndexPath:indexPath andPopulateCell:cell];
        
        cell.userNameField.text = tweetsArray[indexPath.row][@"user" ][@"name"];
        cell.tweetTextLabel.text = tweetsArray[indexPath.row][@"text"];
        
    }
    return cell;
}
#pragma mark - Lazy load Profile Images and Media

- (void)downloadProfileImages:(AppRecord *)appRecord forIndexPath:(NSIndexPath *)indexPath andPopulateCell:(TweetsTableViewCell *)cell {
    
    appRecord.imageURLString = [NSString stringWithFormat:@"%@", tweetsArray[indexPath.row][@"user"][@"profile_image_url"]];
    
    // Only load cached images; defer new downloads until scrolling ends
    if (!appRecord.appIcon)
    {
        if (self.tweetsTableView.dragging == NO && self.tweetsTableView.decelerating == NO)
        {
            [self startIconDownload:appRecord forIndexPath:indexPath];
        }
        // if a download is deferred or in progress, return a placeholder image
        cell.profileImageView.image = [UIImage imageNamed:@"Placeholder"];
    }
    else
    {
        cell.profileImageView.image = appRecord.appIcon;
    }
}

- (void)downloadMedia:(AppRecord *)appRecord forIndexPath:(NSIndexPath *)indexPath andPopulateCell:(TweetsTableViewCell *)cell {
    
    if ([self checkIfMediaPresent:(int)indexPath.row]) {
        
        appRecord.mediaURLString = [NSString stringWithFormat:@"%@", tweetsArray[indexPath.row][@"entities"][@"media"][0][@"media_url_https"]];
        
        if (!appRecord.mediaImage)
        {
            if (self.tweetsTableView.dragging == NO && self.tweetsTableView.decelerating == NO)
            {
                [self startMediaDownload:appRecord forIndexPath:indexPath];
            }
            
            cell.sharedMediaView.image = [UIImage imageNamed:@"loading"];
        }
        else
        {
            cell.sharedMediaView.image = appRecord.mediaImage;
        }
    }
}

#pragma mark - Table cell image support

- (void)startIconDownload:(AppRecord *)appRecord forIndexPath:(NSIndexPath *)indexPath
{
    IconDownloader *iconDownloader = (self.imageDownloadsInProgress)[indexPath];
    if (iconDownloader == nil)
    {
        iconDownloader = [[IconDownloader alloc] init];
        iconDownloader.appRecord = appRecord;
        [iconDownloader setCompletionHandler:^{
            
            TweetsTableViewCell *cell = [self.tweetsTableView cellForRowAtIndexPath:indexPath];
            
            // Display the newly loaded image
            cell.profileImageView.image = appRecord.appIcon;
            
            // Remove the IconDownloader from the in progress list.
            // This will result in it being deallocated.
            [self.imageDownloadsInProgress removeObjectForKey:indexPath];
            
        }];
        (self.imageDownloadsInProgress)[indexPath] = iconDownloader;
        [iconDownloader startDownload];
    }
}

- (void)startMediaDownload:(AppRecord *)appRecord forIndexPath:(NSIndexPath *)indexPath
{
    MediaDownloader *mediaDowloader = (self.mediaDownloadsInProgress)[indexPath];
    if (mediaDowloader == nil)
    {
        mediaDowloader = [[MediaDownloader alloc] init];
        mediaDowloader.appRecord = appRecord;
        [mediaDowloader setCompletionHandler:^{
            
            TweetsTableViewCell *cell = [self.tweetsTableView cellForRowAtIndexPath:indexPath];
            
            // Display the newly loaded image
            cell.sharedMediaView.image = appRecord.mediaImage;
            
            // Remove the IconDownloader from the in progress list.
            // This will result in it being deallocated.
            [self.mediaDownloadsInProgress removeObjectForKey:indexPath];
            
        }];
        (self.mediaDownloadsInProgress)[indexPath] = mediaDowloader;
        [mediaDowloader startDownload];
    }
}

- (void)loadImagesForOnscreenRows
{
    if (tweetsArray.count > 0)
    {
        NSArray *visiblePaths = [self.tweetsTableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths)
        {
            AppRecord *appRecord = [[AppRecord alloc]init];
            appRecord.imageURLString = tweetsArray[indexPath.row][@"user"][@"profile_image_url"];
            
            if ([self checkIfMediaPresent:(int)indexPath.row]) {
                
                appRecord.mediaURLString = [NSString stringWithFormat:@"%@", tweetsArray[indexPath.row][@"entities"][@"media"][0][@"media_url_https"]];
            }
            
            if (!appRecord.appIcon)
                // Avoid the app icon download if the app already has an icon
            {
                [self startIconDownload:appRecord forIndexPath:indexPath];
            }
            
            if (!appRecord.mediaImage) {
                
                [self startMediaDownload:appRecord forIndexPath:indexPath];
                
            }
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
    {
        [self loadImagesForOnscreenRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadImagesForOnscreenRows];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    [tweetsArray removeAllObjects];

    if ([searchBar.text isEqualToString:@""]) {
        
        [self.tweetsTableView reloadData];
        self.tweetsTableView.hidden = YES;
        self.placeholderLabel.hidden = NO;
    }
    
    NSString *stringWithoutHashes = [searchBar.text
                                     stringByReplacingOccurrencesOfString:@"#" withString:@""];
    
    self.placeholderLabel.hidden = YES;
   
    searchString = stringWithoutHashes;
    [self getTweetsFromTwitterUsingSearchString];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [refreshTimer invalidate];
        refreshTimer = nil;
    });
}

@end

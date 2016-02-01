//
//  TweetsTableViewCell.h
//  FetchTweetExample
//
//  Created by Sreedeepkesav on 31/01/16.
//  Copyright © 2016 test. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TweetsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *userNameField;
@property (weak, nonatomic) IBOutlet UIImageView *sharedMediaView;
@property (weak, nonatomic) IBOutlet UILabel *tweetTextLabel;

@end

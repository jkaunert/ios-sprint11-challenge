//
//  JKLyricFinderController.m
//  LyricFinder
//
//  Created by TuneUp Shop  on 3/1/19.
//  Copyright © 2019 jkaunert. All rights reserved.
//

#import "JKLyricFinderController.h"


@implementation JKLyricFinderController {
    NSMutableArray *_savedSongs;
}

static NSString *baseURL = @"https://musixmatchcom-musixmatch.p.rapidapi.com/wsr/1.1/matcher.lyrics.get";
static NSString *xMashapeKey = @"229497ddc9msh1274a5e55aaf19bp1d89a8jsn08a5dcd5d514";

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _savedSongs = [NSMutableArray array];
    }
    return self;
}

- (void)saveWithNSFileManager {
    // get the document directory URL
    NSURL *documentsDirectoryURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    // append our file name
    NSURL *url = [documentsDirectoryURL URLByAppendingPathComponent:@"SavedSongs" isDirectory:NO];
    // write our array to the file
    [_savedSongs writeToURL:url atomically:YES];
}

- (void)loadWithNSFileManger {
    // get the document directory URL
    NSURL *documentsDirectoryURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    // append our file name
    NSURL *url = [documentsDirectoryURL URLByAppendingPathComponent:@"SavedSongs" isDirectory:NO];
    // read (mutable) array from file
    _savedSongs = [[NSArray arrayWithContentsOfURL:url] mutableCopy];
}

- (void)saveSong:(JKSong *)song {
    [_savedSongs addObject:song];
    [self saveWithNSFileManager];
}

- (void)removeSavedSong:(JKSong *)song {
    [_savedSongs removeObject:song];
    [self saveWithNSFileManager];
}

- (void)fetchSongInfoByArtist:(NSString *)artist andWithTitle:(NSString *)title withBlock:(JKSongCompletionBlock)completionBlock {
    
    // Construct request URL
    NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
    urlComponents.scheme = @"https";
    urlComponents.host = @"musixmatchcom-musixmatch.p.rapidapi.com";
    urlComponents.path = @"/wsr/1.1/matcher.lyrics.get";
    
    NSURLQueryItem *searchedArtist = [NSURLQueryItem queryItemWithName:@"q_artist" value:artist];
    NSURLQueryItem *searchedSongTitle = [NSURLQueryItem queryItemWithName:@"q_track" value:title];
    urlComponents.queryItems = @[searchedArtist, searchedSongTitle];
    
    //construct request URL
    NSURL *requestURL = urlComponents.URL;
    
    //construct request header
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    [request setValue:xMashapeKey forHTTPHeaderField:@"X-Mashape-Key"];
    
    //initiate dataTask
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        
        [self processResponse:data error:error byArtist:artist forSongTitle:title completionBlock:^(JKSong *song, NSError *error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(song, error);
            });
            
        }];
        
    }];
    [dataTask resume];
    
}

#pragma mark - Private Methods

- (void)processResponse:(NSData *)data error:(NSError *)error byArtist:(NSString *)artist forSongTitle:(NSString *)title completionBlock:(JKSongCompletionBlock)completionBlock {
    

    if (error != nil) {
        NSLog(@"Error fetching person information: %@", error);
        completionBlock(nil, error);
        return;
    }
    
    if (data == nil) {
        NSLog(@"No error, but missing data???");
        completionBlock(nil, nil);
        return;
    }
    
    NSError *decodingError = nil;
    NSDictionary *decodedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&decodingError];
    
    if (decodingError != nil) {
        NSLog(@"Error decoding JSON: %@", decodingError);
        completionBlock(nil, decodingError);
        return;
    }
    
    if ([decodedObject isKindOfClass:[NSDictionary class]] == NO) {
        NSLog(@"JSON result is not a dictionary");
        completionBlock(nil, nil);
        return;
    }
    
    JKSong *song = [[JKSong alloc] init];
    song.songLyrics = [decodedObject objectForKey:@"lyrics_body"];
    song.artistName = artist;
    song.songTitle = title;
    song.jKSongRating = ratingStepperValue;
    
    completionBlock(song, nil);
}

@end

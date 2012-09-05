//
//  LevelParser.m
//  MakeLevel
//
//  Created by User on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LevelParser.h"
#import "Level.h"


@implementation LevelParser

- (LevelParser *) initXMLParser {
	[super init];
    
	return self;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
	attributes:(NSDictionary *)attributeDict {	
    
	//NSLog(@"Processing Element: %@", elementName);
    if([elementName isEqualToString: @"levels"])
    {
        levels = [[NSMutableArray alloc] init];
    }
    
    if([elementName isEqualToString:@"level"])
    {
        aLevel = [[Level alloc] init];
        aLevel.number = [[attributeDict objectForKey:@"number"] integerValue]; // level
        aLevel.unlocked = [[attributeDict objectForKey:@"unlocked"] integerValue]; // level unclocked
        aLevel.stars = [[attributeDict objectForKey:@"stars"] integerValue]; // stars
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string { 
	
	if(!currentElementValue) 
		currentElementValue = [[NSMutableString alloc] initWithString:string];
	else
        [currentElementValue stringByAppendingString:string];
	
	//NSLog(@"Processing Value: %@", currentElementValue);
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName 
{
	//There is nothing to do if we encounter the Books element here.
	//If we encounter the Book element howevere, we want to add the book object to the array
	// and release the object.
	//NSLog(@"Processing Element: %@ with value: %@", elementName, currentElementValue);
    if([elementName isEqualToString:@"levels"]){
        return;
    }
    if([elementName isEqualToString:@"level"]){
        [levels addObject:aLevel]; // add alevel into a mutablearray
        [aLevel release];
        aLevel = nil;
    }
    else{             
            [aLevel setValue:currentElementValue forKey:elementName];          
    }
    
	[currentElementValue release];
	currentElementValue = nil;
}



// Get path of XML file
+ (NSString *)dataFilePath:(BOOL)forSave {
    
    NSString *xmlFileName = [NSString stringWithFormat:@"levelsdata"];
    
    /***************************************************************************
     This method is used to set up the specified xml for reading/writing.
     Specify the name of the XML file you want to work with above.
     You don't have to worry about the rest of the code in this method.
     ***************************************************************************/
    
    NSString *xmlFileNameWithExtension = [NSString stringWithFormat:@"%@.xml",xmlFileName];    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *documentsPath = [documentsDirectory stringByAppendingPathComponent:xmlFileNameWithExtension];
    if (forSave || [[NSFileManager defaultManager] fileExistsAtPath:documentsPath]) {
        return documentsPath;   
        NSLog(@"%@ opened for read/write",documentsPath);
    } else {
        NSLog(@"Created/copied in default %@",xmlFileNameWithExtension);
        return [[NSBundle mainBundle] pathForResource:xmlFileName ofType:@"xml"];
    }  
}

// REturn array of Level object
- (NSMutableArray *)loadLevels
{
    NSString *path = [LevelParser dataFilePath:NO];
    NSLog(@"%@",path);
    NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    [parser setDelegate:self];    
    if([parser parse])
        return levels;
    return nil;
}

- (void) dealloc 
{
	[aLevel release];
	[currentElementValue release];
	[super dealloc];
}

@end

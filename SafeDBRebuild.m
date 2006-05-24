/*
 *  SafeDBRebuild.c
 *  OsiriX
 *
 *  Created by Antoine Rosset on 22.05.06.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>
#include "SafeDBRebuild.h"
#include "DicomFile.h"
#include "BrowserController.h"
#include "AppController.h"

NSLock	*PapyrusLock = 0L;
NSMutableDictionary *fileFormatPlugins = 0L;

NSMutableArray			*preProcessPlugins = 0L;
NSMutableDictionary		*reportPlugins = 0L;
AppController			*appController = 0L;
NSMutableDictionary		*plugins = 0L, *pluginsDict = 0L;
NSThread				*mainThread = 0L;
BOOL					NEEDTOREBUILD = NO;
NSMutableDictionary		*DATABASECOLUMNS = 0L;

NSString* convertDICOM( NSString *inputfile)
{
	return inputfile;
}

int main(int argc, const char *argv[])
{
	NSAutoreleasePool	*pool	= [[NSAutoreleasePool alloc] init];
	
	Papy3Init();
	
//	argv[ 1] : array
//	argv[ 2] : database path
//	argv[ 3] : model path
	
	if( argv[ 1] && argv[ 2] && argv[ 3])
	{
		NSManagedObjectModel		*model;
		NSManagedObjectContext		*context;
		BOOL						COMMENTSAUTOFILL;
		
		NSString					*f = [NSString stringWithCString:argv[ 1]];
		NSString					*p = [NSString stringWithCString:argv[ 2]];
		NSString					*m = [NSString stringWithCString:argv[ 3]];
				
		NSArray	*newFilesArray = [NSArray arrayWithContentsOfFile: f];
		NSLog( f);

		NSString *INpath = [NSString stringWithContentsOfFile: p];
		NSLog( p);
		
		// Preferences
		NSDictionary	*dict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.rossetantoine.osirix"];
		COMMENTSAUTOFILL = [[dict objectForKey: @"COMMENTSAUTOFILL"] intValue];
		
		// Context & Model
		
		NSLog( m);
		model = [[NSManagedObjectModel alloc] initWithContentsOfURL: [NSURL fileURLWithPath: [NSString stringWithContentsOfFile: m]]];
		
		
		NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: model];
		context = [[NSManagedObjectContext alloc] init];
		[context setPersistentStoreCoordinator: coordinator];
	
		NSURL *url = [NSURL fileURLWithPath: [[INpath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"/Database.sql"]];
		
		NSError *error = 0L;
		if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error])
		{
			NSLog( [error localizedDescription]);
		}
		[coordinator release];
		
		[BrowserController addFilesToDatabaseSafe: newFilesArray context: context model: model databasePath:INpath COMMENTSAUTOFILL: COMMENTSAUTOFILL];
		
		error = 0L;
		[context save: &error];
		
		[model release];
		[context release];
	}
	
	[pool release];
	
	return 0;
}

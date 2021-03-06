/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSMutableDictionary+PKGLocalizedValues.h"

#import "PKGPackagesError.h"

#import "PKGObjectProtocol.h"

NSString * const PKGLanguageKey=@"LANGUAGE";
NSString * const PKGValueKey=@"VALUE";

@implementation NSMutableDictionary (PKGLocalizedValues)

+ (NSMutableDictionary *)PKG_dictionaryWithRepresentations:(NSArray *) inArray ofLocalizationsOfValueOfClass:(Class)inClass error:(out NSError **)outError
{
	if ([inArray isKindOfClass:NSArray.class]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationInvalidTypeOfValueError userInfo:nil];
		
		return nil;
	}
	
	__block NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
	
	__block NSError * tError=nil;
	
	[inArray enumerateObjectsUsingBlock:^(id bLocalizationDictionary,__attribute__((unused))NSUInteger bIndex,BOOL * bOutStop){
		
		NSString * tLanguageName=bLocalizationDictionary[PKGLanguageKey];
		
		if (tLanguageName==nil)
		{
			tError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
									   code:PKGRepresentationInvalidValue
								   userInfo:@{PKGKeyPathErrorKey:PKGLanguageKey}];
			
			tMutableDictionary=nil;
			*bOutStop=YES;
			
			return;
		}
		
		if ([tLanguageName isKindOfClass:NSString.class]==NO)
		{
			tError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
									   code:PKGRepresentationInvalidTypeOfValueError
								   userInfo:@{PKGKeyPathErrorKey:PKGLanguageKey}];
			
			tMutableDictionary=nil;
			*bOutStop=YES;
			
			return;
		}
		
		if ([tLanguageName length]==0)		// Language can not be empty
		{
			tError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
									   code:PKGRepresentationInvalidValue
								   userInfo:@{PKGKeyPathErrorKey:PKGLanguageKey}];
			
			tMutableDictionary=nil;
			*bOutStop=YES;
			
			return;
		}
		
		id tValueRepresentation=bLocalizationDictionary[PKGValueKey];
		
		if (tValueRepresentation==nil)
		{
			tError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
									   code:PKGRepresentationInvalidValue
								   userInfo:@{PKGKeyPathErrorKey:PKGValueKey}];
			
			tMutableDictionary=nil;
			*bOutStop=YES;
			
			return;
		}
		
		id tValue=nil;
		
		if ([tValueRepresentation isKindOfClass:NSDictionary.class]==YES && [inClass conformsToProtocol:@protocol(PKGObjectProtocol)]==YES)
		{
			NSError * tValueError=nil;
			
			tValue=[[inClass alloc] initWithRepresentation:(NSDictionary *)tValueRepresentation error:&tValueError];
		
			if (tValue==nil)
			{
				NSInteger tCode=tValueError.code;
					
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValue;
				
				NSString * tPathError=PKGValueKey;
				
				if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
					tPathError=[tPathError stringByAppendingPathComponent:tValueError.userInfo[PKGKeyPathErrorKey]];
				
				tError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
										   code:tCode
									   userInfo:@{PKGKeyPathErrorKey:tPathError}];
				
				tMutableDictionary=nil;
				*bOutStop=YES;
				
				return;
			}
		}
		else
		{
			if ([tValueRepresentation isKindOfClass:inClass]==NO)
			{
				tError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
										   code:PKGRepresentationInvalidTypeOfValueError
									   userInfo:@{PKGKeyPathErrorKey:PKGValueKey}];
				
				tMutableDictionary=nil;
				*bOutStop=YES;
				
				return;
			}
			
			tValue=tValueRepresentation;
		}
		
		tMutableDictionary[tLanguageName]=tValue;
		
	}];
	
	if (tMutableDictionary==nil)
	{
		if (outError!=NULL)
		{
			NSInteger tCode=tError.code;
			
			if (tCode==PKGRepresentationNilRepresentationError)
				tCode=PKGRepresentationInvalidValue;
			
			NSString * tPathError=PKGValueKey;
			
			if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
				tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
			
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
										  code:tCode
									  userInfo:@{PKGKeyPathErrorKey:tPathError}];
		}
	}
	
	return tMutableDictionary;
}

- (NSMutableArray *)PKG_representationsOfLocalizations
{
	NSMutableArray * tMutableArray=[NSMutableArray array];
	
	[self enumerateKeysAndObjectsUsingBlock:^(NSString * bLanguageKey,id bValue,__attribute__((unused))BOOL * bOutStop){
		
		id tValueRepresentation=nil;
		
		if ([bValue conformsToProtocol:@protocol(PKGObjectProtocol)]==YES)
			tValueRepresentation=[bValue representation];
		else
			tValueRepresentation=bValue;
		
		if (tValueRepresentation!=nil)
		{
			NSDictionary * tLocalizationRepresentation=@{PKGLanguageKey:bLanguageKey,PKGValueKey:tValueRepresentation};
			
			[tMutableArray addObject:tLocalizationRepresentation];
		}
		
	}];
	
	return tMutableArray;
}

@end

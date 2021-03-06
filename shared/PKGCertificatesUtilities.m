/*
Copyright (c) 2004-2016, Stephane Sudre
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "PKGCertificatesUtilities.h"

#import "NSArray+WBExtensions.h"

NSString * const PKGLoginKeychainPath=@"~/Library/Keychains/login.keychain";

@implementation PKGCertificatesUtilities

+ (NSArray *)availableIdentities
{
	NSDictionary * tQueryDictionary=@{(id)kSecClass:(id)kSecClassIdentity,
									  (id)kSecMatchSubjectStartsWith:@"Developer ID Installer:",
									  (id)kSecAttrCanSign:@(YES),
									  (id)kSecReturnRef:@(YES),
									  (id)kSecMatchLimit:(id)kSecMatchLimitAll};
	
	CFArrayRef tResults=NULL;
	
	if (SecItemCopyMatching((__bridge CFDictionaryRef)tQueryDictionary, (CFTypeRef *)&tResults)!=errSecSuccess)
		return [NSArray array];
	
	if (tResults==NULL)
		return [NSArray array];
	
	return (__bridge_transfer NSArray *)tResults;
}

+ (SecCertificateRef)copyOfCertificateWithName:(NSString *) inName
{
	SecIdentityRef tIdentityRef=[PKGCertificatesUtilities identityWithName:inName atPath:nil];
	
	if (tIdentityRef==NULL)
		return NULL;
	
	SecCertificateRef tCertificateRef=NULL;
	SecIdentityCopyCertificate(tIdentityRef,&tCertificateRef);
	
	return tCertificateRef;
	
	if (tCertificateRef!=NULL)
	{
		CFStringRef tCertificateCommonName=NULL;
		
		if (SecCertificateCopyCommonName(tCertificateRef, &tCertificateCommonName)!=errSecSuccess)
		{
			// Release Memory
			
			CFRelease(tCertificateRef);
		}
		
		if (CFStringCompare(tCertificateCommonName,(__bridge CFStringRef)inName,0)==kCFCompareEqualTo)
			return tCertificateRef;
		
		// Release Memory
		
		CFRelease(tCertificateRef);
	}
}

+ (SecIdentityRef)identityWithName:(NSString *) inName atPath:(NSString *) inPath
{
	if ([inName length]==0)
		return NULL;
	
	NSArray * tKeychainPaths=((inPath!=nil) ? @[inPath] : nil);
	
	NSArray * tSecKeychainArray=[tKeychainPaths WB_arrayByMappingObjectsLenientlyUsingBlock:^id(NSString * bKeychainPath,NSUInteger bIndex){
	
		SecKeychainRef tKeyChainRef=NULL;
		
		OSStatus tStatus=SecKeychainOpen([inPath fileSystemRepresentation],&tKeyChainRef);
			
		if (tStatus!=errSecSuccess)
		{
			NSLog(@"SecKeychainOpen error:%ld",(long)tStatus);
			
			switch(tStatus)
			{
				case errSecNoSuchKeychain:
					
					break;
			}
			
			return nil;
		}
		
		return (__bridge id)tKeyChainRef;
	}];
	
	NSMutableDictionary * tQueryDictionary=[@{(id)kSecClass:(id)kSecClassIdentity,
											  (id)kSecMatchSubjectWholeString:inName,
											  (id)kSecAttrCanSign:@(YES),
											  (id)kSecReturnRef:@(YES),
											  (id)kSecMatchLimit:(id)kSecMatchLimitOne} mutableCopy];
	
	if ([tSecKeychainArray count]>0)
		[tQueryDictionary setObject:tSecKeychainArray forKey:kSecMatchSearchList];
	
	
	SecIdentityRef tResult=NULL;
	
	OSStatus tStatus=SecItemCopyMatching((__bridge CFDictionaryRef)tQueryDictionary, (CFTypeRef *)&tResult);
	
	if (tStatus!=errSecSuccess)
		return NULL;
	
	return tResult;
}

@end

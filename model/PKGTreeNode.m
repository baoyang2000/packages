/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/* Some portions of this code is from or inspired by the NSOutlineView sample code from Apple, inc */

#import "PKGTreeNode.h"

#import "PKGPackagesError.h"

#import "NSArray+WBExtensions.h"

NSString * const PKGTreeNodeChildrenKey=@"CHILDREN";

@interface PKGTreeNode ()
{
	__weak PKGTreeNode * _parent;
	
	id<PKGObjectProtocol,NSCopying> _representedObject;
	
	NSMutableArray * _children;
}

- (PKGTreeNode *)deepCopyWithZone:(NSZone *)inZone;

- (void)setParent:(PKGTreeNode *)inParent;

- (BOOL)_enumerateRepresentedObjectsRecursivelyUsingBlock:(void(^)(id<PKGObjectProtocol> representedObject,BOOL *stop))block;

@end


@implementation PKGTreeNode

+ (instancetype)treeNode
{
	return [[self alloc] init];
}

+ (instancetype)treeNodeWithRepresentedObject:(id<PKGObjectProtocol>)inRepresentedObject children:(NSArray *)inChildren
{
	return [[self alloc] initWithRepresentedObject:inRepresentedObject children:inChildren];
}

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_parent=nil;
		_children=[NSMutableArray array];
	}
	
	return self;
}

- (instancetype)initWithRepresentedObject:(id<PKGObjectProtocol,NSCopying>)inRepresentedObject children:(NSArray *)inChildren
{
	self=[super init];
	
	if (self!=nil)
	{
		_representedObject=inRepresentedObject;
		
		if (inChildren!=nil)
		{
			_children=[inChildren mutableCopy];
		
			[_children makeObjectsPerformSelector:@selector(setParent:) withObject:self];
		}
		else
		{
			_children=[NSMutableArray array];
		}
	}
	
	return self;
}

- (id)initWithRepresentation:(NSDictionary *)inRepresentation error:(out NSError **)outError
{
	if (inRepresentation==nil)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationNilRepresentationError userInfo:nil];
		
		return nil;
	}
	
	if ([inRepresentation isKindOfClass:NSDictionary.class]==NO)
	{
		if (outError!=NULL)
			*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain code:PKGRepresentationInvalidTypeOfValueError userInfo:nil];
		
		return nil;
	}
	
	self=[super init];
	
	if (self!=nil)
	{
		_parent=nil;
		
		__block NSError * tError=nil;
		
		_representedObject=[[[self representedObjectClassForRepresentation:inRepresentation] alloc] initWithRepresentation:inRepresentation error:&tError];
		
		if (_representedObject==nil)
		{
			if (outError!=NULL)
			{
				NSInteger tCode=tError.code;
				
				if (tCode==PKGRepresentationNilRepresentationError)
					tCode=PKGRepresentationInvalidValue;
				
				*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
											  code:tCode
										  userInfo:tError.userInfo];
			}
			
			return nil;
		}
		
		NSArray * tChildrenRepresentation=inRepresentation[PKGTreeNodeChildrenKey];
		
		if (tChildrenRepresentation==nil)
		{
			_children=[NSMutableArray array];
		}
		else
		{
			if ([tChildrenRepresentation isKindOfClass:NSArray.class]==NO)
			{
				if (outError!=NULL)
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:PKGRepresentationInvalidTypeOfValueError
											  userInfo:@{PKGKeyPathErrorKey:PKGTreeNodeChildrenKey}];
				
				return nil;
			}
			
			_children=[[tChildrenRepresentation WB_arrayByMappingObjectsUsingBlock:^id(NSDictionary * bChildRepresentation,__attribute__((unused))NSUInteger bIndex){
				PKGTreeNode * tChild=[[[self class] alloc] initWithRepresentation:bChildRepresentation error:&tError];
				
				[tChild setParent:self];
				
				return tChild;
			}] mutableCopy];
			
			if (_children==nil)
			{
				if (outError!=NULL)
				{
					NSInteger tCode=tError.code;
					
					if (tCode==PKGRepresentationNilRepresentationError)
						tCode=PKGRepresentationInvalidValue;
					
					NSString * tPathError=PKGTreeNodeChildrenKey;
					
					if (tError.userInfo[PKGKeyPathErrorKey]!=nil)
						tPathError=[tPathError stringByAppendingPathComponent:tError.userInfo[PKGKeyPathErrorKey]];
					
					*outError=[NSError errorWithDomain:PKGPackagesModelErrorDomain
												  code:tCode
											  userInfo:@{PKGKeyPathErrorKey:tPathError}];
				}
				
				return nil;
			}
		}
	}
	
	return self;
}

- (NSMutableDictionary *)representation
{
	NSMutableDictionary * tRepresentation=[NSMutableDictionary dictionary];
	
	NSMutableDictionary * tRepresentedObjectRepresentation=[_representedObject representation];
	
	if (tRepresentedObjectRepresentation!=nil)
		tRepresentation=tRepresentedObjectRepresentation;
	
	NSArray * tChildrenRepresentation=[_children WB_arrayByMappingObjectsUsingBlock:^id(PKGTreeNode * bTreeNode,__attribute__((unused))NSUInteger bIndex){
		return [bTreeNode representation];
	}];
	
	if ([tChildrenRepresentation count]>0)
		tRepresentation[PKGTreeNodeChildrenKey]=tChildrenRepresentation;
	
	return tRepresentation;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tDescription=[NSMutableString string];
	
	// A COMPLETER
	
	return tDescription;
}

- (PKGTreeNode *)deepCopy
{
	return [self deepCopyWithZone:nil];
}

- (PKGTreeNode *)deepCopyWithZone:(NSZone *)inZone
{
	PKGTreeNode * nTreeNode=[[[self class] allocWithZone:inZone] init];
	
	if (nTreeNode!=nil)
	{
		nTreeNode->_representedObject=[_representedObject copyWithZone:inZone];
		
		for(PKGTreeNode * tChild in _children)
		{
			PKGTreeNode * nChild=[tChild deepCopyWithZone:inZone];
			
			if (nChild==nil)
				return nil;
			
			nChild.parent=self;
			
			[nTreeNode->_children addObject:nChild];
		}
	}
	
	return nTreeNode;
}

#pragma mark -

- (Class)representedObjectClassForRepresentation:(NSDictionary *)inRepresentation
{
	NSLog(@"You need to define the class of the represented object");
	
	return nil;
}

- (id<PKGObjectProtocol,NSCopying>)representedObject
{
	return _representedObject;
}

#pragma mark -

- (NSUInteger)height
{
	if (_children.count==0)
		return 0;
	
	NSUInteger tMaxChildHeight=0;
	
	for(PKGTreeNode * tChild in _children)
	{
		NSUInteger tChildHeight=[tChild height];
		
		if (tChildHeight>tMaxChildHeight)
			tMaxChildHeight=tChildHeight;
	}
	
	return (tMaxChildHeight+1);
}

- (BOOL)isLeaf
{
	return ([self numberOfChildren]==0);
}

- (NSIndexPath *)indexPath
{
	PKGTreeNode * tParent=[self parent];
	
	if (tParent==nil)
		return nil;
	
	NSIndexPath * tParentIndexPath=[tParent indexPath];
	
	NSUInteger tIndex=[[tParent children] indexOfObject:self];
	
	if (tParentIndexPath==nil)
		return [NSIndexPath indexPathWithIndex:tIndex];
	
	return [tParentIndexPath indexPathByAddingIndex:tIndex];
}

- (PKGTreeNode *)parent
{
	return _parent;
}

- (void)setParent:(PKGTreeNode *)inParent
{
	_parent=inParent;
}

- (NSUInteger)numberOfChildren
{
	return [_children count];
}

- (NSArray *)children
{
	return [_children copy];
}

- (BOOL)isDescendantOfNode:(PKGTreeNode *)inTreeNode
{
	PKGTreeNode * tParent = [self parent];
	
	while (tParent)
	{
		if (tParent == inTreeNode)
			return YES;
		
		tParent = [tParent parent];
	}
	
	return NO;
}

- (BOOL)isDescendantOfNodeInArray:(NSArray *)inTreeNodes
{
	for (PKGTreeNode * tTreeNode in inTreeNodes)
	{
		if ([self isDescendantOfNode:tTreeNode]==YES)
			return YES;
	}
	
	return NO;
}

- (PKGTreeNode *)descendantNodeAtIndex:(NSUInteger)inIndex
{
	if (inIndex>=[_children count])
		return nil;
	
	return [_children objectAtIndex:inIndex];
}

- (PKGTreeNode *)descendantNodeAtIndexPath:(NSIndexPath *)inIndexPath
{
	// A COMPLETER
	
	return nil;
}

#pragma mark -

- (NSUInteger)indexOfChildIdenticalTo:(PKGTreeNode *)inTreeNode
{
	if (inTreeNode==nil)
		return NSNotFound;
	
	return [_children indexOfObjectIdenticalTo:inTreeNode];
}

- (NSUInteger)indexOfChildMatching:(BOOL (^)(id bTreeNode))inBlock
{
	if (inBlock==nil)
		return NSNotFound;
	
	__block NSUInteger tChildIndex=NSNotFound;
	
	[_children enumerateObjectsUsingBlock:^(PKGTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
	
		if (inBlock(bTreeNode)==YES)
		{
			tChildIndex=bIndex;
			*bOutStop=YES;
		}
	
	}];
	
	return tChildIndex;
}

#pragma mark -

- (void)addChild:(PKGTreeNode *)inChild
{
	[inChild setParent:self];
	[_children addObject:inChild];
}

- (void)addChildren:(NSArray *)inChildren
{
	[inChildren makeObjectsPerformSelector:@selector(setParent:) withObject:self];
	[_children addObjectsFromArray:inChildren];
}

- (BOOL)addUnmatchedDescendantsOfNode:(PKGTreeNode *)inTreeNode usingSelector:(SEL)inComparator
{
	if (inTreeNode==nil)
		return NO;
	
	__block BOOL tDidAddDescendants=NO;
	
	NSInvocation * tInvocation=[NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:inComparator]];
	tInvocation.selector=inComparator;
	
	for(PKGTreeNode * tDescendant in inTreeNode.children)
	{
		__block BOOL tMatched=NO;
		
		tInvocation.target=tDescendant;
		
		[_children enumerateObjectsUsingBlock:^(PKGTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
			
			NSComparisonResult tComparisonResult;
			
			[tInvocation setArgument:&bTreeNode atIndex:2];
			[tInvocation invoke];
			[tInvocation getReturnValue:&tComparisonResult];
			
			if (tComparisonResult==NSOrderedSame)
			{
				tMatched=YES;
				
				// Checked with the descendants
				
				tDidAddDescendants=[bTreeNode addUnmatchedDescendantsOfNode:tDescendant usingSelector:inComparator];
				*bOutStop=YES;
			}
		}];
					
		if (tMatched==NO)
		{
			tDidAddDescendants=YES;
			[tDescendant insertAsSiblingOfChildren:_children ofNode:self sortedUsingSelector:inComparator];
		}
	}
	
	return tDidAddDescendants;
}

- (PKGTreeNode *)filterRecursivelyUsingBlock:(BOOL (^)(id bTreeNode))inBlock
{
	return [self filterRecursivelyUsingBlock:inBlock maximumDepth:NSNotFound];
}

- (PKGTreeNode *)filterRecursivelyUsingBlock:(BOOL (^)(id bTreeNode))inBlock maximumDepth:(NSUInteger)inMaximumDepth
{
	if (inBlock==nil)
		return self;
	
	if (inMaximumDepth>0)
	{
		if (inMaximumDepth!=NSNotFound)
			inMaximumDepth--;
		
		NSUInteger tCount=_children.count;
		
		for(NSUInteger tIndex=tCount;tIndex>0;tIndex--)
		{
			PKGTreeNode * tResult=[_children[tIndex-1] filterRecursivelyUsingBlock:inBlock maximumDepth:inMaximumDepth];
			
			if (tResult==nil)
				[_children removeObjectAtIndex:tIndex-1];
		}
	}
	
	if (inBlock(self)==NO)
		return nil;
	
	return self;
}

- (void)insertChild:(PKGTreeNode *)inChild atIndex:(NSUInteger)inIndex
{
	if (inChild==nil || inIndex>[_children count])
		return;
	
	[inChild setParent:self];
	[_children insertObject:inChild atIndex:inIndex];
}

- (void)insertChildren:(NSArray *)inChildren atIndex:(NSUInteger)inIndex
{
	if ([inChildren count]==0 || inIndex>[_children count])
		return;
	
	[inChildren makeObjectsPerformSelector:@selector(setParent:) withObject:self];
	[_children insertObjects:inChildren atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(inIndex, [inChildren count])]];
}


- (void)insertAsSiblingOfChildren:(NSMutableArray *)inChildren ofNode:(PKGTreeNode *)inParent sortedUsingComparator:(NSComparator)inComparator
{
	if (inChildren==nil || inComparator==nil)
		return;
	
	if ([inChildren isKindOfClass:[NSMutableArray class]]==NO)
		return;
	
	if (inChildren.count==0)
	{
		[self setParent:inParent];
		[inChildren addObject:self];
		return;
	}
	
	__block BOOL tInserted=NO;
	
	[_children enumerateObjectsUsingBlock:^(PKGTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
		
		if (inComparator(self,bTreeNode)!=NSOrderedDescending)
		{
			[self setParent:inParent];
			[inChildren insertObject:self atIndex:bIndex];
			tInserted=YES;
			*bOutStop=YES;
		}
	}];
	
	if (tInserted==0)
	{
		[self setParent:inParent];
		[inChildren addObject:self];
		return;
	}
}

- (void)insertAsSiblingOfChildren:(NSMutableArray *)inChildren ofNode:(PKGTreeNode *)inParent sortedUsingSelector:(SEL)inComparator
{
	if (inChildren==nil || inComparator==nil)
		return;
	
	if ([inChildren isKindOfClass:[NSMutableArray class]]==NO)
		return;
	
	NSInvocation * tInvocation=[NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:inComparator]];
	tInvocation.target=self;
	tInvocation.selector=inComparator;
	
	__block BOOL tInserted=NO;
	
	[inChildren enumerateObjectsUsingBlock:^(PKGTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
		
		NSComparisonResult tComparisonResult;
		
		[tInvocation setArgument:&bTreeNode atIndex:2];
		[tInvocation invoke];
		[tInvocation getReturnValue:&tComparisonResult];
		
		if (tComparisonResult!=NSOrderedDescending)
		{
			[self setParent:inParent];
			[inChildren insertObject:self atIndex:bIndex];
			tInserted=YES;
			*bOutStop=YES;
		}
	}];
	
	if (tInserted==0)
	{
		[self setParent:inParent];
		[inChildren addObject:self];
		return;
	}
}

- (void)insertChild:(PKGTreeNode *)inChild sortedUsingComparator:(NSComparator)inComparator
{
	if (inChild==nil || inComparator==nil)
		return;
	
	__block BOOL tDone=NO;
	
	[_children enumerateObjectsUsingBlock:^(PKGTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
		
		if (inComparator(inChild,bTreeNode)!=NSOrderedDescending)
		{
			[inChild setParent:self];
			[_children insertObject:inChild atIndex:bIndex];
			
			tDone=YES;
			*bOutStop=YES;
		}
	}];
	
	if (tDone==YES)
		return;
	
	[inChild setParent:self];
	[_children addObject:inChild];
}


- (void)insertChild:(PKGTreeNode *)inChild sortedUsingSelector:(SEL)inComparator
{
	if (inChild==nil || inComparator==nil)
		return;
	
	NSInvocation * tInvocation=[NSInvocation invocationWithMethodSignature:[inChild methodSignatureForSelector:inComparator]];
	tInvocation.target=inChild;
	tInvocation.selector=inComparator;
	
	__block BOOL tDone=NO;
	
	[_children enumerateObjectsUsingBlock:^(PKGTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
		
		NSComparisonResult tComparisonResult;
		
		[tInvocation setArgument:&bTreeNode atIndex:2];
		[tInvocation invoke];
		[tInvocation getReturnValue:&tComparisonResult];
		
		if (tComparisonResult!=NSOrderedDescending)
		{
			[inChild setParent:self];
			[_children insertObject:inChild atIndex:bIndex];
			
			tDone=YES;
			*bOutStop=YES;
		}
	}];
	
	if (tDone==YES)
		return;
	
	[inChild setParent:self];
	[_children addObject:inChild];
}

- (void)removeChildAtIndex:(NSUInteger)inIndex
{
	if (inIndex>=[_children count])
		return;
	
	PKGTreeNode * tTreeNode=_children[inIndex];
	
	[tTreeNode setParent:nil];
	
	[_children removeObjectAtIndex:inIndex];
}

- (void)removeChildrenAtIndexes:(NSIndexSet *)inIndexSet
{
	if (inIndexSet==nil || [inIndexSet lastIndex]>=[_children count])
		return;
	
	[_children enumerateObjectsAtIndexes:inIndexSet options:0 usingBlock:^(PKGTreeNode *bTreeNode,__attribute__((unused))NSUInteger bIndex,__attribute__((unused))BOOL * boutStop){
	
		[bTreeNode setParent:nil];
	}];
	
	[_children removeObjectsAtIndexes:inIndexSet];
}

- (void)removeChild:(PKGTreeNode *)inChild
{
	if (inChild==nil)
		return;
	
	[inChild setParent:nil];
	[_children removeObjectIdenticalTo:inChild];
}

- (void)removeChildren
{
	[_children makeObjectsPerformSelector:@selector(setParent:) withObject:self];
	[_children removeAllObjects];
}

- (void)removeFromParent
{
	[[self parent] removeChild:self];
}

#pragma mark -

/* Code from the Apple Sample Code */

+ (NSArray *)minimumNodeCoverFromNodesInArray:(NSArray *)inArray
{
	NSMutableArray *tMinimumNodeCover = [NSMutableArray array];
	NSMutableArray * tNodeQueue = [NSMutableArray arrayWithArray:inArray];
	PKGTreeNode *tTreeNode = nil;
	
	while ([tNodeQueue count])
	{
		tTreeNode = tNodeQueue[0];
		[tNodeQueue removeObjectAtIndex:0];
		
		PKGTreeNode *tTreeNodeParent=[tTreeNode parent];
		
		while ( tTreeNodeParent && [tNodeQueue indexOfObjectIdenticalTo:tTreeNodeParent]!=NSNotFound)
		{
			[tNodeQueue removeObjectIdenticalTo: tTreeNode];
			tTreeNode = tTreeNodeParent;
			tTreeNodeParent=tTreeNode.parent;
		}
		
		if (![tTreeNode isDescendantOfNodeInArray: tMinimumNodeCover])
			[tMinimumNodeCover addObject: tTreeNode];
		
		[tNodeQueue removeObjectIdenticalTo: tTreeNode];
	}
	
	return [tMinimumNodeCover copy];
}

#pragma mark -

- (BOOL)_enumerateRepresentedObjectsRecursivelyUsingBlock:(void(^)(id<PKGObjectProtocol> representedObject,BOOL *stop))block
{
	BOOL tBlockDidStop=NO;

	(void)block(self.representedObject,&tBlockDidStop);
	if (tBlockDidStop==YES)
		return NO;

	for(PKGTreeNode * tTreeNode in self.children)
	{
		if ([tTreeNode _enumerateRepresentedObjectsRecursivelyUsingBlock:block]==NO)
			return NO;
	}
	
	return YES;
}
																													  																																												
- (void)enumerateRepresentedObjectsRecursivelyUsingBlock:(void(^)(id<PKGObjectProtocol> representedObject,BOOL *stop))block
{
	[self _enumerateRepresentedObjectsRecursivelyUsingBlock:block];
}

@end


/*
 Copyright (c) 2006, Greg Hulands <ghulands@mac.com>
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, 
 are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list 
 of conditions and the following disclaimer.
 
 Redistributions in binary form must reproduce the above copyright notice, this 
 list of conditions and the following disclaimer in the documentation and/or other 
 materials provided with the distribution.
 
 Neither the name of Greg Hulands nor the names of its contributors may be used to 
 endorse or promote products derived from this software without specific prior 
 written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
 SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
 BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY 
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CKHostCategory.h"
#import "CKHost.h"

NSString *CKHostCategoryChanged = @"CKHostCategoryChanged";

@interface CKHostCategory (private)
- (void)didChange;
@end

@implementation CKHostCategory

+ (void)initialize	// preferred over +load in most cases
{
	[CKHostCategory setVersion:1];
}

- (id)initWithName:(NSString *)name
{
	if ((self = [super init]))
	{
		myName = [name copy];
		myIsEditable = YES;
		myChildCategories = [[NSMutableArray array] retain];
	}
	return self;
}

- (void)dealloc
{
	[myName release];
	[myChildCategories release];
	[super dealloc];
}

- (id)initWithCoder:(NSCoder *)coder
{
	if (self = [super init])
	{
		int version = [coder decodeIntForKey:@"version"];
#pragma unused (version)
		myName = [[coder decodeObjectForKey:@"name"] copy];
		myIsEditable = YES;
		myChildCategories = [[NSMutableArray arrayWithArray:[coder decodeObjectForKey:@"categories"]] retain];
		
		NSEnumerator *e = [myChildCategories objectEnumerator];
		id cur;
		
		while ((cur = [e nextObject]))
		{
			if ([cur isKindOfClass:[CKHostCategory class]])
			{
				[[NSNotificationCenter defaultCenter] addObserver:self
														 selector:@selector(childChanged:)
															 name:CKHostCategoryChanged
														   object:cur];
			}
			else
			{
				[[NSNotificationCenter defaultCenter] addObserver:self
														 selector:@selector(hostChanged:)
															 name:CKHostChanged
														   object:cur];
			}
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeInt:[CKHostCategory version] forKey:@"version"];
	[coder encodeObject:myName forKey:@"name"];
	[coder encodeObject:myChildCategories forKey:@"categories"];
}

- (NSString *)name
{
	return myName;
}

- (void)setName:(NSString *)name
{
	if (name != myName)
	{
		[myName autorelease];
		myName = [name copy];
		[self didChange];
	}
}

- (void)didChange
{
	[[NSNotificationCenter defaultCenter] postNotificationName:CKHostCategoryChanged object:self];
}

- (void)childChanged:(NSNotification *)n
{
	[self didChange];
}

- (void)addChildCategory:(CKHostCategory *)cat
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(childChanged:) 
												 name:CKHostCategoryChanged 
											   object:cat];
	[self willChangeValueForKey:@"childCategories"];
	[myChildCategories addObject:cat];
	[cat setCategory:self];
	[self didChangeValueForKey:@"childCategories"];
	[self didChange];
}
- (void)insertChildCategory:(CKHostCategory *)cat atIndex:(unsigned)index
{
	if (index >= [myChildCategories count])
	{
		[self addChildCategory:cat];
		return;
	}
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(childChanged:) 
												 name:CKHostCategoryChanged 
											   object:cat];
	[self willChangeValueForKey:@"childCategories"];
	[myChildCategories insertObject:cat atIndex:index];
	[cat setCategory:self];
	[self didChangeValueForKey:@"childCategories"];
	[self didChange];
}

- (void)removeChildCategory:(CKHostCategory *)cat
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:CKHostCategoryChanged object:cat];
	[self willChangeValueForKey:@"childCategories"];
    [cat setCategory:nil];
	[myChildCategories removeObject:cat];
	[self didChangeValueForKey:@"childCategories"];
	[self didChange];
}

- (NSArray *)childCategories
{
	return [NSArray arrayWithArray:myChildCategories];
}

- (void)hostChanged:(NSNotification *)n
{
	[self didChange];
}

- (void)addHost:(CKHost *)host
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(hostChanged:)
												 name:CKHostCategoryChanged
											   object:host];
	[self willChangeValueForKey:@"childCategories"];
	[myChildCategories addObject:host];
	[host setCategory:self];
	[self didChangeValueForKey:@"childCategories"];
	[self didChange];
}
- (void)insertHost:(CKHost *)host atIndex:(unsigned)index
{
	if (index >= [myChildCategories count])
	{
		[self addHost:host];
		return;
	}
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(hostChanged:)
												 name:CKHostCategoryChanged
											   object:host];
	[self willChangeValueForKey:@"childCategories"];
	[myChildCategories insertObject:host atIndex:index];
	[host setCategory:self];
	[self didChangeValueForKey:@"childCategories"];
	[self didChange];
}

- (void)removeHost:(CKHost *)host
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:CKHostCategoryChanged object:host];
	[self willChangeValueForKey:@"childCategories"];
	[myChildCategories removeObjectIdenticalTo:host];
	[host setCategory:nil];
	[self didChangeValueForKey:@"childCategories"];
	[self didChange];
}

- (NSArray *)hosts
{
	return [NSArray arrayWithArray:myChildCategories];
}

- (void)setCategory:(CKHostCategory *)parent
{
	if (parent != myParentCategory)
	{
		myParentCategory = parent;
		[self didChange];
	}
}

- (CKHostCategory *)category
{
	return myParentCategory;
}

static NSImage *sFolderImage = nil;
- (NSImage *)icon
{
	if (!sFolderImage)
	{
		NSBundle *b = [NSBundle bundleForClass:[self class]];
		NSString *p = [b pathForResource:@"folder" ofType:@"png"];
		sFolderImage = [[NSImage alloc] initWithContentsOfFile:p];
	}
	return sFolderImage;
}

- (NSImage *)iconWithSize:(NSSize)size
{
	NSImage *copy = [[self icon] copy];
	[copy setScalesWhenResized:YES];
	[copy setSize:size];
	return [copy autorelease];
}

- (void)setEditable:(BOOL)editableFlag
{
	myIsEditable = editableFlag;
}

- (BOOL)isEditable
{
	return myIsEditable;
}

- (NSArray *)children
{
	return [NSArray arrayWithArray:myChildCategories];
}

- (void)appendToDescription:(NSMutableString *)str indentation:(unsigned)indent
{
	[str appendFormat:@"%@:\n", myName];
	NSEnumerator *e = [myChildCategories objectEnumerator];
	id host;
	
	while ((host = [e nextObject]))
	{
		if ([host isKindOfClass:[CKHost class]])
		{
			int i;
			for (i = 0; i < indent; i++)
			{
				[str appendString:@"\t"];
			}
			[str appendFormat:@"\t%@\n", [host name]];
		}
		else
		{
			[host appendToDescription:str indentation:indent+1];
		}
	}
}

- (NSString *)description
{
	NSMutableString *str = [NSMutableString stringWithString:@"\n"];
	[self appendToDescription:str indentation:0];
	return str;
}

@end

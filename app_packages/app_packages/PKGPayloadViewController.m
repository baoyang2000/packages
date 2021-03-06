/*
 Copyright (c) 2016, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PKGPayloadViewController.h"

#import "PKGApplicationPreferences.h"

#import "PKGPackagePayloadDataSource.h"

#import "PKGPayloadFilesHierarchyViewController.h"

#import "PKGFilesEmptySelectionInspectorViewController.h"
#import "PKGFilesSelectionInspectorViewController.h"

#import "NSOutlineView+Selection.h"

#import "PKGPayloadTreeNode+UI.h"

@interface PKGPayloadViewController ()
{
	IBOutlet NSPopUpButton * _payloadTypePopUpButton;
	IBOutlet NSButton * _splitForksCheckbox;
	
	IBOutlet NSTextField * _defaultDestinationLabel;
	IBOutlet NSButton * _defaultDestinationSetButton;
	
	IBOutlet NSView * _hierarchyPlaceHolderView;
	IBOutlet NSView * _inspectorPlaceHolderView;
	
	PKGPayloadFilesHierarchyViewController * _filesHierarchyViewController;
	
	PKGViewController *_emptySelectionInspectorViewController;
	PKGFilesSelectionInspectorViewController * _selectionInspectorViewController;
	
	PKGViewController *_currentInspectorViewController;
	
	PKGPackagePayloadDataSource * _dataSource;
}

- (void)_updateLayout;

- (IBAction)switchPayloadType:(id)sender;

- (IBAction)setDefaultDestination:(id)sender;

- (IBAction)switchHiddenFolderTemplatesVisibility:(id)sender;

// Notifications

- (void)fileHierarchySelectionDidChange:(NSNotification *)inNotification;

- (void)fileHierarchyDidRenameFolder:(NSNotification *)inNotification;

- (void)advancedModeStateDidChange:(NSNotification *)inNotification;

@end

@implementation PKGPayloadViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self=[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	_dataSource=[PKGPackagePayloadDataSource new];
	
	return self;
}

- (NSString *)nibName
{
	return @"PKGPayloadViewController";
}

- (void)WB_viewDidLoad
{
	[super WB_viewDidLoad];
	
    _filesHierarchyViewController=[PKGPayloadFilesHierarchyViewController new];
	
	_filesHierarchyViewController.label=@"Payload";
	_filesHierarchyViewController.hierarchyDataSource=_dataSource;
	
	_filesHierarchyViewController.view.frame=_hierarchyPlaceHolderView.bounds;
	
	[_hierarchyPlaceHolderView addSubview:_filesHierarchyViewController.view];
	
    // Do view setup here.
}

#pragma mark -

- (void)WB_viewWillAppear
{
	[super WB_viewWillAppear];
	
	[self _updateLayout];
	
	[_payloadTypePopUpButton selectItemWithTag:self.payload.type];
	
	_splitForksCheckbox.state=(self.payload.splitForksIfNeeded==YES) ? NSOnState : NSOffState;
	
	_defaultDestinationLabel.stringValue=self.payload.defaultInstallLocation;
	
	_dataSource.rootNodes=self.payload.filesTree.rootNodes;
	
	_dataSource.delegate=_filesHierarchyViewController;
	_dataSource.installLocationNode=[self.payload.filesTree.rootNode descendantNodeAtPath:self.payload.defaultInstallLocation];
	
	if (_dataSource.installLocationNode==nil)
	{
		// A COMPLETER
	}
	
	[_filesHierarchyViewController WB_viewWillAppear];
	
	// A COMPLETER
}

- (void)WB_viewDidAppear
{
	[super WB_viewDidAppear];
	
	[self.view.window makeFirstResponder:_filesHierarchyViewController.outlineView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(advancedModeStateDidChange:) name:PKGPreferencesAdvancedAdvancedModeStateDidChangeNotification object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileHierarchySelectionDidChange:) name:NSOutlineViewSelectionDidChangeNotification object:_filesHierarchyViewController.outlineView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileHierarchyDidRenameFolder:) name:PKGFilesHierarchyDidRenameFolderNotification object:_filesHierarchyViewController.outlineView];
	
	_dataSource.filePathConverter=self.filePathConverter;
	
	[_filesHierarchyViewController WB_viewDidAppear];
	
	[self fileHierarchySelectionDidChange:[NSNotification notificationWithName:NSOutlineViewSelectionDidChangeNotification object:_filesHierarchyViewController.outlineView]];
}

- (void)WB_viewWillDisappear
{
	[super WB_viewWillDisappear];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGPreferencesAdvancedAdvancedModeStateDidChangeNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSOutlineViewSelectionDidChangeNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PKGFilesHierarchyDidRenameFolderNotification object:nil];
	
	[_filesHierarchyViewController WB_viewWillDisappear];
}

- (void)WB_viewDidDisappear
{
	[_filesHierarchyViewController WB_viewDidDisappear];
}

#pragma mark -

- (void)_updateLayout
{
	BOOL tAdvancedModeEnabled=[PKGApplicationPreferences sharedPreferences].advancedMode;
	
	_splitForksCheckbox.hidden=(tAdvancedModeEnabled==NO);
}

#pragma mark -

- (IBAction)switchPayloadType:(id)sender
{
	// A COMPLETER
}

- (IBAction)setDefaultDestination:(id)sender
{
	NSOutlineView * tOutlineView=_filesHierarchyViewController.outlineView;
	NSIndexSet * tClickedOrSelectedIndexes=tOutlineView.WB_selectedOrClickedRowIndexes;
	
	if (tClickedOrSelectedIndexes.count!=1)
		return;
	
	[_defaultDestinationSetButton setEnabled:NO];
	
	PKGPayloadTreeNode * tPreviousDefaultInstallationLocationNode=_dataSource.installLocationNode;
	_dataSource.installLocationNode=[tOutlineView itemAtRow:tClickedOrSelectedIndexes.firstIndex];
	
	NSMutableIndexSet * tRowIndexes=[tClickedOrSelectedIndexes mutableCopy];
	NSInteger tIndex=[tOutlineView rowForItem:tPreviousDefaultInstallationLocationNode];
	
	if (tIndex!=-1)
		[tRowIndexes addIndex:tIndex];
	
	self.payload.defaultInstallLocation=[_dataSource.installLocationNode filePath];
	_defaultDestinationLabel.stringValue=self.payload.defaultInstallLocation;
	
	[tOutlineView reloadDataForRowIndexes:tRowIndexes
							columnIndexes:[NSIndexSet indexSetWithIndex:[tOutlineView columnWithIdentifier:@"file.name"]]];
	
	[self noteDocumentHasChanged];
}

- (IBAction)switchHiddenFolderTemplatesVisibility:(id)sender
{
	self.payload.hiddenFolderTemplatesIncluded=!self.payload.hiddenFolderTemplatesIncluded;
	
	if (self.payload.hiddenFolderTemplatesIncluded==YES)
		[_filesHierarchyViewController showHiddenFolderTemplates];
	else
		[_filesHierarchyViewController hideHiddenFolderTemplates];
	
	[self noteDocumentHasChanged];
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tSelector=inMenuItem.action;
	
	// Set Default Location
	
	if (tSelector==@selector(setDefaultDestination:))
	{
		NSOutlineView * tOutlineView=_filesHierarchyViewController.outlineView;
		NSIndexSet * tClickedOrSelectedIndexes=tOutlineView.WB_selectedOrClickedRowIndexes;
		
		if (tClickedOrSelectedIndexes.count!=1)
			return NO;
		
		PKGPayloadTreeNode * tSelectedTreeNode=[tOutlineView itemAtRow:tClickedOrSelectedIndexes.firstIndex];
		
		if (tSelectedTreeNode==_dataSource.installLocationNode)
			return NO;
		
		return [tSelectedTreeNode isSelectableAsInstallationLocation];
	}
	
	// Show|Hide Hidden Folders
	
	if (tSelector==@selector(switchHiddenFolderTemplatesVisibility:))
	{
		[inMenuItem setTitle:(self.payload.hiddenFolderTemplatesIncluded==YES) ? NSLocalizedString(@"Hide Hidden Folders", @"") : NSLocalizedString(@"Show Hidden Folders", @"")];
		 
		 return YES;
	}
	
	// A COMPLETER
	
	return YES;
}

#pragma mark - Notifications

- (void)fileHierarchySelectionDidChange:(NSNotification *)inNotification
{
	NSOutlineView * tOutlineView=_filesHierarchyViewController.outlineView;
	
	if (inNotification.object!=tOutlineView)
		return;
	
	NSUInteger tNumberOfSelectedRows=tOutlineView.numberOfSelectedRows;
	
	// Inspector
	
	if (tNumberOfSelectedRows==0)
	{
		if (_emptySelectionInspectorViewController==nil)
			_emptySelectionInspectorViewController=[PKGFilesEmptySelectionInspectorViewController new];
		
		if (_currentInspectorViewController!=_emptySelectionInspectorViewController)
		{
			[_currentInspectorViewController WB_viewWillDisappear];
			
			[_currentInspectorViewController.view removeFromSuperview];
			
			[_currentInspectorViewController WB_viewDidDisappear];
			
			_currentInspectorViewController=_emptySelectionInspectorViewController;
			
			_currentInspectorViewController.view.frame=_inspectorPlaceHolderView.bounds;
			
			[_currentInspectorViewController WB_viewWillAppear];
			
			[_inspectorPlaceHolderView addSubview:_currentInspectorViewController.view];
			
			[_currentInspectorViewController WB_viewDidAppear];
		}
	}
	else
	{
		if (_selectionInspectorViewController==nil)
		{
			_selectionInspectorViewController=[PKGFilesSelectionInspectorViewController new];
			_selectionInspectorViewController.delegate=_filesHierarchyViewController;
		}
		
		if (_currentInspectorViewController!=_selectionInspectorViewController)
		{
			[_currentInspectorViewController WB_viewWillDisappear];
			
			[_currentInspectorViewController.view removeFromSuperview];
			
			[_currentInspectorViewController WB_viewDidDisappear];

			
			_currentInspectorViewController=_selectionInspectorViewController;
			
			_currentInspectorViewController.view.frame=_inspectorPlaceHolderView.bounds;
			
			[_currentInspectorViewController WB_viewWillAppear];
			
			[_inspectorPlaceHolderView addSubview:_currentInspectorViewController.view];
			
			[_currentInspectorViewController WB_viewDidAppear];
		}
		
		_selectionInspectorViewController.selectedItems=[tOutlineView WB_selectedItems];
	}
	
	// Default Destination
	
	if (tNumberOfSelectedRows!=1)
	{
		[_defaultDestinationSetButton setEnabled:NO];
		return;
	}
	
	PKGPayloadTreeNode * tSelectedTreeNode=[tOutlineView itemAtRow:tOutlineView.selectedRow];
	
	if (tSelectedTreeNode==_dataSource.installLocationNode)
	{
		[_defaultDestinationSetButton setEnabled:NO];
		return;
	}
	
	[_defaultDestinationSetButton setEnabled:[tSelectedTreeNode isSelectableAsInstallationLocation]];
		
	// A COMPLETER
}

- (void)fileHierarchyDidRenameFolder:(NSNotification *)inNotification
{
	NSOutlineView * tOutlineView=_filesHierarchyViewController.outlineView;
	
	if (inNotification.object!=tOutlineView)
		return;
	
	PKGPayloadTreeNode * tTreeNode=inNotification.userInfo[@"NSObject"];
	
	if (tTreeNode==_dataSource.installLocationNode)
	{
		self.payload.defaultInstallLocation=[_dataSource.installLocationNode filePath];
		_defaultDestinationLabel.stringValue=self.payload.defaultInstallLocation;
	}
}

- (void)advancedModeStateDidChange:(NSNotification *)inNotification
{
	[self _updateLayout];
}

@end

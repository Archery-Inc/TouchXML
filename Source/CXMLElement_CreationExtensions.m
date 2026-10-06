//
//  CXMLElement_CreationExtensions.m
//  TouchCode
//
//  Created by Jonathan Wight on 04/01/08.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//     1. Redistributions of source code must retain the above copyright notice, this list of
//        conditions and the following disclaimer.
//
//     2. Redistributions in binary form must reproduce the above copyright notice, this list
//        of conditions and the following disclaimer in the documentation and/or other materials
//        provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY TOXICSOFTWARE.COM ``AS IS'' AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL TOXICSOFTWARE.COM OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those of the
//  authors and should not be interpreted as representing official policies, either expressed
//  or implied, of toxicsoftware.com.

#import "CXMLElement_CreationExtensions.h"

#import "CXMLNode_PrivateExtensions.h"
#import "CXMLDocument_PrivateExtensions.h"

// Removes every cached Objective-C wrapper for the subtree rooted at inNode from inNodePool and clear the corresponding back-pointers.
static void CXMLElementEvictSubtreeNodePoolEntries(struct _xmlNode *inNode, NSMutableSet *inNodePool)
{
    for (struct _xmlNode *theCurrentNode = inNode; theCurrentNode != NULL; theCurrentNode = theCurrentNode->next)
    {
        if (theCurrentNode->_private != NULL)
        {
            [inNodePool removeObject:(__bridge id)theCurrentNode->_private];
            theCurrentNode->_private = NULL;
        }
        if (theCurrentNode->children != NULL)
        {
            CXMLElementEvictSubtreeNodePoolEntries(theCurrentNode->children, inNodePool);
        }
    }
}

@implementation CXMLElement (CXMLElement_CreationExtensions)

- (void)addChild:(CXMLNode *)inNode
{
NSAssert(inNode->_node->doc == NULL, @"Cannot addChild with a node that already is part of a document. Copy it first!");
NSAssert(self->_node != NULL, @"_node should not be null");
NSAssert(inNode->_node != NULL, @"_node should not be null");
xmlAddChild(self->_node, inNode->_node);
// now XML element is tracked by document, do not release on dealloc
inNode->_freeNodeOnRelease = NO;
}

- (CXMLNode *)removeChildAtIndex:(NSUInteger)index
{
    NSAssert(self->_node != NULL, @"_node should not be null");

    /* Find the child at the given index. */
    NSUInteger i = 0;
    struct _xmlNode *child = _node->children;
    while (i++ < index && child != NULL) {
        child = child->next;
    }
    if (child == NULL) {
        return nil;
    }

    // Reuse the wrapper cached for this node (if any) so that callers already
    // holding it keep a valid object and only one wrapper ever owns the node.
    CXMLNode *theWrapper = (__bridge CXMLNode *)child->_private;

    xmlDocPtr theDocumentNode = child->doc;
    xmlUnlinkNode(child);

    // Detach every cached wrapper for the removed subtree from its document so
    // the document no longer retains nodes it does not own.
    if (theDocumentNode != NULL) {
        CXMLDocument *theDocumentObject = (__bridge CXMLDocument *)theDocumentNode->_private;
        if (theDocumentObject != nil) {
            if (theWrapper != nil) {
                [theDocumentObject.nodePool removeObject:theWrapper];
            }
            CXMLElementEvictSubtreeNodePoolEntries(child->children, theDocumentObject.nodePool);
        }
    }

    // Transfer ownership of the unlinked subtree to the wrapper
    if (theWrapper == nil) {
        Class theClass = [CXMLNode nodeClassForLibXMLNode:child];
        theWrapper = [[theClass alloc] initWithLibXMLNode:child freeOnDealloc:YES];
        child->_private = (__bridge void *)theWrapper;
    }
    theWrapper->_freeNodeOnRelease = YES;

    return theWrapper;
}

- (void)addNamespace:(CXMLNode *)inNamespace
{
xmlSetNs(self->_node, (xmlNsPtr)inNamespace->_node);
}

- (void)setStringValue:(NSString *)inStringValue
{
NSAssert(inStringValue != NULL, @"CXMLElement setStringValue should not be null");
xmlNodePtr theContentNode = xmlNewText((const xmlChar *)[inStringValue UTF8String]);
NSAssert(self->_node != NULL, @"_node should not be null");
xmlAddChild(self->_node, theContentNode);
}

@end

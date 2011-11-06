//
//  ISUpload.m
//  Imageshack
//
//  Created by Dan Ponte on 9/1/09.
//  Copyright (c) 2009 __MyCompanyName__, All Rights Reserved.
//

#import "ISUpload.h"
#include <curl/curl.h>
#include <curl/types.h>
#include <curl/easy.h>
//#import <CURLHandle/CURLHandle.h>
//#import <CURLHandle/CURLHandle+extras.h>
#define MYKEY "DIMPQVXY37aab067282b4cd446b1e05fd17bc2de"


@implementation ISUpload

struct SvrResponse {
	char *strg;
	size_t size;
};

size_t WriteMemCB(void *ptr, size_t size, size_t nmemb, void *data)
{
	size_t realsize = size * nmemb;
	struct SvrResponse *mem = (struct SvrResponse *)data;
	mem->strg = realloc(mem->strg, mem->size + realsize + 1);
	if(mem->strg) {
		memcpy(&(mem->strg[mem->size]), ptr, realsize);
		mem->size += realsize;
		mem->strg[mem->size] = 0;
	}
	return realsize;
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
	//the parser started this document. what are you going to do?
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict {
	if ([elementName isEqualToString: @"image_link"])
		gimglink = YES;
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	if ([elementName isEqualToString: @"image_link"])
		gimglink = NO;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if (gimglink) {
		imglink = [NSURL URLWithString: string];
	}
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
	//the parser finished. what are you going to do?
}

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo
{
	NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:[input count]];
	NSEnumerator *enumerate = [input objectEnumerator];
	NSString *itu;
	CURL *curl;
	CURLcode res;
	NSString *ermsg = nil;
	
	curl_global_init(CURL_GLOBAL_ALL);
	
	imglink = nil;
	
	while (itu = [enumerate nextObject]) {
		struct curl_httppost *formpost = nil;
		struct curl_httppost *lastptr = nil;
		struct curl_slist *headerlist = nil;
		static const char buf[] = "Expect:";
		struct SvrResponse chnk;
		NSXMLParser *xp;
		NSData *xmldoc;
		

		chnk.strg = nil;
		chnk.size = 0;
		
		curl_formadd(&formpost, &lastptr, CURLFORM_COPYNAME, "fileupload", CURLFORM_FILE,
					 [itu cStringUsingEncoding: NSNonLossyASCIIStringEncoding], CURLFORM_END);
		curl_formadd(&formpost, &lastptr, CURLFORM_COPYNAME, "xml", CURLFORM_COPYCONTENTS, "yes",
					 CURLFORM_END);
		curl_formadd(&formpost, &lastptr, CURLFORM_COPYNAME, "key", CURLFORM_COPYCONTENTS, MYKEY,
					 CURLFORM_END);
		if ([[[self parameters] objectForKey:@"loginCheck"] boolValue] == YES) {
			curl_formadd(&formpost, &lastptr, CURLFORM_COPYNAME, "a_username", CURLFORM_COPYCONTENTS,
						 [[[self parameters] objectForKey:@"usernameField"] cStringUsingEncoding:NSNonLossyASCIIStringEncoding], CURLFORM_END);
			curl_formadd(&formpost, &lastptr, CURLFORM_COPYNAME, "a_password", CURLFORM_COPYCONTENTS,
						 [[[self parameters] objectForKey:@"passField"] cStringUsingEncoding:NSNonLossyASCIIStringEncoding], CURLFORM_END);
		}
		curl = curl_easy_init();
		headerlist = curl_slist_append(headerlist, buf);
		if (curl) {
			char *erbuf = malloc(CURL_ERROR_SIZE);
			curl_easy_setopt(curl, CURLOPT_ERRORBUFFER, erbuf);
			curl_easy_setopt(curl, CURLOPT_URL, "http://www.imageshack.us/index.php");
			curl_easy_setopt(curl, CURLOPT_HTTPPOST, formpost);
			curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteMemCB);
			curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&chnk);
			res = curl_easy_perform(curl);
			if (res != 0) {
				ermsg = [NSString stringWithCString:erbuf encoding:NSNonLossyASCIIStringEncoding];
			}
			// XXX: add error handling here! popup a box or something
			curl_easy_cleanup(curl);
			curl_formfree(formpost);
			curl_slist_free_all(headerlist);
			free(erbuf);
		}
		
		if (ermsg != nil) {
			NSArray *objsArray = [NSArray arrayWithObjects:
								  [NSNumber numberWithInt:errOSASystemError],
								  ermsg, nil];
			NSArray *keysArray = [NSArray arrayWithObjects:OSAScriptErrorNumber,
								  OSAScriptErrorMessage, nil];
			*errorInfo = [NSDictionary dictionaryWithObjects:objsArray forKeys:keysArray];
			imglink = nil;
			[ermsg autorelease];
		} else {
			xmldoc = [[NSData alloc] initWithBytes:chnk.strg length:chnk.size];
		
			xp = [[NSXMLParser alloc] initWithData:xmldoc];
			[xp setDelegate:self];
			[xp parse];
			[xp autorelease];
			[xmldoc autorelease];
		}
		// XXX: free imglink
		if (chnk.strg)
			free(chnk.strg);
		if (imglink == nil) {
			// XXX: raise some error condition
			curl_global_cleanup();
			
			return nil;
		} else {
			[returnArray addObject: imglink];
			[imglink autorelease];
		}
		imglink = nil;
	}
	
	curl_global_cleanup();
	
	[ermsg autorelease]; // XXX: we will actually use it someday
	return returnArray;
}

@end

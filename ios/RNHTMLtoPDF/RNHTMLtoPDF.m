
//  Created by Christopher on 9/3/15.

#import <UIKit/UIKit.h>
#import <React/RCTConvert.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTView.h>
#import <React/UIView+React.h>
#import <React/RCTUtils.h>
#import "RNHTMLtoPDF.h"

typedef struct PageStruct{
    const char * const key;
    int height;
    int width;
} PageStruct;


// http://www.printernational.org/iso-paper-sizes.php
// http://www.printernational.org/american-paper-sizes.php
//
//    A0    841 mm x 1189 mm    33 in x 46.81 in    2384 pt x 3370 pt
//    A1    594 mm x 841 mm    23.39 in x 33 in    1684 pt x 2384 pt
//    A2    420 mm x 594 mm    16.54 in x 23.36 in    1191 pt x 1684 pt
//    A3    297 mm x 420 mm    11.69 in x 16.54 in    842 pt x 1191 pt
//    A4    210 mm 297 mm    8.27 in x 11.69 in    595 pt x 842 pt
//    A5    148 mm x 210 mm    5.83 in x 8.27 in    420 pt x 595 pt
//    A6    105 mm x 148 mm    4.13 in x 5.83 in    298 pt x 420 pt
//    A7    74 mm x 105 mm    2.91 in x 4.13 in    210 pt x 298 pt
//    A8    52 mm x 74 mm    2.05 in x 2.91 in    147 pt x 210 pt
//    A9    37 mm x 52 mm    1.46 in x 2.05 in    105 pt x 147 pt
//    A10    26 mm x 37 mm    1.02 in x 1.46 in    74 pt x 105 pt
//
//    ANSI-A (Letter)     792 pt x 612 pt
//    US Government    279 mm x 203 mm    11 in x 8 in    792 pt x 575 pt
//    Legal (Legal-2)    356 mm x 216 mm    14 in x 8.5 in    1008 pt x 612 pt
//
const PageStruct pageTableLookup[] = {
    { "A0", 2384, 3370, },
    { "A1", 1684, 2384, },
    { "A2", 1191, 1684, },
    { "A3", 842, 1191, },
    { "A4", 595, 842, },
    { "A5", 420, 595, },
    { "A6", 298, 420, },
    { "A7", 210, 298, },
    { "A8", 147, 210, },
    { "A9", 105, 147, },
    { "A10", 74, 105, },
    { "UsLetter", 792, 612, },   // <- Default to US Letter
    { "UsGovernmentLetter", 792, 575, },
    { "Legal", 1008, 612, }
};

const int PageStructIndexA4 = 4;
const int PageStructIndexUsLetter = 11;

// Google search returns more hits for "US Letter" than "A4"
// Portrait is more common than landscape
NSString *const PageDefaultSize = @"UsLetter";
NSString *const PageDefaultOrientation = @"Portrait";

@implementation UIPrintPageRenderer (PDF)
- (NSData*) printToPDF
{
    NSMutableData *pdfData = [NSMutableData data];
    UIGraphicsBeginPDFContextToData( pdfData, self.paperRect, nil );

    [self prepareForDrawingPages: NSMakeRange(0, self.numberOfPages)];

    CGRect bounds = UIGraphicsGetPDFContextBounds();

    for ( int i = 0 ; i < self.numberOfPages ; i++ )
    {
        UIGraphicsBeginPDFPage();
        [self drawPageAtIndex: i inRect: bounds];
    }

    UIGraphicsEndPDFContext();
    return pdfData;
}
@end

@implementation RnHtmlToPdf {
    RCTEventDispatcher *_eventDispatcher;
    RCTPromiseResolveBlock _resolveBlock;
    RCTPromiseRejectBlock _rejectBlock;
    NSString *_html;
    NSString *_fileName;
    NSString *_filePath;
    CGSize _PDFSize;
    UIWebView *_webView;
    float _padding;
    BOOL _base64;
    BOOL autoHeight;
}

RCT_EXPORT_MODULE();

@synthesize bridge = _bridge;

// Is this the correct approach?
//
// Returning methodQueue dispatch_get_main_queue fixed concurrency issue with TCMWSessionController writeDataInternal
//
- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

- (instancetype)init
{
    if (self = [super init]) {
        _webView = [[UIWebView alloc] initWithFrame:self.bounds];
        _webView.delegate = self;
        [self addSubview:_webView];
        autoHeight = false;
    }
    return self;
}

RCT_EXPORT_METHOD(convert:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {

    if (options[@"html"]){
        _html = [RCTConvert NSString:options[@"html"]];
    }

    if (options[@"fileName"]){
        _fileName = [RCTConvert NSString:options[@"fileName"]];
    } else {
        _fileName = [[NSProcessInfo processInfo] globallyUniqueString];
    }

    if (options[@"directory"] && [options[@"directory"] isEqualToString:@"docs"]){
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];

        _filePath = [NSString stringWithFormat:@"%@/%@.pdf", documentsPath, _fileName];
    } else {
        _filePath = [NSString stringWithFormat:@"%@%@.pdf", NSTemporaryDirectory(), _fileName];
    }

    if (options[@"base64"] && [options[@"base64"] boolValue]) {
        _base64 = true;   
    } else {
        _base64 = false;   
    }
    
    if (options[@"height"] && options[@"width"]) {
        float width = [RCTConvert float:options[@"width"]];
        float height = [RCTConvert float:options[@"height"]];
        _PDFSize = CGSizeMake(width, height);
    } else {
        _PDFSize = [self getMediaSize:options];
    }

    if (options[@"padding"]) {
        _padding = [RCTConvert float:options[@"padding"]];
    } else {
        _padding = 10.0f;
    }

    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];

    [_webView loadHTMLString:_html baseURL:baseURL];

    _resolveBlock = resolve;
    _rejectBlock = reject;

}

- (void)webViewDidFinishLoad:(UIWebView *)awebView
{
    if (awebView.isLoading)
        return;

    UIPrintPageRenderer *render = [[UIPrintPageRenderer alloc] init];
    [render addPrintFormatter:awebView.viewPrintFormatter startingAtPageAtIndex:0];

    // Define the printableRect and paperRect
    // If the printableRect defines the printable area of the page
    CGRect paperRect = CGRectMake(0, 0, _PDFSize.width, _PDFSize.height);
    CGRect printableRect = CGRectMake(_padding, _padding, _PDFSize.width-(_padding * 2), _PDFSize.height-(_padding * 2));

    [render setValue:[NSValue valueWithCGRect:paperRect] forKey:@"paperRect"];
    [render setValue:[NSValue valueWithCGRect:printableRect] forKey:@"printableRect"];

    NSData *pdfData = [render printToPDF];

    if (pdfData) {
        NSString *pdfBase64 = @"";
        
        [pdfData writeToFile:_filePath atomically:YES];
        if (_base64) {
            pdfBase64 = [pdfData base64EncodedStringWithOptions:0];   
        }
        NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                             pdfBase64, @"base64",
                             _filePath, @"filePath", nil];
        _resolveBlock(data);
    } else {
        NSError *error;
        _rejectBlock(RCTErrorUnspecified, nil, RCTErrorWithMessage(error.description));
    }
}

- (CGSize) getMediaSize:(NSDictionary *)options {
    PageStruct pageStruct = pageTableLookup[PageStructIndexUsLetter];
    NSString* pageSize = PageDefaultSize;
    NSString* pageOrientation = PageDefaultOrientation;
    if (options[@"page"]) {
        NSDictionary * optionsPage = [RCTConvert NSDictionary:options[@"page"]];
        pageOrientation = optionsPage[@"orientation"] ? [RCTConvert NSString:optionsPage[@"orientation"]] : pageOrientation;
        if (optionsPage[@"size"]) {
            NSDictionary * optionsPageSize = [RCTConvert NSDictionary:optionsPage[@"size"]];
            pageSize = optionsPageSize[@"id"] ? [RCTConvert NSString:optionsPageSize[@"id"]] : pageSize;
        }
    }
    for (int i = 0; i < (sizeof(pageTableLookup) / sizeof(PageStruct)); ++i) {
        PageStruct pg = pageTableLookup[i];
        if (strcmp(pg.key, pageSize.UTF8String) == 0) {
            pageStruct = pg;
            break;
        }
    }
    if ([pageOrientation isEqualToString:@"Landscape"]) {
        return CGSizeMake(pageStruct.height, pageStruct.width);
    }
    return CGSizeMake(pageStruct.width, pageStruct.height);
}

@end

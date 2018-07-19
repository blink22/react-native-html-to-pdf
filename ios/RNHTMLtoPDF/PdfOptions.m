#import <React/RCTConvert.h>

#import "PdfOptions.h"
 
@implementation PdfOptions

// 1 millimeter [mm] = 2.83464566929134 point
const double MillimeterToPoints = 2.83464566929134;

-(void)parseOptions:(NSDictionary *)options {
    if (!options[@"page"]){
        return;
    }
    NSDictionary * page = [RCTConvert NSDictionary:options[@"page"]];
    self.pageOrientation = page[@"orientation"] ? [RCTConvert NSString:page[@"orientation"]] : self.pageOrientation;
    if (!page[@"size"]){
        return;
    }
    NSDictionary * pageSize = [RCTConvert NSDictionary:page[@"size"]];
    self.pageId = pageSize[@"id"] ? [RCTConvert NSString:pageSize[@"id"]] : self.pageId;
    if (!pageSize[@"mm"]){
        return;
    }    
    NSDictionary * pageSizeMm = [RCTConvert NSDictionary:pageSize[@"mm"]];
    self.pageSizeHeightMm = pageSizeMm[@"h"] ? [RCTConvert float:pageSizeMm[@"h"]] : self.pageSizeHeightMm;
    self.pageSizeWidthMm = pageSizeMm[@"w"] ? [RCTConvert float:pageSizeMm[@"w"]] : self.pageSizeWidthMm;
}


-(id)initWithOptions:(NSDictionary *)options {
     self = [super init];
     if (self) {
        self.pageOrientation = @"Portrait";
        self.pageId = @"";
        self.pageSizeHeightMm = 0;
        self.pageSizeWidthMm = 0;

        [self parseOptions:options];
     }
     return self;
}

// UsLetter: { id: 'UsLetter', mm: { w: 279, h: 216 }},
- (CGSize) getMediaSize {
    // ANSI-A (Letter)    279 mm x 216 mm    11 in x 8.5 in    792 pt x 612 pt
    double widthPoints = MillimeterToPoints * self.pageSizeHeightMm;
    double heightPonts = MillimeterToPoints * self.pageSizeHeightMm;
    if ([pageOrientation caseInsensitiveCompare:@"Landscape"]) {
        return CGSizeMake(heightPonts, widthPoints);
    }
    return CGSizeMake(widthPoints, heightPonts);
}
 
@end


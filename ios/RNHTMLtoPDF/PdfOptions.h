

@interface PdfOptions : NSObject {

NSString *pageOrientation;
NSString *pageId;
double pageSizeHeightMm;
double pageSizeWidthMm;

}

-(id)initWithOptions:(NSDictionary *)options;
- (CGSize) getMediaSize;

@property NSString *pageOrientation;
@property NSString *pageId;
@property double pageSizeHeightMm;
@property double pageSizeWidthMm;

@end
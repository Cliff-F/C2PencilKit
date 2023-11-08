//
//  MNVerticalTextLabel.m
//  TuiFramework
//
//  Created by Masatoshi Nishikata on 16/10/12.
//
//

#import "PalletteTabVerticalTextLabel.h"
#import <UIKit/UIKit.h>

@implementation PalletteTabVerticalTextLabel

@synthesize selected, highlighted;
@synthesize attributedString = attributedString_;
@synthesize highlightedAttributedString = highlightedAttributedString_;
@synthesize contentWidth;
@synthesize onRight;
@synthesize inverted;
@synthesize alignCenter = alignCenter_;
@synthesize alignCenterInsideFrame = alignCenterInsideFrame_;
@synthesize hasShadow = hasShadow_;
@synthesize shadowOffset = shadowOffset_;
@synthesize shadowBlur = shadowBlur_;
@synthesize shadowColor = shadowColor_;

#define MARGIN 7

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        hasShadow_ = NO;
        shadowOffset_ = CGSizeMake(0,1);
        shadowBlur_ = 3.0;
        alignCenter_ = NO;
        alignCenterInsideFrame_ = NO;
        self.contentWidth = frame.size.width;
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;
        
        
    }
    return self;
}

-(void)setFrame:(CGRect)frame
{
    self.contentWidth = frame.size.width;
    [super setFrame:frame];
  [self setNeedsDisplay];

}

-(CTLineRef)line
{
    return line_;
}

-(void)setAttributedString:(NSAttributedString*)attributedString
{
    if( attributedString_ != attributedString )
    {
        attributedString_ = attributedString;
    }
    
    if( line_ )
    {
        CFRelease(line_);
        line_ = nil;
    }
    
    
    [self setNeedsDisplay];
}


//-(void)removeFromSuperview
//{
//
//    self.action = nil;
//
//
//    [super removeFromSuperview];
//}




-(void)dealloc
{
    attributedString_ = nil;
    
    if( line_ ) CFRelease(line_);
    
    //    self.action = nil;
    
    shadowColor_ = nil;
}

-(CGFloat)width
{
    
    if( !line_  )
    {
        line_ = CTLineCreateWithAttributedString((CFAttributedStringRef)attributedString_);
    }
    
    CGFloat width =  CTLineGetTypographicBounds(line_, nil, nil, nil);
    
    if( inverted ) width += 20;
    
    
    return width;
}

-(CGRect)textRect
{
    
    if( !line_  && attributedString_ )
    {
        line_ = CTLineCreateWithAttributedString((CFAttributedStringRef)attributedString_);
    }
    
    CGRect rect = self.bounds;
    CGRect contentRect;
    CGFloat descent;
    CGFloat ascent;
    CGFloat leading;
    CTLineGetTypographicBounds(line_, &ascent, &descent, &leading);
    
    CGFloat ty = roundf( (rect.size.height - descent - ascent)/2 +ascent ) +2;
    
    CGFloat width = CTLineGetTypographicBounds(line_, &ascent, &descent, &leading);
    CGFloat height = ascent;
    
    height += 10;
    contentRect = CGRectMake( (rect.size.width - width)/2, ty - height + 5, width, height);
    contentRect = CGRectIntegral(contentRect);
    
    return contentRect;
}



-(void)drawRect:(CGRect)rect
{
  if( !line_  && attributedString_ )
  {
    NSMutableAttributedString* mattr = (NSMutableAttributedString*)[attributedString_ mutableCopy];
    line_ = CTLineCreateWithAttributedString((CFAttributedStringRef)mattr);
    CGFloat width = CTLineGetTypographicBounds(line_, nil, nil, nil);
    
    if( rect.size.height < width + MARGIN && mattr.length > 2 ) {
      NSMutableDictionary *attributes = [[mattr attributesAtIndex:0 effectiveRange:nil] mutableCopy];
      UIFont* font = [attributes objectForKey: NSFontAttributeName];
      font = [UIFont fontWithName:font.fontName size:font.pointSize-2];
      
      attributes[NSFontAttributeName] = font;
      attributes[NSKernAttributeName] = @(-1);

      [mattr addAttributes:attributes range:NSMakeRange(0, mattr.length)];
      CFRelease(line_);
      line_ = CTLineCreateWithAttributedString((CFAttributedStringRef)mattr);
      width = CTLineGetTypographicBounds(line_, nil, nil, nil);
    }
    
    while( rect.size.height < width + MARGIN && mattr.length > 5 ) {
      NSDictionary *attributes = [mattr attributesAtIndex:mattr.length - 2 effectiveRange:nil];
      [mattr replaceCharactersInRange:NSMakeRange(mattr.length-4, 2) withString:@"︙"];
      [mattr addAttributes:attributes range:NSMakeRange(mattr.length - 2, 1)];
      CFRelease(line_);
      line_ = CTLineCreateWithAttributedString((CFAttributedStringRef)mattr);
      width = CTLineGetTypographicBounds(line_, nil, nil, nil);
    }
  }
  
  if( !attributedString_ || !line_ || attributedString_.length == 0 )
  {
    [super drawRect:rect];
    return;
  }
  
  CGFloat descent;
  CGFloat ascent;
  CGFloat leading;
  double width;
  
  width = CTLineGetTypographicBounds(line_, &ascent, &descent, &leading);
  
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGContextSaveGState(ctx);
  
  CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
  transform = CGAffineTransformTranslate(transform, 0,0);
  CGContextSetTextMatrix(ctx, transform);
  
  CGAffineTransform t;
  
  // Drawing left part
  if( self.alignedToLeft ) {
    t = CGAffineTransformMakeTranslation( rect.size.width - 22, MARGIN );

  }else {
    t = CGAffineTransformMakeTranslation( 12, MARGIN );
//    t = CGAffineTransformMakeTranslation( rect.size.width/2-7, MARGIN );
  }
  CGContextConcatCTM(ctx, t);
  
  NSArray* runs = (NSArray*)CTLineGetGlyphRuns(line_);
  for( id run in runs )
  {
    CTRunDraw((CTRunRef)run, ctx, CFRangeMake(0, 0));
  }
  
  CGContextRestoreGState(ctx);
}

@end

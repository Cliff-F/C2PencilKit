#import "MyAttributedTextLabel.h"

@implementation  MyAttributedTextLabel

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
}

-(CTLineRef)line
{
	return line_;
}

-(void)setAttributedString:(NSAttributedString*)attributedString
{
	if( attributedString_ != attributedString )
	{
		[attributedString_ release];
		attributedString_ = [attributedString retain];
	}
	
	if( line_ )
	{
		CFRelease(line_);
		line_ = nil;
	}
	
	
	[self setNeedsDisplay];
}

-(void)setHighlightedAttributedString:(NSAttributedString*)attributedString
{
	if( highlightedAttributedString_ != attributedString )
	{
		[highlightedAttributedString_ release];
		highlightedAttributedString_ = [attributedString retain];
	}
	
	[self setNeedsDisplay];
}


//-(void)removeFromSuperview
//{
//
//	self.action = nil;
//
//
//	[super removeFromSuperview];
//}




-(void)dealloc
{

	[attributedString_ release];
	attributedString_ = nil;
	
	[highlightedAttributedString_ release];
	highlightedAttributedString_ = nil;
	
	if( line_ ) CFRelease(line_);
	
	//	self.action = nil;
	
	[shadowColor_ release];
	shadowColor_ = nil;
	
	[super dealloc];
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
		line_ = CTLineCreateWithAttributedString((CFAttributedStringRef)attributedString_);
	}
	
	
	if( !attributedString_ || !line_ || attributedString_.length == 0 )
	{
		[super drawRect:rect];
		return;
	}
	
	
	
	CGFloat descent;
	CGFloat ascent;
	CGFloat leading;
	CTLineGetTypographicBounds(line_, &ascent, &descent, &leading);
	
	
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGFloat ty = roundf( (rect.size.height - descent - ascent)/2 +ascent ) +2;

	
	if( inverted )
	{
		CGRect contentRect;
		
		CGFloat ascent, descent, leading;
		CGFloat width = CTLineGetTypographicBounds(line_, &ascent, &descent, &leading);
		CGFloat height = ascent;
		
		height += 10;
		contentRect = CGRectMake( rect.size.width - width - 20, ty - height + 5, width + 20, height);
		contentRect = CGRectIntegral(contentRect);
		

		
		CGContextSetFillColorWithColor(ctx, [UIColor lightGrayColor].CGColor);
		CGContextFillPath(ctx);
	}
	
	
	
	CGContextSaveGState(ctx);
	
	CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
	transform = CGAffineTransformTranslate(transform, 0,0);
	CGContextSetTextMatrix(ctx, transform);
	
	
	
	CGAffineTransform t;
	BOOL rightToLeft = NO;

	if( onRight )
	{
		// drawing detail view
		
		if( inverted )
		{
			BOOL isIOS7 = !( [[[UIDevice currentDevice] systemVersion] hasPrefix:@"6"] || [[[UIDevice currentDevice] systemVersion] hasPrefix:@"5"]  );

			// Drawing folder count
			t = CGAffineTransformMakeTranslation( roundf( rect.size.width - [self width] ) + 10, ty );
			
			if( isIOS7 )
			{
				t = CGAffineTransformMakeTranslation( roundf( rect.size.width - [self width] ) + 10, ty );

			}
			else
			{
				t = CGAffineTransformMakeTranslation( roundf( rect.size.width - [self width] ) + 10, ty );

			}
				
		}
		else
		{
			CGFloat tx = rect.size.width - [self width];
			
			
			if( alignCenter_ )
			{
				CGPoint superCenter = CGPointMake( self.superview.bounds.size.width/2, 0);
				CGPoint superCenterInMe = [self.superview convertPoint:superCenter toView:self];
				CGFloat centerX = superCenterInMe.x;
				tx = rect.origin.x + centerX - [self width]/2;
				tx = fmaxf( 0, tx );
				tx = fminf( tx, CGRectGetMaxX(rect) - [self width] );
				
			}else if( alignCenterInsideFrame_ )
			{
				CGFloat centerX = self.bounds.size.width/2;
				tx = rect.origin.x + centerX - [self width]/2;
				tx = fmaxf( 0, tx );
				tx = fminf( tx, CGRectGetMaxX(rect) - [self width] );
			}
			
			
			
			t = CGAffineTransformMakeTranslation( roundf( tx ) , ty );
		}
	}
	else
	{
		uint8_t enumBuffer = 0;
		
		CTParagraphStyleRef paragraphStyle = (CTParagraphStyleRef)[attributedString_  attribute:(NSString*)kCTParagraphStyleAttributeName atIndex:0 effectiveRange:nil];
		if( paragraphStyle && CTParagraphStyleGetValueForSpecifier( paragraphStyle, kCTParagraphStyleSpecifierBaseWritingDirection, sizeof(uint8_t), &enumBuffer) )
		{
			if( enumBuffer == kCTWritingDirectionRightToLeft )
				rightToLeft = YES;
		}
		
		// Drawing left part
		
		if( rightToLeft )
		{
			t = CGAffineTransformMakeTranslation( roundf( rect.origin.x ) - [self width] + contentWidth, ty);
			
		}else
		{
			CGFloat tx = rect.origin.x;
			
			if( alignCenter_ )
			{
				CGPoint superCenter = CGPointMake( self.superview.bounds.size.width/2, 0);
				CGPoint superCenterInMe = [self.superview convertPoint:superCenter toView:self];
				CGFloat centerX = superCenterInMe.x;
				tx = rect.origin.x + centerX - [self width]/2;
				tx = fminf( tx, CGRectGetMaxX(rect) - [self width] );
				tx = fmaxf( 0, tx );
				
			}else if( alignCenterInsideFrame_ )
			{
				CGFloat centerX = self.bounds.size.width/2;
				tx = rect.origin.x + centerX - [self width]/2;
				tx = fmaxf( 0, tx );
				tx = fminf( tx, CGRectGetMaxX(rect) - [self width] );
			}
			
			t = CGAffineTransformMakeTranslation( roundf( tx ), ty);
		}
	}
	
	
	CGContextConcatCTM(ctx, t);
	
	if( hasShadow_ && !self.selected )
	{
		if( shadowBlur_ == 0 )
		{
			UIColor* color = shadowColor_;
			
			if( !color ) color = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
			
			CGContextSetShadowWithColor(
												 ctx,
												 shadowOffset_,
												 shadowBlur_,
												 color.CGColor
												 );
		}
		else
		{
			CGContextSetShadow (
									  ctx,
									  shadowOffset_,
									  shadowBlur_
									  );
			
		}
	}
	
	
	if( self.selected && highlightedAttributedString_ )
	{
		CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)highlightedAttributedString_);

		NSArray* runs = (NSArray*)CTLineGetGlyphRuns(line);
		for( id run in runs )
		{
      CTRunDraw((CTRunRef)run, ctx, CFRangeMake(0, 0));
		}
		
		if( line )
			CFRelease(line);
		
	}else
	{
	
	NSArray* runs = (NSArray*)CTLineGetGlyphRuns(line_);
	for( id run in runs )
	{
    CTRunDraw((CTRunRef)run, ctx, CFRangeMake(0, 0));
	}
	
	}
	
	
	CGContextRestoreGState(ctx);
	
	
	if( !onRight && [self width] > contentWidth )
	{
		if( !rightToLeft )
		{
      //[DrawUtils eraseEdgeFrom:CGPointMake(contentWidth-20, rect.origin.y) to:CGPointMake(contentWidth-5, rect.origin.y)];
		}else {
      //[DrawUtils eraseEdgeFrom:CGPointMake(15, rect.origin.y) to:CGPointMake(0, rect.origin.y)];
			
		}
		
	}
}


/*
 
 -(void)setSelected:(BOOL)flag
 {
 [super setSelected:flag];
 [self setNeedsDisplay];
 }
 
 -(void)setHighlighted:(BOOL)flag
 {
 [super setHighlighted:flag];
 [self setNeedsDisplay];
 }
 
 
 - (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
 {
 
 return YES;
 }
 
 - (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event;
 {
 
 return YES;
 }
 
 
 - (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
 {
 CGPoint location = [touch locationInView:self];
 
 if( CGRectContainsPoint(self.bounds, location) )
 {
 if( action )
 action();
 }
 
 
 }
 
 - (void)cancelTrackingWithEvent:(UIEvent *)event
 {
 
 
 }
 */


@end

//
//  MNAttributedTextLabel.h
//  FastFinga3
//
//  Created by Masatoshi Nishikata on 6/04/11.
//  Copyright 2011 Catalystwo Limited. All rights reserved.
//

#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface MyAttributedTextLabel : UIView
{
	NSAttributedString * attributedString_;
	NSAttributedString * highlightedAttributedString_;

	BOOL selected;
	BOOL highlighted;
	CGFloat contentWidth;
	CTLineRef line_;
	
	//	void (^action)(void);
	
	// Attributes
	BOOL alignCenter_; // Align center in superview 
	BOOL alignCenterInsideFrame_; // Align center of itself
	BOOL hasShadow_;
	UIColor* shadowColor_;
	CGSize shadowOffset_;
	CGFloat shadowBlur_;
	BOOL onRight;
	BOOL inverted; // Folder
}

-(void)setAttributedString:(NSAttributedString*)attributedString;
-(void)dealloc;
-(CGFloat)width;
-(void)drawRect:(CGRect)rect;
-(CTLineRef)line;
-(CGRect)textRect;


@property (nonatomic, retain) NSAttributedString * attributedString;
@property (nonatomic, retain) NSAttributedString * highlightedAttributedString;

@property (nonatomic) 	BOOL selected;
@property (nonatomic) 	BOOL highlighted;
@property (nonatomic) 	CGFloat contentWidth; 
@property (nonatomic) 	BOOL onRight; 
@property (nonatomic) 	BOOL inverted; 
@property (nonatomic) 	BOOL alignCenter;
@property (nonatomic) 	BOOL alignCenterInsideFrame;
@property (nonatomic) BOOL hasShadow;
@property (nonatomic) CGSize shadowOffset;
@property (nonatomic) CGFloat shadowBlur;
@property (nonatomic, retain) UIColor* shadowColor;
//@property (nonatomic, copy) 	void (^action)(void);

@end


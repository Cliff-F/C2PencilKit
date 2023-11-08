//
//  MNVerticalTextLabel.h
//  TuiFramework
//
//  Created by Masatoshi Nishikata on 16/10/12.
//
//

#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>

@interface PalletteTabVerticalTextLabel : UIView
{
    NSAttributedString * attributedString_;
    
    BOOL selected;
    BOOL highlighted;
    CGFloat contentWidth;
    CTLineRef line_;
    
    //    void (^action)(void);
    
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

@property (nonatomic, strong) NSString* backgroundScheme;

@property (nonatomic, retain) NSAttributedString * attributedString;
@property (nonatomic, retain) NSAttributedString * highlightedAttributedString;

@property (nonatomic)     BOOL selected;
@property (nonatomic)     BOOL highlighted;
@property (nonatomic)     CGFloat contentWidth;
@property (nonatomic)     BOOL onRight;
@property (nonatomic)     BOOL inverted;
@property (nonatomic)     BOOL alignCenter;
@property (nonatomic)     BOOL alignCenterInsideFrame;
@property (nonatomic) BOOL hasShadow;
@property (nonatomic) CGSize shadowOffset;
@property (nonatomic) CGFloat shadowBlur;
@property (nonatomic, retain) UIColor* shadowColor;
//@property (nonatomic, copy)     void (^action)(void);

@property (nonatomic) BOOL alignedToLeft;

@end


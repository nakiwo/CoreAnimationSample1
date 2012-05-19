//
//  ViewController.m
//  casample
//
//  Created by Yuichi Fujishige on 12/03/17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

//#define USE_UIVIEW

@interface ViewController ()

@end

@implementation ViewController
{
#if defined (USE_UIVIEW)
    UIView *_testView;
#endif
    CALayer *_testLayer;
    CGPoint _startPoint;
    CGPoint _endPoint;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - 

- (IBAction)reset:(id)sender
{
    CGRect frame = CGRectMake(30, 0, 100, 100);

#if !defined (USE_UIVIEW)
    if(_testLayer) {
        [_testLayer removeFromSuperlayer];
        _testLayer = nil;
    }
    
    _testLayer = [CALayer layer];
    _testLayer.frame = frame;
    _testLayer.backgroundColor = [UIColor redColor].CGColor;
    
    [self.view.layer addSublayer:_testLayer];
#else
    if(_testView) {
        [_testView removeFromSuperview];
        _testView = nil;
    }

    _testView = [[UIView alloc] initWithFrame:frame];
    _testView.backgroundColor = [UIColor greenColor];
    [self.view addSubview:_testView];

    _testLayer = _testView.layer;
#endif

    _startPoint = _testLayer.position;
    _endPoint = CGPointMake(_startPoint.x, _startPoint.y + 300);
}

- (void)showAnimations
{
#if !defined (USE_UIVIEW)
    NSLog(@"[layer] model frame:(%@)", NSStringFromCGRect(_testLayer.frame));
#else
    NSLog(@"[view.layer] model frame:(%@)", NSStringFromCGRect(_testLayer.frame));
    NSLog(@"[view.layer.presentationLayer] model frame:(%@)", NSStringFromCGRect(((CALayer *)_testLayer.presentationLayer).frame));
    NSLog(@"[view] frame:(%@)", NSStringFromCGRect(_testView.frame));
#endif
    NSLog(@"animations -- ");
    if([[_testLayer animationKeys] count]) {
        [[_testLayer animationKeys] enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
            NSLog(@"  %@ > %@", key, [_testLayer animationForKey:key]);
        }];
    } else {
        NSLog(@"  ** empty **");
    }
}

- (IBAction)check:(id)sender
{
    [self showAnimations];
}

#pragma mark - 

- (IBAction)implicit1:(id)sender
{
    // デフォルトのトランザクション内で
    // 暗黙的アニメーション(デフォルトアクション)により、
    // "position"キーのアニメーションが追加される
    _testLayer.position = _endPoint;

    [self showAnimations];  // 追加されたアニメーションがある事がわかる
}

- (IBAction)implicit2:(id)sender
{
    [CATransaction begin];
    [CATransaction setAnimationDuration:2];

    _testLayer.position = _endPoint;

    [CATransaction commit];

    [self showAnimations];  // 追加されたアニメーションがある事がわかる
}

- (IBAction)explicit1:(id)sender
{
    // explicitアニメーション追加だけ行うと
    // モデルが更新されずにアニメーション終了後表示が戻る
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position"];
    anim.fromValue = [NSValue valueWithCGPoint:_startPoint];
    anim.toValue = [NSValue valueWithCGPoint:_endPoint];
    anim.duration = 0.5;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

    [_testLayer addAnimation:anim forKey:@"hoge"];  // 適当な名前のキーで追加
    [self showAnimations];
}

- (IBAction)explicit2:(id)sender
{
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position"];
    anim.fromValue = [NSValue valueWithCGPoint:_startPoint];
    anim.toValue = [NSValue valueWithCGPoint:_endPoint];
    anim.duration = 0.5;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    anim.removedOnCompletion = NO;          // アニメーションが終了しても自動削除しない
    anim.fillMode = kCAFillModeForwards;    // 終了後はtoValueをキープ
    
    [_testLayer addAnimation:anim forKey:@"hoge"];  // 適当な名前のキーで追加
    [self showAnimations];

    // animetion終了後、checkボタンを押すとhogeが残っている事がわかる。(気持ち悪い)
    // implicitアニメーションの時は残らない。
    // 多数のlayerやpropertyをこの方法で処理すると、
    // 張り付いて残っているanimationが多数になり無駄が多くなる
}

- (IBAction)explicit3:(id)sender
{
    [CATransaction begin];  // 暗黙トランザクションのdurationを長めに設定(確認用)
    [CATransaction setAnimationDuration:4];
    NSLog(@"current transaction animationDuration : %f", [CATransaction animationDuration]);

    // animations追加
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position"];
    anim.fromValue = [NSValue valueWithCGPoint:_startPoint];
    anim.toValue = [NSValue valueWithCGPoint:_endPoint];
    anim.duration = 0.3;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

    // モデルの値も更新しておく
    // しかしこの方法だとimplicitアニメーションも同時に走ってしまう!
    // 同じkeyPathに対するアニメーションが2つ以上ある場合、どちらが勝つかは不定? 登録された順番により結果が異なる様子

    _testLayer.position = _endPoint;    // ここで暗黙アニメーション発動
    [self showAnimations]; // positionアニメーションが登録されている事がわかる
    
    [_testLayer addAnimation:anim forKey:@"hoge"];  // 適当な名前のキーで追加
    
    [self showAnimations]; // hoge/positionの2アニメーションが登録されている事がわかる

    [CATransaction commit];

    // note: UIVIew.layerに対しての処理の場合、元々Actionが無効なのでこのやり方でもうまく行く
}

- (IBAction)explicit4:(id)sender
{ 
    [CATransaction begin];  // 暗黙トランザクションのdurationを長めに設定(explicit3との対比確認のため)
    [CATransaction setAnimationDuration:4];
    NSLog(@"current transaction animationDuration : %f", [CATransaction animationDuration]);

    // animations追加
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position"];
    anim.fromValue = [NSValue valueWithCGPoint:_startPoint];
    anim.toValue = [NSValue valueWithCGPoint:_endPoint];
    anim.duration = 1;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    // おすすめ解決策その1
    // モデルの値も更新しておく。
    _testLayer.position = _endPoint;    // デフォルトアクションが発動
    [self showAnimations]; // positionのみ(デフォルトアクション)

    // アニメーションを登録する際、元のプロパティ名をキーとして使用する
    // 同じキーのアニメーションは1つしか登録出来ない。同じ名前があると上書きされる。
    // implicitアニメーションのアニメーションと同じキーで上書き
    [_testLayer addAnimation:anim forKey:@"position"];
    [self showAnimations]; // positionのみ(アプリが指定したインスタンス)

    [CATransaction commit];
}

- (IBAction)explicit5:(id)sender
{ 
    // animations追加
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position"];
    anim.fromValue = [NSValue valueWithCGPoint:_startPoint];
    anim.toValue = [NSValue valueWithCGPoint:_endPoint];
    anim.duration = 0.5;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    // おすすめ解決策その2
    // モデルの値も更新しておく
    // デフォルトアクション(=implicitアニメーション)が走らないように設定
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _testLayer.position = _endPoint;    // Layerアクションが無効になっているのでアニメーションは発動しない
    [CATransaction commit];
    
    [self showAnimations]; // アニメーション無し
    
    [_testLayer addAnimation:anim forKey:@"hoge"];  // 適当な名前のキーで追加
    [self showAnimations]; // hogeしか無い
}

// 暗黙アニメーションが有効な状態でActionを書き換える、という手もある。

@end

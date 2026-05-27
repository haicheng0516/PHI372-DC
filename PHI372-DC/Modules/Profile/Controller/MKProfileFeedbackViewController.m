//
//  MKProfileFeedbackViewController.m
//  PHI372-DC — Figma 3:1220 个人中心-问题反馈
//
//  布局精确还原 (375×812):
//    顶部品牌绿 nav (#385330 r=0,0,14,14) 标题 "Feedback"
//    Hint banner (18,110) 339×91 灰底 + 4 行文案
//    "Your question" (36,228) 14pt 600 #171718
//    多行输入 (36,260) 303×185 白底 r=14 占位 "Please enter" 字数 1/1000
//    "Upload pictures" (36,465) 14pt 600
//    3 格上传位 (横向, 94×93, gap ~10, r=14, 描边)
//    底部 Submit 按钮 (36, bottom) 303×56 r=28 #385330
//

#import "MKProfileFeedbackViewController.h"
#import "MKConstants.h"
#import "MKHintBannerView.h"
#import "MKNetworkManager.h"
#import "MKEncryptManager.h"
#import "MKLoginManager.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <Masonry/Masonry.h>

@interface MKProfileFeedbackViewController () <UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UILabel *counterLabel;
@property (nonatomic, strong) NSMutableArray *slotImages;          // UIImage 或 NSNull,固定 3 格
@property (nonatomic, strong) NSMutableArray<UIControl *> *slotViews;
@property (nonatomic, strong) NSMutableArray<UIImageView *> *slotImageViews;
@property (nonatomic, strong) NSMutableArray<UIView *> *slotEmptyOverlays;  // 空态: plus + "Upload pictures"
@property (nonatomic, strong) NSMutableArray<UIButton *> *slotDeleteButtons;
@property (nonatomic, assign) NSInteger editingSlotIndex;
@property (nonatomic, strong) NSMutableArray<NSString *> *uploadedImageURLs;
@end

@implementation MKProfileFeedbackViewController

- (instancetype)init {
    if (self = [super init]) {
        self.navBarStyle = MKNavBarStylePrimaryDark;
        self.navTitle = @"Feedback";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = kColorBackground;

    self.slotImages = [@[[NSNull null], [NSNull null], [NSNull null]] mutableCopy];
    self.slotViews = [NSMutableArray array];
    self.slotImageViews = [NSMutableArray array];
    self.slotEmptyOverlays = [NSMutableArray array];
    self.slotDeleteButtons = [NSMutableArray array];
    self.uploadedImageURLs = [NSMutableArray array];

    // 设计稿(Pencil uQM3c, 375×812)绝对坐标: y = nav底(=设计 y98) + kScaleH(pencilY-98)
    CGFloat navB = kNavBarHeight;

    // Hint banner — 设计稿 x18 y110 w339 (#E9E9E4 r14);高度按文案自适应,后续元素仍按固定 Y
    NSString *hintText = @"You can describe the problem you encounter in detail on this page, or send your problem to our email, leave your contact information, and we will contact you as soon as possible!";
    CGFloat hintH = [MKHintBannerView heightForText:hintText];
    MKHintBannerView *hint = [[MKHintBannerView alloc] initWithText:hintText];
    hint.frame = CGRectMake(kScaleW(18), navB + kScaleH(12), kScaleW(339), hintH);
    [self.view addSubview:hint];

    // 表单大背景卡 — 设计稿 vkl25 x18 y211 w339 h510 (#E9E9E4 r14),垫在问题/输入框/上传/Submit 之下
    UIView *formCard = [[UIView alloc] initWithFrame:CGRectMake(kScaleW(18), navB + kScaleH(113), kScaleW(339), kScaleH(510))];
    formCard.backgroundColor = MKHexColor(0xE9E9E4);
    formCard.layer.cornerRadius = kScaleH(14);
    [self.view addSubview:formCard];

    // "Your question" — 设计稿 x36 y228 (#171718 14)
    UILabel *qlabel = [[UILabel alloc] initWithFrame:CGRectMake(kScaleW(36), navB + kScaleH(130), kScaleW(303), kScaleH(20))];
    qlabel.text = @"Your question";
    qlabel.font = kFontRegular(14);
    qlabel.textColor = MKHexColor(0x171718);
    [self.view addSubview:qlabel];

    // 多行输入 — 设计稿 x36 y260 w303 h185 (#F8F8F7 r14 + 外阴影 0 1 1.75 rgba(16,24,40,.05))
    CGFloat inputY = navB + kScaleH(162);
    self.textView = [UITextView new];
    self.textView.frame = CGRectMake(kScaleW(36), inputY, kScaleW(303), kScaleH(185));
    self.textView.backgroundColor = MKHexColor(0xF8F8F7);
    self.textView.layer.cornerRadius = kScaleH(14);
    self.textView.layer.shadowColor = MKHexColor(0x101828).CGColor;
    self.textView.layer.shadowOpacity = 0.05;
    self.textView.layer.shadowOffset = CGSizeMake(0, 1);
    self.textView.layer.shadowRadius = 1.75;
    self.textView.layer.masksToBounds = NO;
    self.textView.clipsToBounds = NO;
    self.textView.font = kFontRegular(14);
    self.textView.textColor = kColorTextPrimary;
    self.textView.textContainerInset = UIEdgeInsetsMake(kScaleH(14), kScaleW(14), kScaleH(28), kScaleW(14));
    self.textView.delegate = self;
    [self.view addSubview:self.textView];

    // Placeholder — 设计稿框内 x20 y17 → 绝对 x56 y277
    UILabel *placeholder = [UILabel new];
    placeholder.text = @"Please enter";
    placeholder.textColor = MKHexColor(0x666D80);
    placeholder.font = kFontRegular(14);
    placeholder.tag = 9100;
    placeholder.frame = CGRectMake(kScaleW(56), inputY + kScaleH(17), kScaleW(280), kScaleH(20));
    [self.view addSubview:placeholder];

    // 字数计数器 — 设计稿框内右下 (y260+149=409)
    self.counterLabel = [[UILabel alloc] initWithFrame:CGRectMake(kScaleW(36) + kScaleW(303) - kScaleW(80) - kScaleW(14),
                                                                    inputY + kScaleH(149),
                                                                    kScaleW(80), kScaleH(20))];
    self.counterLabel.text = @"0/1000";
    self.counterLabel.font = kFontRegular(12);
    self.counterLabel.textColor = MKHexColor(0x666D80);
    self.counterLabel.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:self.counterLabel];

    // "Upload pictures" — 设计稿 x36 y465
    UILabel *uplabel = [[UILabel alloc] initWithFrame:CGRectMake(kScaleW(36), navB + kScaleH(367), kScaleW(303), kScaleH(20))];
    uplabel.text = @"Upload pictures";
    uplabel.font = kFontRegular(14);
    uplabel.textColor = MKHexColor(0x171718);
    [self.view addSubview:uplabel];

    // 3 上传格 — 设计稿 y513, x 36/140/245 (94×93, gap 10/11)
    CGFloat slotY = navB + kScaleH(415);
    CGFloat slotW = kScaleW(94);
    CGFloat slotH = kScaleH(93);
    CGFloat gap = kScaleW(10.5);
    for (NSInteger i = 0; i < 3; i++) {
        UIControl *slot = [[UIControl alloc] initWithFrame:CGRectMake(kScaleW(36) + i * (slotW + gap), slotY, slotW, slotH)];
        slot.backgroundColor = MKHexColor(0xF8F8F7);
        slot.layer.cornerRadius = kScaleH(14);
        slot.layer.borderWidth = 1;
        slot.layer.borderColor = MKHexColor(0xBBCB2F).CGColor;  // 空态黄绿描边
        slot.clipsToBounds = YES;
        slot.tag = i;
        [slot addTarget:self action:@selector(slotTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:slot];
        [self.slotViews addObject:slot];

        // 选中图片后覆盖显示的缩略图(初始隐藏,置于底层)
        UIImageView *thumb = [[UIImageView alloc] initWithFrame:slot.bounds];
        thumb.contentMode = UIViewContentModeScaleAspectFill;
        thumb.clipsToBounds = YES;
        thumb.userInteractionEnabled = NO;
        thumb.hidden = YES;
        [slot addSubview:thumb];
        [self.slotImageViews addObject:thumb];

        // 空态层: 绿色 plus + "Upload pictures"
        UIView *empty = [[UIView alloc] initWithFrame:slot.bounds];
        empty.userInteractionEnabled = NO;
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightRegular];
        UIImageView *plus = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"plus" withConfiguration:cfg]
                                                                imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        plus.tintColor = kColorPrimary;  // #385330 绿
        plus.contentMode = UIViewContentModeScaleAspectFit;
        plus.frame = CGRectMake((slotW - kScaleW(22)) * 0.5, kScaleH(30), kScaleW(22), kScaleW(22));
        [empty addSubview:plus];

        UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(0, kScaleH(52), slotW, kScaleH(18))];
        t.text = @"Upload pictures";
        t.textAlignment = NSTextAlignmentCenter;
        t.font = kFontRegular(12);
        t.textColor = MKHexColor(0x999999);
        [empty addSubview:t];
        [slot addSubview:empty];
        [self.slotEmptyOverlays addObject:empty];

        // 删除角标(右上角红圆 + 白减号),初始隐藏
        CGFloat badge = kScaleW(18);
        UIButton *del = [UIButton buttonWithType:UIButtonTypeCustom];
        del.frame = CGRectMake(slotW - badge - kScaleW(5), kScaleH(5), badge, badge);
        del.backgroundColor = MKHexColor(0xDD2B2B);
        del.layer.cornerRadius = badge * 0.5;
        del.tag = i;
        UIImageSymbolConfiguration *mcfg = [UIImageSymbolConfiguration configurationWithPointSize:9 weight:UIImageSymbolWeightBold];
        [del setImage:[[UIImage systemImageNamed:@"minus" withConfiguration:mcfg] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        del.tintColor = kColorWhite;
        del.hidden = YES;
        [del addTarget:self action:@selector(deleteSlot:) forControlEvents:UIControlEventTouchUpInside];
        [slot addSubview:del];
        [self.slotDeleteButtons addObject:del];
    }

    // Submit — 设计稿 x36 y636 w303 h56 r28 (#385330);非底部吸附
    UIButton *submit = [UIButton buttonWithType:UIButtonTypeCustom];
    submit.frame = CGRectMake(kScaleW(36), navB + kScaleH(538), kScaleW(303), kScaleH(56));
    submit.backgroundColor = kColorPrimary;
    submit.layer.cornerRadius = kScaleH(28);
    [submit setTitle:@"Submit" forState:UIControlStateNormal];
    [submit setTitleColor:kColorWhite forState:UIControlStateNormal];
    submit.titleLabel.font = kFontSemibold(16);
    [submit addTarget:self action:@selector(submitTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:submit];
}

#pragma mark - Image Picker

- (void)slotTapped:(UIControl *)slot {
    self.editingSlotIndex = slot.tag;
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) wself = self;
    [sheet addAction:[UIAlertAction actionWithTitle:@"Open the photo library" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [wself showPickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Turn on the camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [wself showPickerWithSourceType:UIImagePickerControllerSourceTypeCamera];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    // iPad: action sheet 需锚点
    sheet.popoverPresentationController.sourceView = slot;
    sheet.popoverPresentationController.sourceRect = slot.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)showPickerWithSourceType:(UIImagePickerControllerSourceType)sourceType {
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        [SVProgressHUD showErrorWithStatus:sourceType == UIImagePickerControllerSourceTypeCamera ? @"Camera is not available" : @"Photo library is not available"];
        return;
    }
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = sourceType;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    if (image && self.editingSlotIndex >= 0 && self.editingSlotIndex < 3) {
        self.slotImages[self.editingSlotIndex] = image;
        [self setSlot:self.editingSlotIndex toImage:image];
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

/// 切换某格为「已选」态:显示图片 + 删除角标,隐藏空态层与黄绿描边
- (void)setSlot:(NSInteger)index toImage:(UIImage *)image {
    self.slotImageViews[index].image = image;
    self.slotImageViews[index].hidden = NO;
    self.slotEmptyOverlays[index].hidden = YES;
    self.slotDeleteButtons[index].hidden = NO;
    self.slotViews[index].layer.borderWidth = 0;
}

/// 删除角标点击:还原为「空」态
- (void)deleteSlot:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index < 0 || index >= 3) return;
    self.slotImages[index] = [NSNull null];
    self.slotImageViews[index].image = nil;
    self.slotImageViews[index].hidden = YES;
    self.slotEmptyOverlays[index].hidden = NO;
    self.slotDeleteButtons[index].hidden = YES;
    self.slotViews[index].layer.borderWidth = 1;
}

#pragma mark - Submit

- (NSArray<UIImage *> *)pickedImages {
    NSMutableArray *images = [NSMutableArray array];
    for (id obj in self.slotImages) {
        if ([obj isKindOfClass:[UIImage class]]) [images addObject:obj];
    }
    return images;
}

- (void)submitTapped {
    NSString *question = self.textView.text;
    if (question.length == 0) {
        [SVProgressHUD showErrorWithStatus:@"Please enter your question"];
        return;
    }
    NSArray<UIImage *> *images = [self pickedImages];
    if (images.count > 0) {
        [self uploadImagesAndSubmit:images];
    } else {
        [self submitFeedbackWithImageURLs:@[]];
    }
}

#pragma mark - Image Upload

/// 压缩图片到 1MB 以内
- (NSData *)compressImageToMaxSize:(UIImage *)image {
    if (!image) return nil;
    NSInteger maxSize = 1024 * 1024;
    CGFloat compression = 0.9f;
    NSData *data = UIImageJPEGRepresentation(image, compression);
    while (data.length > maxSize && compression > 0.1f) {
        compression -= 0.1f;
        data = UIImageJPEGRepresentation(image, compression);
    }
    if (data.length > maxSize) {
        CGFloat scale = sqrt((CGFloat)maxSize / (CGFloat)data.length);
        CGSize newSize = CGSizeMake(image.size.width * scale, image.size.height * scale);
        UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
        [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
        UIImage *scaled = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        compression = 0.8f;
        data = UIImageJPEGRepresentation(scaled, compression);
        while (data.length > maxSize && compression > 0.1f) {
            compression -= 0.1f;
            data = UIImageJPEGRepresentation(scaled, compression);
        }
    }
    return data;
}

- (void)uploadImagesAndSubmit:(NSArray<UIImage *> *)images {
    [SVProgressHUD showWithStatus:@"Uploading images..."];
    [self.uploadedImageURLs removeAllObjects];

    dispatch_group_t group = dispatch_group_create();
    __block BOOL hasError = NO;
    __block NSString *errorMsg = nil;

    for (UIImage *image in images) {
        NSData *data = [self compressImageToMaxSize:image];
        if (data.length == 0) { hasError = YES; errorMsg = @"Failed to compress image"; continue; }
        dispatch_group_enter(group);
        [self uploadImage:data completion:^(NSString *url, NSError *error) {
            if (url.length > 0) {
                [self.uploadedImageURLs addObject:url];
            } else {
                hasError = YES;
                errorMsg = error.localizedDescription ?: @"Upload failed";
            }
            dispatch_group_leave(group);
        }];
    }

    __weak typeof(self) wself = self;
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        if (hasError) {
            [SVProgressHUD showErrorWithStatus:errorMsg ?: @"Failed to upload images"];
            return;
        }
        [wself submitFeedbackWithImageURLs:wself.uploadedImageURLs];
    });
}

- (void)uploadImage:(NSData *)imageData completion:(void(^)(NSString *imageURL, NSError *error))completion {
    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBodyWithSignData:@{} requestData:@{}];
    [[MKNetworkManager sharedManager] uploadFile:@"/app/v3/sys/upload"
                                          params:body
                                        fileData:imageData
                                        fileName:@"image.jpg"
                                        mimeType:@"image/jpeg"
                                         headers:nil
                                        progress:nil
                                         success:^(id resp) {
        NSString *src = nil;
        if ([resp isKindOfClass:[NSDictionary class]] && [resp[@"resultCode"] integerValue] == 200) {
            NSDictionary *data = resp[@"data"];
            if ([data isKindOfClass:[NSDictionary class]]) src = data[@"src"];
        }
        if (completion) completion(src, src.length ? nil : [NSError errorWithDomain:@"MKFeedback" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Upload failed"}]);
    } failure:^(NSError *error) {
        if (completion) completion(nil, error);
    }];
}

- (void)submitFeedbackWithImageURLs:(NSArray<NSString *> *)imageURLs {
    NSString *pictureUrl = [imageURLs componentsJoinedByString:@","];
    NSDictionary *data = @{
        @"userMobile": [MKLoginManager sharedManager].mobile ?: @"",
        @"description": self.textView.text ?: @"",
        @"contactWay": @"",
        @"whatsApp": @"",
        @"pictureUrl": pictureUrl ?: @"",
        @"score": @"5",
        @"questionType": @"3",
    };
    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBodyWithSignData:@{} requestData:data];

    [SVProgressHUD showWithStatus:@"Submitting..."];
    __weak typeof(self) wself = self;
    [[MKNetworkManager sharedManager] post:@"/app/v3/user/problemFeedback"
                                    params:body
                                   success:^(id resp) {
        [SVProgressHUD dismiss];
        if ([resp isKindOfClass:[NSDictionary class]] && [resp[@"resultCode"] integerValue] == 200) {
            [SVProgressHUD showSuccessWithStatus:@"Feedback submitted successfully"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [wself.navigationController popViewControllerAnimated:YES];
            });
        } else {
            NSString *msg = [resp isKindOfClass:[NSDictionary class]] ? resp[@"resultMsg"] : nil;
            [SVProgressHUD showErrorWithStatus:msg.length ? msg : @"Failed to submit feedback"];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD dismiss];
        [SVProgressHUD showErrorWithStatus:@"Network error, please try again"];
    }];
}

- (void)textViewDidChange:(UITextView *)textView {
    UILabel *placeholder = (UILabel *)[self.view viewWithTag:9100];
    placeholder.hidden = textView.text.length > 0;
    if (textView.text.length > 1000) {
        textView.text = [textView.text substringToIndex:1000];
    }
    self.counterLabel.text = [NSString stringWithFormat:@"%lu/1000", (unsigned long)textView.text.length];
}

@end

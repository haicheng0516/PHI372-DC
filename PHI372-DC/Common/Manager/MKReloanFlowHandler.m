//
//  MKReloanFlowHandler.m
//  PHI372-DC
//

#import "MKReloanFlowHandler.h"
#import "MKEncryptManager.h"
#import "MKNetworkManager.h"
#import "MKProductTermModel.h"
#import "MKProductStateResponse.h"
#import "NSString+MKAmount.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface MKReloanFlowHandler ()

@property (nonatomic, assign) BOOL isRequestingProductState;

@end

@implementation MKReloanFlowHandler

- (void)reset {
    self.isRequestingProductState = NO;
    [self hideReloanTipAlert];
}

- (void)hideReloanTipAlert {
    if (self.currentReloanAlert) {
        // TODO[reloan]: 后续接入 MKBottomSheetView 等价类型的 dismiss
        NSLog(@"[Reloan/Seamless] would dismiss reloan alert (current=%@)", self.currentReloanAlert);
        self.currentReloanAlert = nil;
    }
}

#pragma mark - Request Product State

- (void)requestProductStateAndShowTipWithProductId:(NSString *)productId {
    if (self.isRequestingProductState) return;
    if (!productId || productId.length == 0) {
        [self notifyDismiss];
        return;
    }

    self.isRequestingProductState = YES;

    NSDictionary *dataForSign = @{};
    NSDictionary *dataForRequest = @{@"productId": productId};
    NSDictionary *body = [[MKEncryptManager sharedManager]
                           generateRequestBodyWithSignData:dataForSign requestData:dataForRequest];

    __weak typeof(self) weakSelf = self;
    [[MKNetworkManager sharedManager] post:@"/app/v3/product/state"
                                    params:body
                                   success:^(id resp) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.isRequestingProductState = NO;

        MKProductStateResponse *response = [[MKProductStateResponse alloc] initWithDictionary:resp];
        if (![response isSuccess] || !response.data || response.data.amountDetailList.count == 0) {
            [strongSelf notifyDismiss]; return;
        }

        MKProductStateDetailModel *detail = response.data.amountDetailList.firstObject;
        if (detail.productName.length == 0 || detail.loanAmount.length == 0) {
            [strongSelf notifyDismiss]; return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf showReloanAlertWithDetail:detail];
        });
    } failure:^(NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.isRequestingProductState = NO;
        [strongSelf notifyDismiss];
    }];
}

- (void)notifyDismiss {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(reloanFlowHandlerDidDismiss:)]) {
            [self.delegate reloanFlowHandlerDidDismiss:self];
        }
    });
}

#pragma mark - Show Reloan Alert

- (void)showReloanAlertWithDetail:(MKProductStateDetailModel *)detail {
    // TODO[reloan]: 后续接入 MKBottomSheetView 等价类型
    NSString *titleText = @"Tips";
    NSString *messageText = @"Don't miss this opportunity! Your previous application was successful. Apply again today to help you achieve your goals quickly!";
    NSString *productName = detail.productName;
    NSString *productAmount = [detail.loanAmount mk_formattedPesoAmount];
    NSString *productLogoURL = detail.productLogo;
    NSString *confirmTitle = @"Apply Now";
    NSLog(@"[Reloan/Seamless] would show alert type=%@ title=%@ msg=%@ product=%@ amount=%@ logo=%@ confirm=%@",
          @"ReloanProduct", titleText, messageText, productName, productAmount, productLogoURL, confirmTitle);

    __weak typeof(self) weakSelf = self;
    void (^confirmBlock)(void) = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        [strongSelf startSeamlessOrderWithProductId:detail.productId selectedAmount:detail.loanAmount];
    };
    void (^cancelBlock)(void) = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.currentReloanAlert = nil;
        if ([strongSelf.delegate respondsToSelector:@selector(reloanFlowHandlerDidDismiss:)]) {
            [strongSelf.delegate reloanFlowHandlerDidDismiss:strongSelf];
        }
    };
    // 占位: UI 接入前直接走 dismiss 分支, 不自动 confirm
    (void)confirmBlock;
    cancelBlock();
}

#pragma mark - Start Seamless Order

- (void)startSeamlessOrderWithProductId:(NSString *)productId selectedAmount:(NSString *)selectedAmount {
    [SVProgressHUD show];

    NSDictionary *body = [[MKEncryptManager sharedManager] generateRequestBody:@{@"productId": productId ?: @""}];

    __weak typeof(self) weakSelf = self;
    [[MKNetworkManager sharedManager] post:@"/app/v3/product/termV3"
                                    params:body
                                   success:^(id resp) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        if (![resp isKindOfClass:[NSDictionary class]]) {
            [SVProgressHUD dismiss];
            [SVProgressHUD showErrorWithStatus:@"Invalid response"];
            return;
        }
        if ([resp[@"resultCode"] integerValue] != 200) {
            [SVProgressHUD dismiss];
            [SVProgressHUD showErrorWithStatus:resp[@"resultMsg"] ?: @"Failed to load product"];
            return;
        }

        NSDictionary *data = resp[@"data"];
        if (![data isKindOfClass:[NSDictionary class]]) {
            [SVProgressHUD dismiss];
            return;
        }

        MKSeamlessOrderParams *params = [[MKSeamlessOrderParams alloc] init];
        params.productId = productId;
        params.selectedAmount = selectedAmount;
        params.termResponseData = data;

        [MKSeamlessOrderManager sharedManager].delegate = strongSelf.seamlessOrderDelegate;
        BOOL started = [[MKSeamlessOrderManager sharedManager] startSeamlessOrderWithParams:params];
        if (!started) {
            [SVProgressHUD dismiss];
            return;
        }

        if ([strongSelf.delegate respondsToSelector:@selector(reloanFlowHandlerDidStartSeamlessOrder:)]) {
            [strongSelf.delegate reloanFlowHandlerDidStartSeamlessOrder:strongSelf];
        }
    } failure:^(NSError *error) {
        [SVProgressHUD dismiss];
        [SVProgressHUD showErrorWithStatus:@"Network request failed"];
    }];
}

@end

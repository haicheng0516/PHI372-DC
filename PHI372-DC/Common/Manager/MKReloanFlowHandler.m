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
        [self.currentReloanAlert dismiss];
        self.currentReloanAlert = nil;
    }
}

#pragma mark - Request Product State

- (void)requestProductStateAndShowTipWithProductId:(NSString *)productId
                                         sheetType:(MKBottomSheetType)sheetType {
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
            [strongSelf showReloanAlertWithDetail:detail sheetType:sheetType];
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

- (void)showReloanAlertWithDetail:(MKProductStateDetailModel *)detail
                        sheetType:(MKBottomSheetType)sheetType {
    NSString *amount = [detail.loanAmount mk_formattedPesoAmount] ?: detail.loanAmount ?: @"";
    NSDictionary *cfg = @{
        @"productName":    detail.productName    ?: @"",
        @"productAmount":  amount,
        @"productLogoURL": detail.productLogo    ?: @""
    };
    MKBottomSheetView *sheet = [MKBottomSheetView sheetWithType:sheetType config:cfg];
    self.currentReloanAlert = sheet;

    __weak typeof(self) weakSelf = self;
    NSString *productId = [detail.productId copy];
    NSString *loanAmount = [detail.loanAmount copy];
    sheet.onConfirmTapped = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        // 复借弹窗保持在界面上, 等系统定位权限弹窗出现时再 dismiss (与 259 一致)
        [strongSelf startSeamlessOrderWithProductId:productId selectedAmount:loanAmount];
    };
    sheet.onCancelTapped = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.currentReloanAlert = nil;
        if ([strongSelf.delegate respondsToSelector:@selector(reloanFlowHandlerDidDismiss:)]) {
            [strongSelf.delegate reloanFlowHandlerDidDismiss:strongSelf];
        }
    };
    [sheet show];
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

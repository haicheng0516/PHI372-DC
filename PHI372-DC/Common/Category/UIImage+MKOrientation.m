//
//  UIImage+MKOrientation.m
//  PHI372-DC
//

#import "UIImage+MKOrientation.h"

@implementation UIImage (MKOrientation)

- (UIImage *)rotateBasedOnDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    CGFloat degrees = 0.0;
    switch (deviceOrientation) {
        case UIDeviceOrientationLandscapeLeft:
            degrees = 90.0;
            break;
        case UIDeviceOrientationLandscapeRight:
            degrees = -90.0;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            degrees = 180.0;
            break;
        default:
            degrees = 0.0;
            break;
    }
    if (degrees == 0.0) {
        return self;
    }
    return [self rotateByDegrees:degrees];
}

- (UIImage *)fixOrientation {
    if (self.imageOrientation == UIImageOrientationUp) {
        return self;
    }

    CGAffineTransform transform = CGAffineTransformIdentity;

    switch (self.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }

    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }

    CGContextRef ctx = CGBitmapContextCreate(NULL,
                                             self.size.width,
                                             self.size.height,
                                             CGImageGetBitsPerComponent(self.CGImage),
                                             0,
                                             CGImageGetColorSpace(self.CGImage),
                                             CGImageGetBitmapInfo(self.CGImage));
    if (!ctx) {
        return self;
    }

    CGContextConcatCTM(ctx, transform);

    CGRect drawRect = CGRectZero;
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            drawRect = CGRectMake(0, 0, self.size.height, self.size.width);
            break;
        default:
            drawRect = CGRectMake(0, 0, self.size.width, self.size.height);
            break;
    }
    CGContextDrawImage(ctx, drawRect, self.CGImage);

    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg scale:self.scale orientation:UIImageOrientationUp];
    CGImageRelease(cgimg);
    CGContextRelease(ctx);
    return img ?: self;
}

- (UIImage *)rotateByDegrees:(CGFloat)degrees {
    CGFloat radians = degrees * (CGFloat)M_PI / 180.0f;

    CGRect imageRect = CGRectMake(0.0, 0.0, self.size.width, self.size.height);
    CGAffineTransform transform = CGAffineTransformMakeRotation(radians);
    CGRect rotatedRect = CGRectApplyAffineTransform(imageRect, transform);

    UIGraphicsBeginImageContextWithOptions(rotatedRect.size, NO, self.scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) {
        UIGraphicsEndImageContext();
        return self;
    }

    CGContextTranslateCTM(ctx, rotatedRect.size.width / 2.0, rotatedRect.size.height / 2.0);
    CGContextRotateCTM(ctx, radians);
    [self drawInRect:CGRectMake(-self.size.width / 2.0, -self.size.height / 2.0, self.size.width, self.size.height)];

    UIImage *rotatedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return rotatedImage ?: self;
}

@end

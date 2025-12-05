//
//  PolaroidProcessingPipeline.swift
//  camera-poc
//
//  Created by Diogo Camargo on 05/12/25.
//

import SwiftUI

struct PolaroidProcessingPipeline {

    static func applyPolaroidPipeline(to image: UIImage,
                                      overlayIntensity: CGFloat) -> UIImage {

        let oriented = fixImageOrientation(image)
        let flipped = flipImageHorizontally(oriented) ?? oriented

        let filtered = applyPolaroidFilter(to: flipped) ?? flipped

        return applyGrayOverlay(
            to: filtered,
            gray: UIColor(white: 0.02, alpha: 1),
            intensity: overlayIntensity
        ) ?? filtered
    }

    private static func fixImageOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up { return image }
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let result = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return result
    }

    private static func flipImageHorizontally(_ img: UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.translateBy(x: img.size.width, y: 0)
        ctx.scaleBy(x: -1, y: 1)
        img.draw(in: CGRect(origin: .zero, size: img.size))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }

    private static func applyPolaroidFilter(to image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        guard let filtered = applyPolaroidEffect(to: ciImage) else { return nil }

        let context = CIContext()
        guard let cgImage = context.createCGImage(filtered, from: filtered.extent) else { return nil }

        return UIImage(cgImage: cgImage,
                       scale: image.scale,
                       orientation: image.imageOrientation)
    }

    private static func applyPolaroidEffect(to input: CIImage) -> CIImage? {
        let instant = CIFilter.photoEffectInstant()
        instant.inputImage = input
        guard let output1 = instant.outputImage else { return nil }

        let vignette = CIFilter.vignette()
        vignette.inputImage = output1
        vignette.intensity = 0.5
        vignette.radius = 1.2

        return vignette.outputImage
    }

    static func applyGrayOverlay(to image: UIImage,
                                 gray: UIColor,
                                 intensity: CGFloat) -> UIImage? {

        let rect = CGRect(origin: .zero, size: image.size)
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        image.draw(in: rect)
        ctx.setFillColor(gray.withAlphaComponent(intensity).cgColor)
        ctx.fill(rect)

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}

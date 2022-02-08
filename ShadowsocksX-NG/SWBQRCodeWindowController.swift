//
//  SWBQRCodeWindowController.swift
//  ShadowsocksX-NG
//
//  Created by 钟增强 on 2021/4/28.
//

import Cocoa
import WebKit
import CoreImage

class SWBQRCodeWindowController: NSWindowController {

    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var imageView: NSImageView!
    
    var qrCode: String?
    var title: String?

    @IBAction func copyQRCode(_ sender: Any) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let copiedObjects = [imageView?.image]
        pasteboard.writeObjects(copiedObjects.compactMap { $0 })
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        titleTextField.stringValue = title ?? ""
        setQRCode(qrCode)
    }

    func setQRCode(_ qrCode: String?) {
        let cgImgRef = createQRImage(for: qrCode, size: CGSize(width: 250, height: 250))

        var image: NSImage? = nil
        if let cgImgRef = cgImgRef {
            image = NSImage(cgImage: cgImgRef, size: CGSize(width: 250, height: 250))
        }
        imageView?.image = image
    }
    
    func createQRImage(for string: String?, size: CGSize) -> CGImage? {
        // Setup the QR filter with our string
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setDefaults()

        let data = string?.data(using: .utf8)
        filter?.setValue(data, forKey: "inputMessage")
        let image = filter?.value(forKey: "outputImage") as? CIImage

        // Calculate the size of the generated image and the scale for the desired image size
        let extent = image?.extent.integral
        let scale = CGFloat(min(size.width / (extent?.width ?? 0.0), size.height / (extent?.height ?? 0.0)))

        // Since CoreImage nicely interpolates, we need to create a bitmap image that we'll draw into
        // a bitmap context at the desired size;
        let width = size_t((extent?.width ?? 0.0) * scale)
        let height = size_t((extent?.height ?? 0.0) * scale)
        let cs = CGColorSpaceCreateDeviceGray()
        let bitmapRef = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: cs, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue).rawValue )

        #if os(iOS)
        let context = CIContext(options: [
            CIContextOption.useSoftwareRenderer: true
        ])
        #else
        var context: CIContext? = nil
        if let bitmapRef = bitmapRef {
            context = CIContext(cgContext: bitmapRef, options: [
                CIContextOption.useSoftwareRenderer: NSNumber(value: true)
            ])
        }
        #endif

        var bitmapImage: CGImage? = nil
        if let image = image {
            bitmapImage = context?.createCGImage(image, from: extent ?? CGRect.zero)
        }

        bitmapRef!.interpolationQuality = CGInterpolationQuality.none
        bitmapRef?.scaleBy(x: scale, y: scale)
        bitmapRef?.draw(bitmapImage!, in: extent!)

        // Create an image with the contents of our bitmap
        let scaledImage = bitmapRef?.makeImage()

        return scaledImage
    }
}

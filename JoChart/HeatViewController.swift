//
//  HeatViewController.swift
//  JoChart
//
//  Created by jojo on 2020/2/4.
//  Copyright © 2020 joshin. All rights reserved.
//

import UIKit

class HeatViewController: BaseViewController {

    private let Radius: CGFloat = 10
    
    private lazy var heatChart: UIView = {
        let v = UIView()
        v.backgroundColor = .hex(value: 0x03a9f4)
        return v
    }()
    
    private lazy var maskView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        heatChart.frame = CGRect.init(x: 0, y: 120, width: CGFloat.screenWidth, height: 300)
        heatChart.addSubview(maskView)
        maskView.frame = heatChart.bounds
        self.view.addSubview(heatChart)
        
        var list = [HeatModel]()
//        var sum = 10
//        let duration = Date.init().timeIntervalSince1970
//        for i in 0...1000000 {
////            list.append(HeatModel(location: .init(x: 30, y: 30), value: CGFloat.random(in: 1...10)))
//            sum += 1
//        }
//        print("end \(Date.init().timeIntervalSince1970 - duration)")
        
        for _ in 0...1000 {
            list.append(HeatModel(location: .init(x: 40 + Int.random(in: 0...230), y: 60 + Int.random(in: 0...200)), value: CGFloat.random(in: 40...100)))
        }
        
        var maxValue: CGFloat = 0
        var minValue: CGFloat = 0
        for item in list {
            if item.value > maxValue {
                maxValue = item.value
            }
            
            if item.value < minValue {
                minValue = item.value
            }
        }
        
//        let alpha = (count - minValue) / (maxValue - minValue);

//        for data in list {
//            let layer = CAGradientLayer.init()
//            layer.colors = [UIColor.hex(value: 0x000000), UIColor.hex(value: 0x000000).withAlphaComponent(0)]
//
//            heatChart.layer.addSublayer(layer)
//        }
        
//        let image = UIImage.init(named: "rect")
//        let colors = image!.getAllPixelColors()
//        if let list = colors {
//            for color in list {
//                print("\(color.cgColor.alpha)")
//            }
//        }
        
        
        let paletteSize = CGSize(width: 255, height: 5)
        let paletteRender = UIGraphicsImageRenderer(size: paletteSize)
        let paletteImg = paletteRender.image { ctx in
            let colors = [UIColor.green.cgColor, UIColor.yellow.cgColor, UIColor.orange.cgColor,  UIColor.red.cgColor] as CFArray
            let locations = [CGFloat(0.25), CGFloat(0.55), CGFloat(0.85), CGFloat(1.0)]
            let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations)
            let start = CGPoint(x: 0, y: 0)
            let end = CGPoint(x: paletteSize.width, y: 0)
            ctx.cgContext.drawLinearGradient(gradient!, start: start, end: end, options: .drawsBeforeStartLocation)
        }
        
        let paletteView = UIImageView.init(image: paletteImg)
        var frame = paletteView.frame
        frame.origin.y = 100
        paletteView.frame = frame
        self.view.addSubview(paletteView)
        
//        let mainScale = CGFloat(1) //UIScreen.main.scale
        let size = maskView.frame.size
//        let format = UIGraphicsImageRendererFormat()
//        format.scale = 1
        
        DispatchQueue.global(qos: .background).async {
            let img = self.generateImg(size: size, list: list, maxValue: maxValue, minValue: minValue)
            DispatchQueue.main.async {
                self.draw(paletteImg: paletteImg, paletteSize: paletteSize, img: img)
            }
        }
        
//        let render = UIGraphicsImageRenderer(size: size)
//        let png = render.pngData { ctx in
//            for heatData in list {
//                print("value = \(heatData.value)")
//                let alpha = (heatData.value - minValue) / (maxValue - minValue)
//
//                let start = heatData.location
//                let end = heatData.location
//                let colors = [UIColor.black.withAlphaComponent(alpha).cgColor, UIColor.black.withAlphaComponent(0).cgColor] as CFArray
//                let locations = [CGFloat(0.0), CGFloat(1.0)]
//                let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations)
//
//                ctx.cgContext.drawRadialGradient(gradient!, startCenter: start, startRadius: 0, endCenter: end, endRadius: Radius, options:.drawsAfterEndLocation)
//            }
//        }
//        let img = UIImage.init(data: png)!
        
        // #### palette
        
        
        
    }
    
    func getReplaceColor(position: Int, data: UnsafePointer<UInt8>) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        let pixelInfo: Int = position * 4
        
        let r = data[pixelInfo]
        let g = data[pixelInfo + 1]
        let b = data[pixelInfo + 2]
        let a = data[pixelInfo + 3]
        
        return (r, g, b, a)
    }
    
    func generateImg(size: CGSize, list: [HeatModel], maxValue: CGFloat, minValue: CGFloat) -> UIImage {
        let render = UIGraphicsImageRenderer(size: size)
        let png = render.pngData { ctx in
            for heatData in list {
//                print("value = \(heatData.value)")
                let alpha = (heatData.value - minValue) / (maxValue - minValue)
                
                let start = heatData.location
                let end = heatData.location
                let colors = [UIColor.black.withAlphaComponent(alpha).cgColor, UIColor.black.withAlphaComponent(0).cgColor] as CFArray
                let locations = [CGFloat(0.0), CGFloat(1.0)]
                let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations)
                
                ctx.cgContext.drawRadialGradient(gradient!, startCenter: start, startRadius: 0, endCenter: end, endRadius: Radius, options:.drawsAfterEndLocation)
            }
        }
        let img = UIImage.init(data: png)!
        return img
    }
    
    func draw(paletteImg: UIImage, paletteSize: CGSize, img: UIImage) {
        let paletteDataProvider = paletteImg.cgImage!.dataProvider
        
        let palettePixelData = paletteDataProvider!.data
        let paletteData: UnsafePointer<UInt8> = CFDataGetBytePtr(palettePixelData)
        
        
        
        // #### replace alpha to color
        
        let dataProvider = img.cgImage!.dataProvider
        let pixelData = dataProvider!.data
//        let str = "\(pixelData.debugDescription)"
//        let subs = str.split(separator: " ")
        
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let width = img.cgImage!.width
        let height = img.cgImage!.height
        
        
        let bytesPerPixel = 4
        let bitsPerComponent = 8
        let bitsPerPixel = bytesPerPixel * bitsPerComponent;
        let rawData = UnsafeMutablePointer<UInt8>.allocate(capacity: bytesPerPixel * width * height)
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelInfo = (width * y + x) * 4
                
                let alpha = CGFloat(data[pixelInfo + 3]) / CGFloat(255.0)
                
                if alpha > 0 {
                    let position = Int(alpha * paletteSize.width * paletteImg.scale)
                    let (r, g, b, a) = getReplaceColor(position: position, data: paletteData)
                    rawData[pixelInfo] = r
                    rawData[pixelInfo + 1] = g
                    rawData[pixelInfo + 2] = b
                    rawData[pixelInfo + 3] = a
                }
                
            }
        }
        
        
        let cfData = CFDataCreate(kCFAllocatorDefault, rawData, bytesPerPixel * width * height)
        let provider: CGDataProvider = CGDataProvider.init(data: cfData!)!
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let imageRef = CGImage.init(width: width, height: height, bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: bytesPerPixel * width, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        
        rawData.deallocate()
        
        //        maskView.image = img
        
        if imageRef != nil {
            let image = UIImage.init(cgImage: imageRef!, scale: img.scale, orientation: .up)
            maskView.image = image
            
        }
    }

}

struct HeatModel {
    var point: CGPoint = .zero
    var location: CGPoint
    var value: CGFloat
}

//
//  JoHeatChart.swift
//  JoChart
//
//  Created by jojo on 2020/6/1.
//  Copyright © 2020 joshin. All rights reserved.
//

import UIKit

class JoHeatChart: JoChartBase {
    
    private var listData: [JoHeatValue] = []
    
    private lazy var imageView: UIImageView = {
        let iv = UIImageView()
        return iv
    }()
    
    private lazy var loadingView: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .white)
        v.hidesWhenStopped = true
        return v
    }()
    
    var maxRadius: CGFloat = 8
    
    override init() {
        super.init()
        
        self.addSubview(imageView)
        self.addSubview(loadingView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawChart() {
        super.drawChart()
        
        imageView.frame = self.bounds
        loadingView.center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        guard !loadingView.isAnimating else {
            print("heat map is drawing")
            return
        }
        loadingView.startAnimating()
        
        var maxValue: CGFloat = 0
        var minValue: CGFloat = 0
        
        for item in listData {
            if item.value > maxValue {
                maxValue = item.value
            }
            
            if item.value < minValue {
                minValue = item.value
            }
        }
        
        let paletteSize = CGSize(width: 255, height: 2)
        let paletteRender = UIGraphicsImageRenderer(size: paletteSize)
        let paletteImg = paletteRender.image { ctx in
            let colors = [UIColor.green.cgColor, UIColor.yellow.cgColor, UIColor.orange.cgColor,  UIColor.red.cgColor] as CFArray
            let locations = [CGFloat(0.25), CGFloat(0.55), CGFloat(0.85), CGFloat(1.0)]
            let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations)
            let start = CGPoint(x: 0, y: 0)
            let end = CGPoint(x: paletteSize.width, y: 0)
            ctx.cgContext.drawLinearGradient(gradient!, start: start, end: end, options: .drawsBeforeStartLocation)
        }
        
        let size = self.bounds.size
        let data = self.listData
        DispatchQueue.global(qos: .background).async {
            let img = self.generateAlphaGradientImg(size: size, list: data, max: maxValue, min: minValue)
            
            self.replaceImageColor(paletteImg: paletteImg, paletteSize: paletteSize, img: img) {
                self.imageView.image = $0
                self.loadingView.stopAnimating()
            }
        }
    }
}

extension JoHeatChart {
    public func setOptions(data: [JoHeatValue]) {
        listData.removeAll()
        listData += data
    }
    
    private func getReplaceColor(position: Int, data: UnsafePointer<UInt8>) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        let pixelInfo: Int = position * 4
        
        let r = data[pixelInfo]
        let g = data[pixelInfo + 1]
        let b = data[pixelInfo + 2]
        let a = data[pixelInfo + 3]
        
        return (r, g, b, a)
    }
    
    private func generateAlphaGradientImg(size: CGSize, list: [JoHeatValue], max: CGFloat, min: CGFloat) -> UIImage {
        let render = UIGraphicsImageRenderer(size: size)
        let png = render.pngData { ctx in
            for heatData in list {
                
                let alpha = (heatData.value - min) / (max - min)
                
                let start = heatData.location
                let end = heatData.location
                let colors = [UIColor.black.withAlphaComponent(alpha).cgColor, UIColor.black.withAlphaComponent(0).cgColor] as CFArray
                let locations = [CGFloat(0.0), CGFloat(1.0)]
                let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations)
                
                ctx.cgContext.drawRadialGradient(gradient!, startCenter: start, startRadius: 0, endCenter: end, endRadius: heatData.radius, options:.drawsAfterEndLocation)
            }
        }
        let img = UIImage.init(data: png)!
        return img
    }
    
    private func replaceImageColor(paletteImg: UIImage, paletteSize: CGSize, img: UIImage, completion: @escaping (UIImage?) -> Void) {
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
        
        if let imageRef = imageRef {
            let image = UIImage.init(cgImage: imageRef, scale: img.scale, orientation: .up)
            DispatchQueue.main.async {
                completion(image)
            }
        } else {
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
}

struct JoHeatValue {
    var point: CGPoint = .zero
    var radius: CGFloat = 8
    var location: CGPoint
    var value: CGFloat
}

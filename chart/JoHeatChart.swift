//
//  JoHeatChart.swift
//  JoChart
//
//  Created by jojo on 2020/6/1.
//  Copyright © 2020 joshin. All rights reserved.
//

import UIKit
import Metal
import simd

public class JoHeatChart: JoChartBase {
        
    /// JoChartShaders.metal 字符串化
    private let shaderString = """
    #include <metal_stdlib>
    using namespace metal;

    struct JoRasterizerData {
        vector_float4 position [[position]];
        vector_float4 color;
    };

    struct JoVertexIn {
        vector_float2 position;
        vector_float4 color;
    };

    vertex JoRasterizerData jo_vertex_main(uint vId [[vertex_id]],
                                  constant JoVertexIn *in [[buffer(0)]],
                                  constant vector_uint2 *viewportSizePointer [[buffer(1)]]) {
        JoRasterizerData out;
        
        float2 pixelSpacePosition = in[vId].position.xy;
        vector_float2 viewportSize = vector_float2(*viewportSizePointer);
        
        out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
        out.position.xy = pixelSpacePosition / (viewportSize / 2.0);
        
        out.color = in[vId].color;
        
        return out;
    }

    fragment float4 jo_fragment_main(JoRasterizerData in [[stage_in]]) {
        return in.color;
    }

    kernel void jo_compute_main(texture2d<half, access::read>  sourceTexture  [[texture(0)]],
                                texture2d<half, access::write> destTexture [[texture(1)]],
                                texture2d<half, access::read>  paletteTexture  [[texture(2)]],
                                uint2 gid [[thread_position_in_grid]]) {

        half4 color = sourceTexture.read(gid);
        if (color.r == 1 && color.g == 1 && color.b == 1)  { // white
            destTexture.write(half4(0, 0, 0, 0) , gid);
        } else {
            uint index = (1 - color.r) * paletteTexture.get_width() - 1;
            half4 paletteColor = paletteTexture.read(uint2(index, 0));
            destTexture.write(half4(paletteColor.b, paletteColor.g, paletteColor.r, 1), gid);
        }
    }
    """

    
    /// 4
    private let bytesPerPixel = 4
    /// 8
    private let bitsPerComponent = 8
    
    public enum RenderType {
        case CPU
        case GPU
    }
    
    enum JoChartErr: Error {
        case ErrFindGPUDevice
        case ErrFindMetalLibrary
        case ErrCreateCommandQueue
        case ErrCreateCommandEncoder
        case ErrCreateCommandIndexBuffer
        case ErrCreateComputeFunction
        case ErrCreateComputeBuffer
        case ErrCreateTexture
    }
    
    private lazy var maskImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private lazy var loadingView: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .white)
        v.hidesWhenStopped = true
        return v
    }()
    
    private var renderType: RenderType = .GPU
    
    private var paletteColors: [UIColor]!
    private var paletteRatio: [CGFloat]!
    
    private var listData: [JoHeatValue] = []
    
    private lazy var cpuRenderAsnycQueue: DispatchQueue = {
       return .init(label: "JoHeatChartCpuQueue")
    }()
    
    private var maxValue: CGFloat = 0
    private var minValue: CGFloat = 0
    
    
    // for GPU render
    
    private var mDevice: MTLDevice!
    
    private var renderPipelineState: MTLRenderPipelineState!
    
    private var computePipelineState: MTLComputePipelineState!
    
    private var commandQueue: MTLCommandQueue!
    
    private var paletteTexture: MTLTexture!
    
    private var mData: [JoVertexIndexModel] = []
    
    /// 组成圆形的三角形个数
    private let CircleDivideCount = 36
    
    private var viewPortSize: vector_uint2 = [0, 0]
    
    private let inFlightSemaphore = DispatchSemaphore(value: 0)
    
    /// - Parameters:
    ///   - type:渲染模式，默认GPU
    ///   - paletteColors: 调色板颜色，从低到高，默认 [UIColor.green, UIColor.yellow, UIColor.orange,  UIColor.red]
    ///   - paletteRatio: 调色板各个颜色的束位置，范围(0, 1]，默认 [0.25, 0.55, 0.85, 1]
    /// - Attention: paletteColors元素数和paletteRatio一致
    public init(render type: RenderType = .GPU,
         paletteColors: [UIColor] = [UIColor.green, UIColor.yellow, UIColor.orange,  UIColor.red],
         paletteRatio: [CGFloat] = [CGFloat(0.25), CGFloat(0.55), CGFloat(0.85), CGFloat(1.0)]) {
        super.init()
        
        renderType = type
        self.paletteColors = paletteColors
        self.paletteRatio = paletteRatio
        
        guard self.paletteRatio.count == self.paletteColors.count else {
            fatalError("paletteRatio.count should equal paletteColors.count")
        }
        
        self.addSubview(maskImageView)
        self.addSubview(loadingView)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// - Attention: 因为数据位置和chart的尺寸相关，所以如果改变了chart小大，**drawChart**前需要重新调用**setOptions**
    override public func drawChart() {
        super.drawChart()
        
        maskImageView.frame = self.bounds
        loadingView.center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        guard !loadingView.isAnimating else {
            print("heat map is drawing")
            return
        }
        loadingView.startAnimating()
        
        
        if renderType == .CPU {
            drawChartWithCPU()
        } else {
            do {
                try drawChartWithGPU()
            } catch let e {
                print("\(e)")
            }
        }
    }
}

/// common
extension JoHeatChart {
    private func renderPalette(size paletteSize: CGSize) -> UIImage {
        let paletteRender = UIGraphicsImageRenderer(size: paletteSize)
        let colors = self.paletteColors.map {
            return $0.cgColor
            } as CFArray
        let locations = self.paletteRatio
        let paletteImg = paletteRender.image { ctx in
            
            let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations)
            let start = CGPoint(x: 0, y: 0)
            let end = CGPoint(x: paletteSize.width, y: 0)
            ctx.cgContext.drawLinearGradient(gradient!, start: start, end: end, options: .drawsBeforeStartLocation)
        }
        
        return paletteImg
    }
    
    public func setOptions(data: [JoHeatValue]) {
        listData.removeAll()
        listData += data
        
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
        
        self.maxValue = maxValue
        self.minValue = minValue
        
        let scale = UIScreen.main.scale
        viewPortSize.x = UInt32(self.bounds.width * scale)
        viewPortSize.y = UInt32(self.bounds.height * scale)
        
        if renderType == .GPU {
            mData.removeAll()
            for item in data {
                let x: CGFloat = (item.location.x - self.bounds.midX) * scale
                let y: CGFloat = (self.bounds.midY - item.location.y) * scale
                let center = CGPoint(x: x, y: y)
                mData.append(generateVertices(value: item.value, center: center, radius: item.radius * scale))
            }
            
        }
    }
}

// MARK: - CPU render
extension JoHeatChart {
    
    private func drawChartWithCPU() {
        let paletteSize = CGSize(width: 255, height: 2)
        let paletteImg = renderPalette(size: paletteSize)
        
        let size = self.bounds.size
        let data = self.listData
        let min = self.minValue
        let max = self.maxValue
        cpuRenderAsnycQueue.async {
            let img = self.generateAlphaGradientImg(size: size, list: data, max: max, min: min)
            self.replaceImageColor(paletteImg: paletteImg, paletteSize: paletteSize, img: img) {
                self.maskImageView.image = $0
                self.loadingView.stopAnimating()
            }
        }
    }
    
    private func getReplaceColor(position: Int, data: UnsafePointer<UInt8>) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        let pixelInfo: Int = position * bytesPerPixel
        
        let r = data[pixelInfo]
        let g = data[pixelInfo + 1]
        let b = data[pixelInfo + 2]
        let a = data[pixelInfo + 3]
        
        return (r, g, b, a)
    }
    
    private func generateAlphaGradientImg(size: CGSize, list: [JoHeatValue], max: CGFloat, min: CGFloat) -> UIImage {
        let render = UIGraphicsImageRenderer(size: size)
        var count = 0
        let png = render.pngData { ctx in
            for heatData in list {
                count += 1
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
        
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let width = img.cgImage!.width
        let height = img.cgImage!.height
        
        
        let bitsPerPixel = bytesPerPixel * bitsPerComponent;
        let rawData = UnsafeMutablePointer<UInt8>.allocate(capacity: bytesPerPixel * width * height)
        
        var count = 0
        for y in 0..<height {
            for x in 0..<width {
                count += 1
                let pixelInfo = (width * y + x) * bytesPerPixel
                
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

// MARK: - GPU render
extension JoHeatChart {
    
    private func generateVertices(value: CGFloat, center: CGPoint, radius: CGFloat) -> JoVertexIndexModel {
        let alpha = Float((value - self.minValue) / (self.maxValue - self.minValue))
        
        var vertices: [JoVertexIn] = [JoVertexIn(position: vector_float2(Float(center.x), Float(center.y)), color: [0, 0, 0, alpha])]
        var indexes: [UInt32] = []
        for i in 1...CircleDivideCount {
            let radian: Float = Float.pi * 2 * Float(i - 1) / Float(CircleDivideCount)
            let position: vector_float2 = [
                Float(center.x) + Float(radius) * sin(radian),
                Float(center.y) + Float(radius) * cos(radian)
            ]
            let v = JoVertexIn(position: position, color: [0, 0, 0, 0])
            vertices.append(v)
            if i > 1 {
                indexes += [0, UInt32(i - 1), UInt32(i)]
            }
        }
        indexes += [0, UInt32(CircleDivideCount), 1]
        return JoVertexIndexModel(vertices: vertices, indexes: indexes)
    }
    
    private func drawChartWithGPU() throws {

        guard let device = MTLCreateSystemDefaultDevice() else {
            throw JoChartErr.ErrFindGPUDevice
        }
        
        let library = try device.makeLibrary(source: shaderString, options: nil)
        
        guard let queue = device.makeCommandQueue() else {
            throw JoChartErr.ErrCreateCommandQueue
        }
        
        mDevice = device
        commandQueue = queue
        
        let vertexFunc = library.makeFunction(name: "jo_vertex_main")
        let fragmentFunc = library.makeFunction(name: "jo_fragment_main")
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "joRenderPipeline"
        descriptor.vertexFunction = vertexFunc
        descriptor.fragmentFunction = fragmentFunc
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        guard let computeFunc = library.makeFunction(name: "jo_compute_main") else {
            throw JoChartErr.ErrCreateComputeFunction

        }
        
        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
            computePipelineState = try device.makeComputePipelineState(function: computeFunc)
        } catch let e {
            throw e
        }
        
        
        let paletteSize = CGSize(width: 255, height: 2)
        let paletteImg = renderPalette(size: paletteSize)
        
        let spriteImage = paletteImg.cgImage!
        let width = spriteImage.width
        let height = spriteImage.height
        
        
        guard let data = calloc(width * height * bytesPerPixel, MemoryLayout<UInt8>.size),
            let context = CGContext.init(data: data, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: width * bytesPerPixel, space: spriteImage.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                fatalError()
        }
        
        context.draw(spriteImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .rgba8Unorm
        textureDescriptor.width = width
        textureDescriptor.height = height
        textureDescriptor.usage = .shaderRead
        paletteTexture = mDevice.makeTexture(descriptor: textureDescriptor)
        
        paletteTexture.replace(region: MTLRegion(origin: .init(x: 0, y: 0, z: 0), size: .init(width: width, height: height, depth: 1)), mipmapLevel: 0, withBytes: data, bytesPerRow: width * bytesPerPixel)
        
        free(data)
        
        try render()
    }
    
    private func render() throws {
        
        let outputDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: Int(viewPortSize.x), height: Int(viewPortSize.y), mipmapped: false)
        outputDesc.usage = [.renderTarget, .shaderRead]
        
        guard let texture = mDevice.makeTexture(descriptor: outputDesc) else {
            throw JoChartErr.ErrCreateTexture
        }
        
        let pixels = UnsafeMutablePointer<UInt8>.allocate(capacity: outputDesc.width * outputDesc.height * bytesPerPixel)
        //        let pixels2 = UnsafeMutableRawPointer.allocate(byteCount: outputDesc.width * outputDesc.height * 4, alignment: 1)
        memset(pixels, 1, MemoryLayout.size(ofValue: pixels))
        let region = MTLRegionMake2D(0, 0, outputDesc.width, outputDesc.height)
        texture.replace(region: region, mipmapLevel: 0, withBytes: pixels, bytesPerRow: outputDesc.width * bytesPerPixel)
        
        pixels.deallocate()
        
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 2, blue: 3, alpha: 4)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            throw JoChartErr.ErrCreateComputeBuffer
        }
        
        let blockSema = inFlightSemaphore
        
        commandBuffer.addCompletedHandler { buffer in
            blockSema.signal()
        }
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            throw JoChartErr.ErrCreateCommandEncoder
        }
        
        // render
        
        renderEncoder.label = "circle render"
        
        renderEncoder.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(viewPortSize.x), height: Double(viewPortSize.y), znear: 0, zfar: 1))
        renderEncoder.setRenderPipelineState(renderPipelineState)
        
        for data in mData {
            renderEncoder.setVertexBytes(data.vertices, length: MemoryLayout<JoVertexIn>.size * data.vertices.count, index: 0)
            
            renderEncoder.setVertexBytes(&viewPortSize, length: MemoryLayout.size(ofValue: viewPortSize), index: 1)
            
            guard let indexBuffer = mDevice.makeBuffer(bytes: data.indexes, length: MemoryLayout<UInt32>.size * data.indexes.count, options: .storageModeShared) else {
                throw JoChartErr.ErrCreateCommandIndexBuffer
            }
            
            renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: data.indexes.count, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0, instanceCount: 1)
        }
        
        renderEncoder.endEncoding()
        
        commandBuffer.commit()
        
        let _ = blockSema.wait(timeout: .distantFuture)
        
        try compute(texture: texture)
    }
    
    private func compute(texture: MTLTexture) throws {
        let width = texture.width
        let height = texture.height
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .bgra8Unorm
        textureDescriptor.width = width
        textureDescriptor.height = height
        textureDescriptor.usage = [.shaderWrite, .shaderRead]
        guard let destTexture = mDevice.makeTexture(descriptor: textureDescriptor) else {
            throw JoChartErr.ErrCreateTexture
        }
        
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
            let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
                throw JoChartErr.ErrCreateComputeBuffer
        }
        
        let blockSema = inFlightSemaphore
        
        commandBuffer.addCompletedHandler { buffer in
            blockSema.signal()
        }
        
        computeEncoder.setComputePipelineState(computePipelineState)
        
        computeEncoder.setTexture(texture, index: 0)
        computeEncoder.setTexture(destTexture, index: 1)
        computeEncoder.setTexture(paletteTexture, index: 2)
        
        let maxThread = computePipelineState.maxTotalThreadsPerThreadgroup
        let a = Int(sqrt(Double(maxThread)))
        let groupSize = MTLSizeMake(a, a, 1)
        
        let gridSize = MTLSizeMake(width, height, 1)
        
        computeEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: groupSize)
        
        computeEncoder.endEncoding()
        
        commandBuffer.commit()
        
        let _ = blockSema.wait(timeout: .distantFuture)
        
        afterCompute(texture: destTexture)
    }
    
    private func afterCompute(texture: MTLTexture) {
        let width = texture.width
        let height = texture.height
        
        let bitsPerPixel = bytesPerPixel * bitsPerComponent
        
        
        let pixels = UnsafeMutablePointer<UInt8>.allocate(capacity: width * height * bytesPerPixel)
        memset(pixels, 2, MemoryLayout.size(ofValue: pixels))
        
        let region = MTLRegionMake2D(0, 0, width, height)
        let bytesPerRow = MemoryLayout<UInt8>.size * bytesPerPixel * width
        texture.getBytes(pixels, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        let cfData = CFDataCreate(kCFAllocatorDefault, pixels, bytesPerPixel * width * height)
        let provider: CGDataProvider = CGDataProvider.init(data: cfData!)!
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let imageRef = CGImage.init(width: width, height: height, bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: bytesPerPixel * width, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        
        pixels.deallocate()
        
        if let imageRef = imageRef {
            let scale = UIScreen.main.scale
            let image = UIImage.init(cgImage: imageRef, scale: scale, orientation: .up)
            DispatchQueue.main.async {
                self.maskImageView.image = image
                self.loadingView.stopAnimating()
            }
        } else {
            DispatchQueue.main.async {
                self.loadingView.stopAnimating()
            }
        }
    }
    
}

public struct JoHeatValue {
    
    /// UIView的坐标系
    public var location: CGPoint
    public var value: CGFloat
    public var radius: CGFloat
    
    
    /// - Parameters:
    ///   - value: 数据的值
    ///   - location: 数据在图中的位置，UIView的坐标系，左上角为{0, 0}
    ///   - radius: 数据在图中的影响范围
    public init(value: CGFloat, location: CGPoint, radius: CGFloat) {
        self.location = location
        self.value = value
        self.radius = radius
    }
}

/// 与**JoChartShaders.metal**中的**JoVertexIn**保持一致
struct JoVertexIn {
    var position: vector_float2
    var color: vector_float4
}

struct JoVertexIndexModel {
    let vertices: [JoVertexIn]
    let indexes: [UInt32]
}


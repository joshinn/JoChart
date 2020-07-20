//
//  JoChartShaders.metal
//  JoChart
//
//  Created by jojo on 2020/7/20.
//  Copyright © 2020 joshin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct RasterizerData {
    vector_float4 position [[position]];
    vector_float4 color;
};

struct JoVertexIn {
    vector_float2 position;
    vector_float4 color;
};

vertex RasterizerData jo_vertex_main(uint vId [[vertex_id]],
                              constant JoVertexIn *in [[buffer(0)]],
                              constant vector_uint2 *viewportSizePointer [[buffer(1)]]) {
    RasterizerData out;
    
    float2 pixelSpacePosition = in[vId].position.xy;
    vector_float2 viewportSize = vector_float2(*viewportSizePointer);
    
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = pixelSpacePosition / (viewportSize / 2.0);
    
    out.color = in[vId].color;
    
    return out;
}

fragment float4 jo_fragment_main(RasterizerData in [[stage_in]]) {
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

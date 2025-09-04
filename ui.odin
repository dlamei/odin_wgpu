package wgpu_test

import "vendor:wgpu"

Vec2 :: distinct [2]f32
Vec3 :: distinct [3]f32
Mat4 :: matrix[4, 4]f32

RGBA :: [4]f32


UiVertex :: struct {
    pos: Vec2,
    col: RGBA,
}

UiGlobal :: struct {
    proj: Mat4,
}

Shader :: struct {
    layout: wgpu.PipelineLayout,
    pipeline: wgpu.RenderPipeline,
}

global_shaders: struct {
    ui: Shader,
}

build_glob_shaders :: proc() {
    global_shaders.ui = build_ui_shader()
}

free_glob_shaders :: proc() {
    free_shader(global_shaders.ui)
}

free_shader :: proc(shader: Shader) {
    wgpu.RenderPipelineRelease(shader.pipeline)
    wgpu.PipelineLayoutRelease(shader.layout)
}

path_from_points :: proc(points: []Vec2, closed: bool = false) {
    col: RGBA = {1,2, 3, 4}
}


@(private="file")
build_ui_shader :: proc() -> Shader {
    shader ::
    `
    struct Vertex {
        @location(0) pos: vec2<f32>,
        @location(1) col: vec4<f32>,
    }

    struct GlobalUniform {
        proj: mat4x4<f32>,
    }

    // @group(0) @binding(0)
    // var<uniform> global: GlobalUniform;

    struct VSOut {
        @builtin(position) pos: vec4<f32>,
        @location(0) color: vec4<f32>,
    };

    @vertex
    fn vs_main(
        v: Vertex,
    ) -> VSOut {
        var out: VSOut;
        out.color = v.col;
        // out.pos = global.proj * vec4(v.pos, 0.0, 1.0);
        out.pos = vec4(v.pos, 0.0, 1.0);

        return out;
    }


    @fragment
    fn fs_main(in: VSOut) -> @location(0) vec4<f32> {
        return in.color;
    }
    `

    layout := wgpu.DeviceCreateBindGroupLayout(state.device, &{
        entryCount = 1,
        entries = raw_data([]wgpu.BindGroupLayoutEntry {
            {
                binding = 0,
                visibility = { .Vertex, .Fragment },
                buffer = {
                    type = .Uniform,
                    minBindingSize = size_of(Mat4),
                },
            }
        })
        
    })

    // wgpu.DeviceCreateBindGroup(state.device, &{
    //     layout = layout,
    //     entryCount = 1,
    //     entries: raw_data([]wgpu.BindGroupEntry {
    //     })
    // })

    module := wgpu.DeviceCreateShaderModule(state.device, &{
        nextInChain = &wgpu.ShaderSourceWGSL {
            sType = .ShaderSourceWGSL,
            code = shader,
        },
    })

    pipeline_layout := wgpu.DeviceCreatePipelineLayout(state.device, &{})
    pipeline := wgpu.DeviceCreateRenderPipeline(state.device, &{
        layout = pipeline_layout,
        vertex = {
            module     = module,
            entryPoint = "vs_main",
        },
        fragment = &{
            module      = module,
            entryPoint  = "fs_main",
            targetCount = 1,
            targets     = &wgpu.ColorTargetState{
                format    = .BGRA8Unorm,
                writeMask = wgpu.ColorWriteMaskFlags_All,
            },
        },
        primitive = {
            topology = .TriangleList,

        },
        multisample = {
            count = 1,
            mask  = 0xFFFFFFFF,
        },
    })

    return { pipeline_layout, pipeline }
}

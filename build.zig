const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "VulkanMemoryAllocator",
        .target = target,
        .optimize = optimize,
    });

    lib.addIncludePath(.{ .path = "include" });
    lib.addCSourceFiles(&.{
        "src/VmaUsage.cpp",
    }, &.{});
    lib.linkLibC();
    lib.linkLibCpp();
    lib.linkSystemLibrary("vulkan");

    lib.installHeader("include/vk_mem_alloc.h", "vk_mem_alloc.h");
    b.installArtifact(lib);
}

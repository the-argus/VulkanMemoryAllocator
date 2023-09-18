const std = @import("std");

/// Build the VulkanMemoryAllocator library in your build graph and return it.
/// Does NOT install the headers needed to actually use the library- also call
/// buildHeaders for that.
pub fn buildLibrary(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.Mode) *std.Build.Step.Compile {
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

    return lib;
}

// Adds InstallFile steps to your build graph and returns a slice of pointers to
// all of these steps.
// NOTE: this will not add the install steps to your build graph, you must do
// that yourself (see the build function in this file). I believe this is an
// issue with zig because addInstallHeaderFile *should* add to your build graph
pub fn buildHeaders(b: *std.Build) []*std.Build.Step.InstallFile {
    var installs = std.ArrayList(*std.Build.Step.InstallFile).init(b.allocator);
    const vk_mem_alloc = b.addInstallHeaderFile("include/vk_mem_alloc.h", "vk_mem_alloc.h");
    installs.append(vk_mem_alloc) catch @panic("OOM");
    return installs.toOwnedSlice() catch @panic("OOM");
}

/// Build function which by default is only header-only
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    _ = target;
    _ = optimize;
    for (buildHeaders(b)) |*install_file| {
        b.getInstallStep().dependOn(&install_file.*.step);
    }
}

/// Example of how you might use this library, either as header-only or with
/// the static lib
fn exampleUsage(b: *std.Build) void {
    // imagine that we're not in the VulkanMemoryAllocator project right now,
    // instead we are in your downstream project

    // you have an exe
    const exe = b.addExecutable(.{
        // executable options...
    });

    const submodules = false;
    var vma: ?*std.Build.Dependency = null;

    // UNCOMMENT THE NEXT TWO LINES IF YOU WANT TO USE THE STATIC LIB
    // const target = b.standardTargetOptions(.{});
    // const optimize = b.standardOptimizeOption(.{});

    if (submodules) {
        // import VMA with submodules, assuming you have it in a submodule right
        // next to your build.zig, and the submodule is called VulkanMemoryAllocator

        // UNCOMMENT THIS (will not compile in this example because the example
        // path to the VMA build.zig doesn't exist for us)
        // vma = b.anonymousDependency("VulkanMemoryAllocator", @import("VulkanMemoryAllocator/build.zig"), .{});
    } else {
        // OR with build.zig.zon, assuming you called it vulkan_memory_allocator
        vma = b.dependency("vulkan_memory_allocator", .{});
        // UNCOMMENT THE NEXT THREE LINES IF YOU WANT TO INSTALL THE STATIC LIB
        // const vma_build_zig = @import("vulkan_memory_allocator");
        // var vma_lib = vma_build_zig.buildLibrary(b, target, optimize);
        // exe.linkLibrary(vma_lib);
    }
    // add the VMA installation step to our build graph, so building the exe
    // will also build and install VMA headers
    exe.step.dependOn(vma.?.builder.getInstallStep());
    // add the installation path of VMA to our include directories
    exe.addIncludePath(.{ .path = vma.?.builder.install_path });
}

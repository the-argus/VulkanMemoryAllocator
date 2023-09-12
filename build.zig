const std = @import("std");

pub fn build(b: *std.Build) void {
    b.installFile("include/vk_mem_alloc.h", "include/vk_mem_alloc.h");
}

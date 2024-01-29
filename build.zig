const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "manymouse",
        .target = target,
        .optimize = optimize,
    });

    lib.addCSourceFiles(.{ .files = &shared_sources });

    if (target.getOsTag() == .macos) {
        lib.linkFrameworkNeeded("IOKit");
        lib.addCSourceFiles(.{ .files = &macos_sources });
    }
    if (target.isLinux() or target.getOsTag().isBSD()) {
        lib.linkLibC();
        lib.addCSourceFiles(.{ .files = &linux_sources });

        const x11 = b.dependency("x11-headers", .{}).artifact("x11-headers");
        lib.linkLibrary(x11);
    }
    if (target.isWindows()) {
        lib.linkLibC();
        lib.addCSourceFiles(.{ .files = &windows_sources });
    }

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);
    lib.installHeader("manymouse.h", "manymouse.h");
}

const shared_sources = [_][]const u8{
    "manymouse.c",
};

const windows_sources = [_][]const u8{
    "windows_wminput.c",
};

const macos_sources = [_][]const u8{
    "macosx_hidmanager.c",
    "macosx_hidutilities.c",
};

const linux_sources = [_][]const u8{
    "x11_xinput2.c",
    "linux_evdev.c",
};

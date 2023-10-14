const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // run 
    const main = b.addExecutable(.{
        .name = "zig0.12", 
        .root_source_file = .{ .path = "src/main.zig" }, 
        .target = target, 
        .optimize = optimize, 
    });
    b.installArtifact(main);

    const core_module = b.addModule("matrix", 
        std.Build.CreateModuleOptions {
            .source_file = std.Build.LazyPath { .path = "src/matrix.zig" }, 
        }
    ); 

    const main2 = b.addExecutable(.{
        .name = "zig0.12", 
        .root_source_file = .{ .path = "src/bin/main2.zig" }, 
        .target = target, 
        .optimize = optimize, 
    }); 
    b.installArtifact(main2); 
    main2.addModule("matrix", core_module);

    const main3 = b.addExecutable( std.Build.ExecutableOptions {
        .name = "1", 
        .root_source_file = .{ .path = "src/bin/main3.zig" }, 
        .target = target, 
        .optimize = optimize, 
    }); 
    main3.addModule("matrix", core_module); 

    const cm = b.addModule("matrix2", .{ .source_file = .{ .path = "src/main.zig" } }); 

    const main4 = b.addExecutable( std.Build.ExecutableOptions {
        .name = "2", 
        .root_source_file = .{ .path = "src/bin/main4.zig" }, 
        .target = target, 
        .optimize = optimize, 
    }); 
    main4.addModule("matrix", cm); 

    const main3_step = b.step("main3", "Run main3"); 
    main3_step.dependOn(&b.addRunArtifact(main3).step); 

    const m4s = b.step("main4", ""); 
    m4s.dependOn(&b.addRunArtifact(main4).step); 

    const run_main_tests = b.addRunArtifact(main_tests);
    const run_main = b.addRunArtifact(main); 
    const run_main2 = b.addRunArtifact(main2);

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build test`
    // This will evaluate the `test` step rather than the default, which is "install".
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);

    const main_step = b.step("main", "Run main"); 
    main_step.dependOn(&run_main.step); 

    const main2_step = b.step("main2", "Run main2"); 
    main2_step.dependOn(&run_main2.step); 
}

const std = @import("std");
const GitRepoStep = @import("GitRepoStep.zig");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const zigx = GitRepoStep.create(b, .{
        .url = "https://github.com/marler8997/zigx",
        .branch = null,
        .sha = "5a46e3ee7956739dc678efd82e4fe04b4d349cd2",
    });
    
    const bog = GitRepoStep.create(b, .{
        //.url = "https://github.com/vexu/bog",
        .url = "https://github.com/marler8997/bog",
        .branch = null,
        .sha = "2462287a0cd26d244418a6018fb628a070ae4ec5",
    });
    
    {
        const exe = b.addExecutable("x11graphics", "x11graphics.zig");
        exe.setTarget(target);
        exe.setBuildMode(mode);
        exe.install();

        exe.step.dependOn(&zigx.step);
        exe.addPackagePath("x", b.pathJoin(&.{ zigx.getPath(&exe.step), "x.zig" }));
        exe.step.dependOn(&bog.step);
        exe.addPackagePath("bog", b.pathJoin(&.{ bog.getPath(&exe.step), "src", "bog.zig" }));
        
        const run_cmd = exe.run();
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);
    }
}

const std = @import("std");
const x = @import("x");
const bog = @import("bog");

pub fn main() !void {
    std.log.info("running bog example", .{});
    try bogExample(
        \\let b = []
        \\for 0:2
        \\    let mut a = 1
        \\    b.append(a)
        \\    a += 1
        \\return b
    );
}

fn bogExample(source: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();

    var vm = bog.Vm.init(alloc, .{});
    var mod = bog.compile(alloc, source, "<test buf>", &vm.errors) catch |e| switch (e) {
        else => return e,
        error.TokenizeError, error.ParseError, error.CompileError => {
            vm.errors.render(std.io.getStdErr().writer()) catch {};
            return error.TestFailed;
        },
    };
    mod.debug_info.source = "";
    defer mod.deinit(alloc);
    defer vm.deinit();
    vm.addStd() catch unreachable;

    var frame = bog.Vm.Frame{
        .mod = &mod,
        .body = mod.main,
        .caller_frame = null,
        .module_frame = undefined,
        .captures = &.{},
        .params = 0,
    };
    defer frame.deinit(&vm);
    frame.module_frame = &frame;

    vm.gc.stack_protect_start = @frameAddress();

    var frame_val = try vm.gc.alloc(.frame);
    frame_val.* = .{ .frame = &frame };
    defer frame_val.* = .{ .int = 0 }; // clear frame

    const res = vm.run(&frame) catch |e| switch (e) {
        else => return e,
        error.FatalError => {
            vm.errors.render(std.io.getStdErr().writer()) catch {};
            return error.TestFailed;
        },
    };

    var out_buf = std.ArrayList(u8).init(alloc);
    defer out_buf.deinit();
    try res.dump(out_buf.writer(), 2);
    //try testing.expectEqualStrings(expected, out_buf.items);
    std.log.info("bog output is '{s}'", .{out_buf.items});
}

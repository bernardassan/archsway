const std = @import("std");
const log = std.log.scoped(.toBin);

pub fn main(init: std.process.Init) !void {
    const arena_alloc = init.arena;
    const args =
        try init.minimal.args.toSlice(arena_alloc.allocator());

    if (args.len < 2) {
        log.err("hex or binary argument require .eg 0xCAFEBABE", .{});
        std.process.exit(1);
    }
    const value = args[1];
    const hex = if (std.mem.eql(u8, value[0..2], "0x"))
        try std.fmt.parseInt(u64, value[2..], 16)
    else if (std.mem.eql(u8, value[0..2], "0b"))
        try std.fmt.parseInt(u64, value[2..], 2)
    else
        try std.fmt.parseInt(u64, value[0..], 10);

    log.info("bin:         0x{X} <=> 0b{b}", .{ hex, hex });
    log.info("bin reverse: 0x{X} <=> 0b{b}", .{
        hex,
        @bitReverse(hex) >> @intCast(@clz(hex)),
    });
}

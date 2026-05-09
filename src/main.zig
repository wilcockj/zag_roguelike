const std = @import("std");
const Io = std.Io;
const rl = @import("raylib");

const zag_roguelike = @import("zag_roguelike");

pub fn main(init: std.process.Init) !void {
    _ = init;
    rl.initWindow(800, 450, "game");

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.getColor(0x181818ff));
        rl.drawText("hello zag", 0, 0, 12, .white);
    }
}

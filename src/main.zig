const std = @import("std");
const Io = std.Io;
const rl = @import("raylib");
const card = @import("card.zig");

const zag_roguelike = @import("zag_roguelike");

pub fn main(init: std.process.Init) !void {
    _ = init;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var cards: std.ArrayList(card.Card) = .empty;
    defer cards.deinit(allocator);

    const rect = rl.Rectangle.init(10, 10, 300, 200);
    try cards.append(allocator, card.Card.init("test", rect));

    rl.initWindow(800, 450, "game");

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.getColor(0x181818ff));
        rl.drawText("hello zag", 0, 0, 12, .white);

        for (cards.items) |c| {
            c.draw();
        }
    }
}

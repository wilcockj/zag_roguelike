const std = @import("std");
const Io = std.Io;
const rl = @import("raylib");
const card = @import("card.zig");

const zag_roguelike = @import("zag_roguelike");

const State = enum {
    menu,
    running,
};

const Game = struct {
    allocator: std.mem.Allocator,
    state: State,
    cards: std.ArrayList(card.Card),

    pub fn init(allocator: std.mem.Allocator) Game {
        return Game{
            .allocator = allocator,
            .state = .menu,
            .cards = .empty,
        };
    }

    pub fn deinit(self: *Game) void {
        self.cards.deinit(self.allocator);
    }
};

pub fn main(init: std.process.Init) !void {
    _ = init;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var game = Game.init(allocator);
    defer game.deinit();

    rl.initWindow(800, 450, "game");

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.getColor(0x181818ff));
        rl.drawText("hello zag", 0, 0, 12, .white);

        for (game.cards.items) |c| {
            c.draw();
        }
    }
}

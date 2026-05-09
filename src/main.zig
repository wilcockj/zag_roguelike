const std = @import("std");
const Io = std.Io;
const rl = @import("raylib");
const rg = @import("raygui");
const card = @import("card.zig");

const zag_roguelike = @import("zag_roguelike");

const State = enum {
    menu,
    running,
    paused,
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

    pub fn draw(self: *Game) void {
        for (self.cards.items) |c| {
            c.draw();
        }
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
    rl.setExitKey(.null);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.getColor(0x181818ff));
        switch (game.state) {
            .menu => {
                if (rg.button(rl.Rectangle.init(10, 10, 150, 50), "start")) game.state = .running;
                if (rg.button(rl.Rectangle.init(10, 70, 150, 50), "quit")) break;
            },
            .running => {
                if (rl.isKeyPressed(.escape)) game.state = .paused;
                game.draw();
            },
            .paused => {
                if (rg.button(rl.Rectangle.init(10, 10, 150, 50), "resume")) game.state = .running;
                if (rg.button(rl.Rectangle.init(10, 70, 150, 50), "menu")) game.state = .menu;
            },
        }
    }
}

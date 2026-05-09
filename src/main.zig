const std = @import("std");
const Io = std.Io;
const rl = @import("raylib");
const rg = @import("raygui");
const card = @import("card.zig");
const enemy = @import("enemies.zig");

const zag_roguelike = @import("zag_roguelike");

const window_w = 800;
const window_h = 450;

const State = enum {
    menu,
    running,
    paused,
};

const Game = struct {
    allocator: std.mem.Allocator,
    state: State,
    cards: std.ArrayList(card.Card),
    card_pool: std.ArrayList(card.Card),
    enemies: std.ArrayList(enemy.Enemy),
    enemy_count: usize = 0,
    rand: std.Random,

    spawn_cooldown: f32 = 2.0,
    spawn_timer: f32 = 2.0,
    pub fn init(allocator: std.mem.Allocator, rand: std.Random) !Game {
        var game = Game{
            .allocator = allocator,
            .state = .menu,
            .cards = .empty,
            .card_pool = .empty,
            .enemies = .empty,
            .rand = rand,
        };

        try game.card_pool.append(allocator, card.Card.init(allocator, "pull tha plug", .attack, 100, 10));
        try game.card_pool.append(allocator, card.Card.init(allocator, "ping", .attack, 5, 1));
        try game.card_pool.append(allocator, card.Card.init(allocator, "ddoss", .attack, 1, 0.1));

        return game;
    }

    pub fn deinit(self: *Game) void {
        self.cards.deinit(self.allocator);
    }

    pub fn draw(self: *Game) !void {
        for (self.enemies.items) |e| {
            e.draw();
        }

        for (self.cards.items, 0..) |c, i| {
            const pad = 5;
            try c.draw(rl.Vector2.init(@floatFromInt(pad + (card.CARD_W + pad) * i), window_h - card.CARD_H - pad));
        }
    }

    pub fn update(self: *Game, dt: f32) !void {
        for (self.cards.items) |*c| {
            if (c.update_cooldown(dt)) {
                if (c.kind == .attack) {
                    const center: rl.Vector2 = .init(@floatFromInt(@divTrunc(rl.getScreenWidth(), 2)), @floatFromInt(@divTrunc(rl.getScreenHeight(), 2)));

                    var idx: i32 = -1;
                    var distance: f32 = std.math.floatMax(f32);
                    for (self.enemies.items, 0..) |e, i| {
                        const d = center.distance(e.pos);
                        if (d < distance) {
                            distance = d;
                            idx = @intCast(i);
                        }
                    }

                    if (idx >= 0) {}
                }
            }
        }

        if (self.state == .running) {
            self.spawn_timer -= dt;
            if (self.spawn_timer < 0.0) {
                try self.spawn_enemy();
                self.spawn_timer = self.spawn_cooldown;
            }
            for (self.enemies.items) |*e| {
                const width: f32 = @as(f32, @floatFromInt(rl.getScreenWidth()));
                const height: f32 = @as(f32, @floatFromInt(rl.getScreenHeight()));
                const center = rl.Vector2.init(@divFloor(width, 2), @divFloor(height, 2));
                e.move_towards(center, dt);
            }
        }
    }

    pub fn spawn_enemy(self: *Game) !void {
        try self.enemies.append(self.allocator, enemy.Enemy.spawn(self.enemy_count, .red, self.rand));
        self.enemy_count += 1;
    }
};

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // why can't i do init(100).random() ??
    const timestamp = std.Io.Clock.real.now(init.io);
    var prng = std.Random.Xoroshiro128.init(@intCast(std.Io.Timestamp.toMilliseconds(timestamp)));
    const rand: std.Random = prng.random();

    var game = try Game.init(allocator, rand);
    defer game.deinit();

    for (0..5) |_| {
        const idx = rand.uintLessThan(u32, @intCast(game.card_pool.items.len));
        try game.cards.append(allocator, game.card_pool.items[idx]);
    }

    rl.initWindow(window_w, window_h, "game");
    rl.setExitKey(.null);
    rl.setTargetFPS(120);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        const dt = rl.getFrameTime();

        try game.update(dt);

        rl.clearBackground(rl.getColor(0x181818ff));
        switch (game.state) {
            .menu => {
                if (rg.button(rl.Rectangle.init(10, 10, 150, 50), "start")) game.state = .running;
                if (rg.button(rl.Rectangle.init(10, 70, 150, 50), "quit")) break;
            },
            .running => {
                if (rl.isKeyPressed(.escape)) game.state = .paused;
                try game.draw();
                rl.drawFPS(0, 0);
            },
            .paused => {
                if (rg.button(rl.Rectangle.init(10, 10, 150, 50), "resume")) game.state = .running;
                if (rg.button(rl.Rectangle.init(10, 70, 150, 50), "menu")) game.state = .menu;
                if (rg.button(rl.Rectangle.init(10, 130, 150, 50), "quit")) break;
            },
        }
    }
}

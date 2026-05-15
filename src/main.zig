const std = @import("std");
const Io = std.Io;
const rl = @import("raylib");
const rg = @import("raygui");
const card = @import("card.zig");
const enemy = @import("enemies.zig");
const particle = @import("particle.zig");

const zag_roguelike = @import("zag_roguelike");

const window_w = 800;
const window_h = 450;

const State = enum {
    menu,
    running,
    choose_card,
    paused,
    settings,
};

const Game = struct {
    const starting_cooldown: f32 = 5.0;
    const upgrade_scale: f32 = 1.8;
    allocator: std.mem.Allocator,
    state: State,
    cards: std.ArrayList(card.Card),
    card_pool: std.ArrayList(card.Card),
    enemies: std.ArrayList(enemy.Enemy),
    enemy_count: usize = 0,
    rand: std.Random,
    spawn_cooldown: f32 = starting_cooldown,
    spawn_timer: f32 = starting_cooldown,
    kills: usize = 0,
    kills_upgrade_thresh: f32 = 5.0,
    card_options: [3]card.Card = .{ undefined, undefined, undefined },
    return_state: State = .menu,
    particles: std.ArrayList(particle.Particle),
    io: Io,

    pub fn pick3(self: *Game) void {
        for (0..3) |i| {
            const idx = self.rand.uintLessThan(u32, @intCast(self.card_pool.items.len));
            self.card_options[i] = self.card_pool.items[@intCast(idx)];
        }
    }

    pub fn init(allocator: std.mem.Allocator, rand: std.Random, io: Io) !Game {
        var game = Game{
            .allocator = allocator,
            .state = .menu,
            .cards = .empty,
            .card_pool = .empty,
            .enemies = .empty,
            .particles = .empty,
            .rand = rand,
            .io = io,
        };

        try game.card_pool.append(allocator, card.Card.init(allocator, "pull tha plug", .attack, 100, 10));
        try game.card_pool.append(allocator, card.Card.init(allocator, "ping", .attack, 5, 1));
        try game.card_pool.append(allocator, card.Card.init(allocator, "ddoss", .attack, 1, 0.1));

        // scale the spawn cooldown
        if (game.cards.items.len > 0) {
            game.spawn_cooldown = starting_cooldown / @as(f32, @floatFromInt(game.cards.items.len));
        }
        return game;
    }

    pub fn deinit(self: *Game) void {
        self.cards.deinit(self.allocator);
    }

    pub fn draw(self: *Game) !void {
        for (self.enemies.items) |e| {
            e.draw();
        }

        for (self.particles.items) |p| {
            const time = std.Io.Timestamp.toMilliseconds(std.Io.Clock.real.now(self.io));
            p.draw(time);
        }

        for (self.cards.items, 0..) |c, i| {
            const pad = 5;
            _ = try c.draw(rl.Vector2.init(@floatFromInt(pad + (card.CARD_W + pad) * i), window_h - card.CARD_H - pad));
        }

        const kill_txt = try std.fmt.allocPrintSentinel(self.allocator, "Kills: {d}", .{self.kills}, 0);
        const font_size = 20;
        rl.drawText(kill_txt, @divTrunc((window_w - rl.measureText(kill_txt, font_size)), 2), 5, font_size, .red);
    }

    pub fn update(self: *Game, dt: f32) !void {
        if (@as(f32, @floatFromInt(self.kills)) > self.kills_upgrade_thresh) {
            self.state = .choose_card;
            self.kills_upgrade_thresh *= upgrade_scale;
            return;
        }
        for (self.cards.items) |*c| {
            if (c.update_cooldown(dt)) {
                if (c.kind == .attack) {
                    const center: rl.Vector2 = .init(window_w / 2, window_h / 2);

                    var idx: i32 = -1;
                    var distance: f32 = std.math.floatMax(f32);
                    for (self.enemies.items, 0..) |e, i| {
                        const d = center.distance(e.pos);
                        const on_screen = rl.checkCollisionPointRec(e.pos, rl.Rectangle.init(0, 0, window_w, window_h));
                        if (d < distance and e.alive and on_screen) {
                            distance = d;
                            idx = @intCast(i);
                        }
                    }

                    if (idx >= 0) {
                        const cur_enemy = self.enemies.items[@as(usize, @intCast(idx))];
                        // we are hurting the enemy
                        self.kills += if (self.enemies.items[@as(usize, @intCast(idx))].deal_damage(c.value)) 1 else 0;
                        // generate a particle
                        const time = std.Io.Timestamp.toMilliseconds(std.Io.Clock.real.now(self.io));
                        const zero_vec = rl.Vector2.init(0, 0);
                        const new_particle = particle.Particle.init_line(center, cur_enemy.pos, time, 200, zero_vec, .maroon);
                        try self.particles.append(self.allocator, new_particle);
                    }
                }
            }
        }

        // remove the dead enemies from the arraylist
        for (0..self.enemies.items.len) |_| {
            for (0..self.enemies.items.len) |idx| {
                if (!self.enemies.items[idx].alive) {
                    std.debug.print("Removing enemy {d} from list\n", .{self.enemies.items[idx].get_id()});
                    _ = self.enemies.swapRemove(idx);
                    break;
                }
            }
        }

        if (self.cards.items.len > 0) {
            // scale cooldown based on cards num
            self.spawn_cooldown = starting_cooldown / @as(f32, @floatFromInt(self.cards.items.len));
        }

        self.spawn_timer -= dt;
        if (self.spawn_timer < 0.0) {
            try self.spawn_enemy();
            self.spawn_timer = self.spawn_cooldown;
        }
        for (self.enemies.items) |*e| {
            const center = rl.Vector2.init(window_w / 2, window_h / 2);
            e.move_towards(center, dt);
        }

        // check for if particle is dead and remove
        const time = std.Io.Timestamp.toMilliseconds(std.Io.Clock.real.now(self.io));
        for (0..self.particles.items.len) |_| {
            for (0..self.particles.items.len) |idx| {
                const p = self.particles.items[idx];
                if (time - p.start_time > p.lifetime) {
                    // then remove particle
                    _ = self.particles.swapRemove(idx);
                    break;
                }
            }
        }
    }

    pub fn spawn_enemy(self: *Game) !void {
        try self.enemies.append(self.allocator, enemy.Enemy.spawn(self.enemy_count, .red, self.rand));
        self.enemy_count += 1;
    }
};

fn isWsl() bool {
    if (@import("builtin").os.tag != .linux) return false;
    const uname = std.posix.uname();
    const release = std.mem.sliceTo(&uname.release, 0);
    return std.mem.indexOf(u8, release, "microsoft") != null or
        std.mem.indexOf(u8, release, "WSL") != null;
}

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // why can't i do init(100).random() ??
    const timestamp = std.Io.Clock.real.now(init.io);
    var prng = std.Random.Xoroshiro128.init(@intCast(std.Io.Timestamp.toMilliseconds(timestamp)));
    const rand: std.Random = prng.random();

    var game = try Game.init(allocator, rand, init.io);
    defer game.deinit();

    // for (0..5) |_| {
    //     const idx = rand.uintLessThan(u32, @intCast(game.card_pool.items.len));
    //     try game.cards.append(allocator, game.card_pool.items[idx]);
    // }

    const wsl = isWsl();
    rl.setConfigFlags(.{ .window_hidden = wsl, .window_resizable = true });
    rl.initWindow(window_w, window_h, "game");
    if (wsl) {
        rl.setWindowPosition(100, 100);
        rl.clearWindowState(.{ .window_hidden = true });
    }
    rl.setExitKey(.null);
    rl.setTargetFPS(120);

    const target = try rl.loadRenderTexture(window_w, window_h);
    defer target.unload();

    while (!rl.windowShouldClose()) {
        const win_w_f: f32 = @floatFromInt(rl.getScreenWidth());
        const win_h_f: f32 = @floatFromInt(rl.getScreenHeight());
        const scale = @min(win_w_f / @as(f32, @floatFromInt(window_w)), win_h_f / @as(f32, @floatFromInt(window_h)));
        const dest_w = @as(f32, @floatFromInt(window_w)) * scale;
        const dest_h = @as(f32, @floatFromInt(window_h)) * scale;
        const dest_x = (win_w_f - dest_w) / 2;
        const dest_y = (win_h_f - dest_h) / 2;

        // remap mouse into internal coords so raygui hit-tests against the scaled texture
        rl.setMouseOffset(@intFromFloat(-dest_x), @intFromFloat(-dest_y));
        rl.setMouseScale(1.0 / scale, 1.0 / scale);

        rl.beginDrawing();
        defer rl.endDrawing();

        const dt = rl.getFrameTime();

        rl.beginTextureMode(target);
        rl.clearBackground(rl.getColor(0x181818ff));
        switch (game.state) {
            .menu => {
                if (rg.button(rl.Rectangle.init(10, 10, 150, 50), "start")) {
                    game.pick3();
                    game.state = .choose_card;
                }
                if (rg.button(rl.Rectangle.init(10, 70, 150, 50), "settings")) {
                    game.return_state = game.state;
                    game.state = .settings;
                }
                if (rg.button(rl.Rectangle.init(10, 130, 150, 50), "quit")) break;
            },
            .settings => {
                const fs_label = if (rl.isWindowFullscreen()) "fullscreen: on" else "fullscreen: off";
                if (rg.button(rl.Rectangle.init(10, 10, 150, 50), fs_label)) rl.toggleFullscreen();
                if (rg.button(rl.Rectangle.init(10, 70, 150, 50), "back")) game.state = game.return_state;
            },
            .choose_card => {
                try game.draw();
                rl.drawRectangle(0, 0, window_w, window_h, rl.getColor(0x18181899));
                rl.drawText("pick a card!", 20, 20, 40, .blue);
                for (game.card_options, 0..) |c, i| {
                    const pad = 5;
                    const clicked = try c.draw(rl.Vector2.init(@floatFromInt(pad + (card.CARD_W + pad) * i), window_h - card.CARD_H - pad));
                    if (clicked) {
                        try game.cards.append(game.allocator, game.card_options[i]);
                        game.state = .running;
                        break;
                    }
                }
            },
            .running => {
                if (rl.isKeyPressed(.escape)) game.state = .paused;
                try game.update(dt);
                try game.draw();
                rl.drawFPS(0, 0);
            },
            .paused => {
                try game.draw();
                rl.drawRectangle(0, 0, window_w, window_h, rl.getColor(0x18181899));
                if (rg.button(rl.Rectangle.init(10, 10, 150, 50), "resume")) game.state = .running;
                if (rg.button(rl.Rectangle.init(10, 70, 150, 50), "settings")) {
                    game.return_state = game.state;
                    game.state = .settings;
                }
                if (rg.button(rl.Rectangle.init(10, 130, 150, 50), "menu")) game.state = .menu;
                if (rg.button(rl.Rectangle.init(10, 190, 150, 50), "quit")) break;

                if (rl.isKeyPressed(.escape)) game.state = .running;
            },
        }
        rl.endTextureMode();

        rl.clearBackground(.black);
        rl.drawTexturePro(
            target.texture,
            rl.Rectangle.init(0, 0, @floatFromInt(target.texture.width), -@as(f32, @floatFromInt(target.texture.height))),
            rl.Rectangle.init(dest_x, dest_y, dest_w, dest_h),
            rl.Vector2.init(0, 0),
            0,
            .white,
        );
    }
}

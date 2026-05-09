const rl = @import("raylib");
const std = @import("std");

pub const Enemy = struct {
    pos: rl.Vector2,
    id: usize,
    birth_time: usize,
    color: rl.Color,

    pub fn spawn(id: usize, color: rl.Color, rand: std.Random) Enemy {
        // spawn the enemy outside of the screen
        const rand_scale = 100;
        const width: f32 = @floatFromInt(rl.getScreenWidth());
        const height: f32 = @floatFromInt(rl.getScreenHeight());
        const spawn_x_rand = (rand.float(f32) - 0.5);
        var spawn_x = spawn_x_rand * rand_scale;
        if (spawn_x_rand > 0.0) {
            spawn_x = width + spawn_x_rand * rand_scale;
        }

        const spawn_y_rand = (rand.float(f32) - 0.5);
        var spawn_y = spawn_y_rand * rand_scale;
        if (spawn_y_rand > 0.0) {
            spawn_y = height + spawn_y_rand * rand_scale;
        }

        std.debug.print("spawning enemy at {d}, {d}\n", .{ spawn_x, spawn_y });
        return Enemy{
            .pos = rl.Vector2.init(spawn_x, spawn_y),
            .id = id,
            .color = color,
            .birth_time = 0,
        };
    }

    pub fn draw(self: *Enemy) void {
        rl.drawRectangle(self.pos.x, self.pos.y, 10, 10);
    }
};

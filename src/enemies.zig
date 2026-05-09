const rl = @import("raylib");
const std = @import("std");

pub const Enemy = struct {
    pos: rl.Vector2,
    id: usize,
    color: rl.Color,
    alive: bool,
    velocity: f32,
    max_health: f32,
    health: f32,

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
        const health = 30.0 + rand.float(f32) * 40;
        return Enemy{
            .pos = rl.Vector2.init(spawn_x, spawn_y),
            .id = id,
            .color = color,
            .alive = true,
            .velocity = 30.0 * (rand.float(f32) + 0.25),
            .max_health = health,
            .health = health,
        };
    }

    pub fn draw(self: Enemy) void {
        // draw healthbar

        const line_y = rl.Vector2.add(self.pos, rl.Vector2.init(0, -5)).y;
        const health_percent = self.health / self.max_health;
        rl.drawLineEx(rl.Vector2.init(self.pos.x, line_y), rl.Vector2.init(self.pos.x + 10, line_y), 2.0, .dark_gray);
        rl.drawLineEx(rl.Vector2.init(self.pos.x, line_y), rl.Vector2.init(self.pos.x + 10 * health_percent, line_y), 2.0, .red);

        rl.drawRectangle(@intFromFloat(self.pos.x), @intFromFloat(self.pos.y), 10, 10, self.color);
    }

    pub fn move_towards(self: *Enemy, target: rl.Vector2, deltatime: f32) void {
        // move towards this target based on velocity

        //std.debug.print("started at {d},{d}\n", .{ self.pos.x, self.pos.y });
        // get vector from current location to target
        const vec = rl.Vector2.normalize(rl.Vector2.subtract(target, self.pos));
        self.pos = rl.Vector2.add(self.pos, rl.Vector2.scale(vec, deltatime * self.velocity));
        //std.debug.print("ended at {d},{d}\n", .{ self.pos.x, self.pos.y });
    }

    pub fn deal_damage(self: *Enemy, damage: f32) bool {
        self.health -= damage;
        if (self.health < 0.0) {
            self.alive = false;
            return true;
        }

        return false;
    }

    pub fn get_id(self: Enemy) usize {
        return self.id;
    }
};

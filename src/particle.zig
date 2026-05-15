const rl = @import("raylib");
const std = @import("std");

const line_info = struct { start: rl.Vector2, end: rl.Vector2, thickness: f32 };

const Particle_Info = union(enum) { line: line_info, dot: rl.Vector2 };

const LINE_THICKNESS = 2.0;
// need type of particle, maybe we have ones
// that will fly around, some that are lasers that disappear
pub const Particle = struct {
    particle_info: Particle_Info,
    start_time: i64,
    lifetime: i64, // lifetime in seconds
    velocity: rl.Vector2,
    color: rl.Color,

    // want to interp
    pub fn init_line(start: rl.Vector2, end: rl.Vector2, start_time: i64, lifetime: i64, velocity: rl.Vector2, color: rl.Color) Particle {
        const info = Particle_Info{ .line = .{ .start = start, .end = end, .thickness = LINE_THICKNESS } };
        return Particle{
            .particle_info = info,
            .start_time = start_time,
            .lifetime = lifetime,
            .velocity = velocity,
            .color = color,
        };
    }

    pub fn init_dot(start: rl.Vector2, start_time: i64, lifetime: i64, velocity: rl.Vector2, color: rl.Color) Particle {
        const info = Particle_Info{ .dot = start };
        return Particle{
            .particle_info = info,
            .start_time = start_time,
            .lifetime = lifetime,
            .velocity = velocity,
            .color = color,
        };
    }

    pub fn draw(self: Particle, current_time: i64) void {
        switch (self.particle_info) {
            .line => |l| {
                // draw line particle

                var color = self.color;
                const elapsed = @as(f32, @floatFromInt(current_time - self.start_time));
                const lifetime = @as(f32, @floatFromInt(self.lifetime));
                const alpha = (1.0 - elapsed / lifetime) * 255.0;
                if (alpha < 0.0) {
                    color.a = 0;
                } else {
                    color.a = @as(u8, @intFromFloat(alpha));
                }
                rl.drawLineEx(l.start, l.end, l.thickness, color);
            },
            .dot => |d| {
                // draw dot particle
                _ = d;
            },
        }
    }
};

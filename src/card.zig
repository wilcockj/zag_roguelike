const rl = @import("raylib");
const std = @import("std");

pub const CARD_W = 150;
pub const CARD_H = 100;

pub const Kind = enum {
    attack,

    pub fn verb(self: Kind) []const u8 {
        return switch (self) {
            .attack => "deal",
        };
    }

    pub fn action(self: Kind) []const u8 {
        return switch (self) {
            .attack => "damage",
        };
    }
};

pub const Card = struct {
    name: [:0]const u8,
    kind: Kind,
    value: u32,
    cooldown: f32,
    cooldown_timer: f32,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, name: [:0]const u8, kind: Kind, value: u32, cooldown: f32) Card {
        return Card{
            .name = name,
            .kind = kind,
            .value = value,
            .cooldown = cooldown,
            .cooldown_timer = cooldown,
            .allocator = allocator,
        };
    }

    pub fn draw(
        self: Card,
        pos: rl.Vector2,
    ) !void {
        const font_size: usize = 20;
        const card_rect: rl.Rectangle = .init(pos.x, pos.y, CARD_W, CARD_H);
        const pad = 5;
        rl.drawRectangleRec(card_rect, .black);
        rl.drawRectangleLinesEx(card_rect, 2, .ray_white);
        const title_x: i32 = @as(i32, @intFromFloat(card_rect.x)) + pad;
        const title_y: i32 = @as(i32, @intFromFloat(card_rect.y)) + pad;
        rl.drawText(self.name, title_x, title_y, font_size, .ray_white);

        const desc = try std.fmt.allocPrintSentinel(self.allocator, "{s} {d} {s} every {d:.01}s", .{ self.kind.verb(), self.value, self.kind.action(), self.cooldown }, 0);
        // TODO: text wrapping
        rl.drawText(desc, title_x, title_y + @as(i32, @intCast(font_size)) + pad, font_size / 2, .gray);

        rl.drawLineEx(rl.Vector2.init(card_rect.x, card_rect.y), rl.Vector2.init(card_rect.x + card_rect.width * (self.cooldown_timer / self.cooldown), card_rect.y), 5, .blue);
    }

    pub fn update_cooldown(self: *Card, dt: f32) bool {
        self.cooldown_timer -= dt;
        if (self.cooldown_timer < 0) {
            self.cooldown_timer = self.cooldown;
            return true;
        }
        return false;
    }
};

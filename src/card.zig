const rl = @import("raylib");
const std = @import("std");

pub const CARD_W = 150;
pub const CARD_H = 230;

pub const CardKind = enum {
    attack,
};

pub const Card = struct {
    name: [:0]const u8,
    kind: CardKind,
    value: u32,
    cooldown: f32,
    cooldown_timer: f32,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, name: [:0]const u8, kind: CardKind, value: u32, cooldown: f32) Card {
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
        const font_size: usize = 10;
        const card_rect: rl.Rectangle = .init(pos.x, pos.y, CARD_W, CARD_H);
        const pad = 5;
        rl.drawRectangleRec(card_rect, .ray_white);
        const title_x: i32 = @as(i32, @intFromFloat(card_rect.x)) + pad;
        const title_y: i32 = @as(i32, @intFromFloat(card_rect.y)) + pad;
        const text = try std.fmt.allocPrintSentinel(self.allocator, "{s} [{d:.02}]", .{ self.name, self.cooldown_timer }, 0);
        rl.drawText(text, title_x, title_y, font_size, .black);
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

const rl = @import("raylib");

pub const Card = struct {
    name: [:0]const u8,
    rect: rl.Rectangle,
    pub fn init(name: [:0]const u8, rect: rl.Rectangle) Card {
        return Card{
            .name = name,
            .rect = rect,
        };
    }

    pub fn draw(self: Card) void {
        const font_size: usize = 10;
        rl.drawRectangleRec(self.rect, .ray_white);
        const text_len = rl.measureText(self.name, font_size);
        const centered_x = @divFloor(@as(i32, @intFromFloat(self.rect.width)) - text_len, 2);
        const x_loc: i32 = @as(i32, @trunc(self.rect.x + @as(f32, @floatFromInt(centered_x))));
        const y_loc: i32 = @divTrunc((@as(i32, @intFromFloat(self.rect.y)) + @as(i32, @intFromFloat(self.rect.height))), 2);
        rl.drawText(self.name, x_loc, y_loc, font_size, .black);
    }
};

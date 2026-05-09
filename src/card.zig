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
        rl.drawText(self.name, @intFromFloat(self.rect.x + self.rect.width / 2), @intFromFloat(self.rect.y + self.rect.height / 2), font_size, .black);
    }
};

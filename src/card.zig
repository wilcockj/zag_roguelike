const rl = @import("raylib");

const CARD_W = 200;
const CARD_H = 300;

pub const CardKind = enum {
    attack,
    defend,
};

pub const Card = struct {
    name: [:0]const u8,
    kind: CardKind,
    rect: rl.Rectangle,
    value: u32,

    pub fn init(name: [:0]const u8, kind: CardKind, value: u32, rect: rl.Rectangle) Card {
        return Card{
            .name = name,
            .kind = kind,
            .value = value,
            .rect = rect,
        };
    }

    pub fn draw(
        self: Card,
    ) void {
        const font_size: usize = 10;
        rl.drawRectangleRec(self.rect, .ray_white);
        rl.drawText(self.name, @intFromFloat(self.rect.x + self.rect.width / 2), @intFromFloat(self.rect.y + self.rect.height / 2), font_size, .black);
    }
};

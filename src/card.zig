const rl = @import("raylib");

pub const Card = struct {
    name: [:0]const u8,

    pub fn init(name: [:0]const u8) Card {
        return Card{
            .name = name,
        };
    }

    pub fn draw(self: Card) void {
        rl.drawRectangle(10, 10, 100, 250, .ray_white);
        rl.drawText(self.name, 10, 10, 10, .black);
    }
};

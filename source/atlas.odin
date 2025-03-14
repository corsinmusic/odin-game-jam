// This file is generated by running the atlas_builder.
package game

/*
Note: This file assumes the existence of a type Rect that defines a rectangle in the same package, it can defined as:

	Rect :: rl.Rectangle

or if you don't use raylib:

	Rect :: struct {
		x, y, width, height: f32,
	}

or if you want to use integers (or any other numeric type):

	Rect :: struct {
		x, y, width, height: int,
	}

Just make sure you have something along those lines the same package as this file.
*/

TEXTURE_ATLAS_FILENAME :: "assets/atlas.png"
ATLAS_FONT_SIZE :: 32
LETTERS_IN_FONT :: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890?!&.,_:[]-+"

// A generated square in the atlas you can use with rl.SetShapesTexture to make
// raylib shapes such as rl.DrawRectangleRec() use the atlas.
SHAPES_TEXTURE_RECT :: Rect {181, 44, 10, 10}

Texture_Name :: enum {
	None,
	Room,
}

Atlas_Texture :: struct {
	using rect: Rect,
	// These offsets tell you how much space there is between the rect and the edge of the original document.
	// The atlas is tightly packed, so empty pixels are removed. This can be especially apparent in animations where
	// frames can have different offsets due to different amount of empty pixels around the frames.
	// In many cases you need to add {offset_left, offset_top} to your position. But if you are
	// flipping a texture, then you might need offset_bottom or offset_right.
	offset_top: f32,
	offset_right: f32,
	offset_bottom: f32,
	offset_left: f32,
	document_size: [2]f32,
	duration: f32,
}

atlas_textures: [Texture_Name]Atlas_Texture = {
	.None = {},
	.Room = { rect = {0, 0, 48, 48}, offset_top = 0, offset_right = 0, offset_bottom = 0, offset_left = 0, document_size = {48, 48}, duration = 0.100},
}

Animation_Name :: enum {
	None,
}

Tag_Loop_Dir :: enum {
	Forward,
	Reverse,
	Ping_Pong,
	Ping_Pong_Reverse,
}

// Any aseprite file with frames will create new animations. Also, any tags
// within the aseprite file will make that that into a separate animation.
Atlas_Animation :: struct {
	first_frame: Texture_Name,
	last_frame: Texture_Name,
	document_size: [2]f32,
	loop_direction: Tag_Loop_Dir,
	repeat: u16,
}

atlas_animations := [Animation_Name]Atlas_Animation {
	.None = {},
}

// All these are pre-generated so you can save tile IDs to data without
// worrying about their order changing later.
Tile_Id :: enum {
	T0Y0X0,
	T0Y0X1,
	T0Y0X2,
	T0Y0X3,
	T0Y0X4,
	T0Y0X5,
	T0Y0X6,
	T0Y0X7,
	T0Y0X8,
	T0Y0X9,
	T0Y1X0,
	T0Y1X1,
	T0Y1X2,
	T0Y1X3,
	T0Y1X4,
	T0Y1X5,
	T0Y1X6,
	T0Y1X7,
	T0Y1X8,
	T0Y1X9,
	T0Y2X0,
	T0Y2X1,
	T0Y2X2,
	T0Y2X3,
	T0Y2X4,
	T0Y2X5,
	T0Y2X6,
	T0Y2X7,
	T0Y2X8,
	T0Y2X9,
	T0Y3X0,
	T0Y3X1,
	T0Y3X2,
	T0Y3X3,
	T0Y3X4,
	T0Y3X5,
	T0Y3X6,
	T0Y3X7,
	T0Y3X8,
	T0Y3X9,
	T0Y4X0,
	T0Y4X1,
	T0Y4X2,
	T0Y4X3,
	T0Y4X4,
	T0Y4X5,
	T0Y4X6,
	T0Y4X7,
	T0Y4X8,
	T0Y4X9,
	T0Y5X0,
	T0Y5X1,
	T0Y5X2,
	T0Y5X3,
	T0Y5X4,
	T0Y5X5,
	T0Y5X6,
	T0Y5X7,
	T0Y5X8,
	T0Y5X9,
	T0Y6X0,
	T0Y6X1,
	T0Y6X2,
	T0Y6X3,
	T0Y6X4,
	T0Y6X5,
	T0Y6X6,
	T0Y6X7,
	T0Y6X8,
	T0Y6X9,
	T0Y7X0,
	T0Y7X1,
	T0Y7X2,
	T0Y7X3,
	T0Y7X4,
	T0Y7X5,
	T0Y7X6,
	T0Y7X7,
	T0Y7X8,
	T0Y7X9,
	T0Y8X0,
	T0Y8X1,
	T0Y8X2,
	T0Y8X3,
	T0Y8X4,
	T0Y8X5,
	T0Y8X6,
	T0Y8X7,
	T0Y8X8,
	T0Y8X9,
	T0Y9X0,
	T0Y9X1,
	T0Y9X2,
	T0Y9X3,
	T0Y9X4,
	T0Y9X5,
	T0Y9X6,
	T0Y9X7,
	T0Y9X8,
	T0Y9X9,
}

atlas_tiles := #partial [Tile_Id]Rect {
}

Atlas_Glyph :: struct {
	rect: Rect,
	value: rune,
	offset_x: int,
	offset_y: int,
	advance_x: int,
}

atlas_glyphs: []Atlas_Glyph = {
	{ rect = {372, 23, 17, 19}, value = 'A', offset_x = 0, offset_y = 4, advance_x = 16},
	{ rect = {214, 24, 14, 19}, value = 'B', offset_x = 2, offset_y = 4, advance_x = 16},
	{ rect = {369, 1, 15, 20}, value = 'C', offset_x = 1, offset_y = 4, advance_x = 16},
	{ rect = {493, 23, 14, 19}, value = 'D', offset_x = 2, offset_y = 4, advance_x = 16},
	{ rect = {246, 24, 14, 19}, value = 'E', offset_x = 2, offset_y = 4, advance_x = 16},
	{ rect = {162, 25, 13, 19}, value = 'F', offset_x = 2, offset_y = 4, advance_x = 16},
	{ rect = {335, 1, 15, 20}, value = 'G', offset_x = 1, offset_y = 4, advance_x = 16},
	{ rect = {117, 25, 13, 19}, value = 'H', offset_x = 2, offset_y = 4, advance_x = 16},
	{ rect = {102, 25, 13, 19}, value = 'I', offset_x = 2, offset_y = 4, advance_x = 16},
	{ rect = {282, 23, 12, 20}, value = 'J', offset_x = 2, offset_y = 4, advance_x = 16},
	{ rect = {476, 23, 15, 19}, value = 'K', offset_x = 2, offset_y = 4, advance_x = 16},
	{ rect = {85, 28, 13, 19}, value = 'L', offset_x = 3, offset_y = 4, advance_x = 16},
	{ rect = {425, 23, 15, 19}, value = 'M', offset_x = 1, offset_y = 4, advance_x = 16},
	{ rect = {132, 25, 13, 19}, value = 'N', offset_x = 2, offset_y = 4, advance_x = 16},
	{ rect = {420, 1, 15, 20}, value = 'O', offset_x = 1, offset_y = 4, advance_x = 16},
	{ rect = {198, 24, 14, 19}, value = 'P', offset_x = 2, offset_y = 4, advance_x = 16},
	{ rect = {85, 1, 15, 25}, value = 'Q', offset_x = 1, offset_y = 4, advance_x = 16},
	{ rect = {408, 23, 15, 19}, value = 'R', offset_x = 2, offset_y = 4, advance_x = 16},
	{ rect = {301, 1, 15, 20}, value = 'S', offset_x = 1, offset_y = 4, advance_x = 16},
	{ rect = {442, 23, 15, 19}, value = 'T', offset_x = 1, offset_y = 4, advance_x = 16},
	{ rect = {469, 1, 14, 20}, value = 'U', offset_x = 1, offset_y = 4, advance_x = 16},
	{ rect = {334, 23, 17, 19}, value = 'V', offset_x = 0, offset_y = 4, advance_x = 16},
	{ rect = {315, 23, 17, 19}, value = 'W', offset_x = 0, offset_y = 4, advance_x = 16},
	{ rect = {296, 23, 17, 19}, value = 'X', offset_x = 0, offset_y = 4, advance_x = 16},
	{ rect = {353, 23, 17, 19}, value = 'Y', offset_x = 0, offset_y = 4, advance_x = 16},
	{ rect = {459, 23, 15, 19}, value = 'Z', offset_x = 1, offset_y = 4, advance_x = 16},
	{ rect = {50, 30, 15, 17}, value = 'a', offset_x = 1, offset_y = 7, advance_x = 16},
	{ rect = {150, 1, 14, 22}, value = 'b', offset_x = 2, offset_y = 2, advance_x = 16},
	{ rect = {313, 44, 14, 17}, value = 'c', offset_x = 1, offset_y = 7, advance_x = 16},
	{ rect = {102, 1, 14, 22}, value = 'd', offset_x = 1, offset_y = 2, advance_x = 16},
	{ rect = {296, 44, 15, 17}, value = 'e', offset_x = 1, offset_y = 7, advance_x = 16},
	{ rect = {201, 1, 15, 21}, value = 'f', offset_x = 1, offset_y = 2, advance_x = 16},
	{ rect = {118, 1, 14, 22}, value = 'g', offset_x = 1, offset_y = 7, advance_x = 16},
	{ rect = {252, 1, 13, 21}, value = 'h', offset_x = 2, offset_y = 2, advance_x = 16},
	{ rect = {235, 1, 15, 21}, value = 'i', offset_x = 1, offset_y = 2, advance_x = 16},
	{ rect = {50, 1, 11, 27}, value = 'j', offset_x = 1, offset_y = 2, advance_x = 16},
	{ rect = {267, 1, 13, 21}, value = 'k', offset_x = 3, offset_y = 2, advance_x = 16},
	{ rect = {218, 1, 15, 21}, value = 'l', offset_x = 1, offset_y = 2, advance_x = 16},
	{ rect = {344, 44, 15, 16}, value = 'm', offset_x = 1, offset_y = 7, advance_x = 16},
	{ rect = {376, 44, 13, 16}, value = 'n', offset_x = 2, offset_y = 7, advance_x = 16},
	{ rect = {67, 30, 15, 17}, value = 'o', offset_x = 1, offset_y = 7, advance_x = 16},
	{ rect = {134, 1, 14, 22}, value = 'p', offset_x = 2, offset_y = 7, advance_x = 16},
	{ rect = {166, 1, 14, 22}, value = 'q', offset_x = 1, offset_y = 7, advance_x = 16},
	{ rect = {391, 44, 12, 16}, value = 'r', offset_x = 3, offset_y = 7, advance_x = 16},
	{ rect = {329, 44, 13, 17}, value = 's', offset_x = 2, offset_y = 7, advance_x = 16},
	{ rect = {485, 1, 13, 20}, value = 't', offset_x = 2, offset_y = 4, advance_x = 16},
	{ rect = {361, 44, 13, 16}, value = 'u', offset_x = 2, offset_y = 8, advance_x = 16},
	{ rect = {424, 44, 16, 15}, value = 'v', offset_x = 0, offset_y = 8, advance_x = 16},
	{ rect = {405, 44, 17, 15}, value = 'w', offset_x = 0, offset_y = 8, advance_x = 16},
	{ rect = {459, 44, 15, 15}, value = 'x', offset_x = 1, offset_y = 8, advance_x = 16},
	{ rect = {182, 1, 17, 21}, value = 'y', offset_x = 0, offset_y = 8, advance_x = 16},
	{ rect = {476, 44, 13, 15}, value = 'z', offset_x = 2, offset_y = 8, advance_x = 16},
	{ rect = {182, 24, 14, 19}, value = '1', offset_x = 2, offset_y = 4, advance_x = 16},
	{ rect = {262, 24, 14, 19}, value = '2', offset_x = 1, offset_y = 4, advance_x = 16},
	{ rect = {352, 1, 15, 20}, value = '3', offset_x = 1, offset_y = 4, advance_x = 16},
	{ rect = {391, 23, 15, 19}, value = '4', offset_x = 1, offset_y = 4, advance_x = 16},
	{ rect = {403, 1, 15, 20}, value = '5', offset_x = 1, offset_y = 4, advance_x = 16},
	{ rect = {437, 1, 14, 20}, value = '6', offset_x = 2, offset_y = 4, advance_x = 16},
	{ rect = {147, 25, 13, 19}, value = '7', offset_x = 2, offset_y = 4, advance_x = 16},
	{ rect = {318, 1, 15, 20}, value = '8', offset_x = 1, offset_y = 4, advance_x = 16},
	{ rect = {453, 1, 14, 20}, value = '9', offset_x = 1, offset_y = 4, advance_x = 16},
	{ rect = {386, 1, 15, 20}, value = '0', offset_x = 1, offset_y = 4, advance_x = 16},
	{ rect = {230, 24, 14, 19}, value = '?', offset_x = 1, offset_y = 4, advance_x = 16},
	{ rect = {177, 25, 3, 19}, value = '!', offset_x = 7, offset_y = 4, advance_x = 16},
	{ rect = {282, 1, 17, 20}, value = '&', offset_x = 0, offset_y = 4, advance_x = 16},
	{ rect = {193, 45, 5, 5}, value = '.', offset_x = 6, offset_y = 18, advance_x = 16},
	{ rect = {498, 44, 7, 11}, value = ',', offset_x = 3, offset_y = 18, advance_x = 16},
	{ rect = {200, 45, 19, 3}, value = '_', offset_x = -1, offset_y = 24, advance_x = 16},
	{ rect = {491, 44, 5, 15}, value = ':', offset_x = 6, offset_y = 8, advance_x = 16},
	{ rect = {74, 1, 9, 27}, value = '[', offset_x = 5, offset_y = 2, advance_x = 16},
	{ rect = {63, 1, 9, 27}, value = ']', offset_x = 3, offset_y = 2, advance_x = 16},
	{ rect = {221, 45, 9, 3}, value = '-', offset_x = 4, offset_y = 14, advance_x = 16},
	{ rect = {442, 44, 15, 15}, value = '+', offset_x = 1, offset_y = 6, advance_x = 16},
}

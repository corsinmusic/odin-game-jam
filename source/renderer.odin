package game

import "core:mem"
import rl "vendor:raylib"

Render_Line :: struct {
	start: Vec2,
	end: Vec2,
	thickness: f32,
	color: rl.Color,
}

Render_Rect :: struct {
	rect: Rect,	
	color: rl.Color,
}

Render_Text :: struct {
	font: rl.Font,
	text: cstring,
	position: Vec2,	
	size: f32,
	spacing: f32,
	color: rl.Color,
}

Render_Circle :: struct {
	position: Vec2,
	radius: f32,
	color: rl.Color,
}

Render_Command :: union {
	Render_Line,
	Render_Rect,
	Render_Text,
	Render_Circle,
}

Render_Group :: struct {
	arena: mem.Arena,
	arena_allocator: mem.Allocator,
	commands:[dynamic]Render_Command,
}

//..

init_render_group :: proc(render_group:^Render_Group, size: u32) {
	
	data, _ := make([]byte, size)
	mem.arena_init(&render_group.arena, data)
	render_group.arena_allocator = mem.arena_allocator(&render_group.arena)
	render_group.commands = make([dynamic]Render_Command, allocator = render_group.arena_allocator)
}

delete_render_group :: proc(rg: ^Render_Group) {
	delete(rg.commands)
	delete(rg.arena.data)
}

clear_render_group :: proc(rg: ^Render_Group) {	
	prev_len := len(rg.commands)
	prev_cap := cap(rg.commands)
	free_all(rg.arena_allocator)
	rg.commands = make([dynamic]Render_Command, 0, max(prev_len * 2, prev_cap), allocator = rg.arena_allocator)
}

//..

push_line :: proc(commands: ^[dynamic]Render_Command, start: Vec2, end: Vec2, thickness: f32, color: rl.Color) {
	append(commands, Render_Line { start, end, thickness, color })
}

push_rect :: proc(commands: ^[dynamic]Render_Command, rect: Rect, color: rl.Color) {
	append(commands, Render_Rect { rect, color })
}

push_text :: proc(commands: ^[dynamic]Render_Command, font: rl.Font, text: cstring, position: Vec2, size: f32, spacing: f32, color: rl.Color) {
	append(commands, Render_Text { font, text, position, size, spacing, color })
}

push_circle :: proc(commands: ^[dynamic]Render_Command, position: Vec2, radius: f32, color: rl.Color) {
	append(commands, Render_Circle { position, radius, color })
}

//..

draw_render_commands :: proc(commands:[dynamic]Render_Command) {
	for command in commands {
		switch &v in command {
		case Render_Line: {
			rl.DrawLineEx(v.start, v.end, v.thickness, v.color)
		}
		case Render_Rect: {
			rl.DrawRectangleRec(v.rect, v.color)
		}
		case Render_Text: {
			rl.DrawTextEx(v.font, v.text, v.position, v.size, v.spacing, v.color)
		}
		case Render_Circle: {
			rl.DrawCircleV(v.position, v.radius, v.color)
		}
		}
	}
}
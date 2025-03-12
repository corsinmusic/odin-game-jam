package game

import rl "vendor:raylib"

Interaction_Mode :: enum {
	Idle,
	CreateRoom,
	ResizeRoom,
	MoveRoom,
	HoveringCorner,	
}

Interaction_State :: struct {
	mode: Interaction_Mode,
	room_index: u32,
	anchor: Vec2i,
	rect: Recti,	
}

Editor_State :: struct {
	editing : bool,
	//..
	using interaction_state : Interaction_State,	
}

g_editor : ^Editor_State

//..

HOVER_RADIUS :: 3
HOVER_RADIUS_SQ :: (HOVER_RADIUS * HOVER_RADIUS)
draw_editor :: proc() {
	#partial switch g_editor.mode {
		case .CreateRoom: {
			draw_room(g_editor.rect)
		}
		case .ResizeRoom: fallthrough
		case .HoveringCorner: {
			room := g_mem.world.rooms[g_editor.room_index]
			rl.DrawCircleV(to_vec2(get_rect_max(room)), HOVER_RADIUS, {10, 150, 200, 150})
		}
	}
}

//..

find_closest_room_corner :: proc(mouse_pos: Vec2i) -> i32 {
	closest_index:i32 = -1
	min_distance := max(i32)			
	#reverse for room, idx in g_mem.world.rooms {
		distance := length_sq(get_rect_max(room) - mouse_pos)
		if distance <= HOVER_RADIUS_SQ && distance < min_distance {
			min_distance = distance
			closest_index = cast(i32)idx
		}
	}

	return closest_index
}

update_editor :: proc() {

	switch g_editor.mode {
	case .HoveringCorner: fallthrough
	case .Idle: {
		mouse_pos := to_vec2i(get_game_mouse_position())

		if rl.IsMouseButtonPressed(.LEFT) {			
			g_editor.mode = .Idle
			
			room_index := find_closest_room_corner(mouse_pos)
			if room_index >= 0 {
				g_editor.room_index = cast(u32)room_index
				g_editor.mode = .ResizeRoom
				room := g_mem.world.rooms[room_index]
				g_editor.anchor = {room.width - mouse_pos.x, room.height - mouse_pos.y}
			}
			
			if g_editor.mode == .Idle {
				#reverse for room, idx in g_mem.world.rooms {
					if is_in_rectangle(room, mouse_pos) {
						if rl.IsKeyUp(.LEFT_SHIFT) {
							g_editor.mode = .MoveRoom
							g_editor.anchor = room.position - mouse_pos
							g_editor.room_index = cast(u32)idx
						} else {
							ordered_remove(&g_mem.world.rooms, idx)
						}
						break
					}			
				}		
			}

			if g_editor.mode == .Idle {				
				g_editor.mode = .CreateRoom
				g_editor.anchor = mouse_pos
				g_editor.rect = {}
			}
		} else {
			room_index := find_closest_room_corner(mouse_pos)
			if room_index >= 0 {
				g_editor.mode = .HoveringCorner
				g_editor.room_index = cast(u32)room_index
			} else {
				g_editor.mode = .Idle
			}
		}
	}
	case .CreateRoom: {
		if rl.IsMouseButtonDown(.LEFT) {
			min: Vec2i
			max: Vec2i

			mouse_pos := to_vec2i(get_game_mouse_position())
			if mouse_pos.x < g_editor.anchor.x {
				min.x = mouse_pos.x
				max.x = g_editor.anchor.x
			} else {
				min.x = g_editor.anchor.x
				max.x = mouse_pos.x
			}

			if mouse_pos.y < g_editor.anchor.y {
				min.y = mouse_pos.y
				max.y = g_editor.anchor.y
			} else {
				min.y = g_editor.anchor.y
				max.y = mouse_pos.y
			}
			
			g_editor.rect = {min, max.x - min.x, max.y - min.y}
		} else {
			g_editor.mode = .Idle			
			if(g_editor.rect.width > 2 && g_editor.rect.height > 2) {
				append(&g_mem.world.rooms, create_room(g_editor.rect))
			}			
		}		
	}
	case .ResizeRoom: {
		if rl.IsMouseButtonDown(.LEFT) {
			mouse_pos := to_vec2i(get_game_mouse_position())
			room := &g_mem.world.rooms[g_editor.room_index]
			
			new_dim := mouse_pos + g_editor.anchor
			
			room.width = new_dim.x
			room.height = new_dim.y

		} else {
			g_editor.mode = .Idle
		}
	}
	case .MoveRoom: {
		if rl.IsMouseButtonDown(.LEFT) {
			mouse_pos := to_vec2i(get_game_mouse_position())
			g_mem.world.rooms[g_editor.room_index].position = mouse_pos + g_editor.anchor
		} else {
			g_editor.mode = .Idle
		}
	}
	}
}

//..

editor_init :: proc() {
}

editor_shutdown :: proc() {
}
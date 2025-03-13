package game

//import "core:strings"
//import "core:fmt"
import "core:math"
import "core:c"
import rl "vendor:raylib"

Coordinate_System :: enum {
	Window,
	Game,
}

Interaction_Mode :: enum {
	Idle,
	CreateRoom,
	ResizeRect,
	MoveRect,
	HoveringCorner,	
}

Interaction_State :: struct {
	mode: Interaction_Mode,
	coordinate_system: Coordinate_System,
	edit_rect: ^Recti,
	anchor: Vec2i,
	create_rect: Recti,		
}

Editor_State :: struct {
	editing : bool,	
	//..
	using interaction_state : Interaction_State,
	//..
	window: UI_Window,	
}

// TODO: look into how to do this correctly.
g_input_buffer: [64]u8
g_editor : ^Editor_State

edit_text := false

//..

get_editing_mouse_pos :: proc() -> Vec2i{
	result: Vec2i
	switch g_editor.coordinate_system {
	case .Window: {
		result = to_vec2i(rl.GetMousePosition())
	}
	case .Game: {
		result = to_vec2i(get_game_mouse_position())
	}
	}
	return result
}


draw_recti_resize_tool_tip :: proc(scale: f32, offset:Vec2 = {}) {
	room := g_editor.edit_rect^
	corner := to_vec2(get_rect_max(room))
	rl.DrawCircleV(corner + offset, HOVER_RADIUS * scale, {10, 150, 200, 150})
}

HOVER_RADIUS :: 3
HOVER_RADIUS_SQ :: (HOVER_RADIUS * HOVER_RADIUS)
draw_editor :: proc() {
	if g_editor.coordinate_system == .Game {		
		#partial switch g_editor.mode {
			case .CreateRoom: {
				draw_room(g_editor.create_rect)
			}
			case .ResizeRect: fallthrough
			case .HoveringCorner: {			
				draw_recti_resize_tool_tip(1)
			}
		}
	}
}


draw_editor_ui :: proc() {
	if(ui_start(&g_editor.window)) {
		//ui_draw_text("hetto")
		//ui_draw_text("test")
		if(ui_button("hi")) {
			// todo: task
		}		

		// NOTE: end ui if it is visible
		ui_end()
	}

	//..

	if g_editor.coordinate_system == .Window {
		#partial switch g_editor.mode {			
			case .ResizeRect: fallthrough
			case .HoveringCorner: {			
				draw_recti_resize_tool_tip(g_mem.view.zoom, to_vec2(g_mem.view.position))
			}
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

	room = g_mem.world.rooms[0]
	process_room(room)

	switch g_editor.mode {
	case .HoveringCorner: fallthrough
	case .Idle: {
		

		lmb_pressed := rl.IsMouseButtonPressed(.LEFT)

		interacting_with_window := false
		if g_editor.window.visible {			
			window := &g_editor.window
			window_rect := window.rect
			window_rect.position += g_mem.view.position

			max := get_rect_max(window_rect)
			mouse_pos := to_vec2i(rl.GetMousePosition())
			distance := length_sq(max - mouse_pos)
			min_distance := i32(math.round(g_mem.view.zoom * HOVER_RADIUS_SQ))
			if distance <= min_distance {
				g_editor.edit_rect = window
				interacting_with_window = true
				if lmb_pressed {
					g_editor.mode = .ResizeRect
					g_editor.anchor = Vec2i {window.width, window.height} - mouse_pos
				} else {
					g_editor.mode = .HoveringCorner
				}		
				g_editor.coordinate_system = .Window		
			}

			if g_editor.mode == .Idle {
				if lmb_pressed && is_in_rectangle(window_rect, mouse_pos) {
					interacting_with_window = true
					test_rect := window_rect
					slider_width:i32 = 13//rl.GuiGetStyle(.DEFAULT, i32(rl.GuiScrollBarProperty.SCROLL_SLIDER_SIZE))
					
					if window.max.x > f32(test_rect.width) {
						test_rect.height -= slider_width
					}					

					if window.max.y > f32(test_rect.height) {
						test_rect.width -= slider_width
					}

					if is_in_rectangle(test_rect, mouse_pos) {						
						g_editor.mode = .MoveRect
						g_editor.edit_rect = window
						g_editor.anchor = window.position - mouse_pos
						g_editor.coordinate_system = .Window
					}					
				}
			}
		}

		if !interacting_with_window {
			mouse_pos := to_vec2i(get_game_mouse_position())

			if lmb_pressed {
				g_editor.mode = .Idle			
			
				room_index := find_closest_room_corner(mouse_pos)
				if room_index >= 0 {
					g_editor.edit_rect = &g_mem.world.rooms[room_index].rect
					g_editor.mode = .ResizeRect
					g_editor.coordinate_system = .Game
					room := g_mem.world.rooms[room_index]
					g_editor.anchor = {room.width - mouse_pos.x, room.height - mouse_pos.y}
				}
				
				if g_editor.mode == .Idle {
					#reverse for room, idx in g_mem.world.rooms {
						if is_in_rectangle(room, mouse_pos) {
							if rl.IsKeyUp(.LEFT_SHIFT) {
								g_editor.mode = .MoveRect
								g_editor.anchor = room.position - mouse_pos
								g_editor.edit_rect = &g_mem.world.rooms[idx]
								g_editor.coordinate_system = .Game
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
					g_editor.create_rect = {}
					g_editor.coordinate_system = .Game
				}
			} else {
				room_index := find_closest_room_corner(mouse_pos)
				if room_index >= 0 {
					g_editor.mode = .HoveringCorner
					g_editor.edit_rect = &g_mem.world.rooms[room_index]
					g_editor.coordinate_system = .Game
				} else {
					g_editor.mode = .Idle					
				}
			}

		}

	}
	case .CreateRoom: {
		if rl.IsMouseButtonDown(.LEFT) {
			min: Vec2i
			max: Vec2i

			assert(g_editor.coordinate_system == .Game)

			mouse_pos := get_editing_mouse_pos()
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
			
			g_editor.create_rect = {min, max.x - min.x, max.y - min.y}
		} else {
			g_editor.mode = .Idle			
			if(g_editor.create_rect.width > 2 && g_editor.create_rect.height > 2) {
				append(&g_mem.world.rooms, create_room(g_editor.create_rect))
			}			
		}		
	}
	case .ResizeRect: {
		if rl.IsMouseButtonDown(.LEFT) {
			mouse_pos := get_editing_mouse_pos()
			room := g_editor.edit_rect
			
			new_dim := mouse_pos + g_editor.anchor
			
			room.width = new_dim.x
			room.height = new_dim.y

		} else {
			g_editor.mode = .Idle
		}
	}
	case .MoveRect: {
		if rl.IsMouseButtonDown(.LEFT) {

			mouse_pos := get_editing_mouse_pos()
			g_editor.edit_rect.position = mouse_pos + g_editor.anchor
		} else {
			g_editor.mode = .Idle
		}
	}
	}

	when ODIN_DEBUG {
		if rl.IsKeyPressed(.TAB) {
			g_editor.window.visible = !g_editor.window.visible
		}
	} else {
		g_editor.editing = false
		g_editor.mode = .Idle
		g_editor.window.visible = false
	}
}

//..

editor_hot_reload :: proc() {
	
}

editor_init :: proc() {
	g_editor.editing = ODIN_DEBUG

	window := &g_editor.window
	window.font = g_mem.font
	window.font_size = ATLAS_FONT_SIZE * 0.5
	window.items = make(map[string]UI_Data)
	window.delayed_elements = make([dynamic]UI_Element, 0, 64)
	
	window.rect = {
		{0, 0}, 150, 300,
	}
	window.padding = {10, 5}
}

editor_shutdown :: proc() {
	delete(g_editor.window.items)
}
package game

//import "core:strings"
import "core:c"
import "core:fmt"
import "core:math"
import "core:reflect"
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
	AddRoomConnection,
}

Interaction_Type :: enum {
	Normal,
	SelectedRoom,
}

Interaction_State :: struct {
	type: Interaction_Type,
	mode: Interaction_Mode,
	coordinate_system: Coordinate_System,

	edit_rect: ^Recti,
	anchor: Vec2i,
	create_rect: Recti,		

	room_idx:i32,
}

Editor_State :: struct {
	editing : bool,	
	//..
	using interaction_state : Interaction_State,
	//..
	window: UI_Window,	
}

g_editor: ^Editor_State

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

	if g_editor.type == .SelectedRoom && g_editor.room_idx >= 0 {
		room := g_mem.world.rooms[g_editor.room_idx]
		thickness:f32 = 2
		rect := to_rect(room.rect)
		rect.x -= thickness
		rect.y -= thickness
		rect.width += thickness * 2
		rect.height += thickness * 2
		rl.DrawRectangleLinesEx(rect, thickness, rl.YELLOW)
	}
}

g_name1:string = ""
g_name2:string = ""

g_index:c.int = 0

g_data: UI_Data = UI_Textbox_Data {}

draw_editor_ui :: proc() {
	
	if(ui_start(&g_editor.window)) {
		font_size:f32 = 12

		for connection in g_mem.world.connections {
			if g_editor.room_idx != i32(connection.a_idx) &&
			g_editor.room_idx != i32(connection.b_idx) {
				push_room_connection(connection, rl.BLACK, font_size)
			}
		}

		if ui_button((g_editor.editing) ? "stop editing" : "start editing") {
			g_editor.editing = !g_editor.editing
		}
		switch(g_editor.type) {
		case .Normal: {
			if(ui_button("select room")) {
				g_editor.type = .SelectedRoom
				g_editor.mode = .Idle
				g_editor.room_idx = -1
			}
		}
		case .SelectedRoom: {		

			if g_editor.mode == .AddRoomConnection {
				rl.GuiLock()				
			}

			if ui_button("edit world") {
				g_editor.type = .Normal
			}

			if g_editor.room_idx >= 0 {
				if g_editor.mode == .AddRoomConnection {
					if !g_window.lockui {
						rl.GuiUnlock()
					}
					if ui_button("stop add connections") {
						g_editor.mode = .Idle
					}
					rl.GuiLock()
				} else {
					if ui_button("add connections") {
						g_editor.mode = .AddRoomConnection
					}
				}

				room := &g_mem.world.rooms[g_editor.room_idx]
				ui_union_dropdown("room-variant", &room.variant_data, 200)

				mouse_pos := rl.GetMousePosition()
				window_y := f32(g_window.position.y)
				mouse_in_window_bounds := is_in_rectangle(g_window.abs_rect, mouse_pos)


				for connection_idx, idx in room.connections {
					connection := &g_mem.world.connections[connection_idx]

					start_cursor_y := g_window.cursor.y + window_y
					
					ui_draw_text(fmt.ctprintfln("%v: %v - %v", connection_idx, connection.a_idx, connection.b_idx))
					ui_same_line()
					string_id := fmt.tprintfln("%v-connection-%v", g_editor.room_idx, idx)
					ui_edit_i32(string_id, &connection.distance, 1, 100, 90)
					ui_same_line()
					if(ui_button("delete")) {
						delete_connection(connection_idx)
					}

					if mouse_in_window_bounds && 
					mouse_pos.y >= start_cursor_y && mouse_pos.y < (g_window.cursor.y + window_y) {
						push_room_connection(connection^, rl.BROWN, font_size)
					} else {
						push_room_connection(connection^, rl.BLUE, font_size)
					}

				}
			}

			if g_editor.mode == .AddRoomConnection {
				rl.EndScissorMode()
				ui_draw_window_rect({50, 50, 50, 100})
				ui_clip_window()
			}
		}
		}

		ui_draw_text(fmt.ctprintf("%v", g_window.position))
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
		max := get_rect_max(room.rect)
		distance := length_sq(max - mouse_pos)
		if distance <= HOVER_RADIUS_SQ && distance < min_distance {
			min_distance = distance
			closest_index = cast(i32)idx
		}
	}

	return closest_index
}

remove_connection :: proc(room: ^Room, idx: u32) {
	
	for i in 0..<len(room.connections) {
		connection_idx := room.connections[i]
		if connection_idx == idx {
			unordered_remove(&room.connections, i)
			break
		}
	}
}


delete_connection :: proc(idx: u32) {
	connection := g_mem.world.connections[idx]
	unordered_remove(&g_mem.world.connections, idx)
	last_idx := u32(len(g_mem.world.connections))

	room_a := &g_mem.world.rooms[connection.a_idx]
	room_b := &g_mem.world.rooms[connection.b_idx]
	remove_connection(room_a, idx)
	remove_connection(room_b, idx)

	for &room in g_mem.world.rooms {
		for connection_idx, i in room.connections {
			if connection_idx == last_idx {
				room.connections[i] = idx
			}
		}
	}
}

delete_room :: proc(idx: u32) {
	room := g_mem.world.rooms[idx]

	// NOTE: remove connections
	for i in room.connections {
		connection := g_mem.world.connections[i]

		// NOTE: remove connections to room in other rooms
		other_idx:u32
		if connection.a_idx == idx {
			other_idx = connection.b_idx
		} else {
			assert(connection.b_idx == idx)
			other_idx = connection.a_idx
		}

		other := &g_mem.world.rooms[other_idx]
		for other_connection_idx, j in other.connections {
			if other_connection_idx == i {
				unordered_remove(&other.connections, j)
				break
			}
		}

		unordered_remove(&g_mem.world.connections, i)
		last_idx := u32(len(g_mem.world.connections))
		// NOTE: update connection idx after removing connection
		for &test_room in g_mem.world.rooms {
			for connection_idx, j in test_room.connections {
				if last_idx == connection_idx {
					test_room.connections[j] = i
				}
			}
		}
	}

	unordered_remove(&g_mem.world.rooms, idx)

	// NOTE: update room idx in connections	
	last_idx := u32(len(g_mem.world.rooms))
	for &connection in g_mem.world.connections {
		if connection.a_idx == last_idx {
			connection.a_idx = idx
		} else if (connection.b_idx == last_idx) {
			connection.b_idx = idx
		}
	}

}

update_editor :: proc() {

	if g_editor.type == .SelectedRoom &&
	g_editor.mode == .Idle && rl.IsKeyPressed(.ESCAPE) {
		g_editor.type = .Normal
	}

	if g_editor.type != .SelectedRoom {
		g_editor.room_idx = -1
	}

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
					g_editor.anchor = {room.rect.width - mouse_pos.x, room.rect.height - mouse_pos.y}
				}
				
				if g_editor.mode == .Idle {					
					#reverse for room, idx in g_mem.world.rooms {
						if is_in_rectangle(room.rect, mouse_pos) {							
							if g_editor.type == .SelectedRoom {
								if i32(idx) == g_editor.room_idx {
									g_editor.room_idx = -1
									g_editor.type = .Normal
								} else {
									g_editor.room_idx = i32(idx)
								}
							} else {
								if rl.IsKeyUp(.LEFT_SHIFT) {
									g_editor.mode = .MoveRect
									g_editor.anchor = room.rect.position - mouse_pos
									g_editor.edit_rect = &g_mem.world.rooms[idx].rect
									g_editor.coordinate_system = .Game
								} else {								
									delete_room(u32(idx))
								}	
							}
							
							break
						}			
					}		
				}

				if g_editor.type == .Normal &&
				g_editor.mode == .Idle {				
					g_editor.mode = .CreateRoom
					g_editor.anchor = mouse_pos
					g_editor.create_rect = {}
					g_editor.coordinate_system = .Game
				}
			} else {

				room_index := find_closest_room_corner(mouse_pos)
				if room_index >= 0 {
					g_editor.mode = .HoveringCorner
					g_editor.edit_rect = &g_mem.world.rooms[room_index].rect
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
	case .AddRoomConnection: {

		if rl.IsKeyPressed(.ESCAPE) {
			g_editor.mode = .Idle
		}

		if g_editor.type != .SelectedRoom || g_editor.room_idx < 0{
			g_editor.mode = .Idle
		} else {			
			if rl.IsMouseButtonPressed(.LEFT) {
				mouse_pos := get_game_mouse_position()
				selected_room := &g_mem.world.rooms[g_editor.room_idx]
				#reverse for &room, idx in g_mem.world.rooms {
					if is_in_rectangle(room.rect, mouse_pos) {

						if i32(idx) == g_editor.room_idx {
							continue
						}

						connection_idx := u32(len(g_mem.world.connections))
						new_connection := true

						for selected_connection_idx in selected_room.connections {
							selected_connection := g_mem.world.connections[selected_connection_idx]

							if selected_connection.a_idx == u32(idx) ||
							selected_connection.b_idx == u32(idx) {
								new_connection = false
								break
							}
						}

						if new_connection {
							append(&g_mem.world.connections, 
								Room_Connection { a_idx = u32(g_editor.room_idx), 
								b_idx = u32(idx),
								distance = 1 })

							append(&room.connections, connection_idx)
							append(&selected_room.connections, connection_idx)
						}

						break
					}
				}
			}
		}

	}
	}

	when ODIN_DEBUG {
		if rl.IsKeyPressed(.TAB) {
			g_editor.window.visible = !g_editor.window.visible
			if g_editor.window.visible {
				g_editor.editing = true
			}
		}
	}

	if !g_editor.editing {
		g_editor.type = .Normal
		g_editor.mode = .Idle
		g_editor.window.visible = false		
	}	
}

//..

editor_hot_reload :: proc() {
	
}

editor_init :: proc() {
	g_editor.editing = ODIN_DEBUG
	g_editor.room_idx = -1

	window := &g_editor.window
	window.font = g_mem.font
	window.font_size = ATLAS_FONT_SIZE
	window.items = make(map[string]UI_State)
	window.delayed_items = make([dynamic]^UI_State, 0, 64)
	
	window.rect = {
		{0, 0}, 150, 300,
	}
	window.padding = {10, 5}

	g_window = nil
}

editor_shutdown :: proc() {
	delete(g_editor.window.items)
	delete(g_editor.window.delayed_items)
	delete(g_name1)
	delete(g_name2)
}
package game

import "core:math"
import "core:c"
import rl "vendor:raylib"

UI_Data :: struct {
	focused: bool,
	visited: bool,
}

UI_Dropdown :: struct {
	id: string,
	//..
	rect: Rect,
	options: cstring,
	active_index:^i32,
}

UI_Element :: union {
	UI_Dropdown,
}

UI_Window :: struct {	
	using rect: Recti,
	clip_rect: Rect,	
	scroll_pos: Vec2,
	max: Vec2, // NOTE: used to determine the content size
	//..
	cursor:Vec2,  // NOTE: used for layout
	padding:Vec2,  // NOTE: used for layout
	//..
	visible:bool,
	//..
	items:map[string]UI_Data,
	delayed_elements:[dynamic]UI_Element,
	request_lock:bool,
	//..
	font: rl.Font,
	font_size: c.int,
}

g_window: ^UI_Window

ui_start :: proc(window:^UI_Window) -> bool {
	result := window.visible

	clear(&window.delayed_elements)


	if result {			
		//rl.GuiSetFont(window.font)		
		rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), window.font_size)

		window.width = max(window.width, 150)
		window.height = max(window.height, 75)
		window_rect := to_rect(window)

		view_pos := to_vec2(g_mem.view.position)

		window_rect.x += view_pos.x
		window_rect.y += view_pos.y

		max := &window.max
		max.x = math.max(max.x, f32(window.clip_rect.width))		
		max.y = math.max(max.y, f32(window.clip_rect.height))

		content_rect := Rect {0, 0, max.x, max.y }
		max^ = {}

		rl.DrawRectangleRec(window_rect, rl.WHITE)
		rl.GuiScrollPanel(window_rect, nil, content_rect, &window.scroll_pos, &window.clip_rect)

		clip_rect := to_recti(window.clip_rect)

		rl.BeginScissorMode(clip_rect.x, clip_rect.y, clip_rect.width, clip_rect.height)

		window.cursor = window.scroll_pos + view_pos
	}
	return result
}


ui_end :: proc() {
	if g_window != nil {		
		rl.EndScissorMode()	
		
		#reverse for element_ in window.delayed_elements {		
			switch element in element_ {
			case UI_Dropdown: {

			}
			}
		}

		for key, item in window.items {
			if !item.visited {
				delete_key(&window.items, key)
			}
		}
	}
}

push_ui_element :: proc(window: ^UI_Window, ui_element: UI_Element) {
	if len(window.delayed_elements) < cap(window.delayed_elements) {
		append(&window.delayed_elements, ui_element)
	} else {
		assert(false)
	}
}

get_ui_data :: proc(window: ^UI_Window, id: string) -> ^UI_Data {
	result := &window.items[id]
	if result == nil {
		g_editor.window.items[id] = {}
		result = &g_editor.window.items[id]
	}
	result.visited = true
	return result
}

ui_get_next_pos :: proc(window:^UI_Window) -> Vec2 {	
	result := window.cursor + to_vec2(window.position) + window.padding
	return result
}

ui_push_item_dim :: proc(window:^UI_Window, dim:Vec2) {
	window.cursor.y += dim.y
	window.max.y += dim.y
	window.max.x = math.max(window.max.x, dim.x)
}

ui_text_box :: proc(id: string, width: f32) {
	window := &g_editor.window

	item_data := get_ui_data(window, id)

	pos := ui_get_next_pos(window)
	if(rl.GuiTextBox({pos.x, pos.y, width, ATLAS_FONT_SIZE}, cstring(&g_input_buffer[0]), cap(g_input_buffer), item_data.focused)) {
		item_data.focused = !item_data.focused
	}

	dim := Vec2 { width, ATLAS_FONT_SIZE } + 2 * window.padding

	ui_push_item_dim(window, dim)
	
}

ui_edit_i32 :: proc() {

}

ui_button :: proc(lable: cstring) -> bool {
	window := &g_editor.window
	pos := ui_get_next_pos(window)

	size := Vec2 {f32(rl.MeasureText(lable, window.font_size)), f32(window.font_size)}
	rect := Rect {pos.x, pos.y, size.x, size.y}

	rl.DrawRectangleRec(rect, rl.RED)
	result := false//rl.GuiButton(rect, lable)
	dim := size + 2 * window.padding
	ui_push_item_dim(window, dim)
	return result
}

ui_draw_text :: proc(text: cstring) {
	window := &g_editor.window

	pos := ui_get_next_pos(window)
	dim := Vec2 {f32(rl.MeasureText(text, window.font_size)), f32(window.font_size)}
	rect := Rect {pos.x, pos.y, dim.x, dim.y} 
	rl.DrawRectangleRec(rect, rl.RED)
	rl.GuiLabel(rect, text)
	size := dim + 2 * window.padding
	ui_push_item_dim(window, size)
}

ui_dropdown :: proc(id: string, options:cstring, index: ^c.int) {
	window := &g_editor.window	

	item_data := get_ui_data(window, id)
	pos := ui_get_next_pos(window)
	rect := Rect {pos.x, pos.y, }
	ui_element := UI_Dropdown { id = id, rect = rect}
	push_ui_element(ui_element)

	ui_push_delayed_element()
}
package game

import "core:reflect"
import "core:strings"
import "core:math"
import "core:c"
import rl "vendor:raylib"

UI_Textbox_Data :: struct {
	index: u32,
}

UI_Dropdown_Data :: struct {
	rect: Rect,
	options: cstring,
	index:c.int,
	was_focused: bool,
}

UI_Data :: union {
	UI_Textbox_Data,
	UI_Dropdown_Data,
}

UI_State :: struct {
	focused: bool,
	visited: bool,
	data: UI_Data,
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
	lockui: bool,
	//..
	items:map[string]UI_State,
	delayed_items:[dynamic]^UI_State,
	request_lock:bool,
	//..
	font: rl.Font,
	font_size: c.int,
}

g_window: ^UI_Window

Input_Buffer :: [64]u8

g_buffers:[2]Input_Buffer
g_buffer_index:u32 = 0

//..

copy_string_to_buffer :: proc(dest:[]u8, src:string) {
	assert(len(src) <= len(dest))
	for i in 0..<len(src) {
		dest[i] = src[i]
	}
	dest[len(src)] = 0
}


//..

ui_start :: proc(window:^UI_Window) -> bool {
	assert(g_window == nil, "make sure to call ui_end before calling ui_start")

	result := window.visible
	clear(&window.delayed_items)

	if result {			
		g_window = window
		rl.GuiSetFont(window.font)		
		rl.GuiSetStyle(.DEFAULT, i32(rl.GuiDefaultProperty.TEXT_SIZE), g_window.font_size)

		g_window.width = max(g_window.width, 150)
		g_window.height = max(g_window.height, 75)
		window_rect := to_rect(g_window)

		view_pos := to_vec2(g_mem.view.position)

		window_rect.x += view_pos.x
		window_rect.y += view_pos.y

		max := &g_window.max
		max.x = math.max(max.x, f32(g_window.clip_rect.width))		
		max.y = math.max(max.y, f32(g_window.clip_rect.height))

		content_rect := Rect {0, 0, max.x, max.y }
		max^ = {}


		rl.DrawRectangleRec(window_rect, rl.WHITE)
		rl.GuiScrollPanel(window_rect, nil, content_rect, &g_window.scroll_pos, &g_window.clip_rect)

		if g_window.lockui {
			rl.GuiLock()
		}
		clip_rect := to_recti(g_window.clip_rect)

		rl.BeginScissorMode(clip_rect.x, clip_rect.y, clip_rect.width, clip_rect.height)

		g_window.cursor = g_window.scroll_pos + view_pos
	}
	return result
}


ui_end :: proc() {
	assert(g_window != nil)
	g_window.lockui = false
	
	#reverse for item in g_window.delayed_items {
		#partial switch d_ in item.data {
		case UI_Dropdown_Data: {
			data, _ := &item.data.(UI_Dropdown_Data)
			data.was_focused = item.focused
			if(rl.GuiDropdownBox(data.rect, data.options, &data.index, item.focused)) {
				item.focused = !item.focused
			}

			if(item.focused) {
				g_window.lockui = true
			}
		}
		}
	}

	rl.EndScissorMode()
	rl.GuiUnlock()

	for key, item in g_window.items {
		if !item.visited {
			delete_key(&g_window.items, key)
		}
	}

	g_window = nil
}

ui_push_delayed_item :: proc(ui_item: ^UI_State) {
	assert(g_window != nil)
	if len(g_window.delayed_items) < cap(g_window.delayed_items) {
		append(&g_window.delayed_items, ui_item)
	} else {
		assert(false)
	}
}

get_ui_data :: proc(id: string) -> ^UI_State {
	assert(g_window != nil)
	result := &g_window.items[id]
	if result == nil {
		g_window.items[id] = {}
		result = &g_window.items[id]
	}
	result.visited = true
	return result
}

ui_get_next_pos :: proc() -> Vec2 {	
	assert(g_window != nil)
	result := g_window.cursor + to_vec2(g_window.position) + g_window.padding
	return result
}

ui_push_item_dim_bounds :: proc(cursor_dim:Vec2, bounds_dim:Vec2) {
	assert(g_window != nil)
	abs_cursor_y := g_window.cursor.y - f32(g_mem.view.position.y) - g_window.scroll_pos.y
	g_window.cursor.y += cursor_dim.y
	g_window.max.y = math.max(g_window.max.y, abs_cursor_y + bounds_dim.y)
	g_window.max.x = math.max(g_window.max.x, bounds_dim.x)
}


ui_push_item_dim :: proc(dim:Vec2) {
	ui_push_item_dim_bounds(dim, dim)
}

ui_text_box :: proc(id: string, target:^string, width: f32) {
	assert(g_window != nil)

	item_data := get_ui_data(id)
	pos := ui_get_next_pos()

	target_string:cstring

	if item_data.focused {
		assert(item_data.data != nil)
		data, ok := item_data.data.(UI_Textbox_Data)
		assert(ok)
		target_string = cstring(&g_buffers[data.index][0])
	} else {
		target_string = strings.clone_to_cstring(target^, allocator = context.temp_allocator)
	}
	
	if(rl.GuiTextBox({pos.x, pos.y, width, ATLAS_FONT_SIZE}, target_string, cap(g_buffers[0]), item_data.focused)) {
		item_data.focused = !item_data.focused
		if item_data.focused {
			index := g_buffer_index
			item_data.data = UI_Textbox_Data { index = index }
			#assert(((len(g_buffers) - 1) & len(g_buffers)) == 0) // NOTE: is power of two
			g_buffer_index = (g_buffer_index + 1) & (len(g_buffers) - 1)

			copy_string_to_buffer(g_buffers[index][:], target^)
		} else {
			delete(target^)
			target^ = strings.clone(string(target_string))
		}
	}

	dim := Vec2 { width, ATLAS_FONT_SIZE } + 2 * g_window.padding

	ui_push_item_dim(dim)
	
}

ui_edit_i32 :: proc() {

}

ui_button :: proc(lable: cstring) -> bool {
	assert(g_window != nil)
	pos := ui_get_next_pos()

	size := Vec2 {f32(rl.MeasureText(lable, g_window.font_size)) + 10, f32(g_window.font_size) + 6}
	rect := Rect {pos.x, pos.y, size.x, size.y}

	rl.DrawRectangleRec(rect, rl.RED)
	result := rl.GuiButton(rect, lable)
	dim := size + 2 * g_window.padding
	ui_push_item_dim(dim)
	return result
}

ui_draw_text :: proc(text: cstring) {
	assert(g_window != nil)
	pos := ui_get_next_pos()
	size := Vec2 {f32(rl.MeasureText(text, g_window.font_size)) + f32(len(text) * 2), f32(g_window.font_size)}
	rect := Rect {pos.x, pos.y, size.x, size.y} 
	rl.DrawRectangleRec(rect, rl.RED)
	rl.GuiLabel(rect, text)
	dim := size + 2 * g_window.padding
	ui_push_item_dim(dim)
}

ui_dropdown :: proc(id:string, options:cstring, index:^c.int, width:u32 ) {
	assert(g_window != nil)
	ui_data := get_ui_data(id)

	pos := ui_get_next_pos()
	size := Vec2 {f32(width), f32(g_window.font_size) + 12}
	rect := Rect {pos.x, pos.y, size.x, size.y}

	dim := size + 2 * g_window.padding

	if ui_data.focused {
		option_count := 1
		s_options := string(options)
		for r in s_options {
			if r == ';' { 
				option_count += 1
			}
		}
		spacing := rl.GuiGetStyle(.DROPDOWNBOX, c.int(rl.GuiDropdownBoxProperty.DROPDOWN_ITEMS_SPACING))
		bounds := dim
		bounds.y += (f32(spacing) + size.y) * f32(option_count)
		ui_push_item_dim_bounds(dim, bounds)
	} else {
		ui_push_item_dim(dim)
	}	

	dropdown_data, ok := &ui_data.data.(UI_Dropdown_Data)
	if !ok {
		ui_data.data = UI_Dropdown_Data {}
		dropdown_data, ok = &ui_data.data.(UI_Dropdown_Data)
	}

	dropdown_data.rect = rect
	dropdown_data.options = options

	if dropdown_data.was_focused {
		index^ = dropdown_data.index
	} else {
		dropdown_data.index = index^
	}

	ui_push_delayed_item(ui_data)
}

ui_union_dropdown :: proc(id:string, target:^$T, width:u32) {
	if target != nil {		
		u_id := typeid_of(type_of(target^))
		type_info := reflect.type_info_base(type_info_of(u_id))

		if info, ok := type_info.variant.(reflect.Type_Info_Union); ok {
			options := make([dynamic]string, allocator = context.temp_allocator)
			
			for v in info.variants {
				named_type, is_named := v.variant.(reflect.Type_Info_Named)
				if is_named {
					append(&options, named_type.name)
				}			
			}
			
			tag: i32 = cast(i32)reflect.get_union_variant_raw_tag(target^)		
			if !info.no_nil {
				if tag == 0 {
					// TODO: error handling
					return
				}
				tag -= 1
			}

			ui_data := get_ui_data(id)
			dropdown_data, is_dropdown := ui_data.data.(UI_Dropdown_Data)

			if is_dropdown && dropdown_data.was_focused {
				if dropdown_data.index != tag {
					tag = dropdown_data.index
					raw_tag := tag if info.no_nil else (tag + 1)
					reflect.set_union_variant_raw_tag(target^, i64(raw_tag))
				}
			}

			temp := strings.join(options[:], ";", allocator = context.temp_allocator)
			csoptions := strings.clone_to_cstring(temp, allocator = context.temp_allocator)

			index:c.int = i32(tag)
			ui_dropdown(id, csoptions, &index, width)
		} else {
			// TODO: error handling
		}
	} else {
		// TODO: erro handling
	}

}
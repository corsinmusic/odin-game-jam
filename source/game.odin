/*
This file is the starting point of your game.

Some important procedures are:
- game_init_window: Opens the window
- game_init: Sets up the game state
- game_update: Run once per frame
- game_should_close: For stopping your game when close button is pressed
- game_shutdown: Shuts down game and frees memory
- game_shutdown_window: Closes window

The procs above are used regardless if you compile using the `build_release`
script or the `build_hot_reload` script. However, in the hot reload case, the
contents of this file is compiled as part of `build/hot_reload/game.dll` (or
.dylib/.so on mac/linux). In the hot reload cases some other procedures are
also used in order to facilitate the hot reload functionality:

- game_memory: Run just before a hot reload. That way game_hot_reload.exe has a
      pointer to the game's memory that it can hand to the new game DLL.
- game_hot_reloaded: Run after a hot reload so that the `g_mem` global
      variable can be set to whatever pointer it was in the old DLL.

NOTE: When compiled as part of `build_release`, `build_debug` or `build_web`
then this whole package is just treated as a normal Odin package. No DLL is
created.
*/

package game

import "core:encoding/json"
import "core:os"
import "core:fmt"
import "core:mem"
import "core:math"
import "core:slice"
import rl "vendor:raylib"


Rect :: rl.Rectangle
Vec2 :: rl.Vector2

// ====================================
// START GAME DATA ====================
// ====================================

PIXEL_WINDOW_WIDTH :: 640
PIXEL_WINDOW_HEIGHT :: 360

WINDOW_CENTER_X :: (PIXEL_WINDOW_WIDTH * 0.5)
WINDOW_CENTER_Y :: (PIXEL_WINDOW_HEIGHT * 0.5)
CLEAR_COLOR : rl.Color : {80, 10, 70, 255}

WORLD_PATH_JSON :: "assets/world.json"
WORLD_PATH_SPF :: "assets/world.spf"



Sleeping_Berth :: struct {
}

Canteen :: struct {
    // NOTE: gally and crew mess
}

Engine_Room :: struct {
}

Filtration_System :: struct {
}

Cockpit :: struct {
}

Aquaponic_Room :: struct {
}

Infirmary :: struct {
}

Room_Variant :: union #no_nil {
    Sleeping_Berth,
    Canteen,
    Engine_Room,
    Filtration_System,
    Cockpit,
    Aquaponic_Room,
    Infirmary,    
}

Room_Connection :: struct {
    a_idx: u32,
    b_idx: u32,
    distance: i32, // cost for path
}

Room :: struct {
    using rect: Recti,
    connections: [dynamic]u32,
    variant_data: Room_Variant,
}

//..

World :: struct {
    rooms: [dynamic]Room,
    connections: [dynamic]Room_Connection,

}

Game_View :: struct {
    using camera: rl.Camera2D,           
    using position: Vec2i,
}

//..

Node_Info :: struct {
    prev_room_idx: u32,
    room_idx: u32,
    total_distance: i32,    
    connection_idx: int,
}

//..

Player :: struct {
    room_idx: u32,
}

//..

Game_Memory :: struct {
    atlas: rl.Texture,
    font: rl.Font,
    music: rl.Music,
    //..
    view: Game_View,
    world: World,
    player: Player,
    //..
    run: bool,
    //..
    editor_state: Editor_State,
    //..
    grg: Render_Group,
}

g_mem: ^Game_Memory

// ====================================
// START GAME CODE ====================
// ====================================

create_room :: proc(rect: Recti) -> Room {
    result := Room {
        rect = rect,
    }
    return result
}

//..

get_game_mouse_position :: proc() -> Vec2 {
    view := g_mem.view    

    position : Vec2 = to_vec2(view.position)
    result: Vec2 = (rl.GetMousePosition() - position) / view.zoom

    return result
}

//..

push_room_connection :: proc(connection: Room_Connection, color: rl.Color, font_size: f32) {
    a := g_mem.world.rooms[connection.a_idx]
    b := g_mem.world.rooms[connection.b_idx]

    a_pos := get_rect_center(to_rect(a.rect))
    b_pos := get_rect_center(to_rect(b.rect))
    
    grc := &g_mem.grg.commands    

    distance := fmt.caprintf("%v", connection.distance, allocator = g_mem.grg.arena_allocator)    

    dim := rl.MeasureTextEx(rl.GetFontDefault(), distance, font_size, 1)
    radius := max(10, dim.x * 0.5)
    center := (a_pos + b_pos) * 0.5
    
    push_line(grc, a_pos, b_pos, 2, color)
    push_circle(grc, center, radius + 2, color)
    push_circle(grc, center, radius, rl.WHITE)
    push_text(grc, rl.GetFontDefault(), distance, center - dim * 0.5, font_size, 1, color)
}

// =================================
// NOTE: update ====================
// =================================

update :: proc() {

    if (rl.IsKeyDown(.RIGHT_ALT) || rl.IsKeyDown(.LEFT_ALT)) && rl.IsKeyPressed(.ENTER) {
        rl.ToggleBorderlessWindowed()
    }

    if rl.IsKeyDown(.Q) && rl.IsKeyPressed(.ESCAPE) {
        g_mem.run = false
    }    


    // NOTE: START show shortest path

    if !g_mem.editor_state.window.visible &&
        g_mem.editor_state.mode == .Idle {

        mouse_pos := get_game_mouse_position()
        target_room_idx := -1
        for room, idx in g_mem.world.rooms {
            if is_in_rectangle(room, mouse_pos) {
                target_room_idx = idx
                break
            }
        }

        if target_room_idx >= 0 && 
        target_room_idx < len(g_mem.world.rooms) {
            

            path := make([dynamic]Node_Info, 0, len(g_mem.world.rooms), allocator = context.temp_allocator)
            
            prev_node := Node_Info { room_idx = u32(g_mem.player.room_idx), connection_idx = -1 }            
            append(&path, prev_node)
            node_table_ := make([]i32, len(g_mem.world.rooms), allocator = context.temp_allocator)            
            for &node in node_table_ {
                node = -1
            }
            node_table_[prev_node.room_idx] = 0
            
            target_idx := u32(target_room_idx)

            processed_room_count := 0

            for prev_node.room_idx != target_idx {
                prev_room := g_mem.world.rooms[prev_node.room_idx]
                for connection_idx in prev_room.connections {
                    connection := g_mem.world.connections[connection_idx]

                    room_idx := connection.a_idx if connection.a_idx != prev_node.room_idx else connection.b_idx
                    node_idx := node_table_[room_idx]
                    
                    new_node: Node_Info
                    add_new_node := true
                    if node_idx >= 0 {           
                        node := path[node_idx]
                        new_node.total_distance = prev_node.total_distance + connection.distance 
                        if node.total_distance > new_node.total_distance {
                            ordered_remove(&path, node_idx)
                            node.total_distance = new_node.total_distance
                            new_node = node
                            new_node.prev_room_idx = prev_node.room_idx
                            new_node.connection_idx = int(connection_idx)
                        } else {
                            add_new_node = false
                        }
                    } else {
                        new_node = Node_Info {
                            prev_room_idx = prev_node.room_idx,
                            room_idx = room_idx,
                            connection_idx = int(connection_idx),
                            total_distance = prev_node.total_distance + connection.distance,
                        }
                    }

                    if add_new_node {
                        // NOTE: ordered insert      
                        added_node := false
                        for idx := len(path) - 1; idx >= processed_room_count; idx -= 1 {
                            test_node := path[idx]
                            if test_node.total_distance <= new_node.total_distance {
                                new_idx := idx + 1
                                inject_at(&path, new_idx, new_node)
                                node_table_[room_idx] = i32(new_idx)
                                for moved_idx in (new_idx + 1)..<len(path) {
                                    node := &path[moved_idx]
                                    node_table_[node.room_idx] = i32(moved_idx)
                                }
                                added_node = true
                                break
                            }
                        }

                        assert(added_node)
                    }
                }

                processed_room_count += 1
                prev_node = path[processed_room_count]                
            }

            if prev_node.connection_idx >= 0 {                
                connection := g_mem.world.connections[prev_node.connection_idx]
                push_room_connection(connection, rl.BLACK, 12)
                for prev_node.prev_room_idx != g_mem.player.room_idx {               
                    node_idx := node_table_[prev_node.prev_room_idx]
                    prev_node = path[node_idx]
                    connection = g_mem.world.connections[prev_node.connection_idx]
                    push_room_connection(connection, rl.BLACK, 12)
                }

                if rl.IsMouseButtonPressed(.LEFT) {
                    g_mem.player.room_idx = target_idx
                }
            }
        }
    }

    // NOTE: END   show shortest path

}

// NOTE: drawing

calculate_room_dim :: proc(rect_dim:i32, tile_dim: i32) -> (i32, f32, f32) {

    tile_dim_f32 := cast(f32)tile_dim

    min_start_size :: 2
    tile_count := (rect_dim - min_start_size) / tile_dim
    start_size: f32
    end_size: f32

    if tile_count > 0 {
        end_size = tile_dim_f32        
        start_size = cast(f32)(rect_dim - tile_count * tile_dim)
        tile_count -=1
    } else {
        start_size = min_start_size
        end_size = cast(f32)rect_dim - start_size
    }

    return tile_count, start_size, end_size
}

draw_room :: proc(room_rect : Recti) {

    if room_rect.width > 2 && room_rect.height > 2 {
        room := atlas_textures[.Room]
        assert(room.width == room.height)    
        tile_dim_f32 := room.width / 3
        tile_dim := cast(i32)tile_dim_f32

        tile_count_x, start_size_x, end_size_x := calculate_room_dim(room_rect.width, tile_dim)
        tile_count_y, start_size_y, end_size_y := calculate_room_dim(room_rect.height, tile_dim)


        y := cast(f32)room_rect.y
        x := cast(f32)room_rect.x

        _x := x

        rl.DrawTextureRec(g_mem.atlas, {0, 0, start_size_x, start_size_y}, {_x, y}, rl.WHITE)    
        _x += start_size_x
        for i in 0..<tile_count_x {
            rl.DrawTextureRec(g_mem.atlas, {tile_dim_f32, 0, tile_dim_f32, start_size_y}, {_x + cast(f32)(i * tile_dim), y}, rl.WHITE)
        }
        _x += cast(f32)(tile_count_x * tile_dim)
        rl.DrawTextureRec(g_mem.atlas, {tile_dim_f32 * 3 - end_size_x, 0, end_size_x, start_size_y}, {_x, y}, rl.WHITE)

        y += start_size_y
        
        for _ in 0..<tile_count_y {
            _x = x

            rl.DrawTextureRec(g_mem.atlas, {0, tile_dim_f32, start_size_x, tile_dim_f32}, {_x, y}, rl.WHITE)    
            _x += start_size_x
            for i in 0..<tile_count_x {
                rl.DrawTextureRec(g_mem.atlas, {tile_dim_f32, tile_dim_f32, tile_dim_f32, tile_dim_f32}, {_x + cast(f32)(i * tile_dim), y}, rl.WHITE)
            }
            _x += cast(f32)(tile_count_x * tile_dim)
            rl.DrawTextureRec(g_mem.atlas, {tile_dim_f32 * 3 - end_size_x, tile_dim_f32, end_size_x, tile_dim_f32}, {_x, y}, rl.WHITE)

            y += tile_dim_f32
        }
        
        _x = x

        rl.DrawTextureRec(g_mem.atlas, {0, tile_dim_f32 * 3 - end_size_y, start_size_x, end_size_y}, {_x, y}, rl.WHITE)    
        _x += start_size_x
        for i in 0..<tile_count_x {
            rl.DrawTextureRec(g_mem.atlas, {tile_dim_f32, tile_dim_f32 * 3 - end_size_y, tile_dim_f32, end_size_y}, {_x + cast(f32)(i * tile_dim), y}, rl.WHITE)
        }
        _x += cast(f32)(tile_count_x * tile_dim)
        rl.DrawTextureRec(g_mem.atlas, {tile_dim_f32 * 3 - end_size_x, tile_dim_f32 * 3 - end_size_y, end_size_x, end_size_y}, {_x, y}, rl.WHITE)
    }    
}

draw :: proc() {    

    view := &g_mem.view   

    w : f32 = cast(f32)rl.GetScreenWidth()
    h : f32 = cast(f32)rl.GetScreenHeight()    
    
    scale_x := w / PIXEL_WINDOW_WIDTH
    scale_y := h / PIXEL_WINDOW_HEIGHT

    if scale_x < scale_y {
        view.zoom = math.floor(scale_x)
    } else {
        view.zoom = math.floor(scale_y)
    }
    
    width := PIXEL_WINDOW_WIDTH * view.zoom
    height := PIXEL_WINDOW_HEIGHT * view.zoom

    view.position = { cast(i32)math.round((w - width) * 0.5), cast(i32)math.round((h - height) * 0.5) }
    view.offset = to_vec2(view.position) + Vec2 {WINDOW_CENTER_X, WINDOW_CENTER_Y} * view.zoom
    view.target = {WINDOW_CENTER_X, WINDOW_CENTER_Y}


    rl.BeginDrawing()
    rl.ClearBackground(CLEAR_COLOR)
    rl.BeginMode2D(view.camera)

    rl.DrawRectangleRec({-3, -3, PIXEL_WINDOW_WIDTH + 6, PIXEL_WINDOW_HEIGHT + 6}, rl.BLACK)
    rl.DrawRectangleRec({0, 0, PIXEL_WINDOW_WIDTH, PIXEL_WINDOW_HEIGHT}, CLEAR_COLOR)

    for room in g_mem.world.rooms {        
        draw_room(room.rect)
    }

    // NOTE: editor
    draw_editor()
    draw_render_commands(g_mem.grg.commands)
    clear_render_group(&g_mem.grg)
    //..
    
    rl.EndMode2D()

    draw_editor_ui()
    
    rl.EndDrawing()        
}

main_update :: proc() {
    update_editor()
    update()
    draw()
}

@(export)
game_update :: proc() {    
    when ODIN_DEBUG {
        if rl.IsWindowFocused() {        
            main_update()
        } else {      
          rl.EndDrawing() // TODO: find a better way to make sure Window can get focused again.
        } 
    } else {
        main_update()
    }
}

//..
// NOTE: FONTS

delete_atlased_font :: proc(font: rl.Font) {
    delete(slice.from_ptr(font.glyphs, int(font.glyphCount)))
    delete(slice.from_ptr(font.recs, int(font.glyphCount)))
}

// This uses the letters in the atlas to create a raylib font. Since this font is in the atlas
// it can be drawn in the same draw call as the other graphics in the atlas. Don't use
// rl.UnloadFont() to destroy this font, instead use `delete_atlased_font`, since we've set up the
// memory ourselves.
//
// The set of available glyphs is governed by `LETTERS_IN_FONT` in `atlas_builder.odin`
// The font used is governed by `FONT_FILENAME` in `atlas_builder.odin`
load_atlased_font :: proc(atlas: ^rl.Texture) -> rl.Font {
    num_glyphs := len(atlas_glyphs)
    font_rects := make([]Rect, num_glyphs)
    glyphs := make([]rl.GlyphInfo, num_glyphs)    

    for ag, idx in atlas_glyphs {
        font_rects[idx] = ag.rect
        glyphs[idx] = {
            value = ag.value,
            offsetX = i32(ag.offset_x),
            offsetY = i32(ag.offset_y),
            advanceX = i32(ag.advance_x),
        }
    } 

    return {
        baseSize = ATLAS_FONT_SIZE,
        glyphCount = i32(num_glyphs),
        glyphPadding = 0,
        texture = atlas^,
        recs = raw_data(font_rects),
        glyphs = raw_data(glyphs),
    }
}

//..

// =================================
// NOTE: init ======================
// =================================


@(export)
game_init_window :: proc() {    
    rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
    rl.InitWindow(1280, 720, "Odin + Raylib + Hot Reload template!")
    rl.SetWindowPosition(200, 200)
    rl.SetTargetFPS(500)
    rl.SetExitKey(nil)
}

@(export)
game_init :: proc() {
    g_mem = new(Game_Memory)
    rl.InitAudioDevice()

    atlas := rl.LoadTexture(TEXTURE_ATLAS_FILENAME)    
    rl.SetTextureFilter(atlas, .POINT)

    g_mem^ = Game_Memory {
        run = true,
        atlas = atlas,
        font = load_atlased_font(&atlas),
        view = Game_View {
            camera = {
                offset = { WINDOW_CENTER_X, WINDOW_CENTER_Y },
                target = { WINDOW_CENTER_X, WINDOW_CENTER_Y },
            },
        },
    }
    
    if load_world(&g_mem.world, WORLD_PATH_SPF) {        
        // NOTE: delete invalid rooms        
        for i := 0; i < len(g_mem.world.rooms); i += 1 {
            room := g_mem.world.rooms[i]
            if room.rect.width <= 2 || room.rect.height <= 2 {
                ordered_remove(&g_mem.world.rooms, i)
                fmt.printfln("removed invalid room %v", room)                
                i -= 1                
            }
        }
    } else {
        delete_world(&g_mem.world)
        g_mem.world = {}
    }

    init_render_group(&g_mem.grg, 128 * mem.Kilobyte)

    game_hot_reloaded(g_mem)    
    editor_init()
}

@(export)
game_should_run :: proc() -> bool {
    when ODIN_OS != .JS {
        // Never run this proc in browser. It contains a 16 ms sleep on web!
        if rl.WindowShouldClose() {
            return false
        }
    }

    return g_mem.run
}

@(export)
game_shutdown :: proc() {
    save_world(&g_mem.world, WORLD_PATH_SPF)

    editor_shutdown()
    delete_atlased_font(g_mem.font)
    rl.UnloadTexture(g_mem.atlas)
    rl.UnloadMusicStream(g_mem.music)
    rl.CloseAudioDevice()
    delete_world(&g_mem.world)
    delete_render_group(&g_mem.grg)
    free(g_mem)    
}

@(export)
game_shutdown_window :: proc() {
    rl.CloseWindow()
}

@(export)
game_memory :: proc() -> rawptr {
    return g_mem
}

@(export)
game_memory_size :: proc() -> int {
    return size_of(Game_Memory)
}

@(export)
game_hot_reloaded :: proc(mem: rawptr) {    
    g_mem = (^Game_Memory)(mem)
    g_editor = &g_mem.editor_state
    editor_hot_reload()
}

@(export)
game_force_reload :: proc() -> bool {
    return rl.IsKeyPressed(.F5)
}

@(export)
game_force_restart :: proc() -> bool {
    return rl.IsKeyPressed(.F6)
}

// In a web build, this is called when browser changes size. Remove the
// `rl.SetWindowSize` call if you don't want a resizable game.
game_parent_window_size_changed :: proc(w, h: int) {
    rl.SetWindowSize(i32(w), i32(h))
}

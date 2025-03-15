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
//import "core:math/linalg"
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

WORLD_PATH :: "assets/world.json"

Room :: struct {
    using rect: Recti,
}




World :: struct {
    rooms: [dynamic] Room,
}

Game_View :: struct {
    using camera: rl.Camera2D,           
    using position: Vec2i,
}

//..

Game_Memory :: struct {
    view: Game_View,
    atlas: rl.Texture,
    font: rl.Font,
    music: rl.Music,
    world: World,
    run: bool,
    //..
    editor_state: Editor_State,
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

// =================================
// NOTE: update ====================
// =================================

update :: proc() {

    if (rl.IsKeyDown(.RIGHT_ALT) || rl.IsKeyDown(.LEFT_ALT)) && rl.IsKeyPressed(.ENTER) {
        rl.ToggleBorderlessWindowed()
    }

    if rl.IsKeyPressed(.ESCAPE) {
        g_mem.run = false
    }    
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

    //..
/*
    mouse_pos := get_game_mouse_position()
    rl.DrawTextEx(g_mem.font, 
        fmt.ctprintfln("mouse pos %v \nzoom: %v\noffset: %v\ntarget: %v",
        mouse_pos, 
        view.zoom,
        view.offset,
        view.target), {}, 32 / view.zoom, 0, rl.WHITE)
  */  
    rl.EndMode2D()

    draw_editor_ui()
    
/*
    room_texture := atlas_textures[.Room]
    m_p := rl.GetMousePosition()
    t :=  cast(f32)(1 + math.sin(rl.GetTime() * 0.5)) * 0.5

    rl.DrawTexturePro(g_mem.atlas, room_texture.rect, {m_p.x, m_p.y, room_texture.document_size.x * ((t * 4) + 1), room_texture.document_size.y * (t * 4 + 1)}, {}, t * 360, rl.WHITE)
*/
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
    
    if world_data, success := os.read_entire_file(WORLD_PATH, allocator = context.temp_allocator); success {
        json.unmarshal(world_data, &g_mem.world)

        // NOTE: delete invalid rooms        
        for i := 0; i < len(g_mem.world.rooms); i += 1 {
            room := g_mem.world.rooms[i]
            if room.width <= 2 || room.height <= 2 {
                ordered_remove(&g_mem.world.rooms, i)
                fmt.printfln("removed invalid room %v", room)                
                i -= 1                
            }
        }
    }

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
    if world_data, err := json.marshal(g_mem.world, allocator = context.temp_allocator); err == nil {
        os.write_entire_file(WORLD_PATH, world_data)
    }

    editor_shutdown()
    delete_atlased_font(g_mem.font)
    rl.UnloadTexture(g_mem.atlas)
    rl.UnloadMusicStream(g_mem.music)
    rl.CloseAudioDevice()    
    delete(g_mem.world.rooms)
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

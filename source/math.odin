package game

import "core:math"

Vec2i :: [2]i32

length_sq :: proc {
    length_sq_vec2i,
    length_sq_ve2,
}

length_sq_vec2i :: proc(p: Vec2i) -> i32 {
    result := p.x * p.x + p.y * p.y
    return result
}

length_sq_ve2 :: proc(p: Vec2) -> f32 {
    result := p.x * p.x + p.y * p.y
    return result
}

to_vec2i :: proc(p: Vec2) -> [2]i32 {
    result := Vec2i { 
        cast(i32)math.round(p.x), 
        cast(i32)math.round(p.y),
    }
    return result
}

to_vec2 :: proc(p: Vec2i) -> Vec2 {
    result := Vec2 { cast(f32)p.x, cast(f32)p.y}
    return result
}

Recti :: struct {    
    using position: Vec2i,
    width: i32,
    height: i32,
}

get_rect_max :: proc {
    get_rect_max_f32,
    get_rect_max_i32,
}

get_rect_max_f32 :: proc(rect: Rect) -> Vec2 {
    result := Vec2 {rect.x, rect.y} + Vec2 {rect.width, rect.height}
    return result
}

get_rect_max_i32 :: proc(rect: Recti) -> Vec2i {
    result := rect.position + Vec2i {rect.width, rect.height}
    return result
}

is_in_rectangle :: proc {
    is_in_rectangle_i32,
    is_in_rectangle_f32,
    is_in_rectangle_i32_f32,
    is_in_rectangle_f32_i32,
}

is_in_rectangle_i32 :: proc(rect: Recti, p: Vec2i) -> bool {
    rect_max := get_rect_max(rect)
    result := (p.x >= rect.x && p.x < rect_max.x &&
               p.y >= rect.y && p.y < rect_max.y)
    return result
}

is_in_rectangle_f32 :: proc(rect: Rect, p: Vec2) -> bool {
    rect_max := get_rect_max(rect)
    result := (p.x >= rect.x && p.x < rect_max.x &&
               p.y >= rect.y && p.y < rect_max.y)
    return result
}

is_in_rectangle_i32_f32 :: proc(rect_: Recti, p: Vec2) -> bool {
    rect := to_rect(rect_)
    rect_max := get_rect_max(rect)
    result := (p.x >= rect.x && p.x < rect_max.x &&
               p.y >= rect.y && p.y < rect_max.y)
    return result
}

is_in_rectangle_f32_i32 :: proc(rect: Rect, p_: Vec2i) -> bool {
    p := to_vec2(p_)
    rect_max := get_rect_max(rect)
    result := (p.x >= rect.x && p.x < rect_max.x &&
               p.y >= rect.y && p.y < rect_max.y)
    return result
}

to_recti :: proc(rect: Rect) -> Recti {
    result := Recti {
        x = cast(i32)math.round(rect.x), 
        y = cast(i32)math.round(rect.y), 
        width = cast(i32)math.round(rect.width), 
        height = cast(i32)math.round(rect.height),
    }

    return result
}

to_rect :: proc(recti: Recti) -> Rect {
    result := Rect {
        f32(recti.x), 
        f32(recti.y), 
        f32(recti.width), 
        f32(recti.height),
    }

    return result
}
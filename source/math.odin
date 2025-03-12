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

get_rect_max :: proc(rect: Recti) -> Vec2i {
    result := rect.position + Vec2i {rect.width, rect.height}
    return result
}

is_in_rectangle :: proc(rect: Recti, p: Vec2i) -> bool {
    rect_max := get_rect_max(rect)
    result := (p.x >= rect.position.x && p.x < rect_max.x &&
               p.y >= rect.position.y && p.y < rect_max.y)
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
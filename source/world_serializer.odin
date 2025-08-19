package game

import "core:fmt"
import "core:os"

World_Version :: enum u32{
	initial = 0,
	room_variants,
	//..
	LAST_PLUS_ONE,
}

WORLD_VERSION_LATEST :: World_Version(i32(World_Version.LAST_PLUS_ONE) - 1)

// NOTE without versioning

serialize_vec2i :: proc(s: ^Serializer($Version_Enum), datum: ^Vec2i) -> bool {
	serialize_number(s, &datum.x) or_return
	serialize_number(s, &datum.y) or_return
	return true
}

serialize_recti :: proc(s: ^Serializer($Version_Enum), datum: ^Recti) -> bool {
	fmt.printfln("serialize recti")
	serialize_vec2i(s, &datum.position) or_return
	serialize_number(s, &datum.width) or_return
	serialize_number(s, &datum.height) or_return
	return true
}

// with versioning

serialize_sleeping_berth :: proc(s: ^Serializer($Enum_Version), datum: ^Sleeping_Berth) -> bool {
	return true
}

serialize_canteen :: proc(s: ^Serializer($Enum_Version), datum: ^Canteen) -> bool {
	return true
}

serialize_engine_room :: proc(s: ^Serializer($Enum_Version), datum: ^Engine_Room) -> bool {
	return true
}

serialize_filtration_system :: proc(s: ^Serializer($Enum_Version), datum: ^Filtration_System) -> bool {
	return true
}

serialize_cockpit :: proc(s: ^Serializer($Enum_Version), datum: ^Cockpit) -> bool {
	return true
}

serialize_aquaponic_room :: proc(s: ^Serializer($Enum_Version), datum: ^Aquaponic_Room) -> bool {
	return true
}

serialize_infirmary :: proc(s: ^Serializer($Enum_Version), datum: ^Infirmary) -> bool {
	return true
}

serialize_room :: proc(s: ^Serializer($Enum_Version), datum: ^Room) -> bool {

	fmt.printfln("serialize room")

	s_add(s, World_Version.initial, &datum.rect) or_return
	s_add(s, World_Version.room_variants, &datum.connections) or_return
	s_add_union_tag(s, World_Version.room_variants, &datum.variant_data) or_return	
	switch &v in datum.variant_data {
	case Sleeping_Berth: {
		s_add(s, World_Version.room_variants, &v) or_return
	}
	case Canteen: {
		s_add(s, World_Version.room_variants, &v) or_return
	}
	case Engine_Room: {
		s_add(s, World_Version.room_variants, &v) or_return
	}
	case Filtration_System: {
		s_add(s, World_Version.room_variants, &v) or_return
	}
	case Cockpit: {
		s_add(s, World_Version.room_variants, &v) or_return
	}
	case Aquaponic_Room: {
		s_add(s, World_Version.room_variants, &v) or_return
	}
	case Infirmary: {
		s_add(s, World_Version.room_variants, &v) or_return
	}
	}
	return true
}

serialize_room_connection :: proc(s: ^Serializer($Enum_Version), datum: ^Room_Connection) -> bool {
	s_add(s, World_Version.room_variants, &datum.a_idx) or_return
	s_add(s, World_Version.room_variants, &datum.b_idx) or_return
	s_add(s, World_Version.room_variants, &datum.distance) or_return
	return true
}

serialize_world :: proc(s: ^Serializer($Enum_Version), datum: ^World) -> bool {	
	s_add(s, World_Version.initial, &datum.rooms) or_return
	s_add(s, World_Version.room_variants, &datum.connections) or_return
	return true
}

//..

delete_world :: proc(world: ^World) {
	for &room in world.rooms {
		delete(room.connections)
	}
	delete(world.connections)
	delete(world.rooms)
}

MAGIC_NUMBER :: 0x59f59f

main_world_serializer :: proc(s: ^Serializer($Enum_Version), world: ^World) -> bool {		
	magic_number:u32 = MAGIC_NUMBER	
	serialize_number(s, &magic_number) or_return
	if !s.is_writing && magic_number != MAGIC_NUMBER {
		return false
	}
	serialize_basic(s, &s.version) or_return
	serialize_world(s, world) or_return
	return true
}

save_world :: proc(world:^World, path: string) -> bool {
	s, error := create_serializer(World_Version, WORLD_VERSION_LATEST, allocator = context.temp_allocator)
	result := error == nil
	if (result && main_world_serializer(&s, world)) {
		os.write_entire_file(path, s.data[:])
	} else {
		result = false
	}
	
	return result
}

load_world :: proc(world:^World, path: string) -> bool {	
	result := false

	if data, success := os.read_entire_file(path, context.temp_allocator); success {		

		s := create_serializer(World_Version, data)
		if main_world_serializer(&s, world) {
			result = true
		}
	}

	return result
}
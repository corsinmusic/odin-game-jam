package game

import "core:reflect"
import "core:mem"
import "core:fmt"
import "base:runtime"
import "base:intrinsics"

Serializer :: struct ($Version_Enum: typeid) {
	is_writing: bool,
	data: [dynamic]byte,
	read_offset: int,
	version: Version_Enum,
}

//..

create_serializer :: proc {
	create_serializer_read,
	create_serializer_write,
}

create_serializer_write :: proc($Version_Enum: typeid, 
								version: Version_Enum,
								capacity:int = 1024, 
								allocator := context.allocator) -> (Serializer(Version_Enum), mem.Allocator_Error)  {

	result : Serializer(Version_Enum)
	data, ok := make([dynamic]byte, 0, capacity, allocator)

	if ok == nil {
		result =  {
			is_writing = true,
			version = version,
			data = data,
		}
	}

	return result, ok
}

create_serializer_read :: proc($Version_Enum: typeid, data:[]byte) -> Serializer(Version_Enum) {
	result := Serializer(Version_Enum) {
		is_writing = false,
		data = transmute([dynamic]u8)runtime.Raw_Dynamic_Array {
			data = (transmute(runtime.Raw_Slice)data).data,
			len = len(data),
			cap = len(data),
			allocator = runtime.nil_allocator(),
		},
	}

	return result
}

//..

_serialize_bytes :: proc(s: ^Serializer($Version_Enum), data: []byte) -> bool {
	result := true

	if len(data) > 0 {		
		if s.is_writing {
			if _, err := append(&s.data, ..data); err != nil {
				result = false
			}
		} else {
			if len(s.data) >= s.read_offset + len(data) {				
				copy(data, s.data[s.read_offset:][:len(data)])
				s.read_offset += len(data)
			} else {
				result = false
			}
		}
	}

	return result
}

serialize_opaque :: #force_inline proc(s: ^Serializer($Version_Enum), data:^$T) -> bool {
	return _serialize_bytes(s, #force_inline mem.ptr_to_bytes(data))
}

//..

serialize_number :: proc(s: ^Serializer($Version_Enum), datum: ^$T) -> bool 
where (intrinsics.type_is_float(T) || intrinsics.type_is_integer(T)) {
	return serialize_opaque(s, datum)
}

serialize_basic :: proc(s: ^Serializer($Version_Enum), datum: ^$T) -> bool
where (
	intrinsics.type_is_boolean(T) || 
	intrinsics.type_is_enum(T) || 
	intrinsics.type_is_bit_set(T)) {
	return serialize_opaque(s, datum)
}

serialize_dynamic_array :: proc(s: ^Serializer($Version_Enum), data: ^$T/[dynamic]$E) -> bool {	
	len := len(data)
	result := serialize_number(s, &len)
	if result {		
		if !s.is_writing {
			data^ = make([dynamic]E, len, len)
		}

		for &v in data {			
			if !serialize(s, &v) {
				result = false
				break
			}
		}
	}

	return result
}

serialize_union_tag :: proc(s: ^Serializer($Version_Enum), datum: ^$T) -> bool 
where intrinsics.type_is_union(T) {
	result := false
	tag: i64
	if s.is_writing {
		tag = reflect.get_union_variant_raw_tag(datum^)
	}

	if serialize_number(s, &tag) {	
		if !s.is_writing {
			reflect.set_union_variant_raw_tag(datum^, tag)
		}	
		result = true
	}

	return result
}

//..

s_add :: proc(s: ^Serializer($Version_Enum), version: Version_Enum, datum:^$T) -> bool {
	result := true
	if s.version >= version {
		result = serialize(s, datum)
	}
	return result
}

s_add_union_tag :: proc(s: ^Serializer($Version_Enum), version: Version_Enum, datum:^$T) -> bool 
where intrinsics.type_is_union(T) {
	result := true
	if s.version >= version {
		result = serialize_union_tag(s, datum)
	}
	return result
}

s_add_default :: proc(s: ^Serializer($Version_Enum), version: Version_Enum, datum:^$T, default:T) -> bool {
	result := true
	if s.version >= version {
		result = serialize(s, datum)
	} else {
		datum^ = default
	}
	return result
}

s_rem :: proc(s: ^Serializer($Version_Enum), add_version: Version_Enum, rem_version: Version_Enum, datum:^$T) -> bool {
	result := true

	if s.version >= add_version && u32(s.version) < rem_version {
		result = serialize(s, datum)
	}

	return result
}

s_rem_union_tag :: proc(s: ^Serializer($Version_Enum), add_version: Version_Enum, rem_version: Version_Enum, datum:^$T) -> bool 
where intrinsics.type_is_union(T) {
	result := true

	if s.version >= add_version && u32(s.version) < rem_version {
		result = serialize(s, datum)
	}

	return result
}

s_rem_default :: proc(s: ^Serializer($Version_Enum), add_version: Version_Enum, rem_version: Version_Enum, datum:^$T, default:T) -> bool {
	result := true

	if s.version >= add_version && s.version < rem_version {
		result = serialize(s, &datum)
	} else {
		datum^ = default
	}

	return result
}
package game

serialize :: proc {
	serialize_number,
	serialize_basic,
	serialize_dynamic_array,

	// Custom

	// World
	serialize_room,
	serialize_room_connection,
	serialize_sleeping_berth,
	serialize_canteen,
	serialize_engine_room,
	serialize_filtration_system,
	serialize_cockpit,
	serialize_aquaponic_room,
	serialize_infirmary,

	// without versioning
	serialize_recti,
	serialize_vec2i,
}
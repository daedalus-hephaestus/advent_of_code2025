package giftshop

import "core:fmt"
import "core:mem"
import "core:os/os2"
import "core:strconv"
import "core:strings"

file :: "input"

main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				for _, entry in track.allocation_map {
					fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)
				}
			}
			if len(track.bad_free_array) > 0 {
				for entry in track.bad_free_array {
					fmt.eprintf("%v bad free at %v\n", entry.location, entry.memory)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	data, err := os2.read_entire_file_from_path(file, context.allocator)
	defer delete(data)

	if err != .NONE {
		fmt.eprintln(err)
		os2.exit(1)
	}

	input := string(data)

	for line in strings.split_iterator(&input, ",") {
		l, u := get_ranges(line)
		fmt.printfln("%v: %v", l, u)
	}

}

get_ranges :: proc(range: string) -> (lower, upper: int) {
	res, _ := strings.replace(range, "\n", "", 1, context.temp_allocator)
	parts := strings.split(res, "-", context.temp_allocator)

	ok : bool

	lower, ok = strconv.parse_int(parts[0] )
	if !ok {
		fmt.eprintln("error converting string to number")
		os2.exit(2)
	}

	upper, ok = strconv.parse_int(parts[1])
	if !ok {
		fmt.eprintln("error converting string to number")
		os2.exit(2)
	}

	free_all(context.temp_allocator)
	return
}

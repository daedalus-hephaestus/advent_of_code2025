package cafeteria

import "base:intrinsics"
import "core:fmt"
import "core:mem"
import "core:os/os2"
import "core:strconv"
import "core:strings"

file :: "input"

MODE :: enum {
	RANGE,
	ID,
}

ranges : [dynamic][2]int
total := 0

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

	mode: MODE = .RANGE

	for line in strings.split_lines_iterator(&input) {
		if line == "" {
			mode = .ID
			continue
		}

		switch mode {
		case .RANGE:
		l, u := get_range(line)
		append(&ranges, [2]int{l, u})
		case .ID:
			id, ok := strconv.parse_int(line)

			if !ok {
				fmt.eprintln("unable to convert string to int")
				os2.exit(2)
			}

			fresh := check_id(id)
			if fresh do total += 1
		}
	}

	fmt.println(total)

	delete(ranges)
}

get_range :: proc(range: string) -> (lower, upper: int) {
	res, _ := strings.replace(range, "\n", "", 1, context.temp_allocator)
	parts := strings.split(res, "-", context.temp_allocator)

	ok : bool
	lower, ok = strconv.parse_int(parts[0])
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

check_id :: proc(id: int) -> bool {
	for r in ranges {
		if id >= r.x && id <= r.y do return true
	}
	return false
}

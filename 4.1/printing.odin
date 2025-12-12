package printing

import "base:intrinsics"
import "core:fmt"
import "core:mem"
import "core:os/os2"
import "core:strconv"
import "core:strings"

file :: "test_input"

printing: [dynamic][dynamic]int

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
	i := 0

	for line in strings.split_lines_iterator(&input) {
		append(&printing, make([dynamic]int))
		for char in line {
			switch char {
			case '.':
				append(&printing[i], 0)
			case '@':
				append(&printing[i], 1)
			}
		}
		i += 1
	}


	fmt.println(count_all())
	// fmt.println(count_adj(2, 0))


	for row in printing do delete(row)
	delete(printing)
}

count_all :: proc() -> (count: int) {
	for row, y in printing {
		for val, x in row {
			if val == 1 {
				adj := count_adj(x, y)
				if adj < 4 do count += 1
			}
		}
	}

	return count
}

count_adj :: proc(px, py: int) -> (count: int) {
	for y := -1; y < 2; y += 1 {
		for x := -1; x < 2; x += 1 {
			check := [2]int{px, py}
			check += {x, y}

			if (check.x < 0 ||
				   check.x > len(printing[0]) - 1 ||
				   check.y < 0 ||
				   check.y > len(printing) - 1 ||
				   check.x == px && check.y == py) {
				continue
			}

			if printing[check.y][check.x] == 1 do count += 1
		}
	}

	return
}

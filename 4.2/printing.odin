package printing

import "base:intrinsics"
import "core:fmt"
import "core:mem"
import "core:os/os2"
import "core:strconv"
import "core:strings"

file :: "input"

printing: [dynamic][dynamic]int
total_removed := 0

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


	able_to_remove := remove_all()
	total_removed += able_to_remove

	for able_to_remove > 0 {
		r := remove_all()
		total_removed += r
		able_to_remove = r
	}

	fmt.println(total_removed)

	for row in printing do delete(row)
	delete(printing)
}

remove_all :: proc() -> (removed: int) {
	remove_queue : [dynamic][2]int
	defer delete(remove_queue)

	for row, y in printing {
		for val, x in row {
			if val == 1 {
				adj := count_adj(x, y)
				if adj < 4 {
					append(&remove_queue, [2]int{x, y})
				}
			}
		}
	}

	removed = len(remove_queue)	
	for i in remove_queue do printing[i.y][i.x] = 0
	return
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

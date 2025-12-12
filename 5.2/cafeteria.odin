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

ranges: [dynamic][2]int
range_map: map[int]bool
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

	outer: for line in strings.split_lines_iterator(&input) {
		if line == "" {
			mode = .ID
			continue
		}

		switch mode {
		case .RANGE:
			l, u := get_range(line)

			for &r in ranges {
				if l > r.x && u < r.y do continue outer
				if l > r.x && l < r.y && u > r.y {
					l = r.y + 1
				}
				if u > r.x && u < r.y && l < r.x {
					u = r.x - 1
				}
			}
			append(&ranges, [2]int{l, u})
		case .ID:
			break
		}
	}

	for &r in ranges {
		if r.y - r.x + 1 < 0 do fmt.println("negative found")
		check_range(&r)
		check_range(&r)
		check_range(&r)
		total += r.y - r.x + 1
	}

	fmt.println(total)

	delete(ranges)
	delete(range_map)
}

get_range :: proc(range: string) -> (lower, upper: int) {
	res, _ := strings.replace(range, "\n", "", 1, context.temp_allocator)
	parts := strings.split(res, "-", context.temp_allocator)

	ok: bool
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

check_range :: proc(range: ^[2]int) {
	for r in ranges {
		if range.x > r.x && range.y < r.y {
			fmt.printfln("%v contained by %v", range, r)
			range^ = {0, 0}
			break
		}
		if range.x > r.x && range.x < r.y && range.y > r.y {
			fmt.printfln("lower of %v contained by %v", range, r)
			range.x = r.y + 1
			break
		}
		if range.y > r.x && range.y < r.y && range.x < r.x {
			fmt.printfln("upper of %v contained by %v", range, r)
			range.y = r.x - 1
			break
		}
	}
}

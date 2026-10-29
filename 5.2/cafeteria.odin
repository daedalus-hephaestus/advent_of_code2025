package cafeteria

import "base:intrinsics"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"

file :: "input"

MODE :: enum {
	RANGE,
	ID,
}
Range :: struct {
	l: int,
	u: int
}
ranges: [dynamic]Range

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

	data, err := os.read_entire_file_from_path(file, context.allocator)
	defer delete(data)

	if err != .NONE {
		fmt.eprintln(err)
		os.exit(1)
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
			range := get_range(line)


			fmt.printfln("Found range: %v", range)
			mod, add, _ := update_ranges(range, &ranges)
			if add {
				append(&ranges, mod)
			}
		case .ID:
			break
		}
	}

	changes_made := true
	for changes_made {
		changes_made = false
		for r in ranges {
			_, add, change := update_ranges(r, &ranges)
			if change == true do changes_made = true
		}
	}

	total = count_ranges(ranges[:])
	fmt.printfln("TOTAL: %v", total)

	delete(ranges)
}

get_range :: proc(str: string) -> (range: Range) {
	res, _ := strings.replace(str, "\n", "", 1, context.temp_allocator)
	parts := strings.split(res, "-", context.temp_allocator)

	lower, lower_ok := strconv.parse_int(parts[0])
	if !lower_ok {
		fmt.eprintln("error converting string to number")
		os.exit(2)
	}

	upper, upper_ok := strconv.parse_int(parts[1])
	if !upper_ok {
		fmt.eprintln("error converting string to number")
		os.exit(2)
	}

	free_all(context.temp_allocator)

	range = {
		l = lower,
		u = upper
	}
	return
}

update_ranges :: proc(range: Range, ranges: ^[dynamic]Range) -> (mod: Range, add: bool, change: bool) {
	mod = range
	add = true
	change = false

	lower_contained, upper_contained: bool
	lower_index, upper_index: int

	for r, i in ranges {
		if range.l == r.l && range.u == r.u {
			add = false
			continue
		}

		// if the lower is contained by the range
		if range.l >= r.l && range.l <= r.u {
			lower_contained = true
			lower_index = i
		}

		// if the upper is contained by the range
		if range.u >= r.l && range.u <= r.u {
			upper_contained = true
			upper_index = i
		}

		if (range.u > r.u && range.l < r.l) {
			fmt.printfln("%v larger than %v", range, r)
			add = false
			change = true
			ranges[i].l = range.l
			ranges[i].u = range.u
			return
		}
	}

	if lower_contained && upper_contained {

		if lower_index == upper_index {
			fmt.printfln("%v Completely contained: skipping", range)
			add = false
			change = false
			return
		}

		fmt.printfln("Full overlap on %v\nMerging %v and %v", range, ranges[lower_index], ranges[upper_index])
		ranges[lower_index].u = ranges[upper_index].u
		ordered_remove(ranges, upper_index)
		add = false
		change = true
		return
	}

	if lower_contained {
		fmt.printfln("Lower overlap on %v\nModifying %v", range, ranges[lower_index])
		ranges[lower_index].u = range.u
		add = false
		change = true
		return
	}

	if upper_contained {
		fmt.printfln("Upper overlap on %v\nModifying %v", range, ranges[upper_index])
		ranges[upper_index].l = range.l
		add = false
		change = true
		return
	}

	return
}

count_ranges :: proc(ranges: []Range) -> (count: int) {
	for r in ranges {
		diff := r.u - r.l + 1
		count += diff
		fmt.printfln("%v -> %v", r, diff)
	}
	return
}

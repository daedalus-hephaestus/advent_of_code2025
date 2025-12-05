package giftshop

import "core:fmt"
import "core:mem"
import "core:os/os2"
import "core:strconv"
import "core:strings"

file :: "input"
invalid_count := 0

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

		for i := l; i <= u; i += 1 {
			invalid := invalid_id(i)
			if invalid do invalid_count += i
		}
	}
	fmt.println(invalid_count)
}

get_ranges :: proc(range: string) -> (lower, upper: int) {
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

invalid_id :: proc(number: int) -> bool {
	buff: [128]byte

	str := fmt.bprint(buff[:], number)
	length := len(str)

	// get the possible factors for the length of the string to determine the different ways it can be divided
	factors := get_factors(length)
	defer delete(factors)

	// loop through the different factor patterns
	outer: for f in factors {
		// store each segment of the string
		parts : [dynamic]string
		defer delete(parts)

		// how many segments there will be
		part_count := length / f

		// loop through the segments
		for i in 0..<part_count {
			start := i * f
			end := i * f + f

			// append each segment to the parts array
			append(&parts, str[start: end])
		}

		// compare each segment against the previous
		last_part := parts[0]
		for p in parts {
			if p != last_part {
				// if the parts do not match, skip over this segment length
				continue outer
			}
		}

		// if the code has reached this point, all of the parts match, and it is an invalid id
		return true
	}

	return false
}

get_factors :: proc(number: int) -> []int {
	res : [dynamic]int
	for i in 1..<number {
		if number % i == 0 do append(&res, i)
	}
	return res[:]
}

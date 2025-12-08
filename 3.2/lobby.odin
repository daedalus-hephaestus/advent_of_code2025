package giftshop

import "core:fmt"
import "core:mem"
import "core:os/os2"
import "core:strconv"
import "core:strings"
import "base:intrinsics"

file :: "input"
joltage : int

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

	for line in strings.split_lines_iterator(&input) {
		num := calc_bank_new(line)
		joltage += num
	}

	fmt.println(joltage)
}

calc_bank_new :: proc(str: string) -> int {
	res := strings.clone(str)

	remove := len(res) - 12

	for i in 0..<remove { 
		res = remove_lowest(res)
	}

	defer delete(res)

	num, ok := strconv.parse_int(res)
	if !ok {
		fmt.eprintln("unable to convert string to int")
		os2.exit(2)
	}

	return num
}

remove_lowest :: proc(str: string) -> string {
	lowest := int(str[0] - 48)
	index := 0
	for i in 0..<len(str) {
		num := int(str[i] - 48)
		if num < 0 do os2.exit(2)
		if num < lowest {
			lowest = num
			index = i
		} else if num > lowest {
			break
		}
	}
	beg := str[:index]
	end := str[index + 1:]

	defer delete(str)
	return strings.concatenate({string(beg), string(end)})
}

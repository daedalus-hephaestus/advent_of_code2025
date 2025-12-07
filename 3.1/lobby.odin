package giftshop

import "core:fmt"
import "core:mem"
import "core:os/os2"
import "core:strconv"
import "core:strings"

file :: "test_input"
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
		num := calc_bank(line)
		fmt.println(num)
	}
}

calc_bank :: proc(str: string) -> int {
	highest1, index1 := find_highest_n(str, 0, len(str) - 1)
	highest2, _ := find_highest_n(str, index1 + 1, len(str))

	str := fmt.aprintf("%v%v", highest1, highest2)
	defer delete(str)

	res, ok := strconv.parse_int(str)
	if !

}

find_highest_n :: proc(str: string, start, end: int) -> ( highest, index: int ) {
	for i in start..<end {
		num := int(str[i] - 48)
		if num < 0 do os2.exit(2)
		if num > highest {
			highest = num
			index = i
		}
	}

	return
}

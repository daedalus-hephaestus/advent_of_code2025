package compactor

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"

file :: "input"

Operation :: enum {
	ADD,
	MULT,
}

Problem :: struct {
	nums: [dynamic]int,
}

problems: [dynamic]Problem
operations: [dynamic]Operation
final : int

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

	first := true
	for line in strings.split_lines_iterator(&input) {
		nums := parse_line(line)
		defer delete(nums)

		for n, i in nums {
			if first {
				append(&problems, {})
			}
			append(&problems[i].nums, n)
		}
		first = false
	}

	for p, i in problems {
		final += do_problem(p, operations[i])
	}

	fmt.println(final)

	for i in problems do delete(i.nums)
	delete(problems)
	delete(operations)

}

do_problem :: proc(problem: Problem, op: Operation) -> (res: int) {
	first := true
	for n in problem.nums {
		if first {
			res = n
			first = false
		} else {
			switch op {
			case .ADD:
				res += n
			case .MULT:
				res *= n
			}
		}
	}
	fmt.println(res)
	return
}

parse_line :: proc(line: string) -> (nums: [dynamic]int) {
	num_strings := strings.split(line, " ")

	for s, index in num_strings {
		if len(s) > 0 {
			i, ok := strconv.parse_int(s)

			if !ok {
				append(&operations, parse_operation(s))
			} else {
				append(&nums, i)
			}

		}
	}

	delete(num_strings)


	return
}

parse_operation :: proc(string: string) -> (op: Operation) {
	switch string {
	case "*":
		op = .MULT
	case "+":
		op = .ADD
	}
	return
}

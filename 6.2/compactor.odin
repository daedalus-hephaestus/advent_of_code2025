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

RawTable :: [dynamic]string
Table :: [dynamic][dynamic]string
Problem :: [dynamic]int


destroy_raw_table :: proc(raw: RawTable) {
	delete(raw)
}

destroy_table :: proc(table: Table) {
	for row in table {
		delete(row)
	}
	delete(table)
}


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
	raw_table: RawTable
	defer destroy_raw_table(raw_table)

	for line in strings.split_lines_iterator(&input) {
		append(&raw_table, line)
	}

	table := parse_raw_table(raw_table)
	defer destroy_table(table)

	ops := parse_operation(raw_table[len(raw_table) - 1])
	defer delete(ops)

	total := 0

	for i in 0 ..< len(table[0]) {
		prob := get_problem(table, i)
		defer delete(prob)

		res := do_problem(prob, ops[i])
		total += res
	}

	fmt.println(total)

}

parse_raw_table :: proc(raw: RawTable) -> (table: Table) {
	spacing: [dynamic]int
	defer delete(spacing)
	last_line := raw[len(raw) - 1]

	for i in 0 ..< len(raw) - 1 do append(&table, [dynamic]string{})

	for c, i in last_line do if c != ' ' do append(&spacing, i)

	for line, i in raw {
		if i == len(raw) - 1 do break

		for j in 0 ..< len(spacing) {
			end := j == len(spacing) - 1 ? len(line) : spacing[j + 1] - 1
			sub, err := strings.substring(line, spacing[j], end)
			append(&table[i], sub)
		}
	}

	return
}

get_problem :: proc(table: Table, index: int) -> (prob: Problem) {
	num_str := make_slice([][dynamic]u8, len(table[0][index]))
	defer delete(num_str)
	defer for i in num_str do delete(i)

	for row, j in table {
		length := len(row[index])

		for i in 0 ..< length {
			append(&num_str[i], row[index][i])
		}
	}

	for i in 0 ..< len(num_str) {
		trim := strings.trim_space(string(num_str[i][:]))
		num, ok := strconv.parse_int(trim)
		append(&prob, num)
	}

	return
}

parse_operation :: proc(string: string) -> (op: [dynamic]Operation) {
	for char in string {
		switch char {
		case '*':
			append(&op, .MULT)
		case '+':
			append(&op, .ADD)
		case ' ':
			continue
		}
	}

	return
}

do_problem :: proc(problem: Problem, op: Operation) -> (res: int) {
	first := true
	for n in problem {
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
	return
}

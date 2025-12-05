package safe

import "core:fmt"
import "core:math"
import "core:mem"
import "core:os/os2"
import "core:strconv"
import "core:strings"

dial: int = 50
zeros: int = 0
file :: "input"

main :: proc() {
	data, err := os2.read_entire_file_from_path(file, context.allocator)
	defer delete(data)

	if err != .NONE {
		fmt.eprintln(err)
		os2.exit(1)
	}

	input := string(data)

	for line in strings.split_lines_iterator(&input) {
		turns := parse_command(line)
		rotate_dial(turns, &dial)
	}

	fmt.println(zeros)
}

parse_command :: proc(str: string) -> int {
	direction := str[0] == 76 ? -1 : 1

	amount, ok := strconv.parse_int(str[1:])
	if !ok {
		fmt.eprintln("error converting string to number")
		os2.exit(2)
	}

	return direction * amount
}

rotate_dial :: proc(turns: int, dial: ^int) {
	direction := turns < 0 ? -1 : 1

	turns := math.abs(turns)

	for i in 0 ..< turns {
		dial^ += direction
		if dial^ == 0 do zeros += 1
		if dial^ < 0 do dial^ = 99
		if dial^ > 99 {
			dial^ = 0
			zeros += 1
		}
	}
}

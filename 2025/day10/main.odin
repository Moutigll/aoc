package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:slice"

Machine :: struct {
	lights:  []bool,    // Light states (true = on, false = off)
	buttons: [][]int,   // Each button: list of lights it toggles
	joltage: []int,     // Target joltage values for each counter
}

// ==================== PARSING HELPER FUNCTIONS ====================

// Parse light states from a string like ".#..#"
parse_lights :: proc(lights_str: string) -> []bool {
	lights := make([]bool, len(lights_str))
	for char, i in lights_str {
		lights[i] = char == '#'
	}
	return lights
}

// Parse a single button from a string like "0,2,4"
parse_button :: proc(button_str: string) -> []int {
	parts := strings.split(button_str, ",")
	defer delete(parts)

	button := make([dynamic]int)
	for part in parts {
		part := strings.trim_space(part)
		if len(part) > 0 {
			if val, ok := strconv.parse_int(part); ok {
				append(&button, val)
			}
		}
	}
	return button[:]
}

// Parse joltage values from a string like "1,0,2"
parse_joltage :: proc(joltage_str: string) -> []int {
	parts := strings.split(joltage_str, ",")
	defer delete(parts)

	joltage := make([dynamic]int)
	for part in parts {
		part := strings.trim_space(part)
		if len(part) > 0 {
			if val, ok := strconv.parse_int(part); ok {
				append(&joltage, val)
			}
		}
	}
	return joltage[:]
}

// Extract substring between two delimiters
extract_between :: proc(line: string, start_marker, end_marker: rune) -> (string, bool) {
	start_idx := strings.index_rune(line, start_marker)
	if start_idx == -1 do return "", false

	end_idx := strings.index_rune(line[start_idx+1:], end_marker)
	if end_idx == -1 do return "", false

	end_idx = start_idx + 1 + end_idx
	return line[start_idx+1:end_idx], true
}

// Parse a single line into a Machine struct
parse_machine_line :: proc(line: string) -> (Machine, bool) {
	line := strings.trim_space(line)
	if len(line) == 0 do return {}, false

	result: Machine

	// Parse lights (between [])
	if lights_str, ok := extract_between(line, '[', ']'); ok {
		result.lights = parse_lights(lights_str)
	} else {
		return {}, false
	}

	// Parse buttons (multiple between ())
	current_pos := strings.index_rune(line, ']') + 1
	buttons := make([dynamic][]int)

	for current_pos < len(line) {
		// Find next button
		if btn_str, ok := extract_between(line[current_pos:], '(', ')'); ok {
			btn_start := strings.index_rune(line[current_pos:], '(')
			current_pos += btn_start + len(btn_str) + 2 // +2 for "( )"

			if len(btn_str) > 0 {
				button := parse_button(btn_str)
				append(&buttons, button)
			} else {
				append(&buttons, []int{})
			}
		} else {
			break
		}
	}
	result.buttons = buttons[:]

	// Parse joltage (between {})
	if joltage_str, ok := extract_between(line, '{', '}'); ok {
		result.joltage = parse_joltage(joltage_str)
	}

	return result, true
}

// ==================== FILE READING ====================

// Read and parse all machines from a file
read_machines_from_file :: proc(filename: string) -> []Machine {
	data, ok := os.read_entire_file(filename)
	if !ok {
		fmt.println("Error: Unable to read file")
		return nil
	}
	defer delete(data)
	
	lines := strings.split_lines(string(data))
	defer delete(lines)
	
	machines := make([dynamic]Machine)
	for line in lines {
		line := strings.trim_space(line)
		if len(line) == 0 do continue
		
		if machine, ok := parse_machine_line(line); ok {
			append(&machines, machine)
		}
	}
	return machines[:]
}

// Free resources used by a Machine
free_machine_resources :: proc(m: Machine) {
	delete(m.lights)
	for btn in m.buttons do delete(btn)
	delete(m.buttons)
	delete(m.joltage)
}

// ==================== PART 1: LIGHT PUZZLE SOLVER ====================

// Solve the light puzzle using brute force :3
solve_light_puzzle :: proc(lights: []bool, buttons: [][]int) -> int {
	n_lights := len(lights)
	n_buttons := len(buttons)
	
	// Check if all lights are already off
	all_off := true
	for state in lights {
		if state {
			all_off = false
			break
		}
	}
	if all_off do return 0
	
	min_presses := n_buttons + 1

	current_state := make([]bool, n_lights)
	defer delete(current_state)
	
	// Try all possible button combinations (2^n_buttons possibilities)
	for mask: u64 = 0; mask < (1 << u64(n_buttons)); mask += 1 {
		presses := 0
		
		// Reset current state to all off
		for i in 0..<n_lights { current_state[i] = false }
		
		// Apply selected buttons
		for btn_idx in 0..<n_buttons {
			if (mask >> u64(btn_idx)) & 1 == 1 {
				presses += 1
				// Early exit if we already exceed current minimum
				if presses >= min_presses {
					break
				}
				// Toggle lights affected by this button
				for light in buttons[btn_idx] {
					if light < n_lights {
						current_state[light] = !current_state[light]
					}
				}
			}
		}
		
		// Skip if we already have too many presses
		if presses >= min_presses {
			continue
		}
		
		// Check if current state matches target
		correct := true
		for i in 0..<n_lights {
			if current_state[i] != lights[i] {
				correct = false
				break
			}
		}
		
		// Update minimum if this is a valid solution
		if correct && presses < min_presses {
			min_presses = presses
		}
	}
	
	return min_presses
}

// Calculate total presses for all machines (Part 1)
solve_part1 :: proc(machines: []Machine) -> int {
	total := 0
	for machine, i in machines {
		presses := solve_light_puzzle(machine.lights, machine.buttons)
		// fmt.printf("Machine %d (lights): %d presses\n", i+1, presses)
		total += presses
	}
	return total
}

// ==================== MAIN PROGRAM ====================

main :: proc() {
	// Read and parse input
	machines := read_machines_from_file("input.txt")
	defer {
		for machine in machines {
			free_machine_resources(machine)
		}
		delete(machines)
	}
	
	// Solve Part 1
	fmt.println("=== Part 1 ===")
	total_part1 := solve_part1(machines)
	fmt.println("\nTotal light presses:", total_part1)
}

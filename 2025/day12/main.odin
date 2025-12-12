package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"

// Shape struct stores a bitmask of the flattened shape and the total number of occupied cells
Shape :: struct {
	bitmask: int,
	area: int,
}

// Parse shapes from the input string and convert them into Shape structs
parse_shapes :: proc(input: string) -> []Shape {
	chunks := strings.split(input, "\n\n")
	defer delete(chunks)
	
	if len(chunks) < 2 {
		return []Shape{}
	}
	
	shape_chunks := chunks[:len(chunks)-1]
	shapes := make([dynamic]Shape, 0, len(shape_chunks))
	
	for chunk in shape_chunks {
		lines := strings.split(chunk, "\n")
		defer delete(lines)
		
		if len(lines) < 4 {
			continue
		}
		
		shape_lines := lines[1:4] // Extract the 3 lines representing the shape
		
		builder := strings.builder_make()
		defer strings.builder_destroy(&builder)
		
		// Flatten shape lines into a single string
		for line in shape_lines {
			strings.write_string(&builder, line)
		}
		
		flattened_str := strings.to_string(builder)
		
		// Convert shape to binary string representation
		temp1, _ := strings.replace_all(flattened_str, "#", "1")
		defer delete(temp1)
		
		binary_str, _ := strings.replace_all(temp1, ".", "0")
		defer delete(binary_str)
		
		bitmask := 0
		for char in binary_str {
			bitmask <<= 1
			if char == '1' {
				bitmask |= 1
			}
		}
		
		area := 0
		for char in flattened_str {
			if char == '#' {
				area += 1
			}
		}
		
		append(&shapes, Shape{bitmask, area})
	}
	
	// Copy dynamic array to fixed array to return
	result := make([]Shape, len(shapes))
	copy(result[:], shapes[:])
	delete(shapes)
	return result
}

// Extract region lines from input
get_regions :: proc(input: string) -> []string {
	chunks := strings.split(input, "\n\n")
	defer delete(chunks)
	
	if len(chunks) < 2 {
		return []string{}
	}
	
	region_chunk := chunks[len(chunks)-1]
	region_lines := strings.split(region_chunk, "\n")
	defer delete(region_lines)
	
	regions := make([dynamic]string, 0, len(region_lines))
	for line in region_lines {
		if len(line) > 0 {
			append(&regions, line)
		}
	}
	
	// Copy dynamic array to fixed array to return
	result := make([]string, len(regions))
	for region, i in regions {
		result[i] = strings.clone(region)
	}
	delete(regions)
	return result
}

// Check if a region can fit all required shapes based on area heuristic
is_region_valid :: proc(region: string, shapes: []Shape) -> bool {
	parts := strings.split(region, ": ")
	defer delete(parts)
	
	if len(parts) != 2 {
		return false
	}
	
	dim_str := parts[0]
	req_str := parts[1]
	
	dims := strings.split(dim_str, "x")
	defer delete(dims)
	
	if len(dims) != 2 {
		return false
	}
	
	width, width_ok := strconv.parse_int(dims[0])
	height, height_ok := strconv.parse_int(dims[1])
	
	if !width_ok || !height_ok {
		return false
	}
	
	// Calculate available area in the region
	available_area := width * height
	
	req_strs := strings.fields(req_str) // Split by whitespace
	defer delete(req_strs)
	required_area := 0
	
	// Iterate over required shapes and sum their areas
	for str, i in req_strs {
		if i >= len(shapes) {
			break
		}
		
		if count, ok := strconv.parse_int(str); ok {
			required_area += count * shapes[i].area
		}
	}
	
	return available_area >= required_area
}

main :: proc() {
	data, success := os.read_entire_file("input.txt")
	if !success {
		fmt.println("Error reading input.txt")
		return
	}
	defer delete(data)
	
	input := string(data)
	input = strings.trim_space(input)
	
	// Parse shapes and regions
	shapes := parse_shapes(input)
	defer delete(shapes)
	
	regions := get_regions(input)
	defer {
		for region in regions {
			delete(region)
		}
		delete(regions)
	}
	
	// Count valid regions
	valid_count := 0
	for region in regions {
		if is_region_valid(region, shapes) {
			valid_count += 1
		}
	}
	
	fmt.printf("Total regions that can be filled: %d\n", valid_count)
}

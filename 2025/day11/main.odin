package main

import "core:fmt"
import "core:strings"
import "core:os"

// Node represents a device with its name and connections to other devices
Node :: struct {
	name: string,					// Device name
	connections: [dynamic]^Node,	 // Pointers to connected devices
}

// Graph stores all nodes in a map for efficient lookup
Graph :: struct {
	nodes: map[string]^Node,		 // Map from device name to node pointer
}

// =============================================================================
// Graph Parsing
// =============================================================================

// parse_graph creates a graph from the input string
parse_graph :: proc(input: string) -> (graph: Graph, err: bool) {
	lines := strings.split_lines(input)
	defer delete(lines)
	
	// First pass: create all nodes without connections
	for line in lines {
		if len(line) == 0 do continue
		
		parts := strings.split(line, ": ")
		defer delete(parts)
		if len(parts) != 2 do continue
		
		key := parts[0]
		
		// Create node if it doesn't exist
		if key not_in graph.nodes {
			node := new(Node)
			node.name = strings.clone(key)
			node.connections = make([dynamic]^Node)
			// Use the cloned string as the map key
			graph.nodes[strings.clone(key)] = node
		}
	}
	
	// Second pass: create connections between nodes
	for line in lines {
		if len(line) == 0 do continue
		
		parts := strings.split(line, ": ")
		defer delete(parts)
		if len(parts) != 2 do continue
		
		key := parts[0]
		connections_str := parts[1]
		
		// Get the source node
		source_node := graph.nodes[key]
		if source_node == nil do continue
		
		// Parse and create connections
		connection_names := strings.split(connections_str, " ")
		defer delete(connection_names)
		
		for name in connection_names {
			if dest_node, exists := graph.nodes[name]; exists {
				append(&source_node.connections, dest_node)
			} else {
				// Create node if it wasn't defined earlier
				node := new(Node)
				node.name = strings.clone(name)
				node.connections = make([dynamic]^Node)
				// Use the cloned string as the map key
				graph.nodes[strings.clone(name)] = node
				append(&source_node.connections, node)
			}
		}
	}
	
	return graph, false
}

// =============================================================================
// Part 1: Find all paths from "you" to "out"
// =============================================================================

// find_all_paths performs DFS to find all paths from start to end
find_all_paths :: proc(graph: Graph, start_name, end_name: string) -> [dynamic][]string {
	paths := make([dynamic][]string)
	
	start_node := graph.nodes[start_name]
	end_node := graph.nodes[end_name]
	
	if start_node == nil || end_node == nil {
		return paths
	}
	
	current_path := make([dynamic]string)
	defer delete(current_path)
	
	// Inner recursive DFS function
	find_paths_dfs :: proc(
		current: ^Node, 
		end: ^Node, 
		current_path: ^[dynamic]string, 
		paths: ^[dynamic][]string,
		allocator := context.allocator,
	) {
		// Add current node to path
		append(current_path, current.name)
		
		// If we reached the end node, save the path
		if current == end {
			// Clone the current path
			path_copy := make([]string, len(current_path^))
			copy(path_copy, current_path[:])
			append(paths, path_copy)
		} else {
			// Continue DFS to all connections
			for connection in current.connections {
				// Don't revisit nodes (avoid cycles)
				found := false
				for node_name in current_path^ {
					if node_name == connection.name {
						found = true
						break
					}
				}
				
				if !found {
					find_paths_dfs(connection, end, current_path, paths)
				}
			}
		}
		
		// Backtrack
		pop(current_path)
	}
	
	find_paths_dfs(start_node, end_node, &current_path, &paths)
	
	return paths
}

// =============================================================================
// Part 2: Count paths from "svr" to "out" visiting both "dac" and "fft"
// =============================================================================

// count_paths_between counts the number of paths between two nodes using memoization
count_paths_between :: proc(graph: Graph, start_name, end_name: string) -> int {
	start_node := graph.nodes[start_name]
	end_node := graph.nodes[end_name]
	
	if start_node == nil || end_node == nil {
		return 0
	}
	
	// Use a local map for memoization
	memo := make(map[string]int)
	defer delete(memo)
	
	// Recursive DFS with memoization
	dfs_count :: proc(current: ^Node, end: ^Node, memo: ^map[string]int) -> int {
		// Check memoization cache
		if result, exists := memo[current.name]; exists {
			return result
		}
		
		// Base case: reached destination
		if current == end {
			memo[current.name] = 1
			return 1
		}
		
		total := 0
		
		// Sum paths from all connections
		for neighbor in current.connections {
			total += dfs_count(neighbor, end, memo)
		}
		
		// Store in cache and return
		memo[current.name] = total
		return total
	}
	
	return dfs_count(start_node, end_node, &memo)
}

// solve_part2 counts paths from "svr" to "out" that visit both "dac" and "fft"
solve_part2 :: proc(graph: Graph) -> int {
	// Check required nodes exist
	svr_node := graph.nodes["svr"]
	dac_node := graph.nodes["dac"]
	fft_node := graph.nodes["fft"]
	out_node := graph.nodes["out"]
	
	if svr_node == nil || dac_node == nil || fft_node == nil || out_node == nil {
		return 0
	}
	
	// Count paths for each possible order:
	// 1. svr -> fft -> dac -> out
	svr_to_fft := count_paths_between(graph, "svr", "fft")
	fft_to_dac := count_paths_between(graph, "fft", "dac")
	dac_to_out := count_paths_between(graph, "dac", "out")
	
	// 2. svr -> dac -> fft -> out
	svr_to_dac := count_paths_between(graph, "svr", "dac")
	dac_to_fft := count_paths_between(graph, "dac", "fft")
	fft_to_out := count_paths_between(graph, "fft", "out")
	
	// Total paths = sum of both orders
	total := (svr_to_fft * fft_to_dac * dac_to_out) + (svr_to_dac * dac_to_fft * fft_to_out)
	
	return total
}

// =============================================================================
// Cleaning Functions
// =============================================================================

// destroy_graph cleans up allocated memory
destroy_graph :: proc(graph: ^Graph) {
	for key, node in graph.nodes {
		delete(node.name)
		delete(node.connections)
		free(node)
		// Free the map key string
		delete(key)
	}
	delete(graph.nodes)
}

// destroy_paths cleans up path arrays
destroy_paths :: proc(paths: ^[dynamic][]string) {
	for path in paths {
		delete(path)
	}
	delete(paths^)
}

// =============================================================================
// Main Function
// =============================================================================

main :: proc() {
	// Read input
	data, read_success := os.read_entire_file("input.txt")
	if !read_success {
		fmt.println("Error reading input.txt")
		return
	}
	defer delete(data)
	
	// Parse graph
	graph, parse_error := parse_graph(string(data))
	defer destroy_graph(&graph)
	if parse_error {
		fmt.println("Parse error")
		return
	}
	
	// Part 1
	fmt.println("Part 1:")
	if paths := find_all_paths(graph, "you", "out"); len(paths) > 0 {
		defer destroy_paths(&paths)
		fmt.printf("Found %d paths\n", len(paths))
		
	} else {
		fmt.println("No paths found")
	}
	
	// Part 2
	fmt.println("\nPart 2:")
	count := solve_part2(graph)
	fmt.printf("Result: %d\n", count)
}
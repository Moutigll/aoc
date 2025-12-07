package main

import (
	"bufio"
	"fmt"
	"math/big"
	"os"
)

// parseFile reads the input file line by line and returns a slice of strings.
func parseFile(filename string) ([]string, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	sc := bufio.NewScanner(file)
	var grid []string
	for sc.Scan() {
		grid = append(grid, sc.Text())
	}
	if err := sc.Err(); err != nil {
		return nil, err
	}
	return grid, nil
}


// addBig adds val to target. Initializes target if nil.
func addBig(target **big.Int, val *big.Int) {
	if val.Sign() == 0 {
		return
	}
	if *target == nil {
		*target = new(big.Int).Set(val)
	} else {
		(*target).Add(*target, val)
	}
}

// findStart searches the grid for the 'S' starting point.
func findStart(grid []string) (int, int) {
	for y, row := range grid {
		for x, ch := range row {
			if ch == 'S' {
				return x, y
			}
		}
	}
	return -1, -1
}

func propagateBeam(
	next []*big.Int,	// next row counts
	exits *big.Int,		// total exits
	cnt *big.Int,		// current beam count
	nr, nc int,			// next row, next column
	h, w int,			// grid height, width
	) {
	if nr < 0 || nr >= h || nc < 0 || nc >= w {
		exits.Add(exits, cnt) // beam exits the grid
	} else {
		addBig(&next[nc], cnt) // beam continues
	}
}

// handleSplitter processes a splitter cell ('^').
// - Updates part1 counter if this splitter wasn't visited before.
// - Splits the beam into left and right branches for part2.
// - Updates next row's counts or exits if out of grid.
func handleSplitter(
	x, y int,					// current position
	cnt *big.Int,				// current beam count
	next []*big.Int,			// next row counts
	visited map[[2]int]bool,	// visited splitters
	part1 int,					// current part1 count
	exits *big.Int,				// total exits
	h, w int,					// grid height, width
	) int {
	key := [2]int{x, y}
	if !visited[key] {
		part1++
		visited[key] = true
	}

	nr := y + 1
	propagateBeam(next, exits, cnt, nr, x-1, h, w) // left branch
	propagateBeam(next, exits, cnt, nr, x+1, h, w) // right branch

	return part1
}



// computeParts simulates beams through the grid and returns:
// - Part 1: number of unique splitter encounters
// - Part 2: total number of timelines (big.Int)
func computeParts(grid []string) (int, *big.Int) {
	h := len(grid)
	w := len(grid[0])

	sx, sy := findStart(grid)
	if sx == -1 {
		return 0, big.NewInt(0)
	}

	// Current row counts (number of beams in each column)
	curr := make([]*big.Int, w)
	curr[sx] = big.NewInt(1) // initial beam starts here

	firstRow := sy + 1
	if firstRow >= h { // start is at bottom row !?
		return 0, big.NewInt(1)
	}

	part1 := 0									// splitter count
	exits := big.NewInt(0)						// total timelines (Part 2)
	visitedSplitters := make(map[[2]int]bool)	// track unique splitters

	// Iterate row by row
	for r := firstRow; r < h; r++ {
		next := make([]*big.Int, w) // next row counts
		for c := range curr { // iterate columns
			cnt := curr[c]
			if cnt == nil || cnt.Sign() == 0 {
				continue // no beam here
			}
			cell := grid[r][c]
			if cell == '^' {
				part1 = handleSplitter(c, r, cnt, next, visitedSplitters, part1, exits, h, w)
			} else {
				propagateBeam(next, exits, cnt, r+1, c, h, len(next))
			}
		}
		curr = next // move to next row
	}

	return part1, exits
}

func main() {
	grid, err := parseFile("input.txt")
	if err != nil {
		fmt.Println("Error opening input.txt:", err)
		return
	}

	part1, part2 := computeParts(grid)
	fmt.Println("Part 1:", part1)
	fmt.Println("Part 2:", part2.String())
}

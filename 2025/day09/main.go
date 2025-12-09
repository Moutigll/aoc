package main

import (
	"bufio"
	"fmt"
	"math"
	"os"
	"sort"
	"strconv"
	"strings"
)

// Point represents a coordinate
type Point struct{
	X, Y int
}

// Interval represents an inclusive range [a,b]
type Interval struct{
	a, b int
}

// Parsing Input
func parseFile(name string) ([]Point, error) {
	file, err := os.Open(name)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var points []Point
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}
		parts := strings.Split(line, ",")
		if len(parts) != 2 {
			return nil, fmt.Errorf("invalid line: %q", line)
		}
		x, e1 := strconv.Atoi(strings.TrimSpace(parts[0]))
		y, e2 := strconv.Atoi(strings.TrimSpace(parts[1]))
		if e1 != nil || e2 != nil {
			return nil, fmt.Errorf("invalid numbers: %q", line)
		}
		points = append(points, Point{x, y})
	}
	return points, scanner.Err()
}

// Utilities

func min(a, b int) int { if a < b { return a }; return b }
func max(a, b int) int { if a > b { return a }; return b }
func abs(a int) int { if a < 0 { return -a }; return a }


// Part 1 - Maximum rectangle ignoring interior restrictions
func part1(points []Point) int {
	best := 0
	n := len(points)
	for i := range n {
		for j := i + 1; j < n; j++ {
			// +1 to include both edges
			w := abs(points[i].X - points[j].X) + 1
			h := abs(points[i].Y - points[j].Y) + 1
			if w*h > best {
				best = w * h
			}
		}
	}
	return best
}


// Part 2 - Maximum rectangle inside polygon using red/green tiles

// Step 1: Build allowed intervals per row
// buildRowIntervals computes, for each row (Y), a list of X intervals that are allowed (red or green tiles)
func buildRowIntervals(poly []Point) (rows [][]Interval, minX, minY int) {
	n := len(poly)
	if n == 0 { return nil, 0, 0 }

	// 1a) Compute bounding box
	minX, maxX := poly[0].X, poly[0].X
	minY, maxY := poly[0].Y, poly[0].Y
	for _, p := range poly {
		if p.X < minX { minX = p.X }
		if p.X > maxX { maxX = p.X }
		if p.Y < minY { minY = p.Y }
		if p.Y > maxY { maxY = p.Y }
	}
	height := maxY - minY + 1
	rows = make([][]Interval, height)

	// 1b) Add horizontal edges directly as intervals
	for i := range poly { // Loop over edges
		a := poly[i]
		b := poly[(i+1)%n] // next vertex (wrap around)
		if a.Y == b.Y {	// horizontal edge same Y
			y := a.Y - minY
			x1 := min(a.X, b.X) - minX
			x2 := max(a.X, b.X) - minX
			rows[y] = append(rows[y], Interval{x1, x2})
		}
	}

	// 1c) Use scanline (even-odd rule) to fill interior of polygon with intervals
	for yAbs := minY; yAbs <= maxY; yAbs++ { // Loop over each absolute Y coordinate from minY to maxY
		yIdx := yAbs - minY // Local row index
		yCenter := float64(yAbs) + 0.5

		var xs []float64 // X intersections for this row

		for i := range n { // Loop over edges
			a := poly[i] // Current vertex
			b := poly[(i+1)%n] // Next vertex (wrap around at end)
			if a.X == b.X { // vertical edge
				ya := float64(min(a.Y, b.Y))
				yb := float64(max(a.Y, b.Y))
				if yCenter >= ya && yCenter < yb { // Row intersects vertical edge
					xs = append(xs, float64(a.X))
				}
			}
		}

		if len(xs) == 0 { continue } // No intersections on this row

		sort.Float64s(xs) // Sort intersections to process intervals from left to right

		for k := 0; k+1 < len(xs); k += 2 { // Process intersections in pairs (even-odd rule)
			// Convert float X back to integer intervals
			xFrom := int(math.Ceil(xs[k]-0.5)) - minX
			xTo := int(math.Floor(xs[k+1]-0.5)) - minX
			if xFrom <= xTo { // Only add valid intervals
				rows[yIdx] = append(rows[yIdx], Interval{xFrom, xTo}) // Add interval to this row
			}
		}
	}


	// 1d) Merge overlapping intervals per row
	for yi := range rows {
		if len(rows[yi]) == 0 { continue } // No intervals to merge

		// Sort intervals in this row by their start point 'a'
		sort.Slice(rows[yi], func(i, j int) bool { return rows[yi][i].a < rows[yi][j].a })

		merged := []Interval{}
		cur := rows[yi][0] // Start with the first interval

		for _, it := range rows[yi][1:] { // Process remaining intervals
			if it.a <= cur.b+1 {
				if it.b > cur.b { cur.b = it.b }
			} else {
				merged = append(merged, cur)
				cur = it
			}
		}

		merged = append(merged, cur)
		rows[yi] = merged // Update row with merged intervals
	}


	return rows, minX, minY
}

// Step 2: Helper to check if a row fully covers an X interval
func checkRowHasInterval(row []Interval, x1, x2 int) bool {
	for _, r := range row {
		if r.a <= x1 && r.b >= x2 { return true }
		if r.a > x1 { return false }
	}
	return false
}

// Step 3: Part 2 - find largest rectangle using allowed intervals
func part2(points []Point) (best int, bestA, bestB Point) {
	n := len(points)
	if n < 2 { return 0, Point{}, Point{} }

	rows, minX, minY := buildRowIntervals(points)
	height := len(rows)

	// Convert points to local coordinates within bounding box
	local := make([]Point, n)
	for i := range n {
		local[i] = Point{X: points[i].X - minX, Y: points[i].Y - minY}
	}

	best = 0
	for i := range n { // iterate over all points as the first corner
		for j := i+1; j < n; j++ { // iterate over all points as the second corner
			x1, y1 := local[i].X, local[i].Y
			x2, y2 := local[j].X, local[j].Y

			// ensure x1 < x2 and y1 < y2 to simplify area calculation
			if x1 > x2 { x1, x2 = x2, x1 }
			if y1 > y2 { y1, y2 = y2, y1 }

			area := (x2 - x1 + 1) * (y2 - y1 + 1) // compute rectangle area
			if area <= best { continue } // skip if area is not bigger than current best

			ok := y1 >= 0 && y2 < height // check rectangle is inside the row grid
			if ok {
				// check each row from y1 to y2 has an interval covering x1..x2
				for yy := y1; yy <= y2; yy++ {
					if !checkRowHasInterval(rows[yy], x1, x2) {
						ok = false // one row is not fully covered, rectangle is invalid
						break
					}
				}
			}

			if ok { // valid rectangle found
				best = area
				bestA = points[i]
				bestB = points[j]
			}
		}
	}

	return best, bestA, bestB
}


// Main
func main() {
	points, err := parseFile("input.txt")
	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	fmt.Println("Part 1:", part1(points))

	best2, a, b := part2(points)
	fmt.Println("Part 2:", best2)
	if best2 > 0 {
		fmt.Printf("Best pair: (%d,%d) <-> (%d,%d)\n", a.X, a.Y, b.X, b.Y)
	}
}

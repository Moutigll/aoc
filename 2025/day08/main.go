package main

import (
	"bufio"
	"fmt"
	"os"
	"sort"
	"strconv"
	"strings"
)

const LIMIT = 1000

type Vec3 struct {
	X, Y, Z int64
}

type Edge struct {
	A, B int	// point indices in the Vec3 list
	D2   int64	// squared distance
}

// -------------------------------------------------
// DSU (Disjoint Set Union / Union-Find)
// -------------------------------------------------
type DSU struct {
	p  []int	// parent
	sz []int	// size
}

// Create a new DSU for n elements
func newDSU(n int) *DSU {
	p := make([]int, n)
	sz := make([]int, n)

	for i := range p {
		p[i] = i
		sz[i] = 1
	}
	return &DSU{p: p, sz: sz} // First is its own parent
}

// Find with path compression
func (d *DSU) Find(x int) int {
	if d.p[x] == x {
		return x // x is root
	}
	d.p[x] = d.Find(d.p[x]) // We search for root and compress path
	return d.p[x] // Return root
}

// Union by size
func (d *DSU) Union(a, b int) bool {
	ra := d.Find(a)
	rb := d.Find(b)

	if ra == rb { // Already in the same set
		return false
	}

	// Union by size: attach smaller tree to larger
	if d.sz[ra] < d.sz[rb] {
		ra, rb = rb, ra // Swap
	}
	d.p[rb] = ra // Attach smaller tree to larger
	d.sz[ra] += d.sz[rb]
	return true
}

// -------------------------------------------------
// Parsing
// -------------------------------------------------
func parseFile(filename string) ([]Vec3, error) {
	f, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	var pts []Vec3
	sc := bufio.NewScanner(f)

	for sc.Scan() {
		line := strings.TrimSpace(sc.Text())
		if line == "" {
			continue
		}

		split := strings.Split(line, ",")
		if len(split) != 3 {
			return nil, fmt.Errorf("invalid line: %q", line)
		}

		x, e1 := strconv.ParseInt(strings.TrimSpace(split[0]), 10, 64)
		y, e2 := strconv.ParseInt(strings.TrimSpace(split[1]), 10, 64)
		z, e3 := strconv.ParseInt(strings.TrimSpace(split[2]), 10, 64)
		if e1 != nil || e2 != nil || e3 != nil {
			return nil, fmt.Errorf("invalid numbers: %q", line)
		}

		pts = append(pts, Vec3{X: x, Y: y, Z: z})
	}

	return pts, sc.Err()
}

// Compute Euclidean distance
func dist2(a, b Vec3) int64 {
	dx := a.X - b.X
	dy := a.Y - b.Y
	dz := a.Z - b.Z
	return dx*dx + dy*dy + dz*dz
}

// Build and sort all edges by distance
func buildEdges(points []Vec3) []Edge {
	n := len(points)
	var edges []Edge

	for i := range n {
		for j := i + 1; j < n; j++ { // We start from i+1 to avoid duplicates
			edges = append(edges, Edge{i, j, dist2(points[i], points[j])})
		}
	}

	sort.Slice(edges, func(i, j int) bool { // Sort by distance
		return edges[i].D2 < edges[j].D2
	})
	return edges
}

// -------------------------------------------------
// PART 1: run first "LIMIT" unions and compute product
// -------------------------------------------------
func computePart1(points []Vec3, edges []Edge) (DSU, []int) {
	n := len(points)

	dsu := *newDSU(n)
	k := min(LIMIT, len(edges))

	// Apply first LIMIT edges
	for i := range k {
		e := edges[i]
		dsu.Union(e.A, e.B)
	}

	// Compute sizes of connected components
	sizeMap := make(map[int]int)
	for i := range n {
		root := dsu.Find(i)
		sizeMap[root]++
	}

	var sizes []int
	for _, s := range sizeMap {
		sizes = append(sizes, s)
	}

	sort.Slice(sizes, func(a, b int) bool {
		return sizes[a] > sizes[b]
	})

	// Product of the 3 largest components
	prod := 1
	for i := 0; i < 3 && i < len(sizes); i++ {
		prod *= sizes[i]
	}

	fmt.Println("Part 1 product:", prod)

	return dsu, sizes
}

// -------------------------------------------------
// PART 2: continue unions until all components merge
// Return X(A) * X(B) of the last merge
// -------------------------------------------------
func computePart2(points []Vec3, edges []Edge, dsu *DSU, startEdge int) int64 {
	n := len(points)

	// Count current number of components
	components := 0
	for i := range n {
		if dsu.Find(i) == i {
			components++
		}
	}

	// Continue merging until one component remains
	for i := startEdge; i < len(edges); i++ {
		e := edges[i]

		if dsu.Union(e.A, e.B) {
			components--

			// Last merge -> return product
			if components == 1 {
				return points[e.A].X * points[e.B].X
			}
		}
	}

	return -1
}

// -------------------------------------------------
// MAIN
// -------------------------------------------------
func main() {
	points, err := parseFile("input.txt")
	if err != nil {
		fmt.Println("Input error:", err)
		return
	}

	// Compute sorted distances between every pair of points
	edges := buildEdges(points)

	dsu1, _ := computePart1(points, edges)

	result2 := computePart2(points, edges, &dsu1, LIMIT)
	fmt.Println("Part 2 result:", result2)
}

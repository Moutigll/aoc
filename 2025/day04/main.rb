def parseLine(line)
	result = []
	i = 0

	while i < line.length
		result << (line[i] == "@") # True for "@", false otherwise
		i += 1
	end

	return result
end


# Find all "weak" cells in the grid.
# A weak cell is a true cell with strictly fewer than 4 adjacent true neighbors.
# We check the 8 surrounding positions using dr, dc ∈ {-1, 0, 1}.
def findWeakCells(grid)
	weak = [] # List of [row, col] for weak cells

	grid.each_with_index do |row, r|
		row.each_with_index do |cell, c|
			# Only true cells can be weak
			next unless cell == true

			adj = 0

			# Explore the 8 surrounding neighbors
			(-1..1).each do |dr|
				(-1..1).each do |dc|
					# Skip the cell itself
					next if dr == 0 && dc == 0

					rr = r + dr
					cc = c + dc

					# Check boundaries
					if rr >= 0 && rr < grid.length && cc >= 0 && cc < row.length
						adj += 1 if grid[rr][cc] == true
					end
				end
			end

			# A cell is weak if it has fewer than 4 adjacent true neighbors
			weak << [r, c] if adj < 4
		end
	end

	return weak
end


# ------------------- PART 1 -------------------
# Simply count how many cells are weak.
def computePart1(grid)
	findWeakCells(grid).length
end


# ------------------- PART 2 -------------------
# Repeatedly remove (set to false) all weak cells.
# Continue until no more weak cells exist.
# Return the total number of removed cells.
def computePart2(grid)
	totalRemoved = 0

	loop do
		weak = findWeakCells(grid)
		break if weak.empty?

		# Remove all weak cells found in this iteration
		weak.each do |r, c|
			grid[r][c] = false
		end

		totalRemoved += weak.length
	end

	return totalRemoved
end


# ------------------- MAIN -------------------

numbers = []

# Read the input grid line by line
File.foreach("input.txt") do |line|
	numbers << parseLine(line.chomp)
end

# Part 1 must be computed before Part 2, as Part 2 modifies the grid.
puts computePart1(numbers)
puts computePart2(numbers)

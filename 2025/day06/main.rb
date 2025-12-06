def buildColumns(lines)
	width = lines.map(&:size).max # Find max width to pad lines
	grid  = lines.map { |l| l.ljust(width, " ").chars } # Pad lines and convert to char arrays
	grid.transpose # Transpose into columns, tysm Ruby.
end

def splitProblems(columns)
	columns.slice_when { |col| col.all?(" ") } # Split on all-blank columns
end


=begin
We join columns into rows to parse the problems.
Col0 = ["1","4","6","*"]
Col1 = ["2","5"," "," "]
Col2 = ["3"," "," "," "]
=> lines
	= ["123", "45", "6", "*"]
=end
def parseFlat(problem)
	rows = problem.first.size
	lines = (0...rows).map { |r| problem.map { |c| c[r] }.join.rstrip }

	operator = lines.last.strip
	numbers  = lines[0...-1].map(&:strip).reject(&:empty?).map(&:to_i)

	[numbers, operator]
end


def parseMatrix(problem)
	rows = problem.first.size

	operator = problem.map { |c| c[rows - 1] }.join.strip

	# Thanks to transposed matrix, part2 is trivial
	numbers = problem.map do |col|
		digits = col[0...rows - 1].join.strip
		digits.empty? ? nil : digits.to_i
	end.compact

	[numbers, operator]
end



def solve(numbers, op)
	return 0 if numbers.empty?
	op == "+" ? numbers.sum : numbers.inject(1) { |acc, n| acc * n }
end



raw      = File.read(ARGV[0] || "input.txt").lines.map(&:rstrip)
columns  = buildColumns(raw)
problems = splitProblems(columns)

part1 = problems.sum { |p| solve(*parseFlat(p)) }
part2 = problems.sum { |p| solve(*parseMatrix(p)) }

puts part1
puts part2

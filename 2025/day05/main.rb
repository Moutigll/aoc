def parseRanges(lines)
	lines.reject(&:empty?).map { |l| Range.new(*l.split("-").map!(&:to_i)) }
end

def parseNumbers(lines)
	lines.reject(&:empty?).map!(&:to_i)
end

def computePart1(ranges, numbers)
	numbers.count { |n| ranges.any? { |r| r.include?(n) } } # Count numbers included in any range, thanks Ruby !
end

def computePart2(ranges)
	pairs = ranges.map { |r| [r.begin, r.end] }.sort_by!(&:first) # Sort by start value

	merged = []
	curStart, curEnd = pairs.first

	pairs[1..].each do |s, e|
		if s <= curEnd + 1 # Overlapping or contiguous ranges
			curEnd = [curEnd, e].max
		else # No overlap, store current and start new
			merged << [curStart, curEnd]
			curStart, curEnd = s, e
		end
	end

	merged << [curStart, curEnd]

	merged.sum { |s, e| e - s + 1 } # Total length of merged ranges
end

raw			= File.read("input.txt").lines.map!(&:strip)
blankIndex	= raw.index("")
ranges		= parseRanges(raw[0...blankIndex])
numbers		= parseNumbers(raw[(blankIndex + 1)..])

puts computePart1(ranges, numbers)
puts computePart2(ranges)

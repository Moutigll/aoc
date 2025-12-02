use std::fs::File;
use std::io::{self, BufRead, BufReader};

fn parse_range(range: &str) -> Option<(i64, i64)> {
	let parts: Vec<&str> = range.split('-').collect();
	if parts.len() != 2 {
		return None;
	}

	let start = parts[0].trim().parse::<i64>().ok()?;
	let end = parts[1].trim().parse::<i64>().ok()?;

	Some((start, end))
}

fn parse_line(line: &str) -> Vec<(i64, i64)> {
	line.split(',')
		.map(|r| r.trim()) // remove any surrounding whitespace
		.filter(|r| !r.is_empty()) // ignore empty parts
		.filter_map(|r| parse_range(r))
		.collect()
}

// Part 1: check if a number has equal halves
fn has_equal_halves(n: i64) -> bool {
	let s = n.abs().to_string();
	let len = s.len();

	if len % 2 != 0 {
		return false;
	}

	let mid = len / 2;
	let left = &s[..mid];
	let right = &s[mid..];

	left == right
}

// Part 2: check if a number has at least one repeated digit pattern
fn has_repeated_digit(n: i64) -> bool {
	let s = n.abs().to_string();
	let len = s.len();

	if len < 2 {
		return false;
	}

	// try each possible pattern length from 1 to len/2
	for pat_len in 1..=len / 2 {
		if len % pat_len != 0 { // pattern must fit evenly
			continue;
		}

		let pat = &s[..pat_len];
		let mut ok = true;

		// compare each block of length pat_len
		let mut pos = pat_len;
		while pos < len {
			if &s[pos..pos + pat_len] != pat {
				ok = false;
				break;
			}
			pos += pat_len;
		}

		if ok {
			return true;
		}
	}

	false
}


/// Sum of IDs validated by the given condition in the range [start, end]
fn sum_range<F>(start: i64, end: i64, check: F) -> i128
where
	F: Fn(i64) -> bool,
{
	if start > end {
		return 0;
	}

	let mut total: i128 = 0;
	let mut i = start;

	while i <= end {
		if check(i) {
			total += i as i128;
		}
		i += 1;
	}

	total
}

fn check_number(ranges: &Vec<(i64, i64)>, part: bool) -> i128 {
	let mut total: i128 = 0;

	for (start, end) in ranges {
		if part {
			total += sum_range(*start, *end, has_equal_halves);
		} else {
			total += sum_range(*start, *end, has_repeated_digit);
		}
	}

	total
}

fn main() -> io::Result<()> {
	let file = File::open("input.txt")?;
	let reader = BufReader::new(file);

	let mut ranges: Vec<(i64, i64)> = Vec::new();

	for line in reader.lines() {
		if let Ok(content) = line {
			let parsed = parse_line(&content);
			ranges.extend(parsed);
		}
	}

	let total_equal_halves = check_number(&ranges, true);
	println!("Total (equal halves): {}", total_equal_halves);
	let total_repeated_digits = check_number(&ranges, false);
	println!("Total (repeated digits): {}", total_repeated_digits);

	Ok(())
}

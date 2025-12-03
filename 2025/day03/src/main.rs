use std::fs::File;
use std::io::{self, BufRead, BufReader};

fn parse_line(line: &str) -> Vec<i64> {
	line.chars() // Iterate over each character in the line
		.filter_map(|c| c.to_digit(10)) // Convert character to digit (base 10), filter out non-digits
		.map(|d| d as i64)
		.collect()
}

// Compute the largest two-digit number from the row, pretty self-explanatory
fn compute_part_1(row: &[i64]) -> Option<i64> {
	if row.len() < 2 {
		return None;
	}

	let mut best_a = -1;
	let mut idx = 0;

	// The firt digit is necessarily the first occurence of the largest digit
	// except the last one to allow space for the second digit
	for i in 0..row.len() - 1 {
		if row[i] > best_a {
			best_a = row[i];
			idx = i;
		}
	}

	let mut best_b = -1;
	// same but starting from the index of the first digit + 1 including row.len() - 1
	for i in idx + 1..row.len() {
		if row[i] > best_b {
			best_b = row[i];
		}
	}

	Some(best_a * 10 + best_b)
}

fn compute_part_2(row: &[i64]) -> Option<i64> {
	let k = 12;
	let n = row.len();
	if n < k { // Alway pray to not have tricky inputs :3
		return None;
	}

	let mut remove = n - k; // Number of digits to remove
	let mut stack: Vec<i64> = Vec::new();

	for &d in row { // Iterate over each digit with reference
		// While we can remove digits and the last digit in the stack is less than the current digit
		// we pop the stack to make space for a larger digit
		while !stack.is_empty() && remove > 0 && *stack.last().unwrap() < d {
			stack.pop();
			remove -= 1;
		}
		// Then we push the current digit onto the stack
		stack.push(d);
	}

	while remove > 0 { // If we still have to remove digits, we pop from the end
		stack.pop();
		remove -= 1;
	}

	let mut num = 0;
	for &d in &stack[..k] {
		num = num * 10 + d;
	}
	Some(num)
}

fn main() -> io::Result<()> {
	let file = File::open("input.txt")?;
	let reader = BufReader::new(file);

	let mut numbers: Vec<Vec<i64>> = Vec::new();

	for line in reader.lines() {
		if let Ok(text) = line {
			numbers.push(parse_line(&text));
		}
	}

	let mut sum1 = 0;
	let mut sum2 = 0;

	for row in &numbers {
		if let Some(v) = compute_part_1(row) {
			sum1 += v;
		}
		if let Some(v2) = compute_part_2(row) {
			sum2 += v2;
		}
	}

	println!("Part 1 sum = {}", sum1);
	println!("Part 2 sum = {}", sum2);

	Ok(())
}

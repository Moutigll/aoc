use std::fs::File;
use std::io::{self, BufRead, BufReader};

struct Rotation {
	flag: bool,
	value: i32,
}

fn parse_line(line: &str) -> Option<Rotation> {
	if line.is_empty() {
		return None;
	}

	let first_char = line.chars().next()?;
	let rest = &line[1..].trim();

	let flag = match first_char {
		'R' => false,
		'L' => true,
		_ => return None,
	};

	let value = rest.parse::<i32>().ok()?;

	Some(Rotation { flag, value })
}

fn compute_safe(list: &[Rotation]) -> i32 {
	const SIZE: i32 = 99;
	let mut dial = 50;
	let mut password = 0;

	for rotation in list {
		let delta = if rotation.flag { -rotation.value } else { rotation.value };
		dial = (dial + delta).rem_euclid(SIZE + 1);

		if dial == 0 {
			password += 1;
		}

		println!("Dial: {}, Password: {}", dial, password);
	}

	println!("Final dial position: {}", dial);
	println!("Password: {}", password);

	password
}


fn compute_safe_part2(list: &[Rotation]) -> i32 {
	const SIZE: i32 = 99;
	let mut dial = 50;
	let mut password = 0;

	for rotation in list {
		password += rotation.value / (SIZE + 1); // number of complete turns
		let rest = rotation.value % (SIZE + 1);	 // remaining steps after full turns

		if rest > 0 {
			let mut pos = dial;
			for _ in 0..rest {
				pos = if rotation.flag {
					(pos - 1 + SIZE + 1) % (SIZE + 1)
				} else {
					(pos + 1) % (SIZE + 1)
				};
				if pos == 0 {
					password += 1;
				}
			}
			dial = pos;
		}
	}

	println!("Final dial position: {}, Password: {}", dial, password);
	password
}




fn main() -> io::Result<()> {
	let file = File::open("input.txt")?;
	let reader = BufReader::new(file);

	let list: Vec<Rotation> = reader
		.lines()
		.filter_map(|line| line.ok().and_then(|l| parse_line(&l)))
		.collect();

	compute_safe(&list);

	compute_safe_part2(&list);

	Ok(())
}

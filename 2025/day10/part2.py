#!/usr/bin/env python3
import re
from z3 import Int, Sum, Solver, sat, Optimize

def parseInput(filename):
	"""Simple input parser"""
	machines = []
	with open(filename) as f:
		for line in f:
			line = line.strip()
			if not line:
				continue
			
			# Find everything between parentheses
			buttons = []
			for match in re.findall(r'\(([^)]*)\)', line):
				if match.strip():
					buttons.append([int(x) for x in match.split(",")])
				else:
					buttons.append([])
			
			# Find joltage between braces
			if match := re.search(r'\{([^}]*)\}', line):
				joltage = [int(x) for x in match.group(1).split(",")]
				machines.append((buttons, joltage))
	
	return machines

def solveMachines(targets, buttons):
	"""Solve with Z3"""
	n = len(buttons)
	
	# Trivial case
	if all(t == 0 for t in targets):
		return 0
	
	# Create variables
	x = [Int(f"b{i}") for i in range(n)]
	
	# Create solver
	solver = Optimize()
	
	# Basic constraints: non-negative integers
	for var in x:
		solver.add(var >= 0)
	
	# Target constraints
	for i, target in enumerate(targets):
		total = Sum([x[j] for j in range(n) if i in buttons[j]])
		solver.add(total == target)
	
	# Minimize sum
	solver.minimize(Sum(x))
	
	# Solve
	if solver.check() == sat:
		model = solver.model()
		return sum(model[var].as_long() for var in x)
	
	return None

def main():
	"""Main function"""
	machines = parseInput("input.txt")
	total = 0
	
	for i, (buttons, joltage) in enumerate(machines, 1):
		presses = solveMachines(joltage, buttons)
		if presses is not None:
			print(f"Machine {i}: {presses} presses")
			total += presses
	
	print(f"\nTOTAL: {total}")

if __name__ == "__main__":
	main()
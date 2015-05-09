#!/usr/bin/python
import itertools
import functools
import subprocess

possibilities = {
	"shaft": {
		"5mm": {"gear1_shaft_diameter": 5+0.4},
		"4mm": {"gear1_shaft_diameter": 4+0.4}
	},
	"distance": {
		"41": {"distance_between_axles": 41.7055},
		"39": {"distance_between_axles": 39.4555}
	},
	"ratio": {
		"9to47": {"gear1_teeth": 9, "gear2_teeth": 47},
		"11to45": {"gear1_teeth": 11, "gear2_teeth": 45}
	},
	"decoration": {
		"solid": {"gear2_decoration_solid": "true"},
		"spokes": {"gear2_decoration_spokes": 5, "gear2_decoration_extra_margin": 1},
		"arcs": {"gear2_decoration_arcs": 5, "gear2_decoration_extra_margin": 1},
		"spiral1": {"gear2_decoration_spiral1": 5, "gear2_decoration_extra_margin": 1},
		"spiral2": {"gear2_decoration_spiral2": 5, "gear2_decoration_extra_margin": 1},
		"arrows": {"gear2_decoration_arrows": 5, "gear2_decoration_extra_margin": 1},
		"drops": {"gear2_decoration_drops": 5},
		"holes": {"gear2_decoration_holes": 5},
		"flower": {"gear2_decoration_flower": 7},
		"twosegments": {"gear2_decoration_segments": 2, "gear2_decoration_extra_margin": 1},
		"threesegments": {"gear2_decoration_segments": 3, "gear2_decoration_extra_margin": 1},
		"foursegments": {"gear2_decoration_segments": 4, "gear2_decoration_extra_margin": 1},
	},
	"hobdistance": {
		"9p5": {"gear2_shaft_height": 9.5},
		"6": {"gear2_shaft_height": 6},
	}
}

renders = [{"name":".stl", "constants": {"debug":0, "printing": 1}}]

# Merge an option name, current render options, and an option value
def merger(option_name, render, n):
	option_value, contants = n
	mergedconstants = {}
	mergedconstants.update(render["constants"])
	mergedconstants.update(contants)
	return {"name": "_" + option_name + "_" + option_value + render["name"], "constants": mergedconstants}

# Create all possible permutations of possibilities as render.
for option_name, option_values in possibilities.items():
	renders = itertools.starmap(functools.partial(merger, option_name), itertools.product(renders, option_values.items()))

#Go
for render in renders:
	cmdline = ["openscad"]
	cmdline += ["-o", "renders/herringbonegears" + render["name"]]
	for key, value in render["constants"].items():
		cmdline += ["-D",key+"="+str(value)]
	cmdline += ["WadeHerringboneGears.scad"]
	print("Rendering herringbonegears" + render["name"] + "...")
	subprocess.call(cmdline)
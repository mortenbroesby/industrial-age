PrefabFiles = {
    "energy_cell",
    "generator",
    "heated_lamp",
}

Assets = {
	Asset("ATLAS", "images/inventoryimages/energy_cell/energy_cell.xml"),
	Asset("ATLAS", "images/inventoryimages/generator/generator.xml"),
	Asset("ATLAS", "images/inventoryimages/heated_lamp/heated_lamp.xml"),
	Asset("IMAGE", "energy_cell.tex" ),
	Asset("ATLAS", "energy_cell.xml" ),
}

STRINGS = GLOBAL.STRINGS
RECIPETABS = GLOBAL.RECIPETABS
Recipe = GLOBAL.Recipe
Ingredient = GLOBAL.Ingredient
TECH = GLOBAL.TECH

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

RECIPETABS['Industrial']  = {str = "Industrial", sort=999, icon = "energy_cell.tex", icon_atlas = "energy_cell.xml"}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

STRINGS.NAMES.ENERGY_CELL = "Energy Cell"
STRINGS.RECIPE_DESC.ENERGY_CELL = "Stores electricity."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ENERGY_CELL = "Interesting. It stores electricity."
local energy_cell = Recipe("energy_cell", { Ingredient("goldnugget", 1) }, RECIPETABS.Industrial, TECH.NONE, "energy_cell_placer")
energy_cell.atlas = "images/inventoryimages/energy_cell/energy_cell.xml"
--local energy_cell = GLOBAL.Recipe("energy_cell",{ Ingredient("goldnugget", 1), Ingredient("gears", 1), Ingredient("lightbulb", 1) },

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

STRINGS.NAMES.GENERATOR = "Generator"
STRINGS.RECIPE_DESC.GENERATOR = "Generates electricity."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.GENERATOR = "Let's fill this thing with fuel!"
local generator = Recipe("generator", { Ingredient("goldnugget", 1) }, RECIPETABS.Industrial, TECH.NONE, "generator_placer")
generator.atlas = "images/inventoryimages/generator/generator.xml"

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

STRINGS.NAMES.HEATED_LAMP = "Heat Lamp"
STRINGS.RECIPE_DESC.HEATED_LAMP = "Creates heated light."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HEATED_LAMP = "Edison would be proud."
local heated_lamp = Recipe("heated_lamp", { Ingredient("goldnugget", 1) }, RECIPETABS.Industrial, TECH.NONE, "heated_lamp_placer")
heated_lamp.atlas = "images/inventoryimages/heated_lamp/heated_lamp.xml"

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

TUNING.CELL_ENERGY_MAX = 21 -- 21
TUNING.CELL_DEPLETION_MULTIPLIER = 33 -- 33
TUNING.GENERATOR_EFFICIENCY_MULTIPLIER = 8 -- 5
TUNING.GENERATOR_EFFICIENCY = 0 -- 0
TUNING.GENERATOR_FUEL_MAX = 360 -- 360
TUNING.GENERATOR_FUEL_RATE = 1 -- 4
TUNING.GENERATOR_RANGE = 20
TUNING.HEATED_LAMP_RANGE = 25

--!strict
-- Shared Configuration for Brainrot Bazaar

local Config = {}

export type RarityInfo = {
	Name: string,
	Color: Color3,
	DropWeight: number,
}

export type MutationInfo = {
	Name: string,
	Multiplier: number,
	Weight: number,
	Color: Color3?,
	Material: Enum.Material?,
}

export type CharacterDef = {
	Id: string,
	Name: string,
	Rarity: string,
	BaseIncome: number,
	Price: number,
	Description: string,
	WalkSpeed: number,
	ModelStyle: string,
	PrimaryColor: Color3,
	SecondaryColor: Color3,
}

-- 6 Distinct Rarities
Config.Rarities = {
	Common = {
		Name = "Common",
		Color = Color3.fromRGB(205, 205, 210),
		DropWeight = 38,
	},
	Rare = {
		Name = "Rare",
		Color = Color3.fromRGB(50, 160, 255),
		DropWeight = 28,
	},
	Epic = {
		Name = "Epic",
		Color = Color3.fromRGB(185, 65, 245),
		DropWeight = 18,
	},
	Legendary = {
		Name = "Legendary",
		Color = Color3.fromRGB(255, 175, 20),
		DropWeight = 10,
	},
	Mythic = {
		Name = "Mythic",
		Color = Color3.fromRGB(245, 45, 75),
		DropWeight = 5,
	},
	BrainrotGod = {
		Name = "Brainrot God",
		Color = Color3.fromRGB(0, 255, 230),
		DropWeight = 1,
	},
}

-- Mutations on Spawn
Config.Mutations = {
	Normal = {
		Name = "Normal",
		Multiplier = 1,
		Weight = 74,
		Color = nil,
		Material = Enum.Material.SmoothPlastic,
	},
	Golden = {
		Name = "Golden",
		Multiplier = 2,
		Weight = 16,
		Color = Color3.fromRGB(255, 215, 0),
		Material = Enum.Material.Metal,
	},
	Diamond = {
		Name = "Diamond",
		Multiplier = 5,
		Weight = 8,
		Color = Color3.fromRGB(0, 240, 255),
		Material = Enum.Material.Ice,
	},
	Rainbow = {
		Name = "Rainbow",
		Multiplier = 10,
		Weight = 2,
		Color = Color3.fromRGB(255, 90, 220),
		Material = Enum.Material.Neon,
	},
}

-- 8 Original Absurd Brainrot Characters across 6 Rarities
Config.Characters = {
	{
		Id = "sir_barksalot",
		Name = "Sir Barksalot",
		Rarity = "Common",
		BaseIncome = 5,
		Price = 50,
		Description = "A distinguished canine gentleman wearing a miniature black silk top hat.",
		WalkSpeed = 9,
		ModelStyle = "Canine",
		PrimaryColor = Color3.fromRGB(140, 85, 45),
		SecondaryColor = Color3.fromRGB(20, 20, 20),
	},
	{
		Id = "captain_croissant",
		Name = "Captain Croissant",
		Rarity = "Rare",
		BaseIncome = 12,
		Price = 160,
		Description = "Flaky buttery hero armed with a tiny golden butter sword.",
		WalkSpeed = 9,
		ModelStyle = "Croissant",
		PrimaryColor = Color3.fromRGB(230, 165, 70),
		SecondaryColor = Color3.fromRGB(255, 215, 110),
	},
	{
		Id = "professor_pigeon",
		Name = "Professor Pigeon",
		Rarity = "Rare",
		BaseIncome = 25,
		Price = 380,
		Description = "Scholarly feathered professor with wire spectacles and a tiny briefcase.",
		WalkSpeed = 10,
		ModelStyle = "Bird",
		PrimaryColor = Color3.fromRGB(130, 140, 150),
		SecondaryColor = Color3.fromRGB(230, 100, 30),
	},
	{
		Id = "dj_pickle",
		Name = "DJ Pickle",
		Rarity = "Epic",
		BaseIncome = 55,
		Price = 950,
		Description = "The brine beatmaster with oversized sunglasses and neon headphones.",
		WalkSpeed = 10,
		ModelStyle = "Pickle",
		PrimaryColor = Color3.fromRGB(60, 175, 50),
		SecondaryColor = Color3.fromRGB(0, 240, 255),
	},
	{
		Id = "baron_von_banana",
		Name = "Baron von Banana",
		Rarity = "Epic",
		BaseIncome = 110,
		Price = 2400,
		Description = "Aristocratic yellow peel sporting a golden monocle and crimson bowtie.",
		WalkSpeed = 11,
		ModelStyle = "Banana",
		PrimaryColor = Color3.fromRGB(255, 225, 40),
		SecondaryColor = Color3.fromRGB(220, 30, 40),
	},
	{
		Id = "grandmas_flying_toaster",
		Name = "Grandma's Flying Toaster",
		Rarity = "Legendary",
		BaseIncome = 260,
		Price = 6800,
		Description = "Vintage chrome toaster hovering via rooftop rotor blade and launching toast.",
		WalkSpeed = 12,
		ModelStyle = "Toaster",
		PrimaryColor = Color3.fromRGB(210, 215, 225),
		SecondaryColor = Color3.fromRGB(180, 120, 60),
	},
	{
		Id = "infinite_sandwich",
		Name = "The Infinite Sandwich",
		Rarity = "Mythic",
		BaseIncome = 750,
		Price = 25000,
		Description = "A four-dimensional club sandwich bending the fabric of cosmic lunch.",
		WalkSpeed = 13,
		ModelStyle = "Sandwich",
		PrimaryColor = Color3.fromRGB(240, 200, 130),
		SecondaryColor = Color3.fromRGB(50, 210, 80),
	},
	{
		Id = "emperor_lost_socks",
		Name = "Emperor of the Lost Socks",
		Rarity = "BrainrotGod",
		BaseIncome = 2500,
		Price = 100000,
		Description = "Supreme ruler of all missing socks departed into dryer dimensions.",
		WalkSpeed = 14,
		ModelStyle = "Monarch",
		PrimaryColor = Color3.fromRGB(160, 50, 240),
		SecondaryColor = Color3.fromRGB(255, 215, 0),
	},
}

-- Economy & Base Settings
Config.Economy = {
	StarterCoins = 150,
	SlotCount = 8,
	BaseCount = 4,
	BaseLockCost = 100,
	BaseLockDuration = 60, -- 60 seconds lock duration
	BaseLockCooldown = 30, -- 30 seconds cooldown
	RebirthBaseCost = 25000,
	RebirthCostScale = 1.75,
	RebirthIncomeMultiplier = 0.25, -- +25% permanent income per rebirth
	StealHoldDuration = 1.5, -- seconds near slot to steal
	StealMaxDistance = 10, -- studs
}

-- Hazard Wave: Meme Storm
Config.MemeStorm = {
	Interval = 180, -- Storm every 3 minutes
	WarningDuration = 15, -- 15s warning before storm hits
	StormDuration = 25, -- Storm lasts 25s
	PlazaDangerRadius = 75, -- Studs from center (outside bases)
	SlowWalkSpeed = 8, -- Slowdown penalty in danger zone
	CoinDrainPercent = 0.03, -- 3% coins drained per pulse
	CoinDrainInterval = 2.5, -- pulse every 2.5s
}

-- Conveyor & Spawning
Config.Conveyor = {
	StartX = -72,
	EndX = 72,
	Y = 2.8,
	Z = 0,
	SpawnInterval = 4.0,
	MaxActive = 5,
}

return Config

local _G = _G

_G.HCTextureInfo = {}

HCTextureInfo = _G.HCTextureInfo

-- [ Add dictionaries below to add texture metadata ] --
-- @param Str             Path to texture
-- @param OffsetX_0       How many pts to offset left side of texture
-- @param OffsetX_1       How many pts to offset right side of texture
-- @param OffsetY_0       How many pts to offset top side of texture
-- @param OffsetY_1       How many pts to offset bottom side of texture
-- @param LevelOffsetX    How many pts to offset the level text horizontally
-- @param LevelOffsetY    How many pts to offset the level text vertically
-- @param TexCoords       Coordinates of texture
-- @param AnimationInfo   Metadata for spritemaps

HCTextureInfo.TestFrame = {}
HCTextureInfo.TestFrame.test_sprite = {
	Str = "Interface\\AddOns\\HardcoreUnlocked\\Media\\test_sprite.blp",
	OffsetX_0 = 16,
	OffsetX_1 = 50,
	OffsetY_0 = 30,
	OffsetY_1 = -4,
	LevelOffsetX = -31,
	LevelOffsetY = -11,
	RestIconOffsetX = 1.5,
	RestIconOffsetY = 3,
	TexCoords = { 0, 1, 0, 1 },
	AnimationInfo = {
		TextureWidth = 1024,
		TextureHeight = 1024,
		SpriteWidth = 1024 / 3.0,
		SpriteHeight = 1024 / 3.0,
		NumFrames = 9,
		Throttle = 0.5,
	},
}

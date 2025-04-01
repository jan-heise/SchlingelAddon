local _G = _G

_G.HCTextureUtils = {}

HCTextureUtils = _G.HCTextureUtils

local animation_frames = {} -- List of frames to animate

-- Update general texture.
-- @param texture A texture object.
-- @param points Points used to position texture.
-- @param texture_info Additional loading, animation, and positioning metadata for specific texture.
function HCTextureUtils.UpdateTexture(texture, points, texture_info)
	texture:SetTexture(texture_info.Str)
	texture:ClearAllPoints()
	for k, v in pairs(points) do
		if k == 1 then
			texture:SetPoint(
				v.Anchor,
				v.RelativeFrame,
				v.RelativeAnchor,
				(v.OffsetX + texture_info.OffsetX_0),
				(v.OffsetY + texture_info.OffsetY_0)
			)
		else
			texture:SetPoint(
				v.Anchor,
				v.RelativeFrame,
				v.RelativeAnchor,
				(v.OffsetX + texture_info.OffsetX_1),
				(v.OffsetY + texture_info.OffsetY_1)
			)
		end
	end
	texture:SetTexCoord(
		texture_info.TexCoords[1],
		texture_info.TexCoords[2],
		texture_info.TexCoords[3],
		texture_info.TexCoords[4]
	)

	if PlayerFrame:IsClampedToScreen() == false or force then
		PlayerFrame:SetClampedToScreen(true)
	end
end

-- Only update texture points and texcoords.
-- @param texture A texture object.
-- @param points Points used to position texture.
-- @param texture_info Additional loading, animation, and positioning metadata for specific texture.
function HCTextureUtils.UpdateTexturePoints(texture, points, texture_info)
	texture:ClearAllPoints()
	for k, v in pairs(points) do
		if k == 1 then
			texture:SetPoint(
				v.Anchor,
				v.RelativeFrame,
				v.RelativeAnchor,
				(v.OffsetX + texture_info.OffsetX_0),
				(v.OffsetY + texture_info.OffsetY_0)
			)
		else
			texture:SetPoint(
				v.Anchor,
				v.RelativeFrame,
				v.RelativeAnchor,
				(v.OffsetX + texture_info.OffsetX_1),
				(v.OffsetY + texture_info.OffsetY_1)
			)
		end
	end
	texture:SetTexCoord(
		texture_info.TexCoords[1],
		texture_info.TexCoords[2],
		texture_info.TexCoords[3],
		texture_info.TexCoords[4]
	)
end

-- Update general texture' accent.
-- @param texture A texture object.
-- @param points Points used to position texture.
-- @param texture_info Additional loading, animation, and positioning metadata for specific texture.
-- @param color Color to give the texture.
function HCTextureUtils.UpdateAccentTexture(texture, points, texture_info, color)
	texture:SetTexture(texture_info.AccentStr)
	texture:ClearAllPoints()
	for k, v in pairs(points) do
		if k == 1 then
			texture:SetPoint(
				v.Anchor,
				v.RelativeFrame,
				v.RelativeAnchor,
				(v.OffsetX + texture_info.OffsetX_0),
				(v.OffsetY + texture_info.OffsetY_0)
			)
		else
			texture:SetPoint(
				v.Anchor,
				v.RelativeFrame,
				v.RelativeAnchor,
				(v.OffsetX + texture_info.OffsetX_1),
				(v.OffsetY + texture_info.OffsetY_1)
			)
		end
	end
	texture:SetTexCoord(
		texture_info.TexCoords[1],
		texture_info.TexCoords[2],
		texture_info.TexCoords[3],
		texture_info.TexCoords[4]
	)

	if PlayerFrame:IsClampedToScreen() == false or force then
		PlayerFrame:SetClampedToScreen(true)
	end

	texture:SetVertexColor(color[1], color[2], color[3], color[4])
end

-- Update location of the level text PlayerLevelText, PlayerFrameSettings.Tables.Points.PlayerLevelText
-- @param display_text Level texture.
-- @param text Texture position.
-- @param texture_info Additional loading, animation, and positioning metadata for specific texture.
function HCTextureUtils.UpdateLevelText(display_text, text, texture_info)
	if #text >= 1 then
		display_text:ClearAllPoints()
		for k, v in pairs(text) do
			display_text:SetPoint(
				v.Anchor,
				v.RelativeFrame,
				v.RelativeAnchor,
				(v.OffsetX + texture_info.LevelOffsetX),
				(v.OffsetY + texture_info.LevelOffsetY)
			)
		end
	end
end

-- Update location of the rest icon
-- @param points Texture position information.
-- @param texture_info Additional loading, animation, and positioning metadata for specific texture.
function HCTextureUtils.UpdatePlayerFrameRestIcon(points, texture_info)
	if PlayerFrameSettings.Vars.PlayerLoaded then
		for k, v in pairs(points) do
			if k == 1 then
				PlayerRestIcon:SetPoint(
					v.Anchor,
					v.RelativeFrame,
					v.RelativeAnchor,
					(v.OffsetX + texture_info.RestIconOffsetX),
					v.OffsetY + texture_info.RestIconOffsetY
				)
			end
		end
	end
end

-- [ Animation functions ] --
--
-- Animate the texture by moving TexCoords.  Texture should be a sprite map.
-- @param texture       Texture to animate. Texture should be a spritemap.
-- @param textureWidth  Width of the texture.  Used for helping to detect texcoords.
-- @param textureHeight Height of the texture.  Used for helping to detect texcoords.
-- @param frameWidth    Width of the sprite.  Used for helping to detect texcoords.
-- @param frameHeight   Height of the sprite.  Used for helping to detect texcoords.
-- @param elapsed       Time since last update.
-- @param throttle      Duration between frames (1/fps)
function HCTextureUtils.AnimateTexCoords(
	texture,
	textureWidth,
	textureHeight,
	frameWidth,
	frameHeight,
	numFrames,
	elapsed,
	throttle
)
	if not texture.frame then
		-- initialize everything
		texture.frame = 1
		texture.throttle = throttle
		texture.numColumns = floor(textureWidth / frameWidth)
		texture.numRows = floor(textureHeight / frameHeight)
		texture.columnWidth = frameWidth / textureWidth
		texture.rowHeight = frameHeight / textureHeight
	end
	local frame = texture.frame
	if not texture.throttle or texture.throttle > throttle then
		local framesToAdvance = floor(texture.throttle / throttle)
		while frame + framesToAdvance > numFrames do
			frame = frame - numFrames
		end
		frame = frame + framesToAdvance
		texture.throttle = 0
		local left = mod(frame - 1, texture.numColumns) * texture.columnWidth
		local right = left + texture.columnWidth
		local bottom = ceil(frame / texture.numColumns) * texture.rowHeight
		local top = bottom - texture.rowHeight
		texture:SetTexCoord(left, right, top, bottom)

		texture.frame = frame
	else
		texture.throttle = texture.throttle + elapsed
	end
end

-- Animate active textures which require animation.
-- @param elapsed       Time since last update.
function HCTextureUtils.Animate_OnUpdate(elapsed)
	for _, v in pairs(animation_frames) do
		HCTextureUtils.AnimateTexCoords(
			v.Texture,
			v.TextureWidth,
			v.TextureHeight,
			v.SpriteWidth,
			v.SpriteHeight,
			v.NumFrames,
			elapsed,
			v.Throttle
		)
	end
end

-- Add texture to active animation.
-- @param ID              Identification of the animation
-- @param InputTexture    Texture to animate
-- @param AnimationInfo   Animation meta data.
function HCTextureUtils:AddToAnimationFrames(ID, InputTexture, AnimationInfo)
	if AnimationInfo ~= nil then
		animation_frames[ID] = {
			Texture = InputTexture,
			TextureWidth = AnimationInfo.TextureWidth,
			TextureHeight = AnimationInfo.TextureHeight,
			SpriteWidth = AnimationInfo.SpriteWidth,
			SpriteHeight = AnimationInfo.SpriteHeight,
			NumFrames = AnimationInfo.NumFrames,
			Throttle = AnimationInfo.Throttle,
		}
	else
		animation_frames[ID] = nil
	end
end

-- Fill out Blizzard texture points from existing frames
-- @param frame_data      Reference to FrameData, which holds frame points
-- @param force           Fill out point data even if they already have been.
function HCTextureUtils.FillTexturePointsTable(frame_data, force)
	if force or frame_data.points == nil then
		if UnitExists("player") then
			frame_data.points = {}

			local points = frame_data.texture:GetNumPoints()
			local i = 1
			while i <= points do
				local anchor, relativeFrame, relativeAnchor, x, y = frame_data.texture:GetPoint(i)
				tinsert(frame_data.points, {
					["Anchor"] = anchor,
					["RelativeFrame"] = relativeFrame,
					["RelativeAnchor"] = relativeAnchor,
					["OffsetX"] = x,
					["OffsetY"] = y,
				})
				i = i + 1
			end
		end
	end
end

-- Fill out Blizzard level texture points from existing frames
-- @param frame_data      Reference to FrameData, which holds frame points
-- @param force           Fill out point data even if they already have been.
function HCTextureUtils.FillLevelTextPointsTable(frame_data, force)
	if force or frame_data.points == nil then
		frame_data.points = {}
		TargetFrame.levelText:SetWordWrap(false) -- Todo; remove? move to loaded
		local points = frame_data.texture:GetNumPoints()
		local i = 1
		while i <= points do
			local anchor, relativeFrame, relativeAnchor, x, y = frame_data.texture:GetPoint(i)
			tinsert(frame_data.points, {
				["Anchor"] = anchor,
				["RelativeFrame"] = relativeFrame,
				["RelativeAnchor"] = relativeAnchor,
				["OffsetX"] = x,
				["OffsetY"] = y,
			})
			i = i + 1
		end
	end
end

-- Fill out Blizzard rest icon texture points from existing frames
-- @param frame_data      Reference to FrameData, which holds frame points
function HCTextureUtils.FillRestIconPointsTable(frame_data)
	if UnitExists("player") then
		frame_data.points = {}
		local points = PlayerRestIcon:GetNumPoints()
		local i = 1
		while i <= points do
			local anchor, relativeFrame, relativeAnchor, x, y = PlayerRestIcon:GetPoint(i)
			tinsert(frame_data.points, {
				["Anchor"] = anchor,
				["RelativeFrame"] = relativeFrame,
				["RelativeAnchor"] = relativeAnchor,
				["OffsetX"] = x,
				["OffsetY"] = y,
			})
			i = i + 1
		end
	end
end

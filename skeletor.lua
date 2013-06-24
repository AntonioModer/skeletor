--[[
Title:     skeletor
Use:       2D animation module for the LÖVE 2D game engine
Version:   1.0
Author:    Pierre-Emmanuel Lévesque
Email:     pierre.e.levesque@gmail.com
Date:      August 11th, 2012
Copyright: Copyright 2012, Pierre-Emmanuel Lévesque
License:   MIT license - @see README.md
--]]

----------------------------------------------------
-- Utilities
----------------------------------------------------

--[[
	Copies a single dimension table

	@param   table    table
	@return  table    copied table
--]]
local function copyTable(t)
	local copy = {}
	for k,v in pairs(t) do copy[k] = v end
	return copy
end

--[[
	Copies a multi dimension table

	@param   table    table
	@return  table    copied table
--]]
local function copyDeepTable(t)
	local copy = {}
	for k,v in pairs(t) do
		if type(v) == "table" then
			copy[k] = copyDeepTable(v)
		else
			copy[k] = v
		end
	end
	return copy
end

--[[
	Merges two single dimension tables

	Note: The values in t1 are overwritten by those in t2.

	@param   table    table 1
	@param   table    table 2
	@return  table    merged tables
	@uses    copyTable()
--]]
local function mergeTables(t1, t2)
	local merged = copyTable(t1)
	for k,v in pairs(t2) do merged[k] = v end
	return merged
end

--[[
	Splits a path

	Note: The character "/" cannot begin or terminate a path.

	Example path: "this/is/a/path"

	@param   string   path
	@return  table    split path
--]]
local function splitPath(path)
	local parts = {}
	local needle = 1
	for pos in function() return string.find(path, '/', needle, true) end do
		table.insert(parts, string.sub(path, needle, pos - 1))
		needle = pos + 1
	end
	table.insert(parts, string.sub(path, needle))
	return parts
end

--[[
	Gets a value, or the default value

	@param   mixed    value
	@param   bool     default value
	@return  mixed    picked value
--]]
local function getValOrDef(v, default)
	if v == nil then
		return default
	else
		return v
	end
end

--[[
	Translates coordinates from polar to cartesian

	@param   number   radius
	@param   number   angle in radians
	@return  numbers  (x, y)
--]]
local function polarToCartesian(radius, angle)
	return radius * math.cos(angle), radius * math.sin(angle)
end

--[[
	Gets the distance between two coordinates (Pythagore)

	@param   number   x1
	@param   number   y1
	@param   number   x2
	@param   number   y2
	@return  number   distance
--]]
local function getDistanceOfCoords(x1, y1, x2, y2)
	return math.sqrt(math.pow((x2 - x1), 2) + math.pow((y2 - y1), 2))
end

--[[
	Rotates a vector

	@param   number   x
	@param   number   y
	@param   number   angle in radians
	@return  numbers  (x, y) rotated
--]]
local function rotate(x, y, angle)
	local a = math.atan2(y, x) + angle
	local d = math.sqrt(math.pow(x, 2) + math.pow(y, 2))
	return d * math.cos(a), d * math.sin(a)
end

--[[
	Scales a vector

	@param   number   x
	@param   number   y
	@param   number   scale factor of x
	@param   number   scale factor of y
	@return  numbers  (x, y) scaled
--]]
local function scale(x, y, sx, sy)
	return x * sx, y * sy
end

--[[
	Translates a vector

	@param   number   x
	@param   number   y
	@param   number   offset factor of x
	@param   number   offset factor of y
	@return  numbers  (x, y) translated
--]]
local function translate(x, y, ox, oy)
	return x + ox, y + oy
end

--[[
	Applies rotation, translation, and scaling to a set of vertices

	@param   table    vertices
	@param   number   angle in radians
	@param   number   offset factor of x
	@param   number   offset factor of y
	@param   number   scale factor of x
	@param   number   scale factor or y
	@return  void
	@uses    scale(), rotate(), translate()
--]]
local function transform(v, angle, ox, oy, sx, sy)
	for i = 1, #v, 2 do
		if sx ~= 1 or sy ~= 1 then v[i], v[i + 1] = scale(v[i], v[i + 1], sx, sy) end
		if angle ~= 0 then v[i], v[i + 1] = rotate(v[i], v[i+1], angle) end
		if ox ~= 0 or oy ~= 0 then v[i], v[i + 1] = translate(v[i], v[i + 1], ox, oy) end
	end
end

--[[
	Constant: 1 divided by PI
--]]
local constOneDividedByPI = 1 / math.pi

--[[
	Normalizes scaling from an angle

	@param   number   angle in radians
	@param   number   scale factor of x
	@param   number   scale factor of y
	@return  number   normalized scaling
	@uses    constOneDividedByPI
--]]
local function normalizeScalingFromAngle(angle, sx, sy)
	local factorY = math.abs((constOneDividedByPI * (angle % math.pi)) - .5)
	local factorX = .5 - factorY
	return (math.abs(sx) * factorX) + (math.abs(sy) * factorY)
end

--[[
	Gets the average of two numbers

	@param   number   number 1
	@param   number   number 2
	@return  number   average
--]]
local function getAverage(n1, n2)
	return (n1 + n2) / 2
end

--[[
	Update box boundaries on grow

	@param   table    box boundaries
	@param   number   x1
	@param   number   y1
	@param   number   x2
	@return  number   y2
	@return  void
--]]
local function updateBoxBoundariesOnGrow(box, x1, y1, x2, y2)
	if x1 < box.x1 then box.x1 = x1 end
	if x2 > box.x2 then box.x2 = x2 end
	if y1 < box.y1 then box.y1 = y1 end
	if y2 > box.y2 then box.y2 = y2 end
end

--[[
	Orders two numbers

	@param   number   n1
	@param   number   n2
	@return  numbers  reordered numbers (n1, n2)
--]]
local function orderTwoNumbers(n1, n2)
	if n2 < n1 then
		return n2, n1
	else
		return n1, n2
	end
end

----------------------------------------------------
-- Module setup
----------------------------------------------------

local skeletor = {}
skeletor.__index = skeletor

--[[
	Gets the vertices of an ellipse

	@param   number   center x
	@param   number   center y
	@param   number   width
	@param   number   height
	@param   number   angle in radians
	@param   number   number of segments
	@return  table    vertices {x1, y1, x2, y2, ...}
--]]
function skeletor:getEllipseVertices(cx, cy, width, height, angle, numSegments)
	local sy = height / width
	local radius = width / 2
	local arcAngle = 2 * math.pi
	local theta = arcAngle / numSegments
	local cosine = math.cos(theta)
	local sine = math.sin(theta)
	local x = radius
	local y = 0
	local vertices = {}
	for i = 1, numSegments do
		local vx = x
		local vy = y * sy
		local vxT = vx
		vx = vy * math.sin(angle) + vx * math.cos(angle)
		vy = vxT * math.sin(angle) - vy * math.cos(angle)
		table.insert(vertices, vx + cx)
		table.insert(vertices, vy + cy)
		local xT = x
		x = (cosine * x) - (sine * y)
		y = (sine * xT) + (cosine * y)
	end
	return vertices
end

--[[
	Default style

	uses@    skeletor:getEllipseVertices()
--]]
local defaultStyle = {
	show = true,
	boundariesCalculate = false,
	boundariesShow = true,
	boundariesStyle = "smooth",
	boundariesWidth = 1,
	boundariesColor = {255, 0, 0},
	wireShow = false,
	wireStyle = "smooth",
	wireWidth = 1,
	wireColor = {0, 0, 0},
	jointShow = true,
	jointMode = "fill",
	jointShape = skeletor:getEllipseVertices(0, 0, 8, 8, 0, 30),
	jointRotatable = false,
	jointScalable = true,
	jointColor = {0, 123, 255},
	shapeShow = true,
	shapeMode = "fill",
	shapeShape = skeletor:getEllipseVertices(0, 0, 1, .35, 0, 30),
	shapeSx = 1,
	shapeSy = 1,
	shapeColor = {255, 255, 255},
	textureShow = false,
	textureImage = nil,
	textureBlendMode = "alpha",
	textureColor = {255, 255, 255},
	textureColorMode = "replace",
	texturePixelEffect = nil
}

--[[
	New (constructor)

	@param   table    style [def: {}]
	@param   table    skeletons [def: {}]
	@return  table    metatable
	@uses    mergeTables()
--]]
local function new(style, skeletons)
	return setmetatable({
		style = mergeTables(defaultStyle, style or {}),
		skeletons = skeletons or {}
	}, skeletor)
end

----------------------------------------------------
-- Getters and setters
----------------------------------------------------

function skeletor:getStyle() return self.style end
function skeletor:setStyle(style) self.style = mergeTables(self.style, style) end
function skeletor:getSkeletons() return self.skeletons end
function skeletor:setSkeletons(skeletons) self.skeletons = skeletons end

----------------------------------------------------
-- Skeleton functions
----------------------------------------------------

--[[
	Creates a new skeleton

	@param   string   name
	@param   table    properties
	@return  void
	@uses    getValorDef()
--]]
function skeletor:newSkeleton(name, props)
	props = props or {}
	self.skeletons[name] = {
		x = props.x or 0,
		y = props.y or 0,
		sx = props.sx or 1,
		sy = props.sy or 1,
		angle = props.angle or 0,
		show = getValorDef(props.show, self.style.show),
		boundariesCalculate = getValorDef(props.boundariesCalculate, self.style.boundariesCalculate),
		boundariesShow = getValorDef(props.boundariesShow, self.style.boundariesShow),
		boundariesStyle = props.boundariesStyle or self.style.boundariesStyle,
		boundariesWidth = props.boundariesWidth or self.style.boundariesWidth,
		boundariesColor = props.boundariesColor or self.style.boundariesColor,
		wireShow = getValorDef(props.wireShow, self.style.wireShow),
		wireStyle = props.wireStyle or self.style.wireStyle,
		wireWidth = props.wireWidth or self.style.wireWidth,
		wireColor = props.wireColor or self.style.wireColor,
		jointShow = getValorDef(props.jointShow, self.style.jointShow),
		jointMode = props.jointMode or self.style.jointMode,
		jointShape = props.jointShape or self.style.jointShape,
		jointRotatable = getValorDef(props.jointRotatable, self.style.jointRotatable),
		jointScalable = getValorDef(props.jointScalable, self.style.jointScalable),
		jointColor = props.jointColor or self.style.jointColor,
		shapeShow = getValorDef(props.shapeShow, self.style.shapeShow),
		shapeMode = props.shapeMode or self.style.shapeMode,
		shapeShape = props.shapeShape or self.style.shapeShape,
		shapeSx = props.shapeSx or self.style.shapeSx,
		shapeSy = props.shapeSy or self.style.shapeSy,
		shapeColor = props.shapeColor or self.style.shapeColor,
		textureShow = getValorDef(props.textureShow, self.style.textureShow),
		textureImage = props.textureImage or self.style.textureImage,
		textureBlendMode = props.textureBlendMode or self.style.textureBlendMode,
		textureColor = props.textureColor or self.style.textureColor,
		textureColorMode = props.textureColorMode or self.style.textureColorMode,
		texturePixelEffect = props.texturePixelEffect or self.style.texturePixelEffect,
		boundaries = {},
		childBones = {}
	}
end

--[[
	Creates a new bone

	@param   string   name
	@param   string   path
	@param   table    properties
	@return  void
	@uses    parseBool()
--]]
function skeletor:newBone(path, props)
	local function newBone(path, i, bone, props)
		if #path == i then
			bone[path[i]] = {
				length = props.length or 0,
				sx = props.sx or 1,
				sy = props.sy or 1,
				angle = props.angle or 0,
				show = getValorDef(props.show, true),
				wireShow = props.wireShow,
				wireStyle = props.wireStyle,
				wireWidth = props.wireWidth,
				wireColor = props.wireColor,
				jointShow = props.jointShow,
				jointMode = props.jointMode,
				jointShape = props.jointShape,
				jointRotatable = props.jointRotatable,
				jointScalable = props.jointScalable,
				jointColor = props.jointColor,
				shapeShow = props.shapeShow,
				shapeMode = props.shapeMode,
				shapeShape = props.shapeShape,
				shapeSx = props.shapeSx,
				shapeSy = props.shapeSy,
				shapeColor = props.shapeColor,
				textureShow = props.textureShow,
				textureImage = props.textureImage,
				textureBlendMode = props.textureBlendMode,
				textureColor = props.textureColor,
				textureColorMode = props.textureColorMode,
				texturePixelEffect = props.texturePixelEffect,
				childBones = {}
			}
		else
			newBone(path, i + 1, bone[path[i]].childBones, props)
		end
	end
	newBone(splitPath(path), 1, self.skeletons, props or {})
end

--[[
	Edits a skeleton

	@param   string   name
	@param   table    properties
	@return  void
--]]
function skeletor:editSkeleton(name, props)
	for k,v in pairs(props) do
		self.skeletons[name][k] = v
	end
end

--[[
	Edits a bone

	@param   string   path
	@param   table    properties
	@return  void
--]]
function skeletor:editBone(path, props)
	local function editBone(path, i, bone, props)
		if #path == i then
			for k,v in pairs(props) do
				bone[path[i]][k] = v
			end
		else
			editBone(path, i + 1, bone[path[i]].childBones, props)
		end
	end
	editBone(splitPath(path), 1, self.skeletons, props or {})
end

--[[
	Deletes a skeleton

	@param   string   name
	@return  void
--]]
function skeletor:deleteSkeleton(name)
	self.skeletons[name] = nil
end

--[[
	Deletes a bone

	@param   string   path
	@return  void
--]]
function skeletor:deleteBone(path)
	local function deleteBone(path, i, bone)
		if #path == i then
			bone[path[i]] = nil
		else
			deleteBone(path, i + 1, bone[path[i]].childBones)
		end
	end
	deleteBone(splitPath(path), 1, self.skeletons)
end

--[[
	Clones a skeleton

	@param   string   name of the skeleton to clone from
	@param   string   name of the new skeleton
	@param   table    skeleton properties to edit
	@return  void
	@uses    copyDeepTable(), skeletor:editSkeleton()
--]]
function skeletor:cloneSkeleton(from, clone, props)
	self.skeletons[clone] = copyDeepTable(self.skeletons[from])
	self:editSkeleton(clone, props or {})
end

--[[
	Draws the skeletons

	@return  void
	@uses    scale(), polarToCartesian(), translate(), getCoordinatesDistance()
	@uses    orderTwoNumbers(), updateBoxBoundariesOnGrow(), parseBool()
	@uses    copyTable(), getAverage()
--]]
function skeletor:draw()
	local function drawBones(bone, x1, y1, skeleton)
		local sx, sy = scale(bone.sx, bone.sy, skeleton.sx, skeleton.sy)
		local angle = bone.angle + skeleton.angle
		local x2, y2 = polarToCartesian(bone.length, angle)
		x2, y2 = scale(x2, y2, sx, sy)
		x2, y2 = translate(x2, y2, x1, y1)
		angle = math.atan2(y2 - y1, x2 - x1)
		local length = getCoordinatesDistance(x1, y1, x2, y2)
		local x1T, x2T = orderTwoNumbers(x1, x2)
		local y1T, y2T = orderTwoNumbers(y1, y2)
		updateBoxBoundariesOnGrow(skeleton.boundaries, x1T, y1T, x2T, y2T)
		local xAverage = getAverage(x1, x2)
		local yAverage = getAverage(y1, y2)
		if bone.show then
			if parseBool(bone.wireShow, skeleton.wireShow) then
				local wireStyle = bone.wireStyle or skeleton.wireStyle
				local wireWidth = bone.wireWidth or skeleton.wireWidth
				local wireColor = bone.wireColor or skeleton.wireColor
				love.graphics.setLine(wireWidth, wireStyle)
				love.graphics.setColor(wireColor)
				love.graphics.line(x1, y1, x2, y2)
			end
			if parseBool(bone.jointShow, skeleton.jointShow) then
				local jointMode = bone.jointMode or skeleton.jointMode
				local jointShape = copyTable(bone.jointShape or skeleton.jointShape)
				local jointScalable = parseBool(bone.jointScalable, skeleton.jointScalable)
				local jointRotatable = parseBool(bone.jointRotatable, skeleton.jointRotatable)
				local jointColor = bone.jointColor or skeleton.jointColor
				local jointAngle, jointSx, jointSy
				if jointRotatable then jointAngle = angle else jointAngle = 0 end
				if jointScalable then jointSx, jointSy = sx, sy else jointSx, jointSy = 1, 1 end
				love.graphics.setColor(jointColor)
				transform(jointShape, jointAngle, x1, y1, jointSx, jointSy)
				love.graphics.polygon(jointMode, jointShape)
				transform(jointShape, 0, x2 - x1, y2 - y1, 1, 1)
				love.graphics.polygon(jointMode, jointShape)
			end
			if parseBool(bone.shapeShow, skeleton.shapeShow) then
				local shapeMode = bone.shapeMode or skeleton.shapeMode
				local shapeShape = copyTable(bone.shapeShape or skeleton.shapeShape)
				local shapeSx = bone.shapeSx or skeleton.shapeSx
				local shapeSy = bone.shapeSy or skeleton.shapeSy
				local shapeColor = bone.shapeColor or skeleton.shapeColor
				transform(
					shapeShape,
					angle,
					xAverage,
					yAverage,
					length * shapeSx,
					length * shapeSy * normalizeScalingFromAngle(angle, sx, sy)
				)
				love.graphics.setColor(shapeColor)
				love.graphics.polygon(shapeMode, shapeShape)
			end
			if parseBool(bone.textureShow, skeleton.textureShow) then
				local textureImage = bone.textureImage or skeleton.textureImage
				local textureBlendMode = bone.textureBlendMode or skeleton.textureBlendMode
				local textureColor = bone.textureColor or skeleton.textureColor
				local textureColorMode = bone.textureColorMode or skeleton.textureColorMode
				local texturePixelEffect = bone.texturePixelEffect or skeleton.texturePixelEffect
				love.graphics.setBlendMode(textureBlendMode)
				love.graphics.setColorMode(textureColorMode)
				if textureColorMode ~= "replace" then love.graphics.setColor(textureColor) end
				if texturePixelEffect then love.graphics.setPixelEffect(texturePixelEffect) end
				love.graphics.draw(
					textureImage,
					xAverage,
					yAverage,
					angle,
					sx,
					sy,
					(textureImage:getWidth() / 2),
					(textureImage:getHeight() / 2)
				)
				if texturePixelEffect then love.graphics.setPixelEffect() end
			end
		end
		for _,childBone in pairs(bone.childBones) do
			drawBones(childBone, x2, y2, skeleton)
		end
	end
	for _,skeleton in pairs(self.skeletons) do
		if skeleton.show then
			skeleton.boundaries = {x1 = 999999, y1 = 999999, x2 = -999999, y2 = -999999}
			for _,childBone in pairs(skeleton.childBones) do
				drawBones(childBone, skeleton.x, skeleton.y, skeleton)
			end
			if skeleton.boundariesShow then
				love.graphics.setLine(skeleton.boundariesWidth, skeleton.boundariesStyle)
				love.graphics.setColor(skeleton.boundariesColor)
				love.graphics.rectangle(
					"line",
					skeleton.boundaries.x1,
					skeleton.boundaries.y1,
					skeleton.boundaries.x2 - skeleton.boundaries.x1,
					skeleton.boundaries.y2 - skeleton.boundaries.y1
				)
			end
		end
	end
end

----------------------------------------------------
-- Module
----------------------------------------------------

return setmetatable({new = new},
	{__call = function(_, ...) return new(...) end})

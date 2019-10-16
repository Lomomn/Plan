local floor = math.floor
local min = math.min
local max = math.max
local abs = math.abs

local Scene = Class{
	init = function(self, size)
		self.cells = {}
		self.objects = {}
		self.size = size or 128
	end,

	Rectangle = Class{
		init = function(self, x,y,w,h, scene)
			self.x, self.y, self.w, self.h = x,y,w,h
			self.scene = scene or Scene or error('No scene provided')
			self.cellRefs = {}
			self.scene:insert(self)
		end,
		type = 'Rectangle'
	},

	Point = Class{
		init = function(self, x,y, scene)
			self.x, self.y = x,y
			self.scene = scene or Scene or error('No scene provided')
			self.cellRefs = {}
			self.scene:insert(self)
		end,
		type = 'Point'
	}
}
function Scene:newRectangle(...) return Scene.Rectangle(unpack({...})) end
function Scene.Rectangle:updateDimensions(w,h) self.w, self.h = w, h; self.scene:insert(self) end
function Scene.Rectangle:getDimensions() return self.w, self.h end
function Scene.Rectangle:move(x,y) self.x, self.y = self.x+x, self.y+y; self.scene:insert(self) end
function Scene.Rectangle:moveTo(x,y) self.x, self.y = x, y; self.scene:insert(self) end
function Scene.Rectangle:getPoints() return self.x, self.y, self.x+self.w, self.y+self.h end
function Scene.Rectangle:draw() love.graphics.rectangle('fill', self.x, self.y, self.w, self.h) end
function Scene.Rectangle:collide(other)
	local x1,y1,x2,y2 = self:getPoints()
	local w,h = self:getDimensions()
	if other.type == 'Rectangle' then
		local ox1,oy1,ox2,oy2 = other:getPoints()
		local ow,oh = other:getDimensions()
		return (abs((y1+h/2) - (oy1+oh/2)) <= ((h + oh)/2)) and
					 (abs((x1+w/2) - (ox1+ow/2)) <= ((w + ow)/2))
	elseif other.type == 'Point' then
		local x,y = other:getPoints()
		return x>=x1 and x<=x2 and y>=y1 and y<=y2
	end
end
function Scene.Rectangle:updateCellRefs()
	self.cellRefs = {}
	local x1, y1, x2, y2 = self:getPoints()
	for x=floor(x1/self.scene.size), floor(x2/self.scene.size) do
		for y=floor(y1/self.scene.size), floor(y2/self.scene.size) do
			table.insert(self.cellRefs, self.scene:getCell(x, y))
		end
	end
end

function Scene:newPoint(...) return Scene.Point(unpack({...})) end
function Scene.Point:move(x,y) self.x, self.y = self.x+x, self.y+y; self.scene:insert(self) end
function Scene.Point:moveTo(x,y) self.x, self.y = x, y; self.scene:insert(self) end
function Scene.Point:getPoints() return self.x, self.y end
function Scene.Point:draw() love.graphics.rectangle('fill', self.x-2, self.y-2, 4, 4) end
function Scene.Point:collide(other)
	local x,y = self:getPoints()
	if other.type == 'Rectangle' then
		local x1,y1,x2,y2 = other:getPoints()
		return x>=x1 and x<=x2 and y>=y1 and y<=y2
	elseif other.type == 'Point' then
		return x==other.x and y==other.y
	end
end
function Scene.Point:updateCellRefs()
	self.cellRefs = {}
	local x1, y1 = self:getPoints()
	local cx1, cy1 = floor(x1/self.scene.size), floor(y1/self.scene.size)
	self.cellRefs = {
		self.scene:getCell(cx1, cy1)
	}
end

function Scene:getCell(x,y)
	if self.cells[x] == nil then
		self.cells[x] = {} -- Make column if it doesn't exist
	end
	if self.cells[x][y] == nil then -- Make row
		self.cells[x][y] = { -- Doesn't need it's own class
			['count'] = 0, -- Track the number of objects (manual increment)
			['x'] = x, -- Needed to destroy cell from "above", self = nil
			['y'] = y, --		only destroys a local reference
			['objects'] = {}
		}
	end
	return self.cells[x][y]
end

function Scene:insert(object)
	if self.objects[object] then
		self:remove(object)
	end
	self.objects[object] = object
	
	object:updateCellRefs()
	for _,cell in ipairs(object.cellRefs) do
		if cell.objects[object] == nil then
			cell.count = cell.count + 1
			cell.objects[object] = object
		end
	end
end

function Scene:remove(object)
	for _,cell in ipairs(object.cellRefs) do
		if cell.objects[object] ~= nil then
			cell.count = cell.count - 1
			cell.objects[object] = nil
			if cell.count == 0 then
				self.cells[cell.x][cell.y] = nil
			end
		end
	end
	self.objects[object] = nil
end

function Scene:draw()
	love.graphics.setColor(0,1,0,0.5)
	for v,_ in pairs(self.objects) do
		v:draw()
	end
	for x,columns in pairs(self.cells) do
		for y,cell in pairs(columns) do
			love.graphics.rectangle('line',x*self.size,y*self.size,self.size,self.size)
			love.graphics.print(cell.count,x*self.size,y*self.size)
		end
	end
end

function Scene:getCollisions(object)
	local collisions = {}
	for _,cell in pairs(object.cellRefs) do
		if cell.count > 1 then
			for other,_ in pairs(cell.objects) do
				if object ~= other and object:collide(other) then
					table.insert(collisions, other)
				end
			end
		end
	end
	return collisions
end

return Scene
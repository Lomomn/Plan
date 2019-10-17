local Task = Class{
	init = function(self, pos, text, scene)
		self.pos = pos
		self.text = text
		self.loveText = love.graphics.newText(love.graphics.getFont(), text)
		self.hovered = false
		self.edited = false
		self.above = nil
		self.below = nil

		-- TODO more elegant structure, maybe destructuring pattern
		-- is possible to keep code clean
		self.PlanTextColor = Theme.PlanTextColor or {1,1,1,1}
		self.PlanBackgroundColor = Theme.PlanBackgroundColor or {1,1,1,0.3}
		self.PlanBorderColor = Theme.PlanBorderColor or {1,1,1,1}
		self.PlanPadding = Theme.PlanPadding or 0
		
		self.scene = scene or Scene or error('Scene must be provided or made global')
		self.bounds = self.scene:newRectangle(
			self.pos.x - self.PlanPadding/2,
			self.pos.y - self.PlanPadding/2,
			self.loveText:getWidth() + self.PlanPadding,
			self.loveText:getHeight() + self.PlanPadding
		)
		self.bounds.parent = self -- Set parent ref for collision callbacks
	end
}


function Task:draw()
	self.PlanBackgroundColor = self.hovered and
		Theme.PlanHoveredBackgroundColor or Theme.PlanBackgroundColor
	self.PlanTextColor = self.hovered and
		Theme.PlanHoveredTextColor or Theme.PlanTextColor
	self.PlanBorderColor = self.edited and
		Theme.PlanEditedBorderColor or Theme.PlanBorderColor

	for i=0,1 do
		love.graphics.setColor(i==0 and
			self.PlanBackgroundColor or self.PlanBorderColor)
		love.graphics.rectangle(i==0 and 'fill' or 'line',
			self:getBounds())
	end
	
	love.graphics.setColor(self.PlanTextColor)
	love.graphics.draw(self.loveText, self.pos.x, self.pos.y)
end

function Task:update(dt)
	self.hovered = false
end

-- Text updating functions
function Task:keypressed(char)
	if char == 'backspace' then
		self.text = string.sub(self.text, 1, #self.text-1)
	else
		self.text = self.text .. char
	end
	self.loveText:set(self.text)
	self:updateDimensions()
end

-- Relationship and snapping functions
function Task:snapToAbove(other)
	other.below = self
	self.above = other

	local x,y,w,h = other:getBounds()
	self:moveTo(x, y+h)

	if self.below then
		self.below:snapToAbove(self)
	end
end
function Task:unsnapToAbove()
	self.above.below = nil
	self.above = nil
end

-- Movement and bounds functions
function Task:getBounds()
	local b = self.bounds
	return b.x,b.y,b.w,b.h
end
function Task:move(x,y)
	-- Reposition and/or resize depending on what changed
	self.pos.x = self.pos.x + x
	self.pos.y = self.pos.y + y
	self.bounds:move(x and x or 0, y and y or 0)

	if self.below then
		self.below:move(x,y)
	end
end
function Task:moveTo(x,y)
	self.pos.x = x + self.PlanPadding/2
	self.pos.y = y + self.PlanPadding/2
	self.bounds:moveTo(x, y)
end
function Task:updateDimensions()
	-- Resize on text change event
	self.bounds:updateDimensions(
		self.loveText:getWidth() + self.PlanPadding,
		self.loveText:getHeight() + self.PlanPadding)
end

return Task
local Task = require'task'
Scene = require'collisions'() -- Init global collision scene

Plan = {}

function Plan:init()
	self.mousePos = Vector(0,0)
	self.mouseCur = Scene:newPoint(0,0)
	self.buttonPressed = false -- 1,2,3 or false
	self.touchingTask = nil -- Task the cursor is touching, if any
	self.movingTask = nil -- Task which has been clicked on/is being dragged

	self.camera = Camera(0, 0)
	self.camera:lookAt(0, 0)
	self.camera.scale = 2

	self.tasks = {}
	table.insert(self.tasks, Task(Vector(0,0), 'finish this program, super long boiiiiiiiiiii'))
	table.insert(self.tasks, Task(Vector(300,100), 'zoom'))
end


function Plan:update(dt)
	local mx, my = love.mouse.getPosition()
	local wx, wy = self.camera:mousePosition()

	for _,task in ipairs(self.tasks) do
		task:update(dt)
	end

	self.mouseCur:moveTo(wx,wy)
	if self.buttonPressed then
		local dx, dy = self.mousePos:unpack()
		dx = (dx - mx) / self.camera.scale
		dy = (dy - my) / self.camera.scale
		-- Move camera
		if not self.touchingTask or self.buttonPressed == 3 then
			self.camera:move(dx,dy)
		end
		-- Move task
		if self.touchingTask and self.buttonPressed == 1 then
			self.movingTask = self.touchingTask
			self.movingTask.hovered = true -- Prevent task:update setting to false
			if self.movingTask.above then
				-- Unsnap task
				self.movingTask:unsnapToAbove()
			end
			self.movingTask:move(-dx,-dy)
		end
	else -- Not pressed
		-- Get a new touchingTask
		self.touchingTask = nil
		for _,other in ipairs(Scene:getCollisions(self.mouseCur)) do
			other.parent.hovered = true
			self.touchingTask = other.parent
		end
	end
	self.mousePos.x, self.mousePos.y = mx, my
end


function Plan:wheelmoved(x, y)
	local newScale = self.camera.scale + (y / 10)
	if newScale > 0.1 then
		self.camera.scale = newScale
	end
end


function Plan:draw()
	self.camera:attach()
	for _,task in ipairs(self.tasks) do
		task:draw()
	end
	Scene:draw()
	self.camera:detach()
end


function Plan:mousepressed(x,y,button)
	self.buttonPressed = button
end
function Plan:mousereleased()
	self.buttonPressed = false

	-- Snap task to above
	if self.movingTask then
		for _,otherBounds in ipairs(Scene:getCollisions(self.movingTask.bounds)) do
			if otherBounds.type == 'Rectangle' then -- Exclude cursor
				-- Other task accepts a child
				-- TODO insert between Tasks
				
				if
					not otherBounds.parent.below and
					not self.movingTask.above and
					self.movingTask.above ~= otherBounds.parent and
					self.movingTask.below ~= otherBounds.parent
				then
						self.movingTask:snapToAbove(otherBounds.parent)
				end
			end
		end
	end

	self.movingTask = nil

end


function Plan:leave()

end


return Plan
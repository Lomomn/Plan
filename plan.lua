local json = require'lib.json.json'

local Task = require'task'
Scene = require'collisions'() -- Init global collision scene

Plan = {}

function Plan:init()
	self.mouseCur = Scene:newPoint(0,0)
	self.buttonPressed = false -- 1,2,3 or false
	self.touchingTask = nil -- Task the cursor is touching, if any
	self.movingTask = nil -- Task which has been clicked on/is being dragged
	self.editingTask = nil -- Task which has keyboard input

	self.dx, self.dy = 0, 0
	self.backgroundGridSize = 32 -- Space between background points
	self.camera = Camera(0, 0)
	self.camera:lookAt(0, 0)
	self.camera.scale = 2
	self.focussed = true

	self.tasks = {}
	table.insert(self.tasks, Task(Vector(0,0), 'finish this program'))

	self:generateBackground()
end


function Plan:save() -- Save all tasks to JSON

end


function Plan:update(dt)
	for _,task in ipairs(self.tasks) do
		task:update(dt)
	end
	if self.touchingTask then
		self.touchingTask:setHovered(true)
	end

	if not self.focussed then
		if dt < 1/10 then -- Cut the FPS when window isn't focussed
			love.timer.sleep(1/10 - dt)
		end
	end
end


function Plan:wheelmoved(x, y)
	local newScale = self.camera.scale + (y / 10)
	if newScale > 0.1 then -- Limit zoom so it doesn't invert
		self.camera.scale = newScale
	end
end

function Plan:generateBackground()
	self.backgroundPoints = {}
	local p,w,h = {}, love.graphics.getDimensions()
	for x=-w/2,w/2,self.backgroundGridSize do -- Draw grid pattern
		for y=-h/2,h/2,self.backgroundGridSize do
			table.insert(self.backgroundPoints, {x, y})
		end
	end
end

function Plan:draw()
	self.camera:attach()
	if self.camera.scale >= 0.9 then
		local x,y = self.camera:position()
		love.graphics.translate(x-x%self.backgroundGridSize, y-y%self.backgroundGridSize) -- Offset background drawing
		love.graphics.points(self.backgroundPoints)
		love.graphics.translate(-x+x%self.backgroundGridSize, -y+y%self.backgroundGridSize) -- Reset the offset
	end
	
	for _,task in ipairs(self.tasks) do -- Draw tasks
		task:draw()
	end
	-- Scene:draw()
	self.camera:detach()

	love.graphics.print(love.timer.getFPS())
end


function Plan:mousemoved(x,y,dx,dy,istouch)
	-- Fix dx and dy to account for zoom/scale
	self.dx = -dx / self.camera.scale
	self.dy = -dy / self.camera.scale
	
	local wx, wy = self.camera:mousePosition()
	self.mouseCur:moveTo(wx,wy)

	if self.buttonPressed then
		-- Move camera
		if not self.touchingTask or self.buttonPressed == 3 then
			self.camera:move(self.dx,self.dy)
		end

		-- Promote touchingTask to movingTask
		if self.touchingTask and self.buttonPressed == 1 then
			self.movingTask = self.touchingTask
			self.movingTask:setHovered(true) -- Prevent task:update setting to false
			if self.movingTask.above then
				-- Unsnap task
				self.movingTask:unsnapToAbove()
			end
		end
	else
		-- Don't replace touchingTask unless there are no button presses
		-- because if the cursor moves too fast, it will not be touching
		-- the task any more, meaning that the camera moves.
		if self.touchingTask then
			self.touchingTask:setHovered(false)
			self.touchingTask = nil
		end
		for _,other in ipairs(Scene:getCollisions(self.mouseCur)) do
			self.touchingTask = other.parent
		end
	end

	-- Move task
	if self.movingTask then -- doesn't matter if button is pressed
		self.movingTask:move(-self.dx,-self.dy)
	end
end
function Plan:mousepressed(x,y,button,istouch,presses)
	self.buttonPressed = button
	if presses >= 2 and self.touchingTask then
		-- Edit task
		self.editingTask = self.touchingTask:setEdited(true)
	else
		-- Stop editing task
		if self.editingTask then
			self.editingTask:setEdited(false)
			self.editingTask = nil
		end
	end
end
function Plan:mousereleased(x,y,button,istouch,presses)
	self.buttonPressed = false

	if self.touchingTask then
		if button == 3 then -- Middle click
			self.touchingTask:setDone(not self.touchingTask.done)
		elseif button == 2 then -- Right click
			-- Open context menu
			-- TODO
		end
	
	end

	if self.movingTask then
		-- Snap task to above
		for _,otherBounds in ipairs(Scene:getCollisions(self.movingTask.bounds)) do
			if otherBounds.type == 'Rectangle' then -- Exclude cursor
				if -- Other task accepts a child
					not otherBounds.parent.below and
					not self.movingTask.above and
					self.movingTask.above ~= otherBounds.parent and
					self.movingTask.below ~= otherBounds.parent
				then
					-- TODO insert between Tasks
						self.movingTask:snapToAbove(otherBounds.parent)
				end
			end
		end
	end

	self.movingTask = nil
end

function Plan:textinput(t)
	if self.editingTask then
		self.editingTask:keypressed(t)
	end
end

function Plan:keypressed(key)
	if self.editingTask then -- handle specific cases
		if key == 'backspace' then
			self.editingTask:keypressed(key)
		elseif key == 'return' then
			self.editingTask:setEdited(false)
			self.editingTask = nil
		end
	elseif key == 'n' then -- New Task
		local newTask = Task(Vector(self.mouseCur:getPoints()), 'New Task')
		table.insert(self.tasks, newTask)
		
		if self.touchingTask then
			if not self.touchingTask.below then -- Snap to touchingTask
				newTask:snapToAbove(self.touchingTask)
			else -- Snap to child, if one is found
				local lowest = self.touchingTask:getLowest()
				newTask:snapToAbove(lowest)
			end
		else
			self.movingTask = newTask
		end
		self.editingTask = newTask:setEdited(true)
		love.event.clear() -- Clear events to prevent textinput from firing
	end
	if key == 'escape' then -- Quit
		love.event.quit()
	end
end


function Plan:leave()

end


function Plan:resize()
	self:generateBackground()
end

function Plan:focus(f)
	self.focussed = f
end


return Plan
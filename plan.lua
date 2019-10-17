local Task = require'task'
Scene = require'collisions'() -- Init global collision scene

Plan = {}

function Plan:init()
	self.mouseCur = Scene:newPoint(0,0)
	self.buttonPressed = false -- 1,2,3 or false
	self.touchingTask = nil -- Task the cursor is touching, if any
	self.movingTask = nil -- Task which has been clicked on/is being dragged
	self.editingTask = nil -- Task which has keyboard input

	self.camera = Camera(0, 0)
	self.camera:lookAt(0, 0)
	self.camera.scale = 2

	self.tasks = {}
	table.insert(self.tasks, Task(Vector(0,0), 'finish this program, super long boiiiiiiiiiii'))
	table.insert(self.tasks, Task(Vector(300,100), 'zoom'))
end


function Plan:update(dt)
	for _,task in ipairs(self.tasks) do
		task:update(dt)
	end
	if self.touchingTask then
		self.touchingTask.hovered = true
	end
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
	-- Scene:draw()
	self.camera:detach()

	love.graphics.print(tostring(self.movingTask),0,0)
end

function Plan:mousemoved(x,y,dx,dy,istouch)
	-- Fix dx and dy to account for zoom/scale
	dx = -dx / self.camera.scale
	dy = -dy / self.camera.scale
	
	local wx, wy = self.camera:mousePosition()
	self.mouseCur:moveTo(wx,wy)

	if self.buttonPressed then
		-- Move camera
		if not self.touchingTask or self.buttonPressed == 3 then
			self.camera:move(dx,dy)
		end

		-- Promote touchingTask to movingTask
		if self.touchingTask and self.buttonPressed == 1 then
			self.movingTask = self.touchingTask
			self.movingTask.hovered = true -- Prevent task:update setting to false
			if self.movingTask.above then
				-- Unsnap task
				self.movingTask:unsnapToAbove()
			end
		end
	else
		-- Don't replace touchingTask unless there are no button presses
		-- because if the cursor moves too fast, it will not be touching
		-- the task any more, meaning that the camera moves.
		self.touchingTask = nil
		for _,other in ipairs(Scene:getCollisions(self.mouseCur)) do
			self.touchingTask = other.parent
		end
	end

	-- Move task
	if self.movingTask then -- doesn't matter if button is pressed
		self.movingTask:move(-dx,-dy)
	end
end
function Plan:mousepressed(x,y,button,istouch,presses)
	self.buttonPressed = button
	if presses >= 2 and self.touchingTask then
		-- Edit task
		self.editingTask = self.touchingTask
		self.editingTask.edited = true
	else
		-- Stop editing task
		if self.editingTask then
			self.editingTask.edited = false
			self.editingTask = nil
		end
	end
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
			self.editingTask.edited = nil
			self.editingTask = nil
		end
	elseif key == 'n' then -- New Task
		local newTask = Task(Vector(self.mouseCur:getPoints()), 'New Task')
		table.insert(self.tasks, newTask)
		
		if self.touchingTask then
			if not self.touchingTask.below then -- Snap to touchingTask
				newTask:snapToAbove(self.touchingTask)
			else -- Snap to child, if one is found
				local next = self.touchingTask.below
				while next.below do -- Keep going until you can't :(
					next = next.below
				end
				newTask:snapToAbove(next)
			end
		else
			self.movingTask = newTask
		end
	end
	if key == 'escape' then -- Quit
		love.event.quit()
	end
end


function Plan:leave()

end


return Plan
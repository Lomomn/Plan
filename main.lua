Class = require'lib.hump.class'
Camera = require'lib.hump.camera'
Vector = require'lib.hump.vector'
Gamestate = require'lib.hump.gamestate'

Plan = require'plan'
Theme = require'theme'

function love.load()
	love.graphics.setDefaultFilter('nearest', 'nearest')
	Gamestate.registerEvents()
	Gamestate.switch(Plan)
end


function love.draw()

end


function love.update(dt)

end

function love.keypressed(key)
	if key == 'escape' then
		love.event.quit()
	end
end
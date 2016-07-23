local System = require "lib.knife.system"
local Vec = require "vector"

local Entity = {
   eid = 1,
   entities = {},
   add = function(E, entity)
      table.insert(E.entities, E.eid, entity)
      E.eid = E.eid + 1
   end
}

-- Collision Detection

local collisions = {}

local Hit = {}

function Hit.new(entity)
   return { collider = entity }
end

-- Systems

local updatePlayerVelocity = System(
   { "velocity" , "speed", "-player"},
   function (v, speed)
      v.x = 0
      v.y = 0
      local newSpeed = speed
      
      if love.keyboard.isDown("space") then
         newSpeed = speed * 2.5
      end
      if love.keyboard.isDown("a") then
         v.x = -newSpeed
      end
      if love.keyboard.isDown("d") then
         v.x = newSpeed
      end
      if love.keyboard.isDown("w") then
         v.y = -newSpeed
      end
      if love.keyboard.isDown("s") then
         v.y = newSpeed
      end
   end
)

local updateVelocity = System(
   { "velocity", "speed", "position", "state", "!player"},
   function (v, speed, p, state, target)
      if state.current == "following" then
         local v_new = Vec.sub (target, p)
         local unit = Vec.unit (v_new)
         v.x = unit.x * speed
         v.y = unit.y * speed
      elseif state.current == "attacking" then
         v.x = -v.x
         v.y = -v.y
      else
         v.x, v.y = 0, 0
      end
   end
)

local updatePosition = System(
   { "position", "velocity" },
   function (p, v, dt)
      p.x = p.x + v.x * dt
      p.y = p.y + v.y * dt
   end
)

local drawEntity = System(
   { "position", "size", "color" },
   function (p, s, c)
      love.graphics.setColor(c.r, c.g, c.b, c.a)
      love.graphics.rectangle("fill", p.x, p.y, s.width, s.height)
   end
)

local updatePlayerState = System(
   { "state", "position", "-player" },
   function (state, p, dt)
      if state.current == "invulnerable" then
         if state.cooldown <= 0 then
            state.current = "normal"
         else
            state.cooldown = state.cooldown - dt
         end
      end
   end
)

local updateState = System(
   { "state", "position", "!player" },
   function (state, p, target)
      local distance = Vec.mag( Vec.sub (target, p) )
      if distance < 30 then
         state.current = "attacking"
      else
         state.current = "following"
      end
   end
)

local checkCollisions = System(
   { "position", "size", "!player" },
   function (p, s, target)
      local leftOf  = p.x + s.width < target.position.x
      local rightOf = p.x > target.position.x + target.size.width
      local above   = p.y + s.height < target.position.y
      local below   = p.y > target.position.y + target.size.height
      -- print (leftOf, rightOf, above, below)
      if not (leftOf or rightOf or above or below) then
         collisions[#collisions + 1] = Hit.new(entity)
         -- print("collision")
      end
         
   end
)

function handleCollisions(player)
   for i, v in ipairs(collisions) do
      if player.state.current == "normal" then
         print("Collision detected")
         player.state.current = "invulnerable"
         player.state.cooldown = 2
      end
      collisions[i] = nil
   end
end

function newEnemy(x, y, speed)
   local enemy = {
      position = { x = x, y = y },
      velocity = { x = -20, y = 30 },
      size = { width = 35, height = 40 },
      color = { r = 255, g = 0, b = 200, a = 255 },
      speed = speed or math.random(20,100),
      state = { current = "following" }
   }
   return enemy
end

-- Love API hooks

function love.load()
   local player = {
      player = true,
      position = { x = 20, y = 30 },
      velocity = { x = 150, y = 150 },
      size = { width = 35, height = 40 },
      color = { r = 255, g = 255, b = 0, a = 255 },
      speed = 100,
      state = { current = "normal", cooldown = 0 }
   }
   Entity:add(player)
   Entity:add(newEnemy(500, 300, 60))
   Entity:add(newEnemy(200, 100, 50))
   Entity:add(newEnemy(600, 200, 40))
   Entity:add(newEnemy(300, 140, 40))
end

function love.update(dt)
   if love.keyboard.isDown("escape") then
      love.event.quit()
   end
   for _, entity in pairs(Entity.entities) do
      updateState (entity, Entity.entities[1].position)
      updatePlayerState (entity, dt)
      updatePlayerVelocity (entity)
      updateVelocity (entity, Entity.entities[1].position)
      updatePosition (entity, dt)
      checkCollisions (entity, Entity.entities[1])
      handleCollisions (Entity.entities[1])
   end
end

function love.draw()
   for _, entity in pairs(Entity.entities) do
      drawEntity(entity)
   end
   love.graphics.setColor(255,255,255)
   love.graphics.print("Arcade Game", 200, 400)
end

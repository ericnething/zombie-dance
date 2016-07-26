local System = require "lib.knife.system"
local Vec = require "vector"
local Sort = require "mergesort"
local camera = require "camera"
local sti = require "lib.sti"

local Entity = {
   eid = 1,
   entities = {},
   add = function(E, entity)
      table.insert(E.entities, E.eid, entity)
      E.eid = E.eid + 1
   end
}

local Sprites = {
   player = {},
   enemy = {}
}

local player = {}

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
   { "velocity", "speed", "position", "state", "effects", "!player"},
   function (v, speed, p, state, e, target)
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

      if e["dancing"] then
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
   { "position", "size", "color", "sprites" },
   function (p, s, c, sp)
      local x, y = p.x - s.width/2, p.y - s.height
      love.graphics.setColor(c.r, c.g, c.b, c.a)
      love.graphics.rectangle("fill", x, y, s.width, s.height)
      love.graphics.setColor(255, 255, 255, 255)
      love.graphics.draw(sp[1], x, y, nil, s.width / sp[1]:getWidth() )
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

local updateEffects = System(
   { "position", "=effects", "!player" },
   function (p, e, player_pos, player_effects)
      local distance = Vec.mag( Vec.sub (player_pos, p) )
      if player.effects["playing_music"]
         and distance < 100
      then
         e["dancing"] = true
      else
         e["dancing"] = nil
      end
      return e
   end
)

local updatePlayerEffects = System(
   { "=effects", "-player" },
   function (e)
      if love.mouse.isDown(1) then
         e["playing_music"] = true
      else
         e["playing_music"] = nil
      end
      return e
   end
)

local updateState = System(
   { "state", "position", "!player" },
   function (state, p, target, playerstate)
      local distance = Vec.mag( Vec.sub (target, p) )
      if distance < 30 then
         state.current = "attacking"
      elseif distance > 200 then
         state.current = "idle"
      else
         state.current = "following"
      end
   end
)

local checkCollisions = System(
   { "position", "size", "!player" },
   function (p, s, target)
      local x, y = p.x - s.width/2, p.y - s.height
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
         player.health = player.health - 1
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
      state = { current = "following" },
      sprites = Sprites.enemy,
      effects = {}
   }
   return enemy
end

function updateCamera(player)
   local pad = 100
   local width, height = love.graphics.getDimensions()
   local right  = player.position.x + player.size.width - camera.x + pad
   local left   = player.position.x - pad
   local bottom = player.position.y + player.size.height - camera.y + pad
   local top    = player.position.y - pad
   if right > width then
      camera.x = camera.x + (right - width)
   elseif left < camera.x then
      camera.x = left
   end
   if bottom > height then
      camera.y = camera.y + (bottom - height)
   elseif top < camera.y then
      camera.y = top
   end
end

-- Love API hooks

function love.load()
   local sprite_path = "assets/sprites/"
   Sprites.player[1] = love.graphics.newImage(sprite_path .. "princess-girl.png")
   Sprites.enemy[1] = love.graphics.newImage(sprite_path .. "cat-girl.png")
   
   player = {
      player = true,
      position = { x = 200, y = 300 },
      velocity = { x = 150, y = 150 },
      size = { width = 35, height = 40 },
      color = { r = 255, g = 255, b = 0, a = 255 },
      speed = 100,
      state = { current = "normal", cooldown = 0 },
      health = 10,
      sprites = Sprites.player,
      effects = {}
   }
   Entity:add(player)
   Entity:add(newEnemy(500, 300, 60))
   Entity:add(newEnemy(200, 100, 50))
   Entity:add(newEnemy(600, 200, 40))
   Entity:add(newEnemy(300, 140, 40))

   map = sti("maps/test.lua")
end

function love.update(dt)
   if love.keyboard.isDown("escape") then
      love.event.quit()
   end

   map:update(dt)
   
   for _, entity in pairs(Entity.entities) do
      updateState (entity, player.position, player.state)
      updateEffects (entity, player.position, player.effects)
      
      updatePlayerState (entity, dt)
      updatePlayerEffects (entity)
      updatePlayerVelocity (entity)

      updateVelocity (entity, player.position)
      updatePosition (entity, dt)

      checkCollisions (entity, player)
      handleCollisions (player)
   end
   updateCamera(Entity.entities[1])
end

function love.draw()
   camera:set()

   map:draw()
   
   local drawOrder = getDrawOrder(Entity.entities)
   for _, i in ipairs(drawOrder) do
      drawEntity(Entity.entities[i])
   end
   love.graphics.print("Zombies can dance, too!", 200, 400)
   
   camera:unset()

   love.graphics.setColor(0,0,255,180)
   love.graphics.rectangle("fill",
                           love.graphics.getWidth() - 110, 6,
                           90, 20)
   
   love.graphics.setColor(255,255,255)
   love.graphics.print("Health: " .. player.health,
                       love.graphics.getWidth() - 100, 10)
   if player.effects["playing_music"] then
   love.graphics.print("Playing Music", love.graphics.getWidth() - 100, 30)
   end

   local screen_x, screen_y = map:convertPixelToTile(player.position.x,
                                                     player.position.y)
   love.graphics.print(string.format("(%f ,%f)", screen_x, screen_y),
                       0, love.graphics.getHeight() - 50)
   
end

function getDrawOrder(entities)
   local keys = {}
   for i, e in ipairs(entities) do
      if e.position and e.size and e.color then
         table.insert(keys, i)
      end
   end
   local result = Sort.mergesort(
      keys,
      function (a,b)
         return entities[a].position.y < entities[b].position.y
      end
   )
   return result
end

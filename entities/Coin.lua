Coin = class("Coin", PhysicalEntity)

function Coin:initialize(x, y)
  PhysicalEntity.initialize(self, x, y, "static")
  self.layer = 8
  self.width = 3
  self.height = 3
  self.scale = 1
  self.map = Spritemap:new(assets.images.coin, self.width, self.height)
  self.map:add("spin", { 1, 2, 3, 4 }, 8, true)
  self.map:play("spin")
end

function Coin:added()
  self:setupBody()
  self.fixture = self:addShape(love.physics.newRectangleShape(self.width + 5, self.height + 5))
  self.fixture:setSensor(true)
  self.fixture:setMask(3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16) -- all but player
end

function Coin:update(dt)
  PhysicalEntity.update(self, dt)
  self.map:update(dt)
end

function Coin:draw()
  self:drawMap()
end

function Coin:collided(other, fixt, otherFixt, contact)
  if other:isInstanceOf(Player) then
    self.world:coinCollected()
    other:coinCollected(self.x, self.y)
    self:die()
  end
end

function Coin:die()
  self.dead = true
  self.world = nil
end

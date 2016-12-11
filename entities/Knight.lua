Knight = class("Knight", Enemy)
Knight.static.image = getRectImage(8, 9, 200, 200, 200)
Knight.static.width = 6
Knight.static.height = 10

function Knight:initialize(x, y)
  Enemy.initialize(self, x, y)
  self.width = Knight.width
  self.height = Knight.height
  self.map = Spritemap:new(assets.images.knight, 26, 10)
  self.map:add("move", { 1, 2, 3, 2, 1, 4, 5, 4 }, 20, true)
  self.map:add("attack", { 1, 1, 4, 4, 5, 5, 4, 1, 2, 3, 2, 1 }, 60, false)
  self.map:add("death", { 1, 5, 6, 7, 8, 9, 10, 11 }, 45, false)
  self.attackRange = 10
  self.attackTime = 0.8
  self.damage = 5
end

function Knight:update(dt)
  if self.slowdownTimer > 0 then
    self.map.animations.move.time = 1 / 13
  else
    self.map.animations.move.time = 1 / 20
  end

  Enemy.update(self, dt)
end

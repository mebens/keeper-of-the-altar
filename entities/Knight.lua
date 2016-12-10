Knight = class("Knight", Enemy)
Knight.static.image = getRectImage(8, 9, 200, 200, 200)
Knight.static.width = 8
Knight.static.height = 8

function Knight:initialize(x, y)
  Enemy.initialize(self, x, y)
  self.image = Knight.image
  self.width = Knight.width
  self.height = Knight.height
end
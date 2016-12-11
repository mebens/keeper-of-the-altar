FallZone = class("FallZone", PhysicalEntity)

function FallZone:initialize(xml)
  PhysicalEntity.initialize(self, 0, 0, "static")
  self.xml = xml
end

function FallZone:added()
  self:setupBody()
  self:loadFromXML()
end

function FallZone:loadFromXML()
  local elem = findChild(self.xml, "FallZone")

  for _, v in ipairs(findChildren(elem, "rect")) do
    local w, h = tonumber(v.attr.w) * 3, tonumber(v.attr.h) * 3
    local fixt = self:addShape(love.physics.newRectangleShape(tonumber(v.attr.x) * 3 + w / 2, tonumber(v.attr.y) * 3 + h / 2, w, h))
    fixt:setSensor(true)
  end
end

function FallZone:collided(other)
  if other:isInstanceOf(Player) or other:isInstanceOf(Enemy) then
    other:fall()
  end
end

require("lib.ammo")
require("lib.ammo.modules")
require("lib.gfx")

slaxml = require("slaxdom")
require("utils.xml")
require("utils.misc")

require("entities.Player")
require("entities.Laser")
require("entities.Altar")
require("entities.Enemy")
require("entities.Knight")
require("entities.Spawner")
require("entities.Bullet")
require("entities.Rocket")
require("entities.SeekerRocket")
require("entities.Coin")
require("entities.Walls")
require("entities.Floor")
require("entities.Lighting")
require("entities.HUD")
require("worlds.Room")

require("modules.noise")
require("modules.bloom")

TILE_SIZE = 9

function love.load()
  local cursor = love.mouse.newCursor("assets/images/crosshair.png", 7, 7)
  love.mouse.setCursor(cursor)

  assets.loadFont("square.ttf", { 48, 24, 18, 12, 8 }, "main")
  love.graphics.setDefaultFilter("nearest", "nearest")

  assets.loadShader("noise.frag")
  assets.loadShader("bloom.frag")
  assets.loadImage("tiles.png")
  assets.loadImage("demon-mg.png", "demonMg")
  assets.loadImage("coin.png")
  assets.loadImage("coin-hud.png", "coinHUD")
  assets.loadImage("altar.png")
  assets.loadImage("smoke.png")
  assets.loadImage("rocket.png")

  input.define("left", "a", "left")
  input.define("right", "d", "right")
  input.define("up", "w", "up")
  input.define("down", "s", "down")
  input.define{"attack", mouse = 1}
  input.define{"upgrade", mouse = 1}
  input.define{"repair", mouse = 2}

  input.define("wep1", "1")
  input.define("wep2", "2")
  input.define("wep3", "3")
  input.define("wep4", "4")
  input.define("wep5", "5")
  input.define{"prevweapon", wheel = "up"}
  input.define{"nextweapon", wheel = "down"}

  postfx.init()
  postfx.scale = 2
  postfx.add(bloom)
  postfx.add(noise)

  ammo.world = Room:new()
end

function love.update(dt)
  if not paused then
    ammo.update(dt)
    postfx.update(dt)
  end

  input.update(dt)
end

function love.draw()
  postfx.start()
  ammo.draw()
  postfx.stop()

  if DEBUG then
    love.graphics.setFont(assets.fonts.main[12])
    love.graphics.printf(DEBUG, 5, 5, love.graphics.width - 10, "right")
  end
end

function love.keypressed(key)
  input.keypressed(key)
  if key == "p" then paused = not paused end
  if key == "b" then bloom.active = not bloom.active end
end
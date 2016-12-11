require("lib.ammo")
require("lib.ammo.modules")
require("lib.gfx")

slaxml = require("slaxdom")
require("utils.xml")
require("utils.misc")

require("entities.Lighting")
require("entities.Player")
require("entities.Laser")
require("entities.Altar")
require("entities.Brazier")
require("entities.Fireball")
require("entities.Enemy")
require("entities.Knight")
require("entities.Spawner")
require("entities.Bullet")
require("entities.Rocket")
require("entities.SeekerRocket")
require("entities.Coin")
require("entities.Walls")
require("entities.Floor")
require("entities.FallZone")
require("entities.BloodSpurt")
require("entities.FloorBlood")
require("entities.CorpseLayer")
require("entities.HUD")
require("worlds.Menu")
require("worlds.Room")

require("modules.noise")

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
  assets.loadImage("demon-mg2.png", "demonMgDual")
  assets.loadImage("knight.png")
  assets.loadImage("coin.png")
  assets.loadImage("coin-hud.png", "coinHUD")
  assets.loadImage("altar.png")
  assets.loadImage("brazier.png")
  assets.loadImage("smoke.png")
  assets.loadImage("rocket.png")

  assets.loadSfx("altar-death.ogg")
  assets.loadSfx("coin.ogg")
  assets.loadSfx("coin2.ogg")
  assets.loadSfx("coin3.ogg")
  assets.loadSfx("explosion.ogg")
  assets.loadSfx("explosion2.ogg")
  assets.loadSfx("explosion3.ogg")
  assets.loadSfx("explosion4.ogg")
  assets.loadSfx("hit.ogg")
  assets.loadSfx("hit2.ogg")
  assets.loadSfx("hit3.ogg")
  assets.loadSfx("hit4.ogg")
  assets.loadSfx("hover.ogg")
  assets.loadSfx("hover2.ogg")
  assets.loadSfx("mg.ogg")
  assets.loadSfx("mg2.ogg")
  assets.loadSfx("mg3.ogg")
  assets.loadSfx("rpg.ogg")
  assets.loadSfx("rpg2.ogg")
  assets.loadSfx("seekrpg.ogg")
  assets.loadSfx("seekrpg2.ogg")
  assets.loadSfx("sg.ogg")
  assets.loadSfx("sg2.ogg")
  assets.loadSfx("sg3.ogg")
  assets.loadSfx("smg.ogg")
  assets.loadSfx("smg2.ogg")
  assets.loadSfx("smg3.ogg")
  assets.loadSfx("laser.ogg")
  assets.loadSfx("upgrade.ogg")
  assets.loadSfx("upgrade2.ogg")
  assets.loadSfx("upgrade-screen.ogg")
  assets.loadSfx("spawn.ogg")
  assets.loadSfx("bg.ogg")

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
  postfx.add(noise)

  ammo.world = Menu:new()
  BG_SOUND = assets.sfx.bg:loop()
  BG_SOUND:setVolume(0.85)
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
  if key == "l" then ammo.world:startWave(ammo.world.totalWaves - 1) end
  if key == "o" then ammo.world.coins = 1000 end
end
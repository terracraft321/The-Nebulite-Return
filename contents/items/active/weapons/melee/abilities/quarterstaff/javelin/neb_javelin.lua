require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

GiantBladeAttack = WeaponAbility:new()

function GiantBladeAttack:init()
  self.cooldownTimer = self.cooldownTime
  self:reset()
  self.weapon:setStance(self.stances.idle)
end

function GiantBladeAttack:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if self.fireMode == "alt" and self.weapon.currentState == nil and self.cooldownTimer == 0 and not status.resourceLocked("energy") and shiftHeld == false then
    self:setState(self.windup)
  end
end

function GiantBladeAttack:windup()
  self.weapon:setStance(self.stances.windup)
  self.weapon:updateAim()

  animator.setAnimationState("giantBlade", "charge")
  animator.setParticleEmitterActive(self.weapon.elementalType.."SwordCharge", true)
  animator.playSound(self.weapon.elementalType.."charge")
  
  local damageArea = partDamageArea("giantblade")
  self.weapon:setDamage(self.damageConfig, damageArea)

  local bladeState = "charge"
  local chargeTimer = self.chargeTime
  while self.fireMode == "alt" do
    -- manually update sounds so that we can use elemental variations
    local newState = animator.animationState("giantBlade")
    if newState ~= bladeState then
      if newState == "fullwindup" then
        animator.stopAllSounds(self.weapon.elementalType.."charge")
        animator.playSound(self.weapon.elementalType.."fullwindup")
        animator.setLightActive("glow", true)
      elseif newState == "full" then
        animator.playSound(self.weapon.elementalType.."full", -1)
      end
      bladeState = newState
    end

    chargeTimer = math.max(0, chargeTimer - self.dt)
    coroutine.yield()
  end

  if chargeTimer == 0 and status.overConsumeResource("energy", self.energyUsage) then
    self:setState(self.slash)
  end
end

function GiantBladeAttack:slash()
  self.weapon:setStance(self.stances.slash)
  self.weapon:updateAim()
  
  animator.setLightActive("glow", false)
  
  local position = vec2.add(mcontroller.position(), {self.projectileOffset[1] * mcontroller.facingDirection(), self.projectileOffset[2]})
  local params = {
    powerMultiplier = activeItem.ownerPowerMultiplier(),
    power = self:damageAmount()
  }
  
  world.spawnProjectile(self.projectileType, position, activeItem.ownerEntityId(), self:aimVector(), false, params)

  animator.setAnimationState("giantSwoosh", "slash")
  animator.playSound("fire")
  animator.stopAllSounds(self.weapon.elementalType.."full")
  animator.stopAllSounds(self.weapon.elementalType.."charge")
  animator.setAnimationState("giantBlade", "idle")

  self.cooldownTimer = self.cooldownTime
end

function GiantBladeAttack:reset()
  animator.setAnimationState("giantBlade", "idle")
  animator.setParticleEmitterActive(self.weapon.elementalType.."SwordCharge", false)
  animator.stopAllSounds(self.weapon.elementalType.."charge")
  animator.stopAllSounds(self.weapon.elementalType.."full")
  self.weapon:setStance(self.stances.idle)
  animator.setLightActive("glow", false)
end

function GiantBladeAttack:damageAmount()
  return self.damageConfig.baseDamage * config.getParameter("damageLevelMultiplier")
end

function GiantBladeAttack:aimVector()
  return {mcontroller.facingDirection(), 0.15}
end

function GiantBladeAttack:uninit()
  self:reset()
end

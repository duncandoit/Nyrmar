//
//  AttributesComponent.swift
//  Korin
//
//  Created by Zachary Duncan on 8/9/25.
//

import Foundation

/// This is a non-changeable set of the model stats that is unique for each character.
/// Values for each stat range from 30-150.
/// These are combined with EffortStats to increase the Hero Stats when the character levels up.
class BaseStatsComponent: Component
{
    static var typeID: ComponentTypeID = componentTypeID(for: BaseStatsComponent.self)
    var siblings: SiblingContainer?
    
    var moveSpeed: CGFloat = 100
    var moveSpeedMax: CGFloat?
}

/**
  Effort Stats:
  Each character is worth a number of Effort Points distributed in Health, Attack, Healing, Defense and Movement Speed.
  Gradually increase individual Effort Stats when certain types of enemies are killed. These are combined with Base Stats to increase the Hero Stats when the character levels up.
  EffortStat = floor(0.25 * EffortStatPoints)
  Values for each stat range from 0-200 with an overall limit of 400 for that character.
  When Effort Points are awarded they’re added to the progress of increasing your related Effort Stats. So if your Effort Stat for Attack is 1 you may need 10 more Attack Effort Points before you’ll ding that to 2 for Attack Effort Stat.

  Hero Stats:
  These are the “actual” stats of the character
  These stats are combined with equipment stats and status conditions to determine gameplay things like damage output, actual movement speed, healing received, etc
  Increase when character levels up by individual amounts based on Base Stats.

  Stat Model:
  Health, Attack, Healing Delt, Healing Received, Defense, Movement Speed, Spread, Fire Rate, Melee Knockback, Melee Damage, Projectile Speed, AbilityCooldown, Damage Falloff Start Distance, Damage Falloff End Distance

  Status Conditions:
  Model:
  Name, DamageAmount, HealingAmount, StatModifier, Time
  These are given to a character by other characters’ abilities and consumes.

  Experience Gain:
  EXP = floor((A x B x E x L) / (7 x P)) + 1
  Detail: The 1 at the end makes sure you always get at least 1 exp.
  A: 1 if enemy was less than or equal to your level, 1.5 if they were greater than your level
  B: The base experience yield of the enemy. Ranges: 10 for non combatants, 30-300 for regular enemies, 150-400 for elites, 300-600 for bosses
  E: 1 normally. 1.2 if an experience boosting consume has been used
  L: The level of the enemy
  P: The number of players who participated in the kill

  Level Up:
  Characters start at level 1 and have a max level of 50
  Calculate new Hero Stat Health
  = floor(0.1 x (Level + BaseStat + floor(0.25 x EffortStat))) * 25
  Calculate new other Hero Stat
  = floor(0.01 x (2 x (BaseStat + EquipmentStat + floor(0.25 x EffortStat))) x Level) + 5

  Raw Output:
  Main Weapon Damage Output Per Hit:
  floor(((2 x Level / 5 + 2) x HeroAttackStat / 50 + 2) x S x A x H)
  S: Status Conditions that either buff or nerf damage
  A: 0.5 if you’re damaging an enemy’s armor. 1 otherwise
  H: 2 if hit was a headshot. 1 otherwise
  I called it a DamageMultiplier at the end because it’s multiplying the full damage output rather than buffing or nerfing the attack stats

  Melee Attacks:
  Quick melee does x damage, is active for 0.5 seconds, and has a range of 2.5 meters, and has a cooldown of 1 second, and affects all enemies in range.

  Main Weapon Fire Rate:
  Possible?: ((Level / 5) * HeroFireRateStat / 100)
  Or, the fire-rate doesn’t change. I think I like that idea better. Players get more used to specific weapon handling

  Movement Speed:
  Most Overwatch heroes move at 5.5 m/s. Genji and Tracer move at 6 m/s.
  Moving backwards moves at 90% normal speed. Diagonally backwards is 93.33% normal speed.
  Crouching moves at 3 m/s regardless of direction.
**/

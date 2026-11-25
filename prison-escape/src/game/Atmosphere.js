import * as THREE from 'three';
import { LAYOUT } from './Prison.js';

/** Where the player actually stands — intake compound, walking cage, cell, or hall. */
export function placeOf(pos) {
  if (pos.z < -53) return 'intake';
  if (pos.z < -2.2) return 'proc';
  if (pos.z > LAYOUT.corridorLen - 0.6) return 'yard';
  if (pos.x > 1.55) return 'cell';
  return 'hall';
}

function phaseId(sim) {
  if (sim.stage === 'life') return sim.phase?.id || 'wake';
  if (sim.stage === 'shmon') return 'shmon';
  return sim.stage || 'kpp';
}

/** Rain on even days and on the last walk — grey Ukrainian November, not a weather gag. */
export function isRainDay(sim) {
  const day = sim.day | 0;
  const ph = phaseId(sim);
  if (day === 2 || day === 4 || day === 6) return true;
  if (day === 7 && ph === 'walk') return true;
  if (ph === 'walk' && day % 2 === 0) return true;
  return false;
}

/**
 * Palette the player can tell apart without reading HUD.
 * wake = cold tube, food = kettle amber, shmon = harsh white,
 * walk = open overcast / rain, evening = sodium + window blue.
 */
export function moodFor(sim, place) {
  const day = Math.max(1, sim.day | 0);
  const ph = phaseId(sim);
  const rain = isRainDay(sim);
  const late = day >= 6;
  const dirty = day >= 4;

  const base = {
    rain,
    sky: 0x9aadb8,
    fog: 0x9aadb8,
    fogNear: 18,
    fogFar: 90,
    bg: 0x9aadb8,
    hemiSky: 0xd8e4ee,
    hemiGround: 0x6a6050,
    hemi: 0.85,
    sun: 0xfff1d6,
    sunI: 0.15,
    fill: 0.2,
    fillColor: 0xffe6c0,
    exposure: 1.05,
    cellLamp: 0.7,
    windowFill: 0.45,
    windowTint: 0xc8d4de,
    yardSun: 1.2,
    yardSky: 0x8aa6b8,
    bloom: 0.22,
  };

  if (place === 'intake') {
    Object.assign(base, {
      rain: true,
      fogNear: 28,
      fogFar: 110,
      sunI: 0.42,
      hemi: 0.62,
      exposure: 0.88,
      fill: 0.04,
      sky: 0x5a6874,
      bg: 0x5a6874,
      fog: 0x5a6874,
      hemiSky: 0x9aa8b4,
      hemiGround: 0x3a3c38,
    });
    return base;
  }

  if (place === 'proc') {
    Object.assign(base, {
      fog: 0x1a2220,
      fogNear: 4,
      fogFar: 16,
      bg: 0x101614,
      hemiSky: 0xe8fcf6,
      hemiGround: 0x2a3a38,
      hemi: 0.62,
      sun: 0xf0fff8,
      sunI: 0.18,
      fill: 0.48,
      fillColor: 0xe8f8f2,
      exposure: 1.38,
      bloom: 0.48,
      env: 0.34,
      hall: 1.05,
      proc: 1.45,
      hallColor: 0xf2fff8,
    });
    return base;
  }

  if (place === 'yard') {
    if (ph === 'evening') {
      Object.assign(base, {
        rain: false,
        sky: 0x2a2438,
        fog: 0x2a2430,
        fogNear: 6,
        fogFar: 22,
        bg: 0x1c1824,
        hemiSky: 0x6a6088,
        hemiGround: 0x3a2a20,
        hemi: 0.35,
        sun: 0xff8a3a,
        sunI: 0.08,
        fill: 0.18,
        fillColor: 0xffaa55,
        exposure: 0.72,
        yardSun: 0.35,
        yardSky: 0x3a3550,
        bloom: 0.4,
      });
    } else if (rain) {
      Object.assign(base, {
        sky: 0x5a6570,
        fog: 0x5a6570,
        fogNear: 4,
        fogFar: 16,
        bg: 0x4a555e,
        hemiSky: 0x9aa8b4,
        hemiGround: 0x3a3c38,
        hemi: 0.55,
        sun: 0xc8d0d8,
        sunI: 0.22,
        fill: 0.12,
        fillColor: 0xb8c4cc,
        exposure: 0.88,
        yardSun: 0.55,
        yardSky: 0x6a7884,
        bloom: 0.12,
      });
    } else {
      Object.assign(base, {
        sky: late ? 0x8a9aa8 : 0xb8c6d0,
        fog: late ? 0x7a8a96 : 0xa8b8c4,
        fogNear: 8,
        fogFar: 28,
        bg: late ? 0x7a8a96 : 0xb0c0cc,
        hemiSky: 0xe8eef4,
        hemiGround: 0x6a6458,
        hemi: 0.95,
        sun: 0xffe8c8,
        sunI: 0.55,
        fill: 0.08,
        fillColor: 0xffe0b0,
        exposure: 1.22,
        yardSun: 1.45,
        yardSky: late ? 0x8a9aaa : 0xc4d4e0,
        bloom: 0.18,
      });
    }
    return base;
  }

  if (place === 'cell') {
    if (ph === 'evening') {
      Object.assign(base, {
        fog: 0x120e0c,
        fogNear: 3,
        fogFar: 11,
        bg: 0x080604,
        hemiSky: 0x3a2a1c,
        hemiGround: 0x120c0a,
        hemi: 0.1,
        sunI: 0.01,
        fill: 0.05,
        fillColor: 0xffaa44,
        exposure: 0.46,
        cellLamp: 0.42,
        windowFill: 0.48,
        windowTint: 0x2a4068,
        bloom: 0.62,
        env: 0.05,
      });
    } else if (ph === 'shmon') {
      Object.assign(base, {
        fog: 0x1a1814,
        fogNear: 6,
        fogFar: 18,
        bg: 0x141210,
        hemiSky: 0xe8e4d8,
        hemiGround: 0x4a4038,
        hemi: 0.55,
        sunI: 0.04,
        fill: 0.35,
        fillColor: 0xf4f0e4,
        exposure: 1.28,
        cellLamp: 1.15,
        windowFill: 0.2,
        windowTint: 0xc8d0d8,
        bloom: 0.3,
      });
    } else if (ph === 'food') {
      Object.assign(base, {
        fog: 0x1c140c,
        fogNear: 5,
        fogFar: 15,
        bg: 0x18120c,
        hemiSky: 0xf4d8a4,
        hemiGround: 0x4a3018,
        hemi: 0.42,
        fill: 0.55,
        fillColor: 0xffc878,
        exposure: 1.14,
        cellLamp: 1.28,
        windowFill: 0.38,
        windowTint: 0xf0c888,
        bloom: 0.4,
        env: 0.22,
      });
    } else {
      Object.assign(base, {
        fog: dirty ? 0x141210 : 0x161410,
        fogNear: 7,
        fogFar: 20,
        bg: 0x121110,
        hemiSky: 0xc4b8a8,
        hemiGround: 0x3a342c,
        hemi: 0.32,
        sunI: 0.06,
        fill: 0.22,
        fillColor: 0xffe6c0,
        exposure: 1.08,
        cellLamp: 0.7,
        windowFill: 0.55,
        windowTint: 0xb8cce0,
        bloom: 0.24,
      });
    }
    return base;
  }

  // cell-block corridor
  if (ph === 'evening') {
    Object.assign(base, {
      fog: 0x100c0a,
      fogNear: 3,
      fogFar: 12,
      bg: 0x0a0806,
      hemi: 0.16,
      sunI: 0.02,
      fill: 0.1,
      fillColor: 0xff9944,
      exposure: 0.58,
      bloom: 0.5,
      hall: 0.55,
      hallColor: 0xff9944,
    });
  } else {
    Object.assign(base, {
      fog: 0x161410,
      fogNear: 8,
      fogFar: 28,
      bg: 0x141210,
      hemiSky: 0xc4b8a8,
      hemiGround: 0x3a342c,
      hemi: 0.38,
      sunI: 0.08,
      fill: 0.2,
      exposure: 1.0,
      bloom: 0.2,
      hall: 0.45,
      hallColor: 0xf2ead0,
    });
  }
  return base;
}

export function applyMood(game, mood, place) {
  const { scene, renderer, hemi, sun, fill, prison } = game;
  renderer.toneMappingExposure = mood.exposure;
  if (scene.fog) {
    scene.fog.near = mood.fogNear;
    scene.fog.far = mood.fogFar;
    scene.fog.color.setHex(mood.fog);
  }
  scene.background.setHex(mood.bg);
  hemi.color.setHex(mood.hemiSky);
  hemi.groundColor.setHex(mood.hemiGround);
  hemi.intensity = mood.hemi;
  sun.color.setHex(mood.sun);
  sun.intensity = mood.sunI;
  fill.intensity = mood.fill;
  fill.color.setHex(mood.fillColor);
  if ('environmentIntensity' in scene) scene.environmentIntensity = mood.env ?? 0.2;

  const ph = phaseId(game.sim);
  const night = place === 'cell' && ph === 'evening';
  if (prison.cellLamp) {
    prison.cellLamp.intensity = mood.cellLamp;
    prison.cellLamp.color.setHex(night ? 0xff9944 : ph === 'food' ? 0xffc070 : 0xffd7a0);
  }
  if (prison.foodLamp) {
    prison.foodLamp.intensity = place === 'cell' && ph === 'food' ? 0.9 : 0;
  }
  if (prison.foodSet) prison.foodSet.visible = place === 'cell' && ph === 'food';
  if (prison.cellSodium) {
    prison.cellSodium.intensity = night ? 1.15 : 0.04;
    prison.cellSodium.color.setHex(0xff8a33);
  }
  if (prison.cellSodiumTube) prison.cellSodiumTube.visible = night;
  if (prison.windowFills) {
    for (const l of prison.windowFills) {
      l.intensity = mood.windowFill;
      l.color.setHex(mood.windowTint);
    }
  }
  if (prison.windowGlass) {
    for (const m of prison.windowGlass) m.color.setHex(mood.windowTint);
  }
  if (prison.yardSun) prison.yardSun.intensity = mood.yardSun;
  if (prison.yardDoorLamp) {
    prison.yardDoorLamp.intensity = place === 'yard' ? (mood.rain ? 0.45 : 0.9) : 0.4;
    prison.yardDoorLamp.color.setHex(place === 'yard' && phaseId(game.sim) === 'evening' ? 0xffaa55 : 0xf0ead0);
  }
  if (prison.yardSky) prison.yardSky.material.color.setHex(mood.yardSky);
  if (prison.yardHemis) prison.yardHemis.material.color.setHex(mood.sky);
  if (prison.rain) prison.rain.visible = place === 'intake';
  if (prison.yardRain) prison.yardRain.visible = mood.rain && place === 'yard';
  if (prison.yardWet) {
    prison.yardWet.material.opacity = mood.rain && place === 'yard' ? 0.58 : 0.32;
    prison.yardWet.material.metalness = mood.rain && place === 'yard' ? 0.52 : 0.28;
    prison.yardWet.material.color.setHex(mood.rain ? 0x2a3230 : 0x3a423c);
  }
  if (prison.hallLights) {
    for (const l of prison.hallLights) {
      l.intensity = mood.hall ?? 0.4;
      l.color.setHex(mood.hallColor ?? 0xf2ead0);
    }
  }
  if (prison.procLights) {
    for (const l of prison.procLights) {
      l.intensity = mood.proc ?? (place === 'proc' ? 1.0 : 0.22);
      l.color.setHex(mood.hallColor ?? 0xe8f4f2);
    }
  }
  if (prison.windowShafts) {
    const on = place === 'cell' && phaseId(game.sim) !== 'shmon';
    for (const s of prison.windowShafts) {
      s.visible = on;
      s.material.opacity = phaseId(game.sim) === 'evening' ? 0.08 : 0.16;
      s.material.color.setHex(mood.windowTint);
    }
  }
  if (game.bloomPass) game.bloomPass.strength = game.lowEnd ? 0 : mood.bloom;
}

export function weatherLabel(sim, place) {
  const rain = isRainDay(sim);
  const ph = phaseId(sim);
  if (place === 'yard') {
    if (ph === 'evening') return 'Дворик · сумерки';
    if (rain) return 'Дворик · дождь';
    return 'Дворик · пасмурно';
  }
  if (place === 'cell') {
    if (ph === 'evening') return 'Хата · отбой';
    if (ph === 'shmon') return 'Хата · шмон';
    if (ph === 'food') return 'Хата · баландежка';
    return 'Хата · холодный свет';
  }
  if (place === 'intake') return 'КПП · дождь';
  if (place === 'proc') return ph === 'shmon' || sim.stage === 'shmon' ? 'Сборник · шмон' : 'Сборник · лампа';
  return ph === 'evening' ? 'Коридор · натрий' : 'Коридор';
}

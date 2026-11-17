import './style.css';
import { Game } from './game/Game.js';

const canvas = document.getElementById('game');
const boot = document.getElementById('boot');
const startBtn = document.getElementById('btn-start');

let game = null;
let starting = false;

async function begin() {
  if (starting) return;
  starting = true;
  startBtn.textContent = 'Загрузка…';
  game = new Game(canvas);
  await game.start();
  boot.classList.add('hidden');
}

startBtn.addEventListener('click', begin);
startBtn.addEventListener('pointerup', (e) => {
  e.preventDefault();
  begin();
});

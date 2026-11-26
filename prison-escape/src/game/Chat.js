/** Nearby talk + same-origin BroadcastChannel so two tabs can speak. */

const LINES = {
  starosta: [
    'Чай будешь — к столу. Не к чужой койке.',
    'Администрации — ни слова. Тут так живут.',
    'Новичок молчит первую неделю. Умно.',
    'Цигарка в общак — и ты не пустое место.',
    'Окно не сцена. Вышка не шутит.',
  ],
  cellmate: [
    'Баланда сегодня как вода. Грев бы.',
    'На прогулке не пялься на чужие хаты.',
    'После второго обхода кормушка живая. Не благодари вслух.',
    'Чифир: чай в кружку, ждать пока встанет. С пола не пей.',
  ],
  'bunk-bro': [
    'Карты вечером, если цигарка есть.',
    'Свистеть можно. Орать — нельзя.',
    'Нижняя у окна — твоя. Мою не занимай, даже присесть.',
  ],
  convoy: ['Быстрее, зэк. Не топчись.', 'Голову ниже. Коряк не музей.'],
  hatch: ['Э, новенький! Передай чайку, если будет.', 'Хату четыре видели? Смотрящий строгий.'],
  default: [
    'Не спрашивай «за что» — сам скажет, если надо.',
    'Тряпку на пороге не пинай. Это прописка.',
    'Общак — общий чай. Не свой карман.',
  ],
};

export class Chat {
  constructor() {
    this.root = document.getElementById('chat');
    this.log = document.getElementById('chat-log');
    this.form = document.getElementById('chat-form');
    this.input = document.getElementById('chat-in');
    this.open = false;
    this.nick = localStorage.getItem('hatka-nick') || `зэк-${Math.random().toString(36).slice(2, 6)}`;
    localStorage.setItem('hatka-nick', this.nick);
    this.channel = typeof BroadcastChannel !== 'undefined' ? new BroadcastChannel('hatka-sizo') : null;
    this.channel?.addEventListener('message', (ev) => {
      const m = ev.data || {};
      if (!m.text || m.nick === this.nick) return;
      this.push(m.nick, m.text, 'peer');
    });
    this.form?.addEventListener('submit', (e) => {
      e.preventDefault();
      this.send();
    });
    document.getElementById('btn-chat-close')?.addEventListener('pointerdown', (e) => {
      e.stopPropagation();
      this.hide();
    });
  }

  show() {
    this.open = true;
    this.root.classList.remove('hidden');
    this.root.classList.add('flex');
    setTimeout(() => this.input?.focus(), 30);
  }

  hide() {
    this.open = false;
    this.root.classList.add('hidden');
    this.root.classList.remove('flex');
  }

  toggle() {
    if (this.open) this.hide();
    else this.show();
  }

  send(whoNear) {
    const text = (this.input?.value || '').trim();
    if (!text) return;
    this.input.value = '';
    this.push(this.nick, text, 'me');
    this.channel?.postMessage({ nick: this.nick, text, t: Date.now() });
    const who = whoNear || this.whoNear || 'default';
    const pool = LINES[who] || LINES.default;
    const reply = pool[Math.floor(Math.random() * pool.length)];
    setTimeout(() => this.push(label(who), reply, 'npc'), 400 + Math.random() * 500);
  }

  push(who, text, kind) {
    if (!this.log) return;
    const row = document.createElement('p');
    row.className = `chat-row chat-${kind}`;
    row.innerHTML = `<b></b> <span></span>`;
    row.querySelector('b').textContent = who;
    row.querySelector('span').textContent = text;
    this.log.appendChild(row);
    this.log.scrollTop = this.log.scrollHeight;
  }
}

function label(id) {
  return (
    { starosta: 'Седой', cellmate: 'Лёха', convoy: 'Конвой', hatch: 'Соседняя хата', default: 'Хатка' }[id] || 'Хатка'
  );
}

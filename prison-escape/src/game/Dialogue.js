/**
 * Overlay dialogue battles. Choices shift black / red / men scores.
 */
export class Dialogue {
  constructor() {
    this.root = document.getElementById('dialog');
    this.who = document.getElementById('dialog-who');
    this.text = document.getElementById('dialog-text');
    this.choices = document.getElementById('dialog-choices');
    this.onPick = null;
    this.open = false;
  }

  show(who, text, options) {
    this.open = true;
    this.root.classList.remove('hidden');
    this.root.classList.add('flex');
    this.who.textContent = who;
    this.text.textContent = text;
    this.choices.innerHTML = '';
    for (const opt of options) {
      const b = document.createElement('button');
      b.type = 'button';
      b.className =
        'min-h-[48px] w-full rounded-lg border border-zinc-600 bg-black/70 px-3 py-2 text-left text-[16px] text-zinc-100 active:bg-amber-800/40';
      b.textContent = opt.label;
      b.addEventListener('pointerdown', (e) => {
        e.preventDefault();
        e.stopPropagation();
        this.hide();
        this.onPick?.(opt);
      });
      this.choices.appendChild(b);
    }
  }

  hide() {
    this.open = false;
    this.root.classList.add('hidden');
    this.root.classList.remove('flex');
  }
}

export const STAROSTA_INTRO = {
  who: 'Смотрящий',
  text: 'Новенький. Кто такой, за что сел, с кем по пути шёл? Коротко. И не выёживайся.',
  options: [
    {
      label: 'По понятиям живу. Администрации ничего.',
      black: 2,
      red: 0,
      men: 0,
      reply: 'Ну ладно. Общак уважаем — и тебя заметят.',
    },
    {
      label: 'Мне бы к куму, хочу по-человечески устроиться.',
      black: 0,
      red: 2,
      men: 0,
      reply: 'Красный? Хатка запомнит. Дальше сам.',
    },
    {
      label: 'Моя хата с краю. Не мешайте — не мешаю.',
      black: 0,
      red: 0,
      men: 2,
      reply: 'Мужик. Сиди тихо, койку не занимай чужую.',
    },
  ],
};

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
    document.exitPointerLock?.();
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

export const KPP_DOCS = {
  who: 'Дежурный · КПП',
  text: 'Постановление с суда есть. Лицо сверяем с бумагой, не с тобой. Имя, год, статья. Права — после шмона, не сейчас. Это статут СИЗО, не хата. Собака сзади слышит, как ты дышишь.',
  options: [
    { label: 'Кивнуть. Ладони на прилавок, взгляд в стол.', black: 0, red: 0, men: 1, reply: 'Принято. Ворота. Вещи на стол — шнурки, ремень, телефон. Живым останешься, если не бежишь.' },
    { label: '«Когда адвокат. У меня дети.»', black: 0, red: 1, men: 0, reply: 'После санобработки. Сейчас ты груз. Рот на замок.' },
  ],
};

export const GREETING = {
  who: 'Хатка',
  text: 'Замок. Воздух чужой: чай, известь, ноги. На пороге тряпка, будто забыли. Не забыли. Первое слово здесь стоит дороже пайки.',
  options: [
    { label: 'Мир в хату', black: 1, red: 0, men: 1, reply: 'Седой чуть кивнул. Не пацан и не стукач с порога.' },
    { label: 'Привет, мужики! Ну как вы тут?', black: 0, red: 1, men: 0, reply: 'Тишина, какая бывает перед ударом. Так не здороваются.' },
    { label: 'Молча встать. Руки видно.', black: 0, red: 0, men: 1, reply: 'Молчание лучше лишнего слова. Пока.' },
  ],
};

export const ARTICLE_Q = {
  who: 'Седой · смотрящий',
  text: 'Кто такой. Статья. Первый раз или нет. С кем по этапу шёл — коротко, без кино. Я не мент и не батя. Я смотрю, чтобы хата не сдохла от глупости.',
  options: [
    { label: 'Первый раз. Бытовка. Администрации — ничего.', black: 1, red: 0, men: 2, reply: 'Мужик. Нижняя у окна — твоя. Чужую не занимай, в парашу пока едят — не ходи.' },
    { label: 'По понятиям живу. Общак уважаю.', black: 2, red: 0, men: 0, reply: 'Слышим. Язык дешёвый. Покажи делом, когда попросят чай или маляву.' },
    { label: 'Хочу к куму. Мне бы по-человечески, без этого.', black: 0, red: 2, men: 0, reply: 'Красный заход. Хата не ударит сразу. Хата запомнит.' },
  ],
};

export const TEA_Q = {
  who: 'Лёха',
  text: 'Чай вскипел. Кружка на полу — не чай, проверка: поднимешь — ты тряпка. Со стола сам не бери. Нальют — пей. Не нальют — сиди.',
  options: [
    { label: 'Подождать. Если нальют — выпью.', black: 1, red: 0, men: 1, reply: 'Сел, когда посадили. Правильно. Завтра научит, где прятать огрызок.' },
    { label: 'Взять с пола. Чего стесняться.', black: 0, red: 0, men: 0, reply: 'Седой отвернулся. С пола не пьют. Запомнили надолго.' },
    { label: 'Откажусь. Не курю и не пью.', black: 0, red: 0, men: 1, reply: 'Дело твоё. Только не корчи святого — святых сюда не возят.' },
  ],
};

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

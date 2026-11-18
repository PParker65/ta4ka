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
  who: 'ДПНСИ · сборник',
  text: 'Постановление суда есть. Личность сверяем. Права и обязанности потом под подпись. Это статут администрации, не хата. Дальше — полный обыск.',
  options: [
    { label: 'Молча кивнуть', black: 0, red: 0, men: 1, reply: 'Документы приняты. Вещи на стол.' },
    { label: 'Спросить, когда адвокат', black: 0, red: 1, men: 0, reply: 'Потом. Сейчас шмон. Говори коротко.' },
  ],
};

export const GREETING = {
  who: 'Хатка',
  text: 'Дверь захлопнулась. На пороге тряпка. Как зайдёшь — так и запомнят. Сначала рот.',
  options: [
    { label: 'Мир в хату', black: 1, red: 0, men: 1, reply: 'Нормально зашёл. Не пацан и не стукач с порога.' },
    { label: 'Привет, мужики!', black: 0, red: 1, men: 0, reply: 'Тишина. Так не здороваются. Уже минус.' },
    { label: 'Молча стоять', black: 0, red: 0, men: 1, reply: 'Молчание лучше лишнего слова.' },
  ],
};

export const ARTICLE_Q = {
  who: 'Седой · смотрящий',
  text: 'Кто такой, статья, первый раз? С кем по этапу шёл — коротко. И не выёживайся.',
  options: [
    { label: 'Первый раз. Бытовка. Администрации ничего.', black: 1, red: 0, men: 2, reply: 'Мужик. Койку укажем. Чужую не занимай.' },
    { label: 'По понятиям живу. Общак уважаю.', black: 2, red: 0, men: 0, reply: 'Слышим. Покажи делом, не языком.' },
    { label: 'Хочу к куму, чтобы по-человечески.', black: 0, red: 2, men: 0, reply: 'Красный заход. Хата запомнит.' },
  ],
};

export const TEA_Q = {
  who: 'Лёха',
  text: 'Чай будешь? С пола кружку не бери — это уже не чай, это проверка.',
  options: [
    { label: 'Выпью, если нальёте', black: 1, red: 0, men: 1, reply: 'Сел к столу, когда посадили. Правильно.' },
    { label: 'Сам возьму с пола, чего стесняться', black: 0, red: 0, men: 0, reply: 'Со стола не берут, с пола — тем более. Запомнили.' },
    { label: 'Откажусь, не курю и не пью', black: 0, red: 0, men: 1, reply: 'Дело твоё. Только не корчи из себя святого.' },
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

/**
 * Inner voice — the last private thing they didn't take at KPP.
 * Short, specific, never a tutorial dump.
 */
const BEATS = [
  { id: 'dark', when: (s, p, t) => t > 1 && t < 4, text: 'Мотор затих. Собака ближе, чем стены.' },
  { id: 'doors', when: (s, p, t) => t > 4.2 && t < 7, text: 'Катенька. Это уже не суд и не воля.' },
  { id: 'out', when: (s, p, t) => t > 7.2 && t < 11, text: 'Не смотри собаке в глаза. Смотри, куда ставить ногу.' },
  {
    id: 'puddle',
    when: (s, p, t) => t > 11 && !s.docs && p.z < -78,
    text: 'Лужа. Казёнка ещё не на тебе, но запах уже казённый.',
  },
  {
    id: 'dogs-close',
    when: (s, p) => !s.docs && p.z > -78 && p.z < -68,
    text: 'Овчарка тянет поводок. Не гладь. Не беги.',
  },
  {
    id: 'yard',
    when: (s, p) => !s.docs && p.z < -62 && p.z > -68,
    text: 'КПП справа от ворот. Бежать некуда: за спиной забор, впереди статут.',
  },
  {
    id: 'fence',
    when: (s, p) => !s.docs && (p.x < -8 || p.x > 8 || p.z < -86),
    text: 'Забор не для красоты. Конвой смотрит, овчарка ждёт ошибку.',
  },
  {
    id: 'kpp-near',
    when: (s, p) => !s.docs && p.z > -62 && p.z < -53,
    text: 'Здесь ещё администрация. Понятия — потом, в хате.',
  },
  {
    id: 'shmon-hall',
    when: (s) => s.docs && s.pending.length,
    text: 'Жёлтая черта. Слева скамья — очередь. Шнурки, ремень, телефон. Пока это твоё — ты ещё с воли.',
  },
  {
    id: 'photo-room',
    when: (s, p) => s.docs && !s.pending.length && !s.photo && p.z > -32 && p.z < -24,
    text: 'Ростомер. Вспышка. После этого ты — номер в папке.',
  },
  {
    id: 'med-room',
    when: (s, p) => s.photo && !s.med && p.z > -26 && p.z < -18,
    text: 'Запах спирта. Фельдшер не лечит — отсекает заразных.',
  },
  {
    id: 'bath-room',
    when: (s, p) => s.med && !s.haircut && p.z > -18 && p.z < -12,
    text: 'Плитка и машинка. Вода холодная. Казёнка висит слева.',
  },
  {
    id: 'photo-wait',
    when: (s) => !s.photo && !s.pending.length,
    text: 'Сейчас снимут лицо. После этого ты — номер в папке.',
  },
  {
    id: 'bath-wait',
    when: (s) => s.med && !s.haircut,
    text: 'Машинка. Это не стрижка — это стирают, кем ты был.',
  },
  {
    id: 'kazenka',
    when: (s) => s.haircut && s.robe !== 'kazenka',
    text: 'Роба слева. Как наденешь — все видят одно и то же.',
  },
  {
    id: 'koryak',
    when: (s) => s.stage === 'escort',
    text: 'Коряк. Красный пол, зелёные двери, трубы над ухом. Свою четвёртую не пропусти.',
  },
  {
    id: 'propiska',
    when: (s) => s.stage === 'propiska' || (s.locked && !s.propiska),
    text: 'Первое слово дороже пайки. Тряпка на пороге — не мусор.',
  },
  {
    id: 'cell-alive',
    when: (s) => s.stage === 'life' && !s.task,
    text: 'Седой за столом. Лёха на шконке. Валера у окна. Хату не обходят — в неё входят.',
  },
  {
    id: 'cell-task',
    when: (s) => s.stage === 'life' && s.task && s.task.id !== 'live',
    text: 'Хатка дала дело. Сделай — запомнят. Проигнорируй — тоже запомнят.',
  },
  {
    id: 'life-food',
    when: (s) => s.stage === 'life' && s.phase.id === 'food',
    text: 'Очередь. Не лезь. В сортир, пока едят, не ходи — запомнят.',
  },
  {
    id: 'life-shmon',
    when: (s) => s.stage === 'life' && s.phase.id === 'shmon',
    text: 'Стой. Руки видно. Нычку не проверяй при них.',
  },
  {
    id: 'life-walk',
    when: (s) => s.stage === 'life' && s.phase.id === 'walk',
    text: 'Круг по бетону. Через стену не ори. Уши у всех. КПП — не твоя дверь.',
  },
  {
    id: 'locked-in',
    when: (s, p) => (s.stage === 'life' || s.stage === 'propiska') && s.phase.id !== 'walk' && p.x < 1.4 && p.z > 0.6,
    text: 'Коряк без команды — это уже побег. Мурчики не чай пьют.',
  },
  {
    id: 'hungry',
    when: (s) => s.stage === 'life' && s.hunger < 22,
    text: 'Голод делает из человека шум. Шум здесь стоит дорого.',
  },
  {
    id: 'stress',
    when: (s) => s.stress > 78,
    text: 'Сердце слишком громкое. Дыши. Не дай хате увидеть, что ты сырой.',
  },
  {
    id: 'hope',
    when: (s) => s.stage === 'life' && s.hope > 60,
    text: 'Надежда здесь — как малява: прячут. Но она есть.',
  },
  {
    id: 'nohope',
    when: (s) => s.stage === 'life' && s.hope < 14,
    text: 'Если погаснет и это — останется только распорядок. Так и сажают навсегда.',
  },
  {
    id: 'night-stash',
    when: (s) => s.stage === 'life' && s.seenNight1 && s.stash === 'bunk' && s.day === 1,
    text: 'Матрас помнит руки. Завтра чужие руки будут первыми.',
  },
  {
    id: 'malyava-hold',
    when: (s) => s.malyava === 'hold',
    text: 'Бумага жжёт бедро. Не чеши. Не читай вслух.',
  },
  {
    id: 'snitch',
    when: (s) => s.malyava === 'admin' || s.path === 'red',
    text: 'Чайник щелкает громче, чем слова. Хата уже не смотрит — считает.',
  },
  {
    id: 'day4-debt',
    when: (s) => s.stage === 'life' && s.day === 4,
    text: 'Кормушка помнит чай. Долг здесь не про расписку.',
  },
  {
    id: 'day5-sled',
    when: (s) => s.stage === 'life' && s.day >= 5,
    text: 'Следователь — не хата. Хата спросит раньше, чем он.',
  },
];

export function storyLine(sim, pos, introT) {
  for (let i = BEATS.length - 1; i >= 0; i--) {
    const b = BEATS[i];
    if (b.when(sim, pos, introT)) return b;
  }
  return null;
}

export function wayFor(sim, prison) {
  const find = (type) => prison.interactables.find((it) => it.type === type);
  if (!sim.docs) return pack(find('kpp'), 'КПП', 'Документы. Справа от ворот.');
  if (sim.pending.length) return pack(find('shmon'), 'Шмон', 'Сдай вещи на опись.');
  if (!sim.photo) return pack(find('photo'), 'Фото', 'Анфас, пальцы, номер.');
  if (!sim.med) return pack(find('med'), 'Медчасть', 'Фельдшер.');
  if (!sim.haircut) return pack(find('bath'), 'Баня', 'Стрижка под машинку.');
  if (sim.robe !== 'kazenka') return pack(find('robe'), 'Казёнка', 'Роба и тапочки.');
  if (sim.stage === 'escort') return pack(find('cell-door'), 'Хата 4', 'За конвоем, через дверь.');
  if (!sim.propiska) return pack(find('rag'), 'Прописка', 'Тряпка. Рот. Не шарься.');
  if (sim.phase.id === 'food') return pack(find('food'), 'Баландежка', 'Пайка. Без очереди не лезь.');
  if (sim.phase.id === 'walk') return pack(find('exit'), 'Прогулка', 'Дворик. Круг. Тихо.');
  if (sim.phase.id === 'shmon') return pack(find('bunk'), 'Шконка', 'Стой у своей. Чужую не трогай.');
  if (sim.phase.id === 'evening') return pack(find('bunk'), 'Отбой', 'Своя койка.');
  return pack(find('starosta'), 'Хатка', 'Живи. Слушай. Не выёживайся.');
}

function pack(it, name, hint) {
  const p = it?.position || { x: 3.4, z: -56.2 };
  return { x: p.x, z: p.z, name, hint };
}

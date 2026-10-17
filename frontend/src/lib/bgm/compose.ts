// 作業用 BGM の作曲。設定とシード値から、コード進行・メロディ・伴奏・ドラムを
// すべてアルゴリズムで組み立てる（既存曲・サンプル音源は使わない）。
// 同じ設定とシード値からは必ず同じ曲ができる。

import { createRng, hashString, type Rng } from "./random";
import {
  chordDegrees,
  chordName,
  degreeToMidi,
  foldInto,
  isDiminished,
  MODE_LABELS,
  mod,
  noteName,
  type Mode,
} from "./theory";

export type MoodId = "lofi" | "ambient" | "cafe" | "upbeat";
export type InstrumentId = "kick" | "snare" | "hat" | "bass" | "keys" | "pad" | "lead" | "arp" | "bell";
export type SectionKind = "intro" | "A" | "B" | "outro";
type LeadRhythm = "groove" | "slow" | "bright";

export type MoodPreset = {
  readonly id: MoodId;
  readonly label: string;
  readonly description: string;
  readonly bpm: { readonly min: number; readonly max: number; readonly default: number };
  readonly modes: readonly Mode[];
  readonly swing: number; // 0〜1。1 で 3 連符のハネ
  readonly humanize: number; // 発音タイミングの揺れ（秒）
  readonly chordSize: 3 | 4;
  readonly barsPerChord: 1 | 2;
  readonly leadRhythm: LeadRhythm;
  readonly layers: Readonly<Record<SectionKind, readonly InstrumentId[]>>;
  readonly texture: "vinyl" | "air" | null;
  readonly warmth: number; // マスターのローパス周波数（Hz）
  readonly reverbSeconds: number;
  readonly titleWords: readonly [readonly string[], readonly string[]];
};

export const MOODS: Readonly<Record<MoodId, MoodPreset>> = {
  lofi: {
    id: "lofi",
    label: "Lo-fi 集中",
    description: "ゆったりハネるビートとエレピ。勉強・コーディング向け",
    bpm: { min: 66, max: 92, default: 78 },
    modes: ["dorian", "minor", "major"],
    swing: 0.55,
    humanize: 0.012,
    chordSize: 4,
    barsPerChord: 1,
    leadRhythm: "groove",
    layers: {
      intro: ["keys", "hat"],
      A: ["keys", "kick", "snare", "hat", "bass"],
      B: ["keys", "kick", "snare", "hat", "bass", "lead", "pad"],
      outro: ["keys", "hat", "pad"],
    },
    texture: "vinyl",
    warmth: 8500,
    reverbSeconds: 2.2,
    titleWords: [
      ["Late", "Quiet", "Rainy", "Paper", "Sleepy", "Soft", "Midnight", "Dusty"],
      ["Notebook", "Window", "Desk Lamp", "Tea", "Pencil", "Streetlight", "Library", "Corner"],
    ],
  },
  ambient: {
    id: "ambient",
    label: "アンビエント",
    description: "ドラムなしの広がるパッドとベル。深い集中・読書向け",
    bpm: { min: 54, max: 76, default: 64 },
    modes: ["lydian", "major", "dorian"],
    swing: 0,
    humanize: 0.02,
    chordSize: 4,
    barsPerChord: 2,
    leadRhythm: "slow",
    layers: {
      intro: ["pad"],
      A: ["pad", "bass", "bell"],
      B: ["pad", "bass", "bell", "lead"],
      outro: ["pad", "bell"],
    },
    texture: "air",
    warmth: 9000,
    reverbSeconds: 4.5,
    titleWords: [
      ["Distant", "Floating", "Pale", "Still", "Endless", "Morning", "Glass", "Silver"],
      ["Horizon", "Tide", "Cloud", "Field", "Aurora", "Lake", "Snowfall", "Orbit"],
    ],
  },
  cafe: {
    id: "cafe",
    label: "カフェジャズ",
    description: "ウォーキングベースとスウィング。作業の合間や雑務向け",
    bpm: { min: 86, max: 116, default: 98 },
    modes: ["major", "dorian"],
    swing: 0.65,
    humanize: 0.01,
    chordSize: 4,
    barsPerChord: 1,
    leadRhythm: "groove",
    layers: {
      intro: ["keys", "bass"],
      A: ["keys", "bass", "hat", "kick", "snare"],
      B: ["keys", "bass", "hat", "kick", "snare", "lead"],
      outro: ["keys", "bass", "hat"],
    },
    texture: null,
    warmth: 9000,
    reverbSeconds: 1.8,
    titleWords: [
      ["Corner", "Velvet", "Sunday", "Little", "Golden", "Warm", "Crescent", "Amber"],
      ["Cafe", "Espresso", "Avenue", "Bookshop", "Terrace", "Waltz", "Cup", "Bakery"],
    ],
  },
  upbeat: {
    id: "upbeat",
    label: "爽やかポップ",
    description: "軽快な4つ打ちとアルペジオ。単純作業や朝の始動向け",
    bpm: { min: 104, max: 128, default: 116 },
    modes: ["major", "lydian"],
    swing: 0,
    humanize: 0.004,
    chordSize: 3,
    barsPerChord: 1,
    leadRhythm: "bright",
    layers: {
      intro: ["pad", "arp"],
      A: ["pad", "arp", "kick", "hat", "bass"],
      B: ["pad", "arp", "kick", "snare", "hat", "bass", "lead"],
      outro: ["pad", "arp", "hat"],
    },
    texture: null,
    warmth: 14000,
    reverbSeconds: 2,
    titleWords: [
      ["Bright", "Blue", "Fresh", "Sunny", "Clear", "Open", "Lucky", "Spring"],
      ["Sky", "Breeze", "Station", "Bicycle", "Lemonade", "Runway", "Morning", "Signal"],
    ],
  },
};

export const MOOD_IDS = Object.keys(MOODS) as MoodId[];

export type SongSettings = {
  readonly mood: MoodId;
  readonly bpm: number;
  readonly key: number | null; // null はシード値から決める
  readonly minutes: number;
  readonly seed: number;
};

export type NoteEvent = {
  readonly inst: InstrumentId;
  readonly time: number;
  readonly dur: number;
  readonly midi: number;
  readonly vel: number;
};

export type Section = {
  readonly kind: SectionKind;
  readonly startBar: number;
  readonly bars: number;
};

export type Song = {
  readonly settings: SongSettings;
  readonly preset: MoodPreset;
  readonly title: string;
  readonly keyLabel: string;
  readonly bars: number;
  readonly barSeconds: number;
  readonly duration: number;
  readonly progressions: { readonly A: readonly string[]; readonly B: readonly string[] };
  readonly sections: readonly Section[];
  readonly events: readonly NoteEvent[];
};

export const SECTION_LABELS: Readonly<Record<SectionKind, string>> = {
  intro: "イントロ",
  A: "A",
  B: "B（メロディ）",
  outro: "アウトロ",
};

const STEPS_PER_BAR = 16;
const SECTION_BARS = 8;
const PROGRESSION_LENGTH = 4;

// 和音の度数ごとの、次に進みやすい和音と重み
const CHORD_MOVES: Readonly<Record<number, readonly (readonly [number, number])[]>> = {
  0: [[3, 3], [4, 2], [5, 3], [1, 2], [2, 1]],
  1: [[4, 4], [3, 1], [0, 1]],
  2: [[5, 3], [3, 2]],
  3: [[4, 3], [0, 2], [1, 2], [2, 1]],
  4: [[0, 4], [5, 2], [3, 1]],
  5: [[3, 3], [1, 3], [4, 2], [2, 1]],
  6: [[0, 3], [2, 1]],
};

// 1 拍（16 分音符 4 つ）ぶんのメロディのリズム。[開始位置, 長さ] を 16 分音符単位で書く
const LEAD_CELLS: Readonly<Record<LeadRhythm, readonly (readonly (readonly [number, number])[])[]>> = {
  groove: [[[0, 2], [2, 2]], [[0, 3]], [[2, 2]], [], [[0, 4]], [[0, 6]], [[0, 1], [2, 2]]],
  slow: [[[0, 8]], [[0, 12]], [[0, 4]], [], [[0, 6], [6, 2]]],
  bright: [[[0, 2], [2, 2]], [[0, 1], [1, 1], [2, 2]], [[0, 4]], [[2, 2]], [[0, 3], [3, 1]], []],
};

const ARP_PATTERNS = [
  [0, 1, 2, 3, 2, 1, 0, 1],
  [0, 2, 1, 3, 0, 2, 1, 3],
  [3, 2, 1, 0, 1, 2, 3, 2],
  [0, 1, 2, 1, 3, 2, 1, 2],
] as const;

type MotifNote = { readonly step: number; readonly len: number; readonly degree: number };

const clamp = (value: number, min: number, max: number) => Math.min(max, Math.max(min, value));

function makeProgression(r: Rng, tonic: number, mode: Mode, avoid: readonly number[] | null): number[] {
  const usable = (degree: number) => !isDiminished(tonic, mode, degree);
  let best: number[] = [0, 3, 4, 0];
  for (let attempt = 0; attempt < 50; attempt++) {
    const start = avoid ? r.weighted<number>([[3, 3], [5, 3], [1, 2], [0, 1]]) : r.weighted<number>([[0, 4], [5, 2], [3, 1]]);
    const progression = [start];
    while (progression.length < PROGRESSION_LENGTH) {
      const prev = progression[progression.length - 1];
      const moves = CHORD_MOVES[prev].filter(([d]) => usable(d) && d !== prev);
      if (moves.length === 0) break;
      progression.push(r.weighted(moves));
    }
    if (progression.length < PROGRESSION_LENGTH || !progression.every(usable)) continue;
    best = progression;
    // 4 つ目の和音から 1 つ目へ自然に戻れる進行を優先する（ループ再生のつなぎ目のため）
    const loops = CHORD_MOVES[progression[3]].some(([d]) => d === progression[0]);
    const differs = !avoid || progression.join() !== avoid.join();
    if (loops && differs) return progression;
  }
  return best;
}

function arrange(bars: number): Section[] {
  const count = bars / SECTION_BARS;
  let kinds: SectionKind[];
  if (count === 2) kinds = ["A", "B"];
  else if (count === 3) kinds = ["intro", "A", "B"];
  else {
    kinds = Array.from({ length: count }, (_, i): SectionKind => {
      if (i === 0) return "intro";
      if (i === count - 1) return "outro";
      return i % 2 === 1 ? "A" : "B";
    });
  }
  return kinds.map((kind, i) => ({ kind, startBar: i * SECTION_BARS, bars: SECTION_BARS }));
}

// 2 小節のメロディの核（モチーフ）。B セクションのたびに和音に合わせて変形して使う
function makeMotif(r: Rng, rhythm: LeadRhythm): MotifNote[] {
  const cells = LEAD_CELLS[rhythm];
  let notes: MotifNote[] = [];
  for (let attempt = 0; attempt < 20 && notes.length < 3; attempt++) {
    notes = [];
    let degree = r.pick([0, 2, 4]);
    let beat = 0;
    while (beat < 8) {
      const cell = r.pick(cells);
      let beats = 1;
      for (const [start, len] of cell) {
        notes.push({ step: beat * 4 + start, len, degree });
        const move = r.weighted<number>([[-2, 1], [-1, 3], [0, 1], [1, 3], [2, 1], [3, 0.4], [-3, 0.4]]);
        degree = clamp(degree + move, -3, 8);
        beats = Math.max(beats, Math.ceil((start + len) / 4));
      }
      beat += beats;
    }
    notes = notes.filter((n) => n.step < 32).map((n) => ({ ...n, len: Math.min(n.len, 32 - n.step) }));
  }
  return notes;
}

function snapToChord(degree: number, chordRoot: number, size: number): number {
  const tones = new Set(chordDegrees(chordRoot, size).map((d) => mod(d, 7)));
  for (const delta of [0, -1, 1, -2, 2]) {
    if (tones.has(mod(degree + delta, 7))) return degree + delta;
  }
  return degree;
}

function makeTitle(r: Rng, preset: MoodPreset): string {
  const [adjectives, nouns] = preset.titleWords;
  return `${r.pick(adjectives)} ${r.pick(nouns)}`;
}

export function barCount(bpm: number, minutes: number): number {
  const barSeconds = 240 / bpm;
  return Math.max(16, Math.round((minutes * 60) / barSeconds / SECTION_BARS) * SECTION_BARS);
}

export function composeSong(settings: SongSettings): Song {
  const preset = MOODS[settings.mood];
  const rngFor = (part: string) => createRng(settings.seed ^ hashString(`${settings.mood}:${part}`));
  const base = rngFor("base");

  const mode = base.pick(preset.modes);
  const key = settings.key ?? base.int(0, 11);
  const tonic = 60 + (key > 6 ? key - 12 : key);
  const bpm = clamp(Math.round(settings.bpm), 40, 180);
  const barSeconds = 240 / bpm;
  const stepSeconds = barSeconds / STEPS_PER_BAR;
  const bars = barCount(bpm, settings.minutes);
  const size = preset.chordSize;

  const progA = makeProgression(rngFor("progA"), tonic, mode, null);
  const progB = makeProgression(rngFor("progB"), tonic, mode, progA);
  const sections = arrange(bars);
  // B セクションごとに 2 つのモチーフを交互に使う
  const motifRng = rngFor("motif");
  const motifs = [makeMotif(motifRng, preset.leadRhythm), makeMotif(motifRng, preset.leadRhythm)];
  const leadTonic = foldInto(tonic, 65);
  const arpPattern = rngFor("arp").pick(ARP_PATTERNS);

  const events: NoteEvent[] = [];
  const add = (inst: InstrumentId, time: number, dur: number, midi: number, vel: number) => {
    events.push({ inst, time: Math.max(0, time), dur, midi, vel: clamp(vel, 0, 1) });
  };

  // ハネ（スウィング）は裏拍の 8 分音符を遅らせ、16 分音符の裏はその半分だけ遅らせる
  const swingOffset = (step: number) => {
    const beatSeconds = stepSeconds * 4;
    if (mod(step, 4) === 2) return (preset.swing * beatSeconds) / 6;
    if (mod(step, 2) === 1) return (preset.swing * beatSeconds) / 12;
    return 0;
  };
  const at = (bar: number, step: number, r: Rng) =>
    (bar * STEPS_PER_BAR + step) * stepSeconds + swingOffset(step) + (r.next() - 0.5) * preset.humanize;

  const chordRootAt = (bar: number) => {
    const section = sections[Math.floor(mod(bar, bars) / SECTION_BARS)];
    const progression = section.kind === "B" ? progB : progA;
    const barInSection = mod(bar, bars) - section.startBar;
    return progression[Math.floor(barInSection / preset.barsPerChord) % PROGRESSION_LENGTH];
  };
  const chordMidi = (root: number, count: number, offset = 0) =>
    chordDegrees(root, count).map((d) => degreeToMidi(tonic, mode, d + offset));

  const drums = rngFor("drums");
  const bass = rngFor("bass");
  const keys = rngFor("keys");
  const pads = rngFor("pad");
  const lead = rngFor("lead");
  const bell = rngFor("bell");

  let melodySections = 0;
  for (const section of sections) {
    const layers = new Set(preset.layers[section.kind]);

    for (let i = 0; i < section.bars; i++) {
      const bar = section.startBar + i;
      const root = chordRootAt(bar);
      const nextRoot = chordRootAt(bar + 1);
      const chordStart = i % preset.barsPerChord === 0;
      const isLastBar = i === section.bars - 1;

      if (layers.has("kick") || layers.has("snare") || layers.has("hat")) {
        const hits = drumBar(preset.id, isLastBar, drums);
        for (const hit of hits) {
          if (layers.has(hit.inst)) add(hit.inst, at(bar, hit.step, drums), stepSeconds, 0, hit.vel);
        }
      }

      if (layers.has("bass")) {
        const [r, third, fifth] = chordMidi(root, 3);
        const low = foldInto(r, 33);
        const tones = { root: low, third: low + (third - r), fifth: low + (fifth - r) };
        const next = foldInto(chordMidi(nextRoot, 1)[0], 33);
        for (const note of bassBar(preset, tones, next, chordStart, bass)) {
          add("bass", at(bar, note.step, bass), note.len * stepSeconds * 0.92, note.midi, note.vel);
        }
      }

      if (layers.has("keys")) {
        // 根音を省いて 9 度を足した「ルートレス」の和音にすると、ベースと濁らず響きが柔らかい
        const voicing = (size >= 4 ? chordMidi(root, 4, 2) : chordMidi(root, 3))
          .map((m) => foldInto(m, 53))
          .sort((a, b) => a - b);
        for (const hit of keysBar(preset.id, keys)) {
          const start = at(bar, hit.step, keys);
          voicing.forEach((m, n) => add("keys", start + n * 0.012, hit.len * stepSeconds, m, hit.vel - n * 0.03));
        }
      }

      if (layers.has("pad") && chordStart) {
        const tones = chordMidi(root, size).map((m) => foldInto(m, 48));
        tones.push(foldInto(chordMidi(root, 2)[1], 60));
        for (const m of tones) add("pad", at(bar, 0, pads), preset.barsPerChord * barSeconds, m, 0.5);
      }

      if (layers.has("arp")) {
        const tones = chordMidi(root, 3).map((m) => foldInto(m, 62)).sort((a, b) => a - b);
        tones.push(tones[0] + 12);
        arpPattern.forEach((index, n) => {
          add("arp", at(bar, n * 2, keys), stepSeconds * 1.8, tones[index], n % 2 === 0 ? 0.6 : 0.42);
        });
      }

      if (layers.has("bell")) {
        const tones = chordMidi(root, 4, 7).map((m) => foldInto(m, 74));
        const count = bell.int(1, 3);
        const used = new Set<number>();
        for (let n = 0; n < count; n++) {
          const step = bell.int(0, 7) * 2;
          if (used.has(step)) continue;
          used.add(step);
          add("bell", at(bar, step, bell), stepSeconds * 8, bell.pick(tones), bell.range(0.3, 0.5));
        }
      }
    }

    if (layers.has("lead")) {
      const motif = motifs[melodySections++ % motifs.length];
      for (let block = 0; block < section.bars / 2; block++) {
        const blockBar = section.startBar + block * 2;
        const isFinal = block === section.bars / 2 - 1;
        motif.forEach((note, n) => {
          const bar = blockBar + Math.floor(note.step / STEPS_PER_BAR);
          const chordRoot = chordRootAt(bar);
          let degree = note.degree;
          // 2 回目と 4 回目は終わりの音を少し変えて、繰り返しに飽きないようにする
          if (block % 2 === 1 && n >= motif.length - 2) degree += lead.pick([-1, 1, 2]);
          const strong = note.step % 8 === 0;
          if (strong) degree = snapToChord(degree, chordRoot, size);
          let len = note.len;
          if (isFinal && n === motif.length - 1) {
            degree = snapToChord(degree, 0, 3);
            len = Math.max(len, 32 - note.step);
          }
          add("lead", at(blockBar, note.step, lead), len * stepSeconds * 0.95, degreeToMidi(leadTonic, mode, degree), strong ? 0.75 : 0.6);
        });
      }
    }
  }

  events.sort((a, b) => a.time - b.time);

  const naming = rngFor("title");
  return {
    settings: { ...settings, bpm, key },
    preset,
    title: makeTitle(naming, preset),
    keyLabel: `${noteName(tonic, tonic, mode)} ${MODE_LABELS[mode]}`,
    bars,
    barSeconds,
    duration: bars * barSeconds,
    progressions: {
      A: progA.map((d) => chordName(tonic, mode, d, size)),
      B: progB.map((d) => chordName(tonic, mode, d, size)),
    },
    sections,
    events,
  };
}

type DrumHit = { readonly inst: "kick" | "snare" | "hat"; readonly step: number; readonly vel: number };

function drumBar(mood: MoodId, isLastBar: boolean, r: Rng): DrumHit[] {
  const hits: DrumHit[] = [];
  const hit = (inst: DrumHit["inst"], step: number, vel: number) => hits.push({ inst, step, vel });

  switch (mood) {
    case "lofi":
      hit("kick", 0, 0.85);
      hit("kick", r.chance(0.5) ? 10 : 11, 0.7);
      if (r.chance(0.35)) hit("kick", 7, 0.5);
      hit("snare", 4, 0.75);
      hit("snare", 12, 0.75);
      for (let s = 0; s < 16; s += 2) hit("hat", s, s % 4 === 0 ? 0.5 : 0.32);
      if (r.chance(0.2)) hit("hat", 15, 0.2);
      if (isLastBar && r.chance(0.6)) {
        hit("snare", 14, 0.35);
        hit("snare", 15, 0.45);
      }
      break;
    case "cafe":
      hit("kick", 0, 0.5);
      if (r.chance(0.5)) hit("kick", 10, 0.35);
      hit("snare", 12, 0.5);
      if (r.chance(0.3)) hit("snare", 6, 0.18);
      for (const s of [0, 4, 6, 8, 12, 14]) hit("hat", s, s % 4 === 0 ? 0.45 : 0.3);
      if (isLastBar) hit("snare", 14, 0.4);
      break;
    case "upbeat":
      for (const s of [0, 4, 8, 12]) hit("kick", s, 0.9);
      hit("snare", 4, 0.7);
      hit("snare", 12, 0.7);
      for (const s of [2, 6, 10, 14]) hit("hat", s, 0.55);
      for (const s of [1, 3, 5, 7, 9, 11, 13, 15]) if (r.chance(0.6)) hit("hat", s, 0.18);
      if (isLastBar && r.chance(0.7)) {
        for (const [s, v] of [[13, 0.35], [14, 0.45], [15, 0.6]] as const) hit("snare", s, v);
      }
      break;
    case "ambient":
      break;
  }
  return hits;
}

type BassNote = { readonly step: number; readonly len: number; readonly midi: number; readonly vel: number };
type BassTones = { readonly root: number; readonly third: number; readonly fifth: number };

function bassBar(preset: MoodPreset, tones: BassTones, nextRoot: number, chordStart: boolean, r: Rng): BassNote[] {
  switch (preset.id) {
    case "lofi":
      return [
        { step: 0, len: 6, midi: tones.root, vel: 0.85 },
        ...(r.chance(0.4) ? [{ step: 7, len: 2, midi: tones.root, vel: 0.55 }] : []),
        { step: 10, len: 5, midi: r.chance(0.6) ? tones.fifth : tones.root, vel: 0.7 },
      ];
    case "cafe": {
      // ウォーキングベース：4 拍目は次の和音の根音へ半音でつなぐ
      const approach = nextRoot + (r.chance(0.5) ? -1 : 1);
      return [
        { step: 0, len: 4, midi: tones.root, vel: 0.85 },
        { step: 4, len: 4, midi: r.chance(0.5) ? tones.third : tones.fifth, vel: 0.7 },
        { step: 8, len: 4, midi: r.chance(0.6) ? tones.fifth : tones.root + 12, vel: 0.75 },
        { step: 12, len: 4, midi: approach, vel: 0.68 },
      ];
    }
    case "upbeat":
      return Array.from({ length: 8 }, (_, n) => ({
        step: n * 2,
        len: 2,
        midi: n % 2 === 1 && r.chance(0.3) ? tones.root + 12 : tones.root,
        vel: n % 2 === 0 ? 0.8 : 0.6,
      }));
    case "ambient":
      return chordStart ? [{ step: 0, len: preset.barsPerChord * STEPS_PER_BAR, midi: tones.root, vel: 0.6 }] : [];
  }
}

type KeysHit = { readonly step: number; readonly len: number; readonly vel: number };

function keysBar(mood: MoodId, r: Rng): KeysHit[] {
  if (mood === "lofi") {
    const hits: KeysHit[] = [{ step: 0, len: 12, vel: 0.6 }];
    if (r.chance(0.45)) hits.push({ step: r.pick([10, 14]), len: 4, vel: 0.42 });
    return hits;
  }
  const patterns: readonly (readonly KeysHit[])[] = [
    [{ step: 0, len: 6, vel: 0.55 }, { step: 10, len: 4, vel: 0.45 }],
    [{ step: 0, len: 3, vel: 0.55 }, { step: 6, len: 6, vel: 0.5 }],
    [{ step: 2, len: 4, vel: 0.5 }, { step: 8, len: 2, vel: 0.42 }, { step: 14, len: 2, vel: 0.45 }],
  ];
  return [...r.pick(patterns)];
}

// 音階・和音の計算。度数（degree）は主音を 0 とした音階上の位置で、7 で 1 オクターブ上がる

export type Mode = "major" | "minor" | "dorian" | "lydian";

export const NOTE_NAMES = ["C", "D♭", "D", "E♭", "E", "F", "F♯", "G", "A♭", "A", "B♭", "B"] as const;
const SHARP_NAMES = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"] as const;

export const MODE_LABELS: Readonly<Record<Mode, string>> = {
  major: "メジャー",
  minor: "マイナー",
  dorian: "ドリアン",
  lydian: "リディアン",
};

const MODE_STEPS: Readonly<Record<Mode, readonly number[]>> = {
  major: [0, 2, 4, 5, 7, 9, 11],
  minor: [0, 2, 3, 5, 7, 8, 10],
  dorian: [0, 2, 3, 5, 7, 9, 10],
  lydian: [0, 2, 4, 6, 7, 9, 11],
};

// 同じ調号を持つメジャーキーの主音（ドリアンは長 2 度下、リディアンは完全 4 度下）
const RELATIVE_MAJOR_OFFSET: Readonly<Record<Mode, number>> = { major: 0, minor: 3, dorian: 10, lydian: 7 };

export const mod = (value: number, base: number) => ((value % base) + base) % base;

export function degreeToMidi(tonic: number, mode: Mode, degree: number): number {
  const octave = Math.floor(degree / 7);
  return tonic + octave * 12 + MODE_STEPS[mode][degree - octave * 7];
}

// 3 度ずつ積んだ和音の度数（size=4 なら 1・3・5・7 度）
export function chordDegrees(root: number, size: number): number[] {
  return Array.from({ length: size }, (_, i) => root + i * 2);
}

export function midiToFreq(midi: number): number {
  return 440 * 2 ** ((midi - 69) / 12);
}

// low 以上 low+12 未満に収まるようにオクターブを移す
export function foldInto(midi: number, low: number): number {
  return low + mod(midi - low, 12);
}

// 調号が ♭ の調なら ♭、それ以外は ♯ で音名を書く（E メジャーで D♭ ではなく C♯ と書くため）
export function noteName(pitch: number, tonic: number, mode: Mode): string {
  const relativeMajor = mod(tonic + RELATIVE_MAJOR_OFFSET[mode], 12);
  const names = [1, 3, 5, 8, 10].includes(relativeMajor) ? NOTE_NAMES : SHARP_NAMES;
  return names[mod(pitch, 12)];
}

export function isDiminished(tonic: number, mode: Mode, root: number): boolean {
  const [r, , fifth] = chordDegrees(root, 3).map((d) => degreeToMidi(tonic, mode, d));
  return fifth - r === 6;
}

export function chordName(tonic: number, mode: Mode, root: number, size: number): string {
  const [r, third, fifth, seventh] = chordDegrees(root, 4).map((d) => degreeToMidi(tonic, mode, d));
  const minor = third - r === 3;
  let quality: string;
  if (size >= 4) {
    const major7 = seventh - r === 11;
    if (!minor) quality = major7 ? "M7" : "7";
    else if (fifth - r === 6) quality = "m7(♭5)";
    else quality = major7 ? "mM7" : "m7";
  } else {
    quality = fifth - r === 6 ? "dim" : minor ? "m" : "";
  }
  return noteName(r, tonic, mode) + quality;
}

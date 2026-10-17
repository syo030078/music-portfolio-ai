// 作曲した音符を Web Audio の発振器とノイズだけで合成し、1 本の AudioBuffer に書き出す

import type { InstrumentId, NoteEvent, Song } from "./compose";
import { createRng, type Rng } from "./random";
import { midiToFreq } from "./theory";

const SAMPLE_RATE = 44100;
const TAIL_SECONDS = 5;
const PEAK = 0.89; // 約 -1 dBFS
const CHUNK_SECONDS = 2;

type Mix = { readonly gain: number; readonly pan: number; readonly reverb: number };

const MIX: Readonly<Record<InstrumentId, Mix>> = {
  kick: { gain: 0.8, pan: 0, reverb: 0.02 },
  snare: { gain: 0.7, pan: 0.05, reverb: 0.18 },
  hat: { gain: 0.8, pan: 0.25, reverb: 0.08 },
  bass: { gain: 0.42, pan: 0, reverb: 0 },
  keys: { gain: 0.2, pan: -0.15, reverb: 0.35 },
  pad: { gain: 0.09, pan: 0, reverb: 0.55 },
  lead: { gain: 0.38, pan: 0.12, reverb: 0.4 },
  arp: { gain: 0.26, pan: -0.3, reverb: 0.35 },
  bell: { gain: 0.3, pan: 0.2, reverb: 0.65 },
};

type Shared = { readonly noise: AudioBuffer; readonly rng: Rng };
type Voice = (ctx: BaseAudioContext, out: AudioNode, e: NoteEvent, shared: Shared) => void;

function noiseBuffer(ctx: BaseAudioContext, seconds: number, rng: Rng): AudioBuffer {
  const buffer = ctx.createBuffer(1, Math.floor(ctx.sampleRate * seconds), ctx.sampleRate);
  const data = buffer.getChannelData(0);
  for (let i = 0; i < data.length; i++) data[i] = rng.next() * 2 - 1;
  return buffer;
}

function noiseSource(ctx: BaseAudioContext, shared: Shared): AudioBufferSourceNode {
  const source = ctx.createBufferSource();
  source.buffer = shared.noise;
  return source;
}

function filter(ctx: BaseAudioContext, type: BiquadFilterType, frequency: number, q = 0.7): BiquadFilterNode {
  const node = ctx.createBiquadFilter();
  node.type = type;
  node.frequency.value = frequency;
  node.Q.value = q;
  return node;
}

// 鳴り終わったノードを切り離す。つないだままだとレンダリング中ずっと処理され続けて重くなる
function disconnectOnEnd(source: AudioScheduledSourceNode, nodes: readonly AudioNode[]) {
  source.onended = () => {
    for (const node of nodes) node.disconnect();
  };
}

// 立ち上がり → 減衰して持続 → 音符の終わりで消える、の音量変化を付ける
function envelope(param: AudioParam, t: number, dur: number, peak: number, attack: number, decay: number, sustain: number, release: number): number {
  param.setValueAtTime(0, t);
  param.linearRampToValueAtTime(peak, t + attack);
  param.setTargetAtTime(peak * sustain, t + attack, decay / 3);
  const end = t + Math.max(dur, attack);
  param.setTargetAtTime(0, end, release / 3);
  return end + release * 1.2;
}

const kick: Voice = (ctx, out, e) => {
  const osc = ctx.createOscillator();
  const amp = ctx.createGain();
  osc.frequency.setValueAtTime(150, e.time);
  osc.frequency.exponentialRampToValueAtTime(42, e.time + 0.13);
  amp.gain.setValueAtTime(0.0001, e.time);
  amp.gain.exponentialRampToValueAtTime(e.vel, e.time + 0.004);
  amp.gain.exponentialRampToValueAtTime(0.0001, e.time + 0.42);
  osc.connect(amp).connect(out);
  osc.start(e.time);
  osc.stop(e.time + 0.45);
  disconnectOnEnd(osc, [osc, amp]);
};

const snare: Voice = (ctx, out, e, shared) => {
  const noise = noiseSource(ctx, shared);
  const band = filter(ctx, "bandpass", 1800, 0.8);
  const noiseAmp = ctx.createGain();
  noiseAmp.gain.setValueAtTime(e.vel, e.time);
  noiseAmp.gain.exponentialRampToValueAtTime(0.0001, e.time + 0.2);
  noise.connect(band).connect(noiseAmp).connect(out);
  noise.start(e.time, shared.rng.range(0, 1.5));
  noise.stop(e.time + 0.22);
  disconnectOnEnd(noise, [noise, band, noiseAmp]);

  const body = ctx.createOscillator();
  const bodyAmp = ctx.createGain();
  body.type = "triangle";
  body.frequency.setValueAtTime(200, e.time);
  body.frequency.exponentialRampToValueAtTime(150, e.time + 0.08);
  bodyAmp.gain.setValueAtTime(e.vel * 0.6, e.time);
  bodyAmp.gain.exponentialRampToValueAtTime(0.0001, e.time + 0.1);
  body.connect(bodyAmp).connect(out);
  body.start(e.time);
  body.stop(e.time + 0.12);
  disconnectOnEnd(body, [body, bodyAmp]);
};

const hat: Voice = (ctx, out, e, shared) => {
  const noise = noiseSource(ctx, shared);
  const high = filter(ctx, "highpass", 6000);
  const amp = ctx.createGain();
  amp.gain.setValueAtTime(e.vel, e.time);
  amp.gain.exponentialRampToValueAtTime(0.0001, e.time + 0.08);
  noise.connect(high).connect(amp).connect(out);
  noise.start(e.time, shared.rng.range(0, 1.5));
  noise.stop(e.time + 0.09);
  disconnectOnEnd(noise, [noise, high, amp]);
};

const bass: Voice = (ctx, out, e) => {
  const freq = midiToFreq(e.midi);
  const amp = ctx.createGain();
  const osc = ctx.createOscillator();
  const low = filter(ctx, "lowpass", 800);
  const end = envelope(amp.gain, e.time, e.dur, e.vel, 0.008, 0.3, 0.7, 0.08);
  osc.type = "triangle";
  osc.frequency.value = freq;
  osc.connect(low).connect(amp).connect(out);
  osc.start(e.time);
  osc.stop(end);
  disconnectOnEnd(osc, [osc, low, amp]);
};

// FM 合成のエレクトリックピアノ。打鍵直後だけ倍音が多く、すぐ丸い音になる
const keys: Voice = (ctx, out, e) => {
  const freq = midiToFreq(e.midi);
  const carrier = ctx.createOscillator();
  const modulator = ctx.createOscillator();
  const depth = ctx.createGain();
  const amp = ctx.createGain();
  carrier.frequency.value = freq;
  modulator.frequency.value = freq;
  depth.gain.setValueAtTime(freq * 2.2, e.time);
  depth.gain.setTargetAtTime(freq * 0.4, e.time, 0.25);
  const end = envelope(amp.gain, e.time, e.dur, e.vel, 0.006, 1.8, 0.25, 0.3);
  modulator.connect(depth).connect(carrier.frequency);
  carrier.connect(amp).connect(out);
  for (const osc of [carrier, modulator]) {
    osc.start(e.time);
    osc.stop(end);
  }
  disconnectOnEnd(carrier, [carrier, modulator, depth, amp]);
};

const pad: Voice = (ctx, out, e) => {
  const freq = midiToFreq(e.midi);
  const low = filter(ctx, "lowpass", 1100, 0.5);
  const amp = ctx.createGain();
  const end = envelope(amp.gain, e.time, e.dur, e.vel, 0.9, 2, 0.85, 1.6);
  const oscs = [-8, 8].map((cents) => {
    const osc = ctx.createOscillator();
    osc.type = "sawtooth";
    osc.frequency.value = freq;
    osc.detune.value = cents;
    osc.connect(low);
    osc.start(e.time);
    osc.stop(end);
    return osc;
  });
  low.connect(amp).connect(out);
  disconnectOnEnd(oscs[0], [...oscs, low, amp]);
};

const lead: Voice = (ctx, out, e) => {
  const freq = midiToFreq(e.midi);
  const osc = ctx.createOscillator();
  const vibrato = ctx.createOscillator();
  const vibratoDepth = ctx.createGain();
  const low = filter(ctx, "lowpass", 2800);
  const amp = ctx.createGain();
  osc.type = "triangle";
  osc.frequency.value = freq;
  vibrato.frequency.value = 5.2;
  // ビブラートは音の途中から少しずつかける
  vibratoDepth.gain.setValueAtTime(0, e.time);
  vibratoDepth.gain.linearRampToValueAtTime(freq * 0.005, e.time + Math.min(0.6, e.dur));
  const end = envelope(amp.gain, e.time, e.dur, e.vel, 0.03, 0.4, 0.8, 0.15);
  vibrato.connect(vibratoDepth).connect(osc.frequency);
  osc.connect(low).connect(amp).connect(out);
  for (const node of [osc, vibrato]) {
    node.start(e.time);
    node.stop(end);
  }
  disconnectOnEnd(osc, [osc, vibrato, vibratoDepth, low, amp]);
};

const arp: Voice = (ctx, out, e) => {
  const osc = ctx.createOscillator();
  const low = filter(ctx, "lowpass", 2800, 2);
  const amp = ctx.createGain();
  osc.type = "square";
  osc.frequency.value = midiToFreq(e.midi);
  low.frequency.setValueAtTime(3200, e.time);
  low.frequency.setTargetAtTime(500, e.time, 0.08);
  amp.gain.setValueAtTime(e.vel, e.time);
  amp.gain.exponentialRampToValueAtTime(0.0001, e.time + 0.35);
  osc.connect(low).connect(amp).connect(out);
  osc.start(e.time);
  osc.stop(e.time + 0.4);
  disconnectOnEnd(osc, [osc, low, amp]);
};

const bell: Voice = (ctx, out, e) => {
  const freq = midiToFreq(e.midi);
  const carrier = ctx.createOscillator();
  const modulator = ctx.createOscillator();
  const depth = ctx.createGain();
  const amp = ctx.createGain();
  carrier.frequency.value = freq;
  modulator.frequency.value = freq * 3.5;
  depth.gain.setValueAtTime(freq * 1.5, e.time);
  depth.gain.setTargetAtTime(0, e.time, 0.4);
  amp.gain.setValueAtTime(0, e.time);
  amp.gain.linearRampToValueAtTime(e.vel, e.time + 0.003);
  amp.gain.setTargetAtTime(0, e.time + 0.003, 0.8);
  modulator.connect(depth).connect(carrier.frequency);
  carrier.connect(amp).connect(out);
  for (const osc of [carrier, modulator]) {
    osc.start(e.time);
    osc.stop(e.time + 4);
  }
  disconnectOnEnd(carrier, [carrier, modulator, depth, amp]);
};

const VOICES: Readonly<Record<InstrumentId, Voice>> = { kick, snare, hat, bass, keys, pad, lead, arp, bell };

// 残響。フィードバックするディレイを並べた古典的な構成（Schroeder 型）で、
// 畳み込みより計算がずっと軽い
function createReverb(ctx: BaseAudioContext, seconds: number): { input: AudioNode; output: AudioNode } {
  const input = ctx.createGain();
  const output = ctx.createGain();
  input.channelCount = 1;
  input.channelCountMode = "explicit";

  // 全域通過フィルタで音を拡散させてから、くし形フィルタで減衰する響きを作る
  let diffused: AudioNode = input;
  for (const ms of [6.1, 8.9]) {
    const g = 0.6;
    const sum = ctx.createGain();
    const delay = ctx.createDelay(0.1);
    const feedback = ctx.createGain();
    const direct = ctx.createGain();
    const out = ctx.createGain();
    delay.delayTime.value = ms / 1000;
    feedback.gain.value = g;
    direct.gain.value = -g;
    diffused.connect(sum);
    sum.connect(delay).connect(feedback).connect(sum);
    sum.connect(direct).connect(out);
    delay.connect(out);
    diffused = out;
  }

  const combs = [29.7, 37.1, 41.1, 43.7, 50.3, 56.9];
  combs.forEach((ms, i) => {
    const delaySeconds = (ms / 1000) * (seconds > 3 ? 1.5 : 1);
    const delay = ctx.createDelay(0.2);
    // Q は dB 単位。共振して利得が 1 を超えると響きが発散するので、山を作らない値にする
    const damp = filter(ctx, "lowpass", 4500, -3);
    const feedback = ctx.createGain();
    const pan = ctx.createStereoPanner();
    delay.delayTime.value = delaySeconds;
    // 残響が seconds 秒で 60dB 減衰するようにフィードバック量を決める
    feedback.gain.value = 10 ** ((-3 * delaySeconds) / seconds);
    pan.pan.value = i % 2 === 0 ? -0.7 : 0.7;
    diffused.connect(delay);
    delay.connect(damp).connect(feedback).connect(delay);
    damp.connect(pan).connect(output);
  });
  output.gain.value = 1 / combs.length;
  return { input, output };
}

// レコードのチリチリ音（lo-fi）や空気感のノイズ（アンビエント）。ループさせて全体に敷く
function addTexture(ctx: BaseAudioContext, out: AudioNode, song: Song, rng: Rng, duration: number) {
  if (!song.preset.texture) return;
  const buffer = ctx.createBuffer(1, Math.floor(ctx.sampleRate * 6.3), ctx.sampleRate);
  const data = buffer.getChannelData(0);
  const source = ctx.createBufferSource();
  const amp = ctx.createGain();
  source.buffer = buffer;
  source.loop = true;

  if (song.preset.texture === "vinyl") {
    let smoothed = 0;
    for (let i = 0; i < data.length; i++) {
      smoothed += (rng.next() * 2 - 1 - smoothed) * 0.05;
      data[i] = smoothed * 0.5;
      if (rng.chance(5 / ctx.sampleRate)) {
        const size = rng.range(0.15, 0.6) * (rng.chance(0.5) ? 1 : -1);
        for (let k = 0; k < 40 && i + k < data.length; k++) data[i + k] += size * Math.exp(-k / 6);
      }
    }
    amp.gain.value = 0.12;
    source.connect(filter(ctx, "highpass", 300)).connect(amp).connect(out);
  } else {
    for (let i = 0; i < data.length; i++) data[i] = rng.next() * 2 - 1;
    const band = filter(ctx, "bandpass", 700, 0.6);
    const lfo = ctx.createOscillator();
    const lfoDepth = ctx.createGain();
    lfo.frequency.value = 0.07;
    lfoDepth.gain.value = 350;
    lfo.connect(lfoDepth).connect(band.frequency);
    lfo.start(0);
    lfo.stop(duration);
    amp.gain.value = 0.025;
    source.connect(band).connect(amp).connect(out);
  }
  source.start(0);
  source.stop(duration);
}

export async function renderSong(song: Song, onProgress?: (ratio: number) => void): Promise<AudioBuffer> {
  const loopLength = Math.round(song.duration * SAMPLE_RATE);
  const ctx = new OfflineAudioContext(2, loopLength + TAIL_SECONDS * SAMPLE_RATE, SAMPLE_RATE);
  const rng = createRng(song.settings.seed);

  const masterIn = ctx.createGain();
  const warmth = filter(ctx, "lowpass", song.preset.warmth, 0.5);
  const compressor = ctx.createDynamicsCompressor();
  compressor.threshold.value = -16;
  compressor.ratio.value = 3;
  compressor.attack.value = 0.01;
  compressor.release.value = 0.25;
  masterIn.connect(warmth).connect(compressor).connect(ctx.destination);

  const reverb = createReverb(ctx, song.preset.reverbSeconds);
  reverb.output.connect(masterIn);

  const buses = new Map<InstrumentId, AudioNode>();
  const busFor = (inst: InstrumentId) => {
    const existing = buses.get(inst);
    if (existing) return existing;
    const mix = MIX[inst];
    const gain = ctx.createGain();
    const pan = ctx.createStereoPanner();
    const send = ctx.createGain();
    gain.gain.value = mix.gain;
    pan.pan.value = mix.pan;
    send.gain.value = mix.reverb;
    gain.connect(pan).connect(masterIn);
    gain.connect(send).connect(reverb.input);
    buses.set(inst, gain);
    return gain;
  };

  const shared: Shared = { noise: noiseBuffer(ctx, 2, rng), rng };
  let next = 0;
  const scheduleUntil = (until: number) => {
    for (; next < song.events.length && song.events[next].time < until; next++) {
      const event = song.events[next];
      VOICES[event.inst](ctx, busFor(event.inst), event, shared);
    }
  };
  // 全音符のノードを最初に作ると処理が極端に重くなるため、レンダリングを一定間隔で止め、
  // 少し先までの音符だけを組み立てる
  scheduleUntil(CHUNK_SECONDS * 2);
  for (let t = CHUNK_SECONDS; t < song.duration; t += CHUNK_SECONDS) {
    void ctx.suspend(t).then(() => {
      scheduleUntil(t + CHUNK_SECONDS * 2);
      onProgress?.(t / song.duration);
      return ctx.resume();
    });
  }
  addTexture(ctx, masterIn, song, rng, song.duration + TAIL_SECONDS);

  const rendered = await ctx.startRendering();
  return toSeamlessLoop(rendered, loopLength);
}

// 曲の終わりからはみ出した残響を先頭に重ねて、ループ再生のつなぎ目で響きが途切れないようにする。
// あわせて音量のピークを揃える
function toSeamlessLoop(rendered: AudioBuffer, loopLength: number): AudioBuffer {
  const out = new AudioBuffer({ length: loopLength, numberOfChannels: rendered.numberOfChannels, sampleRate: rendered.sampleRate });
  let peak = 0;
  for (let ch = 0; ch < rendered.numberOfChannels; ch++) {
    const src = rendered.getChannelData(ch);
    const dst = out.getChannelData(ch);
    dst.set(src.subarray(0, loopLength));
    for (let i = loopLength; i < src.length; i++) dst[i - loopLength] += src[i];
    for (let i = 0; i < loopLength; i++) peak = Math.max(peak, Math.abs(dst[i]));
  }
  if (!Number.isFinite(peak)) throw new Error("音声の合成に失敗しました");
  if (peak > 0) {
    const scale = PEAK / peak;
    for (let ch = 0; ch < out.numberOfChannels; ch++) {
      const dst = out.getChannelData(ch);
      for (let i = 0; i < loopLength; i++) dst[i] *= scale;
    }
  }
  return out;
}

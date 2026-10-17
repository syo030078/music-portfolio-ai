"use client";

import { useCallback, useEffect, useRef, useState } from "react";

// 生成した AudioBuffer を途切れなくループ再生する
export function useBgmPlayer() {
  const ctxRef = useRef<AudioContext | null>(null);
  const gainRef = useRef<GainNode | null>(null);
  const sourceRef = useRef<AudioBufferSourceNode | null>(null);
  const bufferRef = useRef<AudioBuffer | null>(null);
  const startedAtRef = useRef(0);
  const offsetRef = useRef(0);
  const [isPlaying, setIsPlaying] = useState(false);
  const [position, setPosition] = useState(0);
  const [volume, setVolumeState] = useState(0.8);

  // ブラウザの自動再生制限があるため、クリック操作の中で同期的に呼ぶ
  const ensureContext = useCallback(() => {
    if (!ctxRef.current) {
      const ctx = new AudioContext();
      const gain = ctx.createGain();
      gain.gain.value = volume;
      gain.connect(ctx.destination);
      ctxRef.current = ctx;
      gainRef.current = gain;
    }
    void ctxRef.current.resume();
    return ctxRef.current;
  }, [volume]);

  const currentPosition = useCallback(() => {
    const ctx = ctxRef.current;
    const buffer = bufferRef.current;
    if (!ctx || !buffer) return 0;
    if (!sourceRef.current) return offsetRef.current;
    return (offsetRef.current + ctx.currentTime - startedAtRef.current) % buffer.duration;
  }, []);

  const stopSource = useCallback(() => {
    sourceRef.current?.stop();
    sourceRef.current?.disconnect();
    sourceRef.current = null;
  }, []);

  const play = useCallback(() => {
    const ctx = ensureContext();
    const buffer = bufferRef.current;
    if (!buffer || !gainRef.current || sourceRef.current) return;
    const source = ctx.createBufferSource();
    source.buffer = buffer;
    source.loop = true;
    source.connect(gainRef.current);
    source.start(0, offsetRef.current);
    startedAtRef.current = ctx.currentTime;
    sourceRef.current = source;
    setIsPlaying(true);
  }, [ensureContext]);

  const pause = useCallback(() => {
    offsetRef.current = currentPosition();
    stopSource();
    setIsPlaying(false);
  }, [currentPosition, stopSource]);

  const load = useCallback(
    (buffer: AudioBuffer) => {
      stopSource();
      bufferRef.current = buffer;
      offsetRef.current = 0;
      setPosition(0);
      setIsPlaying(false);
    },
    [stopSource]
  );

  const seek = useCallback(
    (seconds: number) => {
      const wasPlaying = Boolean(sourceRef.current);
      stopSource();
      offsetRef.current = seconds;
      setPosition(seconds);
      if (wasPlaying) play();
    },
    [play, stopSource]
  );

  const setVolume = useCallback((value: number) => {
    setVolumeState(value);
    if (gainRef.current && ctxRef.current) {
      gainRef.current.gain.setTargetAtTime(value, ctxRef.current.currentTime, 0.05);
    }
  }, []);

  useEffect(() => {
    if (!isPlaying) return;
    let frame = 0;
    const tick = () => {
      setPosition(currentPosition());
      frame = requestAnimationFrame(tick);
    };
    frame = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(frame);
  }, [isPlaying, currentPosition]);

  useEffect(() => {
    return () => {
      sourceRef.current?.stop();
      void ctxRef.current?.close();
    };
  }, []);

  return { ensureContext, load, play, pause, seek, isPlaying, position, volume, setVolume };
}

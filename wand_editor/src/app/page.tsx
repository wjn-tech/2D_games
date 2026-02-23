"use client";

import React, { useState, useRef, useCallback, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  Sparkles,
  Wand2,
  Zap,
  Clock,
  Droplets,
  Gauge,
  Star,
  Target,
  Flame,
  Battery,
  CircleDot,
  GitBranch,
  Play,
  Settings,
  Crown,
  FlameKindling,
  AlertTriangle,
  GripVertical,
  Trash2,
  Eraser,
  Paintbrush,
  X,
  Square,
  ChevronLeft,
  ChevronRight,
  Save,
  Plus,
} from "lucide-react";
import { cn } from "@/lib/utils";

// Types
type EditMode = "appearance" | "nodes";
type NodeType = "energy" | "modifier" | "projectile" | "trigger" | "multicast";
type PaintTool = "brush" | "eraser";

interface Node {
  id: string;
  type: NodeType;
  x: number;
  y: number;
}

interface Connection {
  from: string;
  to: string;
}

interface WandData {
  id: string;
  name: string;
  level: number;
  castDelay: number;
  chargeTime: number;
  manaCapacity: number;
  manaRegen: number;
  chargeRegen: number;
  logicCapacity: number;
  pixels: [string, string][];
  nodes: Node[];
  connections: Connection[];
}

interface WandState {
  name: string;
  level: number;
  castDelay: number;
  chargeTime: number;
  manaCapacity: number;
  manaRegen: number;
  chargeRegen: number;
  logicCapacity: number;
  usedNodes: number;
  appearanceModules: number;
}

interface SpellResult {
  projectiles: ProjectileInfo[];
  totalMana: number;
  totalDamage: number;
  castTime: number;
  executionLog: string[];
}

interface ProjectileInfo {
  id: string;
  modifiers: string[];
  damage: number;
  x: number;
  y: number;
  vx: number;
  vy: number;
  triggerProjectiles?: ProjectileInfo[];
}

// Default wands
const DEFAULT_WANDS: WandData[] = [
  {
    id: "wand-1",
    name: "Ice Wand",
    level: 1,
    castDelay: 0.2,
    chargeTime: 0.5,
    manaCapacity: 100,
    manaRegen: 50,
    chargeRegen: 40,
    logicCapacity: 5,
    pixels: [],
    nodes: [],
    connections: [],
  },
  {
    id: "wand-2",
    name: "Fire Wand",
    level: 2,
    castDelay: 0.15,
    chargeTime: 0.4,
    manaCapacity: 150,
    manaRegen: 60,
    chargeRegen: 50,
    logicCapacity: 7,
    pixels: [],
    nodes: [],
    connections: [],
  },
  {
    id: "wand-3",
    name: "Thunder Wand",
    level: 3,
    castDelay: 0.1,
    chargeTime: 0.3,
    manaCapacity: 200,
    manaRegen: 80,
    chargeRegen: 60,
    logicCapacity: 10,
    pixels: [],
    nodes: [],
    connections: [],
  },
];

// Color palettes
const COLOR_PALETTES = [
  {
    name: "元素之力",
    colors: ["#ff4757", "#ff6b81", "#ffa502", "#ffdd59", "#2ed573", "#1abc9c", "#1e90ff", "#5352ed"],
  },
  {
    name: "神秘暗影",
    colors: ["#2f3542", "#57606f", "#747d8c", "#a4b0be", "#1e272e", "#485460", "#636e72", "#2d3436"],
  },
  {
    name: "魔法光辉",
    colors: ["#a55eea", "#8854d0", "#3867d6", "#4b7bec", "#fc5c65", "#fd9644", "#f7b731", "#26de81"],
  },
  {
    name: "自然之息",
    colors: ["#27ae60", "#2ecc71", "#a3cb38", "#c4e538", "#009432", "#006266", "#20bf6b", "#0fb9b1"],
  },
];

// Node types
const NODE_TYPES: Record<NodeType, { 
  icon: React.ReactNode; 
  label: string; 
  color: string; 
  glow: string;
  description: string;
  category: string;
}> = {
  energy: {
    icon: <Zap className="w-4 h-4" />,
    label: "能量源",
    color: "#22c55e",
    glow: "rgba(34, 197, 94, 0.6)",
    description: "法杖魔法能量的起点",
    category: "source",
  },
  modifier: {
    icon: <Gauge className="w-4 h-4" />,
    label: "修饰符",
    color: "#8b5cf6",
    glow: "rgba(139, 92, 246, 0.6)",
    description: "修饰下一个投射物法术",
    category: "modifier",
  },
  projectile: {
    icon: <CircleDot className="w-4 h-4" />,
    label: "投射物",
    color: "#ef4444",
    glow: "rgba(239, 68, 68, 0.6)",
    description: "发射投射物法术",
    category: "projectile",
  },
  trigger: {
    icon: <Target className="w-4 h-4" />,
    label: "触发器",
    color: "#f59e0b",
    glow: "rgba(245, 158, 11, 0.6)",
    description: "触发后发射连接的投射物",
    category: "trigger",
  },
  multicast: {
    icon: <GitBranch className="w-4 h-4" />,
    label: "多重施法",
    color: "#06b6d4",
    glow: "rgba(6, 182, 212, 0.6)",
    description: "同时激活多个分支",
    category: "multicast",
  },
};

// Animated background
const MagicBackground = () => (
  <div className="fixed inset-0 -z-10 overflow-hidden">
    <div className="absolute inset-0 bg-gradient-to-br from-[#1a1525] via-[#1f1a2e] to-[#151825]" />
    <motion.div className="absolute top-0 left-0 right-0 h-[50%]"
      style={{ background: "linear-gradient(180deg, rgba(139, 92, 246, 0.12) 0%, rgba(236, 72, 153, 0.06) 50%, transparent 100%)" }}
      animate={{ opacity: [0.4, 0.7, 0.4] }} transition={{ duration: 8, repeat: Infinity, ease: "easeInOut" }} />
    <motion.div className="absolute top-[15%] left-[8%] w-72 h-72 rounded-full blur-3xl"
      style={{ background: "radial-gradient(circle, rgba(236, 72, 153, 0.2) 0%, transparent 70%)" }}
      animate={{ x: [0, 40, 0], y: [0, -20, 0] }} transition={{ duration: 15, repeat: Infinity, ease: "easeInOut" }} />
    <motion.div className="absolute bottom-[25%] right-[10%] w-96 h-96 rounded-full blur-3xl"
      style={{ background: "radial-gradient(circle, rgba(99, 102, 241, 0.15) 0%, transparent 70%)" }}
      animate={{ x: [0, -30, 0], y: [0, 30, 0] }} transition={{ duration: 18, repeat: Infinity, ease: "easeInOut" }} />
    {Array.from({ length: 40 }).map((_, i) => (
      <motion.div key={i} className="absolute rounded-full"
        style={{ width: Math.random() * 2.5 + 1, height: Math.random() * 2.5 + 1, left: `${Math.random() * 100}%`, top: `${Math.random() * 100}%`, background: ["#fff", "#c4b5fd", "#a5b4fc", "#f9a8d4"][Math.floor(Math.random() * 4)] }}
        animate={{ opacity: [0.3, 1, 0.3], scale: [1, 1.3, 1] }} transition={{ duration: 2 + Math.random() * 3, repeat: Infinity, delay: Math.random() * 5 }} />
    ))}
  </div>
);

// Header
const Header = ({ wandState, onTestSpell, onStopTest, isTesting, onOpenWandSelect }: { wandState: WandState; onTestSpell: () => void; onStopTest: () => void; isTesting: boolean; onOpenWandSelect: () => void }) => (
  <motion.header initial={{ y: -20, opacity: 0 }} animate={{ y: 0, opacity: 1 }}
    className="px-4 py-2.5 flex items-center justify-between border-b border-white/10 bg-[#1a1525]/80 backdrop-blur-xl">
    <div className="flex items-center gap-3">
      <motion.div className="relative" whileHover={{ scale: 1.1, rotate: 15 }} transition={{ type: "spring", stiffness: 400 }}>
        <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-purple-500/30 to-pink-500/30 flex items-center justify-center border border-purple-400/40 shadow-lg shadow-purple-500/20">
          <Wand2 className="w-4 h-4 text-purple-200" />
        </div>
        <motion.div className="absolute -top-0.5 -right-0.5 w-2.5 h-2.5 bg-gradient-to-br from-yellow-300 to-amber-500 rounded-full"
          animate={{ scale: [1, 1.3, 1], opacity: [1, 0.7, 1] }} transition={{ duration: 1.5, repeat: Infinity }} />
      </motion.div>
      <div>
        <h1 className="text-sm font-medium text-white/90 flex items-center gap-2">
          当前法杖: 
          <span className="bg-gradient-to-r from-purple-300 via-pink-300 to-cyan-300 bg-clip-text text-transparent font-semibold">
            {wandState.name}
          </span>
        </h1>
        <div className="flex items-center gap-2 text-xs text-white/50">
          <Star className="w-3 h-3 text-amber-400 fill-amber-400" />
          <span>★ {wandState.level}</span>
          <span className="text-white/30">|</span>
          <span>{wandState.chargeTime.toFixed(2)}s</span>
          <span className="text-white/30">|</span>
          <span className="text-cyan-300">{wandState.manaCapacity}</span>
          <span className="text-white/30">|</span>
          <span className="text-purple-300">{wandState.usedNodes} / {wandState.logicCapacity}</span>
        </div>
      </div>
    </div>
    <div className="flex items-center gap-2">
      {isTesting ? (
        <motion.button onClick={onStopTest} whileHover={{ scale: 1.05, y: -1 }} whileTap={{ scale: 0.95 }}
          className="px-3 py-1.5 rounded-xl bg-gradient-to-r from-red-500 to-rose-600 text-white text-xs font-medium flex items-center gap-1.5 shadow-lg shadow-red-500/30 hover:shadow-red-500/50 transition-shadow">
          <Square className="w-3 h-3" />停止测试
        </motion.button>
      ) : (
        <motion.button onClick={onTestSpell} whileHover={{ scale: 1.05, y: -1 }} whileTap={{ scale: 0.95 }}
          className="px-3 py-1.5 rounded-xl bg-gradient-to-r from-emerald-500 to-teal-500 text-white text-xs font-medium flex items-center gap-1.5 shadow-lg shadow-emerald-500/30 hover:shadow-emerald-500/50 transition-shadow">
          <Play className="w-3 h-3" />测试法术
        </motion.button>
      )}
      <motion.button onClick={onOpenWandSelect} whileHover={{ scale: 1.05, y: -1 }} whileTap={{ scale: 0.95 }}
        className="px-3 py-1.5 rounded-xl bg-gradient-to-r from-indigo-500 to-purple-500 text-white text-xs font-medium flex items-center gap-1.5 shadow-lg shadow-indigo-500/30 hover:shadow-indigo-500/50 transition-shadow">
        <Settings className="w-3 h-3" />切换法杖
      </motion.button>
    </div>
  </motion.header>
);

// Wand Select Modal
const WandSelectModal = ({
  isVisible,
  wands,
  currentWandId,
  onSelectWand,
  onCreateWand,
  onDeleteWand,
  onClose,
}: {
  isVisible: boolean;
  wands: WandData[];
  currentWandId: string;
  onSelectWand: (wand: WandData) => void;
  onCreateWand: () => void;
  onDeleteWand: (id: string) => void;
  onClose: () => void;
}) => {
  if (!isVisible) return null;

  return (
    <motion.div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm"
      initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={onClose}>
      <motion.div className="relative w-[500px] rounded-2xl overflow-hidden bg-[#1a1525]/95 border border-purple-500/30 shadow-2xl shadow-purple-500/20"
        initial={{ scale: 0.9, y: 20 }} animate={{ scale: 1, y: 0 }} exit={{ scale: 0.9, y: 20 }} onClick={e => e.stopPropagation()}>
        <div className="flex items-center justify-between p-4 border-b border-white/10">
          <div className="flex items-center gap-2">
            <Wand2 className="w-5 h-5 text-purple-400" />
            <h2 className="text-lg font-bold text-white/90">选择法杖</h2>
          </div>
          <button onClick={onClose} className="p-1 rounded-lg hover:bg-white/10 transition-colors">
            <X className="w-5 h-5 text-white/50" />
          </button>
        </div>
        <div className="p-4 max-h-[400px] overflow-y-auto">
          <div className="grid gap-3">
            {wands.map((wand) => (
              <motion.div
                key={wand.id}
                onClick={() => { onSelectWand(wand); onClose(); }}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                className={cn(
                  "p-4 rounded-xl cursor-pointer transition-all border",
                  currentWandId === wand.id
                    ? "bg-purple-500/20 border-purple-400/50 shadow-lg shadow-purple-500/20"
                    : "bg-white/5 border-white/10 hover:bg-white/10 hover:border-purple-400/30"
                )}
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className={cn(
                      "w-10 h-10 rounded-lg flex items-center justify-center",
                      currentWandId === wand.id
                        ? "bg-gradient-to-br from-purple-500/40 to-pink-500/40"
                        : "bg-white/10"
                    )}>
                      <Wand2 className={cn("w-5 h-5", currentWandId === wand.id ? "text-purple-300" : "text-white/50")} />
                    </div>
                    <div>
                      <p className="font-medium text-white/90">{wand.name}</p>
                      <div className="flex items-center gap-2 text-xs text-white/50">
                        <span>★ Lv.{wand.level}</span>
                        <span>•</span>
                        <span>{wand.logicCapacity} 节点</span>
                        <span>•</span>
                        <span>{wand.manaCapacity} 法力</span>
                      </div>
                    </div>
                  </div>
                  {currentWandId === wand.id && (
                    <div className="px-2 py-1 rounded bg-purple-500/30 text-purple-300 text-xs">当前</div>
                  )}
                </div>
                <div className="mt-3 grid grid-cols-4 gap-2 text-xs">
                  <div className="p-2 rounded bg-white/5 text-center">
                    <p className="text-white/40">施法延迟</p>
                    <p className="text-cyan-300 font-medium">{wand.castDelay.toFixed(2)}s</p>
                  </div>
                  <div className="p-2 rounded bg-white/5 text-center">
                    <p className="text-white/40">充能时间</p>
                    <p className="text-blue-300 font-medium">{wand.chargeTime.toFixed(2)}s</p>
                  </div>
                  <div className="p-2 rounded bg-white/5 text-center">
                    <p className="text-white/40">法力回复</p>
                    <p className="text-purple-300 font-medium">{wand.manaRegen}/s</p>
                  </div>
                  <div className="p-2 rounded bg-white/5 text-center">
                    <p className="text-white/40">充能回复</p>
                    <p className="text-emerald-300 font-medium">+{wand.chargeRegen}</p>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
        <div className="p-4 border-t border-white/10 flex gap-2">
          <motion.button onClick={onCreateWand} whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}
            className="flex-1 py-2 rounded-xl bg-gradient-to-r from-purple-500/30 to-pink-500/30 border border-purple-400/30 text-white/90 text-sm font-medium flex items-center justify-center gap-2 hover:from-purple-500/40 hover:to-pink-500/40 transition-all">
            <Plus className="w-4 h-4" />新建法杖
          </motion.button>
        </div>
      </motion.div>
    </motion.div>
  );
};

// Wand Preview
const WandPreview = ({ pixels }: { pixels: Map<string, string> }) => {
  const gridSize = 32;
  const cellSize = 4;
  const canvasSize = gridSize * cellSize;
  const hasPixels = pixels.size > 0;
  
  return (
    <div className="relative w-40 h-40 flex items-center justify-center">
      <motion.div className="absolute w-36 h-36 rounded-full"
        style={{ background: "radial-gradient(circle, rgba(139, 92, 246, 0.08) 0%, transparent 70%)", border: "1px solid rgba(139, 92, 246, 0.25)" }}
        animate={{ rotate: 360 }} transition={{ duration: 20, repeat: Infinity, ease: "linear" }}>
        {["✧", "◈", "⬡", "✦", "◇", "⬢", "✴", "◆"].map((rune, i) => (
          <motion.div key={i} className="absolute text-purple-400/50 text-xs"
            style={{ left: "50%", top: "50%", transform: `rotate(${i * 45}deg) translateY(-72px)` }}>{rune}</motion.div>
        ))}
      </motion.div>
      <motion.div className="absolute w-28 h-28 rounded-full border border-cyan-400/15" animate={{ rotate: -360 }} transition={{ duration: 15, repeat: Infinity, ease: "linear" }} />
      <motion.div className="relative z-10" initial={{ opacity: 0, scale: 0.8 }} animate={{ opacity: 1, scale: 1 }} transition={{ duration: 0.5 }}>
        {hasPixels && (
          <motion.div className="absolute inset-0 blur-xl" style={{ background: "radial-gradient(ellipse, rgba(139, 92, 246, 0.3) 0%, transparent 70%)" }}
            animate={{ scale: [1, 1.3, 1], opacity: [0.4, 0.7, 0.4] }} transition={{ duration: 3, repeat: Infinity }} />
        )}
        <div className="relative rounded-lg overflow-hidden" style={{ width: canvasSize, height: canvasSize }}>
          {Array.from(pixels.entries()).map(([key, color]) => {
            const [x, y] = key.split(",").map(Number);
            return <div key={key} className="absolute" style={{ left: x * cellSize, top: y * cellSize, width: cellSize, height: cellSize, background: color, boxShadow: `0 0 4px ${color}` }} />;
          })}
        </div>
      </motion.div>
      {[...Array(6)].map((_, i) => (
        <motion.div key={i} className="absolute w-2 h-2"
          style={{ position: "absolute", left: "50%", top: "50%", marginLeft: -4, marginTop: -4, transformOrigin: `${40 + i * 8}px center` } as React.CSSProperties}
          animate={{ rotate: [0, 360], scale: [1, 1.2, 1] }} transition={{ duration: 4 + i, repeat: Infinity, ease: "linear", delay: i * 0.5 }}>
          <motion.div className="w-2 h-2 rounded-full"
            style={{ background: ["#a78bfa", "#f472b6", "#67e8f9", "#fcd34d", "#86efac", "#f9a8d4"][i], boxShadow: `0 0 6px ${["#a78bfa", "#f472b6", "#67e8f9", "#fcd34d", "#86efac", "#f9a8d4"][i]}` }} />
        </motion.div>
      ))}
      {!hasPixels && <div className="absolute inset-0 flex items-center justify-center"><p className="text-xs text-white/25 text-center px-4">在画布上绘制<br/>预览将在此显示</p></div>}
    </div>
  );
};

// Spell Test Visualizer with continuous firing
const SpellTestVisualizer = ({
  isVisible,
  result,
  onClose,
  castDelay,
}: {
  isVisible: boolean;
  result: SpellResult | null;
  onClose: () => void;
  castDelay: number;
}) => {
  const [projectiles, setProjectiles] = useState<ProjectileInfo[]>([]);
  const [effects, setEffects] = useState<{ id: string; x: number; y: number; type: string }[]>([]);
  const animationRef = useRef<NodeJS.Timeout | null>(null);
  const castIntervalRef = useRef<NodeJS.Timeout | null>(null);
  const projectileIdRef = useRef(0);

  // Generate new projectiles from result
  const generateProjectiles = useCallback((baseResult: SpellResult): ProjectileInfo[] => {
    return baseResult.projectiles.map((p) => ({
      ...p,
      id: `proj-${++projectileIdRef.current}`,
      x: 50,
      y: 280,
      vx: 3 + Math.random() * 2,
      vy: -2 - Math.random() * 3,
    }));
  }, []);

  // Main animation loop
  useEffect(() => {
    if (!isVisible || !result) {
      if (animationRef.current) { clearInterval(animationRef.current); animationRef.current = null; }
      if (castIntervalRef.current) { clearInterval(castIntervalRef.current); castIntervalRef.current = null; }
      projectileIdRef.current = 0;
      // Defer state updates to avoid synchronous setState in effect
      const clearId = setTimeout(() => {
        setProjectiles([]);
        setEffects([]);
      }, 0);
      return () => clearTimeout(clearId);
    }

    // Initial burst - defer to avoid synchronous setState
    const initId = setTimeout(() => {
      setProjectiles(prev => [...prev, ...generateProjectiles(result)]);
      setEffects([]);

      // Continuous casting
      const castMs = Math.max(castDelay * 1000, 200);
      castIntervalRef.current = setInterval(() => {
        setProjectiles(prev => [...prev, ...generateProjectiles(result)]);
      }, castMs);

      // Physics animation
      animationRef.current = setInterval(() => {
        setProjectiles(prev => {
          const updated = prev.map(p => ({
            ...p,
            x: p.x + p.vx,
            y: p.y + p.vy,
            vy: p.vy + 0.1,
          }));

          updated.forEach(p => {
            if (p.triggerProjectiles && p.y < 200) {
              const newProjectiles = p.triggerProjectiles.map(tp => ({
                ...tp,
                id: `trigger-${++projectileIdRef.current}`,
                x: p.x,
                y: p.y,
                vx: (Math.random() - 0.5) * 4,
                vy: -2 - Math.random() * 2,
              }));
              setProjectiles(prevProj => [...prevProj, ...newProjectiles]);
              setEffects(prevEff => [...prevEff, { id: `fx-${Date.now()}`, x: p.x, y: p.y, type: "trigger" }]);
              p.triggerProjectiles = undefined;
            }
          });

          return updated.filter(p => p.x < 600 && p.y < 450 && p.y > -50);
        });

        setEffects(prev => prev.slice(-10));
      }, 16);
    }, 0);

    return () => {
      clearTimeout(initId);
      if (animationRef.current) { clearInterval(animationRef.current); animationRef.current = null; }
      if (castIntervalRef.current) { clearInterval(castIntervalRef.current); castIntervalRef.current = null; }
    };
  }, [isVisible, result, castDelay, generateProjectiles]);

  if (!isVisible) return null;

  return (
    <motion.div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm"
      initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={onClose}>
      <motion.div className="relative w-[650px] rounded-2xl overflow-hidden bg-[#1a1525]/95 border border-purple-500/30 shadow-2xl shadow-purple-500/20"
        initial={{ scale: 0.9, y: 20 }} animate={{ scale: 1, y: 0 }} exit={{ scale: 0.9, y: 20 }} onClick={e => e.stopPropagation()}>
        <div className="flex items-center justify-between p-4 border-b border-white/10">
          <div className="flex items-center gap-2">
            <motion.div animate={{ rotate: [0, 360] }} transition={{ duration: 2, repeat: Infinity, ease: "linear" }}>
              <Sparkles className="w-5 h-5 text-purple-400" />
            </motion.div>
            <h2 className="text-lg font-bold text-white/90">法术测试中...</h2>
            <span className="px-2 py-0.5 rounded-full bg-red-500/20 border border-red-500/30 text-red-400 text-xs animate-pulse">实时</span>
          </div>
          <button onClick={onClose} className="px-3 py-1.5 rounded-lg bg-red-500/20 border border-red-500/30 hover:bg-red-500/30 text-red-400 text-sm font-medium flex items-center gap-1.5 transition-colors">
            <Square className="w-3 h-3" />停止
          </button>
        </div>
        <div className="relative h-80 bg-gradient-to-b from-[#0d0d1a] to-[#1a1525] overflow-hidden">
          <div className="absolute inset-0 opacity-10" style={{ backgroundImage: "radial-gradient(circle, rgba(139, 92, 246, 0.5) 1px, transparent 1px)", backgroundSize: "20px 20px" }} />
          <div className="absolute left-8 bottom-20 flex flex-col items-center gap-1">
            <motion.div className="w-4 h-12 rounded-full bg-gradient-to-t from-purple-500 to-pink-500 shadow-lg shadow-purple-500/50"
              animate={{ scale: [1, 1.1, 1] }} transition={{ duration: 0.3, repeat: Infinity }} />
            <span className="text-[10px] text-white/40">发射点</span>
          </div>
          {projectiles.map((p) => (
            <motion.div key={p.id} className="absolute" style={{ left: p.x, top: p.y }} initial={{ scale: 0 }} animate={{ scale: 1 }}>
              <motion.div className="w-3 h-3 rounded-full bg-red-500 shadow-lg shadow-red-500/80"
                animate={{ scale: [1, 1.2, 1] }} transition={{ duration: 0.2, repeat: Infinity }} />
              <div className="absolute inset-0 w-8 h-1 -left-2 top-1 bg-gradient-to-l from-red-500/50 to-transparent blur-sm" style={{ transform: `rotate(${Math.atan2(p.vy, p.vx) * 180 / Math.PI}deg)` }} />
            </motion.div>
          ))}
          {effects.map(e => (
            <motion.div key={e.id} className="absolute" style={{ left: e.x, top: e.y }}
              initial={{ scale: 0, opacity: 1 }} animate={{ scale: 3, opacity: 0 }} transition={{ duration: 0.5 }}>
              <div className="w-8 h-8 rounded-full border-2 border-amber-400" />
            </motion.div>
          ))}
          <div className="absolute top-3 right-3 p-3 rounded-lg bg-black/40 backdrop-blur-sm">
            <div className="text-xs space-y-1">
              <p className="text-white/60">投射物: <span className="text-red-400 font-bold">{projectiles.length}</span></p>
              <p className="text-white/60 text-[10px]">每 {castDelay.toFixed(2)}s 发射</p>
            </div>
          </div>
        </div>
        <div className="p-4 border-t border-white/10 bg-white/5">
          <div className="text-center">
            <p className="text-sm text-white/60">点击"停止"按钮或点击外部区域停止测试</p>
          </div>
        </div>
      </motion.div>
    </motion.div>
  );
};

// Pixel Canvas
const PixelCanvas = ({ pixels, selectedColor, tool, onPixelDraw, onClear }: { pixels: Map<string, string>; selectedColor: string; tool: PaintTool; onPixelDraw: (x: number, y: number) => void; onClear: () => void }) => {
  const gridSize = 32;
  const cellSize = 14;
  const isDrawing = useRef(false);

  return (
    <div className="flex flex-col items-center gap-4">
      <motion.div className="relative rounded-2xl overflow-hidden"
        style={{ background: "linear-gradient(135deg, rgba(25, 20, 35, 0.95), rgba(35, 28, 45, 0.95))", boxShadow: "0 0 0 1px rgba(139, 92, 246, 0.3), 0 0 40px -10px rgba(139, 92, 246, 0.4), inset 0 1px 0 rgba(255, 255, 255, 0.08)" }}
        onMouseUp={() => isDrawing.current = false} onMouseLeave={() => isDrawing.current = false}
        initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} transition={{ duration: 0.3 }}>
        <div className="absolute inset-0 pointer-events-none opacity-40" style={{ backgroundImage: "linear-gradient(rgba(139, 92, 246, 0.15) 1px, transparent 1px), linear-gradient(90deg, rgba(139, 92, 246, 0.15) 1px, transparent 1px)", backgroundSize: `${cellSize}px ${cellSize}px` }} />
        <div className="relative" style={{ width: gridSize * cellSize, height: gridSize * cellSize }}>
          {Array.from({ length: gridSize }).map((_, y) =>
            Array.from({ length: gridSize }).map((__, x) => {
              const key = `${x},${y}`;
              const color = pixels.get(key);
              return (
                <div key={key} className="absolute cursor-crosshair" style={{ left: x * cellSize, top: y * cellSize, width: cellSize, height: cellSize }}
                  onMouseDown={() => { isDrawing.current = true; onPixelDraw(x, y); }}
                  onMouseEnter={() => { if (isDrawing.current) onPixelDraw(x, y); }}>
                  <motion.div className="w-full h-full transition-all rounded-sm"
                    style={{ background: color || "rgba(40, 35, 55, 0.3)", boxShadow: color ? `inset 0 0 2px ${color}` : "none" }}
                    whileHover={{ scale: 1.2, background: color || `${selectedColor}60`, zIndex: 10 }} whileTap={{ scale: 0.9 }} />
                </div>
              );
            })
          )}
        </div>
      </motion.div>
      <motion.button onClick={onClear} whileHover={{ scale: 1.05, y: -2 }} whileTap={{ scale: 0.95 }}
        className="px-4 py-2 rounded-xl bg-white/10 border border-white/20 text-white/70 text-sm flex items-center gap-2 hover:text-white hover:border-red-400/50 hover:bg-red-500/20 transition-all">
        <Trash2 className="w-4 h-4" />清空画布
      </motion.button>
    </div>
  );
};

// Draggable Node
const DraggableNodeItem = ({ type, nodeInfo, onDragStart }: { type: NodeType; nodeInfo: typeof NODE_TYPES[NodeType]; onDragStart: (e: React.DragEvent, type: NodeType) => void }) => (
  <motion.div draggable onDragStart={(e) => onDragStart(e as unknown as React.DragEvent, type)}
    whileHover={{ scale: 1.02, x: 4 }} whileTap={{ scale: 0.98 }}
    className="p-2.5 rounded-xl bg-white/10 border border-white/15 hover:border-purple-400/50 transition-all cursor-grab active:cursor-grabbing group flex items-center gap-2.5 backdrop-blur-sm">
    <div className="w-9 h-9 rounded-lg flex items-center justify-center shrink-0"
      style={{ background: `linear-gradient(135deg, ${nodeInfo.color}40, ${nodeInfo.color}20)`, boxShadow: `0 0 15px ${nodeInfo.glow}`, border: `1px solid ${nodeInfo.color}50` }}>
      <span style={{ color: nodeInfo.color }}>{nodeInfo.icon}</span>
    </div>
    <div className="flex-1 min-w-0">
      <p className="text-xs font-medium text-white/90 truncate">{nodeInfo.label}</p>
      <p className="text-[10px] text-white/40 truncate">{nodeInfo.description}</p>
    </div>
    <GripVertical className="w-4 h-4 text-white/30 group-hover:text-purple-300/60 transition-colors shrink-0" />
  </motion.div>
);

// Sidebar
const Sidebar = ({ editMode, setEditMode, selectedColor, onColorSelect, tool, setTool, onDragStartNode, pixels }: { editMode: EditMode; setEditMode: (mode: EditMode) => void; selectedColor: string; onColorSelect: (color: string) => void; tool: PaintTool; setTool: (tool: PaintTool) => void; onDragStartNode: (e: React.DragEvent, type: NodeType) => void; pixels: Map<string, string> }) => {
  const nodeCategories = {
    source: { name: "能量源", types: ["energy"] as NodeType[] },
    modifier: { name: "修饰符", types: ["modifier"] as NodeType[] },
    projectile: { name: "投射物", types: ["projectile"] as NodeType[] },
    trigger: { name: "触发器", types: ["trigger"] as NodeType[] },
    multicast: { name: "多重施法", types: ["multicast"] as NodeType[] },
  };

  return (
    <motion.aside initial={{ x: -20, opacity: 0 }} animate={{ x: 0, opacity: 1 }} className="w-64 border-r border-white/10 flex flex-col bg-[#1a1525]/80 backdrop-blur-xl">
      <div className="p-3 border-b border-white/10">
        <div className="flex gap-1.5 p-1 rounded-xl bg-white/10">
          {[{ id: "appearance" as EditMode, label: "外观编辑", icon: <Sparkles className="w-3.5 h-3.5" /> }, { id: "nodes" as EditMode, label: "节点编辑", icon: <GitBranch className="w-3.5 h-3.5" /> }].map((tab) => (
            <motion.button key={tab.id} onClick={() => setEditMode(tab.id)} whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}
              className={cn("flex-1 px-3 py-2 rounded-lg text-xs font-medium flex items-center justify-center gap-1.5 transition-all",
                editMode === tab.id ? "bg-gradient-to-r from-purple-500/40 to-pink-500/40 text-white shadow-lg border border-purple-400/50" : "text-white/50 hover:text-white/80")}>
              {tab.icon}{tab.label}
            </motion.button>
          ))}
        </div>
      </div>
      <div className="flex-1 overflow-y-auto p-3">
        <AnimatePresence mode="wait">
          {editMode === "appearance" ? (
            <motion.div key="appearance" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -10 }} className="space-y-4">
              <div className="flex items-center justify-center p-4 rounded-xl bg-white/5 border border-white/10">
                <WandPreview pixels={pixels} />
              </div>
              <div>
                <div className="flex items-center gap-2 mb-2"><Paintbrush className="w-4 h-4 text-purple-300" /><h3 className="text-xs font-medium text-white/70">工具</h3></div>
                <div className="flex gap-1.5">
                  <motion.button onClick={() => setTool("brush")} whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}
                    className={cn("flex-1 px-3 py-2 rounded-lg text-xs font-medium flex items-center justify-center gap-1.5 transition-all",
                      tool === "brush" ? "bg-purple-500/40 text-white border border-purple-400/50" : "bg-white/10 text-white/60 hover:text-white")}>
                    <Paintbrush className="w-3.5 h-3.5" />画笔
                  </motion.button>
                  <motion.button onClick={() => setTool("eraser")} whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}
                    className={cn("flex-1 px-3 py-2 rounded-lg text-xs font-medium flex items-center justify-center gap-1.5 transition-all",
                      tool === "eraser" ? "bg-red-500/40 text-white border border-red-400/50" : "bg-white/10 text-white/60 hover:text-white")}>
                    <Eraser className="w-3.5 h-3.5" />橡皮
                  </motion.button>
                </div>
              </div>
              {COLOR_PALETTES.map((palette, pIndex) => (
                <div key={pIndex}>
                  <div className="flex items-center gap-2 mb-2">
                    <div className="w-4 h-4 rounded-full" style={{ background: `linear-gradient(135deg, ${palette.colors[0]}, ${palette.colors[palette.colors.length - 1]})` }} />
                    <h3 className="text-xs font-medium text-white/70">{palette.name}</h3>
                  </div>
                  <div className="grid grid-cols-8 gap-1">
                    {palette.colors.map((color, index) => (
                      <motion.button key={index} onClick={() => { onColorSelect(color); setTool("brush"); }}
                        whileHover={{ scale: 1.2, y: -2 }} whileTap={{ scale: 0.9 }}
                        className="aspect-square rounded-lg relative overflow-hidden"
                        style={{ background: color, boxShadow: selectedColor === color ? `0 0 12px ${color}, 0 0 24px ${color}60` : `0 0 4px ${color}40` }}>
                        {selectedColor === color && <motion.div className="absolute inset-0 flex items-center justify-center bg-black/20" initial={{ opacity: 0 }} animate={{ opacity: 1 }}><Sparkles className="w-3 h-3 text-white drop-shadow-lg" /></motion.div>}
                      </motion.button>
                    ))}
                  </div>
                </div>
              ))}
              <motion.div className="p-3 rounded-xl bg-white/10 border border-white/15" initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
                <div className="flex items-center gap-3">
                  <motion.div className="w-10 h-10 rounded-lg" style={{ background: selectedColor, boxShadow: `0 0 20px ${selectedColor}80` }}
                    animate={{ boxShadow: [`0 0 15px ${selectedColor}60`, `0 0 25px ${selectedColor}a0`, `0 0 15px ${selectedColor}60`] }} transition={{ duration: 2, repeat: Infinity }} />
                  <div><p className="text-xs text-white/50">当前颜色</p><p className="text-sm font-medium text-white/90">{selectedColor}</p></div>
                </div>
              </motion.div>
            </motion.div>
          ) : (
            <motion.div key="nodes" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -10 }}>
              <div className="flex items-center gap-2 mb-2"><GitBranch className="w-4 h-4 text-cyan-300" /><h3 className="text-xs font-medium text-white/70">节点库</h3></div>
              <p className="text-xs text-white/40 mb-3">拖拽节点到右侧画布</p>
              {Object.entries(nodeCategories).map(([catKey, catInfo]) => (
                <div key={catKey} className="mb-4">
                  <p className="text-[10px] text-white/30 uppercase tracking-wider mb-2">{catInfo.name}</p>
                  <div className="space-y-2">
                    {catInfo.types.map((type) => (
                      <DraggableNodeItem key={type} type={type} nodeInfo={NODE_TYPES[type]} onDragStart={onDragStartNode} />
                    ))}
                  </div>
                </div>
              ))}
              <div className="mt-4 p-3 rounded-xl bg-white/5 border border-white/10">
                <h4 className="text-xs font-medium text-white/60 mb-2">📜 树形逻辑说明</h4>
                <div className="text-[10px] text-white/40 space-y-1">
                  <p>• <span className="text-green-400">能量源</span> → 魔法起点</p>
                  <p>• <span className="text-purple-400">修饰符</span> → 修饰下一个投射物</p>
                  <p>• <span className="text-red-400">投射物</span> → 发射法术</p>
                  <p>• <span className="text-amber-400">触发器</span> → 创建分支逻辑</p>
                  <p>• <span className="text-cyan-400">多重施法</span> → 并行执行</p>
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </motion.aside>
  );
};

// Node Canvas
const NodeCanvas = ({ nodes, connections, selectedNode, connectingFrom, onSelectNode, onStartConnect, onMoveNode, onDeleteNode, onDrop, executingNodes }: { nodes: Node[]; connections: Connection[]; selectedNode: string | null; connectingFrom: string | null; onSelectNode: (id: string | null) => void; onStartConnect: (id: string) => void; onMoveNode: (id: string, x: number, y: number) => void; onDeleteNode: (id: string) => void; onDrop: (type: NodeType, x: number, y: number) => void; executingNodes: Set<string> }) => {
  const canvasRef = useRef<HTMLDivElement>(null);
  const [draggingNode, setDraggingNode] = useState<string | null>(null);
  const [dragOffset, setDragOffset] = useState({ x: 0, y: 0 });

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    const nodeType = e.dataTransfer.getData("nodeType") as NodeType;
    if (nodeType && canvasRef.current) {
      const rect = canvasRef.current.getBoundingClientRect();
      onDrop(nodeType, e.clientX - rect.left, e.clientY - rect.top);
    }
  };
  const handleNodeMouseDown = (e: React.MouseEvent, nodeId: string) => {
    e.stopPropagation();
    const node = nodes.find(n => n.id === nodeId);
    if (!node || !canvasRef.current) return;
    const rect = canvasRef.current.getBoundingClientRect();
    setDragOffset({ x: e.clientX - rect.left - node.x, y: e.clientY - rect.top - node.y });
    setDraggingNode(nodeId);
    onSelectNode(nodeId);
  };
  const handleMouseMove = (e: React.MouseEvent) => {
    if (!draggingNode || !canvasRef.current) return;
    const rect = canvasRef.current.getBoundingClientRect();
    onMoveNode(draggingNode, Math.max(30, Math.min(e.clientX - rect.left - dragOffset.x, rect.width - 30)), Math.max(30, Math.min(e.clientY - rect.top - dragOffset.y, rect.height - 30)));
  };

  return (
    <div ref={canvasRef} className="relative w-full h-full overflow-hidden" onDragOver={(e) => e.preventDefault()} onDrop={handleDrop}
      onMouseMove={handleMouseMove} onMouseUp={() => setDraggingNode(null)} onMouseLeave={() => setDraggingNode(null)} onClick={() => onSelectNode(null)}>
      <div className="absolute inset-0 opacity-30" style={{ backgroundImage: "radial-gradient(circle, rgba(139, 92, 246, 0.4) 1px, transparent 1px)", backgroundSize: "24px 24px" }} />
      <svg className="absolute inset-0 w-full h-full pointer-events-none">
        <defs><filter id="connGlow"><feGaussianBlur stdDeviation="2" result="blur" /><feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge></filter></defs>
        {connections.map((conn, idx) => {
          const fromNode = nodes.find(n => n.id === conn.from);
          const toNode = nodes.find(n => n.id === conn.to);
          if (!fromNode || !toNode) return null;
          const colors = { start: NODE_TYPES[fromNode.type].color, end: NODE_TYPES[toNode.type].color };
          const gradId = `grad-${idx}`;
          const midX = (fromNode.x + toNode.x) / 2;
          const d = `M ${fromNode.x} ${fromNode.y} C ${midX} ${fromNode.y}, ${midX} ${toNode.y}, ${toNode.x} ${toNode.y}`;
          return (
            <g key={idx}>
              <defs><linearGradient id={gradId} x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" stopColor={colors.start} /><stop offset="100%" stopColor={colors.end} /></linearGradient></defs>
              <motion.path d={d} fill="none" stroke={`url(#${gradId})`} strokeWidth="2.5" filter="url(#connGlow)" initial={{ pathLength: 0 }} animate={{ pathLength: 1 }} />
              <motion.circle r="4" fill={colors.start} filter="url(#connGlow)" initial={{ offsetDistance: "0%" }} animate={{ offsetDistance: "100%" }} transition={{ duration: 1.5, repeat: Infinity, ease: "linear" }} style={{ offsetPath: `path("${d}")` }} />
            </g>
          );
        })}
      </svg>
      <AnimatePresence>
        {nodes.map((node) => {
          const nodeInfo = NODE_TYPES[node.type];
          const isSelected = selectedNode === node.id;
          const isConnecting = connectingFrom === node.id;
          const isExecuting = executingNodes.has(node.id);
          return (
            <motion.div key={node.id} className="absolute cursor-move" style={{ left: node.x - 28, top: node.y - 28 }}
              initial={{ scale: 0, opacity: 0 }} animate={{ scale: isSelected ? 1.05 : 1, opacity: 1 }} exit={{ scale: 0, opacity: 0 }}
              onMouseDown={(e) => handleNodeMouseDown(e, node.id)}>
              <motion.div className="absolute inset-0 rounded-xl" style={{ background: nodeInfo.glow, filter: "blur(12px)" }}
                animate={isExecuting ? { scale: [1, 1.5, 1], opacity: [0.4, 0.9, 0.4] } : { scale: [1, 1.15, 1], opacity: [0.4, 0.6, 0.4] }}
                transition={isExecuting ? { duration: 0.3, repeat: 3 } : { duration: 2, repeat: Infinity }} />
              <div className={cn("relative w-14 h-14 rounded-xl flex items-center justify-center border-2 backdrop-blur-sm transition-all", isSelected && "border-white/80", isConnecting && "border-amber-400", isExecuting && "ring-2 ring-white/50")}
                style={{ background: `linear-gradient(135deg, ${nodeInfo.color}${isExecuting ? "50" : "30"}, ${nodeInfo.color}15)`, borderColor: isSelected ? "rgba(255,255,255,0.8)" : `${nodeInfo.color}70`, boxShadow: `0 0 ${isExecuting ? "30" : "20"}px ${nodeInfo.glow}, inset 0 1px 0 rgba(255,255,255,0.15)` }}>
                <span style={{ color: nodeInfo.color }}>{nodeInfo.icon}</span>
                <div className="absolute -bottom-2 left-1/2 -translate-x-1/2 px-2 py-0.5 rounded-lg text-[10px] font-bold whitespace-nowrap shadow-lg" style={{ background: nodeInfo.color, color: "white" }}>
                  {node.type.charAt(0).toUpperCase()}
                </div>
              </div>
              <motion.div className={cn("absolute -left-2 top-1/2 -translate-y-1/2 w-4 h-4 rounded-full border-2 cursor-pointer backdrop-blur-sm", isConnecting ? "bg-amber-400 border-amber-300" : "bg-[#1a1525] border-gray-500 hover:border-emerald-400")}
                whileHover={{ scale: 1.3 }} onClick={(e) => { e.stopPropagation(); if (connectingFrom && connectingFrom !== node.id) onStartConnect(node.id); }} />
              <motion.div className="absolute -right-2 top-1/2 -translate-y-1/2 w-4 h-4 rounded-full border-2 bg-[#1a1525] border-gray-500 hover:border-blue-400 cursor-pointer backdrop-blur-sm"
                whileHover={{ scale: 1.3 }} onClick={(e) => { e.stopPropagation(); onStartConnect(node.id); }} />
              {node.type === "trigger" && (
                <motion.div className="absolute -bottom-4 left-1/2 -translate-x-1/2 w-4 h-4 rounded-full border-2 bg-[#1a1525] border-amber-500/50 hover:border-amber-400 cursor-pointer backdrop-blur-sm"
                  whileHover={{ scale: 1.3 }} onClick={(e) => { e.stopPropagation(); onStartConnect(node.id); }} />
              )}
              {node.type === "multicast" && (
                <>
                  <motion.div className="absolute -right-2 top-1/4 -translate-y-1/2 w-3 h-3 rounded-full border-2 bg-[#1a1525] border-cyan-500/50 hover:border-cyan-400 cursor-pointer backdrop-blur-sm" whileHover={{ scale: 1.3 }} onClick={(e) => { e.stopPropagation(); onStartConnect(node.id); }} />
                  <motion.div className="absolute -right-2 top-3/4 -translate-y-1/2 w-3 h-3 rounded-full border-2 bg-[#1a1525] border-cyan-500/50 hover:border-cyan-400 cursor-pointer backdrop-blur-sm" whileHover={{ scale: 1.3 }} onClick={(e) => { e.stopPropagation(); onStartConnect(node.id); }} />
                </>
              )}
              {isSelected && (
                <motion.button className="absolute -top-2 -right-2 w-5 h-5 rounded-full bg-gradient-to-br from-red-500 to-rose-600 flex items-center justify-center text-white text-xs shadow-lg shadow-red-500/40"
                  initial={{ scale: 0 }} animate={{ scale: 1 }} whileHover={{ scale: 1.2 }} onClick={(e) => { e.stopPropagation(); onDeleteNode(node.id); }}>×</motion.button>
              )}
            </motion.div>
          );
        })}
      </AnimatePresence>
      {nodes.length === 0 && (
        <motion.div className="absolute inset-0 flex items-center justify-center pointer-events-none" initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
          <div className="text-center">
            <div className="w-16 h-16 rounded-2xl bg-white/10 border border-white/15 flex items-center justify-center mx-auto mb-4"><GitBranch className="w-8 h-8 text-white/30" /></div>
            <p className="text-sm text-white/50">从左侧拖拽节点到此处</p>
            <p className="text-xs text-white/30 mt-1">构建树形法术逻辑</p>
          </div>
        </motion.div>
      )}
    </div>
  );
};

// Main Editor
const MainEditor = ({ editMode, pixels, selectedColor, tool, onPixelDraw, onClearPixels, nodes, connections, selectedNode, connectingFrom, onSelectNode, onStartConnect, onMoveNode, onDeleteNode, onDropNode, executingNodes }: { editMode: EditMode; pixels: Map<string, string>; selectedColor: string; tool: PaintTool; onPixelDraw: (x: number, y: number) => void; onClearPixels: () => void; nodes: Node[]; connections: Connection[]; selectedNode: string | null; connectingFrom: string | null; onSelectNode: (id: string | null) => void; onStartConnect: (id: string) => void; onMoveNode: (id: string, x: number, y: number) => void; onDeleteNode: (id: string) => void; onDropNode: (type: NodeType, x: number, y: number) => void; executingNodes: Set<string> }) => (
  <motion.main initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="flex-1 flex items-center justify-center p-6 overflow-hidden">
    <AnimatePresence mode="wait">
      {editMode === "appearance" ? (
        <motion.div key="appearance" className="w-full h-full flex items-center justify-center" initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.95 }}>
          <PixelCanvas pixels={pixels} selectedColor={selectedColor} tool={tool} onPixelDraw={onPixelDraw} onClear={onClearPixels} />
        </motion.div>
      ) : (
        <motion.div key="nodes" className="w-full h-full rounded-2xl border border-white/15 overflow-hidden bg-[#1a1525]/60 backdrop-blur-sm"
          initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} style={{ boxShadow: "inset 0 0 60px rgba(139, 92, 246, 0.08)" }}>
          <NodeCanvas nodes={nodes} connections={connections} selectedNode={selectedNode} connectingFrom={connectingFrom}
            onSelectNode={onSelectNode} onStartConnect={onStartConnect} onMoveNode={onMoveNode} onDeleteNode={onDeleteNode} onDrop={onDropNode} executingNodes={executingNodes} />
        </motion.div>
      )}
    </AnimatePresence>
  </motion.main>
);

// Property Panel
const PropertyPanel = ({ wandState }: { wandState: WandState }) => {
  const properties = [
    { icon: <Star className="w-3.5 h-3.5" />, label: "等级", value: wandState.level, color: "text-amber-400" },
    { icon: <Clock className="w-3.5 h-3.5" />, label: "施法延迟", value: `${wandState.castDelay.toFixed(2)}s`, color: "text-cyan-300" },
    { icon: <Clock className="w-3.5 h-3.5" />, label: "充能时间", value: `${wandState.chargeTime.toFixed(2)}s`, color: "text-blue-300" },
    { icon: <Droplets className="w-3.5 h-3.5" />, label: "法力容量", value: wandState.manaCapacity, color: "text-blue-200" },
    { icon: <Zap className="w-3.5 h-3.5" />, label: "法力回复", value: `${wandState.manaRegen}/s`, color: "text-purple-300" },
    { icon: <Battery className="w-3.5 h-3.5" />, label: "充能回复", value: `+${wandState.chargeRegen}`, color: "text-emerald-300" },
  ];

  return (
    <motion.aside initial={{ x: 20, opacity: 0 }} animate={{ x: 0, opacity: 1 }} className="w-64 border-l border-white/10 overflow-y-auto bg-[#1a1525]/80 backdrop-blur-xl">
      <div className="p-3 border-b border-white/10">
        <div className="flex items-center gap-2 mb-3"><Crown className="w-4 h-4 text-purple-300" /><h2 className="text-xs font-medium text-white/70">法杖详细属性</h2></div>
        <div className="space-y-1">
          {properties.map((prop, i) => (
            <motion.div key={i} className="flex items-center gap-2 p-2 rounded-lg hover:bg-white/5 transition-colors" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: i * 0.03 }}>
              <span className={prop.color}>{prop.icon}</span>
              <span className="text-xs text-white/50 flex-1">{prop.label}</span>
              <span className="text-xs font-medium text-white/90">{prop.value}</span>
            </motion.div>
          ))}
        </div>
      </div>
      <div className="p-3">
        <div className="flex items-center gap-2 mb-3"><Gauge className="w-4 h-4 text-cyan-300" /><h2 className="text-xs font-medium text-white/70">实时状态</h2></div>
        <div className="space-y-3">
          <div className="p-3 rounded-xl bg-white/10 border border-white/10">
            <div className="flex items-center justify-between mb-2"><span className="text-xs text-white/50">已用节点</span><span className="text-sm font-bold text-cyan-300">{wandState.usedNodes} / {wandState.logicCapacity}</span></div>
            <div className="h-1.5 bg-white/10 rounded-full overflow-hidden"><motion.div className="h-full rounded-full bg-gradient-to-r from-cyan-500 to-blue-500" initial={{ width: 0 }} animate={{ width: `${(wandState.usedNodes / wandState.logicCapacity) * 100}%` }} /></div>
          </div>
          {wandState.usedNodes >= wandState.logicCapacity && (
            <motion.div className="p-3 rounded-xl bg-red-500/20 border border-red-500/30" initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }}>
              <div className="flex items-center gap-2 text-red-400"><AlertTriangle className="w-3.5 h-3.5" /><span className="text-xs">节点容量已满</span></div>
            </motion.div>
          )}
        </div>
      </div>
    </motion.aside>
  );
};

// Spell Execution Engine
class SpellEngine {
  nodes: Node[];
  connections: Connection[];
  
  constructor(nodes: Node[], connections: Connection[]) {
    this.nodes = nodes;
    this.connections = connections;
  }

  findEnergySource(): Node | undefined { return this.nodes.find(n => n.type === "energy"); }
  getConnectedNodes(nodeId: string): Node[] {
    return this.connections.filter(c => c.from === nodeId).map(c => this.nodes.find(n => n.id === c.to)).filter(Boolean) as Node[];
  }

  async execute(onNodeExecute: (nodeId: string) => void): Promise<SpellResult> {
    const result: SpellResult = { projectiles: [], totalMana: 0, totalDamage: 0, castTime: 0, executionLog: [] };
    const energySource = this.findEnergySource();
    if (!energySource) { result.executionLog.push("❌ 未找到能量源节点"); return result; }

    const mainProjectiles = await this.executeBranch(energySource, [], result, onNodeExecute);
    result.projectiles = mainProjectiles;
    result.totalDamage = mainProjectiles.reduce((sum, p) => sum + p.damage, 0);
    return result;
  }

  async executeBranch(node: Node, modifiers: string[], result: SpellResult, onNodeExecute: (nodeId: string) => void): Promise<ProjectileInfo[]> {
    const projectiles: ProjectileInfo[] = [];
    onNodeExecute(node.id);
    await this.delay(100);

    switch (node.type) {
      case "energy": {
        result.totalMana += 10;
        const nextNodes = this.getConnectedNodes(node.id);
        for (const nextNode of nextNodes) {
          projectiles.push(...await this.executeBranch(nextNode, [], result, onNodeExecute));
        }
        break;
      }
      case "modifier": {
        const modifiedNext = this.getConnectedNodes(node.id);
        for (const nextNode of modifiedNext) {
          projectiles.push(...await this.executeBranch(nextNode, [...modifiers, NODE_TYPES[node.type].label], result, onNodeExecute));
        }
        break;
      }
      case "projectile": {
        projectiles.push({ id: `proj-${Date.now()}`, modifiers: [...modifiers], damage: 10 * (modifiers.length + 1), x: 50, y: 280, vx: 3, vy: -2 });
        result.totalMana += 5 + modifiers.length * 2;
        break;
      }
      case "trigger": {
        const triggerProjectile: ProjectileInfo = { id: `trigger-${Date.now()}`, modifiers: [...modifiers, "触发器"], damage: 5 * (modifiers.length + 1), x: 50, y: 280, vx: 3, vy: -2 };
        const triggerBranches = this.getConnectedNodes(node.id);
        const triggerProjs: ProjectileInfo[] = [];
        for (const branchNode of triggerBranches) {
          triggerProjs.push(...await this.executeBranch(branchNode, [], result, onNodeExecute));
        }
        if (triggerProjs.length > 0) triggerProjectile.triggerProjectiles = triggerProjs;
        projectiles.push(triggerProjectile);
        result.totalMana += 15;
        break;
      }
      case "multicast": {
        const multicastBranches = this.getConnectedNodes(node.id);
        for (const branchNode of multicastBranches) {
          projectiles.push(...await this.executeBranch(branchNode, [...modifiers], result, onNodeExecute));
        }
        result.totalMana += 20;
        break;
      }
    }
    return projectiles;
  }

  delay(ms: number): Promise<void> { return new Promise(resolve => setTimeout(resolve, ms)); }
}

// Main Page
export default function WandEditorPage() {
  const [wands, setWands] = useState<WandData[]>(DEFAULT_WANDS);
  const [currentWandId, setCurrentWandId] = useState<string>(DEFAULT_WANDS[0].id);
  const [editMode, setEditMode] = useState<EditMode>("appearance");
  const [selectedColor, setSelectedColor] = useState(COLOR_PALETTES[2].colors[0]);
  const [tool, setTool] = useState<PaintTool>("brush");
  const [pixels, setPixels] = useState<Map<string, string>>(new Map());
  const [nodes, setNodes] = useState<Node[]>([]);
  const [connections, setConnections] = useState<Connection[]>([]);
  const [selectedNode, setSelectedNode] = useState<string | null>(null);
  const [connectingFrom, setConnectingFrom] = useState<string | null>(null);
  const [isTesting, setIsTesting] = useState(false);
  const [executingNodes, setExecutingNodes] = useState<Set<string>>(new Set());
  const [spellResult, setSpellResult] = useState<SpellResult | null>(null);
  const [showTestPanel, setShowTestPanel] = useState(false);
  const [showWandSelect, setShowWandSelect] = useState(false);

  // Get current wand
  const currentWand = wands.find(w => w.id === currentWandId) || wands[0];

  // Load wand data when switching
  useEffect(() => {
    // Defer to avoid synchronous setState in effect
    const loadId = setTimeout(() => {
      setPixels(new Map(currentWand.pixels));
      setNodes(currentWand.nodes);
      setConnections(currentWand.connections);
    }, 0);
    return () => clearTimeout(loadId);
  }, [currentWandId]);

  // Save current wand data
  const saveCurrentWand = useCallback(() => {
    setWands(prev => prev.map(w => 
      w.id === currentWandId 
        ? { ...w, pixels: Array.from(pixels.entries()), nodes, connections }
        : w
    ));
  }, [currentWandId, pixels, nodes, connections]);

  // Wand state for display
  const wandState: WandState = {
    name: currentWand.name,
    level: currentWand.level,
    castDelay: currentWand.castDelay,
    chargeTime: currentWand.chargeTime,
    manaCapacity: currentWand.manaCapacity,
    manaRegen: currentWand.manaRegen,
    chargeRegen: currentWand.chargeRegen,
    logicCapacity: currentWand.logicCapacity,
    usedNodes: nodes.length,
    appearanceModules: pixels.size,
  };

  const handlePixelDraw = useCallback((x: number, y: number) => {
    const key = `${x},${y}`;
    setPixels(prev => {
      const newPixels = new Map(prev);
      if (tool === "eraser") newPixels.delete(key);
      else if (newPixels.get(key) === selectedColor) newPixels.delete(key);
      else newPixels.set(key, selectedColor);
      return newPixels;
    });
  }, [selectedColor, tool]);

  const handleDropNode = useCallback((type: NodeType, x: number, y: number) => {
    if (nodes.length >= currentWand.logicCapacity) return;
    setNodes(prev => [...prev, { id: `node-${Date.now()}`, type, x, y }]);
  }, [nodes.length, currentWand.logicCapacity]);

  const handleMoveNode = useCallback((id: string, x: number, y: number) => {
    setNodes(prev => prev.map(node => node.id === id ? { ...node, x, y } : node));
  }, []);

  const handleDeleteNode = useCallback((id: string) => {
    setNodes(prev => prev.filter(node => node.id !== id));
    setConnections(prev => prev.filter(conn => conn.from !== id && conn.to !== id));
    setSelectedNode(null);
  }, []);

  const handleStartConnect = useCallback((id: string) => {
    if (connectingFrom === null) setConnectingFrom(id);
    else if (connectingFrom !== id) {
      const exists = connections.some(conn => (conn.from === connectingFrom && conn.to === id) || (conn.from === id && conn.to === connectingFrom));
      if (!exists) setConnections(prev => [...prev, { from: connectingFrom, to: id }]);
      setConnectingFrom(null);
    } else setConnectingFrom(null);
  }, [connectingFrom, connections]);

  // Test spell
  const handleTestSpell = useCallback(async () => {
    if (nodes.length === 0 || !nodes.some(n => n.type === "energy")) return;
    
    saveCurrentWand();
    setIsTesting(true);
    setExecutingNodes(new Set());
    
    const engine = new SpellEngine(nodes, connections);
    const result = await engine.execute((nodeId) => {
      setExecutingNodes(prev => new Set(prev).add(nodeId));
    });
    
    setSpellResult(result);
    setShowTestPanel(true);
    
    setTimeout(() => setExecutingNodes(new Set()), 500);
  }, [nodes, connections, saveCurrentWand]);

  // Stop test
  const handleStopTest = useCallback(() => {
    setIsTesting(false);
    setShowTestPanel(false);
    setSpellResult(null);
  }, []);

  // Switch wand
  const handleSelectWand = useCallback((wand: WandData) => {
    saveCurrentWand();
    setCurrentWandId(wand.id);
    setShowWandSelect(false);
  }, [saveCurrentWand]);

  // Create new wand
  const handleCreateWand = useCallback(() => {
    const newId = `wand-${Date.now()}`;
    const newWand: WandData = {
      id: newId,
      name: `New Wand ${wands.length + 1}`,
      level: 1,
      castDelay: 0.25,
      chargeTime: 0.5,
      manaCapacity: 80,
      manaRegen: 40,
      chargeRegen: 30,
      logicCapacity: 5,
      pixels: [],
      nodes: [],
      connections: [],
    };
    setWands(prev => [...prev, newWand]);
    setCurrentWandId(newId);
    setShowWandSelect(false);
  }, [wands.length]);

  // Save on unmount
  useEffect(() => {
    return () => saveCurrentWand();
  }, [saveCurrentWand]);

  return (
    <div className="min-h-screen flex flex-col">
      <MagicBackground />
      <Header wandState={wandState} onTestSpell={handleTestSpell} onStopTest={handleStopTest} isTesting={isTesting} onOpenWandSelect={() => setShowWandSelect(true)} />
      <div className="flex-1 flex overflow-hidden">
        <Sidebar editMode={editMode} setEditMode={setEditMode} selectedColor={selectedColor} onColorSelect={setSelectedColor}
          tool={tool} setTool={setTool} onDragStartNode={(e, type) => { e.dataTransfer.setData("nodeType", type); e.dataTransfer.effectAllowed = "copy"; }} pixels={pixels} />
        <MainEditor editMode={editMode} pixels={pixels} selectedColor={selectedColor} tool={tool} onPixelDraw={handlePixelDraw}
          onClearPixels={() => setPixels(new Map())} nodes={nodes} connections={connections} selectedNode={selectedNode}
          connectingFrom={connectingFrom} onSelectNode={setSelectedNode} onStartConnect={handleStartConnect}
          onMoveNode={handleMoveNode} onDeleteNode={handleDeleteNode} onDropNode={handleDropNode} executingNodes={executingNodes} />
        <PropertyPanel wandState={wandState} />
      </div>
      
      <AnimatePresence>
        {showTestPanel && spellResult && (
          <SpellTestVisualizer isVisible={showTestPanel} result={spellResult} onClose={handleStopTest} castDelay={currentWand.castDelay} />
        )}
      </AnimatePresence>
      
      <AnimatePresence>
        {showWandSelect && (
          <WandSelectModal
            isVisible={showWandSelect}
            wands={wands}
            currentWandId={currentWandId}
            onSelectWand={handleSelectWand}
            onCreateWand={handleCreateWand}
            onDeleteWand={() => {}}
            onClose={() => setShowWandSelect(false)}
          />
        )}
      </AnimatePresence>
    </div>
  );
}

'use client'

import { useState, useEffect, useRef, useCallback } from 'react'
import { motion, AnimatePresence, useAnimation } from 'framer-motion'
import { 
  Sparkles, 
  Sword, 
  Shield, 
  Gem, 
  FlaskConical, 
  Scroll,
  Coins,
  Package,
  Zap,
  Star,
  Heart,
  Brain,
  Dumbbell,
  Footprints,
  X,
  Plus,
  Settings,
  RefreshCw,
  ChevronDown,
  Wand2,
  Flame,
  Droplets,
  Wind,
  Crown,
  Target,
  Hammer,
  Trash2,
  Check,
  Lock
} from 'lucide-react'

// 物品类型定义
interface Item {
  id: string
  name: string
  icon: React.ReactNode
  rarity: 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary'
  quantity: number
  description: string
  stats?: { name: string; value: string }[]
  level?: number
  type?: 'weapon' | 'armor' | 'consumable' | 'material' | 'accessory'
  equipSlot?: string
}

// 背包格子类型
interface InventorySlot {
  item: Item | null
  locked: boolean
}

// 合成配方类型
interface CraftingRecipe {
  id: string
  name: string
  ingredients: { itemId: string; quantity: number }[]
  result: Item
  description: string
}

// 稀有度颜色配置
const rarityColors = {
  common: { bg: 'from-slate-600/50 to-slate-700/50', border: 'border-slate-500', glow: 'shadow-slate-500/30', text: 'text-slate-300' },
  uncommon: { bg: 'from-green-600/50 to-green-700/50', border: 'border-green-500', glow: 'shadow-green-500/30', text: 'text-green-300' },
  rare: { bg: 'from-blue-600/50 to-blue-700/50', border: 'border-blue-500', glow: 'shadow-blue-500/30', text: 'text-blue-300' },
  epic: { bg: 'from-purple-600/50 to-purple-700/50', border: 'border-purple-500', glow: 'shadow-purple-500/30', text: 'text-purple-300' },
  legendary: { bg: 'from-amber-600/50 to-orange-700/50', border: 'border-amber-500', glow: 'shadow-amber-500/30', text: 'text-amber-300' },
}

// 示例物品数据
const sampleItems: Item[] = [
  { id: '1', name: '魔法水晶', icon: <Gem className="w-6 h-6" />, rarity: 'epic', quantity: 5, description: '蕴含强大魔力的水晶，可用于附魔装备', stats: [{ name: '魔力', value: '+50' }], type: 'material' },
  { id: '2', name: '生命药水', icon: <FlaskConical className="w-6 h-6" />, rarity: 'uncommon', quantity: 10, description: '恢复100点生命值', stats: [{ name: '生命恢复', value: '100' }], type: 'consumable' },
  { id: '3', name: '火焰剑', icon: <Sword className="w-6 h-6" />, rarity: 'legendary', quantity: 1, description: '传说中的火焰之剑，燃烧一切', stats: [{ name: '攻击力', value: '+120' }, { name: '火焰伤害', value: '+50' }], level: 50, type: 'weapon', equipSlot: 'weapon' },
  { id: '4', name: '龙鳞盾', icon: <Shield className="w-6 h-6" />, rarity: 'rare', quantity: 1, description: '由古龙鳞片制成的坚盾', stats: [{ name: '防御力', value: '+80' }], level: 35, type: 'armor', equipSlot: 'offhand' },
  { id: '5', name: '魔法卷轴', icon: <Scroll className="w-6 h-6" />, rarity: 'common', quantity: 3, description: '记载着神秘魔法的卷轴', type: 'consumable' },
  { id: '6', name: '星辰碎片', icon: <Star className="w-6 h-6" />, rarity: 'epic', quantity: 7, description: '从陨石中提炼的神秘物质', stats: [{ name: '全属性', value: '+5' }], type: 'material' },
  { id: '7', name: '闪电符文', icon: <Zap className="w-6 h-6" />, rarity: 'rare', quantity: 2, description: '蕴含闪电之力的符文石', type: 'material' },
  { id: '8', name: '永恒之心', icon: <Heart className="w-6 h-6" />, rarity: 'legendary', quantity: 1, description: '传说中能赋予永生的神秘物品', stats: [{ name: '生命上限', value: '+500' }, { name: '生命恢复', value: '+10/s' }], level: 80, type: 'accessory', equipSlot: 'accessory' },
  { id: '9', name: '火焰精华', icon: <Flame className="w-6 h-6" />, rarity: 'rare', quantity: 4, description: '纯净的火焰元素精华', type: 'material' },
  { id: '10', name: '水之宝石', icon: <Droplets className="w-6 h-6" />, rarity: 'uncommon', quantity: 6, description: '蕴含水之力的宝石', type: 'material' },
  { id: '11', name: '风之羽', icon: <Wind className="w-6 h-6" />, rarity: 'uncommon', quantity: 8, description: '传说中风神遗落的羽毛', type: 'material' },
  { id: '12', name: '王者之冠', icon: <Crown className="w-6 h-6" />, rarity: 'legendary', quantity: 1, description: '古代王者佩戴的神秘皇冠', stats: [{ name: '全属性', value: '+20' }, { name: '领导力', value: '+100' }], level: 70, type: 'armor', equipSlot: 'helmet' },
]

// 合成配方
const craftingRecipes: CraftingRecipe[] = [
  {
    id: 'fire-sword',
    name: '烈焰大剑',
    description: '将火焰精华注入魔法水晶，打造出燃烧的剑刃',
    ingredients: [
      { itemId: '9', quantity: 3 }, // 火焰精华
      { itemId: '1', quantity: 2 }, // 魔法水晶
      { itemId: '7', quantity: 1 }, // 闪电符文
    ],
    result: {
      id: 'fire-sword-crafted',
      name: '烈焰大剑',
      icon: <Sword className="w-6 h-6" />,
      rarity: 'epic',
      quantity: 1,
      description: '通过合成打造的烈焰大剑，散发着灼热的气息',
      stats: [{ name: '攻击力', value: '+80' }, { name: '火焰伤害', value: '+30' }],
      level: 40,
      type: 'weapon',
      equipSlot: 'weapon'
    }
  },
  {
    id: 'magic-elixir',
    name: '魔力灵药',
    description: '混合多种精华制作的高级药水',
    ingredients: [
      { itemId: '10', quantity: 2 }, // 水之宝石
      { itemId: '6', quantity: 1 },  // 星辰碎片
      { itemId: '2', quantity: 3 },  // 生命药水
    ],
    result: {
      id: 'magic-elixir-crafted',
      name: '魔力灵药',
      icon: <FlaskConical className="w-6 h-6" />,
      rarity: 'rare',
      quantity: 1,
      description: '恢复300点生命值和100点魔力值',
      stats: [{ name: '生命恢复', value: '300' }, { name: '魔力恢复', value: '100' }],
      type: 'consumable'
    }
  },
  {
    id: 'wind-boots',
    name: '疾风之靴',
    description: '使用风之羽制作的轻盈靴子',
    ingredients: [
      { itemId: '11', quantity: 5 }, // 风之羽
      { itemId: '1', quantity: 1 },  // 魔法水晶
    ],
    result: {
      id: 'wind-boots-crafted',
      name: '疾风之靴',
      icon: <Footprints className="w-6 h-6" />,
      rarity: 'rare',
      quantity: 1,
      description: '穿上后如风般轻盈',
      stats: [{ name: '移动速度', value: '+30%' }, { name: '闪避', value: '+15%' }],
      level: 30,
      type: 'armor',
      equipSlot: 'boots'
    }
  }
]

// 魔法粒子组件
function MagicParticles({ active = true }: { active?: boolean }) {
  if (!active) return null
  
  return (
    <div className="absolute inset-0 overflow-hidden pointer-events-none">
      {[...Array(20)].map((_, i) => (
        <motion.div
          key={i}
          className="absolute w-1 h-1 bg-purple-400 rounded-full"
          initial={{
            x: Math.random() * 100 + '%',
            y: '100%',
            opacity: 0,
            scale: Math.random() * 0.5 + 0.5
          }}
          animate={{
            y: '-10%',
            opacity: [0, 1, 0],
          }}
          transition={{
            duration: Math.random() * 4 + 3,
            repeat: Infinity,
            delay: Math.random() * 2,
            ease: 'easeOut'
          }}
        />
      ))}
    </div>
  )
}

// 魔法光晕背景
function MagicGlow() {
  return (
    <div className="absolute inset-0 overflow-hidden pointer-events-none">
      <motion.div
        className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] rounded-full"
        style={{
          background: 'radial-gradient(circle, rgba(139, 92, 246, 0.15) 0%, rgba(139, 92, 246, 0) 70%)',
        }}
        animate={{
          scale: [1, 1.2, 1],
          opacity: [0.5, 0.8, 0.5]
        }}
        transition={{
          duration: 4,
          repeat: Infinity,
          ease: 'easeInOut'
        }}
      />
    </div>
  )
}

// 拖拽预览组件
function DragPreview({ item, position }: { item: Item; position: { x: number; y: number } }) {
  const colors = rarityColors[item.rarity]
  
  return (
    <motion.div
      className="fixed pointer-events-none z-50 w-12 h-12 rounded-lg flex items-center justify-center"
      style={{
        left: position.x - 24,
        top: position.y - 24,
      }}
      initial={{ scale: 1.2, opacity: 0.8 }}
      animate={{ scale: 1.1, opacity: 0.9 }}
    >
      <div className={`absolute inset-0 rounded-lg bg-gradient-to-br ${colors.bg} border ${colors.border}`} />
      <div className={`relative ${colors.text}`}>
        {item.icon}
      </div>
      <motion.div
        className="absolute inset-0 rounded-lg"
        animate={{
          boxShadow: [
            `0 0 10px ${item.rarity === 'legendary' ? 'rgba(245, 158, 11, 0.5)' : 'rgba(139, 92, 246, 0.5)'}`,
            `0 0 20px ${item.rarity === 'legendary' ? 'rgba(245, 158, 11, 0.8)' : 'rgba(139, 92, 246, 0.8)'}`,
          ]
        }}
        transition={{ duration: 0.5, repeat: Infinity, repeatType: 'reverse' }}
      />
    </motion.div>
  )
}

// 背包格子组件
function InventorySlotComponent({ 
  slot, 
  index, 
  onClick, 
  isSelected,
  onDragStart,
  onDragEnd,
  onDragOver,
  onDrop,
  isDragTarget
}: { 
  slot: InventorySlot
  index: number
  onClick: () => void
  isSelected: boolean
  onDragStart: () => void
  onDragEnd: () => void
  onDragOver: (e: React.DragEvent) => void
  onDrop: () => void
  isDragTarget: boolean
}) {
  const rarity = slot.item?.rarity || 'common'
  const colors = rarityColors[rarity]
  const [isDragging, setIsDragging] = useState(false)

  const handleDragStart = (e: React.DragEvent) => {
    if (slot.locked || !slot.item) return
    e.dataTransfer.setData('text/plain', JSON.stringify({ slotIndex: index, item: slot.item }))
    setIsDragging(true)
    onDragStart()
  }

  const handleDragEnd = () => {
    setIsDragging(false)
    onDragEnd()
  }

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault()
    onDrop()
  }

  return (
    <motion.div
      className={`
        relative w-full aspect-square rounded-lg cursor-pointer
        transition-all duration-300 group
        ${slot.locked 
          ? 'bg-slate-900/50 border border-slate-700/50 cursor-not-allowed' 
          : 'bg-gradient-to-br from-slate-800/80 to-slate-900/80 border border-purple-500/30 hover:border-purple-400/60'
        }
        ${isSelected ? 'ring-2 ring-purple-400 scale-105' : ''}
        ${isDragging ? 'opacity-50 scale-95' : ''}
        ${isDragTarget ? 'ring-2 ring-amber-400 scale-105 bg-purple-500/20' : ''}
      `}
      whileHover={!slot.locked ? { scale: 1.05 } : {}}
      whileTap={!slot.locked ? { scale: 0.95 } : {}}
      onClick={onClick}
      draggable={!slot.locked && !!slot.item}
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
      onDragOver={onDragOver}
      onDrop={handleDrop}
      initial={{ opacity: 0, scale: 0.8 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ delay: index * 0.01 }}
    >
      {slot.locked ? (
        <div className="absolute inset-0 flex items-center justify-center">
          <Lock className="w-4 h-4 text-slate-600" />
        </div>
      ) : slot.item ? (
        <>
          {/* 稀有度发光效果 */}
          <motion.div
            className={`absolute inset-0 rounded-lg opacity-0 group-hover:opacity-100 transition-opacity duration-300 ${colors.glow} shadow-lg`}
            animate={{
              boxShadow: [
                `0 0 10px ${rarity === 'legendary' ? 'rgba(245, 158, 11, 0.5)' : rarity === 'epic' ? 'rgba(139, 92, 246, 0.5)' : rarity === 'rare' ? 'rgba(59, 130, 246, 0.5)' : 'transparent'}`,
                `0 0 20px ${rarity === 'legendary' ? 'rgba(245, 158, 11, 0.8)' : rarity === 'epic' ? 'rgba(139, 92, 246, 0.8)' : rarity === 'rare' ? 'rgba(59, 130, 246, 0.8)' : 'transparent'}`,
              ]
            }}
            transition={{ duration: 1, repeat: Infinity, repeatType: 'reverse' }}
          />
          
          {/* 物品图标 */}
          <div className={`
            absolute inset-0 flex items-center justify-center
            ${colors.text}
          `}>
            <motion.div
              animate={{ 
                rotateY: [0, 360],
              }}
              transition={{ duration: 8, repeat: Infinity, ease: 'linear' }}
            >
              {slot.item.icon}
            </motion.div>
          </div>
          
          {/* 数量标签 */}
          {slot.item.quantity > 1 && (
            <div className="absolute bottom-1 right-1 bg-slate-900/90 px-1.5 py-0.5 rounded text-xs font-bold text-white border border-slate-600">
              {slot.item.quantity}
            </div>
          )}
          
          {/* 物品名称提示 */}
          <div className="absolute -bottom-8 left-1/2 -translate-x-1/2 opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap z-10">
            <span className={`text-xs ${colors.text} bg-slate-900/90 px-2 py-1 rounded`}>
              {slot.item.name}
            </span>
          </div>
        </>
      ) : (
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="w-2 h-2 rounded-full bg-slate-700/50" />
        </div>
      )}
    </motion.div>
  )
}

// 物品详情面板
function ItemDetailPanel({ 
  item, 
  onUse,
  onDropIntoSlot 
}: { 
  item: Item | null
  onUse?: () => void
  onDropIntoSlot?: () => void
}) {
  const [isDropTarget, setIsDropTarget] = useState(false)

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDropTarget(true)
  }

  const handleDragLeave = () => {
    setIsDropTarget(false)
  }

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDropTarget(false)
    onDropIntoSlot?.()
  }

  if (!item) {
    return (
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className={`p-4 rounded-xl bg-gradient-to-br from-slate-800/40 to-slate-900/40 border border-purple-500/20 transition-all ${isDropTarget ? 'border-amber-400 bg-amber-500/10' : ''}`}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onDrop={handleDrop}
      >
        <div className="text-center py-8 text-slate-400">
          <Package className="w-12 h-12 mx-auto mb-3 opacity-50" />
          <p>选择或拖拽物品到此处</p>
        </div>
      </motion.div>
    )
  }

  const colors = rarityColors[item.rarity]

  return (
    <motion.div
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: 20 }}
      className={`
        relative p-4 rounded-xl
        bg-gradient-to-br ${colors.bg}
        border ${colors.border}
        shadow-lg ${colors.glow}
      `}
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
    >
      {/* 装饰性魔法符号 */}
      <div className="absolute top-2 right-2 opacity-30">
        <Sparkles className="w-4 h-4" />
      </div>
      
      {/* 物品名称 */}
      <h3 className={`text-lg font-bold ${colors.text} mb-2`}>{item.name}</h3>
      
      {/* 稀有度标签 */}
      <div className={`inline-block px-2 py-0.5 rounded text-xs font-medium mb-3
        ${item.rarity === 'legendary' ? 'bg-amber-500/30 text-amber-200' : ''}
        ${item.rarity === 'epic' ? 'bg-purple-500/30 text-purple-200' : ''}
        ${item.rarity === 'rare' ? 'bg-blue-500/30 text-blue-200' : ''}
        ${item.rarity === 'uncommon' ? 'bg-green-500/30 text-green-200' : ''}
        ${item.rarity === 'common' ? 'bg-slate-500/30 text-slate-200' : ''}
      `}>
        {item.rarity === 'legendary' ? '传说' : 
         item.rarity === 'epic' ? '史诗' : 
         item.rarity === 'rare' ? '稀有' : 
         item.rarity === 'uncommon' ? '精良' : '普通'}
      </div>
      
      {/* 类型标签 */}
      {item.type && (
        <div className="inline-block ml-2 px-2 py-0.5 rounded text-xs font-medium bg-slate-500/30 text-slate-200 mb-3">
          {item.type === 'weapon' ? '武器' :
           item.type === 'armor' ? '护甲' :
           item.type === 'consumable' ? '消耗品' :
           item.type === 'material' ? '材料' : '饰品'}
        </div>
      )}
      
      {/* 等级要求 */}
      {item.level && (
        <p className="text-sm text-slate-400 mb-2">需要等级: {item.level}</p>
      )}
      
      {/* 描述 */}
      <p className="text-sm text-slate-300 mb-3">{item.description}</p>
      
      {/* 属性 */}
      {item.stats && item.stats.length > 0 && (
        <div className="space-y-1 border-t border-slate-600/50 pt-3">
          {item.stats.map((stat, index) => (
            <div key={index} className="flex justify-between text-sm">
              <span className="text-slate-400">{stat.name}</span>
              <span className="text-green-400">{stat.value}</span>
            </div>
          ))}
        </div>
      )}
      
      {/* 使用按钮 */}
      {onUse && (
        <motion.button
          className="w-full mt-4 py-2 rounded-lg bg-gradient-to-r from-purple-600 to-pink-600 text-white font-medium
            hover:from-purple-500 hover:to-pink-500 transition-all duration-300"
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
          onClick={onUse}
        >
          {item.type === 'consumable' ? '使用物品' : item.equipSlot ? '装备' : '使用'}
        </motion.button>
      )}
    </motion.div>
  )
}

// 属性槽位组件
function AttributeSlot({ name, value, icon }: { name: string; value: number; icon: React.ReactNode }) {
  return (
    <motion.div
      className="relative p-3 rounded-lg bg-gradient-to-br from-slate-800/80 to-slate-900/80 border border-purple-500/30"
      whileHover={{ scale: 1.02, borderColor: 'rgba(168, 85, 247, 0.5)' }}
    >
      <div className="flex items-center gap-3">
        <div className="p-2 rounded-lg bg-purple-500/20 text-purple-400">
          {icon}
        </div>
        <div>
          <p className="text-xs text-slate-400 uppercase tracking-wider">{name}</p>
          <p className="text-lg font-bold text-white">{value}</p>
        </div>
      </div>
      
      {/* 魔法闪烁效果 */}
      <motion.div
        className="absolute inset-0 rounded-lg pointer-events-none"
        animate={{
          boxShadow: [
            'inset 0 0 0px rgba(139, 92, 246, 0)',
            'inset 0 0 10px rgba(139, 92, 246, 0.3)',
            'inset 0 0 0px rgba(139, 92, 246, 0)',
          ]
        }}
        transition={{ duration: 2, repeat: Infinity }}
      />
    </motion.div>
  )
}

// 快捷栏组件
function QuickBar({ 
  slots, 
  onDrop, 
  onItemClick 
}: { 
  slots: InventorySlot[]
  onDrop: (index: number) => void
  onItemClick: (index: number) => void
}) {
  const [dragOverIndex, setDragOverIndex] = useState<number | null>(null)

  const handleDragOver = (e: React.DragEvent, index: number) => {
    e.preventDefault()
    setDragOverIndex(index)
  }

  const handleDragLeave = () => {
    setDragOverIndex(null)
  }

  const handleDrop = (e: React.DragEvent, index: number) => {
    e.preventDefault()
    setDragOverIndex(null)
    onDrop(index)
  }

  return (
    <div className="flex gap-2">
      {slots.map((slot, index) => {
        const colors = slot.item ? rarityColors[slot.item.rarity] : null
        
        return (
          <motion.div
            key={index}
            className={`
              relative w-12 h-12 rounded-lg cursor-pointer
              bg-gradient-to-br from-slate-800/80 to-slate-900/80 
              border border-cyan-500/30 hover:border-cyan-400/60
              ${dragOverIndex === index ? 'ring-2 ring-cyan-400 scale-105' : ''}
            `}
            whileHover={{ scale: 1.1 }}
            whileTap={{ scale: 0.95 }}
            onClick={() => onItemClick(index)}
            onDragOver={(e) => handleDragOver(e, index)}
            onDragLeave={handleDragLeave}
            onDrop={(e) => handleDrop(e, index)}
          >
            {slot.item ? (
              <>
                <div className={`absolute inset-0 flex items-center justify-center ${colors?.text}`}>
                  {slot.item.icon}
                </div>
                {slot.item.quantity > 1 && (
                  <div className="absolute bottom-0.5 right-0.5 bg-slate-900/90 px-1 py-0.5 rounded text-[10px] font-bold text-white">
                    {slot.item.quantity}
                  </div>
                )}
                {/* 快捷键提示 */}
                <div className="absolute -top-1 -left-1 w-4 h-4 rounded bg-cyan-600 text-[10px] flex items-center justify-center text-white font-bold">
                  {index + 1}
                </div>
              </>
            ) : (
              <div className="absolute inset-0 flex items-center justify-center text-slate-600">
                <span className="text-xs">{index + 1}</span>
              </div>
            )}
          </motion.div>
        )
      })}
    </div>
  )
}

// 装备槽位组件
function EquipSlot({ 
  slot, 
  slotName, 
  icon,
  onDrop,
  onClick 
}: { 
  slot: InventorySlot
  slotName: string
  icon: React.ReactNode
  onDrop: () => void
  onClick: () => void
}) {
  const [isDragOver, setIsDragOver] = useState(false)
  const colors = slot.item ? rarityColors[slot.item.rarity] : null

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDragOver(true)
  }

  const handleDragLeave = () => {
    setIsDragOver(false)
  }

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDragOver(false)
    onDrop()
  }

  return (
    <motion.div
      className={`
        relative w-14 h-14 rounded-lg cursor-pointer
        bg-gradient-to-br from-slate-800/80 to-slate-900/80 
        border border-purple-500/30 hover:border-purple-400/60
        ${isDragOver ? 'ring-2 ring-purple-400 scale-105 bg-purple-500/20' : ''}
      `}
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
      onClick={onClick}
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
      title={slotName}
    >
      {slot.item ? (
        <div className={`absolute inset-0 flex items-center justify-center ${colors?.text}`}>
          {slot.item.icon}
        </div>
      ) : (
        <div className="absolute inset-0 flex items-center justify-center text-slate-500">
          {icon}
        </div>
      )}
    </motion.div>
  )
}

// 合成面板组件
function CraftingPanel({ 
  isOpen, 
  onClose, 
  inventory,
  onCraft 
}: { 
  isOpen: boolean
  onClose: () => void
  inventory: InventorySlot[]
  onCraft: (recipe: CraftingRecipe) => void
}) {
  const [selectedRecipe, setSelectedRecipe] = useState<CraftingRecipe | null>(null)
  const [isCrafting, setIsCrafting] = useState(false)
  const [craftingProgress, setCraftingProgress] = useState(0)

  const canCraft = (recipe: CraftingRecipe) => {
    return recipe.ingredients.every(ingredient => {
      const totalQuantity = inventory.reduce((sum, slot) => {
        if (slot.item?.id === ingredient.itemId) {
          return sum + slot.item.quantity
        }
        return sum
      }, 0)
      return totalQuantity >= ingredient.quantity
    })
  }

  const getIngredientCount = (itemId: string) => {
    return inventory.reduce((sum, slot) => {
      if (slot.item?.id === itemId) {
        return sum + slot.item.quantity
      }
      return sum
    }, 0)
  }

  const handleCraft = async () => {
    if (!selectedRecipe || !canCraft(selectedRecipe)) return
    
    setIsCrafting(true)
    setCraftingProgress(0)
    
    // 合成动画
    for (let i = 0; i <= 100; i += 5) {
      await new Promise(resolve => setTimeout(resolve, 50))
      setCraftingProgress(i)
    }
    
    onCraft(selectedRecipe)
    setIsCrafting(false)
    setCraftingProgress(0)
    setSelectedRecipe(null)
  }

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* 背景遮罩 */}
          <motion.div
            className="fixed inset-0 bg-black/60 backdrop-blur-sm z-40"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
          />
          
          {/* 合成面板 */}
          <motion.div
            className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[90%] max-w-2xl max-h-[80vh] overflow-hidden z-50"
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20 }}
          >
            <div className="relative bg-gradient-to-br from-slate-900/95 via-purple-900/30 to-slate-900/95 rounded-2xl border border-purple-500/30 shadow-2xl overflow-hidden">
              {/* 魔法背景效果 */}
              <div className="absolute inset-0 pointer-events-none">
                <MagicParticles active={isCrafting} />
                <motion.div
                  className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96"
                  style={{
                    background: 'radial-gradient(circle, rgba(168, 85, 247, 0.2) 0%, transparent 70%)',
                  }}
                  animate={isCrafting ? { scale: [1, 1.5, 1], opacity: [0.5, 1, 0.5] } : {}}
                  transition={{ duration: 1, repeat: Infinity }}
                />
              </div>
              
              {/* 标题栏 */}
              <div className="relative flex items-center justify-between p-4 border-b border-purple-500/20">
                <div className="flex items-center gap-3">
                  <motion.div
                    animate={isCrafting ? { rotate: 360 } : {}}
                    transition={{ duration: 2, repeat: Infinity, ease: 'linear' }}
                  >
                    <Hammer className="w-6 h-6 text-purple-400" />
                  </motion.div>
                  <h2 className="text-xl font-bold bg-gradient-to-r from-purple-400 to-pink-400 bg-clip-text text-transparent">
                    合成制作
                  </h2>
                </div>
                <motion.button
                  className="p-2 rounded-lg bg-slate-800/60 text-slate-400 hover:text-white hover:bg-slate-700/60"
                  whileHover={{ scale: 1.1 }}
                  whileTap={{ scale: 0.9 }}
                  onClick={onClose}
                >
                  <X className="w-5 h-5" />
                </motion.button>
              </div>
              
              {/* 内容区 */}
              <div className="relative flex flex-col md:flex-row gap-4 p-4 max-h-[60vh] overflow-y-auto">
                {/* 配方列表 */}
                <div className="flex-1 space-y-2">
                  <h3 className="text-sm font-medium text-purple-300 mb-3">可用配方</h3>
                  {craftingRecipes.map((recipe) => {
                    const craftable = canCraft(recipe)
                    const colors = rarityColors[recipe.result.rarity]
                    
                    return (
                      <motion.div
                        key={recipe.id}
                        className={`
                          p-3 rounded-lg cursor-pointer transition-all
                          bg-gradient-to-r from-slate-800/60 to-slate-900/60 
                          border border-purple-500/20
                          ${selectedRecipe?.id === recipe.id ? 'ring-2 ring-purple-400 bg-purple-500/10' : ''}
                          ${craftable ? 'hover:border-purple-400/50' : 'opacity-50'}
                        `}
                        whileHover={craftable ? { scale: 1.02 } : {}}
                        onClick={() => craftable && setSelectedRecipe(recipe)}
                      >
                        <div className="flex items-center gap-3">
                          <div className={`p-2 rounded-lg bg-slate-700/50 ${colors.text}`}>
                            {recipe.result.icon}
                          </div>
                          <div className="flex-1">
                            <h4 className={`font-medium ${colors.text}`}>{recipe.name}</h4>
                            <p className="text-xs text-slate-400">{recipe.description}</p>
                          </div>
                          {craftable && (
                            <div className="text-green-400">
                              <Check className="w-5 h-5" />
                            </div>
                          )}
                        </div>
                      </motion.div>
                    )
                  })}
                </div>
                
                {/* 配方详情 */}
                <div className="flex-1">
                  {selectedRecipe ? (
                    <motion.div
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      className="space-y-4"
                    >
                      <h3 className="text-sm font-medium text-purple-300">配方详情</h3>
                      
                      {/* 所需材料 */}
                      <div className="p-3 rounded-lg bg-slate-800/40 border border-purple-500/20">
                        <p className="text-xs text-slate-400 mb-2">所需材料</p>
                        <div className="space-y-2">
                          {selectedRecipe.ingredients.map((ingredient, index) => {
                            const hasEnough = getIngredientCount(ingredient.itemId) >= ingredient.quantity
                            const ingredientItem = sampleItems.find(i => i.id === ingredient.itemId)
                            
                            return (
                              <div key={index} className="flex items-center justify-between">
                                <span className="text-sm text-slate-300">
                                  {ingredientItem?.name || '未知物品'}
                                </span>
                                <span className={`text-sm ${hasEnough ? 'text-green-400' : 'text-red-400'}`}>
                                  {getIngredientCount(ingredient.itemId)} / {ingredient.quantity}
                                </span>
                              </div>
                            )
                          })}
                        </div>
                      </div>
                      
                      {/* 合成结果 */}
                      <div className="p-3 rounded-lg bg-slate-800/40 border border-purple-500/20">
                        <p className="text-xs text-slate-400 mb-2">合成结果</p>
                        <ItemDetailPanel item={selectedRecipe.result} />
                      </div>
                      
                      {/* 合成进度条 */}
                      {isCrafting && (
                        <div className="relative h-2 rounded-full bg-slate-700 overflow-hidden">
                          <motion.div
                            className="absolute h-full bg-gradient-to-r from-purple-500 to-pink-500"
                            initial={{ width: 0 }}
                            animate={{ width: `${craftingProgress}%` }}
                          />
                        </div>
                      )}
                      
                      {/* 合成按钮 */}
                      <motion.button
                        className="w-full py-3 rounded-lg bg-gradient-to-r from-purple-600 to-pink-600 text-white font-medium
                          hover:from-purple-500 hover:to-pink-500 transition-all duration-300 flex items-center justify-center gap-2"
                        whileHover={{ scale: 1.02 }}
                        whileTap={{ scale: 0.98 }}
                        onClick={handleCraft}
                        disabled={isCrafting}
                      >
                        {isCrafting ? (
                          <>
                            <motion.div
                              animate={{ rotate: 360 }}
                              transition={{ duration: 1, repeat: Infinity, ease: 'linear' }}
                            >
                              <Sparkles className="w-5 h-5" />
                            </motion.div>
                            合成中...
                          </>
                        ) : (
                          <>
                            <Hammer className="w-5 h-5" />
                            开始合成
                          </>
                        )}
                      </motion.button>
                    </motion.div>
                  ) : (
                    <div className="h-full flex items-center justify-center text-slate-400">
                      <div className="text-center">
                        <Package className="w-12 h-12 mx-auto mb-3 opacity-50" />
                        <p>选择一个配方查看详情</p>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}

// 主组件
export default function MagicInventory() {
  const [inventory, setInventory] = useState<InventorySlot[]>(() => {
    const slots: InventorySlot[] = Array(25).fill(null).map(() => ({ item: null, locked: false }))
    sampleItems.forEach((item, index) => {
      if (index < slots.length) {
        slots[index] = { item, locked: false }
      }
    })
    // 锁定最后5个格子
    for (let i = 20; i < 25; i++) {
      slots[i] = { item: null, locked: true }
    }
    return slots
  })
  
  const [quickBar, setQuickBar] = useState<InventorySlot[]>(() => 
    Array(5).fill(null).map(() => ({ item: null, locked: false }))
  )
  
  const [equipSlots, setEquipSlots] = useState<{ [key: string]: InventorySlot }>({
    weapon: { item: null, locked: false },
    helmet: { item: null, locked: false },
    chest: { item: null, locked: false },
    offhand: { item: null, locked: false },
    boots: { item: null, locked: false },
    accessory: { item: null, locked: false },
  })
  
  const [selectedSlot, setSelectedSlot] = useState<number | null>(null)
  const [activeTab, setActiveTab] = useState<'backpack' | 'quickbar'>('backpack')
  const [showCrafting, setShowCrafting] = useState(false)
  const [dragSource, setDragSource] = useState<{ type: 'inventory' | 'quickbar' | 'equip', index?: number, slotKey?: string } | null>(null)
  const [dragTargetIndex, setDragTargetIndex] = useState<number | null>(null)
  
  const [currencies] = useState([
    { name: '金币', icon: <Coins className="w-4 h-4" />, amount: 12580 },
    { name: '钻石', icon: <Gem className="w-4 h-4" />, amount: 350 },
    { name: '魔尘', icon: <Sparkles className="w-4 h-4" />, amount: 1250 },
  ])
  
  const [attributes] = useState([
    { name: '力量', abbr: 'STR', value: 10, icon: <Dumbbell className="w-4 h-4" /> },
    { name: '敏捷', abbr: 'AGI', value: 10, icon: <Footprints className="w-4 h-4" /> },
    { name: '智力', abbr: 'INT', value: 10, icon: <Brain className="w-4 h-4" /> },
    { name: '体质', abbr: 'CON', value: 10, icon: <Heart className="w-4 h-4" /> },
  ])

  const selectedItem = selectedSlot !== null ? inventory[selectedSlot]?.item : null

  // 处理背包内拖拽
  const handleInventoryDrop = useCallback((targetIndex: number) => {
    if (!dragSource) return
    
    if (dragSource.type === 'inventory' && dragSource.index !== undefined) {
      const sourceIndex = dragSource.index
      
      setInventory(prev => {
        const newInventory = [...prev]
        const temp = newInventory[targetIndex]
        newInventory[targetIndex] = newInventory[sourceIndex]
        newInventory[sourceIndex] = temp
        return newInventory
      })
    } else if (dragSource.type === 'quickbar' && dragSource.index !== undefined) {
      const sourceIndex = dragSource.index
      
      // 从快捷栏拖到背包
      setInventory(prev => {
        const newInventory = [...prev]
        const temp = newInventory[targetIndex]
        newInventory[targetIndex] = quickBar[sourceIndex]
        return newInventory
      })
      
      setQuickBar(prev => {
        const newQuickBar = [...prev]
        newQuickBar[sourceIndex] = { item: null, locked: false }
        return newQuickBar
      })
    } else if (dragSource.type === 'equip' && dragSource.slotKey) {
      const slotKey = dragSource.slotKey
      
      // 从装备槽拖到背包
      setInventory(prev => {
        const newInventory = [...prev]
        newInventory[targetIndex] = equipSlots[slotKey]
        return newInventory
      })
      
      setEquipSlots(prev => ({
        ...prev,
        [slotKey]: { item: null, locked: false }
      }))
    }
    
    setDragSource(null)
    setDragTargetIndex(null)
  }, [dragSource, quickBar, equipSlots])

  // 处理快捷栏拖拽
  const handleQuickBarDrop = useCallback((targetIndex: number) => {
    if (!dragSource) return
    
    if (dragSource.type === 'inventory' && dragSource.index !== undefined) {
      const sourceIndex = dragSource.index
      
      setQuickBar(prev => {
        const newQuickBar = [...prev]
        newQuickBar[targetIndex] = inventory[sourceIndex]
        return newQuickBar
      })
    }
    
    setDragSource(null)
  }, [dragSource, inventory])

  // 装备物品的核心函数
  const equipItemToSlot = useCallback((item: Item, sourceIndex: number, slotKey: string) => {
    // 检查物品是否适合该槽位
    if (item.equipSlot && item.equipSlot !== slotKey) {
      return false
    }
    
    // 先卸下原装备（如果有）
    const currentEquip = equipSlots[slotKey]
    
    setInventory(prev => {
      const newInventory = [...prev]
      if (currentEquip.item) {
        newInventory[sourceIndex] = { item: currentEquip.item, locked: false }
      } else {
        newInventory[sourceIndex] = { item: null, locked: false }
      }
      return newInventory
    })
    
    // 装备新物品
    setEquipSlots(prev => ({
      ...prev,
      [slotKey]: { item: { ...item }, locked: false }
    }))
    
    // 清除选中状态
    setSelectedSlot(null)
    
    return true
  }, [equipSlots])

  // 处理装备槽拖拽
  const handleEquipSlotDrop = useCallback((slotKey: string, requiredSlot?: string) => {
    if (!dragSource) return
    
    const sourceItem = dragSource.type === 'inventory' && dragSource.index !== undefined
      ? inventory[dragSource.index].item
      : null
    
    if (!sourceItem) return
    
    // 检查物品是否适合该槽位
    if (requiredSlot && sourceItem.equipSlot !== requiredSlot) {
      return
    }
    
    if (dragSource.type === 'inventory' && dragSource.index !== undefined) {
      const sourceIndex = dragSource.index
      equipItemToSlot(sourceItem, sourceIndex, slotKey)
    }
    
    setDragSource(null)
  }, [dragSource, inventory, equipItemToSlot])

  // 处理合成
  const handleCraft = useCallback((recipe: CraftingRecipe) => {
    // 移除材料
    setInventory(prev => {
      const newInventory = [...prev]
      
      recipe.ingredients.forEach(ingredient => {
        let remaining = ingredient.quantity
        for (let i = 0; i < newInventory.length && remaining > 0; i++) {
          if (newInventory[i].item?.id === ingredient.itemId) {
            const take = Math.min(newInventory[i].item!.quantity, remaining)
            newInventory[i].item!.quantity -= take
            remaining -= take
            
            if (newInventory[i].item!.quantity <= 0) {
              newInventory[i] = { item: null, locked: false }
            }
          }
        }
      })
      
      // 添加合成结果
      for (let i = 0; i < newInventory.length; i++) {
        if (!newInventory[i].item && !newInventory[i].locked) {
          newInventory[i] = { item: { ...recipe.result }, locked: false }
          break
        }
      }
      
      return newInventory
    })
  }, [])

  // 使用物品
  const handleUseItem = useCallback(() => {
    if (!selectedItem || selectedSlot === null) return
    
    if (selectedItem.type === 'consumable') {
      // 消耗品：减少数量
      setInventory(prev => {
        const newInventory = [...prev]
        if (newInventory[selectedSlot].item) {
          newInventory[selectedSlot].item!.quantity -= 1
          if (newInventory[selectedSlot].item!.quantity <= 0) {
            newInventory[selectedSlot] = { item: null, locked: false }
            setSelectedSlot(null)
          }
        }
        return newInventory
      })
    } else if (selectedItem.equipSlot) {
      // 可装备物品：装备到对应槽位
      equipItemToSlot(selectedItem, selectedSlot, selectedItem.equipSlot)
    }
  }, [selectedItem, selectedSlot, equipItemToSlot])

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-950 via-purple-950/30 to-slate-950 flex flex-col">
      {/* 背景魔法效果 */}
      <div className="fixed inset-0 pointer-events-none">
        <MagicGlow />
        <MagicParticles />
      </div>
      
      {/* 主容器 */}
      <div className="relative z-10 flex-1 p-4 md:p-6 lg:p-8 flex flex-col">
        {/* 标题栏 */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="flex items-center justify-between mb-6"
        >
          <div className="flex items-center gap-3">
            <motion.div
              animate={{ rotate: 360 }}
              transition={{ duration: 20, repeat: Infinity, ease: 'linear' }}
            >
              <Sparkles className="w-8 h-8 text-purple-400" />
            </motion.div>
            <h1 className="text-2xl md:text-3xl font-bold bg-gradient-to-r from-purple-400 via-pink-400 to-purple-400 bg-clip-text text-transparent">
              魔法背包
            </h1>
          </div>
          
          {/* 功能按钮 */}
          <div className="flex gap-2">
            <motion.button
              className="p-2 rounded-lg bg-purple-500/20 border border-purple-500/30 text-purple-400 hover:bg-purple-500/30"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              <Settings className="w-5 h-5" />
            </motion.button>
            <motion.button
              className="p-2 rounded-lg bg-purple-500/20 border border-purple-500/30 text-purple-400 hover:bg-purple-500/30"
              whileHover={{ scale: 1.05, rotate: 180 }}
              whileTap={{ scale: 0.95 }}
            >
              <RefreshCw className="w-5 h-5" />
            </motion.button>
          </div>
        </motion.div>
        
        {/* 货币栏 */}
        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="flex gap-4 mb-6 flex-wrap"
        >
          {currencies.map((currency, index) => (
            <motion.div
              key={currency.name}
              className="flex items-center gap-2 px-4 py-2 rounded-full bg-gradient-to-r from-slate-800/80 to-slate-900/80 border border-amber-500/30"
              whileHover={{ scale: 1.05, borderColor: 'rgba(245, 158, 11, 0.5)' }}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.1 + index * 0.1 }}
            >
              <span className="text-amber-400">{currency.icon}</span>
              <span className="text-sm text-slate-300">{currency.name}:</span>
              <span className="font-bold text-amber-400">{currency.amount.toLocaleString()}</span>
            </motion.div>
          ))}
        </motion.div>
        
        {/* 快捷栏 */}
        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.15 }}
          className="mb-6 p-3 rounded-xl bg-gradient-to-r from-slate-800/60 to-slate-900/60 border border-cyan-500/20"
        >
          <div className="flex items-center gap-4">
            <span className="text-sm text-cyan-300 font-medium">快捷栏</span>
            <QuickBar 
              slots={quickBar}
              onDrop={handleQuickBarDrop}
              onItemClick={(index) => {
                if (quickBar[index].item) {
                  // 可以添加快捷栏物品使用逻辑
                }
              }}
            />
          </div>
        </motion.div>
        
        {/* 主内容区域 */}
        <div className="flex-1 flex flex-col lg:flex-row gap-6">
          {/* 左侧面板 */}
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.2 }}
            className="w-full lg:w-72 flex-shrink-0 space-y-4"
          >
            {/* 属性面板 */}
            <div className="p-4 rounded-xl bg-gradient-to-br from-slate-800/60 to-slate-900/60 border border-purple-500/20">
              <h2 className="text-sm font-medium text-purple-300 mb-4 flex items-center gap-2">
                <Star className="w-4 h-4" />
                角色属性
              </h2>
              <div className="grid grid-cols-2 gap-3">
                {attributes.map((attr) => (
                  <AttributeSlot
                    key={attr.abbr}
                    name={attr.abbr}
                    value={attr.value}
                    icon={attr.icon}
                  />
                ))}
              </div>
            </div>
            
            {/* 装备槽位 */}
            <div className="p-4 rounded-xl bg-gradient-to-br from-slate-800/60 to-slate-900/60 border border-purple-500/20">
              <h2 className="text-sm font-medium text-purple-300 mb-4 flex items-center gap-2">
                <Shield className="w-4 h-4" />
                装备栏
              </h2>
              <div className="grid grid-cols-3 gap-3 justify-items-center">
                <div />
                <EquipSlot 
                  slot={equipSlots.helmet} 
                  slotName="头盔" 
                  icon={<Crown className="w-5 h-5" />}
                  onDrop={() => handleEquipSlotDrop('helmet', 'helmet')}
                  onClick={() => {}}
                />
                <div />
                <EquipSlot 
                  slot={equipSlots.weapon} 
                  slotName="武器" 
                  icon={<Sword className="w-5 h-5" />}
                  onDrop={() => handleEquipSlotDrop('weapon', 'weapon')}
                  onClick={() => {}}
                />
                <EquipSlot 
                  slot={equipSlots.chest} 
                  slotName="胸甲" 
                  icon={<Shield className="w-5 h-5" />}
                  onDrop={() => handleEquipSlotDrop('chest', 'chest')}
                  onClick={() => {}}
                />
                <EquipSlot 
                  slot={equipSlots.offhand} 
                  slotName="副手" 
                  icon={<Target className="w-5 h-5" />}
                  onDrop={() => handleEquipSlotDrop('offhand', 'offhand')}
                  onClick={() => {}}
                />
                <div />
                <EquipSlot 
                  slot={equipSlots.boots} 
                  slotName="靴子" 
                  icon={<Footprints className="w-5 h-5" />}
                  onDrop={() => handleEquipSlotDrop('boots', 'boots')}
                  onClick={() => {}}
                />
                <EquipSlot 
                  slot={equipSlots.accessory} 
                  slotName="饰品" 
                  icon={<Gem className="w-5 h-5" />}
                  onDrop={() => handleEquipSlotDrop('accessory', 'accessory')}
                  onClick={() => {}}
                />
              </div>
            </div>
            
            {/* 功能按钮组 */}
            <div className="space-y-2">
              <motion.button
                className="w-full py-3 px-4 rounded-xl bg-gradient-to-r from-purple-600/80 to-pink-600/80 border border-purple-400/30 text-white font-medium flex items-center justify-center gap-2 hover:from-purple-500/80 hover:to-pink-500/80"
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                onClick={() => setShowCrafting(true)}
              >
                <Hammer className="w-5 h-5" />
                合成制作
              </motion.button>
              <motion.button
                className="w-full py-3 px-4 rounded-xl bg-gradient-to-r from-blue-600/80 to-cyan-600/80 border border-blue-400/30 text-white font-medium flex items-center justify-center gap-2 hover:from-blue-500/80 hover:to-cyan-500/80"
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                <Settings className="w-5 h-5" />
                工作台
              </motion.button>
            </div>
          </motion.div>
          
          {/* 中间背包区域 */}
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.3 }}
            className="flex-1"
          >
            {/* 标签栏 */}
            <div className="flex gap-2 mb-4">
              <motion.button
                className={`px-6 py-2 rounded-lg font-medium transition-all duration-300 ${
                  activeTab === 'backpack'
                    ? 'bg-gradient-to-r from-purple-600 to-pink-600 text-white shadow-lg shadow-purple-500/30'
                    : 'bg-slate-800/60 text-slate-400 hover:text-white hover:bg-slate-700/60'
                }`}
                onClick={() => setActiveTab('backpack')}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                背包
              </motion.button>
              <motion.button
                className={`px-6 py-2 rounded-lg font-medium transition-all duration-300 ${
                  activeTab === 'quickbar'
                    ? 'bg-gradient-to-r from-purple-600 to-pink-600 text-white shadow-lg shadow-purple-500/30'
                    : 'bg-slate-800/60 text-slate-400 hover:text-white hover:bg-slate-700/60'
                }`}
                onClick={() => setActiveTab('quickbar')}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                快捷栏
              </motion.button>
            </div>
            
            {/* 背包格子 */}
            <div className="p-4 rounded-xl bg-gradient-to-br from-slate-800/40 to-slate-900/40 border border-purple-500/20 backdrop-blur-sm">
              <div className="grid grid-cols-5 gap-2">
                {inventory.map((slot, index) => (
                  <InventorySlotComponent
                    key={index}
                    slot={slot}
                    index={index}
                    onClick={() => setSelectedSlot(selectedSlot === index ? null : index)}
                    isSelected={selectedSlot === index}
                    onDragStart={() => setDragSource({ type: 'inventory', index })}
                    onDragEnd={() => setDragSource(null)}
                    onDragOver={(e) => {
                      e.preventDefault()
                      setDragTargetIndex(index)
                    }}
                    onDrop={() => handleInventoryDrop(index)}
                    isDragTarget={dragTargetIndex === index}
                  />
                ))}
              </div>
            </div>
            
            {/* 底部信息栏 */}
            <div className="mt-4 flex items-center justify-between text-sm text-slate-400">
              <span>容量: {inventory.filter(s => s.item).length} / {inventory.filter(s => !s.locked).length}</span>
              <span className="flex items-center gap-1">
                <Sparkles className="w-4 h-4 text-purple-400" />
                魔法背包 v1.0
              </span>
            </div>
          </motion.div>
          
          {/* 右侧详情面板 */}
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.4 }}
            className="w-full lg:w-72 flex-shrink-0"
          >
            <AnimatePresence mode="wait">
              <ItemDetailPanel 
                item={selectedItem} 
                onUse={handleUseItem}
              />
            </AnimatePresence>
            
            {/* 垃圾桶 */}
            <motion.div
              className="mt-4 p-4 rounded-xl bg-gradient-to-br from-red-900/30 to-slate-900/60 border border-red-500/20 cursor-pointer"
              whileHover={{ scale: 1.02, borderColor: 'rgba(239, 68, 68, 0.5)' }}
              onDragOver={(e) => e.preventDefault()}
              onDrop={(e) => {
                e.preventDefault()
                if (dragSource?.type === 'inventory' && dragSource.index !== undefined) {
                  setInventory(prev => {
                    const newInventory = [...prev]
                    newInventory[dragSource.index!] = { item: null, locked: false }
                    return newInventory
                  })
                  setSelectedSlot(null)
                }
                setDragSource(null)
              }}
            >
              <div className="flex items-center justify-center gap-2 text-red-400">
                <Trash2 className="w-5 h-5" />
                <span className="text-sm">拖拽物品到此处销毁</span>
              </div>
            </motion.div>
          </motion.div>
        </div>
      </div>
      
      {/* 合成面板 */}
      <CraftingPanel 
        isOpen={showCrafting}
        onClose={() => setShowCrafting(false)}
        inventory={inventory}
        onCraft={handleCraft}
      />
    </div>
  )
}

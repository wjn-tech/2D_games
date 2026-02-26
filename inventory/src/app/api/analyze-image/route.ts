import { NextRequest, NextResponse } from 'next/server';
import ZAI from 'z-ai-web-dev-sdk';
import fs from 'fs';
import path from 'path';

export async function POST(request: NextRequest) {
  try {
    const { imagePath } = await request.json();
    
    if (!imagePath) {
      return NextResponse.json({ error: 'Image path is required' }, { status: 400 });
    }

    const fullPath = path.join(process.cwd(), imagePath);
    
    if (!fs.existsSync(fullPath)) {
      return NextResponse.json({ error: 'Image file not found' }, { status: 404 });
    }

    const imageBuffer = fs.readFileSync(fullPath);
    const base64Image = imageBuffer.toString('base64');
    const mimeType = imagePath.endsWith('.png') ? 'image/png' : 'image/jpeg';

    const zai = await ZAI.create();

    const response = await zai.chat.completions.createVision({
      messages: [
        {
          role: 'user',
          content: [
            {
              type: 'text',
              text: `请详细分析这个游戏背包界面，以JSON格式返回以下信息：
{
  "layout": {
    "gridColumns": 数字,
    "gridRows": 数字,
    "totalSlots": 数字
  },
  "equipmentSlots": [
    {"name": "槽位名称", "position": "位置描述"}
  ],
  "features": {
    "hasCurrency": true/false,
    "hasSearch": true/false,
    "hasSort": true/false,
    "hasFilter": true/false,
    "hasTabs": true/false
  },
  "currencies": ["货币名称列表"],
  "tabs": ["标签页名称列表"],
  "colorScheme": "描述整体颜色风格",
  "items": ["可见物品名称列表"],
  "itemDetails": {
    "hasRarity": true/false,
    "hasQuantity": true/false,
    "hasLevel": true/false,
    "hasStats": true/false
  }
}`
            },
            {
              type: 'image_url',
              image_url: {
                url: `data:${mimeType};base64,${base64Image}`
              }
            }
          ]
        }
      ],
      thinking: { type: 'disabled' }
    });

    const content = response.choices[0]?.message?.content;
    
    // 尝试解析JSON
    try {
      const jsonMatch = content?.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return NextResponse.json({ analysis: JSON.parse(jsonMatch[0]) });
      }
    } catch {
      // 如果解析失败，返回原始内容
    }

    return NextResponse.json({ analysis: content });
  } catch (error) {
    console.error('Vision analysis error:', error);
    return NextResponse.json(
      { error: 'Failed to analyze image' },
      { status: 500 }
    );
  }
}

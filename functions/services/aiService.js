const OpenAI = require('openai');

const PROMPT_TEXT = `Bu kıyafetin kombin için önemli özelliklerini detaylı olarak analiz et. Yanıtı şu formatta ver:

Ana Grup: [üst giyim, alt giyim, dış giyim, ayakkabı, aksesuar]
Kategori: [ana grup içindeki detay kategori - örn: gömlek, pantolon, elbise, ceket, ayakkabı]
Renk: [ana renk ve varsa detay renkleri]
Materyal: [kumaş/malzeme türü - örn: pamuk, keten, deri, kot]
Stil: [casual, formal, spor, bohem, klasik, vintage, vb.]
Sezon: [hangi mevsimler için uygun - örn: yaz, kış, tüm yıl]
Detaylar: [desen, dikiş, kesim, fit, tasarım özellikleri ve kombinasyon için önemli diğer detaylar]

ÖNEMLİ NOTLAR:
1. Ana Grup seçiminde şu kategorileri kullan: Üst Giyim, Alt Giyim, Dış Giyim, Ayakkabı, Aksesuar.
2. Her kıyafeti sadece bir ana gruba yerleştir. Renk analizinde hem ana rengi hem de varsa desen/çizgi renklerini belirt.`;

function normalizeMainGroup(group) {
  const normalized = (group || '').toLowerCase().trim();
  const valid = ['üst giyim', 'alt giyim', 'dış giyim', 'ayakkabı', 'aksesuar'];
  return valid.find(g => g === normalized) || 'üst giyim';
}

function mapMainGroupToCategory(mainGroup) {
  const m = {
    'üst giyim': 'top',
    'alt giyim': 'bottom',
    'dış giyim': 'outerwear',
    'ayakkabı': 'shoes',
    'aksesuar': 'accessory'
  };
  return m[mainGroup] || 'top';
}

function parseAnalysis(analysis) {
  let mainGroup = '', category = '', color = '', material = '', style = '', season = '', details = '';
  const lines = analysis.split('\n');
  for (const line of lines) {
    if (line.startsWith('Ana Grup:')) mainGroup = normalizeMainGroup(line.replace('Ana Grup:', '').trim());
    else if (line.startsWith('Kategori:')) category = line.replace('Kategori:', '').trim();
    else if (line.startsWith('Renk:')) color = line.replace('Renk:', '').trim();
    else if (line.startsWith('Materyal:')) material = line.replace('Materyal:', '').trim();
    else if (line.startsWith('Stil:')) style = line.replace('Stil:', '').trim();
    else if (line.startsWith('Sezon:')) season = line.replace('Sezon:', '').trim();
    else if (line.startsWith('Detaylar:')) details = line.replace('Detaylar:', '').trim();
  }
  return { mainGroup, category, color, material, style, season, details };
}

function getCombinationName(n) {
  const names = { 1: 'Günlük Kombin', 2: 'İş Kombini', 3: 'Özel Kombin' };
  return names[n] || `Kombin ${n}`;
}

function mapUsageToOccasion(usage) {
  if (!usage) return 'casual';
  const t = usage.toLowerCase();
  if (/iş|ofis|formal|görüşme|çalış/.test(t)) return 'work';
  if (/spor|aktif|egzersiz/.test(t)) return 'sport';
  if (/parti|özel|davet|akşam|gece/.test(t)) return 'party';
  if (/günlük|casual|evde/.test(t)) return 'daily';
  if (/resmi|töreni/.test(t)) return 'formal';
  return 'casual';
}

function parseOutfits(content) {
  const outfits = [];
  const sections = content.split(/KOMBİN \d+:/);
  for (let i = 1; i < sections.length; i++) {
    const section = sections[i].trim();
    const lines = section.split('\n');
    const outfit = { outfit_number: i, items: [], details: {} };
    for (let j = 0; j < lines.length; j++) {
      const line = lines[j].trim();
      if (line.startsWith('ID:')) {
        const id = line.replace('ID:', '').trim();
        if (id && id !== '-' && id !== 'varsa') outfit.items.push(id);
      } else if (line.startsWith('AÇIKLAMA:')) {
        outfit.details.aciklama = line.replace('AÇIKLAMA:', '').trim();
      } else if (line.startsWith('KULLANIM:')) {
        outfit.details.kullanim = line.replace('KULLANIM:', '').trim();
      } else if (line.startsWith('TAMAMLAYICILAR:')) {
        outfit.details.tamamlayicilar = line.replace('TAMAMLAYICILAR:', '').trim();
      } else if (line.startsWith('SEZON:')) {
        outfit.details.sezon = line.replace('SEZON:', '').trim();
      }
    }
    outfits.push(outfit);
  }
  return outfits;
}

const COMBINATION_SYSTEM = `Sen bir profesyonel stilistsin. Kullanıcının gardırobundan uyumlu ve tarz kıyafet kombinasyonları oluştur.

1. KOMBİN KURALLARI:
- 1 üst giyim (top), 1 alt giyim (bottom), opsiyonel dış giyim (outerwear), opsiyonel ayakkabı (shoes).
- Aynı kategoriden birden fazla kıyafet KULLANMA. Her kıyafeti SADECE BİR kombinde kullan (ID'ler tekrarlanmamalı).

2. UYUM: Renk, stil, sezon ve materyal uyumuna dikkat et.

3. ÇIKTI FORMATI (SADECE bu formatı kullan):
KOMBİN 1:
ID: [dış giyim ID - varsa]
ID: [üst giyim ID]
ID: [alt giyim ID]
ID: [ayakkabı ID - varsa]
AÇIKLAMA: [Kombinin stil tanımı, max 3 cümle]
KULLANIM: [Giyilebileceği ortamlar]
TAMAMLAYICILAR: [Aksesuar önerileri]
SEZON: [Uygun mevsim(ler)]

Lütfen 3 FARKLI KOMBİN oluştur: Günlük (Casual), İş/Ofis (Formal), Spor veya Özel Durum.`;

async function analyzeClothingFromUrl(openai, imageUrl) {
  const response = await openai.chat.completions.create({
    model: 'gpt-4o',
    messages: [
      {
        role: 'user',
        content: [
          { type: 'text', text: PROMPT_TEXT },
          { type: 'image_url', image_url: { url: imageUrl } }
        ]
      }
    ],
    max_tokens: 800
  });
  const analysis = response.choices[0].message.content;
  const usage = response.usage;
  const { mainGroup, category, color, material, style, season, details } = parseAnalysis(analysis);
  const colors = color.includes(',') ? color.split(',').map(c => c.trim()) : [color];
  return {
    success: true,
    rawAnalysis: analysis,
    parsedAnalysis: { mainGroup, category, color, material, style, season, details },
    formattedAnalysis: {
      ana_grup: mainGroup,
      kategori: category,
      renk: color,
      materyal: material,
      stil: style,
      sezon: season,
      detaylar: details
    },
    category: mapMainGroupToCategory(mainGroup),
    colors,
    advancedAnalysis: {
      mainGroup,
      category,
      color,
      material,
      style,
      season,
      details,
      rawAnalysis: analysis
    },
    usage: {
      prompt_tokens: usage.prompt_tokens,
      completion_tokens: usage.completion_tokens
    }
  };
}

async function generateCombinations(openai, clothingItems) {
  if (!clothingItems || clothingItems.length === 0) {
    throw new Error('Dolabınızda henüz kıyafet bulunmuyor. Önce kıyafet eklemelisiniz.');
  }
  const idField = (item) => item.id || item._id;
  const descriptions = clothingItems.map((item) => {
    const adv = item.advancedAnalysis || {};
    return `[Kıyafet ${idField(item)}]
ID: ${idField(item)}
Ana Grup: ${mapMainGroupToCategory(item.category)}
Kategori: ${item.category}
Başlık: ${item.title || 'Kıyafet'}
Renk: ${(item.colors && item.colors.join) ? item.colors.join(', ') : (adv.color || 'Belirtilmemiş')}
Materyal: ${adv.material || 'Belirtilmemiş'}
Stil: ${adv.style || 'Belirtilmemiş'}
Sezon: ${adv.season || 'Belirtilmemiş'}
Detaylar: ${adv.details || 'Belirtilmemiş'}
-------------------`;
  }).join('\n\n');

  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'system', content: COMBINATION_SYSTEM },
      {
        role: 'user',
        content: `Mevcut Kıyafetlerim:\n${descriptions}\n\nLütfen bu kıyafetlerle 3 FARKLI KOMBİN oluştur. Eğer bir kategoride yeterli kıyafet yoksa belirt ve mevcut parçalarla uygun kombinler oluştur.`
      }
    ],
    temperature: 0.2,
    max_tokens: 1200
  });

  const content = response.choices[0].message.content;
  const parsedOutfits = parseOutfits(content);
  const combinations = parsedOutfits.slice(0, 3).map((outfit) => ({
    name: getCombinationName(outfit.outfit_number),
    items: outfit.items,
    occasion: mapUsageToOccasion(outfit.details.kullanim),
    description: outfit.details.aciklama || '',
    season: outfit.details.sezon || 'all-season',
    accessories: outfit.details.tamamlayicilar || '',
    usage: outfit.details.kullanim || ''
  }));

  return {
    success: true,
    combinations,
    rawResponse: content,
    parsed_outfits: parsedOutfits,
    usage: {
      prompt_tokens: response.usage.prompt_tokens,
      completion_tokens: response.usage.completion_tokens
    }
  };
}

async function getStyleAdvice(openai, message, conversationHistory = [], wardrobeContext) {
  const messages = [
    {
      role: 'system',
      content: 'Sen bir profesyonel kişisel stilistsin. Kullanıcıya giyim, kombin ve stil konularında yardımcı oluyorsun. Kısa, net ve Türkçe yanıt ver.'
    }
  ];
  if (wardrobeContext) {
    messages.push({
      role: 'system',
      content: `Kullanıcının gardırop özeti:\n${wardrobeContext}`
    });
  }
  for (const msg of conversationHistory) {
    messages.push({
      role: msg.role === 'user' ? 'user' : 'assistant',
      content: msg.content || msg.message
    });
  }
  messages.push({ role: 'user', content: message });

  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages,
    temperature: 0.7,
    max_tokens: 500
  });

  return {
    success: true,
    response: response.choices[0].message.content
  };
}

module.exports = {
  analyzeClothingFromUrl,
  generateCombinations,
  getStyleAdvice,
  mapMainGroupToCategory
};

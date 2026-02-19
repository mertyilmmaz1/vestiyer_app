const OpenAI = require('openai');
const {
  normalizeMainGroup,
  normalizeCategory,
  normalizeMaterial,
  normalizeFit,
  normalizePattern,
  mapMainGroupToFirestore,
  MAIN_GROUPS,
  MATERIALS,
  FIT_VALUES,
  PATTERN_VALUES
} = require('./categoryTaxonomy');



const SHOPPING_SUGGESTIONS_SCHEMA = {
  type: 'object',
  properties: {
    missingEssensials: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          item: { type: 'string', description: 'Eksik olan temel parça (örn: Beyaz Blazer)' },
          reason: { type: 'string', description: 'Neden bu parçaya ihtiyaç var?' },
          compatibility: { type: 'string', description: 'Mevcut hangi parçalarla uyumlu?' }
        },
        required: ['item', 'reason', 'compatibility'],
        additionalProperties: false
      },
      description: 'Dolapta eksik olan ve kombinleri tamamlayacak temel parçalar.'
    },
    complementarySuggestions: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          item: { type: 'string', description: 'Mevcut bir parçayı tamamlayacak yeni bir öneri' },
          completes: { type: 'string', description: 'Dolaptaki hangi parçayı tamamlıyor?' },
          styleTip: { type: 'string', description: 'Stil tüyosu' }
        },
        required: ['item', 'completes', 'styleTip'],
        additionalProperties: false
      },
      description: 'Mevcut parçaların potansiyelini artıracak tamamlayıcı öneriler.'
    },
    seasonalEssentials: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          item: { type: 'string', description: 'Mevsimlik temel parça' },
          reason: { type: 'string', description: 'Bu mevsim için neden önemli?' }
        },
        required: ['item', 'reason'],
        additionalProperties: false
      },
      description: 'Mevcut mevsime özel mutlaka olması gereken parçalar.'
    }
  },
  required: ['missingEssensials', 'complementarySuggestions', 'seasonalEssentials'],
  additionalProperties: false
};

const STEP1_SCHEMA = {
  type: 'object',
  properties: {
    mainGroup: {
      type: 'string',
      enum: MAIN_GROUPS,
      description: 'Ana grup. ' + MAIN_GROUPS.join(', ') + ' arasından seç.'
    },
    category: {
      type: 'string',
      description: 'Kategori. Ana grup ile uyumlu olmalı.'
    },
    material: {
      type: 'string',
      enum: MATERIALS,
      description: 'Materyal. ' + MATERIALS.join(', ') + ' arasından seç.'
    },
    pattern: {
      type: 'string',
      enum: PATTERN_VALUES,
      description: 'Desen'
    },
    fit: {
      type: 'string',
      enum: FIT_VALUES,
      description: 'Fit'
    },
    colors: {
      type: 'array',
      items: { type: 'string' },
      description: 'Kıyafetin baskın renkleri (max 3). Türkçe renk isimleri kullan (örn: Lacivert, Kiremit, Haki, Bej).'
    },
    mainColorHex: {
      type: 'string',
      description: 'Ana rengin yaklaşık HEX kodu (örn: #000080).'
    },
    confidence: {
      type: 'number',
      description: 'Güven skoru 0-1'
    }
  },
  required: ['mainGroup', 'category', 'material', 'pattern', 'fit', 'colors', 'mainColorHex', 'confidence'],
  additionalProperties: false
};

const STEP2_SCHEMA = {
  type: 'object',
  properties: {
    style: {
      type: 'array',
      items: { type: 'string' },
      description: 'Stil listesi. (casual, formal, spor, klasik, vintage, minimal, sokak_stili, business)'
    },
    season: {
      type: 'array',
      items: { type: 'string' },
      description: 'Sezon listesi. (ilkbahar, yaz, sonbahar, kis, tum_yil, mevsimsiz)'
    },
    details: {
      type: 'string',
      description: 'Kıyafetin detaylı açıklaması. Kullanıcıya gösterilecek şık ve açıklayıcı bir metin.'
    }
  },
  required: ['style', 'season', 'details'],
  additionalProperties: false
};

const STEP1_PROMPT = `Bu kıyafetin 'Vestiyer' uygulaması için profesyonel analizini yap.
Görseli incele ve aşağıdaki özelliklerini çıkar:
1. **Ana Grup ve Kategori**: Listeden en uygun olanı seç.
2. **Renkler**: En baskın rengi ve varsa 2 yan rengi belirle. Renk isimleri konusunda hassas ol (örn: sadece 'Mavi' deme, 'Saks Mavisi' veya 'Bebek Mavisi' gibi detay ver).
3. **Materyal ve Desen**: Kumaş türünü ve desenini analiz et.
4. **Fit**: Kıyafetin kesimini belirle.

Not: Sadece kıyafete odaklan, arka planı yok say.`;

const STEP2_PROMPT = (step1Output) => `Bu kıyafetin teknik özellikleri: ${JSON.stringify(step1Output)}

Bu özelliklere dayanarak:
1. **Stil**: Hangi tarza uygun? (örn: Casual, Business, Streetwear)
2. **Sezon**: Hangi mevsimlerde giyilir?
3. **Detaylar**: Kullanıcıya hitap eden, kıyafeti öven ve kombin tüyosu içeren kısa ama etkili bir açıklama yaz (1-2 cümle, kısa ve net).
Kurallar:
- Genel ve tekrar eden kalıp cümlelerden kaçın (örn: sürekli "X tarzına uygun").
- Somut anlat: parça tipi + renk + materyal/fit bilgisini kullan.
- En az bir pratik eşleştirme önerisi ver (ör: hangi alt/ayakkabı ile iyi gider).`;

const SHOPPING_SUGGESTIONS_SYSTEM = `Sen profesyonel bir stilist ve gardırop danışmanısın. 
Kullanıcının gardırop özetini ve stil tercihlerini analiz ederek, dolabındaki eksiklikleri tespit et ve alışveriş önerileri sun.

ÖNERİ KURALLARI:
1. Kullanıcının mevcut parçalarını 'çöpe at' veya 'değiştir' deme. Tam tersine, mevcut parçaların değerini artıracak önerilerde bulun.
2. 'Eksik Temel Parçalar' kısmında, her dolapta olması gereken ve kombin yapmayı kolaylaştıracak ürünleri öner.
3. 'Tamamlayıcı Öneriler' kısmında, kullanıcının dolabındaki spesifik bir parçayı (örn: 'Lacivert Kot Pantolon') baz alarak onu neyle daha şık hale getirebileceğini söyle.
4. 'Mevsimlik Temel Parçalar' kısmında, güncel mevsime (varsa) veya genel mevsime göre öneri ver.
5. Kullanıcıya ürün linki veya fiyat verme, sadece ürün türü ve stil tüyosu ver.
6. Dil: Türkçe. Üslup: Profesyonel, zarif ve heveslendirici.`;

function getCombinationName(n) {
  const names = { 1: 'Günlük Kombin', 2: 'İş Kombini', 3: 'Özel Kombin' };
  return names[n] || `Kombin ${n}`;
}

function mapUsageToOccasion(usage) {
  if (!usage) return 'casual';
  const t = (usage || '').toLowerCase();
  if (/iş|ofis|formal|görüşme|çalış/.test(t)) return 'work';
  if (/spor|aktif|egzersiz/.test(t)) return 'sport';
  if (/parti|özel|davet|akşam|gece/.test(t)) return 'party';
  if (/günlük|casual|evde/.test(t)) return 'daily';
  if (/resmi|töreni/.test(t)) return 'formal';
  return 'casual';
}

async function analyzeClothingFromUrl(openai, imageUrl, backendColors = null) {
  // Step 1: Visual Analysis & Categorization
  const response1 = await openai.chat.completions.create({
    model: 'gpt-4o',
    messages: [
      {
        role: 'user',
        content: [
          { type: 'text', text: STEP1_PROMPT },
          { type: 'image_url', image_url: { url: imageUrl } }
        ]
      }
    ],
    response_format: {
      type: 'json_schema',
      json_schema: {
        name: 'clothing_step1',
        strict: true,
        schema: STEP1_SCHEMA
      }
    },
    max_tokens: 300
  });

  const step1Content = response1.choices[0].message.content;
  let step1;
  try {
    step1 = JSON.parse(step1Content);
  } catch (e) {
    throw new Error('Analiz (Adım 1) yanıtı işlenemedi.');
  }

  // Step 2: Styling & Description
  const response2 = await openai.chat.completions.create({
    model: 'gpt-4o',
    messages: [
      {
        role: 'user',
        content: STEP2_PROMPT(step1)
      }
    ],
    response_format: {
      type: 'json_schema',
      json_schema: {
        name: 'clothing_step2',
        strict: true,
        schema: STEP2_SCHEMA
      }
    },
    max_tokens: 400
  });

  const step2Content = response2.choices[0].message.content;
  let step2;
  try {
    step2 = JSON.parse(step2Content);
  } catch (e) {
    step2 = { style: ['casual'], season: ['tum_yil'], details: '' };
  }

  // Normalization
  const mainGroup = normalizeMainGroup(step1.mainGroup);
  const category = normalizeCategory(mainGroup, step1.category);
  const material = normalizeMaterial(step1.material);
  const pattern = normalizePattern(step1.pattern);
  const fit = normalizeFit(step1.fit);
  const confidence = Math.max(0, Math.min(1, Number(step1.confidence) || 0.8));

  // Color selection: Prefer AI detected colors, fallback to backend (k-means) if explicit match needed,
  // but AI is generally better at naming.
  let colors = [];
  let colorsWithDominance = [];

  if (step1.colors && step1.colors.length > 0) {
    colors = step1.colors;
    // Mock dominance for AI colors since GPT doesn't return percentages easily in this schema
    colorsWithDominance = colors.map((c, i) => ({
      name: c,
      dominance: i === 0 ? 0.7 : 0.15, // Dummy values
      hex: i === 0 ? (step1.mainColorHex || null) : null
    }));
  } else if (backendColors && backendColors.length > 0) {
    // Fallback to k-means
    colorsWithDominance = backendColors;
    colors = backendColors.map(c => c.name);
  } else {
    colors = ['Belirsiz'];
    colorsWithDominance = [{ name: 'belirsiz', dominance: 1 }];
  }

  const colorStr = colors.join(', ');

  const style = Array.isArray(step2.style) ? step2.style : ['casual'];
  const season = Array.isArray(step2.season) ? step2.season : ['tum_yil'];
  const details = step2.details || '';

  const firestoreCategory = mapMainGroupToFirestore(mainGroup);

  return {
    success: true,
    rawAnalysis: JSON.stringify({ step1, step2 }),
    parsedAnalysis: { mainGroup, category, color: colorStr, material, style, season, details },
    formattedAnalysis: {
      ana_grup: mainGroup,
      kategori: category,
      renk: colorStr,
      materyal: material,
      stil: style.join(', '),
      sezon: season.join(', '),
      detaylar: details
    },
    category: firestoreCategory,
    colors, // Array<String>
    colorsWithDominance,
    confidence,
    advancedAnalysis: {
      mainGroup,
      category,
      color: colorStr, // Primary color for backwards compatibility
      material,
      style: style.join(', '),
      season: season.join(', '),
      details,
      pattern,
      fit,
      confidence,
      rawAnalysis: JSON.stringify({ step1, step2 })
    },
    usage: {
      prompt_tokens: (response1.usage?.prompt_tokens || 0) + (response2.usage?.prompt_tokens || 0),
      completion_tokens: (response1.usage?.completion_tokens || 0) + (response2.usage?.completion_tokens || 0)
    }
  };
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
3. AÇIKLAMA KALİTESİ:
- Her kombin açıklaması en fazla 2 cümle olmalı.
- Açıklama genel stil etiketi tekrarı yapmasın (örn: sürekli "bohem tarzına uygun").
- Açıklama seçilen parçaları somut olarak anlatsın: parça tipi + renk + varsa materyal.
- Açıklamada mutlaka "neden bu parçalar birlikte iyi çalışıyor" bilgisi yer alsın (siluet, kontrast, doku, denge vb.).
- 3 kombinin açıklama cümle başlangıçları ve anlatım açısı birbirinden farklı olsun.

4. ÇIKTI FORMATI (SADECE bu formatı kullan):
KOMBİN 1:
ID: [dış giyim ID - varsa]
ID: [üst giyim ID]
ID: [alt giyim ID]
ID: [ayakkabı ID - varsa]
AÇIKLAMA: [Kombinin stil tanımı, max 3 cümle]
KULLANIM: [Giyilebileceği ortamlar]
TAMAMLAYICILAR: [Aksesuar önerileri]
SEZON: [Uygun mevsim(ler)]

Lütfen mümkünse TAM 3 FARKLI KOMBİN oluştur: Günlük (Casual), İş/Ofis (Formal), Spor veya Özel Durum.
Eğer parça sayısı yetmiyorsa yine en iyi alternatifleri üret ve eksikliği KULLANIM alanında kısaca belirt.`;

function formatUserProfileForPrompt(userProfile) {
  if (!userProfile || typeof userProfile !== 'object') return '';
  const parts = [];
  if (Array.isArray(userProfile.styleDNA) && userProfile.styleDNA.length > 0) {
    parts.push(`Stil tercihleri: ${userProfile.styleDNA.join(', ')}`);
  }
  if (Array.isArray(userProfile.colorBias) && userProfile.colorBias.length > 0) {
    parts.push(`Renk tercihi: ${userProfile.colorBias.join(', ')}`);
  }
  if (userProfile.fitPreference) {
    parts.push(`Fit tercihi: ${userProfile.fitPreference}`);
  }
  if (userProfile.lifestyle) {
    parts.push(`Yaşam tarzı: ${userProfile.lifestyle}`);
  }
  return parts.length > 0 ? `Kullanıcı profil bilgisi: ${parts.join('. ')}. Bu tercihlere uygun kombinler oluştur.` : '';
}

async function generateCombinations(openai, clothingItems, occasion = null, userProfile = null) {
  if (!clothingItems || clothingItems.length === 0) {
    throw new Error('Dolabınızda henüz kıyafet bulunmuyor. Önce kıyafet eklemelisiniz.');
  }
  const idField = (item) => item.id || item._id;
  const descriptions = clothingItems.map((item) => {
    const adv = item.advancedAnalysis || {};
    return `[Kıyafet ${idField(item)}]
ID: ${idField(item)}
Ana Grup: ${item.category || 'top'}
Kategori: ${item.category}
Başlık: ${item.title || 'Kıyafet'}
Renk: ${(item.colors && item.colors.join) ? item.colors.join(', ') : (adv.color || 'Belirtilmemiş')}
Materyal: ${adv.material || 'Belirtilmemiş'}
Stil: ${adv.style || 'Belirtilmemiş'}
Sezon: ${adv.season || 'Belirtilmemiş'}
Detaylar: ${adv.details || 'Belirtilmemiş'}
-------------------`;
  }).join('\n\n');

  const occasionHint = occasion ? `\nKullanıcı ${occasion} ortamı için kombin istiyor.` : '';
  const profileHint = formatUserProfileForPrompt(userProfile);

  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'system', content: COMBINATION_SYSTEM },
      {
        role: 'user',
        content: `Mevcut Kıyafetlerim:\n${descriptions}${occasionHint}${profileHint ? '\n' + profileHint : ''}

Lütfen bu kıyafetlerle 3 FARKLI KOMBİN oluştur.
Ek zorunlu kurallar:
- AÇIKLAMA kısmı 2 cümleyi geçmesin.
- "X tarzına uygun" gibi kalıp ifadeleri 3 kombinde tekrar etme.
- Her açıklamada seçilen parçaları (renk + parça türü) belirt ve uyum nedenini anlat.
- Üç açıklama birbirinden farklı yazılsın, aynı cümle şablonunu kopyalama.
- Eğer bir kategoride yeterli kıyafet yoksa mevcut parçalarla en iyi alternatifi ver ve bunu KULLANIM satırında kısa belirt.`
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

/**
 * Detect chat intent from user message (rule-based).
 * @returns {'wardrobe_question'|'combination_advice'|'style_chat'}
 */
function detectChatIntent(message) {
  if (!message || typeof message !== 'string') return 'style_chat';
  const t = message.toLowerCase().trim();

  const wardrobePatterns = [
    /dolabım|dolabim|dolabı|gardırop|gardrop|gardırobum/,
    /eksik\s+ne|ne\s+eksik|ne\s+var|nasıl\s+dolap|dolap\s+nasıl/,
    /satın\s+al|satin\s+al|almam\s+gerek|öner.*al|al.*öner/,
    /kaç\s+parça|toplam|kategori|dağılım/
  ];
  if (wardrobePatterns.some((p) => p.test(t))) return 'wardrobe_question';

  const combinationPatterns = [
    /bugün\s+ne\s+giy|ne\s+giysem|ne\s+giyeyim|ne\s+giyeyim/,
    /kombin\s+öner|kombin\s+ver|outfit|kombin\s+yap/,
    /giyeceğim|giyecegim|giyeyim|giysem/
  ];
  if (combinationPatterns.some((p) => p.test(t))) return 'combination_advice';

  return 'style_chat';
}

/** Format wardrobe summary object for system prompt. */
function formatWardrobeSummaryForPrompt(summary) {
  if (!summary || typeof summary !== 'object') return '';
  const counts = summary.counts || {};
  const styles = summary.dominant_styles || [];
  const colors = summary.dominant_colors || [];
  const seasons = summary.seasons || [];
  const missing = summary.missing_categories || [];
  const total = summary.total_items ?? 0;
  const conf = summary.confidence_level ?? 'medium';

  const parts = [
    `Toplam kıyafet: ${total}. Güven: ${conf}.`,
    `Kategori sayıları: ${JSON.stringify(counts)}.`,
    `Baskın stiller: ${styles.join(', ') || 'belirsiz'}.`,
    `Baskın renkler: ${colors.join(', ') || 'belirsiz'}.`,
    `Sezonlar: ${seasons.join(', ') || 'belirsiz'}.`
  ];
  if (missing.length > 0) {
    parts.push(`Eksik kategoriler: ${missing.join(', ')}. (Bunları asla varmış gibi söyleme.)`);
  }
  return parts.join(' ');
}

const CHAT_BASE_RULES = `Sen bir profesyonel kişisel stil danışmanısın.
- Kombin oluşturma kurallarını ihlal etme.
- Dolapta olmayan ürünü varmış gibi söyleme.
- Eksik kategori varsa açıkça belirt; pozitif dil kullan (örn: "Ayakkabı eklemen kombin tamamlar").
- Kısa, net ve Türkçe cevap ver.
- ID üretme, fiyat verme, link verme, "şu ürünü satın al" deme.
- İstersen "Dolabına uygun ayakkabı türü önerebilirim" gibi yönlendirici bitir.`;

const MODE1_PROMPT = `Mod: Dolap hakkında soru.
Kullanıcı dolabını soruyor. Wardrobe summary'e göre: eksik kategorileri söyle, satın alma tavsiyesi ver (genel, ürün önermeden).
${CHAT_BASE_RULES}`;

const MODE2_PROMPT = (missingCategories) => `Mod: Kombin danışma.
Kombin motoru sonuçlarını doğal dille özetle. ID kullanma.
${missingCategories.length > 0 ? `Eksik kategoriler (${missingCategories.join(', ')}): Açıkça belirt, mevcut parçalarla öner, eksik olanı tamamlamak için genel tavsiye ver (örn: beyaz sneaker).` : ''}
${CHAT_BASE_RULES}`;

const MODE3_PROMPT = `Mod: Stil sohbeti.
Dolap verisine göre kişiselleştir, genel stil bilgisi ekle.
${CHAT_BASE_RULES}`;

/**
 * Get style advice with mode-based behavior.
 * @param {Object} openai - OpenAI client
 * @param {string} message - User message
 * @param {Array} conversationHistory - Max 5 messages [{role, content}]
 * @param {Object} wardrobeSummary - Wardrobe summary JSON from client
 * @param {Object} [options] - { combinationResult, occasion }
 * @param {Object} options.combinationResult - For mode 2: { combinations: [...] }
 * @param {string} options.occasion - For mode 2 context
 */
async function getStyleAdvice(openai, message, conversationHistory = [], wardrobeSummary, options = {}) {
  const history = Array.isArray(conversationHistory) ? conversationHistory.slice(-5) : [];
  const intent = detectChatIntent(message);
  const mode = intent === 'wardrobe_question' ? 1 : intent === 'combination_advice' ? 2 : 3;

  const summaryStr = formatWardrobeSummaryForPrompt(wardrobeSummary);
  const missingCategories = (wardrobeSummary && wardrobeSummary.missing_categories) || [];

  let systemContent = '';
  let userContent = message;

  if (mode === 1) {
    systemContent = MODE1_PROMPT;
    if (summaryStr) {
      systemContent += `\n\nKullanıcının gardırop özeti: ${summaryStr}`;
    }
  } else if (mode === 2 && options.combinationResult && options.combinationResult.combinations && options.combinationResult.combinations.length > 0) {
    systemContent = MODE2_PROMPT(missingCategories);
    if (summaryStr) {
      systemContent += `\n\nGardırop özeti: ${summaryStr}`;
    }
    const combos = options.combinationResult.combinations;
    const comboText = combos.map((c, i) => {
      const desc = c.description || '';
      const occ = c.occasion || c.usage || '';
      const acc = c.accessories || '';
      const sea = c.season || '';
      return `Kombin ${i + 1}: ${desc} Kullanım: ${occ}. Aksesuar: ${acc}. Sezon: ${sea}.`;
    }).join('\n');
    userContent = `Kullanıcı kombin istedi. Kombin motoru şu önerileri üretti:\n${comboText}\n\nBunları doğal dille özetle. ID kullanma.`;
  } else if (mode === 2) {
    systemContent = MODE2_PROMPT(missingCategories);
    if (summaryStr) {
      systemContent += `\n\nGardırop özeti: ${summaryStr}`;
    }
    systemContent += '\n\nNot: Kombin oluşturmak için yeterli kıyafet yok veya motor sonuç dönmedi. Mevcut dolaba göre genel kombin tavsiyesi ver.';
    userContent = message;
  } else {
    systemContent = MODE3_PROMPT;
    if (summaryStr) {
      systemContent += `\n\nGardırop özeti: ${summaryStr}`;
    }
    userContent = message;
  }

  const messages = [{ role: 'system', content: systemContent }];
  for (const msg of history) {
    messages.push({
      role: msg.role === 'user' ? 'user' : 'assistant',
      content: msg.content || msg.message || ''
    });
  }
  messages.push({ role: 'user', content: userContent });

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

const SELECT_DESCRIBE_SCHEMA = {
  type: 'object',
  properties: {
    combinations: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          index: { type: 'integer', description: 'Aday indeksi (0-based)' },
          aciklama: { type: 'string', description: 'Kombin açıklaması' },
          kullanim: { type: 'string', description: 'Giyilebileceği ortamlar' },
          tamamlayicilar: { type: 'string', description: 'Aksesuar önerileri' },
          sezon: { type: 'string', description: 'Uygun mevsim' }
        },
        required: ['index', 'aciklama', 'kullanim', 'tamamlayicilar', 'sezon'],
        additionalProperties: false
      }
    }
  },
  required: ['combinations'],
  additionalProperties: false
};

async function selectAndDescribeCombinations(openai, candidates, occasion, userProfile = null) {
  if (!candidates || candidates.length === 0) {
    return { success: true, combinations: [], usage: { prompt_tokens: 0, completion_tokens: 0 } };
  }

  const idField = (item) => item.id || item._id;
  const candidateDesc = candidates.map((c, i) => {
    const items = c.items || [];
    const ids = items.map(idField);
    const names = items.map(it => it.title || it.category || idField(it)).join(', ');
    return `[Aday ${i}] ID'ler: ${ids.join(', ')} | Parçalar: ${names}`;
  }).join('\n');

  const occasionHint = occasion ? ` Kullanıcı ${occasion} ortamı için kombin istiyor.` : '';
  const profileHint = formatUserProfileForPrompt(userProfile);
  const systemContent = `Sen bir profesyonel stilistsin. Verilen kombin adaylarından en uyumlu olanları seç ve her biri için kısa açıklama yaz.${occasionHint}${profileHint ? ' ' + profileHint : ''}
Kurallar:
- Mümkünse 3 kombin seç.
- aciklama alanı en fazla 2 cümle olsun.
- aciklama, "bohem tarzına uygun" benzeri kalıp tekrarları yapmasın.
- aciklama içinde seçilen parçaları somut anlat (renk/parça) ve kombin mantığını belirt.
- 3 kombinin anlatım dili birbirinden farklı olsun.`;

  const targetCount = Math.min(3, candidates.length);

  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      {
        role: 'system',
        content: systemContent
      },
      {
        role: 'user',
        content: `Kombin adayları:\n${candidateDesc}

Her aday için index (0'dan başlayarak), aciklama (max 2 cümle), kullanim, tamamlayicilar ve sezon döndür.
En fazla ${targetCount} kombin seç.
aciklama yazım kuralları:
- Genel stil etiketi tekrarı yapma.
- Somut parça uyumu anlat (ör: beyaz gömlek + lacivert pantolon dengesi).
- Her kombin açıklamasında farklı bir anlatım açısı kullan.`
      }
    ],
    response_format: {
      type: 'json_schema',
      json_schema: {
        name: 'select_combinations',
        strict: true,
        schema: SELECT_DESCRIBE_SCHEMA
      }
    },
    max_tokens: 600
  });

  const content = response.choices[0].message.content;
  let parsed;
  try {
    parsed = JSON.parse(content);
  } catch (e) {
    parsed = { combinations: [] };
  }

  const seenIndexes = new Set();
  const normalized = [];
  for (const desc of (parsed.combinations || [])) {
    const idx = typeof desc.index === 'number' ? desc.index : -1;
    if (idx < 0 || idx >= candidates.length || seenIndexes.has(idx)) continue;
    seenIndexes.add(idx);
    normalized.push(desc);
    if (normalized.length >= targetCount) break;
  }

  // Fallback: model 3'ten az seçim döndürürse, kalan adaylardan tamamla.
  if (normalized.length < targetCount) {
    for (let idx = 0; idx < candidates.length && normalized.length < targetCount; idx++) {
      if (seenIndexes.has(idx)) continue;
      seenIndexes.add(idx);
      const candidate = candidates[idx];
      const partNames = (candidate.items || [])
        .map((it) => it.title || it.category || 'parça')
        .slice(0, 3)
        .join(', ');
      normalized.push({
        index: idx,
        aciklama: `${partNames} birlikte dengeli bir görünüm oluşturur. Parça oranları ve renk geçişleri kombini tutarlı hale getirir.`,
        kullanim: occasion || 'Günlük kullanım',
        tamamlayicilar: 'Minimal takı veya sade çanta',
        sezon: 'all-season'
      });
    }
  }

  const combinations = normalized.map((desc, i) => {
    const idx = typeof desc.index === 'number' ? desc.index : i;
    const candidate = candidates[idx];
    const items = candidate && candidate.items ? candidate.items.map(idField) : [];
    return {
      name: getCombinationName(i + 1),
      items,
      occasion: mapUsageToOccasion(desc.kullanim),
      description: desc.aciklama || '',
      season: desc.sezon || 'all-season',
      accessories: desc.tamamlayicilar || '',
      usage: desc.kullanim || ''
    };
  }).filter(c => c.items.length > 0);

  return {
    success: true,
    combinations,
    rawResponse: content,
    usage: {
      prompt_tokens: response.usage?.prompt_tokens || 0,
      completion_tokens: response.usage?.completion_tokens || 0
    }
  };
}

async function generateStylingAdvice(openai, singleItem, occasion) {
  const idField = (item) => item.id || item._id;
  const adv = singleItem.advancedAnalysis || {};
  const desc = `Parça: ${singleItem.title || 'Kıyafet'} | ID: ${idField(singleItem)}
Kategori: ${singleItem.category}
Renk: ${(singleItem.colors || []).join(', ') || adv.color || 'Belirtilmemiş'}
Materyal: ${adv.material || 'Belirtilmemiş'}
Stil: ${adv.style || 'Belirtilmemiş'}`;

  const occasionHint = occasion ? ` Kullanıcı ${occasion} ortamı için öneri istiyor.` : '';

  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      {
        role: 'system',
        content: `Sen bir profesyonel stilistsin. Kullanıcının sadece bir parça kıyafeti var. Bu parçayı nasıl kombinleyebileceğine dair kısa, pratik öneriler ver. Örn: "Bu üstü koyu renk slim fit jean ile kombinleyebilirsin."${occasionHint}`
      },
      { role: 'user', content: desc }
    ],
    temperature: 0.7,
    max_tokens: 300
  });

  return {
    success: true,
    advice: response.choices[0].message.content,
    itemId: idField(singleItem),
    usage: {
      prompt_tokens: response.usage?.prompt_tokens || 0,
      completion_tokens: response.usage?.completion_tokens || 0
    }
  };
}

async function getShoppingSuggestions(openai, wardrobeSummary, userProfile = null) {
  const summaryStr = formatWardrobeSummaryForPrompt(wardrobeSummary);
  const profileHint = formatUserProfileForPrompt(userProfile);

  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'system', content: SHOPPING_SUGGESTIONS_SYSTEM },
      {
        role: 'user',
        content: `İşte kullanıcının gardırop özeti: ${summaryStr}\n${profileHint}\n\nLütfen bu verilere dayanarak alışveriş önerileri oluştur.`
      }
    ],
    response_format: {
      type: 'json_schema',
      json_schema: {
        name: 'shopping_suggestions',
        strict: true,
        schema: SHOPPING_SUGGESTIONS_SCHEMA
      }
    },
    temperature: 0.5,
    max_tokens: 1000
  });

  const content = response.choices[0].message.content;
  let parsed;
  try {
    parsed = JSON.parse(content);
  } catch (e) {
    throw new Error('Alışveriş önerileri yanıtı işlenemedi.');
  }

  return {
    success: true,
    suggestions: parsed,
    usage: {
      prompt_tokens: response.usage?.prompt_tokens || 0,
      completion_tokens: response.usage?.completion_tokens || 0
    }
  };
}

module.exports = {
  analyzeClothingFromUrl,
  generateCombinations,
  selectAndDescribeCombinations,
  generateStylingAdvice,
  getStyleAdvice,
  getShoppingSuggestions, // Added
  detectChatIntent,
  mapMainGroupToCategory: mapMainGroupToFirestore,
  parseOutfits
};

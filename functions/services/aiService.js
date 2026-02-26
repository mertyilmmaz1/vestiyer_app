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
const { getPrompts } = require('./prompts');
const { t } = require('./i18n');



function buildShoppingSuggestionsSchema(locale) {
  const d = getPrompts(locale).SHOPPING_SCHEMA_DESCRIPTIONS;
  return {
    type: 'object',
    properties: {
      missingEssensials: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            item: { type: 'string', description: d.missingItem },
            reason: { type: 'string', description: d.missingReason },
            compatibility: { type: 'string', description: d.missingCompatibility }
          },
          required: ['item', 'reason', 'compatibility'],
          additionalProperties: false
        },
        description: d.missingEssensials
      },
      complementarySuggestions: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            item: { type: 'string', description: d.complementaryItem },
            completes: { type: 'string', description: d.complementaryCompletes },
            styleTip: { type: 'string', description: d.complementaryStyleTip }
          },
          required: ['item', 'completes', 'styleTip'],
          additionalProperties: false
        },
        description: d.complementarySuggestions
      },
      seasonalEssentials: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            item: { type: 'string', description: d.seasonalItem },
            reason: { type: 'string', description: d.seasonalReason }
          },
          required: ['item', 'reason'],
          additionalProperties: false
        },
        description: d.seasonalEssentials
      }
    },
    required: ['missingEssensials', 'complementarySuggestions', 'seasonalEssentials'],
    additionalProperties: false
  };
}

function buildClothingAnalysisSchema(locale) {
  const prompts = getPrompts(locale);
  const d = prompts.ANALYSIS_SCHEMA_DESCRIPTIONS || {};
  const step1 = prompts.STEP1_SCHEMA_DESCRIPTIONS || {};
  const step2 = prompts.STEP2_SCHEMA_DESCRIPTIONS || {};
  const resolveDescription = {
    mainGroup: d.mainGroup || step1.mainGroup || ((groups) => `Main group: ${groups.join(', ')}`),
    category: d.category || step1.category || 'Category',
    material: d.material || step1.material || ((materials) => `Material: ${materials.join(', ')}`),
    pattern: d.pattern || step1.pattern || 'Pattern',
    fit: d.fit || step1.fit || 'Fit',
    colors: d.colors || step1.colors || 'Dominant colors',
    mainColorHex: d.mainColorHex || step1.mainColorHex || 'Main HEX color',
    style: d.style || step2.style || 'Style list',
    season: d.season || step2.season || 'Season list',
    details: d.details || step2.details || 'Details',
    confidence: d.confidence || step1.confidence || 'Confidence score'
  };
  return {
    type: 'object',
    properties: {
      mainGroup: {
        type: 'string',
        enum: MAIN_GROUPS,
        description: resolveDescription.mainGroup(MAIN_GROUPS)
      },
      category: {
        type: 'string',
        description: resolveDescription.category
      },
      material: {
        type: 'string',
        enum: MATERIALS,
        description: resolveDescription.material(MATERIALS)
      },
      pattern: {
        type: 'string',
        enum: PATTERN_VALUES,
        description: resolveDescription.pattern
      },
      fit: {
        type: 'string',
        enum: FIT_VALUES,
        description: resolveDescription.fit
      },
      colors: {
        type: 'array',
        items: { type: 'string' },
        minItems: 1,
        maxItems: 3,
        description: resolveDescription.colors
      },
      mainColorHex: {
        type: 'string',
        description: resolveDescription.mainColorHex
      },
      style: {
        type: 'array',
        items: { type: 'string' },
        minItems: 1,
        maxItems: 5,
        description: resolveDescription.style
      },
      season: {
        type: 'array',
        items: { type: 'string' },
        minItems: 1,
        maxItems: 4,
        description: resolveDescription.season
      },
      details: {
        type: 'string',
        description: resolveDescription.details
      },
      confidence: {
        type: 'number',
        description: resolveDescription.confidence
      }
    },
    required: [
      'mainGroup',
      'category',
      'material',
      'pattern',
      'fit',
      'colors',
      'mainColorHex',
      'style',
      'season',
      'details',
      'confidence'
    ],
    additionalProperties: false
  };
}

function mapUsageToOccasion(usage) {
  if (!usage) return 'casual';
  const u = (usage || '').toLowerCase();
  if (/iş|ofis|formal|görüşme|çalış|work|office|business/.test(u)) return 'work';
  if (/spor|aktif|egzersiz|sport|exercise|active/.test(u)) return 'sport';
  if (/parti|özel|davet|akşam|gece|party|evening|special/.test(u)) return 'party';
  if (/günlük|casual|evde|daily|everyday|home/.test(u)) return 'daily';
  if (/resmi|töreni|ceremony/.test(u)) return 'formal';
  return 'casual';
}

function normalizeStringArray(value, fallback) {
  if (Array.isArray(value)) {
    const normalized = value
      .map((x) => (typeof x === 'string' ? x.trim() : ''))
      .filter(Boolean);
    if (normalized.length > 0) return normalized;
  }
  if (typeof value === 'string' && value.trim()) {
    return [value.trim()];
  }
  return fallback;
}

function normalizeHexColor(value) {
  if (typeof value !== 'string') return null;
  const v = value.trim();
  if (!v) return null;
  const fullHex = /^#[0-9A-Fa-f]{6}$/;
  const shortHex = /^#[0-9A-Fa-f]{3}$/;
  if (fullHex.test(v)) return v.toUpperCase();
  if (!shortHex.test(v)) return null;
  const r = v[1];
  const g = v[2];
  const b = v[3];
  return `#${r}${r}${g}${g}${b}${b}`.toUpperCase();
}

function buildColorDominance(colors, mainHex) {
  if (!Array.isArray(colors) || colors.length === 0) return [];
  const cleaned = colors
    .map((c) => (typeof c === 'string' ? c.trim() : ''))
    .filter(Boolean)
    .slice(0, 3);
  if (cleaned.length === 0) return [];

  if (cleaned.length === 1) {
    return [{ name: cleaned[0], dominance: 1, hex: mainHex || null }];
  }

  if (cleaned.length === 2) {
    return [
      { name: cleaned[0], dominance: 0.75, hex: mainHex || null },
      { name: cleaned[1], dominance: 0.25, hex: null }
    ];
  }

  return [
    { name: cleaned[0], dominance: 0.6, hex: mainHex || null },
    { name: cleaned[1], dominance: 0.25, hex: null },
    { name: cleaned[2], dominance: 0.15, hex: null }
  ];
}

async function analyzeClothingFromUrl(openai, imageUrl, backendColors = null, locale = 'tr') {
  const prompts = getPrompts(locale);
  const F = prompts.FORMAT_STRINGS;
  const analyzePrompt = prompts.ANALYZE_CLOTHING_PROMPT || prompts.STEP1_PROMPT;

  const response = await openai.chat.completions.create({
    model: 'gpt-4o',
    messages: [
      {
        role: 'user',
        content: [
          { type: 'text', text: analyzePrompt },
          { type: 'image_url', image_url: { url: imageUrl } }
        ]
      }
    ],
    response_format: {
      type: 'json_schema',
      json_schema: {
        name: 'clothing_analysis',
        strict: true,
        schema: buildClothingAnalysisSchema(locale)
      }
    },
    max_tokens: 700
  });

  const content = response.choices[0].message.content;
  let analysis;
  try {
    analysis = JSON.parse(content);
  } catch (e) {
    analysis = {
      mainGroup: 'ust_giyim',
      category: 'tişört',
      material: 'pamuk',
      pattern: 'duz',
      fit: 'regular',
      colors: [F.unknownColor],
      mainColorHex: '#808080',
      style: ['casual'],
      season: ['tum_yil'],
      details: '',
      confidence: 0.35
    };
  }

  // Normalization
  const mainGroup = normalizeMainGroup(analysis.mainGroup);
  const category = normalizeCategory(mainGroup, analysis.category);
  const material = normalizeMaterial(analysis.material);
  const pattern = normalizePattern(analysis.pattern);
  const fit = normalizeFit(analysis.fit);
  const confidence = Math.max(0, Math.min(1, Number(analysis.confidence) || 0.8));

  // Color selection: AI is primary. Backend k-means is emergency fallback only.
  let colors = [];
  let colorsWithDominance = [];
  const mainColorHex = normalizeHexColor(analysis.mainColorHex);

  colors = normalizeStringArray(analysis.colors, []);
  if (colors.length > 0) {
    colorsWithDominance = buildColorDominance(colors, mainColorHex);
  } else if (backendColors && backendColors.length > 0) {
    colorsWithDominance = backendColors;
    colors = backendColors.map(c => c.name);
  } else {
    colors = [F.unknownColor];
    colorsWithDominance = [{ name: F.unknownColor, dominance: 1, hex: null }];
  }

  const colorStr = colors.join(', ');

  const style = normalizeStringArray(analysis.style, ['casual']);
  const season = normalizeStringArray(analysis.season, ['tum_yil']);
  const details = typeof analysis.details === 'string' ? analysis.details.trim() : '';

  const firestoreCategory = mapMainGroupToFirestore(mainGroup);

  return {
    success: true,
    rawAnalysis: JSON.stringify({ analysis }),
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
      rawAnalysis: JSON.stringify({ analysis })
    },
    usage: {
      prompt_tokens: response.usage?.prompt_tokens || 0,
      completion_tokens: response.usage?.completion_tokens || 0
    }
  };
}

function parseOutfits(content, locale = 'tr') {
  const fmt = getPrompts(locale).COMBINATION_PARSE_FORMAT;
  const sections = content.split(fmt.sectionPattern);
  const outfits = [];
  for (let i = 1; i < sections.length; i++) {
    const section = sections[i].trim();
    const lines = section.split('\n');
    const outfit = { outfit_number: i, items: [], details: {} };
    for (let j = 0; j < lines.length; j++) {
      const line = lines[j].trim();
      if (line.startsWith(fmt.idLabel)) {
        const id = line.replace(fmt.idLabel, '').trim();
        if (id && id !== '-' && id !== 'varsa') outfit.items.push(id);
      } else if (line.startsWith(fmt.aciklamaLabel)) {
        outfit.details.aciklama = line.replace(fmt.aciklamaLabel, '').trim();
      } else if (line.startsWith(fmt.kullanimLabel)) {
        outfit.details.kullanim = line.replace(fmt.kullanimLabel, '').trim();
      } else if (line.startsWith(fmt.tamamlayicilarLabel)) {
        outfit.details.tamamlayicilar = line.replace(fmt.tamamlayicilarLabel, '').trim();
      } else if (line.startsWith(fmt.sezonLabel)) {
        outfit.details.sezon = line.replace(fmt.sezonLabel, '').trim();
      }
    }
    outfits.push(outfit);
  }
  return outfits;
}

function formatUserProfileForPrompt(userProfile, locale = 'tr') {
  if (!userProfile || typeof userProfile !== 'object') return '';
  const F = getPrompts(locale).FORMAT_STRINGS;
  const parts = [];
  if (Array.isArray(userProfile.styleDNA) && userProfile.styleDNA.length > 0) {
    parts.push(`${F.stylePreferences}: ${userProfile.styleDNA.join(', ')}`);
  }
  if (Array.isArray(userProfile.colorBias) && userProfile.colorBias.length > 0) {
    parts.push(`${F.colorPreference}: ${userProfile.colorBias.join(', ')}`);
  }
  if (userProfile.fitPreference) {
    parts.push(`${F.fitPreference}: ${userProfile.fitPreference}`);
  }
  if (userProfile.lifestyle) {
    parts.push(`${F.lifestyle}: ${userProfile.lifestyle}`);
  }
  return parts.length > 0 ? `${F.profilePrefix}: ${parts.join('. ')}. ${F.profileSuffix}` : '';
}

async function generateCombinations(openai, clothingItems, occasion = null, userProfile = null, locale = 'tr') {
  if (!clothingItems || clothingItems.length === 0) {
    throw new Error(t(locale, 'errors.wardrobeEmpty'));
  }
  const prompts = getPrompts(locale);
  const L = prompts.WARDROBE_LABELS;
  const F = prompts.FORMAT_STRINGS;
  const idField = (item) => item.id || item._id;
  const descriptions = clothingItems.map((item) => {
    const adv = item.advancedAnalysis || {};
    return `[${L.clothing} ${idField(item)}]
ID: ${idField(item)}
${L.mainGroup}: ${item.category || 'top'}
${L.category}: ${item.category}
${L.title}: ${item.title || L.clothing}
${L.color}: ${(item.colors && item.colors.join) ? item.colors.join(', ') : (adv.color || L.notSpecified)}
${L.material}: ${adv.material || L.notSpecified}
${L.style}: ${adv.style || L.notSpecified}
${L.season}: ${adv.season || L.notSpecified}
${L.details}: ${adv.details || L.notSpecified}
-------------------`;
  }).join('\n\n');

  const occasionHint = occasion ? F.occasionHint(occasion) : '';
  const profileHint = formatUserProfileForPrompt(userProfile, locale);

  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'system', content: prompts.COMBINATION_SYSTEM },
      {
        role: 'user',
        content: `${prompts.WARDROBE_INTRO}:\n${descriptions}${occasionHint}${profileHint ? '\n' + profileHint : ''}

${prompts.GENERATE_COMBINATIONS_USER_EXTRA}`
      }
    ],
    temperature: 0.2,
    max_tokens: 1200
  });

  const content = response.choices[0].message.content;
  const parsedOutfits = parseOutfits(content, locale);
  const combinations = parsedOutfits.slice(0, 3).map((outfit) => ({
    name: prompts.getCombinationName(outfit.outfit_number),
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
  const lower = message.toLowerCase().trim();

  const wardrobePatterns = [
    /dolabım|dolabim|dolabı|gardırop|gardrop|gardırobum/,
    /eksik\s+ne|ne\s+eksik|ne\s+var|nasıl\s+dolap|dolap\s+nasıl/,
    /satın\s+al|satin\s+al|almam\s+gerek|öner.*al|al.*öner/,
    /kaç\s+parça|toplam|kategori|dağılım/,
    /\bwardrobe\b|\bcloset\b|what'?s?\s+missing|what\s+to\s+buy|how\s+many\s+items|outfit\s+count/
  ];
  if (wardrobePatterns.some((p) => p.test(lower))) return 'wardrobe_question';

  const combinationPatterns = [
    /bugün\s+ne\s+giy|ne\s+giysem|ne\s+giyeyim|ne\s+giyeyim/,
    /kombin\s+öner|kombin\s+ver|outfit|kombin\s+yap/,
    /giyeceğim|giyecegim|giyeyim|giysem/,
    /what\s+should\s+i\s+wear|what\s+to\s+wear|outfit\s+suggestion|suggest\s+an?\s+outfit|pick\s+my\s+outfit/
  ];
  if (combinationPatterns.some((p) => p.test(lower))) return 'combination_advice';

  return 'style_chat';
}

/** Format wardrobe summary object for system prompt. */
function formatWardrobeSummaryForPrompt(summary, locale = 'tr') {
  if (!summary || typeof summary !== 'object') return '';
  const F = getPrompts(locale).FORMAT_STRINGS;
  const counts = summary.counts || {};
  const styles = summary.dominant_styles || [];
  const colors = summary.dominant_colors || [];
  const seasons = summary.seasons || [];
  const missing = summary.missing_categories || [];
  const total = summary.total_items ?? 0;
  const conf = summary.confidence_level ?? 'medium';

  const parts = [
    `${F.totalClothing}: ${total}. ${F.confidence}: ${conf}.`,
    `${F.categoryCounts}: ${JSON.stringify(counts)}.`,
    `${F.dominantStyles}: ${styles.join(', ') || F.unknown}.`,
    `${F.dominantColors}: ${colors.join(', ') || F.unknown}.`,
    `${F.seasons}: ${seasons.join(', ') || F.unknown}.`
  ];
  if (missing.length > 0) {
    parts.push(`${F.missingCategories}: ${missing.join(', ')}. (${F.missingCategoriesWarning})`);
  }
  return parts.join(' ');
}

/**
 * Get style advice with mode-based behavior.
 * @param {Object} openai - OpenAI client
 * @param {string} message - User message
 * @param {Array} conversationHistory - Max 5 messages [{role, content}]
 * @param {Object} wardrobeSummary - Wardrobe summary JSON from client
 * @param {Object} [options] - { combinationResult, occasion }
 * @param {Object} options.combinationResult - For mode 2: { combinations: [...] }
 * @param {string} options.occasion - For mode 2 context
 * @param {string} [locale='tr'] - Locale for prompts
 */
async function getStyleAdvice(openai, message, conversationHistory = [], wardrobeSummary, options = {}, locale = 'tr') {
  const prompts = getPrompts(locale);
  const F = prompts.FORMAT_STRINGS;
  const history = Array.isArray(conversationHistory) ? conversationHistory.slice(-5) : [];
  const intent = detectChatIntent(message);
  const mode = intent === 'wardrobe_question' ? 1 : intent === 'combination_advice' ? 2 : 3;

  const summaryStr = formatWardrobeSummaryForPrompt(wardrobeSummary, locale);
  const missingCategories = (wardrobeSummary && wardrobeSummary.missing_categories) || [];

  let systemContent = '';
  let userContent = message;

  if (mode === 1) {
    systemContent = prompts.MODE1_PROMPT;
    if (summaryStr) {
      systemContent += `\n\n${F.wardrobeSummaryLabel}: ${summaryStr}`;
    }
  } else if (mode === 2 && options.combinationResult && options.combinationResult.combinations && options.combinationResult.combinations.length > 0) {
    systemContent = prompts.mode2Prompt(missingCategories);
    if (summaryStr) {
      systemContent += `\n\n${F.wardrobeSummaryShort}: ${summaryStr}`;
    }
    const combos = options.combinationResult.combinations;
    const comboText = combos.map((c, i) => {
      const desc = c.description || '';
      const occ = c.occasion || c.usage || '';
      const acc = c.accessories || '';
      const sea = c.season || '';
      return `${F.comboLabel} ${i + 1}: ${desc} ${F.usageLabel}: ${occ}. ${F.accessoryLabel}: ${acc}. ${F.seasonLabel}: ${sea}.`;
    }).join('\n');
    userContent = `${F.userRequestedOutfit}:\n${comboText}\n\n${F.summarizeInstructions}`;
  } else if (mode === 2) {
    systemContent = prompts.mode2Prompt(missingCategories);
    if (summaryStr) {
      systemContent += `\n\n${F.wardrobeSummaryShort}: ${summaryStr}`;
    }
    systemContent += `\n\n${F.noEngineResult}`;
    userContent = message;
  } else {
    systemContent = prompts.MODE3_PROMPT;
    if (summaryStr) {
      systemContent += `\n\n${F.wardrobeSummaryShort}: ${summaryStr}`;
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

function buildSelectDescribeSchema(locale) {
  const d = getPrompts(locale).SELECT_DESCRIBE_SCHEMA_DESCRIPTIONS;
  return {
    type: 'object',
    properties: {
      combinations: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            index: { type: 'integer', description: d.index },
            aciklama: { type: 'string', description: d.aciklama },
            kullanim: { type: 'string', description: d.kullanim },
            tamamlayicilar: { type: 'string', description: d.tamamlayicilar },
            sezon: { type: 'string', description: d.sezon }
          },
          required: ['index', 'aciklama', 'kullanim', 'tamamlayicilar', 'sezon'],
          additionalProperties: false
        }
      }
    },
    required: ['combinations'],
    additionalProperties: false
  };
}

async function selectAndDescribeCombinations(openai, candidates, occasion, userProfile = null, locale = 'tr') {
  if (!candidates || candidates.length === 0) {
    return { success: true, combinations: [], usage: { prompt_tokens: 0, completion_tokens: 0 } };
  }

  const prompts = getPrompts(locale);
  const F = prompts.FORMAT_STRINGS;
  const idField = (item) => item.id || item._id;
  const candidateDesc = candidates.map((c, i) => {
    const items = c.items || [];
    const ids = items.map(idField);
    const names = items.map(it => it.title || it.category || idField(it)).join(', ');
    return `[${F.candidateLabel} ${i}] ${F.idsLabel}: ${ids.join(', ')} | ${F.piecesLabel}: ${names}`;
  }).join('\n');

  const occasionHint = occasion ? F.occasionHintAdvice(occasion) : '';
  const profileHint = formatUserProfileForPrompt(userProfile, locale);
  const systemContent = prompts.SELECT_DESCRIBE_SYSTEM(occasionHint, profileHint ? ' ' + profileHint : '');

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
        content: prompts.SELECT_DESCRIBE_USER(candidateDesc, targetCount)
      }
    ],
    response_format: {
      type: 'json_schema',
      json_schema: {
        name: 'select_combinations',
        strict: true,
        schema: buildSelectDescribeSchema(locale)
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

  const fallback = prompts.SELECT_DESCRIBE_FALLBACK;
  // Fallback: model 3'ten az seçim döndürürse, kalan adaylardan tamamla.
  if (normalized.length < targetCount) {
    for (let idx = 0; idx < candidates.length && normalized.length < targetCount; idx++) {
      if (seenIndexes.has(idx)) continue;
      seenIndexes.add(idx);
      const candidate = candidates[idx];
      const partNames = (candidate.items || [])
        .map((it) => it.title || it.category || F.pieceDefault)
        .slice(0, 3)
        .join(', ');
      normalized.push({
        index: idx,
        aciklama: `${partNames} ${fallback.defaultDescription}`,
        kullanim: occasion || fallback.usage,
        tamamlayicilar: fallback.accessories,
        sezon: fallback.season
      });
    }
  }

  const combinations = normalized.map((desc, i) => {
    const idx = typeof desc.index === 'number' ? desc.index : i;
    const candidate = candidates[idx];
    const items = candidate && candidate.items ? candidate.items.map(idField) : [];
    return {
      name: prompts.getCombinationName(i + 1),
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

async function generateStylingAdvice(openai, singleItem, occasion, locale = 'tr') {
  const prompts = getPrompts(locale);
  const L = prompts.WARDROBE_LABELS;
  const F = prompts.FORMAT_STRINGS;
  const idField = (item) => item.id || item._id;
  const adv = singleItem.advancedAnalysis || {};
  const desc = `${L.clothing}: ${singleItem.title || L.clothing} | ID: ${idField(singleItem)}
${L.category}: ${singleItem.category}
${L.color}: ${(singleItem.colors || []).join(', ') || adv.color || L.notSpecified}
${L.material}: ${adv.material || L.notSpecified}
${L.style}: ${adv.style || L.notSpecified}`;

  const occasionHint = occasion ? F.occasionHintAdvice(occasion) : '';

  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      {
        role: 'system',
        content: prompts.STYLING_ADVICE_SYSTEM(occasionHint)
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

async function getShoppingSuggestions(openai, wardrobeSummary, userProfile = null, locale = 'tr') {
  const prompts = getPrompts(locale);
  const summaryStr = formatWardrobeSummaryForPrompt(wardrobeSummary, locale);
  const profileHint = formatUserProfileForPrompt(userProfile, locale);

  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'system', content: prompts.SHOPPING_SUGGESTIONS_SYSTEM },
      {
        role: 'user',
        content: prompts.SHOPPING_SUGGESTIONS_USER(summaryStr, profileHint ? `\n${profileHint}` : '')
      }
    ],
    response_format: {
      type: 'json_schema',
      json_schema: {
        name: 'shopping_suggestions',
        strict: true,
        schema: buildShoppingSuggestionsSchema(locale)
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
    throw new Error(t(locale, 'errors.shoppingSuggestionsParse'));
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

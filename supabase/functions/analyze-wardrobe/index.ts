// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ClothingItem {
  id: string
  category: string
  description: string
  image_url: string
  color?: string
  material?: string
  main_group?: string
  style?: string
  season?: string
}

interface RequestBody {
  userId: string
}

// GPT-4.1-mini pricing
const GPT41_MINI_INPUT_PRICE_PER_1K_TOKENS = 0.0004
const GPT41_MINI_OUTPUT_PRICE_PER_1K_TOKENS = 0.0016

// Rate limiting constants
const RATE_LIMIT_WINDOW = 3600 // 1 hour in seconds
const FREE_TIER_LIMIT = 2 // 2 requests per hour for free users
const PREMIUM_TIER_LIMIT = 8 // 8 requests per hour for premium users

// Cache duration: 3 days in seconds
const CACHE_DURATION = 3 * 24 * 60 * 60

console.log("Starting wardrobe analysis function")

serve(async (req) => {
  // CORS için OPTIONS request'i
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { userId } = await req.json() as RequestBody

    // Supabase istemcisini oluştur
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Check if user exists and get their subscription status
    const { data: userData, error: userError } = await supabaseClient
      .from('user_profiles')
      .select('is_premium')
      .eq('id', userId)
      .single()

    // If user is not found in profiles, assume they are a free user
    const isPremium = userData?.is_premium ?? false;

    // Check for cached analysis (within last 3 days)
    const threeDaysAgo = new Date(Date.now() - CACHE_DURATION * 1000).toISOString()
    const { data: cachedAnalysis, error: cacheError } = await supabaseClient
      .from('wardrobe_analysis')
      .select('*')
      .eq('user_id', userId)
      .gte('created_at', threeDaysAgo)
      .order('created_at', { ascending: false })
      .limit(1)
      .single()

    if (cachedAnalysis && !cacheError) {
      console.log('Returning cached analysis from', cachedAnalysis.created_at)
      
      // Calculate time remaining until cache expiry
      const cacheExpiryDate = new Date(new Date(cachedAnalysis.created_at).getTime() + CACHE_DURATION * 1000)
      const timeUntilExpiry = Math.max(0, Math.floor((cacheExpiryDate.getTime() - Date.now()) / 1000))
      const hoursRemaining = Math.floor(timeUntilExpiry / 3600)
      const daysRemaining = Math.floor(hoursRemaining / 24)
      
      return new Response(
        JSON.stringify({
          success: true,
          analysis: cachedAnalysis.analysis_content,
          parsed_analysis: cachedAnalysis.parsed_analysis,
          is_cached: true,
          cache_info: {
            created_at: cachedAnalysis.created_at,
            expires_at: cacheExpiryDate.toISOString(),
            time_until_expiry: timeUntilExpiry,
            days_remaining: daysRemaining,
            hours_remaining: hoursRemaining % 24,
          }
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      )
    }

    /* Rate limiting temporarily disabled
    // Get user's API usage in the last hour
    const oneHourAgo = new Date(Date.now() - RATE_LIMIT_WINDOW * 1000).toISOString()
    const { data: recentUsage, error: usageError } = await supabaseClient
      .from('api_usage')
      .select('id')
      .eq('user_id', userId)
      .gte('timestamp', oneHourAgo)

    if (usageError) {
      console.error('Error checking API usage:', usageError)
      // Continue with default limits if there's an error checking usage
    }

    const requestCount = recentUsage?.length ?? 0
    const rateLimit = isPremium ? PREMIUM_TIER_LIMIT : FREE_TIER_LIMIT

    if (requestCount >= rateLimit) {
      return new Response(
        JSON.stringify({
          success: false,
          error: `Rate limit exceeded. Please wait before making another request. ${isPremium ? 'Premium users' : 'Free users'} are limited to ${rateLimit} requests per hour.`,
          nextAvailableTimestamp: new Date(Date.now() + RATE_LIMIT_WINDOW * 1000).toISOString(),
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 429, // Too Many Requests
        }
      )
    }
    */

    // Kullanıcının kıyafetlerini getir
    const { data: items, error: itemsError } = await supabaseClient
      .from('clothing_items')
      .select()
      .eq('user_id', userId)
      .order('created_at', { ascending: false })

    if (itemsError) {
      console.error('Error fetching clothing items:', itemsError)
      throw new Error('Kıyafetler yüklenirken bir hata oluştu')
    }

    if (!items || items.length === 0) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Dolabınızda henüz kıyafet bulunmuyor. Önce kıyafet eklemelisiniz.',
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400,
        }
      )
    }

    // Kıyafetleri prompt için formatla
    const clothingDescriptions = items.map((item: ClothingItem) => {
      return `[Kıyafet ${item.id}]
ID: ${item.id}
Ana Grup: ${item.main_group || 'Belirtilmemiş'}
Kategori: ${item.category || 'Belirtilmemiş'}
Renk: ${item.color || 'Belirtilmemiş'}
Materyal: ${item.material || 'Belirtilmemiş'}
Stil: ${item.style || 'Belirtilmemiş'}
Sezon: ${item.season || 'Belirtilmemiş'}
Detaylar: ${item.description || 'Belirtilmemiş'}
-------------------`
    }).join('\n\n')

    // ChatGPT API'ye istek at
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${Deno.env.get('OPENAI_API_KEY')}`,
      },
      body: JSON.stringify({
        model: 'gpt-4.1-mini',
        messages: [
          {
            role: 'system',
            content: `Sen bir profesyonel stilist ve kişisel gardrop danışmanısın. Kullanıcının mevcut kıyafet koleksiyonunu analiz ederek stil profilini çıkarıyor ve gardırop için tavsiyeler veriyorsun.

1. ANALİZ KURALLARI:
- Kullanıcının mevcut gardırobunu temel stil, renk paleti ve sezonluk dağılım açısından analiz et
- Gardıropta eksik olabilecek temel parçaları net ve kısa isimlerle belirt
- Renk uyumu ve çeşitlilik açısından değerlendirme yap
- Mevcut kıyafetlere uyumlu yeni parçalar önererek gardırobu zenginleştir
- Kullanıcının tarzını belirle ve bu tarzı güçlendirecek öneriler sun

2. SUNUM KURALLARI:
- Eksik parçalar ve alışveriş tavsiyeleri listesi için her öğe için net, kısa (5-6 kelimeyi geçmeyen) ve belirgin isimler kullan
- Her liste öğesi yeni bir satırda, madde işareti (-) ile başlamalı veya virgülle ayrılmalı
- Tüm ifadelerinde net, özlü ve doğrudan bir dil kullan
- Her bir bölüm için en az 3, en fazla 8 madde belirt
- Önerilerde marka adı kullanma, sadece tarz ve genel ürün tipi belirt

3. TARZı BELİRLEME:
- Gardıropta bulunan kıyafetlerin kategorisi, rengi ve stiline göre kullanıcının baskın stil tercihini belirle
- Stil kategorileri: Klasik, Casual, Minimalist, Sportif, Romantik, Vintage, Modern, Bohemian, Ofis, vb.
- Renk paletini belirle: sıcak tonlar, soğuk tonlar, nötrler, canlı renkler vs.

4. ÇIKTI FORMATI (SADECE bu formatı kullan, asla değiştirme):
STİL PROFİLİ:
BASKINTARZ: [Kullanıcının belirlediğin baskın tarzı]
RENKPALETİ: [Gardırobun renk özellikleri]
SEZONLAR: [Hangi sezonlar için kıyafetlerin daha fazla olduğu]

GARDROP TAVSİYELERİ:
EKSİKPARÇALAR: 
- [Gardıroba eklenmesi gereken ilk temel parça]
- [İkinci temel parça]
- [Üçüncü temel parça]
(en az 3, en fazla 8 parça)

STİLÖNERİLERİ: [Baskın tarzı tamamlayacak veya zenginleştirecek öneriler]

ALIŞVERİŞTAVSİYELERİ: 
- [Bir sonraki alışverişte bakılması önerilen ilk parça]
- [İkinci parça]
- [Üçüncü parça]
(en az 3, en fazla 8 parça)

NOT: Aslında sana verilen her bir kıyafeti dikkatli incele ve buna göre detaylı bir analiz çıkar.`
          },
          {
            role: 'user',
            content: `Mevcut Kıyafetlerim:
${clothingDescriptions}

Lütfen gardırobumu kapsamlı bir şekilde analiz ederek stil profilimi çıkar, gardırobumun güçlü ve zayıf yönlerini belirle, eksik parçaları tespit et ve alışveriş tavsiyeleri ver.`
          }
        ],
        temperature: 0.2,
        max_tokens: 1200,
      }),
    })

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${response.status} - ${await response.text()}`)
    }

    const data = await response.json()
    const content = data.choices[0].message.content

    // Parse wardrobe analysis to create structured output
    const analysis = parseWardrobeAnalysis(content)

    // API kullanım maliyetini hesapla
    const promptTokens = data.usage.prompt_tokens
    const completionTokens = data.usage.completion_tokens
    const cost = (promptTokens * GPT41_MINI_INPUT_PRICE_PER_1K_TOKENS / 1000) +
      (completionTokens * GPT41_MINI_OUTPUT_PRICE_PER_1K_TOKENS / 1000)

    // Save API usage to database
    try {
      await supabaseClient.from('api_usage').insert({
        user_id: userId,
        model: 'gpt-4.1-mini (gardırop analizi)',
        prompt_tokens: promptTokens,
        completion_tokens: completionTokens,
        cost: cost,
        timestamp: new Date().toISOString(),
      })
    } catch (error) {
      console.error('Error saving API usage:', error)
      // Continue even if saving usage fails
    }

    // Save analysis to database (first check if there's an old cached analysis and delete it)
    try {
      // Delete any old analysis for this user
      await supabaseClient
        .from('wardrobe_analysis')
        .delete()
        .eq('user_id', userId)

      // Insert new analysis
      await supabaseClient.from('wardrobe_analysis').insert({
        user_id: userId,
        analysis_content: content,
        parsed_analysis: analysis,
        created_at: new Date().toISOString(),
      })
    } catch (error) {
      console.error('Error saving analysis to database:', error)
      // Continue even if saving analysis fails
    }

    return new Response(
      JSON.stringify({
        success: true,
        analysis: content,
        parsed_analysis: analysis,
        is_cached: false,
        usage: {
          prompt_tokens: promptTokens,
          completion_tokens: completionTokens,
          total_cost: cost
        }
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})

// Helper function to parse wardrobe analysis
function parseWardrobeAnalysis(content: string) {
  const analysis = {
    stil_profili: {
      baskin_tarz: '',
      renk_paleti: '',
      sezonlar: '',
    },
    gardrop_tavsiyeleri: {
      eksik_parcalar: [] as string[],
      stil_onerileri: '',
      alisveris_tavsiyeleri: [] as string[],
    }
  };

  // Extract style profile information
  let currentSection = '';
  let currentSubsection = '';

  const lines = content.split('\n');
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    
    if (line === 'STİL PROFİLİ:') {
      currentSection = 'stil_profili';
      continue;
    } else if (line === 'GARDROP TAVSİYELERİ:') {
      currentSection = 'gardrop_tavsiyeleri';
      continue;
    }
    
    if (currentSection === 'stil_profili') {
      if (line.startsWith('BASKINTARZ:')) {
        analysis.stil_profili.baskin_tarz = cleanupText(line.replace('BASKINTARZ:', '').trim());
      } else if (line.startsWith('RENKPALETİ:')) {
        analysis.stil_profili.renk_paleti = cleanupText(line.replace('RENKPALETİ:', '').trim());
      } else if (line.startsWith('SEZONLAR:')) {
        analysis.stil_profili.sezonlar = cleanupText(line.replace('SEZONLAR:', '').trim());
      }
    } else if (currentSection === 'gardrop_tavsiyeleri') {
      if (line.startsWith('EKSİKPARÇALAR:')) {
        currentSubsection = 'eksik_parcalar';
        const items = line.replace('EKSİKPARÇALAR:', '').trim();
        if (items) {
          processListItems(items, analysis.gardrop_tavsiyeleri.eksik_parcalar);
        }
      } else if (line.startsWith('STİLÖNERİLERİ:')) {
        currentSubsection = 'stil_onerileri';
        analysis.gardrop_tavsiyeleri.stil_onerileri = cleanupText(line.replace('STİLÖNERİLERİ:', '').trim());
      } else if (line.startsWith('ALIŞVERİŞTAVSİYELERİ:')) {
        currentSubsection = 'alisveris_tavsiyeleri';
        const items = line.replace('ALIŞVERİŞTAVSİYELERİ:', '').trim();
        if (items) {
          processListItems(items, analysis.gardrop_tavsiyeleri.alisveris_tavsiyeleri);
        }
      } else if (currentSubsection === 'eksik_parcalar' && line !== '') {
        processListItems(line, analysis.gardrop_tavsiyeleri.eksik_parcalar);
      } else if (currentSubsection === 'stil_onerileri' && line !== '') {
        analysis.gardrop_tavsiyeleri.stil_onerileri += ' ' + line;
      } else if (currentSubsection === 'alisveris_tavsiyeleri' && line !== '') {
        processListItems(line, analysis.gardrop_tavsiyeleri.alisveris_tavsiyeleri);
      }
    }
  }

  // Final cleanup and formatting
  analysis.gardrop_tavsiyeleri.stil_onerileri = cleanupText(analysis.gardrop_tavsiyeleri.stil_onerileri);
  
  // Remove duplicates and clean up list items
  analysis.gardrop_tavsiyeleri.eksik_parcalar = removeDuplicatesAndClean(analysis.gardrop_tavsiyeleri.eksik_parcalar);
  analysis.gardrop_tavsiyeleri.alisveris_tavsiyeleri = removeDuplicatesAndClean(analysis.gardrop_tavsiyeleri.alisveris_tavsiyeleri);

  return analysis;
}

// Helper function to process list items
function processListItems(text: string, targetArray: string[]) {
  // Try multiple approaches to extract list items
  
  // First check if the text has list markers
  const listItemsRegex = /(?:^|\n)(?:\d+\.\s*|\-\s*|\*\s*)([^,;\n]+)(?:,|;|\n|$)/g;
  let match;
  let foundItems = false;
  
  while ((match = listItemsRegex.exec(text)) !== null) {
    if (match[1].trim()) {
      targetArray.push(cleanupText(match[1].trim()));
      foundItems = true;
    }
  }
  
  // If no list markers found, try comma-separated items
  if (!foundItems && text.includes(',')) {
    const items = text.split(',').map(item => item.trim()).filter(item => item);
    for (const item of items) {
      targetArray.push(cleanupText(item));
    }
    foundItems = true;
  }
  
  // If still no items found, try line breaks
  if (!foundItems && text.includes('\n')) {
    const items = text.split('\n').map(item => item.trim()).filter(item => item);
    for (const item of items) {
      targetArray.push(cleanupText(item));
    }
    foundItems = true;
  }
  
  // If all else fails, add as single item if it's not empty
  if (!foundItems && text.trim()) {
    targetArray.push(cleanupText(text.trim()));
  }
}

// Helper function to clean up text
function cleanupText(text: string): string {
  // Remove any leading/trailing punctuation, extra spaces, etc.
  return text
    .replace(/^[.\-:,;]+/, '') // Remove leading punctuation
    .replace(/[.\-:,;]+$/, '') // Remove trailing punctuation
    .replace(/\s+/g, ' ')      // Replace multiple spaces with single space
    .trim();
}

// Helper function to remove duplicates and clean up items
function removeDuplicatesAndClean(items: string[]): string[] {
  // Convert to lowercase for comparison but keep original case for display
  const seen = new Set<string>();
  const result: string[] = [];
  
  for (const item of items) {
    const cleanItem = cleanupText(item);
    const lowerItem = cleanItem.toLowerCase();
    
    // Skip empty items or duplicates
    if (cleanItem && !seen.has(lowerItem)) {
      seen.add(lowerItem);
      result.push(cleanItem);
    }
  }
  
  return result;
} 
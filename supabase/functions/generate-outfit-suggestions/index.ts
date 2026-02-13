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

// GPT-3.5 Turbo pricing (as of March 2024)
const GPT35_TURBO_INPUT_PRICE_PER_1K_TOKENS = 0.0004

const GPT35_TURBO_OUTPUT_PRICE_PER_1K_TOKENS = 0.0016

// Rate limiting constants
const RATE_LIMIT_WINDOW = 3600 // 1 hour in seconds
const FREE_TIER_LIMIT = 3 // 3 requests per hour for free users
const PREMIUM_TIER_LIMIT = 10 // 10 requests per hour for premium users

console.log("Hello from Functions!")

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

    // Log the prompt being sent to ChatGPT
  

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
            content: `Sen bir profesyonel stilistsin. Kullanıcının gardırobundan uyumlu ve tarz kıyafet kombinasyonları oluşturarak kişilerin daha iyi giyinmelerine yardımcı oluyorsun.

1. KOMBİN KURALLARI:
- Duruma göre şu parçaları içermelisin:
  * 1 üst giyim (tişört, gömlek, bluz vb.) - "Üst Giyim" ana grubundan
  * 1 alt giyim (pantolon, etek, şort vb.) - "Alt Giyim" ana grubundan
  * Opsiyonel: 1 dış giyim (ceket, hırka, mont vb.) - "Dış Giyim" ana grubundan (her kombinde olması şart değil)
- EĞER belirli bir ana gruptan kıyafet yoksa, bunu kombin açıklamasında belirt ve diğer mevcut öğelerle kombin oluştur
- Aynı ana gruptan birden fazla kıyafet KULLANMA
- Her kıyafeti SADECE BİR kombinde kullan (ID'ler kombinler arasında tekrarlanmamalı)

2. UYUM KURALLARI:
- Renk uyumu: Tamamlayıcı veya uyumlu renkler seç
- Stil uyumu: Benzer stil kategorisindeki kıyafetleri eşleştir
- Sezon uyumu: Aynı mevsim için tasarlanmış kıyafetleri bir araya getir
- Materyal uyumu: Dokuların birbirine uyumlu olmasına dikkat et

3. ÇIKTI FORMATI (SADECE bu formatı kullan, asla değiştirme):
KOMBİN 1:
ID: [dış giyim ID] 
ID: [üst giyim ID]
ID: [alt giyim ID]
AÇIKLAMA: [Kombinin stil tanımı ve neden bu parçaların seçildiği, max 3 cümle]
KULLANIM: [Bu kombinin giyilebileceği ortamlar/durumlar]
TAMAMLAYICILAR: [Eklenebilecek aksesuar/ayakkabı önerileri]
SEZON: [Bu kombinin uygun olduğu mevsim(ler)]

NOT: Her kombin için TÜM alanları doldur ve TÜM ID'leri doğru şekilde belirt.`
          },
          {
            role: 'user',
            content: `Mevcut Kıyafetlerim:
${clothingDescriptions}

Lütfen bu kıyafetlerimi kullanarak 3 FARKLI KOMBİN oluştur:
1. Günlük Kullanım (Casual)
2. Spor/Aktif Yaşam
3. Şık/Özel Durum (Akşam Yemeği, Davet vb.)

Eğer belirli bir tür için yeterli kıyafetim yoksa, bunu belirt ve mevcut kıyafetlerimle en uygun kombinleri oluşturmaya çalış.`
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

    // Log the response from ChatGPT
 

    // Parse outfit suggestions to create structured output
    const outfits = parseOutfits(content)

    // API kullanım maliyetini hesapla
    const promptTokens = data.usage.prompt_tokens
    const completionTokens = data.usage.completion_tokens
    const cost = (promptTokens * GPT35_TURBO_INPUT_PRICE_PER_1K_TOKENS / 1000) +
      (completionTokens * GPT35_TURBO_OUTPUT_PRICE_PER_1K_TOKENS / 1000)

    return new Response(
      JSON.stringify({
        success: true,
        suggestions: content,
        parsed_outfits: outfits,
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

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/generate-outfit-suggestions' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/

// Helper function to parse outfit suggestions
function parseOutfits(content: string) {
  const outfits: Array<{
    outfit_number: number;
    items: string[];
    details: {
      aciklama?: string;
      kullanim?: string;
      tamamlayicilar?: string;
      sezon?: string;
      [key: string]: string | undefined;
    };
  }> = [];
  
  // Split by "KOMBİN" to get each outfit section
  const outfitSections = content.split(/KOMBİN \d+:/)
  
  // Skip the first empty element
  for (let i = 1; i < outfitSections.length; i++) {
    const section = outfitSections[i].trim()
    const lines = section.split('\n')
    
    const outfit = {
      outfit_number: i,
      items: [] as string[],
      details: {} as {
        aciklama?: string;
        kullanim?: string;
        tamamlayicilar?: string;
        sezon?: string;
        [key: string]: string | undefined;
      }
    }
    
    // Parse the outfit information
    for (let j = 0; j < lines.length; j++) {
      const line = lines[j].trim()
      
      if (line.startsWith('ID:')) {
        // Extract item ID
        const itemId = line.replace('ID:', '').trim()
        outfit.items.push(itemId)
      } else if (line.startsWith('AÇIKLAMA:')) {
        outfit.details.aciklama = line.replace('AÇIKLAMA:', '').trim()
        
        // Continue reading lines if the section continues
        while (j + 1 < lines.length && 
               !lines[j + 1].startsWith('ID:') && 
               !lines[j + 1].startsWith('KULLANIM:') && 
               !lines[j + 1].startsWith('TAMAMLAYICILAR:') && 
               !lines[j + 1].startsWith('SEZON:')) {
          j++
          outfit.details.aciklama += ' ' + lines[j].trim()
        }
      } else if (line.startsWith('KULLANIM:')) {
        outfit.details.kullanim = line.replace('KULLANIM:', '').trim()
        
        // Continue reading lines if the section continues
        while (j + 1 < lines.length && 
               !lines[j + 1].startsWith('ID:') && 
               !lines[j + 1].startsWith('AÇIKLAMA:') && 
               !lines[j + 1].startsWith('TAMAMLAYICILAR:') && 
               !lines[j + 1].startsWith('SEZON:')) {
          j++
          outfit.details.kullanim += ' ' + lines[j].trim()
        }
      } else if (line.startsWith('TAMAMLAYICILAR:')) {
        outfit.details.tamamlayicilar = line.replace('TAMAMLAYICILAR:', '').trim()
        
        // Continue reading lines if the section continues
        while (j + 1 < lines.length && 
               !lines[j + 1].startsWith('ID:') && 
               !lines[j + 1].startsWith('AÇIKLAMA:') && 
               !lines[j + 1].startsWith('KULLANIM:') && 
               !lines[j + 1].startsWith('SEZON:')) {
          j++
          outfit.details.tamamlayicilar += ' ' + lines[j].trim()
        }
      } else if (line.startsWith('SEZON:')) {
        outfit.details.sezon = line.replace('SEZON:', '').trim()
        
        // Continue reading lines if the section continues
        while (j + 1 < lines.length && 
               !lines[j + 1].startsWith('ID:') && 
               !lines[j + 1].startsWith('AÇIKLAMA:') && 
               !lines[j + 1].startsWith('KULLANIM:') && 
               !lines[j + 1].startsWith('TAMAMLAYICILAR:')) {
          j++
          outfit.details.sezon += ' ' + lines[j].trim()
        }
      }
    }
    
    outfits.push(outfit)
  }
  
  return outfits
}

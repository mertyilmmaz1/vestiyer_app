// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"

import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4"
import { Configuration, OpenAIApi } from "npm:openai@3.2.1"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RequestBody {
  base64Image: string
  userId: string
  imageUrl: string
}

console.log("Hello from Functions!")

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { base64Image, userId, imageUrl } = await req.json() as RequestBody

    console.log('Request received:', { userId, imageUrl });

    // Use service role client to bypass RLS
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
        }
      }
    )

    console.log('Supabase client created');

    // Check if the user has reached the free limit (10 items)
    const FREE_LIMIT = 10;
    
    try {
      console.log('Fetching user profile for:', userId);
      // Get user profile to check premium status
      const { data: userProfile, error: profileError } = await supabaseClient
        .from('user_profiles')
        .select('is_premium, free_items_used, subscription_end_date')
        .eq('id', userId)
        .single();
      
      if (profileError) {
        console.error('Profile error:', profileError);
        throw profileError;
      }
      
      console.log('User Profile:', {
        userId,
        is_premium: userProfile.is_premium,
        free_items_used: userProfile.free_items_used,
        subscription_end_date: userProfile.subscription_end_date,
      });

      // Check if subscription has expired
      const hasExpired = userProfile.subscription_end_date && new Date(userProfile.subscription_end_date) < new Date();
      const isPremium = userProfile.is_premium && !hasExpired;
      
      console.log('Premium status:', { isPremium, hasExpired });

      // If user is not premium and has reached the free limit, return error
      if (!isPremium && userProfile.free_items_used >= FREE_LIMIT) {
        return new Response(
          JSON.stringify({
            success: false,
            error: `Free users can only add up to ${FREE_LIMIT} clothing items. Please upgrade to premium.`
          }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
          }
        );
      }
      
      // If user is not premium, increment their free items count
      if (!isPremium) {
        console.log('Incrementing free items for non-premium user');
        try {
          const { error: updateError } = await supabaseClient
            .from('user_profiles')
            .update({ 
              free_items_used: userProfile.free_items_used + 1,
              updated_at: new Date().toISOString()
            })
            .eq('id', userId);
          
          if (updateError) {
            console.error('Update error:', updateError);
            throw updateError;
          }
        } catch (error) {
          console.error('Error incrementing free items:', error);
          throw error;
        }
      }
      
    } catch (error) {
      console.error('Error checking user profile:', error);
      throw error;
    }

    // OpenAI API yapılandırması
    const configuration = new Configuration({
      apiKey: Deno.env.get('OPENAI_API_KEY'),
    })
    const openai = new OpenAIApi(configuration)

    // ChatGPT ile analiz
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${Deno.env.get('OPENAI_API_KEY')}`,
      },
      body: JSON.stringify({
        model: 'gpt-4-turbo',
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: `Bu kıyafetin kombin için önemli özelliklerini detaylı olarak analiz et. Yanıtı şu formatta ver:

Ana Grup: [üst giyim, alt giyim, dış giyim, ayakkabı, aksesuar]
Kategori: [ana grup içindeki detay kategori - örn: gömlek, pantolon, elbise, ceket, ayakkabı]
Renk: [ana renk ve varsa detay renkleri]
Materyal: [kumaş/malzeme türü - örn: pamuk, keten, deri, kot]
Stil: [casual, formal, spor, bohem, klasik, vintage, vb.]
Sezon: [hangi mevsimler için uygun - örn: yaz, kış, tüm yıl]
Detaylar: [desen, dikiş, kesim, fit, tasarım özellikleri ve kombinasyon için önemli diğer detaylar]

Önemli Notlar:
1. Ana Grup seçiminde şu kategorileri kullan:
   - Üst Giyim: gömlek, tişört, kazak, sweatshirt, bluz, t-shirt
   - Alt Giyim: pantolon, etek, şort, tayt
   - Dış Giyim: ceket, mont, kaban, hırka, yelek
   - Ayakkabı: bot, ayakkabı, sandalet, spor ayakkabı
   - Aksesuar: çanta, şapka, atkı, eldiven, kemer

2. Her kıyafeti sadece bir ana gruba yerleştir
3. Ana grup seçiminde kıyafetin temel işlevini dikkate al`
              },
              {
                type: 'image_url',
                image_url: { url: `data:image/jpeg;base64,${base64Image}` }
              }
            ]
          }
        ],
        max_tokens: 500,
      }),
    })

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${response.status} - ${await response.text()}`)
    }

    const data = await response.json()
    const analysis = data.choices[0].message.content

    // Ana grup değerlerini normalize etme fonksiyonu
    function normalizeMainGroup(group: string): string {
      const normalized = group.toLowerCase().trim()
      const validGroups = ['üst giyim', 'alt giyim', 'dış giyim', 'ayakkabı', 'aksesuar']
      return validGroups.find(g => g === normalized) ?? 'üst giyim'
    }

    // Analiz sonuçlarını parse et
    let mainGroup = '', category = '', color = '', material = '', style = '', season = '', details = ''
    const lines = analysis.split('\n')
    for (const line of lines) {
      if (line.startsWith('Ana Grup:')) mainGroup = normalizeMainGroup(line.replace('Ana Grup:', '').trim())
      else if (line.startsWith('Kategori:')) category = line.replace('Kategori:', '').trim()
      else if (line.startsWith('Renk:')) color = line.replace('Renk:', '').trim()
      else if (line.startsWith('Materyal:')) material = line.replace('Materyal:', '').trim()
      else if (line.startsWith('Stil:')) style = line.replace('Stil:', '').trim()
      else if (line.startsWith('Sezon:')) season = line.replace('Sezon:', '').trim()
      else if (line.startsWith('Detaylar:')) details = line.replace('Detaylar:', '').trim()
    }

    // Kıyafeti veritabanına kaydet
    const { data: supabaseData, error } = await supabaseClient
      .from('clothing_items')
      .insert([
        {
          user_id: userId,
          main_group: mainGroup,
          category,
          color,
          material,
          style,
          season,
          description: details,
          image_url: imageUrl,
          created_at: new Date().toISOString(),
        },
      ])
      .select('id::text, main_group, category, color, material, style, season, description, image_url')
      .single()

    if (error) {
      console.error('Database error:', error)
      throw error
    }

    // API kullanım maliyetini hesapla ve kaydet
    const promptTokens = data.usage.prompt_tokens
    const completionTokens = data.usage.completion_tokens
    const visionInputCost = (promptTokens * 0.00765) / 1000 // $0.00765 per 1K tokens
    const visionOutputCost = (completionTokens * 0.03) / 1000 // $0.03 per 1K tokens
    const totalCost = visionInputCost + visionOutputCost

    // API kullanımını kaydet
    await supabaseClient
      .from('api_usage')
      .insert({
        user_id: userId,
        model: 'gpt-4-turbo',
        prompt_tokens: promptTokens,
        completion_tokens: completionTokens,
        cost: totalCost,
        timestamp: new Date().toISOString()
      });

    // Daha kolay okunabilir bir analiz yanıtı hazırla
    const formattedAnalysis = {
      ana_grup: mainGroup,
      kategori: category,
      renk: color,
      materyal: material, 
      stil: style,
      sezon: season,
      detaylar: details
    }

    return new Response(
      JSON.stringify({
        success: true,
        data: supabaseData,
        analysis: analysis,
        formatted_analysis: formattedAnalysis,
        usage: {
          prompt_tokens: promptTokens,
          completion_tokens: completionTokens,
          total_cost: totalCost
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

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/analyze-and-save-clothing' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/

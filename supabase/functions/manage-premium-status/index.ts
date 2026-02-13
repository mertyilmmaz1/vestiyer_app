// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"

import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RequestBody {
  userId: string
  isPremium: boolean
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client
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

    // Verify the JWT token from the request
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('No authorization header')
    }

    const jwt = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(jwt)
    
    if (authError || !user) {
      throw new Error('Unauthorized')
    }

    // Verify if the user has admin role
    const { data: roleData, error: roleError } = await supabaseClient
      .from('user_profiles')
      .select('role')
      .eq('id', user.id)
      .single()

    if (roleError || roleData?.role !== 'admin') {
      throw new Error('Unauthorized: Admin access required')
    }

    // Parse request body
    const { userId, isPremium } = await req.json() as RequestBody

    if (!userId || typeof isPremium !== 'boolean') {
      throw new Error('Invalid request body')
    }

    const now = new Date()
    const endDate = new Date(now)
    endDate.setFullYear(endDate.getFullYear() + 1) // 1 year premium

    // Update user_profiles table
    const { data: userData, error: userError } = await supabaseClient
      .from('user_profiles')
      .update({
        is_premium: isPremium,
        subscription_end_date: isPremium ? endDate.toISOString() : null,
        updated_at: now.toISOString()
      })
      .eq('id', userId)
      .select()
      .single()

    if (userError) throw userError

    // Log the transaction
    await supabaseClient
      .from('subscription_transactions')
      .insert({
        user_id: userId,
        transaction_id: `manual_${now.getTime()}`,
        provider: 'manual',
        subscription_type: isPremium ? 'yearly' : 'cancelled',
        status: 'completed',
        details: {
          transactionDate: now.toISOString(),
          adminModified: true,
          modifiedBy: user.id,
          previousStatus: !isPremium
        }
      })

    return new Response(
      JSON.stringify({
        success: true,
        message: `User premium status updated to: ${isPremium}`,
        user: userData
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )

  } catch (error) {
    console.error('Error in manage-premium-status:', error)
    
    const status = error.message.includes('Unauthorized') ? 401 : 400
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status,
      },
    )
  }
})

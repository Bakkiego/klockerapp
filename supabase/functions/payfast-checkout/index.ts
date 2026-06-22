import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
// We use a lightweight MD5 library for Deno to generate the PayFast signature
import { Md5 } from "https://deno.land/std@0.119.0/hash/md5.ts"

// CORS headers so your Flutter app is allowed to talk to this function
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // 1. Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 2. Parse the request from your Flutter app
    const { tenant_id } = await req.json()

    if (!tenant_id) {
      throw new Error("Missing tenant_id")
    }

    // 3. Setup PayFast Variables
    // In production, you would pull these from Deno.env.get('PAYFAST_MERCHANT_ID')
    const merchantId = '10000100' // Sandbox ID
    const merchantKey = '46f0cd694581a' // Sandbox Key
    const passphrase = Deno.env.get('PAYFAST_PASSPHRASE') || 'YOUR_SECRET_PASSPHRASE'
    const payfastUrl = 'https://sandbox.payfast.co.za/eng/process'
    
    // NOTE: Change to your actual Make.com ITN webhook URL later
    const notifyUrl = 'https://your-make-webhook-url.com' 

    // 4. Build the payload
    const payload = new URLSearchParams()
    payload.append('merchant_id', merchantId)
    payload.append('merchant_key', merchantKey)
    payload.append('return_url', 'https://app.klockerapp.com')
    payload.append('cancel_url', 'https://app.klockerapp.com')
    payload.append('notify_url', notifyUrl)
    payload.append('amount', '49.00')
    payload.append('item_name', 'KlockerApp Standard Tier')
    payload.append('custom_str1', tenant_id) // Hidden Tenant ID!
    payload.append('subscription_type', '1')
    payload.append('billing_date', new Date().toISOString().split('T')[0])
    payload.append('recurring_amount', '49.00')
    payload.append('frequency', '3')
    payload.append('cycles', '0')

    // 5. Generate the MD5 Signature
    // PayFast requires the string to be URI encoded, replacing %20 with +
    let signatureString = ''
    for (const [key, value] of payload.entries()) {
      signatureString += `${key}=${encodeURIComponent(value).replace(/%20/g, '+')}&`
    }
    signatureString += `passphrase=${encodeURIComponent(passphrase).replace(/%20/g, '+')}`

    const md5 = new Md5()
    md5.update(signatureString)
    payload.append('signature', md5.toString())

    // 6. Return the final secure URL back to Flutter
    const checkoutUrl = `${payfastUrl}?${payload.toString()}`

    return new Response(
      JSON.stringify({ url: checkoutUrl }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
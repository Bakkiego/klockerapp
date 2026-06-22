import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

// 🚀 These headers tell the browser "Yes, Flutter is allowed to call me!"
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle the CORS "preflight" check
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Grab the data sent from Flutter
    const { employeeEmail, employeeName } = await req.json()
    
    // 2. Grab your secret Resend Key from Supabase's secure vault
    const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')

    // 3. Send the email via Resend
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: 'KlockerApp <onboarding@klockerapp.com>', // Your verified domain
        to: [employeeEmail],
        subject: 'Welcome to KlockerApp – Your Account is Approved!',
        html: `
          <div style="font-family: sans-serif; text-align: center; padding: 40px;">
            <h1 style="color: #4BAE4F;">Welcome to Klocker, ${employeeName}!</h1>
            <p>Your HR Manager has officially approved your account.</p>
            <p>Download the app and log in to view your roster.</p>
          </div>
        ` // Note: Paste your full beautiful HTML template in here!
      }),
    })

    const data = await res.json()

    // 4. Send the success response back to Flutter
    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: res.ok ? 200 : 400,
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
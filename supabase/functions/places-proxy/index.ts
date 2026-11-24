import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    const key = Deno.env.get("GOOGLE_PLACES_API_KEY")
    if (!key) {
      throw new Error(
        "GOOGLE_PLACES_API_KEY is not set on the places-proxy function",
      )
    }

    const body = await req.json()
    const action = (body.action ?? "autocomplete") as string

    if (action === "autocomplete") {
      const input = String(body.input ?? "").trim()
      if (input.length < 2) {
        return json({ status: "OK", predictions: [] })
      }

      const params = new URLSearchParams({
        input,
        key,
        types: "address",
        language: "en",
      })

      if (body.lat != null && body.lng != null) {
        params.set("location", `${body.lat},${body.lng}`)
        params.set("radius", String(body.radius ?? 50000))
      }
      if (body.country && String(body.country).length === 2) {
        params.set("components", `country:${String(body.country).toLowerCase()}`)
      }

      const googleRes = await fetch(
        `https://maps.googleapis.com/maps/api/place/autocomplete/json?${params}`,
      )
      const data = await googleRes.json()
      return json(data)
    }

    if (action === "details") {
      const placeId = String(body.place_id ?? "").trim()
      if (!placeId) throw new Error("place_id is required")

      const params = new URLSearchParams({
        place_id: placeId,
        fields: "geometry,formatted_address,name,address_component",
        key,
      })

      const googleRes = await fetch(
        `https://maps.googleapis.com/maps/api/place/details/json?${params}`,
      )
      const data = await googleRes.json()
      return json(data)
    }

    if (action === "reverse_country") {
      const lat = body.lat
      const lng = body.lng
      if (lat == null || lng == null) throw new Error("lat/lng required")

      const params = new URLSearchParams({
        latlng: `${lat},${lng}`,
        result_type: "country",
        key,
      })

      const googleRes = await fetch(
        `https://maps.googleapis.com/maps/api/geocode/json?${params}`,
      )
      const data = await googleRes.json()
      return json(data)
    }

    throw new Error(`Unknown action: ${action}`)
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    return new Response(JSON.stringify({ error: message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    })
  }
})

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
    status,
  })
}

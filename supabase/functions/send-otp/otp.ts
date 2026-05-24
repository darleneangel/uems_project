/**
 * UEMSSP OTP Service & Edge Function Handler
 * Generates, verifies, and routes secure Gmail SMTP transactional emails.
 * Supports cross-origin requests from Flutter Web and Windows Desktop environments.
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { SmtpClient } from "https://deno.land/x/smtp@v0.7.0/mod.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Initialize Supabase Client with system secrets and secure fallback credentials
const supabaseUrl = Deno.env.get("SUPABASE_URL") || "https://ipmkemontxkxzfymidej.supabase.co";
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "sb_secret_n-yVEO9QNDbynR9hyA-V8w_pB5u-8L5";
const supabase = createClient(supabaseUrl, supabaseKey);

Deno.serve(async (req: Request) => {
  // 1. Handle CORS Pre-flight Options requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    
    // Fallback alignment: safely handle both 'toEmail' (Flutter Client) and 'email' parameters
    const email = body.toEmail || body.email;
    const otp = body.otp;
    const name = body.name || "Academic Member";

    if (!email || !otp) {
      return new Response(JSON.stringify({ error: "Missing email or OTP verification code." }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Write/Upsert OTP status inside Supabase for verification reference
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes expiry window
    const { error: dbError } = await supabase
      .from("otp_verification")
      .upsert({ 
        email: email.toLowerCase().trim(), 
        otp: otp, 
        expires_at: expiresAt.toISOString() 
      }, { onConflict: "email" });

    if (dbError) {
      console.error("Database Save Error:", dbError);
      throw new Error("Failed to secure validation metrics inside cloud ledger.");
    }

    // 3. Dispatch Email via Gmail SMTP TLS Core (Port 465)
    const client = new SmtpClient();
    const gmailUser = Deno.env.get("GMAIL_USER") || "lustredarlene45@gmail.com";
    const gmailPass = Deno.env.get("GMAIL_APP_PASSWORD") || "xzgkbybbhiqhhrxh";

    if (!gmailUser || !gmailPass) {
      throw new Error("SMTP Configuration Error: Missing GMAIL_USER or GMAIL_APP_PASSWORD secrets.");
    }

    await client.connectTLS({
      hostname: "smtp.gmail.com",
      port: 465,
      username: gmailUser,
      password: gmailPass,
    });

    await client.send({
      from: `UEMSSP Security Core <${gmailUser}>`,
      to: email,
      subject: "UEMSSP Adaptive Security Verification Code",
      content: `Hello, your security verification code is: ${otp}. This code expires in 10 minutes.`,
      html: `
        <div style="font-family: 'Segoe UI', Helvetica, Arial, sans-serif; max-width: 500px; margin: 40px auto; padding: 32px; border: 1px solid #E2E8F0; border-radius: 24px; color: #1E1033; background: #FFFFFF; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.05);">
          <div style="text-align: center; margin-bottom: 24px;">
            <h2 style="color: #8B5CF6; margin: 0; font-size: 22px; font-weight: 900; letter-spacing: -0.5px;">UEMSSP SECURITY</h2>
            <p style="color: #64748B; font-size: 11px; margin: 4px 0 0 0; font-weight: bold; letter-spacing: 1.5px; text-transform: uppercase;">Bright Future Academy</p>
          </div>
          <div style="height: 1px; background: #E2E8F0; margin-bottom: 28px;"></div>
          <p style="font-size: 14px; line-height: 1.6; color: #334155; margin-bottom: 20px;">
            Hello <strong>${name}</strong>,
          </p>
          <p style="font-size: 14px; line-height: 1.6; color: #334155; margin-bottom: 24px;">
            We detected a password recovery sequence or an authentication challenge on your academic workstation. Input the secure verification code below to authorize this session:
          </p>
          <div style="background: #F8FAFC; border: 1px dashed #CBD5E1; border-radius: 16px; padding: 24px; text-align: center; margin-bottom: 24px;">
            <span style="font-family: monospace; font-size: 32px; font-weight: bold; color: #8B5CF6; letter-spacing: 6px; display: inline-block;">${otp}</span>
          </div>
          <p style="font-size: 12px; line-height: 1.6; color: #64748B; margin-bottom: 28px; font-style: italic;">
            Note: This code will expire in exactly 10 minutes. If you did not initiate this change, ignore this email and secure your workstation immediately.
          </p>
          <div style="height: 1px; background: #E2E8F0; margin-bottom: 20px;"></div>
          <div style="text-align: center; font-size: 11px; color: #94A3B8;">
            UEMSSP Multi-Tier Adaptive Defense Core • SysAdmin System Dispatch
          </div>
        </div>
      `,
    });

    await client.close();

    return new Response(JSON.stringify({ success: true, message: "Security payload dispatched successfully." }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("Deno Edge Function Failure:", message);
    
    return new Response(JSON.stringify({ error: message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
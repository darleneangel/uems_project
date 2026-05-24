import * as nodemailer from "https://esm.sh/nodemailer@6.9.10";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  // 1. Handle CORS Pre-flight Options requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    
    const email = body.toEmail || body.email;
    const otp = body.otp;
    const name = body.name || "Academic Member";
    const documents: string[] = body.documents || [];

    if (!email || !otp) {
      return new Response(JSON.stringify({ error: "Missing email or identification payload." }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Programmatically trim whitespace, newlines (\n), and carriage returns (\r)
    const gmailUser = (Deno.env.get("GMAIL_USER") || "lustredarlene45@gmail.com").trim();
    const gmailPass = (Deno.env.get("GMAIL_APP_PASSWORD") || "dgylahnljhvsoplr").trim();

    if (!gmailUser || !gmailPass) {
      throw new Error("SMTP Configuration Error: Missing GMAIL_USER or GMAIL_APP_PASSWORD secrets.");
    }

    // 2. Configure Nodemailer with modern pool stream configurations
    const transporter = nodemailer.createTransport({
      host: "smtp.gmail.com",
      port: 465,
      secure: true, // Use SSL/TLS
      auth: {
        user: gmailUser,
        pass: gmailPass,
      },
    });

    // 3. Adaptive Template Generator: Check if payload is a Document Claim Ticket
    const isDocumentTicket = otp.startsWith("BATCH-") || documents.length > 0;
    
    let subject = "UEMSSP Adaptive Security Verification Code";
    let text = `Hello, your security verification code is: ${otp}. This code expires in 10 minutes.`;
    let htmlContent = "";

    if (isDocumentTicket) {
      const docListHtml = documents.map((doc) => `
        <li style="padding: 10px 0; border-bottom: 1px solid #F1F5F9; color: #1E293B; font-weight: 600; font-size: 13px;">
          • ${doc}
        </li>
      `).join("");

      const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${otp}&margin=10&ecc=H`;

      subject = `Official BFA Document Claim Ticket: ${documents.length} Item(s)`;
      text = `Hello ${name}, your document claim ticket is confirmed. Reference: ${otp}`;
      htmlContent = `
        <div style="font-family: 'Segoe UI', Helvetica, Arial, sans-serif; max-width: 500px; margin: 40px auto; padding: 32px; border: 1px solid #E2E8F0; border-radius: 24px; color: #1E1033; background: #FFFFFF; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.05);">
          <div style="text-align: center; margin-bottom: 24px;">
            <h2 style="color: #8B5CF6; margin: 0; font-size: 22px; font-weight: 900; letter-spacing: -0.5px;">OFFICIAL CLAIM TICKET</h2>
            <p style="color: #64748B; font-size: 11px; margin: 4px 0 0 0; font-weight: bold; letter-spacing: 1.5px; text-transform: uppercase;">Bright Future Academy</p>
          </div>
          <div style="height: 1px; background: #E2E8F0; margin-bottom: 28px;"></div>
          <p style="font-size: 14px; line-height: 1.6; color: #334155; margin-bottom: 20px;">
            Hello <strong>${name}</strong>,
          </p>
          <p style="font-size: 14px; line-height: 1.6; color: #334155; margin-bottom: 24px;">
            Your academic document request has been processed successfully. Present the secure QR code below at the Registrar window to claim your documents:
          </p>
          
          <div style="background: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 16px; padding: 20px; margin-bottom: 24px;">
            <p style="font-size: 11px; color: #64748B; font-weight: bold; margin: 0 0 10px 0; text-transform: uppercase; letter-spacing: 1px;">Requested Document(s):</p>
            <ul style="margin: 0; padding: 0 0 0 5px; list-style-type: none;">
              ${docListHtml}
            </ul>
          </div>

          <div style="background: #F8FAFC; border: 1px dashed #CBD5E1; border-radius: 16px; padding: 24px; text-align: center; margin-bottom: 24px;">
            <img src="${qrUrl}" width="200" height="200" style="border: 4px solid #FFFFFF; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.05);" />
            <p style="font-family: monospace; font-size: 11px; font-weight: bold; color: #8B5CF6; margin: 12px 0 0 0; letter-spacing: 1px;">REF: ${otp}</p>
          </div>
          
          <p style="font-size: 12px; line-height: 1.6; color: #64748B; margin-bottom: 28px; font-style: italic; text-align: center;">
            Note: Please bring a valid Student/Employee Identification Card along with this ticket to complete verification.
          </p>
          <div style="height: 1px; background: #E2E8F0; margin-bottom: 20px;"></div>
          <div style="text-align: center; font-size: 11px; color: #94A3B8;">
            UEMSSP Core Systems • Registrar Office Dispatch
          </div>
        </div>
      `;
    } else {
      // Standard layout for normal OTP security challenges
      htmlContent = `
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
      `;
    }

    // 4. Dispatch email payload via transporter
    await transporter.sendMail({
      from: `UEMSSP Core Systems <${gmailUser}>`,
      to: email,
      subject: subject,
      text: text,
      html: htmlContent,
    });

    return new Response(JSON.stringify({ success: true, message: "Transactional email payload dispatched successfully." }), {
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
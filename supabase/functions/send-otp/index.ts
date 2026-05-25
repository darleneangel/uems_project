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
    const type = body.type || ""; // "otp", "document", "enrollment", "assessment_billing"
    const tempPassword = body.tempPassword || "";
    const studentId = body.studentId || "";
    
    // Financial Breakdown Data Structure payloads
    const tuitionFee = body.tuitionFee || "₱0.00";
    const labFee = body.labFee || "₱0.00";
    const totalNetFees = body.totalNetFees || "₱0.00";
    const totalUnits = body.totalUnits || "0.0";
    const blockSection = body.blockSection || "N/A";

    if (!email) {
      return new Response(JSON.stringify({ error: "Missing recipient email address." }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const gmailUser = (Deno.env.get("GMAIL_USER") || "lustredarlene45@gmail.com").trim();
    const gmailPass = (Deno.env.get("GMAIL_APP_PASSWORD") || "dgylahnljhvsoplr").trim();

    if (!gmailUser || !gmailPass) {
      throw new Error("SMTP Configuration Error: Missing GMAIL_USER or GMAIL_APP_PASSWORD secrets.");
    }

    // 2. Configure Nodemailer with modern pool configurations
    const transporter = nodemailer.createTransport({
      host: "smtp.gmail.com",
      port: 465,
      secure: true,
      auth: {
        user: gmailUser,
        pass: gmailPass,
      },
    });

    // 3. Adaptive Template Generator: Determine the target transaction type
    let subject = "UEMSSP Adaptive Security Verification Code";
    let text = `Hello, your security verification code is: ${otp}.`;
    let htmlContent = "";

if (type === "assessment_billing") {
  subject = "Official Course Assessment & Schedule Invoice - Bright Future Academy";
  text = `Hello ${name}, your course loading and tuition assessment has been approved for this term. Total Amount Due: ${totalNetFees}.`;

  // --- Structured fee payloads from Flutter ---
  const miscBreakdown: Record<string, string>  = body.miscBreakdown  || {};
  const otherBreakdown: Record<string, string> = body.otherBreakdown || {};
  const tuitionRate    = body.tuitionRate    || "0.00";
  const cashDiscount   = body.cashDiscount   || "0.00";
  const downpayment    = body.downpayment    || "0.00";
  const perInstallment = body.perInstallment || "0.00";
  const grandTotal     = body.grandTotal     || totalNetFees;

  // --- Row builders ---
  const buildFeeRows = (map: Record<string, string>) =>
    Object.entries(map)
      .filter(([, v]) => parseFloat(v) > 0)
      .map(([label, val]) => `
        <tr>
          <td style="padding:5px 10px;color:#475569;font-size:11px;border-bottom:1px solid #F1F5F9;">${label}</td>
          <td style="padding:5px 10px;text-align:right;font-family:'Courier New',monospace;font-size:11px;color:#1E293B;border-bottom:1px solid #F1F5F9;">₱${parseFloat(val).toLocaleString("en-PH",{minimumFractionDigits:2})}</td>
        </tr>`).join("");

  const subjectRows = documents.map((subLine: string) => `
    <tr>
      <td colspan="2" style="padding:8px 12px;border-bottom:1px solid #E2E8F0;color:#334155;font-size:12px;font-weight:500;">${subLine}</td>
    </tr>`).join("");

  htmlContent = `
    <div style="font-family:'Segoe UI',Arial,sans-serif;max-width:700px;margin:32px auto;background:#FFFFFF;border:1px solid #CBD5E1;border-radius:4px;overflow:hidden;">

      <!-- ── Header ── -->
      <div style="background:#1C3557;padding:18px 28px;text-align:center;">
        <div style="color:#FFFFFF;font-size:16px;font-weight:700;letter-spacing:0.5px;">BRIGHT FUTURE ACADEMY</div>
        <div style="color:#93C5FD;font-size:10px;font-weight:700;letter-spacing:2px;text-transform:uppercase;margin-top:4px;">Official Study Load &amp; Fee Assessment Invoice</div>
      </div>

      <div style="padding:24px 28px;">

        <!-- ── Greeting ── -->
        <p style="font-size:13px;color:#334155;margin:0 0 6px 0;">Hello <strong>${name}</strong>,</p>
        <p style="font-size:13px;color:#64748B;margin:0 0 20px 0;line-height:1.6;">
          Your academic curriculum courses have been successfully reviewed and loaded by your Program Chair.
          Below is your complete official schedule and itemized breakdown of fees for this term.
        </p>

        <!-- ── Subject Schedule ── -->
        <div style="font-size:10px;font-weight:700;color:#1C3557;letter-spacing:1.5px;text-transform:uppercase;border-bottom:2px solid #1C3557;padding-bottom:4px;margin-bottom:12px;">
          List of Subjects Taken &nbsp;(${totalUnits} Total Units)
        </div>
        <table style="width:100%;border-collapse:collapse;font-size:11.5px;margin-bottom:24px;">
          <thead>
            <tr style="background:#1C3557;">
              <th colspan="2" style="padding:7px 12px;color:#FFFFFF;font-weight:700;font-size:10px;letter-spacing:0.5px;text-transform:uppercase;text-align:left;">Code &nbsp;/&nbsp; Description &nbsp;/&nbsp; Schedule</th>
            </tr>
          </thead>
          <tbody>${subjectRows}</tbody>
        </table>

        <!-- ── Fee Breakdown Grid ── -->
        <div style="font-size:10px;font-weight:700;color:#1C3557;letter-spacing:1.5px;text-transform:uppercase;border-bottom:2px solid #1C3557;padding-bottom:4px;margin-bottom:16px;">
          Itemized Fee Breakdown
        </div>

        <table style="width:100%;border-collapse:collapse;margin-bottom:24px;">
          <tbody>

            <!-- Tuition -->
            <tr style="background:#1C3557;">
              <td colspan="2" style="padding:7px 12px;color:#93C5FD;font-size:10px;font-weight:700;letter-spacing:1px;text-transform:uppercase;">Tuition</td>
            </tr>
            <tr>
              <td style="padding:8px 10px;color:#475569;font-size:12px;border-bottom:1px solid #E2E8F0;">
                Gross Tuition Base &nbsp;<span style="color:#94A3B8;font-size:10px;">(${totalUnits} Units @ ₱${tuitionRate}/Unit)</span>
              </td>
              <td style="padding:8px 10px;text-align:right;font-family:'Courier New',monospace;font-size:12px;font-weight:700;color:#1E293B;border-bottom:1px solid #E2E8F0;">${tuitionFee}</td>
            </tr>

            <!-- Laboratory -->
            <tr style="background:#1C3557;">
              <td colspan="2" style="padding:7px 12px;color:#93C5FD;font-size:10px;font-weight:700;letter-spacing:1px;text-transform:uppercase;">Laboratory</td>
            </tr>
            <tr>
              <td style="padding:8px 10px;color:#475569;font-size:12px;border-bottom:1px solid #E2E8F0;">Laboratory Matrix Fee</td>
              <td style="padding:8px 10px;text-align:right;font-family:'Courier New',monospace;font-size:12px;font-weight:700;color:#1E293B;border-bottom:1px solid #E2E8F0;">${labFee}</td>
            </tr>

            <!-- Miscellaneous -->
            <tr style="background:#1C3557;">
              <td colspan="2" style="padding:7px 12px;color:#93C5FD;font-size:10px;font-weight:700;letter-spacing:1px;text-transform:uppercase;">Miscellaneous Fees</td>
            </tr>
            ${buildFeeRows(miscBreakdown)}
            <tr style="background:#F1F5F9;">
              <td style="padding:7px 10px;font-size:12px;font-weight:700;color:#334155;">Miscellaneous Total</td>
              <td style="padding:7px 10px;text-align:right;font-family:'Courier New',monospace;font-size:12px;font-weight:700;color:#1E293B;">
                ₱${Object.values(miscBreakdown).reduce((s,v)=>s+parseFloat(v||"0"),0).toLocaleString("en-PH",{minimumFractionDigits:2})}
              </td>
            </tr>

            <!-- Other Fees -->
            <tr style="background:#1C3557;">
              <td colspan="2" style="padding:7px 12px;color:#93C5FD;font-size:10px;font-weight:700;letter-spacing:1px;text-transform:uppercase;">Other Fees</td>
            </tr>
            ${buildFeeRows(otherBreakdown)}
            <tr style="background:#F1F5F9;">
              <td style="padding:7px 10px;font-size:12px;font-weight:700;color:#334155;">Other Fees Total</td>
              <td style="padding:7px 10px;text-align:right;font-family:'Courier New',monospace;font-size:12px;font-weight:700;color:#1E293B;">
                ₱${Object.values(otherBreakdown).reduce((s,v)=>s+parseFloat(v||"0"),0).toLocaleString("en-PH",{minimumFractionDigits:2})}
              </td>
            </tr>

          </tbody>
        </table>

        <!-- ── Grand Total + Payment Options ── -->
        <div style="background:#1C3557;border-radius:4px;padding:20px 24px;margin-bottom:20px;">
          <table style="width:100%;border-collapse:collapse;font-size:13px;">
            <tr>
              <td style="padding:5px 0;color:#CBD5E1;">Gross Total Fees:</td>
              <td style="padding:5px 0;text-align:right;font-family:'Courier New',monospace;color:#FFFFFF;font-weight:700;">${grandTotal}</td>
            </tr>

            <!-- Cash Option -->
            <tr><td colspan="2" style="padding-top:12px;border-top:1px solid #2E4A6B;"></td></tr>
            <tr>
              <td style="padding:4px 0;color:#93C5FD;font-size:10px;font-weight:700;letter-spacing:1px;text-transform:uppercase;" colspan="2">Cash Option</td>
            </tr>
            <tr>
              <td style="padding:4px 0;color:#CBD5E1;">Prompt Payment Discount:</td>
              <td style="padding:4px 0;text-align:right;font-family:'Courier New',monospace;color:#FCA5A5;font-weight:700;">- ₱${parseFloat(cashDiscount).toLocaleString("en-PH",{minimumFractionDigits:2})}</td>
            </tr>
            <tr>
              <td style="padding:4px 0;color:#FFFFFF;font-weight:700;font-size:14px;">NET CASH AMOUNT DUE:</td>
              <td style="padding:4px 0;text-align:right;font-family:'Courier New',monospace;color:#6EE7B7;font-weight:700;font-size:14px;">${totalNetFees}</td>
            </tr>

            <!-- Installment Option -->
            <tr><td colspan="2" style="padding-top:12px;border-top:1px solid #2E4A6B;"></td></tr>
            <tr>
              <td style="padding:4px 0;color:#FCD34D;font-size:10px;font-weight:700;letter-spacing:1px;text-transform:uppercase;" colspan="2">Installment Option</td>
            </tr>
            <tr>
              <td style="padding:4px 0;color:#CBD5E1;">Upon Registration (Downpayment):</td>
              <td style="padding:4px 0;text-align:right;font-family:'Courier New',monospace;color:#FFFFFF;font-weight:700;">₱${parseFloat(downpayment).toLocaleString("en-PH",{minimumFractionDigits:2})}</td>
            </tr>
            <tr>
              <td style="padding:4px 0;color:#CBD5E1;">Periodic (4 installments):</td>
              <td style="padding:4px 0;text-align:right;font-family:'Courier New',monospace;color:#FCD34D;font-weight:700;">₱${parseFloat(perInstallment).toLocaleString("en-PH",{minimumFractionDigits:2})} / term</td>
            </tr>
          </table>
        </div>

        <!-- ── Note ── -->
        <p style="font-size:11px;color:#64748B;font-style:italic;text-align:center;margin:0 0 20px 0;line-height:1.6;">
          Your account is under status <strong>'Assessment'</strong>. Please proceed to the Accounting Portal or Comptroller's Window to settle your balance.
        </p>

      </div>

      <!-- ── Footer ── -->
      <div style="background:#1C3557;padding:12px 28px;text-align:center;font-size:10px;color:#93C5FD;letter-spacing:1px;">
        UEMSSP Core Systems &bull; Program Chair Curriculum Handover Dispatch
      </div>

    </div>
  `;
}
    // Template B: Registrar Enrollment Credentials Dispatch
    else if (type === "enrollment" || tempPassword !== "") {
      subject = "Official Enrollment Confirmation - Bright Future Academy";
      text = `Hello ${name}, welcome to Bright Future Academy. Your Student ID is ${studentId} and your temporary password is ${tempPassword}`;
      htmlContent = `
        <div style="font-family: 'Segoe UI', Helvetica, Arial, sans-serif; max-width: 500px; margin: 40px auto; padding: 32px; border: 1px solid #E2E8F0; border-radius: 24px; color: #1E1033; background: #FFFFFF; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.05);">
          <div style="text-align: center; margin-bottom: 24px;">
            <h2 style="color: #8B5CF6; margin: 0; font-size: 22px; font-weight: 900; letter-spacing: -0.5px;">WELCOME TO THE ACADEMY</h2>
            <p style="color: #64748B; font-size: 11px; margin: 4px 0 0 0; font-weight: bold; letter-spacing: 1.5px; text-transform: uppercase;">Bright Future Academy</p>
          </div>
          <div style="height: 1px; background: #E2E8F0; margin-bottom: 28px;"></div>
          <p style="font-size: 14px; line-height: 1.6; color: #334155; margin-bottom: 20px;">
            Hello <strong>${name}</strong>,
          </p>
          <p style="font-size: 14px; line-height: 1.6; color: #334155; margin-bottom: 24px;">
            Your institutional portal access has been provisioned. Please use the following credentials to access your student dashboard:
          </p>
          
          <div style="background: #F8FAFC; border: 1px dashed #CBD5E1; border-radius: 16px; padding: 24px; text-align: center; margin-bottom: 24px;">
            <p style="font-size: 11px; color: #64748B; font-weight: bold; margin: 0 0 4px 0; text-transform: uppercase; letter-spacing: 1px;">Student ID Number</p>
            <span style="font-family: monospace; font-size: 26px; font-weight: bold; color: #8B5CF6; display: inline-block; margin-bottom: 16px;">${studentId}</span>
            
            <p style="font-size: 11px; color: #64748B; font-weight: bold; margin: 0 0 4px 0; text-transform: uppercase; letter-spacing: 1px;">Temporary Password</p>
            <span style="font-family: monospace; font-size: 18px; font-weight: bold; color: #1E293B; display: inline-block;">${tempPassword}</span>
          </div>
          
          <p style="font-size: 12px; line-height: 1.6; color: #64748B; margin-bottom: 28px; font-style: italic; text-align: center;">
            Note: For security reasons, you will be required to update your temporary login password immediately upon your first workstation login.
          </p>
          <div style="height: 1px; background: #E2E8F0; margin-bottom: 20px;"></div>
          <div style="text-align: center; font-size: 11px; color: #94A3B8;">
            UEMSSP Core Systems • Registrar Enrollment Dispatch
          </div>
        </div>
      `;
    } 
    // Template C: Document Claim Ticket
    else if (otp?.startsWith("BATCH-") || documents.length > 0) {
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
    } 
    // Template D: Standard Security OTP Code
    else {
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
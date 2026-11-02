const LINE_API = "https://api.line.me/v2/bot/message/reply";

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" }
  });
}

function timingSafeEqual(a, b) {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

async function verifyLineSignature(rawBody, signature, channelSecret) {
  if (!signature || !channelSecret) return false;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(channelSecret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const mac = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(rawBody));
  const digest = btoa(String.fromCharCode(...new Uint8Array(mac)));
  return timingSafeEqual(digest, signature);
}

function responseText(event) {
  const text = String(event.message?.text || "").trim().toLowerCase();
  if (!text) return null;

  if (/^(สวัสดี|hello|hi|เริ่ม|เมนู)$/.test(text)) {
    return "ยินดีต้อนรับสู่ บริษัท สายใจ 99 จำกัด 🐔🐷\nเลือกหมวดสินค้า: ไก่สด หรือ หมูสด\nหากต้องการสั่งซื้อ กรุณาแจ้งรายการสินค้า จำนวน และจังหวัด/อำเภอ/ตำบล เพื่อให้เจ้าหน้าที่ตรวจสอบพื้นที่จัดส่งและยืนยันราคาอีกครั้ง";
  }

  if (text.includes("ไก่")) {
    return "รับทราบครับ สนใจสินค้าไก่สดรายการใด และจำนวนเท่าไรครับ? กรุณาระบุพื้นที่จัดส่ง (จังหวัด/อำเภอ/ตำบล) ด้วย เพื่อให้เจ้าหน้าที่ตรวจสอบราคาและรอบจัดส่งจากข้อมูลจริงก่อนยืนยันออร์เดอร์";
  }

  if (text.includes("หมู")) {
    return "รับทราบครับ สนใจสินค้าเนื้อหมูสดรายการใด และจำนวนเท่าไรครับ? กรุณาระบุพื้นที่จัดส่ง (จังหวัด/อำเภอ/ตำบล) ด้วย เพื่อให้เจ้าหน้าที่ตรวจสอบราคาและรอบจัดส่งจากข้อมูลจริงก่อนยืนยันออร์เดอร์";
  }

  if (/ราคา|โปรโมชั่น|โปรโมชัน|ส่ง|จัดส่ง/.test(text)) {
    return "ขอบคุณที่สอบถามครับ กรุณาส่งชื่อสินค้า จำนวน และพื้นที่จัดส่ง (จังหวัด/อำเภอ/ตำบล) เจ้าหน้าที่จะตรวจสอบราคา โปรโมชั่น และค่าจัดส่งล่าสุดให้ก่อนยืนยันครับ";
  }

  return "ขอบคุณที่ติดต่อ บริษัท สายใจ 99 จำกัด ครับ 😊\nต้องการสอบถามหรือสั่งซื้อ ไก่สด / หมูสด แจ้งรายการ จำนวน และพื้นที่จัดส่งได้เลยครับ\nหมายเหตุ: ราคา สต็อก ค่าจัดส่ง และรอบส่งจะยืนยันโดยเจ้าหน้าที่ก่อนรับออร์เดอร์";
}

async function replyMessage(token, replyToken, text) {
  const response = await fetch(LINE_API, {
    method: "POST",
    headers: {
      authorization: `Bearer ${token}`,
      "content-type": "application/json"
    },
    body: JSON.stringify({
      replyToken,
      messages: [{ type: "text", text }]
    })
  });
  if (!response.ok) {
    const detail = await response.text();
    console.error("LINE reply failed", response.status, detail.slice(0, 300));
  }
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    if (request.method === "GET" && url.pathname === "/health") {
      return json({
        service: "saijai99-line-webhook",
        status: "ok",
        credentialsConfigured: Boolean(env.LINE_CHANNEL_ACCESS_TOKEN && env.LINE_CHANNEL_SECRET)
      });
    }

    if (request.method === "GET" && url.pathname === "/") {
      return new Response("Saijai 99 LINE webhook. GET /health; POST /webhook.", {
        headers: { "content-type": "text/plain; charset=utf-8" }
      });
    }

    if (request.method !== "POST" || url.pathname !== "/webhook") {
      return json({ error: "Not found" }, 404);
    }

    if (!env.LINE_CHANNEL_ACCESS_TOKEN || !env.LINE_CHANNEL_SECRET) {
      return json({ error: "LINE credentials are not configured" }, 503);
    }

    const rawBody = await request.text();
    const signature = request.headers.get("x-line-signature");
    const valid = await verifyLineSignature(rawBody, signature, env.LINE_CHANNEL_SECRET);
    if (!valid) return json({ error: "Invalid signature" }, 401);

    let payload;
    try {
      payload = JSON.parse(rawBody);
    } catch {
      return json({ error: "Invalid JSON" }, 400);
    }

    const tasks = (payload.events || []).map(async (event) => {
      if (event.type !== "message" || event.message?.type !== "text" || !event.replyToken) return;
      const message = responseText(event);
      if (message) await replyMessage(env.LINE_CHANNEL_ACCESS_TOKEN, event.replyToken, message);
    });

    ctx.waitUntil(Promise.all(tasks));
    return json({ accepted: true });
  }
};

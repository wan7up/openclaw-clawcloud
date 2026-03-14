import "dotenv/config";
import Fastify from "fastify";
import { getUserProfile } from "./profiles.js";

const app = Fastify({ logger: true });
const port = Number(process.env.PORT || 8787);

app.get("/health", async () => ({ ok: true }));

app.post("/feishu/webhook", async (request, reply) => {
  const body = request.body ?? {};

  // URL verification challenge
  if (body.type === "url_verification") {
    return { challenge: body.challenge };
  }

  const event = body.event ?? {};
  const senderId =
    event?.sender?.sender_id?.open_id ||
    event?.sender?.sender_id?.user_id ||
    event?.sender?.sender_id?.union_id ||
    null;

  const text = event?.message?.content;
  const profile = senderId ? getUserProfile(senderId) : null;

  app.log.info({ senderId, text, profile }, "incoming feishu message");

  if (!senderId) {
    return { ok: false, reason: "missing_sender_id" };
  }

  if (!profile) {
    return { ok: true, message: "user_not_allowed" };
  }

  return {
    ok: true,
    message: `收到来自 ${profile.alias} 的消息。你的独立会话 key 是 ${profile.sessionKey}`,
    next: "Later this webhook will call Feishu send-message API and optionally route to OpenClaw."
  };
});

app.listen({ port, host: "0.0.0.0" }).then(() => {
  app.log.info(`feishu bot listening on :${port}`);
});

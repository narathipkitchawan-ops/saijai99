# Saijai 99 LINE webhook

Cloudflare Worker for LINE Messaging API.

- Worker: `saijai99-line-webhook`
- Webhook: `/webhook`
- Health: `/health`

## Required Worker secrets
Set `LINE_CHANNEL_ACCESS_TOKEN` and `LINE_CHANNEL_SECRET` in Cloudflare Workers & Pages > `saijai99-line-webhook` > Settings > Variables and Secrets. Never commit these values. Rotate any token previously pasted into chat.

## LINE Console
After setting both secrets, configure the webhook URL as `https://<worker-host>/webhook`, click Verify, enable Use webhook, and test by messaging the Official Account.

## Safeguards
The Worker validates `x-line-signature` with HMAC-SHA256. Its starter replies collect product, quantity, and delivery-area details, but do not invent prices, inventory, shipping fees, or schedules. It does not persist orders or customer data yet.

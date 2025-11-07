/* functions/index.js */

const functions = require("firebase-functions");
const Busboy = require("busboy");

// node-fetch ESM bridge for Node18 in Cloud Functions
const fetch = (...args) =>
  import("node-fetch").then(({ default: fetch }) => fetch(...args));

/**
 * Config
 * Set which provider you want to use:
 *   USE_PROVIDER = "hf"       -> Hugging Face Inference API (simpler)
 *   USE_PROVIDER = "replicate"-> Replicate (needs polling)
 *
 * You will set secrets (tokens) in Step 4.
 */
const USE_PROVIDER = process.env.USE_PROVIDER || "hf";

exports.plantDetect = functions
  .runWith({ memory: "512MB", timeoutSeconds: 60 })
  .https.onRequest(async (req, res) => {
    // CORS
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

    if (req.method === "OPTIONS") return res.status(204).send("");

    if (req.method !== "POST") {
      return res.status(405).json({ error: "Method not allowed" });
    }

    try {
      const { fileBuffer, mimeType } = await readMultipartFile(req, "image");
      if (!fileBuffer) {
        return res
          .status(400)
          .json({ error: "Missing image file (field name must be 'image')" });
      }

      let predictions;
      if (USE_PROVIDER === "replicate") {
        predictions = await callReplicate(fileBuffer, mimeType);
      } else {
        predictions = await callHuggingFace(fileBuffer);
      }

      return res.status(200).json({ predictions });
    } catch (e) {
      console.error(e);
      return res.status(500).json({ error: "Server error", details: String(e) });
    }
  });

/** Parse multipart/form-data, return Buffer + mimetype */
function readMultipartFile(req, fieldName) {
  return new Promise((resolve, reject) => {
    const busboy = Busboy({ headers: req.headers });
    let gotFile = false;
    let mimeType = "";
    let fileBuffer = Buffer.alloc(0);

    busboy.on("file", (name, file, info) => {
      if (name !== fieldName) {
        // drain other fields if any
        file.resume();
        return;
      }
      gotFile = true;
      mimeType = info.mimetype || "application/octet-stream";
      file.on("data", (data) => {
        fileBuffer = Buffer.concat([fileBuffer, data]);
      });
    });

    busboy.on("error", reject);
    busboy.on("finish", () => resolve({ fileBuffer: gotFile ? fileBuffer : null, mimeType }));
    req.pipe(busboy);
  });
}

/** Provider A — Hugging Face Inference (simple, one request) */
async function callHuggingFace(fileBuffer) {
  const hfToken = process.env.HUGGINGFACE_TOKEN;
  const hfModel = process.env.HF_MODEL; // e.g. "username/plant-disease-model"
  if (!hfToken || !hfModel) {
    throw new Error("Missing HUGGINGFACE_TOKEN or HF_MODEL secret");
  }

  const resp = await fetch(`https://api-inference.huggingface.co/models/${hfModel}`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${hfToken}`,
      "Content-Type": "application/octet-stream",
    },
    body: fileBuffer,
  });

  // HF may return 503 for first-time cold start (model loading). You may retry.
  if (!resp.ok) {
    const text = await resp.text();
    throw new Error(`HuggingFace ${resp.status}: ${text}`);
  }
  const out = await resp.json();

  // Typical image-classification output:
  // [ { "label": "Early Blight", "score": 0.742 }, ... ]
  const arr = Array.isArray(out) ? out : [];
  const predictions = arr.map((o) => ({
    label: o.label || o.class || "Unknown",
    confidence: Number(o.score ?? o.confidence ?? 0),
    // If your model returns image URLs, map to thumbnailUrl here:
    // thumbnailUrl: o.image || o.thumbnail || undefined
  }));
  return predictions;
}

/** Provider B — Replicate (start + poll) */
async function callReplicate(fileBuffer, mimeType) {
  const token = process.env.REPLICATE_API_TOKEN;
  const version = process.env.REPLICATE_MODEL_VERSION; // e.g. "owner/model:hash"
  if (!token || !version) {
    throw new Error("Missing REPLICATE_API_TOKEN or REPLICATE_MODEL_VERSION secret");
  }
  const base64 = `data:${mimeType};base64,${fileBuffer.toString("base64")}`;

  // 1) start
  const start = await fetch("https://api.replicate.com/v1/predictions", {
    method: "POST",
    headers: {
      Authorization: `Token ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ version, input: { image: base64 } }),
  });
  const started = await start.json();
  if (!start.ok) {
    throw new Error(`Replicate start failed: ${JSON.stringify(started)}`);
  }

  // 2) poll
  let prediction = started;
  let tries = 0;
  while (prediction.status === "starting" || prediction.status === "processing") {
    await new Promise((r) => setTimeout(r, 1200));
    const poll = await fetch(
      `https://api.replicate.com/v1/predictions/${prediction.id}`,
      { headers: { Authorization: `Token ${token}` } }
    );
    prediction = await poll.json();
    if (++tries > 25) break;
  }
  if (prediction.status !== "succeeded") {
    throw new Error(`Replicate failed: ${JSON.stringify(prediction)}`);
  }

  // You must normalize based on your chosen model’s output format.
  // Many models return [{label:"...", score:0.74}, ...]
  const raw = prediction.output || [];
  const predictions = (Array.isArray(raw) ? raw : []).map((r) => ({
    label: r.label ?? r.class ?? "Unknown",
    confidence: Number(r.score ?? r.confidence ?? 0),
    thumbnailUrl: r.thumbnail ?? undefined,
  }));
  return predictions;
}

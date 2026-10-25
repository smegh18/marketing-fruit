const functions = require("firebase-functions");
const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const cors = require("cors")({ origin: true });
const nodemailer = require("nodemailer");
const { ethers } = require("ethers");
const axios = require("axios");
const FormData = require("form-data");
const Stripe = require("stripe");
const fetch = require('node-fetch');

// Initialize Stripe with your secret key
const stripeKey = process.env.STRIPE_SECRET_KEY || "";
const stripe = new Stripe(stripeKey, {
  apiVersion: "2022-11-15",
});

if (!admin.apps.length) {
  admin.initializeApp();
}

// Your existing code here...
 // use your env-configured secret

exports.createStripePaymentLink = functions.https.onCall(async (data, context) => {
  try {
    const payload = data.data || data;
    let { name, price, currency, quantity } = payload;
    price = typeof price === 'string' ? parseFloat(price) : Number(price);
    name = name || "Product";
    currency = currency || "usd";
    quantity = Number(quantity) || 1;

    if (isNaN(price) || price <= 0) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `Invalid price: ${price} (must be a positive number)`
      );
    }

    const unit_amount = Math.round(price * 100);

    const paymentLink = await stripe.paymentLinks.create({
      line_items: [
        {
          price_data: {
            currency: currency,
            product_data: { name: name },
            unit_amount: unit_amount,
          },
          quantity: quantity,
        },
      ],
      phone_number_collection: { enabled: true },
      shipping_address_collection: {
        allowed_countries: ['US', 'CA', 'IN'], // or restrict as needed
      },
      billing_address_collection: 'required',
      // payment_method_types is NOT available for Payment Links,
      // cannot restrict here; API ignores this field for payment links.
      after_completion: {
        type: 'redirect',
        redirect: { url: 'https://marketingfruit-9e24d.web.app/stripe-success' },
      },
    });

    return { url: paymentLink.url, id: paymentLink.id };
  } catch (e) {
    console.error('Stripe Payment Link error', e);
    throw new functions.https.HttpsError('internal', e.message || 'Unknown error');
  }
});


exports.createStripeCheckoutSession = functions.https.onCall(async (data, context) => {
  try {
    const payload = data.data || data;
    let { name, price, currency, quantity, phone, email } = payload;
    price = typeof price === 'string' ? parseFloat(price) : Number(price);
    name = name || "Product";
    currency = currency || "usd";
    quantity = Number(quantity) || 1;

    if (isNaN(price) || price <= 0) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `Invalid price: ${price} (must be a positive number)`
      );
    }

    const unit_amount = Math.round(price * 100);

    // Create the Stripe Checkout Session
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card', 'us_bank_account'],
      // For Apple Pay support, no config needed; it's available for 'card' on Safari devices
      mode: 'payment',
      line_items: [{
        price_data: {
          currency: currency,
          product_data: { name: name },
          unit_amount: unit_amount,
        },
        quantity: quantity,
      }],
      billing_address_collection: 'required',
      shipping_address_collection: {
        allowed_countries: ['US', 'CA', 'IN'], // Edit as needed
      },
      phone_number_collection: { enabled: true },
      customer_email: email, // If you have the email at sign-in, otherwise omit
      tax_id_collection: {enabled: false},
      // Taxes are set as inclusive via Dashboard or by calculating in price
      success_url: 'https://marketingfruit-9e24d.web.app/stripe-success',
      cancel_url: 'https://marketingfruit-9e24d.web.app/stripe-cancel',
      // Optionally add more metadata, automatic tax, etc.
    });

    return { url: session.url, id: session.id }; // Return the Checkout Session URL
  } catch (e) {
    console.error('Stripe Checkout error', e);
    throw new functions.https.HttpsError('internal', e.message || 'Unknown error');
  }
});







// New Stripe PaymentIntent creation function
exports.createPaymentIntent = onRequest(async (req, res) => {
  cors(req, res, async () => {
    if (req.method !== "POST") {
      return res.status(405).send("Only POST requests are allowed");
    }

    try {
      const { amount, currency, quantity, product_id } = req.body;

      if (!amount || !currency) {
        return res.status(400).json({ error: "Missing amount or currency" });
      }

      // Create PaymentIntent
      const paymentIntent = await stripe.paymentIntents.create({
        amount: parseInt(amount, 10),
        currency,
        payment_method_types: ["card"],
        metadata: {
          quantity: quantity?.toString() || "1",
          product_id: product_id?.toString() || "",
        },
      });

      return res.json({
        clientSecret: paymentIntent.client_secret,
      });
    } catch (error) {
      console.error("Stripe payment intent creation error:", error);
      return res.status(500).json({
        error: error.message || "Internal server error while creating PaymentIntent",
      });
    }
  });
});

exports.rssProxy = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const response = await fetch('https://feeds.libsyn.com/561905/rss');
      const xml = await response.text();
      res.set('Content-Type', 'application/xml');
      res.status(200).send(xml);
    } catch (err) {
      res.status(500).send('Error fetching RSS');
    }
  });
});

// EMAIL setup
const gmailEmail = "marketingfruitdev@gmail.com";
const gmailPassword = "ljazugguiavryuln";
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: { user: gmailEmail, pass: gmailPassword },
});
function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// Load ABI (Hardhat JSON)
let contractAbi = null;
function loadAbiIfNeeded() {
  if (!contractAbi) {
    contractAbi = require("./NFTContract.json").abi;
  }
  return contractAbi;
}

// Pinata IPFS upload
async function uploadImageToIPFS(imageBase64, fileName, pinataKey, pinataSecret) {
  const buffer = Buffer.from(imageBase64, "base64");
  const form = new FormData();
  form.append("file", buffer, { filename: fileName });
  const res = await axios.post(
    "https://api.pinata.cloud/pinning/pinFileToIPFS",
    form,
    {
      maxContentLength: Infinity,
      maxBodyLength: Infinity,
      headers: {
        ...form.getHeaders(),
        pinata_api_key: pinataKey,
        pinata_secret_api_key: pinataSecret,
      },
    }
  );
  return `ipfs://${res.data.IpfsHash}`;
}

async function uploadMetadataToIPFS(metadataObj, pinataKey, pinataSecret) {
  const res = await axios.post(
    "https://api.pinata.cloud/pinning/pinJSONToIPFS",
    metadataObj,
    {
      headers: {
        "Content-Type": "application/json",
        pinata_api_key: pinataKey,
        pinata_secret_api_key: pinataSecret,
      },
    }
  );
  return `ipfs://${res.data.IpfsHash}`;
}

// ---- MINT NFT ----
exports.mintNft = onRequest(async (req, res) => {
  cors(req, res, async () => {
    if (req.method !== "POST") return res.status(405).send("Only POST allowed!");
    const PRIVATE_KEY      = process.env.PRIVATE_KEY;
    const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS;
    const POLYGON_RPC      = process.env.POLYGON_RPC;
    const PINATA_KEY       = process.env.PINATA_KEY;
    const PINATA_SECRET    = process.env.PINATA_SECRET;

    if (!PRIVATE_KEY || !CONTRACT_ADDRESS || !POLYGON_RPC || !PINATA_KEY || !PINATA_SECRET) {
      return res.status(500).json({ error: "Server mint ENV missing" });
    }

    let name, description, imageBase64, attributes, quantity, priceWei, validity;
    try {
      const data = typeof req.body === "object" ? req.body : JSON.parse(req.body || "{}");
      name = data.name;
      description = data.description;
      imageBase64 = data.imageBase64;
      attributes = data.attributes;
      quantity = data.quantity;
      priceWei = data.priceWei;
      validity = data.validity;
    } catch (e) {
      return res.status(400).json({ error: "Invalid JSON request body." });
    }

    // Validate required fields
    if (!name)      return res.status(400).json({ error: "Missing required field: name" });
    if (!description) return res.status(400).json({ error: "Missing required field: description" });
    if (!imageBase64) return res.status(400).json({ error: "Missing required field: imageBase64" });
    if (!attributes)  return res.status(400).json({ error: "Missing required field: attributes" });
    if (quantity === undefined || quantity === null) return res.status(400).json({ error: "Missing required field: quantity" });
    if (priceWei === undefined || priceWei === null || priceWei === "") {
      return res.status(400).json({ error: "Missing or invalid required field: priceWei" });
    }

        try {
          // 1. Pin image to Pinata IPFS
          const imageIPFS = await uploadImageToIPFS(imageBase64, name + ".png", PINATA_KEY, PINATA_SECRET);

          // 2. Pin metadata to Pinata IPFS
          const metadata = {
            name,
            description,
            image: imageIPFS,
            attributes,
            validity
          };
          const metadataIPFS = await uploadMetadataToIPFS(metadata, PINATA_KEY, PINATA_SECRET);

          // 3. Mint on chain using BigInt for priceWei
          const abi = loadAbiIfNeeded();
          const provider = new ethers.JsonRpcProvider(POLYGON_RPC);
          const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
          const contract = new ethers.Contract(CONTRACT_ADDRESS, abi, wallet);

          // Mint and get tx object
          const tx = await contract.mintNFT(
            metadataIPFS,
            Number(quantity),
            BigInt(priceWei),
            Number(validity) || 0
          );
          const receipt = await tx.wait();

          // ---- Get tokenId from transaction receipt ----
          let tokenId = null;
          // Find the Minted event in the logs
          if (receipt && receipt.events && receipt.events.length > 0) {
            for (const evt of receipt.events) {
              if (evt.event === "Minted" && evt.args && evt.args.tokenId) {
                tokenId = evt.args.tokenId.toString();
                break;
              }
            }
          }
          // As fallback, try to get from return value or logs
          if (!tokenId && tx && tx.value) {
            tokenId = tx.value.toString();
          }

          return res.json({
            success: true,
            tokenURI: metadataIPFS,
            image: imageIPFS,
            txHash: tx.hash,
            blockNumber: receipt.blockNumber,
            tokenId: tokenId // <--- returned to frontend!
          });
        } catch (e) {
          console.error(e);
          return res.status(500).json({ error: e.message || "Mint failed" });
        }

  });
});


// ---- EDIT NFT ----
exports.editNft = onRequest(async (req, res) => {
  cors(req, res, async () => {
    if (req.method !== "POST") return res.status(405).send("Only POST allowed!");
    const PRIVATE_KEY = process.env.PRIVATE_KEY;
    const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS;
    const POLYGON_RPC = process.env.POLYGON_RPC;

    if (!PRIVATE_KEY || !CONTRACT_ADDRESS || !POLYGON_RPC) {
      return res.status(500).json({ error: "Server ENV missing" });
    }

    const {
      tokenId, newName, newDescription, newImageBase64, newAttributes, newPriceWei, newValidity,
    } = typeof req.body === "object" ? req.body : JSON.parse(req.body || "{}");
    if (!tokenId || !newName || !newDescription || !newAttributes) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    try {
      let newImageIpfs = undefined;
      if (newImageBase64) {
        const PINATA_KEY = process.env.PINATA_KEY;
        const PINATA_SECRET = process.env.PINATA_SECRET;
        newImageIpfs = await uploadImageToIPFS(newImageBase64, newName + "_edit.png", PINATA_KEY, PINATA_SECRET);
      }

      const metadata = {
        name: newName,
        description: newDescription,
        image: newImageIpfs,
        attributes: newAttributes,
        validity: newValidity,
      };

      let newMetadataIpfs;
      if (newImageIpfs) {
        const PINATA_KEY = process.env.PINATA_KEY;
        const PINATA_SECRET = process.env.PINATA_SECRET;
        newMetadataIpfs = await uploadMetadataToIPFS(metadata, PINATA_KEY, PINATA_SECRET);
      }

      const abi = loadAbiIfNeeded();
      const provider = new ethers.JsonRpcProvider(POLYGON_RPC);
      const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
      const contract = new ethers.Contract(CONTRACT_ADDRESS, abi, wallet);

      const tx = await contract.editNFT(
        Number(tokenId),
        newMetadataIpfs || '',
        newPriceWei !== undefined && newPriceWei !== null && newPriceWei !== ""
          ? BigInt(newPriceWei)
          : BigInt(0),
        Number(newValidity) || 0
      );
      const receipt = await tx.wait();

      return res.json({
        success: true,
        txHash: tx.hash,
        blockNumber: receipt.blockNumber
      });
    } catch (e) {
      console.error(e);
      return res.status(500).json({ error: e.message || "Edit failed" });
    }
  });
});

// ---- DELIST NFT ----
exports.delistNft = onRequest(async (req, res) => {
  cors(req, res, async () => {
    if (req.method !== "POST") return res.status(405).send("Only POST allowed!");
    const PRIVATE_KEY = process.env.PRIVATE_KEY;
    const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS;
    const POLYGON_RPC = process.env.POLYGON_RPC;

    if (!PRIVATE_KEY || !CONTRACT_ADDRESS || !POLYGON_RPC) {
      return res.status(500).json({ error: "Server ENV missing" });
    }
    const { tokenId } = typeof req.body === "object" ? req.body : JSON.parse(req.body || "{}");
    if (!tokenId) {
      return res.status(400).json({ error: "Missing tokenId" });
    }
    try {
      const abi = loadAbiIfNeeded();
      const provider = new ethers.JsonRpcProvider(POLYGON_RPC);
      const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
      const contract = new ethers.Contract(CONTRACT_ADDRESS, abi, wallet);

      const tx = await contract.delistNFT(Number(tokenId));
      await tx.wait();
      return res.json({ success: true, txHash: tx.hash });
    } catch (e) {
      console.error(e);
      return res.status(500).json({ error: e.message || "Delist failed" });
    }
  });
});

// ---- BUY NFT ----
exports.buyNft = onRequest(async (req, res) => {
  cors(req, res, async () => {
    if (req.method !== "POST") return res.status(405).send("Only POST allowed!");
    const PRIVATE_KEY = process.env.PRIVATE_KEY;
    const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS;
    const POLYGON_RPC = process.env.POLYGON_RPC;
    if (!PRIVATE_KEY || !CONTRACT_ADDRESS || !POLYGON_RPC) {
      return res.status(500).json({ error: "Server ENV missing" });
    }
    const { tokenId, quantity } = typeof req.body === "object" ? req.body : JSON.parse(req.body || "{}");
    if (!tokenId || !quantity) {
      return res.status(400).json({ error: "Missing tokenId/quantity" });
    }
    try {
      const abi = loadAbiIfNeeded();
      const provider = new ethers.JsonRpcProvider(POLYGON_RPC);
      const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
      const contract = new ethers.Contract(CONTRACT_ADDRESS, abi, wallet);

      const info = await contract.infoOf(tokenId);
      // priceWei should already be a BN or can be BigInt-ed
      const priceWei = BigInt(info.priceWei.toString());
      const totalPrice = priceWei * BigInt(quantity);

      const tx = await contract.buy(Number(tokenId), Number(quantity), { value: totalPrice });
      await tx.wait();
      return res.json({ success: true, txHash: tx.hash });
    } catch (e) {
      console.error(e);
      return res.status(500).json({ error: e.message || "Buy failed" });
    }
  });
});

// --- Email/utility/location functions (unchanged) ---
exports.sendOtpEmail = functions.https.onCall(async (req, context) => {
  const payload = req.data || req;
  const email = payload.email;
  if (!email || typeof email !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'No valid email provided');
  }
  const otp = generateOTP();
  const mailOptions = {
    from: gmailEmail,
    to: email,
    subject: 'Your Verification OTP',
    text: `Your OTP for verification is: ${otp}`,
  };
  try {
    await transporter.sendMail(mailOptions);
    return { success: true, otp };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message || 'Failed to send email');
  }
});
exports.sendGuardianVerificationEmail = functions.https.onCall(async (req, context) => {
  const payload = req.data || req;
  const { guardianEmail, childId } = payload;

  if (!guardianEmail || typeof guardianEmail !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid guardian email');
  }
  if (!childId || typeof childId !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Missing child ID');
  }
  const verificationLink = `https://marketingfruit-9e24d.web.app/#/verify-guardian?childId=${childId}`;
  const mailOptions1 = {
    from: gmailEmail,
    to: guardianEmail,
    subject: 'Guardian Verification Required',
    html: `
      <p>Hello,</p>
      <p>Please verify your child’s account by clicking the link below:</p>
      <a href="${verificationLink}">Verify Child Account</a>
      <p>If you didn’t expect this, you can ignore this email.</p>
    `,
  };

  try {
    await transporter.sendMail(mailOptions1);
    return { success: true };
  } catch (error) {
    throw new functions.https.HttpsError('internal', 'Failed to send guardian verification email');
  }
});
exports.placesProxy = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST");
  res.set("Access-Control-Allow-Headers", "Content-Type");
  const input = req.query.input;
  const key = "AIzaSyBFGd1hXyEqZVJqC34aDDeO7U1tYPn_Snk";
  const url = `https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${encodeURIComponent(input)}&key=${key}&types=geocode`;
  try {
    const apiRes = await fetch(url);
    const data = await apiRes.json();
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch Google API data" });
  }
});
exports.verifyGuardian = functions.https.onCall(async (req, context) => {
  const payload = req.data || req;
  const childId = payload.childId;
  if (!childId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing child ID');
  }
  try {
    return { success: true };
  } catch (error) {
    throw new functions.https.HttpsError('internal', 'Failed to mark guardian as verified');
  }
});

// --- END ---

/**
 * Vestiyer / Dolap AI – Cloud Functions
 * Callables: analyzeClothing, generateCombinations, getStyleAdvice, managePremiumStatus
 * Profil fotoğrafı ve kıyafet görselleri client'tan Storage'a yüklenir; Firestore users/{uid} profil alanları client günceller.
 */
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const {
  analyzeClothingFromUrl,
  generateCombinations,
  selectAndDescribeCombinations,
  generateStylingAdvice,
  getStyleAdvice,
  getShoppingSuggestions,
  detectChatIntent
} = require('./services/aiService');
const { generateOutfitCandidates } = require('./services/combinationEngine');
const { checkImageQuality } = require('./services/imageQualityCheck');
const { extractDominantColors } = require('./services/colorExtraction');
const { callVpsSegment, checkVpsHealth } = require('./services/segmentService');
const { t } = require('./services/i18n');

admin.initializeApp();

const db = admin.firestore();
const { OpenAI } = require('openai');

const CONFIDENCE_THRESHOLD = 0.7;

/** Lazy init: OpenAI is only created at runtime when a function runs (so deploy does not require OPENAI_API_KEY). */
function getOpenAIClient(locale) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      t(locale || 'tr', 'errors.openaiNotConfigured')
    );
  }
  return new OpenAI({ apiKey });
}

function requireAuth(context, locale = 'tr') {
  if (!context.auth || !context.auth.uid) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      t(locale, 'errors.authRequired')
    );
  }
  return context.auth.uid;
}

async function uploadSegmentedToStorage(userId, buffer) {
  const bucket = admin.storage().bucket();
  const filename = `segmented_${Date.now()}.png`;
  const path = `clothing_images/${userId}/${filename}`;
  const file = bucket.file(path);
  await file.save(buffer, { metadata: { contentType: 'image/png' } });
  const expiresMs = 10 * 365 * 24 * 60 * 60 * 1000;
  const [signedUrl] = await file.getSignedUrl({
    action: 'read',
    expires: Date.now() + expiresMs
  });
  return signedUrl;
}

exports.analyzeClothing = functions
  .runWith({
    timeoutSeconds: 60,
    secrets: ['OPENAI_API_KEY', 'SEGMENT_SERVICE_URL', 'SEGMENT_SERVICE_API_KEY']
  })
  .https.onCall(async (data, context) => {
    const locale = (data && data.locale) || 'tr';
    const uid = requireAuth(context, locale);
    const { userId, imageUrl, title } = data || {};
    if (userId && userId !== uid) {
      throw new functions.https.HttpsError('permission-denied', t(locale, 'errors.permissionDenied'));
    }
    const targetUserId = userId || uid;
    if (!imageUrl || typeof imageUrl !== 'string') {
      throw new functions.https.HttpsError('invalid-argument', t(locale, 'errors.imageUrlRequired'));
    }

    const qualityCheck = await checkImageQuality(imageUrl);
    if (!qualityCheck.ok) {
      throw new functions.https.HttpsError('invalid-argument', qualityCheck.error || t(locale, 'errors.imageQualityPoor'));
    }

    let segmentResult = { success: false };
    const segmentUrl =
      process.env.SEGMENT_SERVICE_URL ||
      (typeof functions.config().segment_service === 'object' && functions.config().segment_service?.url) ||
      '';
    const segmentKey =
      process.env.SEGMENT_SERVICE_API_KEY ||
      (typeof functions.config().segment_service === 'object' && functions.config().segment_service?.api_key) ||
      '';
    segmentResult = segmentUrl && segmentUrl.startsWith('http')
      ? await callVpsSegment(imageUrl, segmentUrl, segmentKey)
      : { success: false };

    let imageForVision = imageUrl;
    let imageForColor = imageUrl;
    let segmentedImageUrl = null;
    let segmentationSkipped = true;

    if (segmentResult.success && segmentResult.buffer) {
      try {
        segmentedImageUrl = await uploadSegmentedToStorage(targetUserId, segmentResult.buffer);
        imageForVision = segmentedImageUrl;
        imageForColor = segmentResult.buffer;
        segmentationSkipped = false;
        if (segmentResult.telemetry) {
          console.log('Segment telemetry', {
            uid: targetUserId,
            model: segmentResult.telemetry.model || 'unknown',
            confidence: segmentResult.telemetry.confidence,
            fallbackUsed: segmentResult.telemetry.fallbackUsed,
            latencyMs: segmentResult.telemetry.latencyMs
          });
        }
      } catch (e) {
        imageForVision = imageUrl;
        imageForColor = imageUrl;
      }
    }

    const backendColors = await extractDominantColors(imageForColor);

    const result = await analyzeClothingFromUrl(getOpenAIClient(locale), imageForVision, backendColors, locale);
    if (!result.success) {
      throw new functions.https.HttpsError('internal', result.error || t(locale, 'errors.analysisFailed'));
    }

    const category = result.category || 'top';
    const colors = result.colors || [result.parsedAnalysis.color].filter(Boolean);
    const confidence = result.confidence ?? 0.8;
    const lowConfidence = confidence < CONFIDENCE_THRESHOLD;
    const clothingCost = (result.usage.prompt_tokens * 0.00765) / 1000 + (result.usage.completion_tokens * 0.03) / 1000;
    // Use segmented image as primary when available – user sees only the garment in wardrobe
    const finalImageUrl = segmentedImageUrl || imageUrl;
    const doc = {
      userId: targetUserId,
      title: title || result.parsedAnalysis.category || t(locale, 'defaultClothingTitle'),
      category,
      imageUrl: finalImageUrl,
      imagePath: finalImageUrl,
      ...(segmentationSkipped && { segmentationSkipped: true }),
      ...(!segmentationSkipped && { segmentationSource: 'server' }),
      colors,
      colorsWithDominance: result.colorsWithDominance || null,
      confidence,
      lowConfidence,
      advancedAnalysis: result.advancedAnalysis,
      formattedAnalysis: result.formattedAnalysis,
      apiUsage: {
        promptTokens: result.usage.prompt_tokens,
        completionTokens: result.usage.completion_tokens,
        totalCost: clothingCost,
        model: 'gpt-4o',
        analyzedAt: admin.firestore.FieldValue.serverTimestamp()
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const ref = await db
      .collection('users')
      .doc(targetUserId)
      .collection('clothing')
      .add(doc);

    await db.collection('users').doc(targetUserId).collection('api_usage').add({
      operationType: 'clothing_upload',
      model: 'gpt-4o',
      promptTokens: result.usage.prompt_tokens,
      completionTokens: result.usage.completion_tokens,
      cost: clothingCost,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      clothingId: ref.id
    });

    return {
      success: true,
      clothingId: ref.id,
      message: t(locale, 'success.clothingAnalyzed'),
      lowConfidence: lowConfidence || undefined
    };
  });

exports.generateCombinations = functions
  .runWith({ timeoutSeconds: 60, secrets: ['OPENAI_API_KEY'] })
  .https.onCall(async (data, context) => {
    const locale = (data && data.locale) || 'tr';
    const uid = requireAuth(context, locale);
    const { userId, forceGenerate, occasion } = data || {};
    const targetUserId = userId || uid;

    const clothingSnap = await db
      .collection('users')
      .doc(targetUserId)
      .collection('clothing')
      .orderBy('createdAt', 'desc')
      .get();

    const clothingItems = clothingSnap.docs.map((d) => {
      const x = d.data();
      return {
        id: d.id,
        _id: d.id,
        ...x,
        advancedAnalysis: x.advancedAnalysis || {}
      };
    });

    if (clothingItems.length === 0) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        t(locale, 'errors.wardrobeEmpty')
      );
    }

    const userDoc = await db.collection('users').doc(targetUserId).get();
    const userProfile = userDoc.exists && userDoc.data()?.styleProfile
      ? userDoc.data().styleProfile
      : null;

    const engineResult = generateOutfitCandidates(clothingItems, occasion, { userProfile });

    if (engineResult.mode === 'insufficient') {
      throw new functions.https.HttpsError(
        'failed-precondition',
        engineResult.message || t(locale, 'errors.insufficientItems')
      );
    }

    let result;
    if (engineResult.mode === 'styling' && engineResult.singleItems && engineResult.singleItems.length > 0) {
      const adviceResult = await generateStylingAdvice(
        getOpenAIClient(locale),
        engineResult.singleItems[0],
        occasion,
        locale
      );
      const comboCost = (adviceResult.usage.prompt_tokens * 0.00015) / 1000 +
        (adviceResult.usage.completion_tokens * 0.0006) / 1000;
      await db.collection('users').doc(targetUserId).collection('api_usage').add({
        operationType: 'combination',
        model: 'gpt-4o-mini',
        promptTokens: adviceResult.usage.prompt_tokens,
        completionTokens: adviceResult.usage.completion_tokens,
        cost: comboCost,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        mode: 'styling'
      });
      return {
        success: true,
        mode: 'styling',
        stylingAdvice: { advice: adviceResult.advice, itemId: adviceResult.itemId },
        message: t(locale, 'success.stylingAdviceReady')
      };
    }

    if (engineResult.candidates && engineResult.candidates.length > 0) {
      result = await selectAndDescribeCombinations(
        getOpenAIClient(locale),
        engineResult.candidates,
        occasion,
        userProfile,
        locale
      );
    } else {
      result = await generateCombinations(getOpenAIClient(locale), clothingItems, occasion, userProfile, locale);
    }

    if (!result.success) {
      throw new functions.https.HttpsError('internal', result.error || t(locale, 'errors.combinationFailed'));
    }

    const comboCost = (result.usage.prompt_tokens * 0.00015) / 1000 + (result.usage.completion_tokens * 0.0006) / 1000;
    await db.collection('users').doc(targetUserId).collection('api_usage').add({
      operationType: 'combination',
      model: 'gpt-4o-mini',
      promptTokens: result.usage.prompt_tokens,
      completionTokens: result.usage.completion_tokens,
      cost: comboCost,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      combinationCount: (result.combinations || []).length
    });

    return {
      success: true,
      mode: engineResult.mode || 'full',
      message: t(locale, 'success.combinationsCreated'),
      combinations: result.combinations,
      totalItems: clothingItems.length,
      usedItems: clothingItems.length
    };
  });

exports.saveCombination = functions
  .runWith({ timeoutSeconds: 30 })
  .https.onCall(async (data, context) => {
    const locale = (data && data.locale) || 'tr';
    const uid = requireAuth(context, locale);
    const { userId, combination } = data || {};
    const targetUserId = userId || uid;

    if (!combination || !combination.items || combination.items.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', t(locale, 'errors.combinationDataMissing'));
    }

    const clothingItemsForDoc = (combination.items || []).map((id) => ({
      clothingId: id,
      category: null,
      isRequired: true
    }));

    const docRef = await db
      .collection('users')
      .doc(targetUserId)
      .collection('combinations')
      .add({
        name: combination.name || 'Yeni Kombin',
        description: combination.description || '',
        occasion: combination.occasion || 'casual',
        season: combination.season || 'all-season',
        clothingItems: clothingItemsForDoc,
        isAIGenerated: true,
        isFavorite: false,
        timesWorn: 0,
        tags: [],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

    return {
      success: true,
      combinationId: docRef.id,
      message: t(locale, 'success.combinationSaved')
    };
  });

exports.getStyleAdvice = functions
  .runWith({ timeoutSeconds: 60, secrets: ['OPENAI_API_KEY'] })
  .https.onCall(async (data, context) => {
    const locale = (data && data.locale) || 'tr';
    const uid = requireAuth(context, locale);
    const { message, conversationHistory, wardrobeSummary } = data || {};
    if (!message || typeof message !== 'string') {
      throw new functions.https.HttpsError('invalid-argument', t(locale, 'errors.messageRequired'));
    }

    const history = Array.isArray(conversationHistory) ? conversationHistory.slice(-5) : [];
    const summary = wardrobeSummary && typeof wardrobeSummary === 'object' ? wardrobeSummary : null;

    const intent = detectChatIntent(message);
    let combinationResult = null;

    if (intent === 'combination_advice') {
      const clothingSnap = await db
        .collection('users')
        .doc(uid)
        .collection('clothing')
        .orderBy('createdAt', 'desc')
        .get();

      const clothingItems = clothingSnap.docs.map((d) => {
        const x = d.data();
        return { id: d.id, _id: d.id, ...x, advancedAnalysis: x.advancedAnalysis || {} };
      });

      if (clothingItems.length >= 2) {
        const engineResult = generateOutfitCandidates(clothingItems, 'casual');
        if (engineResult.candidates && engineResult.candidates.length > 0) {
          const selectResult = await selectAndDescribeCombinations(
            getOpenAIClient(locale),
            engineResult.candidates,
            'casual',
            null,
            locale
          );
          if (selectResult.combinations && selectResult.combinations.length > 0) {
            combinationResult = { combinations: selectResult.combinations };
          }
        } else if (engineResult.mode === 'styling' && engineResult.singleItems && engineResult.singleItems.length > 0) {
          const adviceResult = await generateStylingAdvice(
            getOpenAIClient(locale),
            engineResult.singleItems[0],
            'casual',
            locale
          );
          combinationResult = {
            combinations: [{
              name: 'Stil Önerisi',
              description: adviceResult.advice,
              items: [adviceResult.itemId],
              occasion: 'casual',
              season: 'all-season',
              accessories: '',
              usage: ''
            }]
          };
        }
      }
    }

    const result = await getStyleAdvice(
      getOpenAIClient(locale),
      message,
      history,
      summary,
      { combinationResult, occasion: 'casual' },
      locale
    );

    return {
      success: true,
      response: result.response
    };
  });

exports.getShoppingSuggestions = functions
  .runWith({ timeoutSeconds: 60, secrets: ['OPENAI_API_KEY'] })
  .https.onCall(async (data, context) => {
    const locale = (data && data.locale) || 'tr';
    const uid = requireAuth(context, locale);
    const { userId, wardrobeSummary } = data || {};
    const targetUserId = userId || uid;

    if (targetUserId !== uid) {
      throw new functions.https.HttpsError('permission-denied', t(locale, 'errors.permissionDenied'));
    }

    const summary = wardrobeSummary && typeof wardrobeSummary === 'object' ? wardrobeSummary : null;

    const userDoc = await db.collection('users').doc(targetUserId).get();
    const userProfile = userDoc.exists && userDoc.data()?.styleProfile
      ? userDoc.data().styleProfile
      : null;

    const result = await getShoppingSuggestions(
      getOpenAIClient(locale),
      summary,
      userProfile,
      locale
    );

    const cost = (result.usage.prompt_tokens * 0.00015) / 1000 + (result.usage.completion_tokens * 0.0006) / 1000;
    await db.collection('users').doc(targetUserId).collection('api_usage').add({
      operationType: 'shopping_suggestions',
      model: 'gpt-4o-mini',
      promptTokens: result.usage.prompt_tokens,
      completionTokens: result.usage.completion_tokens,
      cost: cost,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    return {
      success: true,
      suggestions: result.suggestions
    };
  });

exports.managePremiumStatus = functions.https.onCall(async (data, context) => {
  const locale = (data && data.locale) || 'tr';
  const uid = requireAuth(context, locale);
  const { userId, ...payload } = data || {};
  const targetUserId = userId || uid;
  if (targetUserId !== uid) {
    throw new functions.https.HttpsError('permission-denied', t(locale, 'errors.permissionDeniedShort'));
  }
  await db.collection('users').doc(targetUserId).update({
    ...payload,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });
  return { success: true };
});

/** VPS segment servisinin sağlık kontrolü. GET /health ile erişilebilirlik ve gecikme döner. */
exports.checkSegmentServiceHealth = functions
  .runWith({
    timeoutSeconds: 15,
    secrets: ['SEGMENT_SERVICE_URL']
  })
  .https.onCall(async (data, context) => {
    const locale = (data && data.locale) || 'tr';
    requireAuth(context, locale);

    const segmentUrl =
      process.env.SEGMENT_SERVICE_URL ||
      (typeof functions.config().segment_service === 'object' && functions.config().segment_service?.url) ||
      '';

    const result = await checkVpsHealth(segmentUrl);

    return {
      ok: result.ok,
      configured: !!segmentUrl && segmentUrl.startsWith('http'),
      ...(result.latencyMs != null && { latencyMs: result.latencyMs }),
      ...(result.error && { error: result.error }),
      ...(result.statusCode != null && { statusCode: result.statusCode })
    };
  });

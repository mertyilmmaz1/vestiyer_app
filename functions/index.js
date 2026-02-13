const functions = require('firebase-functions');
const admin = require('firebase-admin');
const {
  analyzeClothingFromUrl,
  generateCombinations,
  getStyleAdvice
} = require('./services/aiService');

admin.initializeApp();

const db = admin.firestore();
const { OpenAI } = require('openai');

/** Lazy init: OpenAI is only created at runtime when a function runs (so deploy does not require OPENAI_API_KEY). */
function getOpenAIClient() {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'OPENAI_API_KEY yapılandırılmamış. Firebase Secret Manager veya config ile ekleyin.'
    );
  }
  return new OpenAI({ apiKey });
}

function requireAuth(context) {
  if (!context.auth || !context.auth.uid) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Oturum açmanız gerekiyor.'
    );
  }
  return context.auth.uid;
}

const mainGroupToCategory = {
  'üst giyim': 'top',
  'alt giyim': 'bottom',
  'dış giyim': 'outerwear',
  'ayakkabı': 'shoes',
  'aksesuar': 'accessory'
};

exports.analyzeClothing = functions
  .runWith({ timeoutSeconds: 60, secrets: ['OPENAI_API_KEY'] })
  .https.onCall(async (data, context) => {
    const uid = requireAuth(context);
    const { userId, imageUrl, title } = data || {};
    if (userId && userId !== uid) {
      throw new functions.https.HttpsError('permission-denied', 'Yetkisiz erişim.');
    }
    const targetUserId = userId || uid;
    if (!imageUrl || typeof imageUrl !== 'string') {
      throw new functions.https.HttpsError('invalid-argument', 'imageUrl zorunludur.');
    }

    const result = await analyzeClothingFromUrl(getOpenAIClient(), imageUrl);
    if (!result.success) {
      throw new functions.https.HttpsError('internal', result.error || 'Analiz başarısız.');
    }

    const category = mainGroupToCategory[result.parsedAnalysis.mainGroup] || 'top';
    const colors = result.colors || [result.parsedAnalysis.color].filter(Boolean);
    const doc = {
      userId: targetUserId,
      title: title || result.parsedAnalysis.category || 'Kıyafet',
      category,
      imageUrl,
      imagePath: imageUrl,
      colors,
      advancedAnalysis: result.advancedAnalysis,
      formattedAnalysis: result.formattedAnalysis,
      apiUsage: {
        promptTokens: result.usage.prompt_tokens,
        completionTokens: result.usage.completion_tokens,
        totalCost: (result.usage.prompt_tokens * 0.00765) / 1000 + (result.usage.completion_tokens * 0.03) / 1000,
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

    return {
      success: true,
      clothingId: ref.id,
      message: 'Kıyafet analiz edildi ve kaydedildi.'
    };
  });

exports.generateCombinations = functions
  .runWith({ timeoutSeconds: 60, secrets: ['OPENAI_API_KEY'] })
  .https.onCall(async (data, context) => {
    const uid = requireAuth(context);
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
        'Dolabınızda henüz kıyafet bulunmuyor. Önce kıyafet ekleyin.'
      );
    }

    const result = await generateCombinations(getOpenAIClient(), clothingItems);
    if (!result.success) {
      throw new functions.https.HttpsError('internal', result.error || 'Kombin oluşturulamadı.');
    }

    const savedIds = [];
    for (const combo of result.combinations) {
      const clothingItemsForDoc = (combo.items || []).map((id) => ({
        clothingId: id,
        category: null,
        isRequired: true
      }));
      const docRef = await db
        .collection('users')
        .doc(targetUserId)
        .collection('combinations')
        .add({
          name: combo.name,
          description: combo.description,
          occasion: combo.occasion || 'casual',
          season: combo.season || 'all-season',
          clothingItems: clothingItemsForDoc,
          isAIGenerated: true,
          isFavorite: false,
          timesWorn: 0,
          tags: [],
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      savedIds.push({ id: docRef.id, name: combo.name });
    }

    return {
      success: true,
      message: 'Kombinler oluşturuldu.',
      savedCombinations: savedIds,
      totalItems: clothingItems.length,
      usedItems: clothingItems.length
    };
  });

exports.getStyleAdvice = functions
  .runWith({ timeoutSeconds: 30, secrets: ['OPENAI_API_KEY'] })
  .https.onCall(async (data, context) => {
    requireAuth(context);
    const { message, conversationHistory, wardrobeContext } = data || {};
    if (!message || typeof message !== 'string') {
      throw new functions.https.HttpsError('invalid-argument', 'message zorunludur.');
    }

    const result = await getStyleAdvice(
      getOpenAIClient(),
      message,
      Array.isArray(conversationHistory) ? conversationHistory : [],
      wardrobeContext
    );

    return {
      success: true,
      response: result.response
    };
  });

exports.managePremiumStatus = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const { userId, ...payload } = data || {};
  const targetUserId = userId || uid;
  if (targetUserId !== uid) {
    throw new functions.https.HttpsError('permission-denied', 'Yetkisiz.');
  }
  await db.collection('users').doc(targetUserId).update({
    ...payload,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });
  return { success: true };
});

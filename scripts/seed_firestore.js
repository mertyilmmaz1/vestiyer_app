/**
 * Seed Firestore with test user, sample clothing from assets/data/sample_clothes.json,
 * and a few combinations. Run with:
 *   GOOGLE_APPLICATION_CREDENTIALS=path/to/serviceAccountKey.json node scripts/seed_firestore.js
 * Or from project root with Firebase emulator:
 *   FIRESTORE_EMULATOR_HOST=localhost:8080 node scripts/seed_firestore.js
 */
const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const TEST_UID = process.env.TEST_UID || 'test-user-seed-uid';

function mapCategory(category) {
  const c = (category || '').toLowerCase();
  if (c.includes('gömlek') || c.includes('tişört') || c.includes('t-shirt') || c.includes('bluz') || c.includes('polo')) return 'top';
  if (c.includes('pantolon') || c.includes('etek') || c.includes('şort') || c.includes('kargo')) return 'bottom';
  if (c.includes('ceket') || c.includes('mont') || c.includes('kazak') || c.includes('hırka') || c.includes('blazer')) return 'outerwear';
  if (c.includes('ayakkabı') || c.includes('bot') || c.includes('sandalet')) return 'shoes';
  return 'top';
}

async function main() {
  if (!admin.apps.length) {
    admin.initializeApp();
  }
  const db = admin.firestore();

  const samplePath = path.join(__dirname, '..', 'assets', 'data', 'sample_clothes.json');
  let clothes = [];
  if (fs.existsSync(samplePath)) {
    const raw = fs.readFileSync(samplePath, 'utf8');
    const data = JSON.parse(raw);
    clothes = (data.clothes || []).slice(0, 10);
  } else {
    clothes = [
      { category: 'Gömlek', color: 'Beyaz', material: 'Pamuk', style: 'Klasik', season: 'Tüm Sezon', image_url: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c', description: 'Klasik beyaz gömlek' },
      { category: 'Pantolon', color: 'Lacivert', material: 'Denim', style: 'Casual', season: 'Tüm Sezon', image_url: 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246', description: 'Lacivert jean' },
      { category: 'Tişört', color: 'Beyaz', material: 'Pamuk', style: 'Casual', season: 'Yaz', image_url: 'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a', description: 'Basic tişört' },
    ];
  }

  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();

  const userRef = db.collection('users').doc(TEST_UID);
  batch.set(userRef, {
    email: 'test@dolap.ai',
    firstName: 'Test',
    lastName: 'User',
    isPremium: false,
    isActive: true,
    createdAt: now,
  }, { merge: true });

  const clothingIds = [];
  for (let i = 0; i < clothes.length; i++) {
    const c = clothes[i];
    const category = mapCategory(c.category);
    const color = c.color || 'Belirsiz';
    const colors = color.includes(',') ? color.split(',').map(s => s.trim()) : [color];
    const docRef = db.collection('users').doc(TEST_UID).collection('clothing').doc();
    clothingIds.push(docRef.id);
    batch.set(docRef, {
      title: c.category || 'Kıyafet',
      category,
      imageUrl: c.image_url || '',
      imagePath: c.image_url || '',
      colors,
      advancedAnalysis: {
        mainGroup: category === 'top' ? 'üst giyim' : category === 'bottom' ? 'alt giyim' : category === 'outerwear' ? 'dış giyim' : 'üst giyim',
        category: c.category,
        color,
        material: c.material || '',
        style: c.style || '',
        season: c.season || 'Tüm Sezon',
        details: c.description || '',
      },
      createdAt: now,
      updatedAt: now,
    });
  }

  const comboRef1 = db.collection('users').doc(TEST_UID).collection('combinations').doc();
  batch.set(comboRef1, {
    name: 'Günlük Kombin',
    description: 'Rahat günlük kullanım.',
    occasion: 'casual',
    season: 'all-season',
    clothingItems: [
      { clothingId: clothingIds[0], category: 'top', isRequired: true },
      { clothingId: clothingIds[1], category: 'bottom', isRequired: true },
    ],
    isAIGenerated: true,
    isFavorite: false,
    timesWorn: 0,
    tags: [],
    createdAt: now,
    updatedAt: now,
  });

  const comboRef2 = db.collection('users').doc(TEST_UID).collection('combinations').doc();
  batch.set(comboRef2, {
    name: 'İş Kombini',
    description: 'Ofis için uygun.',
    occasion: 'work',
    season: 'all-season',
    clothingItems: [
      { clothingId: clothingIds[0], category: 'top', isRequired: true },
      { clothingId: clothingIds[2] || clothingIds[1], category: 'bottom', isRequired: true },
    ],
    isAIGenerated: true,
    isFavorite: false,
    timesWorn: 0,
    tags: [],
    createdAt: now,
    updatedAt: now,
  });

  await batch.commit();
  console.log('Seed complete. Test UID:', TEST_UID);
  console.log('Clothing docs:', clothingIds.length);
  console.log('Create a user in Firebase Auth with UID', TEST_UID, 'or run with TEST_UID=<your-auth-uid> after creating a test user.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

const OpenAI = require('openai');
const sharp = require('sharp');

class AIService {
  constructor() {
    this.openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY
    });
  }

  // HEIC formatını JPEG'e dönüştür
  async convertHeicToJpeg(base64Image) {
    try {
      // Base64'ü buffer'a çevir
      const imageBuffer = Buffer.from(base64Image, 'base64');
      
      // Sharp ile format kontrol et ve gerekirse dönüştür
      const metadata = await sharp(imageBuffer).metadata();
      
      if (metadata.format === 'heif' || metadata.format === 'heic') {
        // HEIC/HEIF formatını JPEG'e dönüştür
        const jpegBuffer = await sharp(imageBuffer)
          .jpeg({ quality: 90 })
          .toBuffer();
        
        return jpegBuffer.toString('base64');
      }
      
      // Zaten desteklenen format ise olduğu gibi döndür
      return base64Image;
    } catch (error) {
      console.error('Image conversion error:', error);
      // Dönüştürme başarısız olursa orijinal base64'ü döndür
      return base64Image;
    }
  }

  // Ana grup değerlerini normalize etme fonksiyonu
  normalizeMainGroup(group) {
    const normalized = group.toLowerCase().trim();
    const validGroups = ['üst giyim', 'alt giyim', 'dış giyim', 'ayakkabı', 'aksesuar'];
    return validGroups.find(g => g === normalized) || 'üst giyim';
  }

  // Kıyafet fotoğrafı analizi (mobil için)
  async analyzeClothingAdvanced(base64Image) {
    try {
      // Base64 string'i temizle (data URL prefix'i varsa kaldır)
      let cleanBase64 = base64Image;
      if (base64Image.includes(',')) {
        cleanBase64 = base64Image.split(',')[1];
      }
      
      // HEIC formatını JPEG'e dönüştür
      const convertedImage = await this.convertHeicToJpeg(cleanBase64);
      
      // OpenAI API'ya gönderilecek image URL'i oluştur
      const imageUrl = `data:image/jpeg;base64,${convertedImage}`;
      
      const response = await this.openai.chat.completions.create({
        model: "gpt-4o",
        messages: [
          {
            role: "user",
            content: [
              {
                type: "text",
                text: `Bu kıyafetin kombin için önemli özelliklerini detaylı olarak analiz et. Yanıtı şu formatta ver:

Ana Grup: [üst giyim, alt giyim, dış giyim, ayakkabı, aksesuar]
Kategori: [ana grup içindeki detay kategori - örn: gömlek, pantolon, elbise, ceket, ayakkabı]
Renk: [ana renk ve varsa detay renkleri]
Materyal: [kumaş/malzeme türü - örn: pamuk, keten, deri, kot]
Stil: [casual, formal, spor, bohem, klasik, vintage, vb.]
Sezon: [hangi mevsimler için uygun - örn: yaz, kış, tüm yıl]
Detaylar: [desen, dikiş, kesim, fit, tasarım özellikleri ve kombinasyon için önemli diğer detaylar]

ÖNEMLİ NOTLAR:
1. Ana Grup seçiminde şu kategorileri kullan:
   - Üst Giyim: gömlek, tişört, kazak, sweatshirt, bluz, t-shirt, polo, tunik
   - Alt Giyim: pantolon, etek, şort, tayt, tayt-pantolon, şalvar
   - Dış Giyim: ceket, mont, kaban, hırka, yelek, blazer, trench coat
   - Ayakkabı: bot, ayakkabı, sandalet, spor ayakkabı, topuklu, düz
   - Aksesuar: çanta, şapka, atkı, eldiven, kemer, kolye, bilezik

2. Her kıyafeti sadece bir ana gruba yerleştir
3. Ana grup seçiminde kıyafetin temel işlevini dikkate al
4. Detaylar bölümünde kombinasyon için kritik olan tüm özellikleri belirt
5. Renk analizinde hem ana rengi hem de varsa desen/çizgi renklerini belirt
6. Materyal bilgisinde kumaş türü, kalınlık ve doku hakkında bilgi ver
7. Stil kategorisinde birden fazla stil özelliği varsa hepsini belirt
8. Sezon bilgisinde hangi mevsimlerde giyilebileceğini net olarak belirt`
              },
              {
                type: "image_url",
                image_url: { url: imageUrl }
              }
            ]
          }
        ],
        max_tokens: 800
      });

      const analysis = response.choices[0].message.content;
      const usage = response.usage;

      // Analiz sonuçlarını parse et
      let mainGroup = '', category = '', color = '', material = '', style = '', season = '', details = '';
      const lines = analysis.split('\n');
      
      for (const line of lines) {
        if (line.startsWith('Ana Grup:')) {
          mainGroup = this.normalizeMainGroup(line.replace('Ana Grup:', '').trim());
        } else if (line.startsWith('Kategori:')) {
          category = line.replace('Kategori:', '').trim();
        } else if (line.startsWith('Renk:')) {
          color = line.replace('Renk:', '').trim();
        } else if (line.startsWith('Materyal:')) {
          material = line.replace('Materyal:', '').trim();
        } else if (line.startsWith('Stil:')) {
          style = line.replace('Stil:', '').trim();
        } else if (line.startsWith('Sezon:')) {
          season = line.replace('Sezon:', '').trim();
        } else if (line.startsWith('Detaylar:')) {
          details = line.replace('Detaylar:', '').trim();
        }
      }

      // API kullanım maliyetini hesapla
      const promptTokens = usage.prompt_tokens;
      const completionTokens = usage.completion_tokens;
      const visionInputCost = (promptTokens * 0.00765) / 1000; // $0.00765 per 1K tokens
      const visionOutputCost = (completionTokens * 0.03) / 1000; // $0.03 per 1K tokens
      const totalCost = visionInputCost + visionOutputCost;

      return {
        success: true,
        rawAnalysis: analysis,
        parsedAnalysis: {
          mainGroup,
          category,
          color,
          material,
          style,
          season,
          details
        },
        formattedAnalysis: {
          ana_grup: mainGroup,
          kategori: category,
          renk: color,
          materyal: material,
          stil: style,
          sezon: season,
          detaylar: details
        },
        usage: {
          prompt_tokens: promptTokens,
          completion_tokens: completionTokens,
          total_cost: totalCost
        }
      };

    } catch (error) {
      console.error('AI Analysis Error:', error);
      throw new Error(`AI analiz hatası: ${error.message}`);
    }
  }

  // Kombin önerileri oluşturma (mobil için)
  async generateCombinations(clothingItems) {
    try {
      if (!clothingItems || clothingItems.length === 0) {
        throw new Error('Dolabınızda henüz kıyafet bulunmuyor. Önce kıyafet eklemelisiniz.');
      }

      // Kıyafetleri prompt için formatla
      const clothingDescriptions = clothingItems.map((item) => {
        return `[Kıyafet ${item._id}]
ID: ${item._id}
Ana Grup: ${this.mapCategoryToMainGroup(item.category)}
Kategori: ${item.category}
Başlık: ${item.title}
Renk: ${item.colors?.join(', ') || 'Belirtilmemiş'}
Materyal: ${item.advancedAnalysis?.material || 'Belirtilmemiş'}
Stil: ${item.advancedAnalysis?.style || item.aiAnalysis?.style || 'Belirtilmemiş'}
Sezon: ${item.advancedAnalysis?.season || item.aiAnalysis?.season?.join(', ') || 'Belirtilmemiş'}
Detaylar: ${item.advancedAnalysis?.details || item.aiAnalysis?.description || 'Belirtilmemiş'}
-------------------`
      }).join('\n\n');

      const response = await this.openai.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: `Sen bir profesyonel stilistsin. Kullanıcının gardırobundan uyumlu ve tarz kıyafet kombinasyonları oluşturarak kişilerin daha iyi giyinmelerine yardımcı oluyorsun.

1. KOMBİN KURALLARI:
- Duruma göre şu parçaları içermelisin:
  * 1 üst giyim (tişört, gömlek, bluz vb.) - "top" kategorisinden
  * 1 alt giyim (pantolon, etek, şort vb.) - "bottom" kategorisinden
  * Opsiyonel: 1 dış giyim (ceket, hırka, mont vb.) - "outerwear" kategorisinden
  * Opsiyonel: 1 ayakkabı - "shoes" kategorisinden
- EĞER belirli bir kategoriden kıyafet yoksa, bunu kombin açıklamasında belirt ve diğer mevcut öğelerle kombin oluştur
- Aynı kategoriden birden fazla kıyafet KULLANMA
- Her kıyafeti SADECE BİR kombinde kullan (ID'ler kombinler arasında tekrarlanmamalı)

2. UYUM KURALLARI:
- Renk uyumu: Tamamlayıcı veya uyumlu renkler seç
- Stil uyumu: Benzer stil kategorisindeki kıyafetleri eşleştir
- Sezon uyumu: Aynı mevsim için tasarlanmış kıyafetleri bir araya getir
- Materyal uyumu: Dokuların birbirine uyumlu olmasına dikkat et

3. ÇIKTI FORMATI (SADECE bu formatı kullan, asla değiştirme):
KOMBİN 1:
ID: [dış giyim ID - varsa]
ID: [üst giyim ID]
ID: [alt giyim ID]
ID: [ayakkabı ID - varsa]
AÇIKLAMA: [Kombinin stil tanımı ve neden bu parçaların seçildiği, max 3 cümle]
KULLANIM: [Bu kombinin giyilebileceği ortamlar/durumlar]
TAMAMLAYICILAR: [Eklenebilecek aksesuar önerileri]
SEZON: [Bu kombinin uygun olduğu mevsim(ler)]

NOT: Her kombin için TÜM alanları doldur ve TÜM ID'leri doğru şekilde belirt.`
          },
          {
            role: "user",
            content: `Mevcut Kıyafetlerim:
${clothingDescriptions}

Lütfen bu kıyafetlerimi kullanarak 3 FARKLI KOMBİN oluştur:
1. Günlük Kullanım (Casual)
2. İş/Ofis (Formal)
3. Spor/Aktif Yaşam veya Özel Durum

Eğer belirli bir kategori için yeterli kıyafetim yoksa, bunu belirt ve mevcut kıyafetlerimle en uygun kombinleri oluşturmaya çalış.`
          }
        ],
        temperature: 0.2,
        max_tokens: 1200,
      });

      const content = response.choices[0].message.content;
      const usage = response.usage;

      // Parse outfit suggestions to create structured output
      const parsedOutfits = this.parseOutfits(content);

      // API kullanım maliyetini hesapla (GPT-4o-mini pricing)
      const promptTokens = usage.prompt_tokens;
      const completionTokens = usage.completion_tokens;
      const inputCost = (promptTokens * 0.00015) / 1000;  // $0.00015 per 1K tokens
      const outputCost = (completionTokens * 0.0006) / 1000; // $0.0006 per 1K tokens
      const totalCost = inputCost + outputCost;

      return {
        success: true,
        combinations: parsedOutfits.map(outfit => ({
          name: this.getCombinationName(outfit.outfit_number),
          items: outfit.items,
          occasion: this.mapUsageToOccasion(outfit.details.kullanim),
          description: outfit.details.aciklama,
          season: outfit.details.sezon,
          accessories: outfit.details.tamamlayicilar,
          usage: outfit.details.kullanim
        })),
        rawResponse: content,
        parsed_outfits: parsedOutfits,
        usage: {
          prompt_tokens: promptTokens,
          completion_tokens: completionTokens,
          total_cost: totalCost,
          model: 'gpt-4o-mini'
        }
      };

    } catch (error) {
      console.error('Advanced Combination Generation Error:', error);
      return {
        success: false,
        error: error.message,
        combinations: []
      };
    }
  }

  // Çeşitlilik parametreleri ile kombin oluşturma (geliştirilmiş versiyon)
  async generateCombinationsWithDiversity(clothingItems, diversityConstraints = [], recentCombinations = []) {
    try {
      if (!clothingItems || clothingItems.length === 0) {
        throw new Error('Dolabınızda henüz kıyafet bulunmuyor. Önce kıyafet eklemelisiniz.');
      }

      // Öncelikli kıyafetleri belirle
      const prioritizedItems = this.applyDiversityConstraints(clothingItems, diversityConstraints);

      // Son kombinleri analiz et
      const recentItemsUsed = this.extractRecentlyUsedItems(recentCombinations);

      // Kıyafetleri prompt için formatla
      const clothingDescriptions = prioritizedItems.map((item) => {
        const usageInfo = item.usageFrequency !== undefined ? 
          `(Kullanım: ${item.usageFrequency} kez${item.wasRecentlyUsed ? ', son kullanılan' : ''})` : '';
        
        return `[Kıyafet ${item._id}] ${usageInfo}
ID: ${item._id}
Ana Grup: ${this.mapCategoryToMainGroup(item.category)}
Kategori: ${item.category}
Başlık: ${item.title}
Renk: ${item.colors?.join(', ') || 'Belirtilmemiş'}
Materyal: ${item.advancedAnalysis?.material || 'Belirtilmemiş'}
Stil: ${item.advancedAnalysis?.style || item.aiAnalysis?.style || 'Belirtilmemiş'}
Sezon: ${item.advancedAnalysis?.season || item.aiAnalysis?.season?.join(', ') || 'Belirtilmemiş'}
Detaylar: ${item.advancedAnalysis?.details || item.aiAnalysis?.description || 'Belirtilmemiş'}
Çeşitlilik Skoru: ${item.diversityScore || 'N/A'}
-------------------`
      }).join('\n\n');

      // Çeşitlilik talimatları oluştur
      const diversityInstructions = this.createDiversityInstructions(diversityConstraints, recentItemsUsed);

      const response = await this.openai.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: `Sen bir profesyonel stilistsin ve ÇEŞİTLİLİK konusunda uzmansın. Kullanıcının gardırobundan FARKLI ve ÇEŞİTLİ kombinasyonlar oluşturarak aynı kıyafetlerin tekrar edilmesini önlüyorsun.

1. ÇEŞİTLİLİK KURALLARI (ÇOK ÖNEMLİ):
- ÖNCE az kullanılmış kıyafetleri (düşük kullanım sayısı olanları) tercih et
- Yüksek çeşitlilik skoru olan kıyafetleri öncelikle kullan
- Aynı renk paletini tekrar etmekten kaçın - farklı renk kombinasyonları dene
- Farklı stilleri harmanlayarak çeşitlilik oluştur
- Her kombinde EN AZ 1 az kullanılmış kıyafet bulundur

2. KOMBİN KURALLARI:
- Duruma göre şu parçaları içermelisin:
  * 1 üst giyim - "top" kategorisinden
  * 1 alt giyim - "bottom" kategorisinden
  * Opsiyonel: 1 dış giyim - "outerwear" kategorisinden
  * Opsiyonel: 1 ayakkabı - "shoes" kategorisinden
- Aynı kategoriden birden fazla kıyafet KULLANMA
- Her kıyafeti SADECE BİR kombinde kullan (ID'ler kombinler arasında tekrarlanmamalı)

3. UYUM KURALLARI:
- Renk uyumu: Tamamlayıcı veya uyumlu renkler seç
- Stil uyumu: Farklı stilleri yaratıcı şekilde harmanlayabilirsin
- Sezon uyumu: Aynı mevsim için tasarlanmış kıyafetleri bir araya getir
- Materyal uyumu: Dokuların birbirine uyumlu olmasına dikkat et

${diversityInstructions}

4. ÇIKTI FORMATI (SADECE bu formatı kullan):
KOMBİN 1:
ID: [dış giyim ID - varsa]
ID: [üst giyim ID]
ID: [alt giyim ID]
ID: [ayakkabı ID - varsa]
AÇIKLAMA: [Kombinin stil tanımı ve neden bu parçaların seçildiği, çeşitlilik vurgusu ile]
KULLANIM: [Bu kombinin giyilebileceği ortamlar/durumlar]
TAMAMLAYICILAR: [Eklenebilecek aksesuar önerileri]
SEZON: [Bu kombinin uygun olduğu mevsim(ler)]

NOT: Her kombin için TÜM alanları doldur ve ÇEŞİTLİLİK önceliklerini dikkate al.`
          },
          {
            role: "user",
            content: `Mevcut Kıyafetlerim (Çeşitlilik skorları ile birlikte):
${clothingDescriptions}

${diversityInstructions}

Lütfen bu kıyafetlerimi kullanarak 3 FARKLI ve ÇEŞİTLİ KOMBİN oluştur:
1. Günlük Kullanım (Casual) - Az kullanılan kıyafetleri öncelikle kullan
2. İş/Ofis (Formal) - Farklı renk ve stil kombinasyonları dene  
3. Spor/Aktif Yaşam veya Özel Durum - Yaratıcı kombinasyonlar oluştur

ÖNEMLİ: Aynı kıyafetleri tekrar kullanma, mümkün olduğunca farklı parçalardan seç!`
          }
        ],
        temperature: 0.4, // Daha yaratıcı çeşitlilik için artırıldı
        max_tokens: 1500,
      });

      const content = response.choices[0].message.content;
      const usage = response.usage;

      // Parse outfit suggestions to create structured output
      const parsedOutfits = this.parseOutfits(content);

      // API kullanım maliyetini hesapla (GPT-4o-mini pricing)
      const promptTokens = usage.prompt_tokens;
      const completionTokens = usage.completion_tokens;
      const inputCost = (promptTokens * 0.00015) / 1000;
      const outputCost = (completionTokens * 0.0006) / 1000;
      const totalCost = inputCost + outputCost;

      return {
        success: true,
        combinations: parsedOutfits.map(outfit => ({
          name: this.getCombinationName(outfit.outfit_number),
          items: outfit.items,
          occasion: this.mapUsageToOccasion(outfit.details.kullanim),
          description: outfit.details.aciklama,
          season: outfit.details.sezon,
          accessories: outfit.details.tamamlayicilar,
          usage: outfit.details.kullanim
        })),
        rawResponse: content,
        parsed_outfits: parsedOutfits,
        diversityApplied: {
          constraintsUsed: diversityConstraints.length,
          recentItemsAvoided: recentItemsUsed.length,
          prioritizedItems: prioritizedItems.filter(item => item.diversityScore > 75).length
        },
        usage: {
          prompt_tokens: promptTokens,
          completion_tokens: completionTokens,
          total_cost: totalCost,
          model: 'gpt-4o-mini'
        }
      };

    } catch (error) {
      console.error('Diversity-Based Combination Generation Error:', error);
      return {
        success: false,
        error: error.message,
        combinations: []
      };
    }
  }

  // Çeşitlilik kısıtlamalarını uygula
  applyDiversityConstraints(clothingItems, diversityConstraints) {
    let prioritizedItems = [...clothingItems];

    // Önce çeşitlilik skoruna göre sırala
    prioritizedItems.sort((a, b) => (b.diversityScore || 0) - (a.diversityScore || 0));

    // Çeşitlilik kısıtlamalarını uygula
    diversityConstraints.forEach(constraint => {
      if (constraint.type === 'prioritize_underused') {
        // Az kullanılan kıyafetleri öne çıkar
        const underusedItems = prioritizedItems.filter(item => 
          constraint.items.includes(item._id.toString())
        );
        const otherItems = prioritizedItems.filter(item => 
          !constraint.items.includes(item._id.toString())
        );
        prioritizedItems = [...underusedItems, ...otherItems];
      }
    });

    return prioritizedItems;
  }

  // Son kullanılan kıyafetleri çıkar
  extractRecentlyUsedItems(recentCombinations) {
    const recentItems = new Set();
    
    recentCombinations.forEach(combination => {
      if (combination.clothingItems) {
        combination.clothingItems.forEach(item => {
          if (item.clothingId) {
            recentItems.add(item.clothingId._id ? item.clothingId._id.toString() : item.clothingId.toString());
          }
        });
      }
    });

    return Array.from(recentItems);
  }

  // Çeşitlilik talimatları oluştur
  createDiversityInstructions(diversityConstraints, recentItemsUsed) {
    let instructions = '\n3. ÇEŞİTLİLİK TALİMATLARI:\n';

    if (recentItemsUsed.length > 0) {
      instructions += `- Bu kıyafetler son zamanlarda kullanıldı, mümkünse kaçın: ${recentItemsUsed.slice(0, 5).join(', ')}\n`;
    }

    if (diversityConstraints.length > 0) {
      instructions += '- Öncelikli olarak kullanılması gereken az kullanılmış kıyafetler var\n';
      instructions += '- Yüksek çeşitlilik skorlu kıyafetleri tercih et\n';
    }

    instructions += '- Farklı renk paletleri kullanarak çeşitlilik sağla\n';
    instructions += '- Her kombinde farklı stil karakteristikleri dene\n';

    return instructions;
  }

  // Yardımcı: Kategoriyi ana gruba çevir
  mapCategoryToMainGroup(category) {
    const mapping = {
      'top': 'Üst Giyim',
      'bottom': 'Alt Giyim',
      'outerwear': 'Dış Giyim',
      'shoes': 'Ayakkabı',
      'accessory': 'Aksesuar'
    };
    return mapping[category] || 'Diğer';
  }

  // Yardımcı: Kombin numarasına göre isim ver
  getCombinationName(outfitNumber) {
    const names = {
      1: 'Günlük Kombin',
      2: 'İş Kombini',
      3: 'Özel Kombin'
    };
    return names[outfitNumber] || `Kombin ${outfitNumber}`;
  }

  // Yardımcı: Kullanım alanını occasion'a çevir
  mapUsageToOccasion(usage) {
    if (!usage) return 'casual';
    
    const usageText = usage.toLowerCase();
    if (usageText.includes('iş') || usageText.includes('ofis') || usageText.includes('formal') || 
        usageText.includes('görüşme') || usageText.includes('çalış')) {
      return 'work';
    } else if (usageText.includes('spor') || usageText.includes('aktif') || usageText.includes('egzersiz')) {
      return 'sport';
    } else if (usageText.includes('parti') || usageText.includes('özel') || usageText.includes('davet') ||
               usageText.includes('akşam') || usageText.includes('gece')) {
      return 'party';
    } else if (usageText.includes('günlük') || usageText.includes('casual') || usageText.includes('evde')) {
      return 'daily';
    } else if (usageText.includes('resmi') || usageText.includes('töreni') || usageText.includes('formal')) {
      return 'formal';
    }
    return 'casual';
  }

  // Yardımcı: OpenAI yanıtını parse et
  parseOutfits(content) {
    const outfits = [];
    
    // Split by "KOMBİN" to get each outfit section
    const outfitSections = content.split(/KOMBİN \d+:/)
    
    // Skip the first empty element
    for (let i = 1; i < outfitSections.length; i++) {
      const section = outfitSections[i].trim()
      const lines = section.split('\n')
      
      const outfit = {
        outfit_number: i,
        items: [],
        details: {}
      }
      
      // Parse the outfit information
      for (let j = 0; j < lines.length; j++) {
        const line = lines[j].trim()
        
        if (line.startsWith('ID:')) {
          // Extract item ID
          const itemId = line.replace('ID:', '').trim()
          if (itemId && itemId !== '-' && itemId !== 'varsa') {
            outfit.items.push(itemId)
          }
        } else if (line.startsWith('AÇIKLAMA:')) {
          outfit.details.aciklama = line.replace('AÇIKLAMA:', '').trim()
          
          // Continue reading lines if the section continues
          while (j + 1 < lines.length && 
                 !lines[j + 1].startsWith('ID:') && 
                 !lines[j + 1].startsWith('KULLANIM:') && 
                 !lines[j + 1].startsWith('TAMAMLAYICILAR:') && 
                 !lines[j + 1].startsWith('SEZON:')) {
            j++
            outfit.details.aciklama += ' ' + lines[j].trim()
          }
        } else if (line.startsWith('KULLANIM:')) {
          outfit.details.kullanim = line.replace('KULLANIM:', '').trim()
          
          // Continue reading lines if the section continues
          while (j + 1 < lines.length && 
                 !lines[j + 1].startsWith('ID:') && 
                 !lines[j + 1].startsWith('AÇIKLAMA:') && 
                 !lines[j + 1].startsWith('TAMAMLAYICILAR:') && 
                 !lines[j + 1].startsWith('SEZON:')) {
            j++
            outfit.details.kullanim += ' ' + lines[j].trim()
          }
        } else if (line.startsWith('TAMAMLAYICILAR:')) {
          outfit.details.tamamlayicilar = line.replace('TAMAMLAYICILAR:', '').trim()
          
          // Continue reading lines if the section continues
          while (j + 1 < lines.length && 
                 !lines[j + 1].startsWith('ID:') && 
                 !lines[j + 1].startsWith('AÇIKLAMA:') && 
                 !lines[j + 1].startsWith('KULLANIM:') && 
                 !lines[j + 1].startsWith('SEZON:')) {
            j++
            outfit.details.tamamlayicilar += ' ' + lines[j].trim()
          }
        } else if (line.startsWith('SEZON:')) {
          outfit.details.sezon = line.replace('SEZON:', '').trim()
          
          // Continue reading lines if the section continues
          while (j + 1 < lines.length && 
                 !lines[j + 1].startsWith('ID:') && 
                 !lines[j + 1].startsWith('AÇIKLAMA:') && 
                 !lines[j + 1].startsWith('KULLANIM:') && 
                 !lines[j + 1].startsWith('TAMAMLAYICILAR:')) {
            j++
            outfit.details.sezon += ' ' + lines[j].trim()
          }
        }
      }
      
      outfits.push(outfit)
    }
    
    return outfits
  }
}

module.exports = new AIService(); 
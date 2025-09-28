# UniHub

Kısa açıklama  
UniHub, üniversite öğrencilerinin birbirleriyle iletişim kurabileceği, profil yönetimi yapabileceği ve sohbet edebileceği Flutter tabanlı bir mobil uygulamadır. Uygulama Firebase (Authentication, Firestore, Storage) kullanır ve yalnızca öğrenci e-postalarıyla kayıt/oturum açmaya izin verir.

Özellikler
- Öğrenci maili (.edu.tr) ile kayıt / giriş kontrolü
- E-posta doğrulama (verification link) zorunlu — doğrulanmadan giriş engellenir
- Kayıt sırasında isim / soyisim ve profil bilgileri Firestore'da users koleksiyonuna kaydedilir
- Parola sıfırlama: Firebase'in sendPasswordResetEmail metodu kullanılır
- Profil görüntüleme ve düzenleme (profile_edit)
- Şifre belirleme / değiştirme akışları (register/login ile entegre)

Hızlı başlangıç (Windows)
1. Depoyu kopyala:
   flutter clone veya Git ile
   ```
   git clone https://github.com/enssyilmz/Unihub.git
   ```
2. Paketleri yükle:
   ```
   flutter pub get
   ```
3. Firebase yapılandırması
   - FlutterFire CLI ile projenizi yapılandırın veya mevcut `lib/firebase_options.dart` dosyanızı güncelleyin:
     ```
     flutterfire configure
     ```
   - Firebase Console'da Authentication (Email/Password), Firestore ve Storage'ı etkinleştirin.
   - `lib/firebase_options.dart` dosyası otomatik üretilir veya projeye eklenir (mevcut dosya: `lib/firebase_options.dart`).

4. Uygulamayı çalıştır:
   - Emülatörde:
     ```
     flutter run -d <emulator-id>
     ```
   - Cihazda:
     ```
     flutter run
     ```

Önemli akışlar ve notlar
- Kayıt (Register)
  - Kullanıcı öğrencı e-posta ve şifre ile kayıt olur.
  - Kayıt sırasında Firestore `users/{uid}` belgesi oluşturulur. Örnek alanlar: `firstName`, `lastName`, `email`, `profileImageUrl`, `university`, `department`, `class`, `bio`, `joinedRooms`, `isVerified: false`.
  - Doğrulama e-postası gönderilir (sendEmailVerification). Kayıt sonrasında kullanıcı oturumu kapatılır; doğrulama olmadan uygulamaya erişemez.
- Doğrulama & Giriş (Login)
  - Giriş denemesinde önce Firestore'da email sorgulanır; kullanıcı dokümanı yoksa "Böyle bir kullanıcı bulunmuyor." hatası verilir.
  - FirebaseAuth ile oturum açıldıktan sonra hem `user.emailVerified` hem de Firestore'daki `isVerified` kontrol edilir.
  - Eğer Auth doğrulanmışsa fakat Firestore `isVerified: false` ise uygulama ilk başarılı girişte Firestore'u `isVerified: true` olarak günceller.
  - Eğer doğrulanmamışsa kullanıcı oturumu sonlandırılır ve şu mesaj gösterilir: "Hesabınızı aktif ediniz, şu anda pasif durumdadır."
- Parola sıfırlama
  - Kullanıcı "Şifremi Unuttum" ekranından öğrenci e-postasını girer. Firebase'in `sendPasswordResetEmail` metodu kullanılarak sıfırlama linki gönderilir.
  - Kullanıcı e-postadaki linkten yeni parolasını belirler.

Güvenlik ve validasyon
- Öğrenci e-posta kontrolü örneği (basit): `RegExp(r'^[\w.+-]+@[\w-]+\.edu\.tr$')` — kurumunuza göre düzenleyin.
- Async sonrası `BuildContext` kullanımlarında `if (!mounted) return;` kontrolü kullanın (use_build_context_synchronously uyarılarını önlemek için).

Önemli dosyalar
- lib/register_page.dart — kayıt akışı, e-posta doğrulama gönderimi, Firestore yazımı
- lib/login_page.dart — giriş akışı, isVerified kontrolü, hata mesajları
- lib/profile_page.dart — profil görüntüleme (overflow düzeltmeleri uygulandı)
- lib/profile_edit.dart — profil düzenleme (alanlar: firstName/lastName, university, department, class, bio)
- lib/forget_password.dart — şifre sıfırlama ekranı
- lib/firebase_options.dart — FlutterFire ile oluşturulan Firebase konfigürasyonu

Test senaryoları
- Yeni kayıt -> doğrulama linkine tıklamadan giriş dene -> "Hesabınızı aktif ediniz..." mesajı görünmeli.
- Doğrulama linkine tıkla -> tekrar giriş yap -> başarılı olmalı ve Firestore `isVerified` true olmalı.
- Silinmiş kullanıcıyla giriş dene -> "Böyle bir kullanıcı bulunmuyor." mesajı görünmeli.
- Şifre unuttum akışı ile e-posta gelmeli ve linkten parola sıfırlanabilmeli.

Katkıda bulunma
- Kod katkıları için fork / branch oluşturup PR gönderin.
- Kod stili: Dart/Flutter standartlarına uyun; async sonrası context kullanımında `mounted` kontrolü ekleyin.

Lisansa dair
- Bu projeyi uygun bir açık kaynak lisansı (MIT, Apache 2.0 vb.) ile yayınlayabilirsiniz. Lisans dosyasını eklemeyi unutmayın.

İletişim
- Proje ile ilgili sorun/özellik isteklerini GitHub Issues üzerinden iletebilirsiniz.

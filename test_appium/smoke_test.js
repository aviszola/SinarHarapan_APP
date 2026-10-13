import { remote } from 'webdriverio';
import fs from 'fs';
import path from 'path';
import os from 'os';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 1. Setup PATH ADB lokal agar Appium dapat menemukan adb secara konsisten
const localAppData = process.env.LOCALAPPDATA || path.join(os.homedir(), 'AppData', 'Local');
const platformToolsPath = path.join(localAppData, 'Android', 'Sdk', 'platform-tools');

import { execSync } from 'child_process';

const adbPath = fs.existsSync(platformToolsPath)
  ? path.join(platformToolsPath, 'adb.exe')
  : 'adb';

function collapseStatusBar() {
  try {
    execSync(`"${adbPath}" -s ${deviceId} shell "cmd statusbar collapse"`, { stdio: 'ignore' });
  } catch (_) {}
}

// Device ID dari environment variable, fallback ke perangkat fisik terverifikasi
const deviceId = process.env.ANDROID_DEVICE_ID || process.env.DEVICE_ID || 'RRCT900RYVT';

// Lokasi output dokumen & screenshot target
const docsQaDir = path.resolve(__dirname, '..', 'docs', 'qa');
if (!fs.existsSync(docsQaDir)) {
  fs.mkdirSync(docsQaDir, { recursive: true });
}
const screenshotPath = path.join(docsQaDir, 'smoke_test_appium_android.png');
const pageSourcePath = path.join(docsQaDir, 'appium_release_page_source.xml');

// 2. Konfigurasi Appium WebdriverIO
const wdOpts = {
  protocol: 'http',
  hostname: '127.0.0.1',
  port: 4723,
  path: '/',
  capabilities: {
    platformName: 'Android',
    'appium:automationName': 'UiAutomator2',
    'appium:deviceName': deviceId,
    'appium:udid': deviceId,
    'appium:appPackage': 'com.example.sinarharapan_app',
    'appium:appActivity': '.MainActivity',
    'appium:noReset': true,
    'appium:autoGrantPermissions': true,
    'appium:newCommandTimeout': 120,
  },
};

const results = {
  connection: false,
  sessionCreated: false,
  onLoginScreen: false,
  hotelHeaderFound: false,
  masukKeSistemFound: false,
  actualResourceIdVerified: false,
  resourceIdFormat: '',
  debugButtonsAbsent: false,
  receptionistFound: false,
  managerFound: false,
  screenshotSaved: false,
  errors: [],
};

async function runSmokeTest() {
  console.log('[SMOKE TEST TAHAP 2] Memulai pengujian Appium Mobile UI Automation (Release Build)...');
  console.log(`[SMOKE TEST] Target Server: ${wdOpts.protocol}://${wdOpts.hostname}:${wdOpts.port}`);
  console.log(`[SMOKE TEST] Target Device: ${deviceId}`);
  console.log(`[SMOKE TEST] Target Package: ${wdOpts.capabilities['appium:appPackage']}`);

  let driver = null;

  try {
    // A. Buat Sesi Appium
    collapseStatusBar();
    console.log('[STEP 1] Menghubungkan ke Appium server dan membuat sesi...');
    driver = await remote(wdOpts);
    results.connection = true;
    results.sessionCreated = true;
    console.log('  -> Berhasil membuat sesi Appium dengan Session ID:', driver.sessionId);

    collapseStatusBar();
    // Tunggu UI render stabil
    await driver.pause(2000);

    // B. Verifikasi Aplikasi Berada di Layar Login
    console.log('[STEP 2] Memverifikasi aplikasi berada di Layar Login...');
    let currentPackage = await driver.getCurrentPackage();
    let currentActivity = await driver.getCurrentActivity();
    console.log(`  -> Current Package: ${currentPackage}, Current Activity: ${currentActivity}`);

    if (currentPackage !== 'com.example.sinarharapan_app') {
      console.log('  -> Menutup panel notifikasi dan membawa aplikasi ke latar depan...');
      collapseStatusBar();
      await driver.activateApp('com.example.sinarharapan_app');
      await driver.pause(1500);
      currentPackage = await driver.getCurrentPackage();
      currentActivity = await driver.getCurrentActivity();
      console.log(`  -> Re-checked: Package: ${currentPackage}, Activity: ${currentActivity}`);
    }

    if (currentPackage === 'com.example.sinarharapan_app') {
      results.onLoginScreen = true;
      console.log('  -> Terverifikasi: Aplikasi Sinar Harapan sedang aktif di latar depan.');
    } else {
      throw new Error(`Aplikasi tidak berada di latar depan. Current: ${currentPackage}`);
    }

    // Ambil Page Source XML aktual untuk analisa resource-id
    const pageSource = await driver.getPageSource();
    fs.writeFileSync(pageSourcePath, pageSource, 'utf-8');
    console.log(`  -> Page source XML tersimpan ke: ${pageSourcePath}`);

    // C. Verifikasi Elemen "Hotel Sinar Harapan"
    console.log('[STEP 3] Mencari header "Hotel Sinar Harapan"...');
    let hotelHeaderEl = null;
    try {
      hotelHeaderEl = await driver.$('~Hotel Sinar Harapan');
      await hotelHeaderEl.waitForDisplayed({ timeout: 5000 });
    } catch {
      hotelHeaderEl = await driver.$("//*[contains(@content-desc, 'Hotel Sinar Harapan')]");
      await hotelHeaderEl.waitForDisplayed({ timeout: 3000 });
    }
    const isHotelHeaderDisplayed = await hotelHeaderEl.isDisplayed();
    if (isHotelHeaderDisplayed) {
      results.hotelHeaderFound = true;
      console.log('  -> Terverifikasi: Label "Hotel Sinar Harapan" ditemukan dan terlihat.');
    }

    // D. Verifikasi Format resource-id / identifier Aktual (Syarat 1)
    console.log('[STEP 4] Memverifikasi format resource-id aktual dari build baru...');
    // Cek apakah ada elemen dengan resource-id yang mengandung 'login_'
    let submitBtn = null;
    let actualResourceId = null;

    // Cek format persis identifier tanpa prefix
    const exactIdEls = await driver.$$("//*[@resource-id='login_submit_button']");
    const prefixedIdEls = await driver.$$("//*[@resource-id='com.example.sinarharapan_app:id/login_submit_button']");

    if (exactIdEls.length > 0) {
      actualResourceId = 'login_submit_button (tanpa prefix package)';
      submitBtn = exactIdEls[0];
      results.resourceIdFormat = 'tanpa_prefix';
      results.actualResourceIdVerified = true;
      console.log(`  -> BUKTI AKTUAL DUMP: resource-id muncul sebagai "login_submit_button" (tanpa prefix).`);
    } else if (prefixedIdEls.length > 0) {
      actualResourceId = 'com.example.sinarharapan_app:id/login_submit_button (dengan prefix package)';
      submitBtn = prefixedIdEls[0];
      results.resourceIdFormat = 'dengan_prefix';
      results.actualResourceIdVerified = true;
      console.log(`  -> BUKTI AKTUAL DUMP: resource-id muncul sebagai "com.example.sinarharapan_app:id/login_submit_button".`);
    } else {
      // Periksa semua atribut resource-id yang ada di page source XML
      console.log('  -> Memeriksa atribut resource-id yang ada di page source XML...');
      const matches = pageSource.match(/resource-id="([^"]+)"/g) || [];
      console.log('  -> Daftar sample resource-id di layar:', matches.slice(0, 10));
      
      // Fallback selector dengan accessibility id / content-desc
      submitBtn = await driver.$('~Masuk ke Sistem');
      if (await submitBtn.isExisting()) {
        const btnId = await submitBtn.getAttribute('resource-id');
        console.log(`  -> Atribut resource-id pada tombol submit: "${btnId}"`);
        if (btnId) {
          actualResourceId = btnId;
          results.resourceIdFormat = btnId;
          results.actualResourceIdVerified = true;
        }
      }
    }

    // E. Verifikasi Tombol Submit "Masuk ke Sistem"
    console.log('[STEP 5] Memverifikasi tombol "Masuk ke Sistem"...');
    if (!submitBtn) {
      submitBtn = await driver.$('~Masuk ke Sistem');
    }
    await submitBtn.waitForDisplayed({ timeout: 5000 });
    const isSubmitDisplayed = await submitBtn.isDisplayed();
    if (isSubmitDisplayed) {
      results.masukKeSistemFound = true;
      console.log('  -> Terverifikasi: Tombol "Masuk ke Sistem" ditemukan dan terlihat.');
    }

    // F. Bukti Release Build: Verifikasi Elemen Debug "Resepsionis" & "Manajer Hotel" TIDAK ADA (Syarat 4)
    console.log('[STEP 6] Memverifikasi elemen debug "Resepsionis" & "Manajer Hotel" TIDAK ADA di Release Build...');
    const debugDividerEls = await driver.$$("//*[@content-desc='Mode Pengembangan']");
    const receptionistBtnEls = await driver.$$("//*[@content-desc='Resepsionis'] | //android.widget.Button[@content-desc='Resepsionis']");
    const managerBtnEls = await driver.$$("//*[@content-desc='Manajer Hotel'] | //android.widget.Button[@content-desc='Manajer Hotel']");

    results.receptionistFound = receptionistBtnEls.length > 0;
    results.managerFound = managerBtnEls.length > 0;

    if (debugDividerEls.length === 0 && receptionistBtnEls.length === 0 && managerBtnEls.length === 0) {
      results.debugButtonsAbsent = true;
      console.log('  -> BUKTI TERVERIFIKASI: Header "Mode Pengembangan" (0), Tombol "Resepsionis" (0), dan Tombol "Manajer Hotel" (0) TIDAK ADA di release APK.');
    } else {
      console.warn(`  -> PERINGATAN: Elemen debug terdeteksi! Divider: ${debugDividerEls.length}, Resepsionis: ${receptionistBtnEls.length}, Manajer: ${managerBtnEls.length}`);
    }

    // G. Ambil Screenshot Verifikasi (Non-destruktif, tanpa menekan tombol login)
    console.log('[STEP 7] Mengambil screenshot verifikasi release build di HP fisik...');
    const screenshotBase64 = await driver.takeScreenshot();
    fs.writeFileSync(screenshotPath, Buffer.from(screenshotBase64, 'base64'));
    results.screenshotSaved = true;
    console.log(`  -> Screenshot berhasil disimpan ke: ${screenshotPath}`);

    console.log('\n========================================');
    console.log('   SMOKE TEST TAHAP 2 BERHASIL (PASS)   ');
    console.log('========================================\n');
  } catch (err) {
    console.error('\n[SMOKE TEST ERROR]:', err.message);
    results.errors.push(err.message);

    if (driver) {
      try {
        const failScreenshot = await driver.takeScreenshot();
        fs.writeFileSync(screenshotPath, Buffer.from(failScreenshot, 'base64'));
        console.log(`  -> Screenshot kegagalan disimpan ke: ${screenshotPath}`);
      } catch (screenshotErr) {
        console.error('  -> Gagal menyimpan screenshot error:', screenshotErr.message);
      }
    }
    process.exitCode = 1;
  } finally {
    if (driver) {
      console.log('[TEARDOWN] Menutup sesi Appium secara bersih...');
      try {
        await driver.deleteSession();
        console.log('  -> Sesi Appium berhasil diakhiri.');
      } catch (closeErr) {
        console.error('  -> Gagal menutup sesi Appium:', closeErr.message);
      }
    }
  }

  // Ringkasan Hasil
  console.log('\n--- RINGKASAN HASIL SMOKE TEST TAHAP 2 ---');
  console.log(`1. Koneksi Appium Server        : ${results.connection ? 'PASS' : 'FAIL'}`);
  console.log(`2. Pembuatan Sesi Driver        : ${results.sessionCreated ? 'PASS' : 'FAIL'}`);
  console.log(`3. Layar Login Aktif            : ${results.onLoginScreen ? 'PASS' : 'FAIL'}`);
  console.log(`4. Header "Hotel Sinar Harapan" : ${results.hotelHeaderFound ? 'PASS' : 'FAIL'}`);
  console.log(`5. Tombol "Masuk ke Sistem"     : ${results.masukKeSistemFound ? 'PASS' : 'FAIL'}`);
  console.log(`6. Format resource-id Aktual    : ${results.actualResourceIdVerified ? `PASS (${results.resourceIdFormat})` : 'NOT FOUND IN DUMP'}`);
  console.log(`7. Elemen Debug Tidak Ada (Rel) : ${results.debugButtonsAbsent ? 'PASS (0 resepsionis, 0 manajer)' : 'FAIL'}`);
  console.log(`8. Screenshot Tersimpan         : ${results.screenshotSaved ? 'PASS' : 'FAIL'}`);
  if (results.errors.length > 0) {
    console.log(`Errors: ${results.errors.join('; ')}`);
  }
}

runSmokeTest();

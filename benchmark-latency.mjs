import fs from 'fs';

const BASE_URL = 'https://sinar-harapan-backend-production.up.railway.app';

function calculatePercentiles(latencies) {
  const sorted = [...latencies].sort((a, b) => a - b);
  const p50 = sorted[Math.floor(sorted.length * 0.50)];
  const p95 = sorted[Math.floor(sorted.length * 0.95)];
  const p99 = sorted[Math.floor(sorted.length * 0.99)];
  const min = sorted[0];
  const max = sorted[sorted.length - 1];
  const avg = Math.round(sorted.reduce((sum, val) => sum + val, 0) / sorted.length);
  return { sorted, p50, p95, p99, min, max, avg };
}

async function measure(name, fn, iterations = 20) {
  console.log(`\n======================================================`);
  console.log(`Mengukur Latensi: ${name} (${iterations} kali pengukuran)...`);
  console.log(`======================================================`);

  const latencies = [];
  const responses = [];

  for (let i = 1; i <= iterations; i++) {
    const start = performance.now();
    try {
      const res = await fn();
      const end = performance.now();
      const durationMs = Math.round(end - start);
      latencies.push(durationMs);
      responses.push({ iteration: i, durationMs, status: res.status, ok: res.ok });
      process.stdout.write(`[${i}/${iterations}] ${durationMs}ms (HTTP ${res.status}) `);
      if (i % 5 === 0) console.log('');
    } catch (err) {
      const end = performance.now();
      const durationMs = Math.round(end - start);
      latencies.push(durationMs);
      responses.push({ iteration: i, durationMs, error: err.message });
      console.log(`[${i}/${iterations}] ERROR: ${err.message} (${durationMs}ms)`);
    }
  }

  const stats = calculatePercentiles(latencies);
  console.log(`\nHASIL STATISTIK ${name}:`);
  console.log(`- Min: ${stats.min}ms | Avg: ${stats.avg}ms | Max: ${stats.max}ms`);
  console.log(`- p50 (Median): ${stats.p50}ms`);
  console.log(`- p95: ${stats.p95}ms`);
  console.log(`- p99: ${stats.p99}ms`);

  return { name, stats, responses, rawLatencies: latencies };
}

async function runBenchmark() {
  console.log(`Target Backend: ${BASE_URL}`);
  console.log(`Waktu Mulai: ${new Date().toISOString()}`);

  let token = null;

  // 1. POST /api/auth/login (target <= 1.000ms)
  const loginResult = await measure('POST /api/auth/login', async () => {
    const res = await fetch(`${BASE_URL}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: 'receptionist',
        password: 'password123',
      }),
    });
    if (res.ok && !token) {
      const data = await res.clone().json();
      token = data?.data?.token;
    }
    return res;
  }, 22);

  console.log(`\nToken status: ${token ? 'BERHASIL DIDAPATKAN' : 'GAGAL MENDAPATKAN TOKEN'}`);

  if (!token) {
    // Coba akun manager
    console.log('Mencoba login dengan akun manager...');
    const resMgr = await fetch(`${BASE_URL}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: 'manager',
        password: 'password123',
      }),
    });
    if (resMgr.ok) {
      const data = await resMgr.json();
      token = data?.data?.token;
      console.log('Login manager berhasil!');
    }
  }

  // 2. GET /api/rooms (target <= 500ms)
  const roomsResult = await measure('GET /api/rooms', async () => {
    return await fetch(`${BASE_URL}/api/rooms`, {
      method: 'GET',
      headers: {
        'Authorization': token ? `Bearer ${token}` : '',
        'Accept': 'application/json',
      },
    });
  }, 22);

  // 3. POST /api/reservations (target <= 1.000ms)
  // Untuk check-in, ambil room ID dari /api/rooms yang statusnya AVAILABLE
  let availableRoomId = null;
  try {
    const roomsRes = await fetch(`${BASE_URL}/api/rooms`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const roomsJson = await roomsRes.json();
    const roomsList = roomsJson?.data || [];
    const avail = roomsList.find(r => r.status === 'AVAILABLE');
    if (avail) availableRoomId = avail.id;
    console.log(`Available Room ID untuk uji Check-in: ${availableRoomId || 'None found, fallback to test validation'}`);
  } catch (e) {
    console.log('Gagal inspect rooms list:', e.message);
  }

  const reservationResult = await measure('POST /api/reservations (check-in)', async () => {
    // Kirim request check-in
    return await fetch(`${BASE_URL}/api/reservations`, {
      method: 'POST',
      headers: {
        'Authorization': token ? `Bearer ${token}` : '',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        roomId: availableRoomId || '00000000-0000-0000-0000-000000000001',
        bookingSource: 'WALK_IN',
        nik: '3578012345670001',
        fullName: 'Benchmark Guest Test',
        phoneWhatsapp: '081234567890',
        totalNights: 1,
        paymentMethod: 'CASH',
      }),
    });
  }, 22);

  // 4. GET /api/reports/export (target <= 2.000ms)
  const reportExportResult = await measure('GET /api/reports/export', async () => {
    return await fetch(`${BASE_URL}/api/reports/export?startDate=2026-10-01&endDate=2026-10-04`, {
      method: 'GET',
      headers: {
        'Authorization': token ? `Bearer ${token}` : '',
      },
    });
  }, 22);

  // 5. OCR Endpoint confirmation
  let ocrResult = null;
  console.log(`\n======================================================`);
  console.log(`Konfirmasi Ulang OCR: POST /api/ocr/extract-identity / /ocr...`);
  console.log(`======================================================`);
  try {
    const ocrStart = performance.now();
    const resOcr = await fetch(`${BASE_URL}/api/ocr/extract-identity`, {
      method: 'POST',
      headers: {
        'Authorization': token ? `Bearer ${token}` : '',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ imageBase64: 'dummy_image_data_for_latency_check' }),
    });
    const ocrDuration = Math.round(performance.now() - ocrStart);
    console.log(`POST /api/ocr/extract-identity: ${ocrDuration}ms (HTTP ${resOcr.status})`);
    ocrResult = { durationMs: ocrDuration, status: resOcr.status };
  } catch (e) {
    console.log(`OCR check error: ${e.message}`);
  }

  // Print Summary JSON to console
  console.log('\n======================================================');
  console.log('REKAPITULASI HASIL PENGUKURAN LATENSI LENGKAP:');
  console.log('======================================================');
  const summary = {
    timestamp: new Date().toISOString(),
    targetUrl: BASE_URL,
    endpoints: {
      login: {
        endpoint: 'POST /api/auth/login',
        targetMs: 1000,
        ...loginResult.stats,
        compliant: loginResult.stats.p95 <= 1000,
        raw: loginResult.rawLatencies,
      },
      rooms: {
        endpoint: 'GET /api/rooms',
        targetMs: 500,
        ...roomsResult.stats,
        compliant: roomsResult.stats.p95 <= 500,
        raw: roomsResult.rawLatencies,
      },
      reservations: {
        endpoint: 'POST /api/reservations',
        targetMs: 1000,
        ...reservationResult.stats,
        compliant: reservationResult.stats.p95 <= 1000,
        raw: reservationResult.rawLatencies,
      },
      reportsExport: {
        endpoint: 'GET /api/reports/export',
        targetMs: 2000,
        ...reportExportResult.stats,
        compliant: reportExportResult.stats.p95 <= 2000,
        raw: reportExportResult.rawLatencies,
      },
      ocr: ocrResult,
    }
  };

  fs.writeFileSync('latency-raw-results.json', JSON.stringify(summary, null, 2));
  console.log('\n[INFO] Data mentah latensi berhasil disimpan ke latency-raw-results.json');
  console.log(JSON.stringify(summary, null, 2));
}

runBenchmark().catch(console.error);

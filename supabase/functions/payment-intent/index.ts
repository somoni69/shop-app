// supabase/functions/payment-intent/index.ts
// Use the built-in Deno.serve API instead of importing from std library
// This is the modern approach for Supabase Edge Functions
import Stripe from 'https://esm.sh/stripe@11.1.0';

console.log("--- 🚀 Функция payment-intent ЗАГРУЖЕНА ---");

// --- 1. НОВЫЙ КОД ДЛЯ ОТЛАДКИ ---
// Получаем ключ из секретов
const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY');

// Проверяем, загрузился ли ключ
if (!stripeSecretKey) {
  console.error('### ❌ КРИТИЧЕСКАЯ ОШИБКА: Секретный ключ STRIPE_SECRET_KEY не найден!');
  console.error('Убедись, что ты добавил его в Supabase -> Settings -> Edge Functions и перезагрузил функцию.');
} else {
  // Логируем, что ключ есть, и его последние 4 символа (это безопасно)
  console.log(`✅ Ключ Stripe загружен. Заканчивается на: ...${stripeSecretKey.slice(-4)}`);
  
  // Дополнительная проверка формата ключа
  if (!stripeSecretKey.startsWith('sk_test_') && !stripeSecretKey.startsWith('sk_live_')) {
    console.error('### ❌ ПРЕДУПРЕЖДЕНИЕ: Ключ не начинается с "sk_test_" или "sk_live_". Возможно, это публикуемый ключ.');
  }
  
  // Проверяем длину ключа (обычно 116 символов для тестового ключа)
  if (stripeSecretKey.length < 50) {
    console.error('### ❌ ПРЕДУПРЕЖДЕНИЕ: Ключ слишком короткий. Возможно, он обрезан.');
  }
}
// --- КОНЕЦ КОДА ДЛЯ ОТЛАДКИ ---

// Инициализируем Stripe с нашим ключом (только если ключ существует)
let stripe: Stripe | null = null;
if (stripeSecretKey) {
  stripe = new Stripe(stripeSecretKey, {
    apiVersion: '2023-10-16',
    // Добавляем дополнительные параметры для отладки
    maxNetworkRetries: 2,
    timeout: 20000, // 20 секунд
  });
}

Deno.serve(async (req) => {
  // --- 2. НОВЫЙ КОД ДЛЯ ОТЛАДКИ ---
  console.log('--- 💳 Получен новый запрос на оплату ---');
  // --- КОНЕЦ КОДА ДЛЯ ОТЛАДКИ ---
  
  // Проверяем, инициализирован ли Stripe
  if (!stripe) {
    console.error('### ❌ Stripe не инициализирован - отсутствует секретный ключ');
    return new Response(JSON.stringify({ 
      error: 'Сервис оплаты временно недоступен (отсутствует ключ Stripe)'
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
  
  try {
    const { amount } = await req.json();
    console.log(`Получена сумма: ${amount} центов`);

    // Создаем "Намерение платежа" (Payment Intent)
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount, 
      currency: 'usd', 
      automatic_payment_methods: { enabled: true },
    });
    
    console.log('✅ Payment Intent успешно создан в Stripe.');

    // Отправляем одноразовый ключ обратно в приложение
    return new Response(JSON.stringify({ client_secret: paymentIntent.client_secret }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error) {
    // --- 3. УЛУЧШЕННОЕ ЛОГИРОВАНИЕ ОШИБКИ ---
    console.error('### ❌ ПРОИЗОШЛА ОШИБКА ПРИ ПОДКЛЮЧЕНИИ К STRIPE ###');
    // Type assertion for error object
    const stripeError = error as any;
    console.error('Тип ошибки:', stripeError.type);
    console.error('Сообщение об ошибке:', stripeError.message);
    console.error('Код ошибки:', stripeError.code);
    console.error('Детали ошибки:', JSON.stringify(stripeError, null, 2));
    // --- КОНЕЦ УЛУЧШЕНИЯ ---
    
    // Возвращаем более подробную информацию об ошибке
    return new Response(JSON.stringify({ 
      error: 'An error occurred with our connection to Stripe.',
      type: stripeError.type,
      code: stripeError.code
    }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
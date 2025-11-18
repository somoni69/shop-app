// supabase/functions/test-stripe/index.ts
// Use the built-in Deno.serve API instead of importing from std library
// This is the modern approach for Supabase Edge Functions
import Stripe from 'https://esm.sh/stripe@11.1.0';

console.log("--- 🚀 Тестовая функция ЗАГРУЖЕНА ---");

// Получаем ключ
const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY');

if (!stripeSecretKey) {
  console.error('### ❌ КЛЮЧ STRIPE_SECRET_KEY НЕ НАЙДЕН!');
} else {
  console.log(`✅ Ключ Stripe загружен. Заканчивается на: ...${stripeSecretKey.slice(-4)}`);
  
  // Дополнительная проверка формата ключа
  if (!stripeSecretKey.startsWith('sk_test_') && !stripeSecretKey.startsWith('sk_live_')) {
    console.error('### ❌ ПРЕДУПРЕЖДЕНИЕ: Ключ не начинается с "sk_test_" или "sk_live_". Возможно, это публикуемый ключ.');
  }
  
  // Проверяем длину ключа
  if (stripeSecretKey.length < 50) {
    console.error('### ❌ ПРЕДУПРЕЖДЕНИЕ: Ключ слишком короткий. Возможно, он обрезан.');
  }
}

// Инициализируем Stripe с дополнительными параметрами для отладки
const stripe = new Stripe(stripeSecretKey!, {
  apiVersion: '2023-10-16',
  maxNetworkRetries: 2,
  timeout: 20000, // 20 секунд
});

Deno.serve(async (req) => {
  console.log('--- 🏁 Запускаем тест подключения к Stripe... ---');
  try {
    // --- Тестовый запрос ---
    // Мы просто просим у Stripe список из 1 платежа.
    // Это самая простая и безопасная команда для проверки ключа.
    const intents = await stripe.paymentIntents.list({
      limit: 1,
    });
    
    console.log('✅ Успешное подключение к Stripe. Получен ответ.');
    
    // Если все хорошо, возвращаем "Успех"
    return new Response(
      JSON.stringify({ success: true, data: intents.data }),
      { headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('### ❌ ОШИБКА ПОДКЛЮЧЕНИЯ В ТЕСТОВОЙ ФУНКЦИИ:');
    // Type assertion for error object
    const stripeError = error as any;
    console.error('Тип ошибки:', stripeError.type);
    console.error('Сообщение об ошибке:', stripeError.message);
    console.error('Код ошибки:', stripeError.code);
    console.error('Детали ошибки:', JSON.stringify(stripeError, null, 2));

    // Если ошибка, возвращаем ее
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: stripeError.message,
        type: stripeError.type,
        code: stripeError.code
      }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
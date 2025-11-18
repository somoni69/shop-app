declare module 'https://esm.sh/stripe@11.1.0' {
  export default class Stripe {
    constructor(apiKey: string, options?: { apiVersion?: string; maxNetworkRetries?: number; timeout?: number });
    paymentIntents: {
      create(params: { amount: number; currency: string; automatic_payment_methods?: { enabled: boolean } }): Promise<{ client_secret: string }>;
      list(params: { limit: number }): Promise<{ data: any[] }>;
    };
  }
}
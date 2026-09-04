import { createClient } from 'redis';

const redisUrl = process.env.REDIS_URL || `rediss://${process.env.REDIS_HOST || 'localhost'}:${process.env.REDIS_PORT || 6379}`;
console.log('redisUrl');
console.log(redisUrl);
console.log('process.env.REDIS_HOST');
console.log(process.env.REDIS_HOST);

export const client = createClient({ url: redisUrl });

client.on('connect', () => {
  console.log('redisUrl');
  console.log(redisUrl);
  console.log('process.env.REDIS_HOST');
  console.log(process.env.REDIS_HOST);
  console.log('✅ Connected to Redis');
});

client.on('error', (err) => {
   console.log('redisUrl');
   console.log(redisUrl);
   console.log('process.env.REDIS_HOST');
   console.log(process.env.REDIS_HOST);
  console.error('❌ Redis error:', err);
});

await client.connect();

export const saveUrl = async (code, url) => {
  await client.set(code, JSON.stringify({ originalUrl: url }), {
    EX: 259200,
  });
};

export const getUrlByCode = async (code) => {
  const data = await client.get(code);
  if (!data) return null;
  const parsed = JSON.parse(data);
  return parsed.originalUrl;
};

import { generateShortCode } from '../src/services/urlServices.js';
import { client } from '../src/services/redisService.js';



describe('generateShortCode', () => {
  it('should return a 6-character string', async () => {
    const code = await generateShortCode();
    expect(typeof code).toBe('string');
    expect(code).toHaveLength(6);
  });
});


afterAll(async () => {
  await client.quit(); // or disconnect(), depending on the client
});
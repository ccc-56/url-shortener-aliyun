import { saveUrl as redisSaveUrl, getUrlByCode as redisGetUrlByCode } from './redisService.js';
import { nanoid } from 'nanoid';
  
export const generateShortCode = async () => {
    return nanoid(6);
};

export const saveUrl = async (code, url) => {
    // Use Redis to store the URL
    await redisSaveUrl(code, url);
  };
  
export const getUrlByCode = async (code) => {
    // Fetch URL from Redis
    const url = await redisGetUrlByCode(code);
    return url;
  };
  

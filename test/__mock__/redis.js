const mockRedisClient = {
    set: jest.fn().mockResolvedValue('OK'),
    get: jest.fn().mockResolvedValue('https://example.com'),
    connect: jest.fn().mockResolvedValue(true),
    on: jest.fn(),
  };
  
  module.exports = {
    createClient: jest.fn(() => mockRedisClient),
  };
  
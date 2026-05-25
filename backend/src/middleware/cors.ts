import { MiddlewareHandler } from 'hono';

export const corsMiddleware: MiddlewareHandler = async (c, next) => {
  await next();
  c.header('Access-Control-Allow-Origin', '*');
  c.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  c.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-User-Id');
};

export const preflightHandler: MiddlewareHandler = async (c) => {
  return c.text('', 204);
};

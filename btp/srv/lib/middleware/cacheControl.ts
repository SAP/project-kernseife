import { type NextFunction, type Request, type Response } from 'express';

/**
 * Middleware that sets the Cache-Control header
 *
 * @param {Request} request
 * @param {Response} response
 * @param {NextFunction} next
 */
const cacheControlMiddleware = (
    _: Request,
    response: Response,
    next: NextFunction
): void => {
    response.set('Cache-Control', 'no-store');
    next();
};

export default cacheControlMiddleware;
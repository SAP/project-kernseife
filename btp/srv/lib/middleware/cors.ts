/* eslint-disable callback-return */
import { type NextFunction, type Request, type Response } from 'express';

// REVISIT: extract allowed origins into central config
const allowedOrigins: string[] = JSON.parse(
    process.env.allowedOrigins ?? '[]'
) as string[];

/**
 * Middleware that sets the CORS headers
 *
 * @param {Request} request
 * @param {Response} response
 * @param {NextFunction} next
 */
export default function corsMiddleware(
    request: Request,
    response: Response,
    next: NextFunction
): void {
    if (process.env.NODE_ENV !== 'production') {
        const { origin } = request.headers;
        if (origin !== undefined) {
            response.set('Access-Control-Allow-Headers', 'Content-Type, Accept');
        }
        next();
    } else {
        const { origin } = request.headers;

        // standard request
        if (origin !== undefined && allowedOrigins.includes(origin)) {
            response.set('Access-Control-Allow-Origin', origin);
        }
        // preflight request
        if (
            origin !== undefined &&
            allowedOrigins.includes(origin) &&
            request.method === 'OPTIONS'
        ) {
            response.set('Access-Control-Allow-Methods', 'GET,PUT,PATCH,POST').end();
            return;
        }
        next();
    }
}
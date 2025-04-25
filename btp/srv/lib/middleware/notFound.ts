/* eslint-disable @typescript-eslint/no-unused-vars */
import { type NextFunction, type Request, type Response } from 'express';

/**
 * Middleware which returns not found requests
 *
 * @param {Request} _request
 * @param {Response} response
 * @param {NextFunction} _next
 */
const notFoundMiddleware = (
    _request: Request,
    response: Response,
    _next: NextFunction
): void => {
    response.status(404).end();
};

export default notFoundMiddleware;
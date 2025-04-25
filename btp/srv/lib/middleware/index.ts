import corsMiddleware from './cors';

import cacheControlMiddleware from './cacheControl';
import headerMiddleware from './header';
import notFoundMiddleware from './notFound';

export {
    cacheControlMiddleware,
    corsMiddleware,
    headerMiddleware,
    notFoundMiddleware
};

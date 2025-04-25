import cds from '@sap/cds';
import {
    cacheControlMiddleware,
    corsMiddleware,
    headerMiddleware,
    notFoundMiddleware
} from './lib/middleware';

const LOG = cds.log('Init');
const IS_PROD = process.env.NODE_ENV === 'production';
const IS_TEST = process.env.NODE_ENV === 'test';

cds.on('bootstrap', async (app) => {
    LOG.debug('Start custom Bootstrap');
    app.use(cacheControlMiddleware);
    app.use(headerMiddleware);
    app.use(corsMiddleware);

    // Disable the default CAP pages, like index.html, favicon and serving the /app directory staticly
    app.use('/favicon.ico', notFoundMiddleware);
    if (IS_PROD) {
        app.get('/', notFoundMiddleware);
    }
    LOG.debug('Bootstrap finished');
});

export default cds.server;
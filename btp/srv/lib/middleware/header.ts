import helmet from 'helmet';

const headerMiddleware = helmet({
    // CSP Header
    contentSecurityPolicy:
        process.env.NODE_ENV === 'production'
            ? {
                directives: {
                    ...helmet.contentSecurityPolicy.getDefaultDirectives()
                }
            }
            : // Disable for local UI development
            false,
    // HSTS Header
    hsts: {
        maxAge: 31536000,
        includeSubDomains: true
    }
});
export default headerMiddleware;
import { Request, Response, NextFunction } from 'express';

export const ADMIN_USER = process.env.ADMIN_USER || 'admin';
export const ADMIN_PASS = process.env.ADMIN_PASS || 'password123';
export const ADMIN_TOKEN = process.env.ADMIN_TOKEN || 'admintoken';

export const authenticateAdmin = (req: Request, res: Response, next: NextFunction) => {
    const authHeader = req.headers['authorization'];

    if (!authHeader) {
        return res.status(401).json({ message: 'Unauthorized: missing token' });
    }

    const [, token] = authHeader.split(' ');
    if (token !== ADMIN_TOKEN) {
        return res.status(401).json({ message: 'Unauthorized: invalid token' });
    }

    req.user = { id: 0, role: 'admin', name: 'Admin' } as any;
    next();
};

export const verifyAdminCredentials = (email: string, password: string) => {
    return email === ADMIN_USER && password === ADMIN_PASS;
};
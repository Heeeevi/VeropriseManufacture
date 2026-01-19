import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { ExternalLink, MessageCircle, Phone } from 'lucide-react';

interface Supplier {
    id: string;
    name: string;
    phone: string;
    email: string;
    notes: string | null;
}

export default function PartnerVendorSection() {
    const [partners, setPartners] = useState<Supplier[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchPartners();
    }, []);

    const fetchPartners = async () => {
        try {
            const { data, error } = await (supabase as any)
                .from('suppliers')
                .select('id, name, phone, email, notes')
                .eq('is_active', true)
                .order('name')
                .limit(6);

            if (error) throw error;
            setPartners(data || []);
        } catch (error) {
            console.error('Error fetching partner vendors:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleWhatsApp = (phone: string, vendorName: string) => {
        // Clean phone number and add country code if needed
        let cleanPhone = phone.replace(/[^0-9]/g, '');
        if (cleanPhone.startsWith('0')) {
            cleanPhone = '62' + cleanPhone.slice(1);
        }
        const message = encodeURIComponent(`Halo ${vendorName}, saya tertarik dengan produk Anda. Saya menemukan Anda dari Veroprise ERP.`);
        window.open(`https://wa.me/${cleanPhone}?text=${message}`, '_blank');
    };

    if (loading) return null;
    if (partners.length === 0) return null;

    return (
        <div className="space-y-4">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-lg font-semibold flex items-center gap-2">
                        <span className="text-2xl">🤝</span>
                        Supplier Terdaftar
                    </h2>
                    <p className="text-sm text-muted-foreground">
                        Supplier yang sudah terdaftar di sistem
                    </p>
                </div>
                <Badge variant="outline" className="bg-gradient-to-r from-indigo-50 to-purple-50 border-indigo-200">
                    {partners.length} Supplier
                </Badge>
            </div>

            {/* Partner Cards - Horizontal Scroll */}
            <div className="flex gap-4 overflow-x-auto pb-4 -mx-2 px-2 scrollbar-hide">
                {partners.map((partner) => (
                    <Card
                        key={partner.id}
                        className="flex-shrink-0 w-[280px] border-2 border-muted hover:border-primary/30 transition-colors"
                    >
                        <CardContent className="p-4 space-y-3">
                            {/* Header */}
                            <div>
                                <h3 className="font-semibold text-base leading-tight">{partner.name}</h3>
                                {partner.email && (
                                    <p className="text-xs text-muted-foreground mt-0.5">
                                        {partner.email}
                                    </p>
                                )}
                            </div>

                            {/* Description */}
                            {partner.notes && (
                                <p className="text-sm text-muted-foreground line-clamp-2">
                                    {partner.notes}
                                </p>
                            )}

                            {/* Actions */}
                            <div className="flex gap-2 pt-2">
                                {partner.phone && (
                                    <Button
                                        size="sm"
                                        className="flex-1 bg-green-600 hover:bg-green-700"
                                        onClick={() => handleWhatsApp(partner.phone, partner.name)}
                                    >
                                        <MessageCircle className="h-4 w-4 mr-1" />
                                        WhatsApp
                                    </Button>
                                )}
                                {partner.phone && (
                                    <Button
                                        size="sm"
                                        variant="outline"
                                        onClick={() => window.open(`tel:${partner.phone}`)}
                                    >
                                        <Phone className="h-4 w-4" />
                                    </Button>
                                )}
                            </div>
                        </CardContent>
                    </Card>
                ))}
            </div>
        </div>
    );
}

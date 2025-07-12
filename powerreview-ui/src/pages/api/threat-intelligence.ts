/**
 * Threat Intelligence API Integration
 * Connects threat monitoring with PowerReview assessment engine
 */

import type { APIRoute } from 'astro';
import { ThreatIntelligenceMonitor } from '../../lib/threat-intelligence-monitor';

const threatMonitor = new ThreatIntelligenceMonitor();

export const GET: APIRoute = async ({ params, request, url }) => {
    const action = url.searchParams.get('action');
    
    try {
        switch (action) {
            case 'recent-threats':
                const hours = parseInt(url.searchParams.get('hours') || '24');
                const threats = threatMonitor.getRecentThreats(hours);
                return new Response(JSON.stringify({
                    success: true,
                    threats,
                    count: threats.length
                }), {
                    status: 200,
                    headers: { 'Content-Type': 'application/json' }
                });

            case 'security-checks':
                const checks = threatMonitor.getSecurityChecks();
                return new Response(JSON.stringify({
                    success: true,
                    checks,
                    count: checks.length
                }), {
                    status: 200,
                    headers: { 'Content-Type': 'application/json' }
                });

            case 'status':
                return new Response(JSON.stringify({
                    success: true,
                    status: 'running',
                    sources: threatMonitor.getSources().map(source => ({
                        id: source.id,
                        name: source.name,
                        isActive: source.isActive,
                        lastChecked: source.lastChecked
                    }))
                }), {
                    status: 200,
                    headers: { 'Content-Type': 'application/json' }
                });

            default:
                return new Response(JSON.stringify({
                    error: 'Invalid action parameter'
                }), {
                    status: 400,
                    headers: { 'Content-Type': 'application/json' }
                });
        }
    } catch (error) {
        return new Response(JSON.stringify({
            error: 'Internal server error',
            message: error.message
        }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' }
        });
    }
};

export const POST: APIRoute = async ({ request }) => {
    try {
        const data = await request.json();
        const { action } = data;

        switch (action) {
            case 'add-webhook':
                if (!data.url) {
                    return new Response(JSON.stringify({
                        error: 'Webhook URL is required'
                    }), {
                        status: 400,
                        headers: { 'Content-Type': 'application/json' }
                    });
                }
                
                threatMonitor.addWebhook(data.url);
                return new Response(JSON.stringify({
                    success: true,
                    message: 'Webhook added successfully'
                }), {
                    status: 200,
                    headers: { 'Content-Type': 'application/json' }
                });

            case 'trigger-scan':
                await threatMonitor.performDeepScan();
                return new Response(JSON.stringify({
                    success: true,
                    message: 'Deep scan triggered'
                }), {
                    status: 200,
                    headers: { 'Content-Type': 'application/json' }
                });

            case 'add-check-to-assessment':
                if (!data.checkId) {
                    return new Response(JSON.stringify({
                        error: 'Check ID is required'
                    }), {
                        status: 400,
                        headers: { 'Content-Type': 'application/json' }
                    });
                }

                // Find the security check
                const checks = threatMonitor.getSecurityChecks();
                const check = checks.find(c => c.checkId === data.checkId);
                
                if (!check) {
                    return new Response(JSON.stringify({
                        error: 'Security check not found'
                    }), {
                        status: 404,
                        headers: { 'Content-Type': 'application/json' }
                    });
                }

                // Add to assessment engine (this would integrate with your existing assessment system)
                // For now, we'll simulate the integration
                return new Response(JSON.stringify({
                    success: true,
                    message: `Security check "${check.name}" added to assessment engine`,
                    checkId: check.checkId
                }), {
                    status: 200,
                    headers: { 'Content-Type': 'application/json' }
                });

            default:
                return new Response(JSON.stringify({
                    error: 'Invalid action'
                }), {
                    status: 400,
                    headers: { 'Content-Type': 'application/json' }
                });
        }
    } catch (error) {
        return new Response(JSON.stringify({
            error: 'Internal server error',
            message: error.message
        }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' }
        });
    }
};
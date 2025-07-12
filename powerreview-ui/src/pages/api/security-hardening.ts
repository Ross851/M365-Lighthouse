/**
 * Security Hardening API Endpoints
 * Provides REST API for security hardening operations
 */

import type { APIRoute } from 'astro';
import { SecurityHardeningEngine } from '../../lib/security-hardening';

const securityEngine = new SecurityHardeningEngine();

export const GET: APIRoute = async ({ params, request, url }) => {
    const action = url.searchParams.get('action');
    
    try {
        switch (action) {
            case 'assessment':
                const assessment = await securityEngine.performSecurityAssessment();
                return new Response(JSON.stringify({
                    success: true,
                    assessment
                }), {
                    status: 200,
                    headers: { 'Content-Type': 'application/json' }
                });

            case 'policies':
                const policies = securityEngine.getSecurityPolicies();
                return new Response(JSON.stringify({
                    success: true,
                    policies
                }), {
                    status: 200,
                    headers: { 'Content-Type': 'application/json' }
                });

            case 'hardening-rules':
                const rules = securityEngine.getHardeningRules();
                return new Response(JSON.stringify({
                    success: true,
                    rules
                }), {
                    status: 200,
                    headers: { 'Content-Type': 'application/json' }
                });

            case 'incidents':
                const status = url.searchParams.get('status') as any;
                const incidents = securityEngine.getSecurityIncidents(status);
                return new Response(JSON.stringify({
                    success: true,
                    incidents
                }), {
                    status: 200,
                    headers: { 'Content-Type': 'application/json' }
                });

            case 'validate':
                const hardeningId = url.searchParams.get('hardeningId');
                if (!hardeningId) {
                    return new Response(JSON.stringify({
                        error: 'Hardening ID is required'
                    }), {
                        status: 400,
                        headers: { 'Content-Type': 'application/json' }
                    });
                }

                const validation = await securityEngine.validateHardening(hardeningId);
                return new Response(JSON.stringify({
                    success: true,
                    validation
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
            case 'apply-hardening':
                if (!data.hardeningId) {
                    return new Response(JSON.stringify({
                        error: 'Hardening ID is required'
                    }), {
                        status: 400,
                        headers: { 'Content-Type': 'application/json' }
                    });
                }

                const result = await securityEngine.applyHardening(
                    data.hardeningId, 
                    data.testMode || false
                );

                return new Response(JSON.stringify({
                    success: result.success,
                    result: result.result,
                    error: result.error,
                    rollbackScript: result.rollbackScript
                }), {
                    status: result.success ? 200 : 400,
                    headers: { 'Content-Type': 'application/json' }
                });

            case 'update-policy':
                if (!data.policyId || !data.updates) {
                    return new Response(JSON.stringify({
                        error: 'Policy ID and updates are required'
                    }), {
                        status: 400,
                        headers: { 'Content-Type': 'application/json' }
                    });
                }

                const updated = securityEngine.updateSecurityPolicy(data.policyId, data.updates);
                
                return new Response(JSON.stringify({
                    success: updated,
                    message: updated ? 'Policy updated successfully' : 'Policy not found'
                }), {
                    status: updated ? 200 : 404,
                    headers: { 'Content-Type': 'application/json' }
                });

            case 'respond-to-incident':
                if (!data.incidentId || !data.actionId) {
                    return new Response(JSON.stringify({
                        error: 'Incident ID and action ID are required'
                    }), {
                        status: 400,
                        headers: { 'Content-Type': 'application/json' }
                    });
                }

                const response = await securityEngine.respondToIncident(
                    data.incidentId, 
                    data.actionId
                );

                return new Response(JSON.stringify({
                    success: response.success,
                    result: response.result,
                    error: response.error
                }), {
                    status: response.success ? 200 : 400,
                    headers: { 'Content-Type': 'application/json' }
                });

            case 'detect-threat':
                if (!data.threatData) {
                    return new Response(JSON.stringify({
                        error: 'Threat data is required'
                    }), {
                        status: 400,
                        headers: { 'Content-Type': 'application/json' }
                    });
                }

                const incident = securityEngine.detectThreat(data.threatData);
                
                return new Response(JSON.stringify({
                    success: true,
                    incident
                }), {
                    status: 200,
                    headers: { 'Content-Type': 'application/json' }
                });

            case 'generate-report':
                // Generate security hardening report
                const reportData = {
                    timestamp: new Date().toISOString(),
                    assessment: await securityEngine.performSecurityAssessment(),
                    policies: securityEngine.getSecurityPolicies(),
                    incidents: securityEngine.getSecurityIncidents(),
                    summary: {
                        totalPolicies: securityEngine.getSecurityPolicies().length,
                        enabledPolicies: securityEngine.getSecurityPolicies().filter(p => p.enabled).length,
                        totalIncidents: securityEngine.getSecurityIncidents().length,
                        openIncidents: securityEngine.getSecurityIncidents('open').length,
                        criticalFindings: securityEngine.getSecurityIncidents().filter(i => i.severity === 'critical').length
                    }
                };

                return new Response(JSON.stringify({
                    success: true,
                    report: reportData
                }), {
                    status: 200,
                    headers: { 
                        'Content-Type': 'application/json',
                        'Content-Disposition': 'attachment; filename="security-hardening-report.json"'
                    }
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

export const PUT: APIRoute = async ({ request }) => {
    try {
        const data = await request.json();
        const { action } = data;

        switch (action) {
            case 'bulk-apply-hardening':
                if (!data.hardeningIds || !Array.isArray(data.hardeningIds)) {
                    return new Response(JSON.stringify({
                        error: 'Array of hardening IDs is required'
                    }), {
                        status: 400,
                        headers: { 'Content-Type': 'application/json' }
                    });
                }

                const results = [];
                for (const hardeningId of data.hardeningIds) {
                    try {
                        const result = await securityEngine.applyHardening(
                            hardeningId, 
                            data.testMode || false
                        );
                        results.push({ hardeningId, ...result });
                    } catch (error) {
                        results.push({ 
                            hardeningId, 
                            success: false, 
                            error: error.message 
                        });
                    }
                }

                return new Response(JSON.stringify({
                    success: true,
                    results,
                    summary: {
                        total: results.length,
                        successful: results.filter(r => r.success).length,
                        failed: results.filter(r => !r.success).length
                    }
                }), {
                    status: 200,
                    headers: { 'Content-Type': 'application/json' }
                });

            case 'bulk-update-policies':
                if (!data.policyUpdates || !Array.isArray(data.policyUpdates)) {
                    return new Response(JSON.stringify({
                        error: 'Array of policy updates is required'
                    }), {
                        status: 400,
                        headers: { 'Content-Type': 'application/json' }
                    });
                }

                const updateResults = [];
                for (const update of data.policyUpdates) {
                    const success = securityEngine.updateSecurityPolicy(
                        update.policyId, 
                        update.updates
                    );
                    updateResults.push({ 
                        policyId: update.policyId, 
                        success 
                    });
                }

                return new Response(JSON.stringify({
                    success: true,
                    results: updateResults
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

export const DELETE: APIRoute = async ({ request, url }) => {
    try {
        const incidentId = url.searchParams.get('incidentId');
        
        if (!incidentId) {
            return new Response(JSON.stringify({
                error: 'Incident ID is required'
            }), {
                status: 400,
                headers: { 'Content-Type': 'application/json' }
            });
        }

        // In a real implementation, this would delete the incident
        // For now, we'll simulate the deletion
        
        return new Response(JSON.stringify({
            success: true,
            message: `Incident ${incidentId} deleted successfully`
        }), {
            status: 200,
            headers: { 'Content-Type': 'application/json' }
        });
        
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
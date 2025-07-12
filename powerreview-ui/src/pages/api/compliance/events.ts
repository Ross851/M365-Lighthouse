/**
 * Server-Sent Events endpoint for real-time compliance monitoring
 * Simpler alternative to WebSockets that works with standard HTTP
 */

import type { APIRoute } from 'astro';
import { complianceMonitoring } from '../../../lib/compliance-monitoring';
import { MOCK_CLIENTS } from '../../../lib/mock-data-generator';

// Initialize monitoring on first request
let initialized = false;

function initializeMonitoring() {
  if (initialized) return;
  initialized = true;

  console.log('Initializing compliance monitoring...');

  // Start monitoring for each mock client
  MOCK_CLIENTS.forEach(client => {
    // Monitor primary region
    complianceMonitoring.startMonitoring(client.clientId, client.headquarters);
    
    // Initialize with baseline metrics
    complianceMonitoring.updateMetrics(client.clientId, client.headquarters, {
      clientId: client.clientId,
      regionCode: client.headquarters,
      overallScore: 85 + Math.random() * 10,
      scores: {
        dataProtection: 80 + Math.random() * 15,
        accessControl: 85 + Math.random() * 10,
        encryption: 90 + Math.random() * 8,
        auditLogging: 75 + Math.random() * 20,
        incidentResponse: 70 + Math.random() * 25,
        businessContinuity: 80 + Math.random() * 15
      },
      violations: 0,
      warnings: Math.floor(Math.random() * 3),
      lastUpdated: new Date()
    });

    // Monitor additional regions
    if (client.operationalRegions) {
      client.operationalRegions.slice(0, 2).forEach(region => {
        if (region.regionCode !== client.headquarters) {
          complianceMonitoring.startMonitoring(client.clientId, region.regionCode);
          
          complianceMonitoring.updateMetrics(client.clientId, region.regionCode, {
            clientId: client.clientId,
            regionCode: region.regionCode,
            overallScore: 80 + Math.random() * 15,
            scores: {
              dataProtection: 75 + Math.random() * 20,
              accessControl: 80 + Math.random() * 15,
              encryption: 85 + Math.random() * 12,
              auditLogging: 70 + Math.random() * 25,
              incidentResponse: 65 + Math.random() * 30,
              businessContinuity: 75 + Math.random() * 20
            },
            violations: Math.floor(Math.random() * 2),
            warnings: Math.floor(Math.random() * 4),
            lastUpdated: new Date()
          });
        }
      });
    }
  });

  // Start simulating changes
  startSimulation();
}

function startSimulation() {
  // Simulate random compliance changes every 5 seconds
  setInterval(() => {
    const clients = MOCK_CLIENTS;
    const randomClient = clients[Math.floor(Math.random() * clients.length)];
    const regions = [randomClient.headquarters, ...(randomClient.operationalRegions?.map(r => r.regionCode) || [])];
    const randomRegion = regions[Math.floor(Math.random() * regions.length)];

    // Random metric changes
    const metrics = ['dataProtection', 'accessControl', 'encryption', 'auditLogging', 'incidentResponse', 'businessContinuity'];
    const randomMetric = metrics[Math.floor(Math.random() * metrics.length)] as keyof typeof scores;
    
    const currentKey = `${randomClient.clientId}:${randomRegion}`;
    const current = (complianceMonitoring as any).metrics.get(currentKey);
    if (!current) return;

    const currentValue = current.scores[randomMetric];
    const change = (Math.random() - 0.5) * 20; // -10 to +10 change
    const newValue = Math.max(0, Math.min(100, currentValue + change));

    const scores = { ...current.scores };
    scores[randomMetric] = Math.round(newValue);

    complianceMonitoring.updateMetrics(randomClient.clientId, randomRegion, { scores });
  }, 5000);

  // Simulate violations every 20 seconds
  setInterval(() => {
    if (Math.random() < 0.4) { // 40% chance
      const clients = MOCK_CLIENTS;
      const randomClient = clients[Math.floor(Math.random() * clients.length)];
      const regions = [randomClient.headquarters, ...(randomClient.operationalRegions?.map(r => r.regionCode) || [])];
      const randomRegion = regions[Math.floor(Math.random() * regions.length)];

      const metrics = ['dataProtection', 'accessControl', 'encryption', 'auditLogging'] as const;
      const randomMetric = metrics[Math.floor(Math.random() * metrics.length)];
      
      const scores = {
        [randomMetric]: 40 + Math.random() * 15 // Drop to critical level
      };

      complianceMonitoring.updateMetrics(randomClient.clientId, randomRegion, { scores } as any);
    }
  }, 20000);
}

export const GET: APIRoute = async ({ request }) => {
  // Initialize monitoring
  initializeMonitoring();

  // Set up Server-Sent Events
  const encoder = new TextEncoder();
  const stream = new ReadableStream({
    start(controller) {
      // Send initial state
      const summary = complianceMonitoring.getComplianceSummary();
      const allMetrics = Array.from((complianceMonitoring as any).metrics.values());
      const recentEvents = complianceMonitoring.getRecentEvents(20);

      const initialData = {
        type: 'initial-state',
        data: {
          metrics: allMetrics,
          activeViolations: Array.from((complianceMonitoring as any).activeViolations.values()),
          recentEvents,
          averageScore: summary.averageScore,
          criticalViolations: summary.criticalViolations,
          activeWarnings: summary.activeWarnings,
          regionsMonitored: summary.regionsMonitored.size
        }
      };

      controller.enqueue(encoder.encode(`data: ${JSON.stringify(initialData)}\n\n`));

      // Listen for compliance events
      const eventHandler = (event: any) => {
        const message = {
          type: 'compliance-event',
          data: event
        };
        controller.enqueue(encoder.encode(`data: ${JSON.stringify(message)}\n\n`));
      };

      complianceMonitoring.on('compliance-event', eventHandler);

      // Send heartbeat every 30 seconds
      const heartbeat = setInterval(() => {
        controller.enqueue(encoder.encode(': heartbeat\n\n'));
      }, 30000);

      // Send summary update every 10 seconds
      const summaryUpdate = setInterval(() => {
        const summary = complianceMonitoring.getComplianceSummary();
        const message = {
          type: 'summary-update',
          data: {
            averageScore: summary.averageScore,
            criticalViolations: summary.criticalViolations,
            activeWarnings: summary.activeWarnings,
            regionsMonitored: summary.regionsMonitored.size,
            worstPerformers: summary.worstPerformers
          }
        };
        controller.enqueue(encoder.encode(`data: ${JSON.stringify(message)}\n\n`));
      }, 10000);

      // Clean up on close
      request.signal.addEventListener('abort', () => {
        complianceMonitoring.off('compliance-event', eventHandler);
        clearInterval(heartbeat);
        clearInterval(summaryUpdate);
        controller.close();
      });
    }
  });

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'X-Accel-Buffering': 'no'
    }
  });
};
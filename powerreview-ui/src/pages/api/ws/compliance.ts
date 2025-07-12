/**
 * WebSocket endpoint for real-time compliance monitoring
 */

import type { APIRoute } from 'astro';
import { WebSocketServer } from 'ws';
import { complianceMonitoring } from '../../../lib/compliance-monitoring';
import { MOCK_CLIENTS } from '../../../lib/mock-data-generator';

// Create WebSocket server if not exists
let wss: WebSocketServer;

export const GET: APIRoute = async ({ request, url }) => {
  // Check if this is a WebSocket upgrade request
  const upgrade = request.headers.get('upgrade');
  if (upgrade !== 'websocket') {
    return new Response('Expected WebSocket connection', { status: 426 });
  }

  // Initialize WebSocket server if needed
  if (!wss) {
    wss = new WebSocketServer({ noServer: true });
    initializeMonitoring();
  }

  // Handle the upgrade
  try {
    const response = new Response(null, {
      status: 101,
      headers: {
        'Upgrade': 'websocket',
        'Connection': 'Upgrade',
      },
    });

    // The actual WebSocket handling happens in the server
    return response;
  } catch (error) {
    console.error('WebSocket upgrade failed:', error);
    return new Response('WebSocket upgrade failed', { status: 500 });
  }
};

/**
 * Initialize compliance monitoring with mock data
 */
function initializeMonitoring() {
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

  // Start simulating changes for demo
  startSimulation();

  // Listen for compliance events
  complianceMonitoring.on('compliance-event', (event) => {
    console.log('Compliance event:', event);
  });
}

/**
 * Start simulating compliance changes
 */
function startSimulation() {
  // Simulate random compliance changes
  setInterval(() => {
    const clients = MOCK_CLIENTS;
    const randomClient = clients[Math.floor(Math.random() * clients.length)];
    const regions = [randomClient.headquarters, ...(randomClient.operationalRegions?.map(r => r.regionCode) || [])];
    const randomRegion = regions[Math.floor(Math.random() * regions.length)];

    // Simulate metric changes
    complianceMonitoring.simulateComplianceChanges(randomClient.clientId, randomRegion);
  }, 5000);

  // Simulate periodic violations
  setInterval(() => {
    if (Math.random() < 0.3) { // 30% chance
      const clients = MOCK_CLIENTS;
      const randomClient = clients[Math.floor(Math.random() * clients.length)];
      const regions = [randomClient.headquarters, ...(randomClient.operationalRegions?.map(r => r.regionCode) || [])];
      const randomRegion = regions[Math.floor(Math.random() * regions.length)];

      // Create a significant drop in a random metric
      const metrics = ['dataProtection', 'accessControl', 'encryption', 'auditLogging', 'incidentResponse', 'businessContinuity'];
      const randomMetric = metrics[Math.floor(Math.random() * metrics.length)];
      
      const updates = {
        scores: {
          [randomMetric]: 40 + Math.random() * 20 // Drop to critical level
        }
      };

      complianceMonitoring.updateMetrics(randomClient.clientId, randomRegion, updates as any);
    }
  }, 30000); // Every 30 seconds

  // Simulate resolutions
  setInterval(() => {
    const clients = MOCK_CLIENTS;
    const randomClient = clients[Math.floor(Math.random() * clients.length)];
    const regions = [randomClient.headquarters, ...(randomClient.operationalRegions?.map(r => r.regionCode) || [])];
    const randomRegion = regions[Math.floor(Math.random() * regions.length)];

    // Improve a random metric
    const metrics = ['dataProtection', 'accessControl', 'encryption', 'auditLogging', 'incidentResponse', 'businessContinuity'];
    const randomMetric = metrics[Math.floor(Math.random() * metrics.length)];
    
    const updates = {
      scores: {
        [randomMetric]: 85 + Math.random() * 10 // Improve to good level
      }
    };

    complianceMonitoring.updateMetrics(randomClient.clientId, randomRegion, updates as any);
  }, 45000); // Every 45 seconds
}

// Export WebSocket handler for server integration
export function handleWebSocket(ws: WebSocket) {
  console.log('New WebSocket connection for compliance monitoring');
  
  // Add connection to monitoring service
  complianceMonitoring.addWebSocketConnection(ws as any);

  // Send initial summary
  const summary = complianceMonitoring.getComplianceSummary();
  ws.send(JSON.stringify({
    type: 'summary-update',
    data: {
      averageScore: summary.averageScore,
      criticalViolations: summary.criticalViolations,
      activeWarnings: summary.activeWarnings,
      regionsMonitored: summary.regionsMonitored.size
    }
  }));

  ws.on('message', (data) => {
    try {
      const message = JSON.parse(data.toString());
      
      switch (message.type) {
        case 'get-events':
          const events = complianceMonitoring.getRecentEvents(50, message.filters);
          ws.send(JSON.stringify({
            type: 'events-list',
            data: events
          }));
          break;
          
        case 'get-summary':
          const currentSummary = complianceMonitoring.getComplianceSummary();
          ws.send(JSON.stringify({
            type: 'summary-update',
            data: {
              ...currentSummary,
              regionsMonitored: currentSummary.regionsMonitored.size
            }
          }));
          break;
      }
    } catch (error) {
      console.error('WebSocket message error:', error);
    }
  });

  ws.on('close', () => {
    console.log('WebSocket connection closed');
  });

  ws.on('error', (error) => {
    console.error('WebSocket error:', error);
  });
}
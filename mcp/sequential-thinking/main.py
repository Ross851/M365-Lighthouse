#!/usr/bin/env python3
"""
Sequential Thinking MCP Server for PowerReview
Enables parallel execution of multiple PowerShell scripts
"""

import asyncio
import json
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor
from typing import List, Dict, Any, Optional
import threading
import queue
import time
import os
from pathlib import Path

class PowerReviewParallelExecutor:
    def __init__(self):
        self.executor = ProcessPoolExecutor(max_workers=4)
        self.script_queue = queue.Queue()
        self.results = {}
        self.active_scripts = {}
        self.lock = threading.Lock()
        
    async def execute_script_async(self, script_path: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a PowerShell script asynchronously"""
        try:
            # Build PowerShell command
            ps_command = self._build_powershell_command(script_path, parameters)
            
            # Run script in subprocess
            process = await asyncio.create_subprocess_exec(
                'pwsh', '-NoProfile', '-NonInteractive', '-Command', ps_command,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout, stderr = await process.communicate()
            
            return {
                'success': process.returncode == 0,
                'stdout': stdout.decode('utf-8'),
                'stderr': stderr.decode('utf-8'),
                'returncode': process.returncode,
                'script': script_path,
                'timestamp': time.time()
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'script': script_path,
                'timestamp': time.time()
            }
    
    def execute_scripts_parallel(self, scripts: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Execute multiple scripts in parallel"""
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        tasks = []
        for script in scripts:
            task = self.execute_script_async(
                script['path'], 
                script.get('parameters', {})
            )
            tasks.append(task)
        
        results = loop.run_until_complete(asyncio.gather(*tasks))
        return results
    
    def _build_powershell_command(self, script_path: str, parameters: Dict[str, Any]) -> str:
        """Build PowerShell command with parameters"""
        params_str = ""
        for key, value in parameters.items():
            if isinstance(value, bool):
                params_str += f" -{key}:${str(value).lower()}"
            elif isinstance(value, str):
                params_str += f" -{key} '{value}'"
            else:
                params_str += f" -{key} {value}"
        
        return f"& '{script_path}'{params_str}"
    
    def get_assessment_scripts(self, assessment_type: str) -> List[Dict[str, Any]]:
        """Get scripts for a specific assessment type"""
        base_path = Path("/mnt/c/Users/Ross/M365-Lighthouse")
        
        assessment_scripts = {
            'full': [
                {'path': base_path / 'PowerReview-AzureAD.ps1', 'priority': 1},
                {'path': base_path / 'PowerReview-Exchange.ps1', 'priority': 1},
                {'path': base_path / 'PowerReview-SharePoint.ps1', 'priority': 2},
                {'path': base_path / 'PowerReview-Teams.ps1', 'priority': 2},
                {'path': base_path / 'PowerReview-Defender.ps1', 'priority': 3},
                {'path': base_path / 'PowerReview-Compliance.ps1', 'priority': 3}
            ],
            'security': [
                {'path': base_path / 'PowerReview-AzureAD.ps1', 'priority': 1},
                {'path': base_path / 'PowerReview-Defender.ps1', 'priority': 1},
                {'path': base_path / 'PowerReview-Exchange.ps1', 'priority': 2}
            ],
            'compliance': [
                {'path': base_path / 'PowerReview-Compliance.ps1', 'priority': 1},
                {'path': base_path / 'PowerReview-SharePoint.ps1', 'priority': 2},
                {'path': base_path / 'PowerReview-Teams.ps1', 'priority': 2}
            ]
        }
        
        return assessment_scripts.get(assessment_type, [])
    
    def run_assessment_parallel(self, assessment_type: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Run a complete assessment with parallel execution"""
        scripts = self.get_assessment_scripts(assessment_type)
        
        # Group scripts by priority for staged parallel execution
        priority_groups = {}
        for script in scripts:
            priority = script['priority']
            if priority not in priority_groups:
                priority_groups[priority] = []
            
            script['parameters'] = parameters
            priority_groups[priority].append(script)
        
        all_results = []
        start_time = time.time()
        
        # Execute each priority group in parallel
        for priority in sorted(priority_groups.keys()):
            group_scripts = priority_groups[priority]
            group_results = self.execute_scripts_parallel(group_scripts)
            all_results.extend(group_results)
        
        end_time = time.time()
        
        return {
            'assessment_type': assessment_type,
            'total_scripts': len(scripts),
            'execution_time': end_time - start_time,
            'results': all_results,
            'success': all(r['success'] for r in all_results)
        }

class MCPServer:
    """MCP Server implementation for PowerReview parallel execution"""
    
    def __init__(self):
        self.executor = PowerReviewParallelExecutor()
        
    def handle_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Handle incoming MCP requests"""
        method = request.get('method')
        params = request.get('params', {})
        
        if method == 'execute_parallel':
            scripts = params.get('scripts', [])
            return {
                'result': self.executor.execute_scripts_parallel(scripts)
            }
            
        elif method == 'run_assessment':
            assessment_type = params.get('type', 'full')
            parameters = params.get('parameters', {})
            return {
                'result': self.executor.run_assessment_parallel(assessment_type, parameters)
            }
            
        elif method == 'get_scripts':
            assessment_type = params.get('type', 'full')
            return {
                'result': self.executor.get_assessment_scripts(assessment_type)
            }
            
        else:
            return {
                'error': f'Unknown method: {method}'
            }
    
    def run(self):
        """Run the MCP server"""
        while True:
            try:
                # Read request from stdin
                line = sys.stdin.readline()
                if not line:
                    break
                    
                request = json.loads(line)
                response = self.handle_request(request)
                
                # Write response to stdout
                sys.stdout.write(json.dumps(response) + '\n')
                sys.stdout.flush()
                
            except Exception as e:
                error_response = {
                    'error': str(e),
                    'type': 'execution_error'
                }
                sys.stdout.write(json.dumps(error_response) + '\n')
                sys.stdout.flush()

if __name__ == '__main__':
    server = MCPServer()
    server.run()
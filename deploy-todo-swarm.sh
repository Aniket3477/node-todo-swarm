#!/bin/bash

echo "🧹 Cleaning up old manager container..."
# Issue faced: Swarm manager lost state after restart — needed a clean reset
docker rm -f manager 2>/dev/null

echo "🐳 Starting Docker-in-Docker manager with port mapping..."
# Issue faced: Port 8000 wasn't exposed to WSL — added -p 8000:8000
docker run -d --privileged -p 8000:8000 --name manager docker:dind

echo "⏳ Waiting for Docker daemon to start..."
sleep 5

echo "🚀 Initializing Swarm..."
# Issue faced: 'This node is not a swarm manager' — forgot to init after container restart
docker exec manager docker swarm init --advertise-addr eth0

echo "📁 Copying docker-compose.yaml into manager..."
docker cp docker-compose.yaml manager:/docker-compose.yaml

echo "📦 Deploying stack..."
docker exec manager docker stack deploy -c /docker-compose.yaml todoapp

echo "⏳ Waiting for service to stabilize..."
sleep 10

echo "📋 Checking service status..."
docker exec manager docker service ps todoapp_web --no-trunc

echo "🧪 Testing app endpoint..."
# Issue faced: curl gave 'Empty reply from server' — app was bound to localhost
# Fixed by binding to 0.0.0.0 in app.js
curl -i http://localhost:8000

echo "✅ If you see a redirect to /todo, your app is alive!"

# 🚀 Production Deployment Guide

## Before Deployment Checklist

- [ ] Change `SECRET_KEY` in `.env`
- [ ] Set `DEBUG=False`
- [ ] Set `ENVIRONMENT=production`
- [ ] Configure production MongoDB URL
- [ ] Set up HTTPS/SSL certificates
- [ ] Configure email for notifications
- [ ] Set up monitoring & logging
- [ ] Configure backup strategy
- [ ] Load testing completed
- [ ] Security audit completed

---

## Option 1: Docker Compose (Recommended for Small to Medium)

### Prerequisites
- Docker & Docker Compose installed
- Production `.env` file configured

### Steps

```bash
# 1. Clone repo
git clone <repo-url>
cd energy_app_backend

# 2. Create production .env
cp .env.example .env
# Edit .env with production values

# 3. Build and start
docker-compose up -d

# 4. Verify
docker-compose ps
curl http://localhost:8000/health

# 5. View logs
docker-compose logs -f backend
```

### Scaling with Docker Compose

```yaml
# docker-compose.yml
services:
  backend:
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '1'
          memory: 1G
```

---

## Option 2: Kubernetes (For Enterprise)

### Prerequisites
- Kubernetes cluster (GKE, EKS, AKS, etc.)
- kubectl configured
- Docker registry (Docker Hub, ECR, GCR)

### Deployment YAML

```yaml
# k8s-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: energyiq-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: energyiq-backend
  template:
    metadata:
      labels:
        app: energyiq-backend
    spec:
      containers:
      - name: backend
        image: your-registry/energyiq-backend:latest
        ports:
        - containerPort: 8000
        env:
        - name: MONGODB_URL
          valueFrom:
            secretKeyRef:
              name: energyiq-secrets
              key: mongodb-url
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: energyiq-secrets
              key: secret-key
        - name: ENVIRONMENT
          value: production
        resources:
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 250m
            memory: 256Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: energyiq-backend-service
spec:
  type: LoadBalancer
  selector:
    app: energyiq-backend
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8000
```

### Deploy to Kubernetes

```bash
# 1. Create secrets
kubectl create secret generic energyiq-secrets \
  --from-literal=mongodb-url='mongodb://...' \
  --from-literal=secret-key='your-secret-key'

# 2. Create namespace
kubectl create namespace energyiq

# 3. Deploy
kubectl apply -f k8s-deployment.yaml -n energyiq

# 4. Verify
kubectl get deployments -n energyiq
kubectl get pods -n energyiq

# 5. View logs
kubectl logs -f deployment/energyiq-backend -n energyiq

# 6. Access
kubectl port-forward service/energyiq-backend-service 8000:80 -n energyiq
```

---

## Option 3: AWS (Elastic Container Service)

### Steps

```bash
# 1. Build and push to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com

docker build -t energyiq-backend .
docker tag energyiq-backend:latest 123456789.dkr.ecr.us-east-1.amazonaws.com/energyiq-backend:latest
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/energyiq-backend:latest

# 2. Create ECS task definition
# Use console or create task-definition.json

# 3. Create ECS service
aws ecs create-service \
  --cluster energyiq-cluster \
  --service-name energyiq-backend \
  --task-definition energyiq-backend:1 \
  --desired-count 3 \
  --launch-type FARGATE \
  --load-balancers targetGroupArn=arn:aws:elasticloadbalancing:...,containerName=backend,containerPort=8000
```

---

## Option 4: Heroku

```bash
# 1. Install Heroku CLI
curl https://cli.heroku.com/install.sh | sh

# 2. Login
heroku login

# 3. Create app
heroku create energyiq-backend

# 4. Set environment variables
heroku config:set SECRET_KEY=your-secret-key
heroku config:set MONGODB_URL=mongodb+srv://...
heroku config:set ENVIRONMENT=production

# 5. Deploy
git push heroku main

# 6. Check logs
heroku logs --tail
```

---

## Option 5: DigitalOcean (Simple VPS)

### Prerequisites
- DigitalOcean account
- Droplet created (Ubuntu 22.04, 2GB RAM minimum)
- SSH access configured

### Steps

```bash
# 1. SSH into droplet
ssh root@your_droplet_ip

# 2. Update system
apt update && apt upgrade -y

# 3. Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# 4. Clone repo
git clone https://github.com/your-repo/energy_app_backend.git
cd energy_app_backend

# 5. Create production .env
cp .env.example .env
nano .env  # Edit with production values

# 6. Start with Docker Compose
docker-compose up -d

# 7. Set up Nginx reverse proxy (optional)
apt install nginx -y

# Configure /etc/nginx/sites-available/default
# Proxy to localhost:8000
```

---

## Database Configuration

### MongoDB Atlas (Cloud)

```bash
# 1. Create cluster at mongodb.com
# 2. Get connection string:
# mongodb+srv://user:password@cluster.mongodb.net/database?retryWrites=true&w=majority

# 3. Update .env
MONGODB_URL=mongodb+srv://user:password@cluster.mongodb.net/energyiq_db?retryWrites=true&w=majority
```

### Self-Hosted MongoDB

```bash
# Using Docker
docker run -d \
  --name mongodb \
  -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=admin123 \
  -v mongo_data:/data/db \
  mongo:7.0

# Update .env
MONGODB_URL=mongodb://admin:admin123@mongodb:27017/energyiq_db?authSource=admin
```

---

## SSL/HTTPS Setup

### Using Let's Encrypt with Nginx

```bash
# 1. Install Certbot
apt install certbot python3-certbot-nginx -y

# 2. Generate certificate
certbot certonly --nginx -d yourdomain.com

# 3. Update Nginx config
server {
    listen 443 ssl;
    server_name yourdomain.com;
    
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

# 4. Restart Nginx
systemctl restart nginx

# 5. Auto-renewal
certbot renew --dry-run
```

---

## Monitoring & Logging

### ELK Stack (Elasticsearch, Logstash, Kibana)

```yaml
# docker-compose.yml addition
elasticsearch:
  image: docker.elastic.co/elasticsearch/elasticsearch:8.0.0
  environment:
    - discovery.type=single-node
  ports:
    - "9200:9200"

kibana:
  image: docker.elastic.co/kibana/kibana:8.0.0
  ports:
    - "5601:5601"
```

### Prometheus + Grafana

```bash
# Add to docker-compose.yml
prometheus:
  image: prom/prometheus
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml
  ports:
    - "9090:9090"

grafana:
  image: grafana/grafana
  ports:
    - "3000:3000"
```

---

## Backup Strategy

### MongoDB Backup

```bash
# Automatic backup using mongodump
0 2 * * * mongodump --uri mongodb://user:pass@localhost:27017/energyiq_db --out /backups/mongo_$(date +\%Y\%m\%d)

# Or use cloud provider's backup
# MongoDB Atlas: Automated backups every 6 hours
```

### Database Replication

```bash
# Enable replica set
rs.initiate()

# Add secondary
rs.add("secondary-ip:27017")
```

---

## Performance Tuning

### nginx.conf

```nginx
worker_processes auto;
worker_connections 2048;

upstream fastapi {
    least_conn;
    server backend:8000;
    server backend2:8000;
    server backend3:8000;
}

server {
    location / {
        proxy_pass http://fastapi;
        proxy_cache_valid 200 10m;
        proxy_buffering on;
    }
}
```

### MongoDB Optimization

```javascript
// Create indexes
db.consumption_records.createIndex({"device_id": 1, "timestamp": -1})
db.users.createIndex({"email": 1}, {unique: true})

// Enable compression
mongod --wiredTigerCompressionLevel 9
```

---

## Health Checks & Monitoring

### API Endpoints

```bash
# Health check
curl http://localhost:8000/health

# Root
curl http://localhost:8000/

# Docs
curl http://localhost:8000/docs
```

### Container Health

```bash
docker ps
docker logs backend
docker stats backend
```

---

## Scaling Strategy

### Horizontal Scaling

1. **Load Balancer** (Nginx, AWS LB, etc.)
2. **Multiple Backend Instances**
3. **Shared MongoDB**
4. **Redis Cache** (optional)

### Vertical Scaling

- Increase CPU/RAM
- Optimize database queries
- Enable caching

---

## Security Best Practices

1. **Environment Variables**
   - Never commit `.env` to git
   - Use secrets manager (AWS Secrets, Vault, etc.)

2. **Network Security**
   - Use private subnets for database
   - Enable firewall rules
   - Use VPN for admin access

3. **API Security**
   - Rate limiting enabled
   - Input validation enabled
   - CORS properly configured

4. **Database Security**
   - Strong passwords
   - Encryption at rest & transit
   - Regular backups

5. **Monitoring**
   - Log aggregation
   - Alert on errors
   - Monitor resource usage

---

## Troubleshooting

### Port 8000 Already in Use
```bash
lsof -i :8000
kill -9 <PID>
```

### MongoDB Connection Error
```bash
# Check MongoDB is running
docker ps | grep mongo

# Test connection
mongosh "mongodb://localhost:27017"
```

### Out of Memory
```bash
# Check memory usage
docker stats backend

# Increase limit
# docker-compose.yml: mem_limit: 2g
```

### Slow Queries
```bash
# Enable MongoDB profiling
db.setProfilingLevel(1)

# Analyze slow queries
db.system.profile.find({millis: {$gt: 1000}})
```

---

## Post-Deployment

1. ✅ Verify all APIs are working
2. ✅ Load test the system
3. ✅ Test authentication flows
4. ✅ Verify data persistence
5. ✅ Check error handling
6. ✅ Monitor logs
7. ✅ Set up alerts

---

## Support & Maintenance

- Regular updates: `docker-compose pull && docker-compose up -d`
- Monitor: Check logs daily
- Backup: Verify backups work
- Patch: Security updates ASAP
- Test: Regular testing plan

---

**Ready for production! 🚀**

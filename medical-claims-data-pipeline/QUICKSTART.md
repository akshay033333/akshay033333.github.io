# 🚀 Quick Start Guide

Get up and running with the Medical Claims Data Pipeline in minutes!

## ⚡ Prerequisites

- **Docker & Docker Compose** - For local infrastructure
- **Python 3.8+** - For application code
- **Git** - For version control

## 🏃‍♂️ Quick Start (5 minutes)

### 1. Clone the Repository
```bash
git clone <your-repo-url>
cd medical-claims-data-pipeline
```

### 2. Run the Setup Script
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

This script will:
- ✅ Check prerequisites
- ✅ Create project structure
- ✅ Set up Python environment
- ✅ Start local infrastructure (Kafka, Spark, MinIO, etc.)
- ✅ Create sample data

### 3. Access Your Services
Once setup is complete, you can access:

- **Kafka UI**: http://localhost:8080
- **Spark Master**: http://localhost:8081
- **MinIO Console**: http://localhost:9001 (minioadmin/minioadmin)
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090

### 4. Start Processing Data
```bash
# Activate virtual environment
source venv/bin/activate

# Start mock data generator
python src/producers/mock_data_generator.py

# Start streaming processor
python src/processors/streaming_processor.py
```

## 🧪 Test the Pipeline

### Generate Sample Claims
```bash
python -c "
from src.producers.mock_data_generator import MockDataGenerator
generator = MockDataGenerator()
generator.generate_claims(100)
"
```

### Monitor Data Flow
1. Open Kafka UI: http://localhost:8080
2. Check topics: `medical-claims-raw`, `medical-claims-processed`
3. View messages in real-time

### Check Data Quality
```bash
python -c "
from src.processors.quality_checker import QualityChecker
checker = QualityChecker()
metrics = checker.check_claim_quality('CLM001')
print(f'Quality Score: {metrics.overall_score}%')
"
```

## 🔧 Customization

### Environment Variables
```bash
cp .env.example .env
# Edit .env with your configuration
```

### Configuration Files
- **Kafka**: `configs/kafka/`
- **Spark**: `configs/spark/`
- **Monitoring**: `configs/monitoring/`

### Data Schemas
- **Claims**: `src/models/claims_schema.py`
- **Quality Metrics**: `src/models/quality_metrics.py`

## 📊 What You'll See

### Real-time Data Flow
```
Claims Data → Kafka → Spark Streaming → Processed Data → Data Lake
     ↓              ↓           ↓              ↓           ↓
Mock Generator → Raw Topic → Streaming → Validated → MinIO Storage
```

### Sample Output
```json
{
  "claim_id": "CLM001",
  "quality_score": 95.5,
  "processing_time_ms": 150,
  "anomalies_detected": [],
  "status": "processed"
}
```

## 🚨 Troubleshooting

### Common Issues

**Services not starting?**
```bash
# Check Docker status
docker-compose ps

# View logs
docker-compose logs -f kafka
```

**Python import errors?**
```bash
# Activate virtual environment
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

**Port conflicts?**
```bash
# Stop all services
docker-compose down

# Check port usage
lsof -i :8080
```

### Reset Everything
```bash
# Clean slate
docker-compose down -v
rm -rf venv
./scripts/setup.sh
```

## 🔄 Next Steps

### 1. Explore the Code
- **Producers**: `src/producers/` - Data ingestion
- **Processors**: `src/processors/` - Data transformation
- **Models**: `src/models/` - Data schemas
- **Tests**: `src/tests/` - Unit tests

### 2. Run Tests
```bash
python -m pytest src/tests/ -v
```

### 3. Deploy to Cloud
```bash
# Deploy to staging
./scripts/deploy.sh -e staging -a deploy

# Deploy to production
./scripts/deploy.sh -e prod -a deploy
```

### 4. Monitor & Scale
- Set up Grafana dashboards
- Configure Prometheus alerts
- Scale Spark workers
- Add more Kafka brokers

## 📚 Learn More

- **Architecture**: See `docs/architecture.md`
- **API Reference**: See `docs/api.md`
- **Deployment**: See `docs/deployment.md`
- **Contributing**: See `CONTRIBUTING.md`

## 🆘 Need Help?

- 📖 Check the documentation
- 🐛 Report issues on GitHub
- 💬 Join our community
- 📧 Contact the team

---

**🎯 Goal**: Process 1M+ claims per day with sub-second latency!

**⏱️ Time to Value**: < 5 minutes from clone to running pipeline

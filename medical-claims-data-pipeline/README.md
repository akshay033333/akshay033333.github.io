# Medical Claims Data Pipeline

## 🏥 Project Overview

A comprehensive end-to-end data engineering solution for processing and analyzing medical claims data using Apache Spark, Apache Kafka, and modern cloud infrastructure. This project demonstrates real-time streaming data processing, batch analytics, and infrastructure as code practices for healthcare data analytics.

## 📋 Abstract

The Medical Claims Data Pipeline is designed to handle high-volume, real-time processing of healthcare claims data with the following key objectives:

- **Real-time Data Ingestion**: Stream medical claims data from multiple sources using Apache Kafka
- **Data Processing**: Transform and enrich claims data using Apache Spark for both streaming and batch processing
- **Data Quality**: Implement comprehensive data validation, cleansing, and quality checks
- **Analytics**: Provide real-time insights and batch analytics for claims processing efficiency
- **Scalability**: Design infrastructure that can handle millions of claims per day
- **Compliance**: Ensure HIPAA compliance and data security throughout the pipeline
- **Monitoring**: Comprehensive observability and alerting for production operations

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Data Sources  │───▶│   Apache Kafka  │───▶│  Apache Spark   │
│                 │    │   (Ingestion)   │    │  (Processing)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Data Lake     │    │   Data Warehouse│
                       │   (Raw Data)    │    │  (Processed)    │
                       └─────────────────┘    └─────────────────┘
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Monitoring    │    │   Analytics     │
                       │   & Alerting    │    │   Dashboard     │
                       └─────────────────┘    └─────────────────┘
```

## 📁 Project Structure

```
medical-claims-data-pipeline/
├── README.md                           # This file
├── docker-compose.yml                  # Local development environment
├── requirements.txt                    # Python dependencies
├── .env.example                       # Environment variables template
├── .gitignore                         # Git ignore file
│
├── infrastructure/                     # Terraform infrastructure code
│   ├── main.tf                        # Main Terraform configuration
│   ├── variables.tf                   # Variable definitions
│   ├── outputs.tf                     # Output definitions
│   ├── providers.tf                   # Provider configurations
│   ├── modules/                       # Reusable Terraform modules
│   │   ├── kafka/                     # Kafka cluster module
│   │   ├── spark/                     # Spark cluster module
│   │   ├── monitoring/                # Monitoring stack module
│   │   └── networking/                # Network configuration module
│   └── environments/                  # Environment-specific configs
│       ├── dev/                       # Development environment
│       ├── staging/                   # Staging environment
│       └── prod/                      # Production environment
│
├── src/                               # Source code
│   ├── producers/                     # Data producers
│   │   ├── __init__.py
│   │   ├── claims_producer.py         # Medical claims producer
│   │   ├── mock_data_generator.py     # Mock data for testing
│   │   └── data_validator.py          # Input data validation
│   │
│   ├── consumers/                     # Data consumers
│   │   ├── __init__.py
│   │   ├── claims_consumer.py         # Claims data consumer
│   │   └── batch_consumer.py          # Batch processing consumer
│   │
│   ├── processors/                    # Data processing logic
│   │   ├── __init__.py
│   │   ├── streaming_processor.py     # Real-time processing
│   │   ├── batch_processor.py         # Batch processing
│   │   ├── data_transformer.py        # Data transformation logic
│   │   └── quality_checker.py         # Data quality validation
│   │
│   ├── models/                        # Data models and schemas
│   │   ├── __init__.py
│   │   ├── claims_schema.py           # Claims data schema
│   │   ├── processed_schema.py        # Processed data schema
│   │   └── quality_metrics.py         # Quality metrics schema
│   │
│   ├── utils/                         # Utility functions
│   │   ├── __init__.py
│   │   ├── config.py                  # Configuration management
│   │   ├── logger.py                  # Logging configuration
│   │   ├── metrics.py                 # Metrics collection
│   │   └── helpers.py                 # Helper functions
│   │
│   └── tests/                         # Test files
│       ├── __init__.py
│       ├── test_producers.py          # Producer tests
│       ├── test_consumers.py          # Consumer tests
│       ├── test_processors.py         # Processor tests
│       └── test_utils.py              # Utility tests
│
├── configs/                           # Configuration files
│   ├── kafka/                         # Kafka configurations
│   │   ├── producer.properties        # Producer configuration
│   │   ├── consumer.properties        # Consumer configuration
│   │   └── topics.json                # Topic definitions
│   │
│   ├── spark/                         # Spark configurations
│   │   ├── spark-defaults.conf        # Spark default settings
│   │   ├── spark-env.sh               # Spark environment variables
│   │   └── log4j.properties           # Logging configuration
│   │
│   └── monitoring/                    # Monitoring configurations
│       ├── prometheus.yml             # Prometheus configuration
│       ├── grafana/                   # Grafana dashboards
│       └── alertmanager.yml           # Alerting rules
│
├── scripts/                           # Utility scripts
│   ├── setup.sh                       # Environment setup script
│   ├── deploy.sh                      # Deployment script
│   ├── health_check.sh                # Health check script
│   └── cleanup.sh                     # Cleanup script
│
├── docs/                              # Documentation
│   ├── architecture.md                # Detailed architecture
│   ├── api.md                         # API documentation
│   ├── deployment.md                  # Deployment guide
│   └── troubleshooting.md             # Troubleshooting guide
│
└── data/                              # Sample data and schemas
    ├── sample_claims.json             # Sample claims data
    ├── expected_output.json           # Expected output format
    └── data_dictionary.md             # Data field definitions
```

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- Python 3.8+
- Terraform 1.0+
- AWS CLI (for cloud deployment)
- kubectl (for Kubernetes deployment)

### Local Development Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd medical-claims-data-pipeline
   ```

2. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Start local infrastructure**
   ```bash
   docker-compose up -d
   ```

4. **Install Python dependencies**
   ```bash
   pip install -r requirements.txt
   ```

5. **Run the pipeline**
   ```bash
   # Start data producer
   python src/producers/mock_data_generator.py
   
   # Start streaming processor
   python src/processors/streaming_processor.py
   
   # Start batch processor
   python src/processors/batch_processor.py
   ```

## 🏗️ Infrastructure Deployment

### Development Environment

```bash
cd infrastructure/environments/dev
terraform init
terraform plan
terraform apply
```

### Production Environment

```bash
cd infrastructure/environments/prod
terraform init
terraform plan
terraform apply
```

## 📊 Data Flow

1. **Data Ingestion**
   - Medical claims data is ingested from various sources (EMR systems, claims processors, etc.)
   - Data is validated and enriched before streaming to Kafka
   - Multiple Kafka topics handle different types of claims data

2. **Real-time Processing**
   - Apache Spark Streaming processes claims data in real-time
   - Immediate fraud detection and validation
   - Real-time metrics and alerting

3. **Batch Processing**
   - Daily batch jobs for comprehensive analytics
   - Data quality assessments and reporting
   - Historical trend analysis

4. **Data Storage**
   - Raw data stored in data lake (S3/MinIO)
   - Processed data stored in data warehouse (Redshift/Snowflake)
   - Metadata and quality metrics stored separately

5. **Analytics & Reporting**
   - Real-time dashboards for operational insights
   - Batch reports for business intelligence
   - API endpoints for data access

## 🔧 Configuration

### Kafka Topics

- `medical-claims-raw`: Raw incoming claims data
- `medical-claims-validated`: Validated claims data
- `medical-claims-processed`: Processed claims data
- `medical-claims-quality`: Data quality metrics
- `medical-claims-alerts`: Fraud and anomaly alerts

### Spark Configuration

- **Streaming**: 5-second micro-batches
- **Batch**: Daily processing windows
- **Memory**: Configurable based on data volume
- **Partitioning**: Optimized for claims data patterns

## 📈 Monitoring & Observability

- **Metrics**: Prometheus for system and business metrics
- **Logging**: Centralized logging with ELK stack
- **Tracing**: Distributed tracing for request flows
- **Alerting**: Proactive alerting for issues
- **Dashboards**: Grafana dashboards for real-time monitoring

## 🧪 Testing

```bash
# Run all tests
python -m pytest src/tests/

# Run specific test categories
python -m pytest src/tests/test_producers.py
python -m pytest src/tests/test_processors.py

# Run with coverage
python -m pytest --cov=src src/tests/
```

## 📚 API Documentation

The project provides REST APIs for:
- Claims data ingestion
- Real-time analytics queries
- Batch processing status
- Data quality metrics
- System health checks

See `docs/api.md` for detailed API documentation.

## 🔒 Security & Compliance

- **HIPAA Compliance**: All data handling follows HIPAA guidelines
- **Data Encryption**: Data encrypted in transit and at rest
- **Access Control**: Role-based access control (RBAC)
- **Audit Logging**: Comprehensive audit trails
- **Data Masking**: PII data masked in non-production environments

## 🚨 Troubleshooting

Common issues and solutions:
- **Kafka connectivity**: Check network configuration and firewall rules
- **Spark job failures**: Review logs and resource allocation
- **Data quality issues**: Validate input data and transformation logic
- **Performance issues**: Monitor resource usage and optimize configurations

See `docs/troubleshooting.md` for detailed troubleshooting guide.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and questions:
- Create an issue in the repository
- Contact the data engineering team
- Check the troubleshooting documentation

## 🔄 Version History

- **v1.0.0**: Initial release with basic streaming and batch processing
- **v1.1.0**: Added data quality monitoring and alerting
- **v1.2.0**: Enhanced security and compliance features
- **v1.3.0**: Performance optimizations and monitoring improvements

---

**Note**: This is a production-ready data engineering project. Ensure proper testing and validation before deploying to production environments.

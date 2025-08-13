#!/bin/bash

# Medical Claims Data Pipeline Setup Script
# This script sets up the development environment for the project

set -e

echo "🏥 Setting up Medical Claims Data Pipeline..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed. Please install Python 3 first."
        exit 1
    fi
    
    # Check pip
    if ! command -v pip3 &> /dev/null; then
        print_error "pip3 is not installed. Please install pip3 first."
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_warning "Terraform is not installed. This is optional for local development."
    fi
    
    print_success "Prerequisites check completed"
}

# Create project structure
create_project_structure() {
    print_status "Creating project structure..."
    
    # Create directories
    mkdir -p src/{producers,consumers,processors,models,utils,tests}
    mkdir -p configs/{kafka,spark,monitoring,postgres}
    mkdir -p infrastructure/{modules,environments/{dev,staging,prod}}
    mkdir -p scripts docs data
    
    print_success "Project structure created"
}

# Set up Python virtual environment
setup_python_env() {
    print_status "Setting up Python virtual environment..."
    
    if [ ! -d "venv" ]; then
        python3 -m venv venv
        print_success "Virtual environment created"
    else
        print_warning "Virtual environment already exists"
    fi
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install requirements
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
        print_success "Python dependencies installed"
    else
        print_warning "requirements.txt not found, skipping dependency installation"
    fi
    
    # Deactivate virtual environment
    deactivate
}

# Set up environment variables
setup_env_vars() {
    print_status "Setting up environment variables..."
    
    if [ ! -f ".env" ]; then
        cp .env.example .env
        print_success "Environment file created from template"
        print_warning "Please edit .env file with your configuration"
    else
        print_warning ".env file already exists"
    fi
}

# Start local infrastructure
start_infrastructure() {
    print_status "Starting local infrastructure..."
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    # Start services
    docker-compose up -d
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 30
    
    # Check service health
    check_service_health
    
    print_success "Local infrastructure started"
}

# Check service health
check_service_health() {
    print_status "Checking service health..."
    
    # Check Kafka
    if curl -s http://localhost:8080 > /dev/null; then
        print_success "Kafka UI is running on http://localhost:8080"
    else
        print_warning "Kafka UI is not accessible"
    fi
    
    # Check Spark
    if curl -s http://localhost:8081 > /dev/null; then
        print_success "Spark Master is running on http://localhost:8081"
    else
        print_warning "Spark Master is not accessible"
    fi
    
    # Check MinIO
    if curl -s http://localhost:9001 > /dev/null; then
        print_success "MinIO Console is running on http://localhost:9001"
    else
        print_warning "MinIO Console is not accessible"
    fi
    
    # Check PostgreSQL
    if docker exec postgres pg_isready -U postgres > /dev/null 2>&1; then
        print_success "PostgreSQL is running"
    else
        print_warning "PostgreSQL is not accessible"
    fi
    
    # Check Prometheus
    if curl -s http://localhost:9090 > /dev/null; then
        print_success "Prometheus is running on http://localhost:9090"
    else
        print_warning "Prometheus is not accessible"
    fi
    
    # Check Grafana
    if curl -s http://localhost:3000 > /dev/null; then
        print_success "Grafana is running on http://localhost:3000"
    else
        print_warning "Grafana is not accessible"
    fi
}

# Create sample data
create_sample_data() {
    print_status "Creating sample data..."
    
    # Create sample claims data
    cat > data/sample_claims.json << 'EOF'
[
  {
    "claim_id": "CLM001",
    "claim_number": "CLM001",
    "claim_type": "medical",
    "claim_status": "submitted",
    "patient": {
      "patient_id": "PAT001",
      "member_id": "MEM001",
      "first_name": "John",
      "last_name": "Doe",
      "date_of_birth": "1980-01-01T00:00:00",
      "gender": "M",
      "address": {
        "street": "123 Main St",
        "city": "Anytown",
        "state": "CA",
        "zip": "12345"
      }
    },
    "provider": {
      "provider_id": "PROV001",
      "name": "Dr. Smith",
      "type": "physician",
      "npi": "1234567890",
      "address": {
        "street": "456 Medical Dr",
        "city": "Anytown",
        "state": "CA",
        "zip": "12345"
      }
    },
    "insurance": {
      "insurance_id": "INS001",
      "payer_name": "Health Insurance Co",
      "payer_id": "PAYER001",
      "group_number": "GRP001",
      "subscriber_number": "SUB001",
      "plan_type": "PPO",
      "coverage_start_date": "2023-01-01T00:00:00"
    },
    "claim_lines": [
      {
        "line_id": "LINE001",
        "procedure_code": {
          "code": "99213",
          "description": "Office visit, established patient, 20-29 minutes"
        },
        "diagnosis_codes": [
          {
            "code": "Z00.00",
            "description": "Encounter for general adult medical examination without abnormal findings",
            "primary": true
          }
        ],
        "service_date": "2023-08-01T00:00:00",
        "billed_amount": "150.00",
        "place_of_service": "11",
        "rendering_provider_id": "PROV001"
      }
    ],
    "total_billed_amount": "150.00",
    "date_of_service": "2023-08-01T00:00:00",
    "claim_received_date": "2023-08-01T10:00:00"
  }
]
EOF
    
    print_success "Sample data created"
}

# Display next steps
display_next_steps() {
    echo ""
    echo "🎉 Setup completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Edit .env file with your configuration"
    echo "2. Activate virtual environment: source venv/bin/activate"
    echo "3. Run tests: python -m pytest src/tests/"
    echo "4. Start data producer: python src/producers/mock_data_generator.py"
    echo "5. Start streaming processor: python src/processors/streaming_processor.py"
    echo ""
    echo "🌐 Access points:"
    echo "- Kafka UI: http://localhost:8080"
    echo "- Spark Master: http://localhost:8081"
    echo "- MinIO Console: http://localhost:9001 (minioadmin/minioadmin)"
    echo "- Grafana: http://localhost:3000 (admin/admin)"
    echo "- Prometheus: http://localhost:9090"
    echo ""
    echo "📚 Documentation:"
    echo "- README.md: Project overview and setup"
    echo "- docs/architecture.md: Detailed architecture"
    echo "- docs/api.md: API documentation"
    echo ""
    echo "🛠️  Useful commands:"
    echo "- Stop services: docker-compose down"
    echo "- View logs: docker-compose logs -f"
    echo "- Restart services: docker-compose restart"
    echo ""
}

# Main setup function
main() {
    echo "🏥 Medical Claims Data Pipeline Setup"
    echo "====================================="
    echo ""
    
    check_prerequisites
    create_project_structure
    setup_python_env
    setup_env_vars
    start_infrastructure
    create_sample_data
    display_next_steps
}

# Run main function
main "$@"
